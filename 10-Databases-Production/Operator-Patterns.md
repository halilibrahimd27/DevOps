---
description: "Kubernetes için 3 büyük Postgres operator karşılaştırması: CloudNativePG, Crunchy PGO ve Zalando; HA, backup, monitoring ve 2026 için net karar."
tags:
  - Databases
  - Kubernetes
  - PostgreSQL
  - Postgres HA
---
# Postgres Operator Karşılaştırma — CloudNativePG, Crunchy, Zalando

> *"K8s'de Postgres yönetiyorsan **operator zorunlu**. Manuel
> StatefulSet + Patroni 2018'in yöntemi. 2026'da operator olmadan
> 'declarative DB' iddia edemezsin. Soru: **hangi operator**?"*

Bu rehber 3 büyük Postgres operator'ünü karşılaştırır: CloudNativePG,
Crunchy PGO, Zalando Postgres Operator. 2026 itibarıyla net karar.

---

## ⚖️ 3 Büyük Operator

| Boyut | **CloudNativePG** | **Crunchy PGO** | **Zalando** |
|---|---|---|---|
| **Sahibi** | EnterpriseDB (CNCF Sandbox) | Crunchy Data | Zalando |
| **License** | Apache 2 | Apache 2 | MIT |
| **HA backend** | Postgres replication (no Patroni) | Patroni | Patroni |
| **DCS** | K8s API | K8s API | K8s API |
| **Setup** | Çok kolay | Orta | Orta |
| **Backup native** | Barman | pgBackRest | WAL-E (eski) / WAL-G |
| **Monitoring** | Prometheus exporter built-in | pgmonitor (separate) | exporter + Spilo |
| **Connection pooler** | PgBouncer integrated | pgBouncer optional | Connection Manager (custom) |
| **Cluster image** | Stock Postgres | Crunchy custom | Spilo (Patroni + Postgres) |
| **Major version upgrade** | ✅ In-place | ✅ Manual + tooling | ✅ |
| **Multi-cluster (DR)** | ✅ Native | ✅ | ⚠️ Manual |
| **Active-passive replication** | ✅ | ✅ | ✅ |
| **Active-active** | ❌ | ❌ (PostgreSQL native değil) | ❌ |
| **GitOps friendly** | ✅ Native | ✅ | ✅ |
| **Topluluk** | Yükselişte | Köklü, enterprise | Köklü, OSS |
| **2026 Öneri** | ✅✅ **K8s ekosisteminde 1.tercih** | ✅ Enterprise + ticari destek | ⚠️ Eski projeler için |

---

## 🌳 Karar Ağacı

```
START
  │
  ├── Yeni cluster + greenfield?
  │     │
  │     └── EVET → CloudNativePG
  │            (en modern, en kolay, CNCF momentum)
  │
  ├── Enterprise support gerekli + ticari kontrat?
  │     │
  │     └── EVET → Crunchy PGO (Crunchy Data ticari)
  │            veya CloudNativePG (EnterpriseDB ticari)
  │
  ├── Mevcut Patroni setup'ından migrate?
  │     │
  │     └── EVET → Zalando (Patroni native) veya Crunchy
  │
  └── Multi-cluster DR critical?
         │
         └── CloudNativePG (native multi-cluster) veya Crunchy
```

> 🎯 **2026 net önerisi**: **CloudNativePG** çoğu durum için. Enterprise + premium support ihtiyacı varsa **Crunchy**.

---

## 🚀 CloudNativePG — Detay

### Niye 2026 önerisi?
- **K8s-native**: K8s API DCS olarak (Patroni / etcd yok)
- **Operator pattern**: Tam declarative
- **Backup native**: Barman + S3
- **Monitoring native**: Prometheus exporter
- **Rolling updates**: Zero-downtime
- **CNCF Sandbox**: Bağımsız topluluk

### Install
```bash
helm install cnpg cloudnative-pg/cloudnative-pg \
  -n cnpg-system --create-namespace
```

### Cluster manifest (production-ready)
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
      log_min_duration_statement: "500ms"
      pg_stat_statements.track: "all"

    pg_hba:
      - host app app 10.0.0.0/8 scram-sha-256
      - host replication replicator 10.0.0.0/8 scram-sha-256

    shared_preload_libraries:
      - pg_stat_statements

  bootstrap:
    initdb:
      database: app
      owner: app
      secret:
        name: postgres-app-creds
      postInitSQL:
        - CREATE EXTENSION IF NOT EXISTS pgcrypto;

  storage:
    size: 100Gi
    storageClass: <FAST_SSD>

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
      destinationPath: s3://<BUCKET>/postgres
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

### Otomatik service'ler
```
postgres-prod-rw  → primary (read-write)
postgres-prod-ro  → replicas (read-only)
postgres-prod-r   → primary + replicas (any)
```

### Failover
```bash
# Primary pod'u sil → otomatik failover
kubectl delete pod postgres-prod-1 -n postgres

# 30 saniye içinde yeni primary up
kubectl get cluster postgres-prod -n postgres \
  -o jsonpath='{.status.currentPrimary}'
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

### Major version upgrade
```yaml
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:17  # 16 → 17
```

→ Operator rolling upgrade yapar; downtime ~5-10 saniye (failover).

---

## 🏛️ Crunchy PGO — Enterprise Tier

### Niye Crunchy?
- 10+ yıllık enterprise pedigree
- **Ticari destek**: Crunchy Data subscription
- **pgBackRest** (en güçlü Postgres backup)
- **PostgreSQL Enterprise Manager** UI
- TDE, audit, FIPS 140-2 compliance
- Air-gapped deployment

### Cluster manifest (örnek)
```yaml
apiVersion: postgres-operator.crunchydata.com/v1beta1
kind: PostgresCluster
metadata:
  name: hippo
spec:
  postgresVersion: 16
  instances:
    - name: instance1
      replicas: 3
      dataVolumeClaimSpec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 100Gi
  backups:
    pgbackrest:
      repos:
        - name: repo1
          s3:
            bucket: <BUCKET>
            endpoint: s3.amazonaws.com
            region: <REGION>
```

> Crunchy K8s'de Crunchy custom container'ları kullanır (stock Postgres image değil).

---

## 🌍 Zalando Postgres Operator

### Niye Zalando?
- Patroni'yi K8s'e adaptasyon
- Spilo image (Patroni + Postgres + WAL-G önceden installed)
- Açık kaynak, stable
- Mevcut Patroni-based migration için doğal

### Manifest
```yaml
apiVersion: acid.zalan.do/v1
kind: postgresql
metadata:
  name: my-postgres
spec:
  teamId: "<TEAM>"
  volume:
    size: 100Gi
  numberOfInstances: 3
  users:
    app:
      - superuser
      - createdb
  databases:
    app: app
  postgresql:
    version: "16"
```

> 🔑 Zalando son yıllarda yavaşladı — Crunchy ve CloudNativePG daha aktif.

---

## 🚧 Operator Olmayan Senaryolar

### "DB managed servisi kullan" zaten önerimiz
Bkz [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md).

| Senaryo | Tercih |
|---|---|
| AWS-native + low ops | RDS / Aurora |
| GCP | CloudSQL / AlloyDB |
| Multi-cloud | CloudNativePG K8s |
| On-prem | CloudNativePG / Crunchy |
| Air-gapped | Crunchy enterprise |

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Manual StatefulSet + Patroni | Operasyon yükü | Operator (CNPG / Crunchy) |
| Operator kullanıyor ama backup yok | İhlal an meselesi | Barman / pgBackRest auto-config |
| Single replica "yeter" | SPOF | min 3 replica HA |
| Sync replication yok | RPO yüksek | synchronous_standby_names="ANY 1 (*)" |
| Pod anti-affinity yok | Aynı node'da pod'lar → node down felaket | required + topologyKey: hostname |
| TLS sertifika manuel | Manuel rotation | cert-manager + operator integration |
| Major version skip | Direct 13 → 17 (test'siz) | 13 → 14 → 15 → 16 → 17 |
| Operator restart manuel | Drift | GitOps + ArgoCD self-heal |
| Backup sadece cluster içi | Region down | Cross-region replication |
| Operator upgrade ihmal | Eski operator → bug birikir | Quarterly minor upgrade |

---

## 📋 Operator Adoption Checklist

```
[ ] Operator seçimi: CNPG / Crunchy / Zalando (karar belgelenmiş)
[ ] HA: 3+ instance (sync + async mix)
[ ] Pod anti-affinity required + topologyKey: hostname
[ ] Storage: fast SSD class, 100Gi+ headroom
[ ] Resources: explicit requests/limits
[ ] postgresql parameters tune edilmiş
[ ] pg_stat_statements + pg_hba doğru
[ ] Backup: S3 + encryption + cross-region
[ ] Restore drill quarterly
[ ] PITR test edilmiş
[ ] Monitoring: postgres-exporter + alarmlar
[ ] TLS: cert-manager + secret rotation
[ ] PgBouncer integrate (CNPG'de native)
[ ] Operator upgrade prosedürü dokumante
[ ] Major version upgrade plan
[ ] DR: cross-region cluster (varsa)
[ ] Documentation: operator + Postgres tunables
```

---

## 📚 Referanslar

- **CloudNativePG** — cloudnative-pg.io
- **Crunchy PGO** — crunchydata.com/products/crunchy-postgres-for-kubernetes
- **Zalando Postgres Operator** — postgres-operator.readthedocs.io
- **Patroni** — patroni.readthedocs.io (operator olmadan)
- **CNCF Sandbox** — cncf.io
- [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md)
- [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md)
- [`Backup-Restore-Patterns.md`](Backup-Restore-Patterns.md)
- [`Connection-Pooling.md`](Connection-Pooling.md)
- [`Monitoring-Postgres.md`](Monitoring-Postgres.md)
- [`Zero-Downtime-Migrations.md`](Zero-Downtime-Migrations.md)

---

> *"Operator olmadan K8s'de Postgres yönetmek 'declarative' iddiası
> imkansız — her başarısız failover manuel müdahale gerektirir.
> **Operator** = saatlerce manuel iş **dakikalara**, **bus factor**
> 1'den **N**'e."*
