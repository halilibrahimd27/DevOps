---
description: "Postgres observability stack guide: pg_stat_statements, postgres-exporter, slow query log, and replication monitoring — with concrete alert and dashboard examples."
tags:
  - Databases
  - PostgreSQL
  - Observability
  - Monitoring
  - Prometheus
---
# Postgres Monitoring — Slow Query, Lock, Bloat, Replication

> *"Postgres seems to run 'like nothing's wrong' while it might actually
> be on fire in 5 different places: autovacuum is choking, there's
> index bloat, replication has lagged, idle conns are leaking, the
> lock chain is growing. **The fire you don't see doesn't go out.**"*

This guide covers a practical observability stack for Postgres —
pg_stat_statements, postgres-exporter, slow query log, replication
monitoring — with concrete alert examples and dashboard recommendations.

---

## 🎯 5 Dimensions to Measure

| Dimension | Why | Example metric |
|---|---|---|
| **Activity** | What's the DB doing? | conn count, qps, tx/s |
| **Performance** | Is it fast? | slow query, p99 latency |
| **Health** | Any errors? | deadlock, error rate, replication lag |
| **Capacity** | Close to the limit? | disk usage, conn count, lock |
| **Bloat** | Is vacuum running? | dead tuples, index bloat, table bloat |

---

## 🛠️ 1️⃣ pg_stat_statements — Query-Level Insight

```ini
# postgresql.conf
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = all
pg_stat_statements.save = on
```

```sql
-- Add in the DB
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

### Common queries
```sql
-- Slowest queries (mean time)
SELECT
  substring(query, 1, 80) AS query,
  calls,
  total_exec_time::int AS total_ms,
  mean_exec_time::int AS mean_ms,
  rows
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Total time consumption (hot queries)
SELECT
  substring(query, 1, 80) AS query,
  total_exec_time::int AS total_ms,
  calls,
  mean_exec_time::int AS mean_ms
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- Cache misses (disk-heavy)
SELECT
  substring(query, 1, 80) AS query,
  shared_blks_read AS blocks_from_disk,
  shared_blks_hit AS blocks_from_cache,
  100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_rate_pct
FROM pg_stat_statements
ORDER BY shared_blks_read DESC
LIMIT 20;

-- Highest temp file usage (work_mem insufficient)
SELECT
  substring(query, 1, 80) AS query,
  temp_blks_written AS temp_blocks
FROM pg_stat_statements
WHERE temp_blks_written > 0
ORDER BY temp_blks_written DESC
LIMIT 20;

-- Reset (for sampling)
SELECT pg_stat_statements_reset();
```

> 🔑 Queries with **`mean_exec_time` 100 ms+** are optimize candidates.
> If **`hit_rate_pct < 90%`**, you need more cache (work_mem or shared_buffers).

---

## 🛠️ 2️⃣ Slow Query Log

```ini
# postgresql.conf
log_min_duration_statement = 500ms   # log queries taking 500ms+
log_lock_waits = on                  # log queries waiting on locks
log_temp_files = 0                   # log queries that create temp files
log_autovacuum_min_duration = 0      # autovacuum activity
log_line_prefix = '%m [%p] %q%u@%d/%a '
```

### Log analysis: pgBadger
```bash
# /var/log/postgresql/postgresql-*.log → HTML report
pgbadger -j 4 -o /var/www/pgbadger/report.html /var/log/postgresql/*.log
```

→ Slow query rank, hour-of-day breakdown, lock graph.

### Loki integration
```yaml
# promtail config
scrape_configs:
  - job_name: postgresql
    static_configs:
      - targets: [localhost]
        labels:
          job: postgresql
          __path__: /var/log/postgresql/*.log
    pipeline_stages:
      - regex:
          expression: '(?P<timestamp>\S+ \S+ \S+) \[(?P<pid>\d+)\] (?P<user>\S+)@(?P<db>\S+)/(?P<app>\S*) (?P<message>.*)'
      - labels:
          db: db
          user: user
          app: app
```

→ In Grafana: `{job="postgresql"} |= "duration:"`

---

## 🛠️ 3️⃣ postgres-exporter (Prometheus)

```bash
helm install postgres-exporter prometheus-community/prometheus-postgres-exporter \
  -n monitoring \
  --set config.datasource.uri=<DB_HOST>:5432 \
  --set config.datasource.user=postgres_exporter \
  --set config.datasource.passwordSecret.name=postgres-exporter-creds \
  --set config.datasource.passwordSecret.key=password \
  --set config.datasource.sslmode=require \
  --set serviceMonitor.enabled=true
```

### Custom queries — more detail
```yaml
# postgres-exporter custom-queries.yaml
pg_stat_statements:
  query: |
    SELECT
      datname,
      substring(query, 1, 100) as query,
      calls,
      total_exec_time::float8 as total_ms,
      mean_exec_time::float8 as mean_ms,
      rows
    FROM pg_stat_statements
    JOIN pg_database ON pg_database.oid = pg_stat_statements.dbid
    WHERE calls > 100
    ORDER BY mean_exec_time DESC
    LIMIT 100
  master: true
  metrics:
    - datname: {usage: "LABEL"}
    - query: {usage: "LABEL"}
    - calls: {usage: "COUNTER"}
    - total_ms: {usage: "COUNTER"}
    - mean_ms: {usage: "GAUGE"}

pg_replication_lag:
  query: |
    SELECT
      application_name,
      EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()))::int AS lag_seconds
    FROM pg_stat_replication
  metrics:
    - application_name: {usage: "LABEL"}
    - lag_seconds: {usage: "GAUGE"}

pg_table_bloat:
  query: |
    SELECT
      schemaname || '.' || tablename AS table,
      pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)::bigint) AS total_size,
      n_dead_tup,
      n_live_tup,
      CASE WHEN n_live_tup > 0
        THEN round(100 * n_dead_tup::numeric / n_live_tup, 2)
        ELSE 0
      END AS bloat_pct
    FROM pg_stat_user_tables
    WHERE n_dead_tup > 1000
    ORDER BY n_dead_tup DESC
    LIMIT 20
  metrics:
    - table: {usage: "LABEL"}
    - n_dead_tup: {usage: "GAUGE"}
    - bloat_pct: {usage: "GAUGE"}
```

---

## 🚨 Key Alerts

```yaml
groups:
  - name: postgres
    rules:
      # Availability
      - alert: PostgresDown
        expr: pg_up == 0
        for: 1m
        labels: {severity: page}

      # Connection
      - alert: PostgresHighConnections
        expr: pg_stat_activity_count / pg_settings_max_connections > 0.8
        for: 5m
        labels: {severity: warn}

      # Replication
      - alert: PostgresReplicationLag
        expr: pg_replication_lag_seconds > 60
        for: 5m
        labels: {severity: page}
        annotations:
          summary: "Replica lag {{ $value }}s"

      - alert: PostgresStandbyDown
        expr: count(pg_replication_lag_seconds) < 1   # standby not visible
        for: 2m

      # Long-running
      - alert: PostgresLongRunningTransaction
        expr: pg_stat_activity_max_tx_duration > 600
        for: 5m
        annotations:
          summary: "10+ min tx running — may be blocking vacuum"

      # Lock
      - alert: PostgresLockWait
        expr: pg_locks_count{mode="ExclusiveLock"} > 10
        for: 2m

      - alert: PostgresDeadlocks
        expr: rate(pg_stat_database_deadlocks[5m]) > 0
        for: 1m

      # Vacuum
      - alert: PostgresAutovacuumDisabled
        expr: pg_settings_autovacuum != 1

      - alert: PostgresTableBloat
        expr: pg_table_bloat_pct > 50
        for: 30m
        annotations:
          summary: "{{ $labels.table }} bloat %{{ $value }}"

      # Disk
      - alert: PostgresDiskFullSoon
        expr: predict_linear(pg_database_size_bytes[6h], 24*3600) > pg_settings_max_database_size_bytes * 0.95
        for: 30m

      # Cache
      - alert: PostgresLowCacheHitRate
        expr: |
          sum(rate(pg_stat_database_blks_hit[5m]))
          /
          (sum(rate(pg_stat_database_blks_hit[5m])) + sum(rate(pg_stat_database_blks_read[5m]))) < 0.95
        for: 30m
        annotations:
          summary: "Cache hit rate below 95% — tune work_mem/shared_buffers"

      # Slow queries
      - alert: PostgresSlowQueryRate
        expr: rate(pg_stat_statements_mean_ms[5m]) > 100
        for: 10m
```

---

## 📊 Grafana Dashboards

### Recommended panels
1. **Activity overview**: conn count, qps, tx/s, active vs idle
2. **Performance**: p50/p95/p99 query latency, slow query top 10
3. **Replication**: lag per replica, WAL flush position
4. **Locks**: active locks count, lock wait events
5. **Vacuum**: autovacuum runs, dead tuples trend, table bloat
6. **Disk**: DB size, table size top 10, free space
7. **Cache**: hit rate, buffer cache usage
8. **Connections**: active/idle/idle-in-tx breakdown, conn per app

### Ready-made dashboards
- **postgres-exporter**: grafana.com/grafana/dashboards/9628
- **CloudNativePG**: cloudnative-pg.io
- **PgHero** (UI): github.com/ankane/pghero

---

## 🔍 Operational Query Cookbook

### Active queries
```sql
SELECT pid, state, age(now(), xact_start) AS tx_age,
       substring(query, 1, 100)
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY xact_start;
```

### Lock tree (who's waiting on whom)
```sql
SELECT
  blocked_locks.pid AS blocked_pid,
  blocked_activity.usename AS blocked_user,
  blocking_locks.pid AS blocking_pid,
  blocking_activity.usename AS blocking_user,
  blocked_activity.query AS blocked_query,
  blocking_activity.query AS blocking_query
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks
  ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
  AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
  AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

### Bloat estimate
```sql
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) AS total_size,
  n_dead_tup,
  n_live_tup,
  round(100 * n_dead_tup::numeric / nullif(n_live_tup, 0), 2) AS dead_pct,
  last_vacuum,
  last_autovacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 20;
```

### Index usage
```sql
-- Never-used indexes (drop candidates)
SELECT
  schemaname || '.' || relname AS table,
  indexrelname AS index,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
  idx_scan AS scans
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND NOT indisunique
  AND NOT indisprimary
ORDER BY pg_relation_size(indexrelid) DESC;
```

### Replication slot check
```sql
SELECT slot_name, active, restart_lsn,
  pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained_wal
FROM pg_replication_slots;
```

> ⚠️ **An inactive slot** accumulates WAL → disk full. If the slot isn't in use, `pg_drop_replication_slot()`.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Only a "DB up" check | Slow query, lock, bloat stay invisible | Multi-dimensional monitoring |
| No pg_stat_statements | No visibility into which query is slow | Extension default |
| No slow log | Forensics gap | log_min_duration_statement |
| No replication lag alert | Read replica stale data | Alert + dashboard |
| Ignoring bloat | Continuously growing dead tuples | Quarterly review + autovacuum tune |
| Inactive slots not cleaned up | WAL accumulates, disk full | Quarterly slot review |
| Accepting cache hit rate below 80% | Disk I/O bottleneck | shared_buffers + work_mem tune |
| `idle in transaction` leak stays invisible | Pool exhaustion | Activity dashboard |
| No long-running tx alert | Vacuum block | 10+ min tx → alert |
| No index usage analysis | Bloat from unused indexes | Quarterly index review |
| Slow query screenshot in Slack | Tracking is impossible | Issue + permanent fix |
| Generic Grafana dashboard | "Doesn't show our use case" | Custom + specific to your workload |

---

## 📋 Postgres Observability Checklist

```
[ ] pg_stat_statements extension enabled
[ ] log_min_duration_statement = 500ms
[ ] log_lock_waits = on
[ ] log_autovacuum_min_duration = 0
[ ] log_temp_files = 0
[ ] postgres-exporter Prometheus
[ ] Custom queries (slow, replication, bloat)
[ ] Slow log → Loki / SIEM
[ ] pgBadger report (weekly)
[ ] Grafana dashboard: activity + perf + replication + bloat
[ ] Alert: down, conn high, repl lag, deadlock, bloat, disk full
[ ] PgHero or equivalent UI (self-service for devs)
[ ] Quarterly: query review (top 20 mean time)
[ ] Quarterly: index review (unused + bloat)
[ ] Quarterly: replication slot review
[ ] Yearly: capacity planning (disk, conn count trend)
[ ] Backup: backup status metric + alert
```

---

## 📚 References

- **PostgreSQL Monitoring** — postgresql.org/docs/current/monitoring.html
- **pg_stat_statements** — postgresql.org/docs/current/pgstatstatements.html
- **postgres-exporter** — github.com/prometheus-community/postgres_exporter
- **pgBadger** — github.com/darold/pgbadger
- **PgHero** — github.com/ankane/pghero
- **CloudNativePG monitoring** — cloudnative-pg.io
- [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md)
- [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md)
- [`Connection-Pooling.md`](Connection-Pooling.md)
- [`11-SRE/Runbook-Template.md`](../11-SRE/Runbook-Template.md) — Postgres alert runbooks

---

> *"Postgres monitoring isn't at the level of **'shall we glance at
> CPU?'** Slow query, lock chain, replication slot, autovacuum —
> **5 separate dimensions** get watched continuously. You pay for the
> fire you didn't see with a SEV-1 at night."*
