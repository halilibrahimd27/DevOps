# Postgres Monitoring — Slow Query, Lock, Bloat, Replication

> *"Postgres 'bir şey yok gibi' çalışırken aslında 5 farklı yerde yangın
> çıkıyor olabilir: autovacuum boğuldu, index bloat var, replication
> gecikti, idle conn sızıyor, lock chain büyüyor. **Görmediğin yangın
> sönmez.**"*

Bu rehber Postgres için pratik observability stack'i — pg_stat_statements,
postgres-exporter, slow query log, replication monitoring — somut alarm
örnekleri ve dashboard önerileriyle.

---

## 🎯 Ölçülecek 5 Boyut

| Boyut | Niye | Örnek metrik |
|---|---|---|
| **Aktivite** | DB ne yapıyor? | conn count, qps, tx/s |
| **Performans** | Hızlı mı? | slow query, p99 latency |
| **Sağlık** | Hata var mı? | deadlock, error rate, replication lag |
| **Kapasite** | Sınıra yakın mı? | disk usage, conn count, lock |
| **Bloat** | Vacuum çalışıyor mu? | dead tuples, index bloat, table bloat |

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
-- DB'de ekle
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

### Yaygın query'ler
```sql
-- En yavaş query'ler (mean time)
SELECT
  substring(query, 1, 80) AS query,
  calls,
  total_exec_time::int AS total_ms,
  mean_exec_time::int AS mean_ms,
  rows
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Toplam zaman tüketimi (hot query'ler)
SELECT
  substring(query, 1, 80) AS query,
  total_exec_time::int AS total_ms,
  calls,
  mean_exec_time::int AS mean_ms
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- Cache miss yapanlar (disk-heavy)
SELECT
  substring(query, 1, 80) AS query,
  shared_blks_read AS blocks_from_disk,
  shared_blks_hit AS blocks_from_cache,
  100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_rate_pct
FROM pg_stat_statements
ORDER BY shared_blks_read DESC
LIMIT 20;

-- En çok temp file kullananlar (work_mem yetersiz)
SELECT
  substring(query, 1, 80) AS query,
  temp_blks_written AS temp_blocks
FROM pg_stat_statements
WHERE temp_blks_written > 0
ORDER BY temp_blks_written DESC
LIMIT 20;

-- Reset (örnekleme için)
SELECT pg_stat_statements_reset();
```

> 🔑 **`mean_exec_time` 100 ms+** olan query'ler optimize candidates.
> **`hit_rate_pct < 90%`** ise cache gerek var (work_mem veya shared_buffers).

---

## 🛠️ 2️⃣ Slow Query Log

```ini
# postgresql.conf
log_min_duration_statement = 500ms   # 500ms+ query'leri logla
log_lock_waits = on                  # lock bekleyen query'leri logla
log_temp_files = 0                   # temp file oluşan query'leri logla
log_autovacuum_min_duration = 0      # autovacuum aktivitesi
log_line_prefix = '%m [%p] %q%u@%d/%a '
```

### Log analizi: pgBadger
```bash
# /var/log/postgresql/postgresql-*.log → HTML rapor
pgbadger -j 4 -o /var/www/pgbadger/report.html /var/log/postgresql/*.log
```

→ Slow query rank, hour-of-day breakdown, lock graph.

### Loki entegrasyonu
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

→ Grafana'da `{job="postgresql"} |= "duration:"`

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

### Custom queries — daha detaylı
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

## 🚨 Anahtar Alarmlar

```yaml
groups:
  - name: postgres
    rules:
      # Erişilebilirlik
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
        expr: count(pg_replication_lag_seconds) < 1   # standby görünmüyor
        for: 2m

      # Long-running
      - alert: PostgresLongRunningTransaction
        expr: pg_stat_activity_max_tx_duration > 600
        for: 5m
        annotations:
          summary: "10+ dk tx çalışıyor — vacuum block ediyor olabilir"

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
          summary: "Cache hit rate %95'in altında — work_mem/shared_buffers tune"

      # Slow queries
      - alert: PostgresSlowQueryRate
        expr: rate(pg_stat_statements_mean_ms[5m]) > 100
        for: 10m
```

---

## 📊 Grafana Dashboard'lar

### Önerilen panels
1. **Activity overview**: conn count, qps, tx/s, active vs idle
2. **Performance**: p50/p95/p99 query latency, slow query top 10
3. **Replication**: lag per replica, WAL flush position
4. **Locks**: active locks count, lock wait events
5. **Vacuum**: autovacuum runs, dead tuples trend, table bloat
6. **Disk**: DB size, table size top 10, free space
7. **Cache**: hit rate, buffer cache usage
8. **Connections**: active/idle/idle-in-tx breakdown, conn per app

### Hazır dashboard
- **postgres-exporter**: grafana.com/grafana/dashboards/9628
- **CloudNativePG**: cloudnative-pg.io
- **PgHero** (UI): github.com/ankane/pghero

---

## 🔍 Operasyonel Query Cookbook

### Aktif query'ler
```sql
SELECT pid, state, age(now(), xact_start) AS tx_age,
       substring(query, 1, 100)
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY xact_start;
```

### Lock tree (kim kimi bekliyor)
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

### Bloat tahmini
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

### Index kullanımı
```sql
-- Hiç kullanılmamış index'ler (drop adayı)
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

### Replication slot kontrol
```sql
SELECT slot_name, active, restart_lsn,
  pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained_wal
FROM pg_replication_slots;
```

> ⚠️ **Inactive slot** WAL biriktirir → disk full. Slot kullanılmıyorsa `pg_drop_replication_slot()`.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Sadece "DB up" check | Slow query, lock, bloat görünmez | Multi-dimensional monitoring |
| pg_stat_statements yok | Hangi query yavaş bilinmez | Extension default |
| Slow log yok | Forensic eksik | log_min_duration_statement |
| Replication lag alert yok | Read replica stale data | Alert + dashboard |
| Bloat ignore | Sürekli growing dead tuples | Quarterly review + autovacuum tune |
| Inactive slot temizlenmiyor | WAL birikir, disk full | Quarterly slot review |
| Cache hit rate 80%'in altı kabul | Disk I/O bottleneck | shared_buffers + work_mem tune |
| `idle in transaction` sızıntısı görünmüyor | Pool exhaustion | Activity dashboard |
| Long-running tx alert yok | Vacuum block | 10+ dk tx → alarm |
| Index kullanım analizi yok | Bloat unused indexes | Quarterly index review |
| Slow query ekran görüntüsü Slack'te | Tracking imkansız | Issue + permanent fix |
| Generic Grafana dashboard | "Bizim use-case'i göstermez" | Custom + specific to your workload |

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
[ ] pgBadger raporu (haftalık)
[ ] Grafana dashboard: activity + perf + replication + bloat
[ ] Alert: down, conn high, repl lag, deadlock, bloat, disk full
[ ] PgHero veya equivalent UI (devs için self-service)
[ ] Quarterly: query review (top 20 mean time)
[ ] Quarterly: index review (kullanılmayan + bloat)
[ ] Quarterly: replication slot review
[ ] Yearly: capacity planning (disk, conn count trend)
[ ] Backup: backup status metric + alert
```

---

## 📚 Referanslar

- **PostgreSQL Monitoring** — postgresql.org/docs/current/monitoring.html
- **pg_stat_statements** — postgresql.org/docs/current/pgstatstatements.html
- **postgres-exporter** — github.com/prometheus-community/postgres_exporter
- **pgBadger** — github.com/darold/pgbadger
- **PgHero** — github.com/ankane/pghero
- **CloudNativePG monitoring** — cloudnative-pg.io
- [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md)
- [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md)
- [`Connection-Pooling.md`](Connection-Pooling.md)
- [`11-SRE/Runbook-Template.md`](../11-SRE/Runbook-Template.md) — Postgres alert runbook'ları

---

> *"Postgres monitoring **'CPU bakar mıyız?'** seviyesinde değildir.
> Slow query, lock chain, replication slot, autovacuum — **5 ayrı
> boyut** sürekli gözlemlenir. Görmediğin yangının bedelini gece SEV-1
> ile ödersin."*
