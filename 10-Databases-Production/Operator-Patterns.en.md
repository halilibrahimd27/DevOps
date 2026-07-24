---
description: "Comparison of the 3 major Postgres operators for Kubernetes: CloudNativePG, Crunchy PGO, and Zalando; HA, backup, monitoring, and a clear decision for 2026."
tags:
  - Databases
  - Kubernetes
  - PostgreSQL
  - Postgres HA
---
# Postgres Operator Comparison — CloudNativePG, Crunchy, Zalando

> *"If you're managing Postgres on K8s, an **operator is mandatory**. Manual
> StatefulSet + Patroni is the 2018 way. In 2026 you can't claim a
> 'declarative DB' without an operator. The question is: **which operator**?"*

This guide compares the 3 major Postgres operators: CloudNativePG,
Crunchy PGO, and Zalando Postgres Operator. A clear decision as of 2026.

---

## ⚖️ The 3 Major Operators

| Dimension | **CloudNativePG** | **Crunchy PGO** | **Zalando** |
|---|---|---|---|
| **Owner** | EnterpriseDB (CNCF Sandbox) | Crunchy Data | Zalando |
| **License** | Apache 2 | Apache 2 | MIT |
| **HA backend** | Postgres replication (no Patroni) | Patroni | Patroni |
| **DCS** | K8s API | K8s API | K8s API |
| **Setup** | Very easy | Medium | Medium |
| **Backup native** | Barman | pgBackRest | WAL-E (old) / WAL-G |
| **Monitoring** | Prometheus exporter built-in | pgmonitor (separate) | exporter + Spilo |
| **Connection pooler** | PgBouncer integrated | pgBouncer optional | Connection Manager (custom) |
| **Cluster image** | Stock Postgres | Crunchy custom | Spilo (Patroni + Postgres) |
| **Major version upgrade** | ✅ In-place | ✅ Manual + tooling | ✅ |
| **Multi-cluster (DR)** | ✅ Native | ✅ | ⚠️ Manual |
| **Active-passive replication** | ✅ | ✅ | ✅ |
| **Active-active** | ❌ | ❌ (not native PostgreSQL) | ❌ |
| **GitOps friendly** | ✅ Native | ✅ | ✅ |
| **Community** | Rising | Established, enterprise | Established, OSS |
| **2026 Recommendation** | ✅✅ **First choice in the K8s ecosystem** | ✅ Enterprise + commercial support | ⚠️ For legacy projects |

---

## 🌳 Decision Tree

```
START
  │
  ├── New cluster + greenfield?
  │     │
  │     └── YES → CloudNativePG
  │            (most modern, easiest, CNCF momentum)
  │
  ├── Enterprise support needed + commercial contract?
  │     │
  │     └── YES → Crunchy PGO (Crunchy Data commercial)
  │            or CloudNativePG (EnterpriseDB commercial)
  │
  ├── Migrating from an existing Patroni setup?
  │     │
  │     └── YES → Zalando (Patroni native) or Crunchy
  │
  └── Multi-cluster DR critical?
         │
         └── CloudNativePG (native multi-cluster) or Crunchy
```

> 🎯 **The clear 2026 recommendation**: **CloudNativePG** for most cases. If you need enterprise + premium support, **Crunchy**.

---

## 🚀 CloudNativePG — Details

### Why the 2026 recommendation?
- **K8s-native**: K8s API as DCS (no Patroni / etcd)
- **Operator pattern**: Fully declarative
- **Backup native**: Barman + S3
- **Monitoring native**: Prometheus exporter
- **Rolling updates**: Zero-downtime
- **CNCF Sandbox**: Independent community

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

### Automatic services
```
postgres-prod-rw  → primary (read-write)
postgres-prod-ro  → replicas (read-only)
postgres-prod-r   → primary + replicas (any)
```

### Failover
```bash
# Delete the primary pod → automatic failover
kubectl delete pod postgres-prod-1 -n postgres

# New primary up within 30 seconds
kubectl get cluster postgres-prod -n postgres \
  -o jsonpath='{.status.currentPrimary}'
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

### Major version upgrade
```yaml
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:17  # 16 → 17
```

→ The operator performs a rolling upgrade; downtime ~5-10 seconds (failover).

---

## 🏛️ Crunchy PGO — Enterprise Tier

### Why Crunchy?
- 10+ years of enterprise pedigree
- **Commercial support**: Crunchy Data subscription
- **pgBackRest** (the strongest Postgres backup tool)
- **PostgreSQL Enterprise Manager** UI
- TDE, audit, FIPS 140-2 compliance
- Air-gapped deployment

### Cluster manifest (example)
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

> On K8s, Crunchy uses Crunchy's custom containers (not the stock Postgres image).

---

## 🌍 Zalando Postgres Operator

### Why Zalando?
- Adapts Patroni to K8s
- Spilo image (Patroni + Postgres + WAL-G pre-installed)
- Open source, stable
- A natural fit for migrating from an existing Patroni-based setup

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

> 🔑 Zalando has slowed down in recent years — Crunchy and CloudNativePG are more active.

---

## 🚧 Scenarios Without an Operator

### "Use a managed DB service" is already our recommendation
See [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md).

| Scenario | Preference |
|---|---|
| AWS-native + low ops | RDS / Aurora |
| GCP | CloudSQL / AlloyDB |
| Multi-cloud | CloudNativePG on K8s |
| On-prem | CloudNativePG / Crunchy |
| Air-gapped | Crunchy enterprise |

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Manual StatefulSet + Patroni | Operational burden | Operator (CNPG / Crunchy) |
| Using an operator but no backup | Breach is a matter of time | Barman / pgBackRest auto-config |
| Single replica is "enough" | SPOF | min 3 replicas HA |
| No sync replication | High RPO | synchronous_standby_names="ANY 1 (*)" |
| No pod anti-affinity | Pods on the same node → node down is a disaster | required + topologyKey: hostname |
| Manual TLS certificates | Manual rotation | cert-manager + operator integration |
| Skipping major versions | Direct 13 → 17 (untested) | 13 → 14 → 15 → 16 → 17 |
| Manual operator restart | Drift | GitOps + ArgoCD self-heal |
| Backup only within the cluster | Region down | Cross-region replication |
| Neglected operator upgrade | Old operator → bugs pile up | Quarterly minor upgrade |

---

## 📋 Operator Adoption Checklist

```
[ ] Operator choice: CNPG / Crunchy / Zalando (decision documented)
[ ] HA: 3+ instances (sync + async mix)
[ ] Pod anti-affinity required + topologyKey: hostname
[ ] Storage: fast SSD class, 100Gi+ headroom
[ ] Resources: explicit requests/limits
[ ] postgresql parameters tuned
[ ] pg_stat_statements + pg_hba correct
[ ] Backup: S3 + encryption + cross-region
[ ] Restore drill quarterly
[ ] PITR tested
[ ] Monitoring: postgres-exporter + alerts
[ ] TLS: cert-manager + secret rotation
[ ] PgBouncer integrated (native in CNPG)
[ ] Operator upgrade procedure documented
[ ] Major version upgrade plan
[ ] DR: cross-region cluster (if applicable)
[ ] Documentation: operator + Postgres tunables
```

---

## 📚 References

- **CloudNativePG** — cloudnative-pg.io
- **Crunchy PGO** — crunchydata.com/products/crunchy-postgres-for-kubernetes
- **Zalando Postgres Operator** — postgres-operator.readthedocs.io
- **Patroni** — patroni.readthedocs.io (without an operator)
- **CNCF Sandbox** — cncf.io
- [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md)
- [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md)
- [`Backup-Restore-Patterns.md`](Backup-Restore-Patterns.md)
- [`Connection-Pooling.md`](Connection-Pooling.md)
- [`Monitoring-Postgres.md`](Monitoring-Postgres.md)
- [`Zero-Downtime-Migrations.md`](Zero-Downtime-Migrations.md)

---

> *"Managing Postgres on K8s without an operator makes any 'declarative'
> claim impossible — every failed failover requires manual intervention.
> **An operator** turns hours of manual work into **minutes**, and turns
> **bus factor** from 1 into **N**."*
