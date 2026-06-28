---
description: "Postgres connection pooling rehberi: PgBouncer pratikleri, pgcat ve app-side pooling alternatifleri, pool exhaustion sorunu ve doğru pool size hesabı."
tags:
  - Databases
  - PostgreSQL
  - Performance
  - Networking
---
# Connection Pooling — Postgres'in En Sık İhmal Edilen Tarafı

> *"Postgres connection = process. 10 MB RAM. 500 connection = 5 GB.
> 'DB yavaşladı' diyen ekiplerin %40'ı aslında **pool exhaustion**
> yaşıyor. Connection sızıntısı, **slow query'den daha sinsidir**."*

Bu rehber Postgres connection pooling — özellikle PgBouncer — pratik
detaylarını, modern alternatif **pgcat** ve **app-side pooling**
seçeneklerini, ve "doğru pool size" sorusunun cevabını verir.

---

## 🎯 Niye Pool?

### Postgres connection ekonomisi
```
1 connection = 1 OS process
                 ~10 MB RAM
                 ~1 ms forking time

500 connection = 5 GB RAM (idle bile)
              = OS scheduler stres
              = lock contention
```

### App tarafı problemi
```
[App pod 1]  ── 50 conn ──┐
[App pod 2]  ── 50 conn ──┤
[App pod 3]  ── 50 conn ──┤  → 500 conn → DB OOM
[...]                      │
[App pod 10] ── 50 conn ──┘
```

### Pooler ile çözüm
```
[App pod 1] ── 50 conn ──┐
[App pod 2] ── 50 conn ──┤  → [PgBouncer] ── 25 conn ──▶ Postgres
[App pod 3] ── 50 conn ──┤
[...]                     │     (binlerce client → onlarca DB conn)
[App pod 10] ─ 50 conn ──┘
```

> 🔑 **Pool 1 worker, binlerce client conn'ı onlarca DB conn'ına çoğaltır.**

---

## 🛠️ PgBouncer — De-Facto Standart

### Pool mode seçimi

| Mode | Açıklama | Limit |
|---|---|---|
| **Session** | Default; client-conn = DB-conn lifetime | Pool tükenir, idle timeout zor |
| **Transaction** | Conn transaction sonu serbest | **Çoğu app için en iyi** |
| **Statement** | Her statement sonu serbest | Multi-statement TX yasak |

### Transaction mode (önerilen)

```ini
# pgbouncer.ini
[databases]
app = host=<DB_HOST> port=5432 dbname=app

[pgbouncer]
listen_addr = *
listen_port = 6432

# Auth
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

# Mode
pool_mode = transaction

# Pool sizing
default_pool_size = 25
min_pool_size = 5
reserve_pool_size = 5
reserve_pool_timeout = 5

max_client_conn = 1000      # client'tan toplam max
max_db_connections = 50     # DB tarafına toplam max

# Timeout
server_idle_timeout = 600    # 10 dk idle conn drop
server_lifetime = 3600       # 1 saat sonra recycle
query_wait_timeout = 120

# TLS
server_tls_sslmode = require
client_tls_sslmode = require
client_tls_cert_file = /etc/pgbouncer/server.crt
client_tls_key_file = /etc/pgbouncer/server.key

# Logging
log_connections = 1
log_disconnections = 1
log_pooler_errors = 1
log_stats = 1
stats_period = 60

# Admin
admin_users = pgbouncer_admin
stats_users = pgbouncer_stats
```

### `userlist.txt`
```
"app" "SCRAM-SHA-256$..."
"replica" "SCRAM-SHA-256$..."
```

> 🔑 **MD5 deprecated** — mutlaka SCRAM-SHA-256.

### Transaction mode'da prepared statements
**Sorun**: Transaction mode'da prepared statement next-conn'a taşınmaz.

**Çözüm**:
- Postgres 14+ ve PgBouncer 1.21+ → `max_prepared_statements > 0` ile **protocol-level prepared statements** desteği
- Ya da app tarafı: `prepareThreshold=0` (JDBC), `prepare=False` (psycopg)

```ini
# pgbouncer.ini
max_prepared_statements = 100
```

---

## 📐 Pool Size Hesaplama — En Sık Yanlış

### Klasik formül (Brett Wooldridge — HikariCP)
```
connections = ((core_count × 2) + effective_spindle_count)
```
- `core_count`: DB sunucusunun CPU çekirdek sayısı
- `effective_spindle_count`: SSD = 0, HDD = disk sayısı

**Örnek**: 16-core SSD DB → 16 × 2 + 0 = **32 connection**.

### Pratik gerçeklik
- Tüm app'ler için **toplam** 32 değil, dağıt
- App başına: 25 (PgBouncer arkasında zaten multiplexing var)
- DB tarafı: `max_connections = 100` + buffer (admin, monitoring)

### Pool sizing Tepkisel olarak
```promql
# Pool kullanımı %80+ ise scale up
pgbouncer_pool_used_clients / pgbouncer_pool_max_clients > 0.8

# Server side waiting clients
pgbouncer_pool_waiting_clients > 0
```

---

## ⚖️ PgBouncer vs pgcat vs Odyssey

| Özellik | **PgBouncer** | **pgcat** | **Odyssey** |
|---|---|---|---|
| Dil | C | Rust | C |
| Yaş | 2007, mature | 2022, modern | Yandex, 2019 |
| TLS | ✅ | ✅ | ✅ |
| Transaction mode | ✅ | ✅ | ✅ |
| Sharding | ❌ | ✅ Native | ✅ |
| Read replica routing | ❌ | ✅ | ✅ |
| Prepared statements (TX mode) | ⚠️ Postgres 14+ | ✅ Native | ✅ |
| Performance | İyi | Mükemmel (multi-thread) | Mükemmel |
| Topluluk | Geniş | Yükselişte | Niche |
| 2026 öneri | ✅ Stable | ✅ Modern, sharding | ✅ Yandex/Postgres pro |

> 🔑 **Stable + yaygın → PgBouncer**. Sharding/multi-replica routing → **pgcat**.

---

## 🌐 pgcat — Modern Alternatif

### Niye?
- Multi-threaded (PgBouncer single-threaded)
- Native sharding (key-based)
- Read/write split (primary vs replica)
- Native prepared statement passthrough

### Config
```toml
# pgcat.toml
[general]
host = "0.0.0.0"
port = 6432
admin_username = "admin"
admin_password = "<PWD>"

[pools.app]
pool_mode = "transaction"
default_role = "any"
query_parser_enabled = true

[pools.app.users.0]
username = "app"
password = "<PWD>"
pool_size = 25

[pools.app.shards.0]
servers = [
  ["primary-host", 5432, "primary"],
  ["replica-1-host", 5432, "replica"],
  ["replica-2-host", 5432, "replica"],
]
database = "app"
```

```python
# App tarafı: query'ye göre routing
# SELECT → replica
# INSERT/UPDATE/DELETE → primary
```

---

## 📦 K8s'de PgBouncer Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pgbouncer
  namespace: postgres
spec:
  replicas: 3
  selector:
    matchLabels: {app: pgbouncer}
  template:
    metadata:
      labels: {app: pgbouncer}
    spec:
      containers:
        - name: pgbouncer
          image: edoburu/pgbouncer:<VERSION>
          ports:
            - containerPort: 6432
          env:
            - name: DB_HOST
              value: postgres-prod-rw.postgres.svc
            - name: DB_USER
              valueFrom: {secretKeyRef: {name: pgbouncer-creds, key: user}}
            - name: DB_PASSWORD
              valueFrom: {secretKeyRef: {name: pgbouncer-creds, key: password}}
            - name: POOL_MODE
              value: transaction
            - name: DEFAULT_POOL_SIZE
              value: "25"
            - name: MAX_CLIENT_CONN
              value: "1000"
          resources:
            requests: {cpu: 100m, memory: 128Mi}
            limits: {cpu: 500m, memory: 256Mi}
          livenessProbe:
            tcpSocket: {port: 6432}
          readinessProbe:
            tcpSocket: {port: 6432}
---
apiVersion: v1
kind: Service
metadata:
  name: pgbouncer
  namespace: postgres
spec:
  selector: {app: pgbouncer}
  ports:
    - port: 5432
      targetPort: 6432
```

App config:
```
DATABASE_URL=postgres://app:<PWD>@pgbouncer.postgres.svc:5432/app
```

> 🔑 **App PgBouncer ile konuşur** (5432). PgBouncer DB ile konuşur (5432). 3 replica HA için.

---

## 📊 Monitoring + Alerting

### PgBouncer admin console
```bash
psql -h pgbouncer-host -p 6432 -U pgbouncer_admin pgbouncer

pgbouncer=# SHOW POOLS;
# database | user | cl_active | cl_waiting | sv_active | sv_idle | sv_used | maxwait | pool_mode
# app      | app  | 50        | 0          | 25        | 0       | 0       | 0       | transaction

pgbouncer=# SHOW STATS;
# total_xact_count | total_query_count | ...

pgbouncer=# SHOW CLIENTS;
pgbouncer=# SHOW SERVERS;
```

### Prometheus exporter
```yaml
# prometheus-pgbouncer-exporter
- job_name: pgbouncer
  static_configs:
    - targets: [pgbouncer-exporter:9127]
```

### Anahtar metrikler
```promql
# Pool kullanım oranı
pgbouncer_pool_used_clients / pgbouncer_pool_max_clients

# Bekleyen client (pool tükendi)
pgbouncer_pool_waiting_clients

# Query wait süresi
pgbouncer_pool_max_wait_seconds

# DB conn count (DB tarafında ne kadar açık)
pgbouncer_databases_connections

# Server idle (boş duran conn)
pgbouncer_pool_used_servers - pgbouncer_pool_active_servers
```

### Alert
```yaml
groups:
  - name: pgbouncer
    rules:
      - alert: PgBouncerHighPoolUsage
        expr: pgbouncer_pool_used_clients / pgbouncer_pool_max_clients > 0.8
        for: 5m

      - alert: PgBouncerClientsWaiting
        expr: pgbouncer_pool_waiting_clients > 5
        for: 2m

      - alert: PgBouncerHighWait
        expr: pgbouncer_pool_max_wait_seconds > 1
        for: 1m
```

---

## 🚦 App-Side Pooling

PgBouncer arkasındayken **app pooling de**'ye gerek var mı?

| Senaryo | Tercih |
|---|---|
| Stateless API (HTTP) | App pool boyutu küçük (5-10), PgBouncer multiplexing yapar |
| Stateful (websocket, long-lived conn) | App pool yetersiz; PgBouncer **transaction mode** kritik |
| Serverless (Lambda) | Her invocation yeni conn yapar — RDS Proxy / PgBouncer şart |

### App pool ayarı (örn: HikariCP, JDBC)
```properties
# spring.datasource.hikari.*
maximum-pool-size=10
minimum-idle=2
connection-timeout=30000
idle-timeout=600000
max-lifetime=1800000

# PgBouncer'a yönelik:
data-source-properties.prepareThreshold=0   # transaction mode için
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| App'ler direkt DB'ye bağlanır | Conn count fazlası | PgBouncer arkasında |
| `max_connections=500` PgBouncer'sız | RAM exhaustion | PgBouncer + max_connections düşük |
| Session mode default'a güven | Pool tükenmesi yaygın | Transaction mode |
| Transaction mode + prepared statements (eski) | Statement kayıp | Postgres 14+ + protocol-level |
| `pool_mode = statement` | Multi-statement tx yasak | Transaction mode tercih |
| Tek PgBouncer instance | SPOF | 3+ replica |
| PgBouncer auth `md5` | Deprecated | scram-sha-256 |
| App pool boyutu = max conn DB | PgBouncer faydası kayıp | App pool 5-10, PgBouncer multiplexing |
| Server idle timeout sonsuz | Idle conn DB'yi tıkar | 600s |
| Monitoring yok | "DB yavaşladı" → ne sebep belirsiz | exporter + alert |
| `idle in transaction` connection sızıntı | Pool tükenir | App'te tx commit/rollback hijyen |
| TLS yok | Sniffer şifre okur | server_tls + client_tls |

---

## 📋 Connection Pooling Checklist

```
[ ] PgBouncer (veya pgcat) kurulu, 3+ replica
[ ] Transaction mode
[ ] SCRAM-SHA-256 auth
[ ] TLS server + client
[ ] Pool sizing: 25-50 default per pool
[ ] max_client_conn yüksek (1000+)
[ ] max_db_connections düşük (DB max_connections altında)
[ ] App pool boyutu küçük (5-10)
[ ] Server idle timeout 600s
[ ] Server lifetime 3600s
[ ] Prometheus exporter + alert
[ ] Pool usage dashboard
[ ] App-side: tx commit/rollback hijyen
[ ] Postgres 14+ + max_prepared_statements (TX mode için)
[ ] PgBouncer pod'lar farklı node'lar (anti-affinity)
[ ] HAProxy / Service ile LB
[ ] Quarterly: pool sizing review
```

---

## 📚 Referanslar

- **PgBouncer Docs** — pgbouncer.org
- **pgcat** — github.com/postgresml/pgcat
- **Odyssey** — github.com/yandex/odyssey
- **HikariCP Pool Sizing** — github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing
- **AWS RDS Proxy** — aws.amazon.com/rds/proxy/
- [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md)
- [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md)
- [`Monitoring-Postgres.md`](Monitoring-Postgres.md)
- [`11-SRE/Runbook-Template.md`](../11-SRE/Runbook-Template.md) — pool exhaustion runbook

---

> *"Connection pool **tasarım kararı**dır, çalıştırma değil. Pool olmayan
> sistem 'sorunsuz çalışıyor' diyebilir — bir traffic spike geldiğinde
> ekip **pool exhaustion incident'ında** olur, **6 ay önceki tasarım
> kararının** bedelini öderken."*
