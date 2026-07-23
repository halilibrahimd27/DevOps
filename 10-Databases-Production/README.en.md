---
description: "Index for the production databases section: Postgres tuning, backup/restore, HA failover, zero-downtime migration, operator patterns, and connection pooling."
tags:
  - Databases
  - PostgreSQL
  - Postgres HA
  - Roadmap
---
# 10 · Databases in Production

> *"Every startup's problem for its first five years is 'how do we keep
> scaling PostgreSQL' — everyone else is still solving the same problem."*

Databases can be containerized, but "stateless workload" rules don't apply.
Backup, HA, and migration are a separate discipline.

## Contents

| File | Topic |
|---|---|
| [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md) | `postgresql.conf` tuning, connection pooling (PgBouncer), monitoring |
| [`Backup-Restore-Patterns.md`](Backup-Restore-Patterns.md) | Logical (pg_dump) vs Physical (pgBackRest, WAL-G), PITR |
| [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md) | Auto-failover, sentinel, split-brain resolution |
| [`Zero-Downtime-Migrations.md`](Zero-Downtime-Migrations.md) | Expand/contract pattern, online schema change, gh-ost/pt-osc |
| [`Operator-Patterns.md`](Operator-Patterns.md) | CloudNativePG, Zalando postgres-operator, Crunchy comparison |
| [`Connection-Pooling.md`](Connection-Pooling.md) | PgBouncer transaction vs session mode, pool sizing |
| [`Monitoring-Postgres.md`](Monitoring-Postgres.md) | Slow query, lock, autovacuum, replication lag dashboards |

## "Can I containerize it?"

| Scenario | Recommendation |
|---|---|
| Dev / staging | ✅ Container (docker-compose or StatefulSet) |
| Prod, small (<100 GB) | ✅ Operator-managed K8s (CloudNativePG) |
| Prod, medium (100 GB-1 TB) | ✅ Managed service (RDS / CloudSQL / Aurora) |
| Prod, very large (>1 TB, IOPS-heavy) | ⚠️ Bare metal / dedicated VM + managed backup |
| Multi-region active-active | 🔴 CockroachDB / YugabyteDB / Spanner — Postgres is not suitable |

> **Decision principle:** Is database operations *your* core competency?
> If the answer is "no" → managed service. 30% higher cost, one-tenth of
> a Postgres DBA's salary.

## Backup matrix

| Method | RPO | Restore time | Size | Use case |
|---|---|---|---|---|
| `pg_dump` once a day | 24 hours | Slow (hours) | Small | Dev / archive |
| `pg_basebackup` | 1 day | Fast | Full DB | Small prod |
| **WAL-G + S3** | < 5 min | Medium (PITR) | DB + WAL | **Sweet spot for most prod** |
| pgBackRest | < 5 min | Fast | Incremental | Large prod |
| Streaming replica + snapshot | 0 (RTO) | Instant (failover) | Full DB x N | HA prod |

## Anti-patterns

- ❌ Backing up a 500 GB DB with `pg_dump` (takes hours, no transactional consistency)
- ❌ Untested backup (restore fails exactly when you need it — an untested backup is not a backup)
- ❌ DB host exposed to the Internet (`pg_hba.conf` `0.0.0.0/0`)
- ❌ Application connects as `superuser` (violates least privilege)
- ❌ No connection pooling → DB connection limit becomes hostage to app instance count
- ❌ Unattended schema migration in prod (`DROP COLUMN` mid-deploy)
- ❌ `vacuum` disabled "for performance" (table bloat → DB dies)
