---
description: "Postgres yüksek erişilebilirlik (HA) çözümleri: Patroni, Stolon ve CloudNativePG karşılaştırması, otomatik failover, split-brain çözümü ve 2026 önerisi."
---
# Postgres HA — Patroni, Stolon, CloudNativePG

> *"Single instance prod Postgres = saatlik downtime kabul eden iş.
> 2026'da müşteri SLA'ları **otomatik failover** bekliyor — manuel
> 'master'ı promote et' günleri **bitti**."*

Bu rehber Postgres için yüksek erişilebilirlik (HA) çözümlerini —
Patroni, Stolon, CloudNativePG — karşılaştırır, **split-brain
çözümünü** açıklar, ve 2026 için pragmatik öneriyi verir.

---

## 🎯 HA Niye Lazım?

| Senaryo | Single instance | HA |
|---|---|---|
| Postgres process crash | Manuel müdahale, 30+ dk | Otomatik standby promote, < 30 sn |
| Node down | DB kayıp, restore gerekir | Standby aynı veriyle devam |
| Maintenance | Planlı downtime | Zero-downtime upgrade |
| Region down | Tüm DB kayıp | Cross-region replica → DR |
| Disk failure | Restore from backup (saatler) | Standby zaten var |

> 🔑 **HA = Otomatik failover + minimum veri kaybı (RPO < 5 dk)**.
> Manuel "master'ı promote et" SRE çağında kabul edilemez.

---

## 🏛️ Replication Türleri

### Streaming Replication
```
[PRIMARY] ──WAL stream──▶ [STANDBY-1]  (sync veya async)
        └────WAL──────▶ [STANDBY-2]  (async, read-replica)
```

- **Sync**: Primary commit'i standby ack edene kadar bekler. RPO = 0.
- **Async**: Primary hızlı commit, standby gecikebilir. RPO ≈ saniyeler.

### Logical Replication (Postgres 10+)
- Subset table replication
- Cross-version migration
- Multi-master için kullanılabilir (CDC pattern)

### Bidirectional Replication (BDR)
- 2nd Quadrant ticari
- Multi-master, conflict resolution
- Çoğu use-case için **gereksiz karmaşa**

---

## ⚖️ HA Çözümleri — Karşılaştırma

| Çözüm | Tip | DCS | K8s | 2026 Öneri |
|---|---|---|---|---|
| **Patroni** | Standalone (Python) | etcd / Consul / ZooKeeper | Manuel | ✅ Geleneksel ortam |
| **Stolon** | Standalone (Go) | etcd / Consul | Helm chart | ⚠️ Yavaşladı |
| **CloudNativePG** | K8s Operator | K8s API | ✅ Native | ✅ K8s'de **birinci tercih** |
| **Crunchy PGO** | K8s Operator | K8s API | ✅ Native | ✅ Enterprise |
| **Zalando Postgres Operator** | K8s Operator | K8s API | ✅ Native | ⚠️ Patroni-tabanlı |
| **pg_auto_failover** | Microsoft | Built-in monitor | Manuel | Niche |

---

## 🛠️ Patroni — Geleneksel Standart

### Mimari
```
┌─────────────────────────────────────────────┐
│                DCS (etcd)                    │
│   leader lock + cluster state               │
└──────────┬─────────────┬─────────────┬──────┘
           │             │             │
       ┌───▼───┐     ┌───▼───┐     ┌───▼───┐
       │ Patro │     │ Patro │     │ Patro │
       │   ni  │     │   ni  │     │   ni  │
       └───┬───┘     └───┬───┘     └───┬───┘
           │             │             │
       ┌───▼───┐     ┌───▼───┐     ┌───▼───┐
       │   PG  │     │   PG  │     │   PG  │
       │ PRIM  │     │ STBY  │     │ STBY  │
       └───────┘     └───────┘     └───────┘
```

### Config (`patroni.yml`)
```yaml
scope: postgres-prod
namespace: /db/
name: postgres-1

restapi:
  listen: 0.0.0.0:8008
  connect_address: <NODE_IP>:8008

etcd3:
  hosts: <ETCD_1>:2379,<ETCD_2>:2379,<ETCD_3>:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    synchronous_mode: true
    synchronous_mode_strict: false
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        max_connections: 200
        shared_buffers: 4GB
        wal_level: replica
        hot_standby: 'on'
        max_wal_senders: 10
        max_replication_slots: 10
        synchronous_commit: 'on'
        synchronous_standby_names: '*'

  initdb:
    - encoding: UTF8
    - data-checksums

  pg_hba:
    - host replication replicator 10.0.0.0/8 scram-sha-256
    - host all all 10.0.0.0/8 scram-sha-256

  users:
    admin:
      password: <ADMIN_PWD>
      options: [createrole, createdb]
    replicator:
      password: <REPL_PWD>
      options: [replication]

postgresql:
  listen: 0.0.0.0:5432
  connect_address: <NODE_IP>:5432
  data_dir: /var/lib/postgresql/data
  authentication:
    superuser:
      username: postgres
      password: <PG_SU_PWD>
    replication:
      username: replicator
      password: <REPL_PWD>

watchdog:
  mode: required   # OS-level watchdog (fence için)
  device: /dev/watchdog
  safety_margin: 5

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
  nosync: false
```

### Failover akışı
```
1. Primary Patroni keepalive etcd'ye gönderemiyor (30s)
2. Etcd lock TTL bitiyor
3. Standby'lar lock için yarışıyor
4. Synchronous standby kazanır (en güncel)
5. Watchdog primary'i fence ediyor (split-brain önlemek)
6. Yeni primary write trafiğini almaya başlıyor
7. Eski primary uyandığında pg_rewind ile yeniden senkronize
```

### HAProxy ile front
```
# /etc/haproxy/haproxy.cfg
listen postgres
  bind *:5432
  mode tcp
  option httpchk GET /master
  http-check expect status 200
  default-server inter 3s rise 2 fall 3 on-marked-down shutdown-sessions
  server pg1 10.0.0.1:5432 check port 8008
  server pg2 10.0.0.2:5432 check port 8008
  server pg3 10.0.0.3:5432 check port 8008

listen postgres-readonly
  bind *:5433
  mode tcp
  option httpchk GET /replica
  http-check expect status 200
  server pg1 10.0.0.1:5432 check port 8008
  server pg2 10.0.0.2:5432 check port 8008
  server pg3 10.0.0.3:5432 check port 8008
```

> 🔑 **App** sadece HAProxy 5432'ye bağlanır. HAProxy `/master` HTTP check ile primary'i bulur.

---

## 🛠️ CloudNativePG — K8s'de 2026 Önerisi

### Niye CloudNativePG?
- **K8s-native** (Patroni'siz, etcd-siz — K8s API'sini DCS olarak kullanır)
- **Operator pattern** — declarative
- **Backup native** (Barman + S3)
- **Monitoring native** (Prometheus exporter)
- **Rolling updates** zero-downtime
- **Healthy ecosystem** (CNCF projesi)

### Install
```bash
helm install cnpg cloudnative-pg/cloudnative-pg \
  -n cnpg-system --create-namespace
```

### Cluster manifest
```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-prod
  namespace: postgres
spec:
  instances: 3
  imageName: ghcr.io/cloudnative-pg/postgresql:16.4

  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: "4GB"
      effective_cache_size: "12GB"
      work_mem: "16MB"
      maintenance_work_mem: "1GB"
      synchronous_commit: "on"
      synchronous_standby_names: "ANY 1 (*)"

  bootstrap:
    initdb:
      database: app
      owner: app
      secret:
        name: postgres-app-creds

  storage:
    size: 100Gi
    storageClass: <FAST_SSD_CLASS>

  resources:
    requests: {cpu: "2", memory: "8Gi"}
    limits: {cpu: "4", memory: "16Gi"}

  affinity:
    podAntiAffinityType: required
    topologyKey: kubernetes.io/hostname

  monitoring:
    enablePodMonitor: true

  backup:
    barmanObjectStore:
      destinationPath: s3://<BACKUP_BUCKET>/postgres
      s3Credentials:
        accessKeyId: {name: backup-creds, key: ACCESS_KEY}
        secretAccessKey: {name: backup-creds, key: SECRET_KEY}
      wal:
        compression: gzip
        encryption: AES256
      data:
        compression: gzip
        encryption: AES256
    retentionPolicy: "30d"

  certificates:
    serverTLSSecret: postgres-server-cert
    clientCASecret: postgres-client-ca
```

### Service'ler (otomatik üretilir)
- `postgres-prod-rw` → primary (read-write)
- `postgres-prod-ro` → replicas (read-only)
- `postgres-prod-r` → primary + replicas (any)

### Failover testi
```bash
# Primary pod'u sil — failover otomatik
kubectl delete pod postgres-prod-1 -n postgres

# 30 saniye içinde yeni primary up:
kubectl get cluster postgres-prod -n postgres -o yaml | grep -A 5 currentPrimary
```

### Switchover (planlı)
```bash
kubectl cnpg promote postgres-prod postgres-prod-2 -n postgres
```

### Backup tetikle
```bash
kubectl cnpg backup postgres-prod --backup-name now -n postgres
```

### PITR restore
```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-restored
spec:
  bootstrap:
    recovery:
      backup:
        name: backup-20260504
      recoveryTarget:
        targetTime: "2026-05-04 14:30:00.00000+00"
```

---

## 🚦 Split-Brain — En Korktuğun Senaryo

### Ne demek?
İki node'un her ikisi de "ben primary'im" sansa, write'ları kabul ediyorlar → veri çakışması.

### Kaynaklar
- Network partition (etcd erişimsiz)
- DCS fail
- Watchdog bypass

### Çözüm: Quorum + Fencing
1. **Quorum** — DCS (etcd) çoğunluk kararı verir. 3 node'da 2 sağlıklıysa karar verilebilir; 1 sağlıklıysa primary "yok" denir.
2. **Watchdog/STONITH** — Primary erişilemez olduğunda OS-level fence (kernel reboot) → write kabul edemez hâle gelir.
3. **Synchronous mode** — Write'ı en az 1 standby ack etmeden commit yok → split-brain'de write kaybı yok (ama primary down olabilir).

### Patroni `synchronous_mode_strict: true`
```yaml
synchronous_mode: true
synchronous_mode_strict: true  # standby yoksa write reddedilir
```

> ⚠️ **Strict mode**: tüm standby'lar düşerse primary write kabul etmez. Veri tutarlılık kazancı, availability kaybı.

---

## 📊 Monitoring + Alerting

### Anahtar metrikler
```promql
# Replication lag
pg_replication_lag_seconds > 60

# Standby down
up{job="postgres-standby"} == 0

# Primary olmayan node primary olmuş (split-brain işareti)
count(pg_in_recovery == 0) > 1

# Connection count
pg_stat_activity_count / pg_settings_max_connections > 0.85

# Long-running transaction
pg_stat_activity_max_tx_duration > 600
```

### Alert
```yaml
groups:
  - name: postgres-ha
    rules:
      - alert: PostgresReplicationLag
        expr: pg_replication_lag_seconds > 60
        for: 5m
        labels: {severity: warning}

      - alert: PostgresStandbyDown
        expr: up{job="postgres-standby"} == 0
        for: 2m
        labels: {severity: page}

      - alert: PostgresMultiplePrimaries
        expr: count(pg_in_recovery == 0) > 1
        for: 1m
        labels: {severity: critical}
        annotations:
          summary: "SPLIT BRAIN: birden fazla primary"
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Single instance prod | Crash = downtime + restore | HA: 3 node minimum |
| 2-node setup | Quorum yok, split-brain riski | 3 node (etcd quorum) |
| Async replication only + claim "HA" | RPO yüksek (saniye-dakika veri kayıp) | Sync için en az 1 standby |
| Watchdog disabled | Split-brain mümkün | Watchdog enable, STONITH |
| Failover testi yok | İlk gerçek failover'da bug | Quarterly chaos drill |
| HAProxy single instance | LB down → cluster ulaşılmaz | HAProxy 2+ + Keepalived |
| Etcd shared (cluster ile aynı) | Etcd down = K8s + Postgres down | Dedicated etcd cluster |
| Replication user superuser | Compromise = full access | Sadece replication permission |
| `synchronous_standby_names` boş | Sync mode aktif değil | `'*'` veya specific isim |
| Backup HA stack'in dışında değil | Primary + standby aynı disk array → felaket | Off-site backup zorunlu |
| Manuel failover prosedürü | Bus factor 1 | Otomatik (Patroni/CNPG) |
| K8s'de bare PVC + manuel | Operator olmadan zor | CNPG / Crunchy / Zalando |

---

## 📋 Postgres HA Production Checklist

```
[ ] Min 3 node cluster (quorum için)
[ ] Sync replication: en az 1 standby
[ ] DCS: dedicated etcd / consul (cluster ile paylaşımlı değil)
[ ] Watchdog enabled (OS-level fence)
[ ] HAProxy / Keepalived front (2+ instance)
[ ] App: HAProxy connection (master/replica ayrı port)
[ ] PgBouncer arkasında HAProxy
[ ] Pod anti-affinity (farklı node'lar)
[ ] Backup off-cluster (S3, cross-region)
[ ] Backup retention politikası
[ ] PITR test edilmiş
[ ] Failover otomatik (manuel müdahale yok)
[ ] Quarterly chaos drill (primary kill → recover)
[ ] Switchover prosedürü dokumante (planlı maintenance)
[ ] Monitoring: replication lag, conn count, long tx
[ ] Alert: SplitBrain, StandbyDown, ReplicationLag
[ ] Replication user least-privilege
[ ] TLS internal (encryption-in-transit)
[ ] CloudNativePG (K8s) veya Patroni (VM) — tercih net
[ ] Upgrade prosedürü: rolling, zero-downtime
```

---

## 📚 Referanslar

- **Patroni** — github.com/zalando/patroni
- **CloudNativePG** — cloudnative-pg.io
- **Crunchy PGO** — crunchydata.com/products/crunchy-postgres-for-kubernetes
- **Stolon** — github.com/sorintlab/stolon
- **PostgreSQL High Availability** — postgresql.org/docs/current/high-availability.html
- [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md)
- [`Backup-Restore-Patterns.md`](Backup-Restore-Patterns.md)
- [`Zero-Downtime-Migrations.md`](Zero-Downtime-Migrations.md)
- [`11-SRE/Runbook-Template.md`](../11-SRE/Runbook-Template.md) — failover runbook

---

> *"HA 'biraz zaman sonra' değil, **gün-1** kararıdır. Single instance
> ile başlayan bir prod'a HA eklemek 6 ay sürer; HA ile başlamak 6
> haftalık iştir. **6 ay**'dan tasarrufu olan disiplin."*
