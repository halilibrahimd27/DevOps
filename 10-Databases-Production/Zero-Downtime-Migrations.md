---
description: "Postgres zero-downtime schema migration pattern'leri: expand/contract, online schema change, gh-ost ve pg_repack; naif migration neden coker, somut orneklerle."
tags:
  - Databases
  - PostgreSQL
  - SRE
  - Performance
---
# Zero-Downtime Migrations — Schema Değişikliği Yaparken Prod'u Düşürme

> *"Schema migration deploy ortasında 'sadece bir DROP COLUMN' diyen
> mühendis, **2 saatlik incident**'ın yazarıdır. Production'da DDL
> = mayın tarlası — **disiplinle** geçilir."*

Bu rehber Postgres için zero-downtime schema migration pattern'lerini
(expand/contract, online schema change, gh-ost, pg_repack) somut
örneklerle anlatır.

---

## 🎯 Sorun: Naif Migration Niye Çöker?

```
v1.0 deploy edildi: "users" tablosu, "email" sütunu var.
v1.1 PR: "email" → "primary_email" rename + "email_verified" sütun ekle.

Naif yaklaşım:
  ALTER TABLE users RENAME COLUMN email TO primary_email;
  ALTER TABLE users ADD COLUMN email_verified BOOLEAN NOT NULL DEFAULT false;

Ne olur?
  1. App v1.0 hâlâ "email" yazıyor → query fail
  2. ALTER TABLE büyük tabloda lock alıyor → 5+ dakika hangs
  3. NOT NULL DEFAULT false → tablo rewrite (10+ dakika)
  4. App v1.1 deploy oluyor: hangi rev hangi schema sürümünde belirsiz
```

**Sonuç**: 30 dakikalık downtime + veri tutarsızlığı + müşteri şikâyeti.

---

## ✅ Çözüm: Expand/Contract Pattern

```
EXPAND:    yeni schema öğelerini ekle (geriye uyumlu)
           ↓
SOĞUTMA:   app çift yazma yap (eski + yeni)
           ↓
BACKFILL:  eski veri → yeni alana kopyala
           ↓
SWITCH:    app sadece yeni alandan oku/yaz
           ↓
CONTRACT:  eski schema öğelerini sil
```

> 🔑 Migration **tek deploy değil, 4 deploy**. Her biri geriye uyumlu.
> Aksi halde rollback imkansız.

---

## 📋 Tipik Senaryolar

### 1. Yeni sütun ekle
```sql
-- ✅ İyi: NULL allowed, default yok (DDL hızlı)
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- ❌ Kötü: NOT NULL DEFAULT → tablo rewrite
ALTER TABLE users ADD COLUMN phone VARCHAR(20) NOT NULL DEFAULT '';
```

> Postgres 11+ ile **NOT NULL + DEFAULT constant** rewrite yapmaz (metadata-only). Ama dynamic default yine rewrite.

### 2. Sütun rename
**Tek migration ile yapma!** Çift yazma akışı:

```sql
-- DEPLOY 1: yeni sütunu ekle
ALTER TABLE users ADD COLUMN primary_email VARCHAR(255);
```

```python
# DEPLOY 2: app her ikisine yazsın
def update_user(user_id, email):
    db.execute("""
      UPDATE users SET email = %s, primary_email = %s WHERE id = %s
    """, (email, email, user_id))

def get_user(user_id):
    # Okuma: yeni varsa onu, yoksa eskiyi
    user = db.fetch_one("SELECT email, primary_email FROM users WHERE id = %s", (user_id,))
    return user.primary_email or user.email
```

```sql
-- DEPLOY 3: backfill
UPDATE users SET primary_email = email WHERE primary_email IS NULL;
-- Büyük tabloda batch'le yap! (aşağıda)
```

```python
# DEPLOY 4: app sadece yeni'den oku
def get_user(user_id):
    return db.fetch_one("SELECT primary_email FROM users WHERE id = %s", (user_id,))
```

```sql
-- DEPLOY 5 (CONTRACT): eski sütunu sil
ALTER TABLE users DROP COLUMN email;
```

> 🔑 5 deploy, ~2 hafta süreç. Ama **zero downtime**.

### 3. Sütun tip değişikliği
```sql
-- ❌ Naif: tablo rewrite + lock
ALTER TABLE users ALTER COLUMN id TYPE BIGINT;

-- ✅ Expand/contract:
-- 1. Yeni sütun ekle
ALTER TABLE users ADD COLUMN id_new BIGINT;

-- 2. Trigger ile her INSERT/UPDATE sync
CREATE TRIGGER sync_id BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION sync_id_func();

-- 3. Backfill batch'le
UPDATE users SET id_new = id WHERE id_new IS NULL AND id IN (...);

-- 4. App'i yeni sütuna geçir
-- 5. Eski sütunu drop et
ALTER TABLE users DROP COLUMN id;
ALTER TABLE users RENAME COLUMN id_new TO id;
```

### 4. Index ekle
```sql
-- ❌ Lock alır (yazma engellenir)
CREATE INDEX idx_email ON users(email);

-- ✅ Lock'sız (online)
CREATE INDEX CONCURRENTLY idx_email ON users(email);
```

> ⚠️ `CONCURRENTLY` failure durumunda **invalid index** bırakır.
> Kontrol: `SELECT * FROM pg_index WHERE indisvalid = false;` → drop + retry.

### 5. Constraint ekle
```sql
-- ❌ Tüm tabloyu lock'lar
ALTER TABLE users ADD CONSTRAINT users_email_unique UNIQUE (email);

-- ✅ Önce CONCURRENTLY index, sonra constraint'e bağla
CREATE UNIQUE INDEX CONCURRENTLY users_email_unique ON users(email);
ALTER TABLE users ADD CONSTRAINT users_email_unique UNIQUE USING INDEX users_email_unique;
```

```sql
-- ✅ NOT NULL constraint için CHECK + VALIDATE pattern
ALTER TABLE users ADD CONSTRAINT email_not_null CHECK (email IS NOT NULL) NOT VALID;
ALTER TABLE users VALIDATE CONSTRAINT email_not_null;  -- bu lock almaz, scan yapar
```

### 6. Sütun sil
```sql
-- ✅ Hızlı (metadata-only)
ALTER TABLE users DROP COLUMN old_field;
```

> Ama önce **app sütunu kullanmaktan vazgeçmiş** olmalı (expand/contract).

### 7. Tablo rename
Aynı expand/contract: yeni tablo oluştur, çift yazma, backfill, switch, drop.

---

## 🛠️ Batch Backfill — Büyük Tabloları Lock'lamadan

```sql
-- ❌ Naif: 100M satırı tek transaction'da update
UPDATE users SET primary_email = email WHERE primary_email IS NULL;
-- → 30+ dakika lock, replication lag, OOM

-- ✅ Batch'le, transaction'lara böl
DO $$
DECLARE
  batch_size INT := 10000;
  rows_updated INT;
BEGIN
  LOOP
    UPDATE users SET primary_email = email
    WHERE id IN (
      SELECT id FROM users
      WHERE primary_email IS NULL
      LIMIT batch_size
    );

    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    EXIT WHEN rows_updated = 0;

    COMMIT;
    PERFORM pg_sleep(0.1);  -- replication breathing room
  END LOOP;
END $$;
```

> 🔑 **`COMMIT` her batch'te**. Replication lag'i monitor et, lag büyürse `pg_sleep`'i artır.

---

## 🔧 pg_repack — Tablo Refactor (Lock'sız)

```bash
# Tablo bloat'ı temizle, lock'suz
pg_repack -d <DB> -t <TABLE>

# Tüm DB
pg_repack -d <DB> -a
```

`pg_repack` arka planda yeni tablo oluşturur, trigger ile değişiklikleri sync eder, sonunda atomic swap yapar.

> ⚠️ **`pg_repack` setup gerektirir**: extension install + replication slot.
> Production'da test ortamında dene.

---

## 🛠️ Migration Tool'lar

| Tool | Dil | Özellik |
|---|---|---|
| **Flyway** | Java/CLI | Versioned migrations, rollback |
| **Liquibase** | Java/CLI | XML/YAML change log |
| **Alembic** | Python (SQLAlchemy) | Auto-generate from model |
| **golang-migrate** | Go/CLI | Multi-DB support |
| **Atlas** | CLI | Declarative schema, drift detection |
| **sqitch** | Perl | Tag-based, rollback |

### Atlas ile declarative schema
```hcl
# schema.hcl
schema "public" {
}

table "users" {
  schema = schema.public
  column "id" {
    type = bigint
    null = false
  }
  column "email" {
    type = varchar(255)
    null = false
  }
  primary_key {
    columns = [column.id]
  }
  index "idx_email" {
    columns = [column.email]
    unique  = true
  }
}
```

```bash
# Diff ile migration üret
atlas schema diff --to file://schema.hcl --from "postgres://..."

# Apply (CI gate ile)
atlas migrate apply --url "postgres://..."
```

---

## 🚦 Migration CI Gate

```yaml
# .github/workflows/db-migration-check.yml
on: [pull_request]

jobs:
  migration-safety:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>

      - name: Lint migrations
        run: |
          # Yasaklı pattern'ler
          if grep -E "ALTER TABLE.*RENAME COLUMN" migrations/*.sql; then
            echo "::error::Direct column rename yasak — expand/contract kullan"
            exit 1
          fi

          if grep -E "DROP COLUMN" migrations/*.sql; then
            echo "::warning::DROP COLUMN — app artık kullanmıyor doğrulandı mı?"
          fi

          if grep -E "CREATE INDEX" migrations/*.sql | grep -v "CONCURRENTLY"; then
            echo "::error::CREATE INDEX yerine CREATE INDEX CONCURRENTLY"
            exit 1
          fi

      - name: Test migration on staging clone
        run: |
          # Staging DB'nin clone'unda dene
          atlas migrate apply --url $STAGING_CLONE_URL --dry-run
```

---

## 📋 Schema Migration Akışı (Safe)

```
1. RFC: schema değişikliği niye + plan
2. Atlas / Flyway ile migration script yaz
3. Lint: yasaklı pattern yok
4. Staging clone'da uygula → uygulama testleri
5. PR review (DBA + dev + QA)
6. Production deploy:
   a. Migration: expand (yeni alan ekle)
   b. App deploy: çift yazma
   c. Backfill (batch, replication-aware)
   d. App deploy: yeni alandan oku
   e. Migration: contract (eski sil)
7. Postmortem (gerekiyorsa)
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tek deploy + tek migration | Rollback imkansız | Expand/contract çoklu deploy |
| `ALTER TABLE` büyük tabloda lock alır | 5+ dakika downtime | Batch + CONCURRENTLY + pg_repack |
| `DROP COLUMN` direkt | App hâlâ yazıyor olabilir | Önce app, sonra DDL |
| `RENAME COLUMN` direkt | App eski isimle yazıyor | Yeni alan + çift yazma + backfill |
| `CREATE INDEX` non-concurrently | Yazma engellendi | `CONCURRENTLY` |
| `NOT NULL DEFAULT 'value'` (PG 10-) | Tablo rewrite | PG 11+ ile metadata-only OR add → backfill → constraint |
| Backfill tek transaction | Replication lag, OOM | Batch'le, breathing room |
| Migration prod'a unattended | Lock alırsa hayatta yok | Window planlı + monitoring |
| Rollback prosedürü yok | Bug'da geri dönüş yok | `down` migration veya feature flag |
| Testler migration'sız | Yeni schema'da bug çıkar | CI'da staging clone'da migration test |
| App sürümü ile schema senkron değil | "v1.1 schema'sız çalışıyor" sürpriz | Backward-compatible kural |
| `ALTER TYPE` direkt | Tablo rewrite | Yeni sütun + backfill + switch |
| Production'da `pg_dump` migration sırası | Lock contention | Migration window'unda backup yapma |

---

## 📋 Migration Disiplini Checklist

```
[ ] Migration tool seçilmiş (Atlas / Flyway / Alembic)
[ ] Migration repo'da versioned
[ ] CI lint: yasaklı pattern (RENAME, DROP, non-concurrently INDEX)
[ ] Staging clone'da test edildi
[ ] Big table'da: batch backfill
[ ] Replication lag monitor edilirken backfill
[ ] App: backward-compatible (eski + yeni schema okuyabilir)
[ ] Expand/contract aşamaları net (en az 4 deploy)
[ ] Feature flag: yeni alan opsiyonel başlangıçta
[ ] PR review: DBA + senior eng
[ ] Migration window: yoğun olmayan saat
[ ] Monitoring: lock contention, query latency
[ ] Rollback prosedürü dokumante
[ ] Postmortem: yeni anti-pattern keşfedildi mi
[ ] Quarterly: migration retro (hangi pattern'ler tekrar)
```

---

## 📚 Referanslar

- **PostgreSQL DDL Concurrency** — postgresql.org/docs/current/explicit-locking.html
- **Atlas** — atlasgo.io
- **Flyway** — flywaydb.org
- **gh-ost** (MySQL'e özel ama prensipler ortak) — github.com/github/gh-ost
- **pg_repack** — github.com/reorg/pg_repack
- **Strong Migrations gem (Rails)** — github.com/ankane/strong_migrations (örnek pattern'ler)
- [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md)
- [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md)
- [`Backup-Restore-Patterns.md`](Backup-Restore-Patterns.md)
- [`01-Git-Workflow/Trunk-Based-Development.md`](../01-Git-Workflow/Trunk-Based-Development.md) — feature flag

---

> *"Schema migration **sprint sonuna sıkıştırılmaz**. Expand/contract
> 'gereksiz formalite' değil — **rollback hakkını**'nı saklayan tek
> disiplindir."*
