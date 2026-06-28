---
description: "Production veritabanları bölümünün indeksi: Postgres tuning, backup/restore, HA failover, zero-downtime migration, operator pattern ve connection pooling."
tags:
  - Databases
  - PostgreSQL
  - Postgres HA
  - Roadmap
---
# 10 · Databases in Production

> *"Bütün startup'ların ilk 5 yıllık problemi 'PostgreSQL'i nasıl ölçeklenir
> tutarız' meselesidir; geri kalan herkes hâlâ aynı sorunu çözüyor."*

Veritabanları containerize edilebilir ama "stateless workload" kuralları
geçerli değildir. Backup, HA, migration ayrı bir disiplin.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md) | `postgresql.conf` tuning, connection pooling (PgBouncer), monitoring |
| [`Backup-Restore-Patterns.md`](Backup-Restore-Patterns.md) | Logical (pg_dump) vs Physical (pgBackRest, WAL-G), PITR |
| [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md) | Auto-failover, sentinel, split-brain çözümü |
| [`Zero-Downtime-Migrations.md`](Zero-Downtime-Migrations.md) | Expand/contract pattern, online schema change, gh-ost/pt-osc |
| [`Operator-Patterns.md`](Operator-Patterns.md) | CloudNativePG, Zalando postgres-operator, Crunchy karşılaştırma |
| [`Connection-Pooling.md`](Connection-Pooling.md) | PgBouncer transaction vs session mode, pool sizing |
| [`Monitoring-Postgres.md`](Monitoring-Postgres.md) | Slow query, lock, autovacuum, replication lag dashboards |

## "Containerize edebilir miyim?"

| Senaryo | Önerilen |
|---|---|
| Dev / staging | ✅ Container (docker-compose veya StatefulSet) |
| Prod, küçük (<100 GB) | ✅ Operator-managed K8s (CloudNativePG) |
| Prod, orta (100 GB-1 TB) | ✅ Managed servis (RDS / CloudSQL / Aurora) |
| Prod, çok büyük (>1 TB, IOPS-yoğun) | ⚠️ Bare metal / dedicated VM + managed backup |
| Multi-region active-active | 🔴 CockroachDB / YugabyteDB / Spanner — Postgres uygun değil |

> **Karar prensibi:** "Database operasyonu *senin* core competency'n mi?"
> Cevap "hayır" ise → managed servis. Maliyetin %30 fazlası, postgres DBA
> maaşının onda biri.

## Backup matrisi

| Yöntem | RPO | Restore süresi | Boyut | Kullanım |
|---|---|---|---|---|
| `pg_dump` günde 1 | 24 saat | Yavaş (saatler) | Küçük | Dev / archive |
| `pg_basebackup` | 1 gün | Hızlı | Tam DB | Küçük prod |
| **WAL-G + S3** | < 5 dk | Orta (PITR) | DB + WAL | **Çoğu prod için sweet-spot** |
| pgBackRest | < 5 dk | Hızlı | Inkremental | Büyük prod |
| Streaming replica + snapshot | 0 (RTO) | Anlık (failover) | Tam DB x N | HA prod |

## Anti-pattern'ler

- ❌ `pg_dump` ile 500 GB DB backup'ı (saatler sürer, transaction tutarlılığı yok)
- ❌ Backup test edilmemiş (ihtiyaç anında restore çalışmaz)
- ❌ DB host'u Internet'e açık (`pg_hba.conf` `0.0.0.0/0`)
- ❌ `superuser` ile uygulama bağlanıyor (least privilege ihlali)
- ❌ Connection pooling yok → DB connection limit'i app instance sayısına bağımlı
- ❌ Schema migration prod'da unattended (`DROP COLUMN` deploy ortasında)
- ❌ `vacuum` disabled "performans için" (table bloat → DB ölür)
