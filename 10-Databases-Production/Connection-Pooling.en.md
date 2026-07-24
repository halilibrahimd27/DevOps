---
description: "Postgres connection pooling guide: PgBouncer practices, the pgcat and app-side pooling alternatives, the pool exhaustion problem, and how to calculate the right pool size."
tags:
  - Databases
  - PostgreSQL
  - Performance
  - Networking
---
# Connection Pooling — Postgres's Most Neglected Side

> *"Postgres connection = process. 10 MB RAM. 500 connections = 5 GB.
> 40% of teams that say 'the DB got slow' are actually hitting
> **pool exhaustion**. A connection leak is **sneakier than a slow
> query**."*

This guide covers the practical details of Postgres connection
pooling — PgBouncer in particular — the modern alternatives **pgcat**
and **app-side pooling**, and the answer to "what's the right pool
size?"

---

## 🎯 Why Pool?

### Postgres connection economics
```
1 connection = 1 OS process
                 ~10 MB RAM
                 ~1 ms forking time

500 connections = 5 GB RAM (even idle)
              = OS scheduler stress
              = lock contention
```

### The app-side problem
```
[App pod 1]  ── 50 conn ──┐
[App pod 2]  ── 50 conn ──┤
[App pod 3]  ── 50 conn ──┤  → 500 conn → DB OOM
[...]                      │
[App pod 10] ── 50 conn ──┘
```

### The pooler solution
```
[App pod 1] ── 50 conn ──┐
[App pod 2] ── 50 conn ──┤  → [PgBouncer] ── 25 conn ──▶ Postgres
[App pod 3] ── 50 conn ──┤
[...]                     │     (thousands of clients → dozens of DB conns)
[App pod 10] ─ 50 conn ──┘
```

> 🔑 **A pool multiplies 1 worker into dozens of DB conns for thousands of client conns.**

---

## 🛠️ PgBouncer — The De Facto Standard

### Choosing a pool mode

| Mode | Description | Limit |
|---|---|---|
| **Session** | Default; client-conn = DB-conn lifetime | Pool runs dry, idle timeout is hard to tune |
| **Transaction** | Conn freed at end of transaction | **Best fit for most apps** |
| **Statement** | Freed after every statement | Multi-statement TX forbidden |

### Transaction mode (recommended)

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

max_client_conn = 1000      # total max from clients
max_db_connections = 50     # total max toward the DB

# Timeout
server_idle_timeout = 600    # drop idle conn after 10 min
server_lifetime = 3600       # recycle after 1 hour
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

> 🔑 **MD5 is deprecated** — always use SCRAM-SHA-256.

### Prepared statements in transaction mode
**Problem**: in transaction mode, a prepared statement doesn't carry over to the next conn.

**Solution**:
- Postgres 14+ and PgBouncer 1.21+ → **protocol-level prepared statement** support via `max_prepared_statements > 0`
- Or on the app side: `prepareThreshold=0` (JDBC), `prepare=False` (psycopg)

```ini
# pgbouncer.ini
max_prepared_statements = 100
```

---

## 📐 Pool Size Calculation — The Most Common Mistake

### The classic formula (Brett Wooldridge — HikariCP)
```
connections = ((core_count × 2) + effective_spindle_count)
```
- `core_count`: number of CPU cores on the DB server
- `effective_spindle_count`: SSD = 0, HDD = number of disks

**Example**: 16-core SSD DB → 16 × 2 + 0 = **32 connections**.

### Practical reality
- Not **32 total** across all apps — spread it out
- Per app: 25 (multiplexing already happens behind PgBouncer)
- DB side: `max_connections = 100` + buffer (admin, monitoring)

### Reactive pool sizing
```promql
# Scale up if pool usage is 80%+
pgbouncer_pool_used_clients / pgbouncer_pool_max_clients > 0.8

# Server side waiting clients
pgbouncer_pool_waiting_clients > 0
```

---

## ⚖️ PgBouncer vs pgcat vs Odyssey

| Feature | **PgBouncer** | **pgcat** | **Odyssey** |
|---|---|---|---|
| Language | C | Rust | C |
| Age | 2007, mature | 2022, modern | Yandex, 2019 |
| TLS | ✅ | ✅ | ✅ |
| Transaction mode | ✅ | ✅ | ✅ |
| Sharding | ❌ | ✅ Native | ✅ |
| Read replica routing | ❌ | ✅ | ✅ |
| Prepared statements (TX mode) | ⚠️ Postgres 14+ | ✅ Native | ✅ |
| Performance | Good | Excellent (multi-thread) | Excellent |
| Community | Wide | Growing | Niche |
| 2026 recommendation | ✅ Stable | ✅ Modern, sharding | ✅ Yandex/Postgres pro |

> 🔑 **Stable + widespread → PgBouncer**. Sharding/multi-replica routing → **pgcat**.

---

## 🌐 pgcat — A Modern Alternative

### Why?
- Multi-threaded (PgBouncer is single-threaded)
- Native sharding (key-based)
- Read/write split (primary vs replica)
- Native prepared-statement passthrough

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
# App side: routing based on the query
# SELECT → replica
# INSERT/UPDATE/DELETE → primary
```

---

## 📦 PgBouncer Deployment on K8s

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

> 🔑 **The app talks to PgBouncer** (5432). PgBouncer talks to the DB (5432). 3 replicas for HA.

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

### Key metrics
```promql
# Pool usage ratio
pgbouncer_pool_used_clients / pgbouncer_pool_max_clients

# Waiting clients (pool exhausted)
pgbouncer_pool_waiting_clients

# Query wait time
pgbouncer_pool_max_wait_seconds

# DB conn count (how many are open on the DB side)
pgbouncer_databases_connections

# Server idle (conns sitting unused)
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

Sitting behind PgBouncer, do you still need **app-side pooling too**?

| Scenario | Preference |
|---|---|
| Stateless API (HTTP) | Small app pool (5-10), PgBouncer does the multiplexing |
| Stateful (websocket, long-lived conn) | App pool falls short; PgBouncer **transaction mode** is critical |
| Serverless (Lambda) | Every invocation opens a new conn — RDS Proxy / PgBouncer mandatory |

### App pool settings (e.g. HikariCP, JDBC)
```properties
# spring.datasource.hikari.*
maximum-pool-size=10
minimum-idle=2
connection-timeout=30000
idle-timeout=600000
max-lifetime=1800000

# For PgBouncer:
data-source-properties.prepareThreshold=0   # for transaction mode
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Apps connect straight to the DB | Excess conn count | Put PgBouncer in front |
| `max_connections=500` without PgBouncer | RAM exhaustion | PgBouncer + lower max_connections |
| Trusting the session-mode default | Pool exhaustion is common | Transaction mode |
| Transaction mode + prepared statements (old) | Statement gets lost | Postgres 14+ + protocol-level |
| `pool_mode = statement` | Multi-statement tx forbidden | Prefer transaction mode |
| Single PgBouncer instance | SPOF | 3+ replicas |
| PgBouncer auth `md5` | Deprecated | scram-sha-256 |
| App pool size = DB max conn | PgBouncer's benefit is lost | App pool 5-10, PgBouncer multiplexing |
| Server idle timeout set to infinite | Idle conns clog the DB | 600s |
| No monitoring | "DB got slow" → cause unclear | exporter + alert |
| `idle in transaction` connection leak | Pool runs dry | Tx commit/rollback hygiene in the app |
| No TLS | A sniffer reads the password | server_tls + client_tls |

---

## 📋 Connection Pooling Checklist

```
[ ] PgBouncer (or pgcat) installed, 3+ replicas
[ ] Transaction mode
[ ] SCRAM-SHA-256 auth
[ ] TLS server + client
[ ] Pool sizing: 25-50 default per pool
[ ] max_client_conn high (1000+)
[ ] max_db_connections low (below DB max_connections)
[ ] Small app pool size (5-10)
[ ] Server idle timeout 600s
[ ] Server lifetime 3600s
[ ] Prometheus exporter + alert
[ ] Pool usage dashboard
[ ] App-side: tx commit/rollback hygiene
[ ] Postgres 14+ + max_prepared_statements (for TX mode)
[ ] PgBouncer pods on different nodes (anti-affinity)
[ ] LB via HAProxy / Service
[ ] Quarterly: pool sizing review
```

---

## 📚 References

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

> *"A connection pool is a **design decision**, not something you just
> run. A poolless system might say it's 'running fine' — until a
> traffic spike hits and the team lands in a **pool exhaustion
> incident**, paying the bill for a **design decision made 6 months
> earlier**."*
