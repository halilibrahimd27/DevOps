---
description: "Guide for a prod-grade PostgreSQL setup: postgresql.conf tuning, connection pooling, monitoring, and operational decisions; referencing Postgres 16/17."
tags:
  - Databases
  - PostgreSQL
  - Performance
  - Monitoring
---
# PostgreSQL Production Guide — Tuning, Pooling, Monitoring

> *"PostgreSQL's default config looks like it was written for a
> Raspberry Pi. If it isn't tuned in the **first week** on a production
> server, 6 months later the 'why is this slow' argument starts."*

As of 2026, this guide compiles the critical tuning, connection
pooling, monitoring, and operational topics for a prod-grade
PostgreSQL setup. It references Postgres 16/17.

---

## 🎯 First Decision: Containerized, Managed, or Bare-Metal?

| Scenario | Preference |
|---|---|
| Dev / staging | Container (docker-compose / StatefulSet) |
| Prod < 100 GB | K8s Operator (CloudNativePG, Zalando) |
| Prod 100 GB – 1 TB | Managed (RDS / CloudSQL / Aurora) |
| Prod > 1 TB, IOPS-heavy | Bare metal / dedicated VM + managed backup |
| Multi-region active-active | CockroachDB / YugabyteDB (not Postgres!) |

> 🔑 **Rule:** "Is DB operations **your core competency**?" If the answer
> is "no", use a managed service. Vendor lock-in cost is a tenth of
> a postgres DBA's salary.

---

## ⚙️ `postgresql.conf` Tuning

> ⚠️ Start with **`pgtune.leopard.in.ua`**, then tune based on your workload.
> The values below reference **16 GB RAM, 4 vCPU**.

### Memory
```ini
# Total RAM × 25% — query buffer cache
shared_buffers = 4GB

# Per-query work memory — sorting, hash join (PER operation, not per connection)
# Start conservative (16-64MB); if EXPLAIN ANALYZE shows disk-temp, increase gradually.
# WARNING: total consumption ≈ work_mem × concurrent sort/hash op count → an aggressive value risks OOM.
work_mem = 16MB

# Maintenance (VACUUM, CREATE INDEX) — Total RAM × 5%
maintenance_work_mem = 1GB

# OS file cache hint — Postgres's trust in the OS cache
effective_cache_size = 12GB

# WAL buffer
wal_buffers = 16MB
```

### Connections
```ini
max_connections = 100   # keep low behind PgBouncer

# Statement timeout — kill bad queries
statement_timeout = 60s
idle_in_transaction_session_timeout = 5min
lock_timeout = 30s
```

> 🔑 **Rule:** `max_connections` × `work_mem` ≤ `shared_buffers`. Otherwise
> there's a memory exhaustion risk.

### Checkpoint & WAL
```ini
# Checkpoint less frequent + smoother
checkpoint_timeout = 15min
checkpoint_completion_target = 0.9
max_wal_size = 4GB
min_wal_size = 1GB

# For WAL replication
wal_level = replica
max_wal_senders = 10
hot_standby = on
```

### Query Planner
```ini
random_page_cost = 1.1   # for SSD (4.0 on HDD)
effective_io_concurrency = 200   # SSD/NVMe
default_statistics_target = 100   # plan quality
```

### Logging (critical for production observability)
```ini
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB

log_min_duration_statement = 500ms   # log queries taking 500ms+
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0   # log all temp files (indicator that work_mem is insufficient)
log_autovacuum_min_duration = 0
log_line_prefix = '%m [%p] %q%u@%d/%a '
```

### Autovacuum (never disable)
```ini
autovacuum = on   # NEVER off
autovacuum_max_workers = 4
autovacuum_naptime = 30s

# Speed it up (defaults lead to bloat)
autovacuum_vacuum_scale_factor = 0.05   # vacuum once the table grows 5%
autovacuum_analyze_scale_factor = 0.02
autovacuum_vacuum_cost_limit = 1000
```

> 🚨 **`autovacuum = off`** = a death sentence for the DB. Table bloat →
> queries slow down → cardinality gets worse → more bloat. A spiral.

---

## 🌊 Connection Pooling: PgBouncer

A PostgreSQL connection = a **process**. Each connection is ~10 MB RAM.
`max_connections=500` = 5 GB just for idle connections.

**PgBouncer**: 1 worker multiplies thousands of client connections into a handful of DB connections.

### Choosing a mode
| Mode | Usage | Limits |
|---|---|---|
| **Session** | Default; client-conn = DB-conn lifetime | Pool runs dry, idle timeouts |
| **Transaction** | Connection freed at end of transaction | **Best for most apps** |
| **Statement** | Freed after every statement | Multi-statement TX forbidden |

> 🔑 **`pool_mode = transaction`** is the sweet spot for modern apps.

### Config example
```ini
# /etc/pgbouncer/pgbouncer.ini
[databases]
app = host=<DB_HOST> port=5432 dbname=app

[pgbouncer]
listen_addr = *
listen_port = 6432
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

pool_mode = transaction

# Pool sizing
default_pool_size = 25      # DB connection per pool
min_pool_size = 5
reserve_pool_size = 5
reserve_pool_timeout = 5

max_client_conn = 1000      # total max from clients
max_db_connections = 50     # total max toward the DB

# Timeout
server_idle_timeout = 600
server_lifetime = 3600
query_wait_timeout = 120

# TLS
server_tls_sslmode = require
client_tls_sslmode = require
```

### App side
```
postgres://app:<PWD>@<PGBOUNCER_HOST>:6432/app?sslmode=require
```

> ⚠️ In transaction mode, **prepared statements** cause trouble.
> With Postgres 14+, `protocol-level` prepared statements are supported
> in PgBouncer (`max_prepared_statements`).

---

## 🔒 Security Baseline

### `pg_hba.conf`
```
# /etc/postgresql/<VER>/main/pg_hba.conf

# local connection (Unix socket)
local  all      all                            scram-sha-256

# local network — application subnet
host   app      app           10.0.0.0/8       scram-sha-256

# replica
host   replication  replicator  10.0.0.0/8     scram-sha-256

# DENY everything else
host   all      all           0.0.0.0/0        reject
```

> 🚨 `host all all 0.0.0.0/0 trust` or `md5` = **leaving the door open**.
> This line must not exist in production.

### Role hygiene
```sql
-- Superuser only for the DBA, not the app
CREATE ROLE dba_team SUPERUSER;

-- App user — only its own DB, only the required tables
CREATE ROLE app LOGIN PASSWORD '<PWD>';
GRANT CONNECT ON DATABASE app TO app;
GRANT USAGE ON SCHEMA public TO app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app;

-- Separate role for migrations
CREATE ROLE app_migrate LOGIN PASSWORD '<PWD>';
GRANT app TO app_migrate;
GRANT CREATE ON SCHEMA public TO app_migrate;
```

### Encryption
- **In transit**: TLS mandatory (`pg_hba.conf` `hostssl`)
- **At rest**: Filesystem-level (LUKS) or cloud KMS-backed disk
- **Sensitive columns**: pgcrypto or app-side encryption

---

## 📊 Monitoring

### `pg_stat_statements` extension
```sql
-- postgresql.conf
shared_preload_libraries = 'pg_stat_statements'

-- In the DB
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

```sql
-- The slowest queries
SELECT query, calls, total_exec_time, mean_exec_time, rows
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Where the total time goes
SELECT query, total_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;
```

### Postgres Exporter (Prometheus)
```yaml
# helm install: prometheus-community/prometheus-postgres-exporter
postgresql-exporter:
  config:
    datasource:
      uri: <PG_HOST>:5432
      user: postgres_exporter
      passwordSecret:
        name: postgres-exporter-creds
        key: password
      database: postgres
      sslmode: require
  serviceMonitor:
    enabled: true
```

### Key metrics + alerts
```yaml
groups:
  - name: postgres
    rules:
      - alert: PostgresDown
        expr: pg_up == 0
        for: 1m

      - alert: PostgresReplicationLag
        expr: pg_replication_lag_seconds > 60
        for: 5m

      - alert: PostgresConnectionsHigh
        expr: pg_stat_activity_count / pg_settings_max_connections > 0.8
        for: 5m

      - alert: PostgresLongRunningTransaction
        expr: pg_stat_activity_max_tx_duration > 600
        for: 5m

      - alert: PostgresDeadlocks
        expr: rate(pg_stat_database_deadlocks[5m]) > 0
        for: 1m

      - alert: PostgresAutovacuumDisabled
        expr: pg_settings_autovacuum != 1

      - alert: PostgresTableBloat
        expr: pg_bloat_ratio > 50
        for: 30m

      - alert: PostgresDiskFullSoon
        expr: predict_linear(node_filesystem_avail_bytes{mountpoint="/var/lib/postgresql"}[6h], 24*3600) < 0
        for: 30m
```

### Slow query log
```sql
-- Log any query that runs 1+ second
ALTER SYSTEM SET log_min_duration_statement = '1s';
SELECT pg_reload_conf();
```

→ Logs are shipped to Loki/Splunk, and flow into dashboards.

---

## 🚦 Index Hygiene

### Detecting missing indexes
```sql
-- Tables doing sequential scans
SELECT relname, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch
FROM pg_stat_user_tables
WHERE seq_scan > idx_scan
ORDER BY seq_tup_read DESC;
```

### Unused indexes
```sql
-- Indexes never used (drop candidates)
SELECT schemaname, relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

### Index bloat
```sql
-- REINDEX CONCURRENTLY while pg_stat_progress_create_index tracks progress
REINDEX INDEX CONCURRENTLY <INDEX_NAME>;
```

---

## 🛡️ HA Topology

### Streaming Replication (simple)
```
PRIMARY ──WAL stream──▶ STANDBY-1 (sync, automatic failover)
                    └──▶ STANDBY-2 (async, read replica)
```

### Auto-failover: Patroni
- **Patroni** = Postgres + DCS (etcd/Consul) + watchdog
- Primary down → standby switches to promote
- Details: [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md)

### K8s Operator: CloudNativePG (recommended)
```bash
helm install cnpg cloudnative-pg/cloudnative-pg \
  -n cnpg-system --create-namespace
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: app-postgres
spec:
  instances: 3
  imageName: ghcr.io/cloudnative-pg/postgresql:16.4
  storage:
    size: 100Gi
    storageClass: <FAST_SSD_CLASS>
  bootstrap:
    initdb:
      database: app
      owner: app
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
    retentionPolicy: "30d"
  resources:
    requests: {cpu: "2", memory: "8Gi"}
    limits: {cpu: "4", memory: "16Gi"}
```

> 🔑 **CloudNativePG** is the most pragmatic K8s operator in 2026. HA + backup + monitoring + replication integrated.

---

## 📦 Backup Strategy

| Method | RPO | Restore | Usage |
|---|---|---|---|
| `pg_dump` once a day | 24h | Slow | Dev / small |
| `pg_basebackup` | 1 day | Fast | Full DB image |
| **WAL-G + S3** | < 5 min | PITR | **Sweet spot for most prod** |
| **pgBackRest** | < 5 min | Fast | Incremental, large prod |
| Streaming replica + snapshot | 0 | Instant | HA, top tier |

### An untested backup is not a backup
```bash
# Quarterly: backup restore drill
1. Spin up a new instance
2. Restore the latest backup
3. Smoke test: is the schema consistent, is row count reasonable, does the app connect?
4. Measure RTO
5. Postmortem: fix any gaps
```

> ⚠️ **3-2-1 rule:** 3 copies, 2 different media, 1 off-site.
> Backup on S3 has **versioned** + **MFA delete** on.

---

## 🔄 Zero-Downtime Migration

> Details: [`Zero-Downtime-Migrations.md`](Zero-Downtime-Migrations.md).

### Expand/Contract pattern
```
1. EXPAND: add new column (default null)
2. App: dual write (old + new column)
3. Backfill: copy data from old → new
4. App: write/read only the new column
5. CONTRACT: drop the old column
```

### Online schema change
- **gh-ost** (GitHub) — designed for MySQL, the postgres alternative is `pg_repack`
- **`pg_repack`**: lock-free table refactor

```bash
# Clean up table bloat, lock-free
pg_repack -d app -t large_table
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Default `postgresql.conf` in prod | Optimized for a Raspberry Pi | pgtune + workload-tune |
| `max_connections=500` without PgBouncer | RAM exhaustion | PgBouncer + lower max_connections |
| App connects with `superuser` | Privilege violation, audit trail lost | App-specific role, least privilege |
| `autovacuum = off` | Bloat → DB dies | Never disable it |
| Backup never tested | Doesn't work during a crisis | Quarterly restore drill |
| `pg_dump` on a 500 GB DB | Takes hours, transaction inconsistent | WAL-G or pgBackRest |
| No index strategy | Sequential scans, slow queries | pg_stat_user_indexes review |
| 50+ unused indexes | Write amplification | Quarterly cleanup |
| Replication lag not monitored | Read replica serves stale data | Alert + dashboard |
| Schema migration in unattended deploy | `DROP COLUMN` mid-prod | Expand/contract pattern |
| DB exposed to the internet | Brute force | private network only |
| No TLS | A sniffer reads the password | `hostssl` enforce |
| Same DB for all apps | Cross-tenant query, SLO violation | DB-per-service or schema-per-service |
| Infinite connection retry | DB down → app DDoSes the DB | Exponential backoff + jitter |

---

## 📋 Production Readiness Checklist

```
[ ] postgresql.conf tuned to the workload
[ ] PgBouncer (transaction mode) installed
[ ] pg_hba.conf: no 0.0.0.0/0, app subnet only
[ ] TLS enforced (hostssl)
[ ] App user least privilege; superuser only for the DBA
[ ] autovacuum active, sped up
[ ] pg_stat_statements extension
[ ] postgres-exporter + Prometheus + alerts
[ ] Slow query log → SIEM/Loki
[ ] HA: streaming replica (sync + async)
[ ] Auto-failover via Patroni or CloudNativePG
[ ] Backup: WAL-G or pgBackRest, S3 versioned + MFA delete
[ ] Quarterly restore drill
[ ] Index review (missing + unused)
[ ] Migration: expand/contract pattern, manual review
[ ] Connection retry: exponential backoff + jitter (app-side)
[ ] DR plan: how long for primary down → standby promote?
[ ] Capacity planning: disk/conn/CPU trend
[ ] PII encryption: pgcrypto or app-side
[ ] Audit log: pgaudit (or shipped from pg_stat_activity)
[ ] Logical replication (read-replica → analytics)
```

---

## 📚 References

- **PostgreSQL Documentation** — postgresql.org/docs
- **CloudNativePG** — cloudnative-pg.io
- **Patroni** — github.com/zalando/patroni
- **PgBouncer** — pgbouncer.org
- **pgtune** — pgtune.leopard.in.ua
- **WAL-G** — github.com/wal-g/wal-g
- **pgBackRest** — pgbackrest.org
- [`Backup-Restore-Patterns.md`](Backup-Restore-Patterns.md)
- [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md)
- [`Zero-Downtime-Migrations.md`](Zero-Downtime-Migrations.md)
- [`Connection-Pooling.md`](Connection-Pooling.md)
- [`Monitoring-Postgres.md`](Monitoring-Postgres.md)

---

> *"PostgreSQL's best feature: 35 years of maturity. **Its worst**:
> its default config was written for hardware from 35 years ago.
> If you deploy to prod without tuning it, blame **yourself**, not Postgres."*
