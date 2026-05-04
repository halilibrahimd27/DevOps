# PostgreSQL Production Guide — Tuning, Pooling, Monitoring

> *"PostgreSQL'in default config'i bir RaspberryPi için yazılmış gibidir.
> Production sunucusunda **ilk hafta** tune edilmezse, 6 ay sonra
> 'niye yavaş' tartışması başlar."*

Bu rehber 2026 itibarıyla bir prod-grade PostgreSQL kurulumu için
kritik tuning, connection pooling, monitoring ve operational
konularını derler. Postgres 16/17 referans alır.

---

## 🎯 İlk Karar: Containerize, Managed, Bare-Metal?

| Senaryo | Tercih |
|---|---|
| Dev / staging | Container (docker-compose / StatefulSet) |
| Prod < 100 GB | K8s Operator (CloudNativePG, Zalando) |
| Prod 100 GB – 1 TB | Managed (RDS / CloudSQL / Aurora) |
| Prod > 1 TB IOPS-yoğun | Bare metal / dedicated VM + managed backup |
| Multi-region active-active | CockroachDB / YugabyteDB (Postgres değil!) |

> 🔑 **Kural:** "DB operasyonu **senin core competency'in** mi?" Cevap "hayır"
> ise managed servis. Vendor lock-in maliyeti, postgres DBA maaşının
> onda biri.

---

## ⚙️ `postgresql.conf` Tuning

> ⚠️ **`pgtune.leopard.in.ua`** ile başla, sonra workload'una göre tune et.
> Aşağıdaki değerler **16 GB RAM, 4 vCPU** referansı.

### Memory
```ini
# Total RAM × 25% — query buffer cache
shared_buffers = 4GB

# Per-query work memory — sıralama, hash join
# Total RAM × 25% / max_connections * 2
work_mem = 16MB

# Maintenance (VACUUM, CREATE INDEX) — Total RAM × 5%
maintenance_work_mem = 1GB

# OS file cache hint — Postgres'in OS cache'e güveni
effective_cache_size = 12GB

# WAL buffer
wal_buffers = 16MB
```

### Connections
```ini
max_connections = 100   # PgBouncer arkasında düşük tut

# Statement timeout — kötü query'leri öldür
statement_timeout = 60s
idle_in_transaction_session_timeout = 5min
lock_timeout = 30s
```

> 🔑 **Kural:** `max_connections` × `work_mem` ≤ `shared_buffers`. Aksi
> halde memory exhaustion riski.

### Checkpoint & WAL
```ini
# Checkpoint daha seyrek + smooth
checkpoint_timeout = 15min
checkpoint_completion_target = 0.9
max_wal_size = 4GB
min_wal_size = 1GB

# WAL replication için
wal_level = replica
max_wal_senders = 10
hot_standby = on
```

### Query Planner
```ini
random_page_cost = 1.1   # SSD için (HDD'de 4.0)
effective_io_concurrency = 200   # SSD/NVMe
default_statistics_target = 100   # plan kalitesi
```

### Logging (production observability için kritik)
```ini
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB

log_min_duration_statement = 500ms   # 500ms+ query'leri logla
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0   # tüm temp file'ları logla (work_mem yetersiz indikatörü)
log_autovacuum_min_duration = 0
log_line_prefix = '%m [%p] %q%u@%d/%a '
```

### Autovacuum (asla kapatma)
```ini
autovacuum = on   # ASLA off değil
autovacuum_max_workers = 4
autovacuum_naptime = 30s

# Hızlandır (default'lar bloat'a yol açar)
autovacuum_vacuum_scale_factor = 0.05   # tablo %5 büyüyünce vacuum
autovacuum_analyze_scale_factor = 0.02
autovacuum_vacuum_cost_limit = 1000
```

> 🚨 **`autovacuum = off`** = DB ölüm fermanı. Table bloat → query yavaşlar
> → cardinality kötü → daha çok bloat. Spiral.

---

## 🌊 Connection Pooling: PgBouncer

PostgreSQL connection = **process**. Her connection ~10 MB RAM.
`max_connections=500` = 5 GB sadece idle connection.

**PgBouncer**: 1 worker, binlerce client connection'ını birkaç DB connection'ına çoğaltır.

### Mod seçimi
| Mode | Kullanım | Limitler |
|---|---|---|
| **Session** | Default; client-conn = DB-conn lifetime | Pool tükenir, idle timeouts |
| **Transaction** | Connection transaction sonu serbest | **Çoğu app için en iyi** |
| **Statement** | Her statement sonu serbest | Multi-statement TX yasak |

> 🔑 **`pool_mode = transaction`** modern app için sweet spot.

### Config örneği
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

max_client_conn = 1000      # client'tan toplam max
max_db_connections = 50     # DB tarafına toplam max

# Timeout
server_idle_timeout = 600
server_lifetime = 3600
query_wait_timeout = 120

# TLS
server_tls_sslmode = require
client_tls_sslmode = require
```

### App tarafı
```
postgres://app:<PWD>@<PGBOUNCER_HOST>:6432/app?sslmode=require
```

> ⚠️ Transaction mode'da **prepared statements** sorun yaratır.
> Postgres 14+ ile `protocol-level` prepared statements PgBouncer'da
> destekleniyor (`max_prepared_statements`).

---

## 🔒 Security Baseline

### `pg_hba.conf`
```
# /etc/postgresql/<VER>/main/pg_hba.conf

# local connection (Unix socket)
local  all      all                            scram-sha-256

# local network — uygulama subnet'i
host   app      app           10.0.0.0/8       scram-sha-256

# replica
host   replication  replicator  10.0.0.0/8     scram-sha-256

# DENY everything else
host   all      all           0.0.0.0/0        reject
```

> 🚨 `host all all 0.0.0.0/0 trust` veya `md5` = **kapı açık bırakmak**.
> Production'da bu satır olmamalı.

### Role hijyeni
```sql
-- Superuser sadece DBA için, app değil
CREATE ROLE dba_team SUPERUSER;

-- App user — sadece kendi DB'sine, sadece gerekli table'lar
CREATE ROLE app LOGIN PASSWORD '<PWD>';
GRANT CONNECT ON DATABASE app TO app;
GRANT USAGE ON SCHEMA public TO app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app;

-- Migration için ayrı role
CREATE ROLE app_migrate LOGIN PASSWORD '<PWD>';
GRANT app TO app_migrate;
GRANT CREATE ON SCHEMA public TO app_migrate;
```

### Encryption
- **In transit**: TLS zorunlu (`pg_hba.conf` `hostssl`)
- **At rest**: Filesystem-level (LUKS) veya cloud KMS-backed disk
- **Sensitive columns**: pgcrypto veya app-side encryption

---

## 📊 Monitoring

### `pg_stat_statements` extension
```sql
-- postgresql.conf
shared_preload_libraries = 'pg_stat_statements'

-- DB'de
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

```sql
-- En yavaş query'ler
SELECT query, calls, total_exec_time, mean_exec_time, rows
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Toplam zamanın nereye gittiği
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

### Anahtar metrikler + alarmlar
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
-- Query 1+ saniye sürdü, log'a düşsün
ALTER SYSTEM SET log_min_duration_statement = '1s';
SELECT pg_reload_conf();
```

→ Log'lar Loki/Splunk'a ship edilir, dashboard'lara akar.

---

## 🚦 Index Hijyeni

### Eksik index tespiti
```sql
-- Sequential scan yapan tablolar
SELECT relname, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch
FROM pg_stat_user_tables
WHERE seq_scan > idx_scan
ORDER BY seq_tup_read DESC;
```

### Kullanılmayan index
```sql
-- Hiç kullanılmayan index'ler (drop adayı)
SELECT schemaname, relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

### Index bloat
```sql
-- pg_stat_progress_create_index sırasında REINDEX CONCURRENTLY
REINDEX INDEX CONCURRENTLY <INDEX_NAME>;
```

---

## 🛡️ HA Topolojisi

### Streaming Replication (basit)
```
PRIMARY ──WAL stream──▶ STANDBY-1 (sync, otomatik failover)
                    └──▶ STANDBY-2 (async, read replica)
```

### Auto-failover: Patroni
- **Patroni** = Postgres + DCS (etcd/Consul) + watchdog
- Primary down → standby promote'a geçer
- Detaylar: _`HA-Patroni-Stolon.md`_ *(yakında)*

### K8s Operator: CloudNativePG (önerilen)
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

> 🔑 **CloudNativePG** 2026'da en pragmatik K8s operator. HA + backup + monitoring + replication entegre.

---

## 📦 Backup Stratejisi

| Yöntem | RPO | Restore | Kullanım |
|---|---|---|---|
| `pg_dump` günde 1 | 24h | Yavaş | Dev / küçük |
| `pg_basebackup` | 1 gün | Hızlı | Tam DB image |
| **WAL-G + S3** | < 5 dk | PITR | **Çoğu prod sweet-spot** |
| **pgBackRest** | < 5 dk | Hızlı | Inkremental, büyük prod |
| Streaming replica + snapshot | 0 | Anlık | HA, en üst seviye |

### Test edilmeyen backup = backup değil
```bash
# Quarterly: backup'tan restore tatbikatı
1. Yeni instance ayağa kaldır
2. Son backup'ı restore et
3. Smoke test: schema tutarlı mı, row count makul mü, app bağlanıyor mu?
4. RTO ölçü
5. Postmortem: gap varsa düzelt
```

> ⚠️ **3-2-1 kuralı:** 3 kopya, 2 farklı medium, 1 off-site.
> Backup S3'te **versioned** + **MFA delete** açık.

---

## 🔄 Zero-Downtime Migration

> Detay: _`Zero-Downtime-Migrations.md`_ *(yakında)*.

### Expand/Contract pattern
```
1. EXPAND: yeni column ekle (default null)
2. App: çift yazma (eski + yeni column)
3. Backfill: eski → yeni veri kopyala
4. App: sadece yeni column'a yaz/oku
5. CONTRACT: eski column'u drop et
```

### Online schema change
- **gh-ost** (GitHub) — MySQL için tasarlandı, postgres alternative `pg_repack`
- **`pg_repack`**: lock'suz tablo refactor

```bash
# Tablo bloat'ı temizle, lock'suz
pg_repack -d app -t large_table
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Default `postgresql.conf` prod'da | RaspberryPi optimize | pgtune + workload-tune |
| `max_connections=500` PgBouncer'sız | RAM exhaustion | PgBouncer + düşük max_connections |
| `superuser` ile uygulama bağlanıyor | Yetki ihlali, audit kayıp | App-specific role, least privilege |
| `autovacuum = off` | Bloat → DB ölür | Asla kapatma |
| Backup test edilmemiş | Kriz anında çalışmaz | Quarterly restore drill |
| `pg_dump` 500 GB DB'de | Saatler sürer, transaction tutarsız | WAL-G veya pgBackRest |
| Index strategy yok | Sequential scan'ler, query yavaş | pg_stat_user_indexes review |
| Kullanılmayan index 50+ | Write amplification | Quarterly cleanup |
| Replication lag monitor edilmez | Read replica stale veri verir | Alert + dashboard |
| Schema migration unattended deploy | `DROP COLUMN` prod ortasında | Expand/contract pattern |
| DB internet'e açık | Brute force | private network only |
| TLS yok | Sniffer şifre okur | `hostssl` enforce |
| Aynı DB tüm app'ler | Cross-tenant query, SLO ihlali | DB-per-service veya schema-per-service |
| Connection retry sonsuz | DB down → app DDoS yapar DB'ye | Exponential backoff + jitter |

---

## 📋 Production Hazırlık Checklist

```
[ ] postgresql.conf workload'a tune
[ ] PgBouncer (transaction mode) kurulu
[ ] pg_hba.conf: 0.0.0.0/0 yok, sadece app subnet
[ ] TLS enforce (hostssl)
[ ] App user least privilege; superuser sadece DBA
[ ] autovacuum aktif, hızlandırılmış
[ ] pg_stat_statements extension
[ ] postgres-exporter + Prometheus + alarmlar
[ ] Slow query log → SIEM/Loki
[ ] HA: streaming replica (sync + async)
[ ] Patroni veya CloudNativePG ile auto-failover
[ ] Backup: WAL-G veya pgBackRest, S3 versioned + MFA delete
[ ] Quarterly restore drill
[ ] Index review (eksik + kullanılmayan)
[ ] Migration: expand/contract pattern, manuel review
[ ] Connection retry: exponential backoff + jitter (app-side)
[ ] DR plan: primary down → standby promote ne kadar?
[ ] Capacity planning: disk/conn/CPU trend
[ ] PII encryption: pgcrypto veya app-side
[ ] Audit log: pgaudit (ya da pg_stat_activity'den ship)
[ ] Logical replication (read-replica → analytics)
```

---

## 📚 Referanslar

- **PostgreSQL Documentation** — postgresql.org/docs
- **CloudNativePG** — cloudnative-pg.io
- **Patroni** — github.com/zalando/patroni
- **PgBouncer** — pgbouncer.org
- **pgtune** — pgtune.leopard.in.ua
- **WAL-G** — github.com/wal-g/wal-g
- **pgBackRest** — pgbackrest.org
- _`Backup-Restore-Patterns.md`_ *(yakında)*
- _`HA-Patroni-Stolon.md`_ *(yakında)*
- _`Zero-Downtime-Migrations.md`_ *(yakında)*
- _`Connection-Pooling.md`_ *(yakında)*
- _`Monitoring-Postgres.md`_ *(yakında)*

---

> *"PostgreSQL'in en iyi feature'ı: 35 yıllık olgunluk. **En kötüsü**:
> default config'inin 35 yıl önceki donanım için yazılmış olması.
> Tune etmeyen prod'a alıyorsa, Postgres'i değil **kendini** suçlasın."*
