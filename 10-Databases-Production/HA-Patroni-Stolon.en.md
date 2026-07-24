---
description: "Postgres high-availability (HA) solutions: comparison of Patroni, Stolon, and CloudNativePG, automatic failover, split-brain resolution, and the 2026 recommendation."
tags:
  - Databases
  - PostgreSQL
  - Postgres HA
  - SRE
---
# Postgres HA — Patroni, Stolon, CloudNativePG

> *"Single-instance prod Postgres = a business that accepts hourly downtime.
> In 2026, customer SLAs expect **automatic failover** — the days of
> manually 'promoting the master' are **over**."*

This guide compares Postgres high-availability (HA) solutions —
Patroni, Stolon, CloudNativePG — explains **split-brain
resolution**, and gives the pragmatic recommendation for 2026.

---

## 🎯 Why Do You Need HA?

| Scenario | Single instance | HA |
|---|---|---|
| Postgres process crash | Manual intervention, 30+ min | Automatic standby promote, < 30 sec |
| Node down | DB lost, restore required | Standby continues with the same data |
| Maintenance | Planned downtime | Zero-downtime upgrade |
| Region down | Entire DB lost | Cross-region replica → DR |
| Disk failure | Restore from backup (hours) | Standby already exists |

> 🔑 **HA = automatic failover + minimum data loss (RPO < 5 min)**.
> Manually "promoting the master" is unacceptable when SRE gets paged.

---

## 🏛️ Types of Replication

### Streaming Replication
```
[PRIMARY] ──WAL stream──▶ [STANDBY-1]  (sync or async)
        └────WAL──────▶ [STANDBY-2]  (async, read-replica)
```

- **Sync**: The primary waits until the standby acks the commit. RPO = 0.
- **Async**: Primary commits fast, standby may lag. RPO ≈ seconds.

### Logical Replication (Postgres 10+)
- Subset table replication
- Cross-version migration
- Can be used for multi-master (CDC pattern)

### Bidirectional Replication (BDR)
- 2nd Quadrant commercial
- Multi-master, conflict resolution
- **Unnecessary complexity** for most use cases

---

## ⚖️ HA Solutions — Comparison

| Solution | Type | DCS | K8s | 2026 Recommendation |
|---|---|---|---|---|
| **Patroni** | Standalone (Python) | etcd / Consul / ZooKeeper | Manual | ✅ Traditional environment |
| **Stolon** | Standalone (Go) | etcd / Consul | Helm chart | ⚠️ Slowed down |
| **CloudNativePG** | K8s Operator | K8s API | ✅ Native | ✅ **First choice** on K8s |
| **Crunchy PGO** | K8s Operator | K8s API | ✅ Native | ✅ Enterprise |
| **Zalando Postgres Operator** | K8s Operator | K8s API | ✅ Native | ⚠️ Patroni-based |
| **pg_auto_failover** | Microsoft | Built-in monitor | Manual | Niche |

---

## 🛠️ Patroni — The Traditional Standard

### Architecture
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
  mode: required   # OS-level watchdog (for fencing)
  device: /dev/watchdog
  safety_margin: 5

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
  nosync: false
```

### Failover flow
```
1. Primary Patroni can't send its keepalive to etcd (30s)
2. Etcd lock TTL expires
3. Standbys race for the lock
4. Synchronous standby wins (the most up-to-date one)
5. Watchdog fences the primary (to prevent split-brain)
6. New primary starts accepting write traffic
7. When the old primary wakes up, it re-syncs via pg_rewind
```

### Fronting with HAProxy
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

> 🔑 **The app** only connects to HAProxy on 5432. HAProxy locates the primary via the `/master` HTTP check.

---

## 🛠️ CloudNativePG — The 2026 Recommendation on K8s

### Why CloudNativePG?
- **K8s-native** (no Patroni, no etcd — uses the K8s API as the DCS)
- **Operator pattern** — declarative
- **Native backup** (Barman + S3)
- **Native monitoring** (Prometheus exporter)
- **Rolling updates** zero-downtime
- **Healthy ecosystem** (a CNCF project)

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

### Services (auto-generated)
- `postgres-prod-rw` → primary (read-write)
- `postgres-prod-ro` → replicas (read-only)
- `postgres-prod-r` → primary + replicas (any)

### Failover test
```bash
# Delete the primary pod — failover is automatic
kubectl delete pod postgres-prod-1 -n postgres

# New primary is up within 30 seconds:
kubectl get cluster postgres-prod -n postgres -o yaml | grep -A 5 currentPrimary
```

### Switchover (planned)
```bash
kubectl cnpg promote postgres-prod postgres-prod-2 -n postgres
```

### Trigger a backup
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

## 🚦 Split-Brain — The Scenario You Fear Most

### What does it mean?
Both nodes believe "I'm the primary" and accept writes → data conflict.

### Causes
- Network partition (etcd unreachable)
- DCS fail
- Watchdog bypass

### Solution: Quorum + Fencing
1. **Quorum** — the DCS (etcd) makes the majority decision. With 3 nodes, a decision can be made if 2 are healthy; with only 1 healthy, the primary is declared "gone."
2. **Watchdog/STONITH** — when the primary becomes unreachable, an OS-level fence (kernel reboot) → it becomes unable to accept writes.
3. **Synchronous mode** — no commit until at least 1 standby acks the write → no write loss during split-brain (but the primary may go down).

### Patroni `synchronous_mode_strict: true`
```yaml
synchronous_mode: true
synchronous_mode_strict: true  # write is rejected if there's no standby
```

> ⚠️ **Strict mode**: if all standbys go down, the primary stops accepting writes. Consistency gain, availability loss.

---

## 📊 Monitoring + Alerting

### Key metrics
```promql
# Replication lag
pg_replication_lag_seconds > 60

# Standby down
up{job="postgres-standby"} == 0

# A non-primary node has become primary (split-brain indicator)
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
          summary: "SPLIT BRAIN: multiple primaries"
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Single-instance prod | Crash = downtime + restore | HA: 3-node minimum |
| 2-node setup | No quorum, split-brain risk | 3 nodes (etcd quorum) |
| Async replication only + claim "HA" | High RPO (seconds-to-minutes data loss) | At least 1 sync standby |
| Watchdog disabled | Split-brain possible | Enable watchdog, STONITH |
| No failover test | Bugs surface on the first real failover | Quarterly chaos drill |
| Single HAProxy instance | LB down → cluster unreachable | HAProxy 2+ + Keepalived |
| Shared etcd (same as the cluster) | Etcd down = K8s + Postgres down | Dedicated etcd cluster |
| Replication user is superuser | Compromise = full access | Replication permission only |
| `synchronous_standby_names` empty | Sync mode isn't active | `'*'` or a specific name |
| Backup isn't outside the HA stack | Primary + standby on the same disk array → disaster | Off-site backup mandatory |
| Manual failover procedure | Bus factor of 1 | Automatic (Patroni/CNPG) |
| Bare PVC + manual on K8s | Hard without an operator | CNPG / Crunchy / Zalando |

---

## 📋 Postgres HA Production Checklist

```
[ ] Min 3-node cluster (for quorum)
[ ] Sync replication: at least 1 standby
[ ] DCS: dedicated etcd / consul (not shared with the cluster)
[ ] Watchdog enabled (OS-level fence)
[ ] HAProxy / Keepalived front (2+ instances)
[ ] App: HAProxy connection (separate port for master/replica)
[ ] HAProxy behind PgBouncer
[ ] Pod anti-affinity (different nodes)
[ ] Backup off-cluster (S3, cross-region)
[ ] Backup retention policy
[ ] PITR tested
[ ] Failover automatic (no manual intervention)
[ ] Quarterly chaos drill (primary kill → recover)
[ ] Switchover procedure documented (planned maintenance)
[ ] Monitoring: replication lag, conn count, long tx
[ ] Alert: SplitBrain, StandbyDown, ReplicationLag
[ ] Replication user least-privilege
[ ] Internal TLS (encryption-in-transit)
[ ] CloudNativePG (K8s) or Patroni (VM) — clear preference
[ ] Upgrade procedure: rolling, zero-downtime
```

---

## 📚 References

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

> *"HA is not a 'some day' decision — it's a **day-1** decision. Adding
> HA to a prod that started as a single instance takes 6 months; starting
> with HA is 6 weeks of work. A discipline that saves you **6 months**."*
