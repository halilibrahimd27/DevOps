---
description: "Postgres zero-downtime schema migration patterns: expand/contract, online schema change, gh-ost and pg_repack; concrete examples of why naive migrations crash production."
tags:
  - Databases
  - PostgreSQL
  - SRE
  - Performance
---
# Zero-Downtime Migrations — Taking Down Prod While Changing the Schema

> *"The engineer who says 'it's just a DROP COLUMN' in the middle
> of a schema migration deploy is the author of a **2-hour incident**.
> In production, DDL = a minefield — crossed only **with discipline**."*

This guide covers zero-downtime schema migration patterns for
Postgres (expand/contract, online schema change, gh-ost, pg_repack)
with concrete examples.

---

## 🎯 The Problem: Why Does a Naive Migration Crash?

```
v1.0 deployed: "users" table has an "email" column.
v1.1 PR: rename "email" → "primary_email" + add an "email_verified" column.

Naive approach:
  ALTER TABLE users RENAME COLUMN email TO primary_email;
  ALTER TABLE users ADD COLUMN email_verified BOOLEAN NOT NULL DEFAULT false;

What happens?
  1. App v1.0 still writes "email" → query fails
  2. ALTER TABLE takes a lock on the big table → hangs for 5+ minutes
  3. NOT NULL DEFAULT false → table rewrite (10+ minutes)
  4. App v1.1 gets deployed: unclear which revision is on which schema version
```

**Result**: 30 minutes of downtime + data inconsistency + customer complaints.

---

## ✅ Solution: The Expand/Contract Pattern

```
EXPAND:    add new schema elements (backward compatible)
           ↓
COOL-DOWN: app does dual writes (old + new)
           ↓
BACKFILL:  copy old data → new field
           ↓
SWITCH:    app reads/writes only from the new field
           ↓
CONTRACT:  delete old schema elements
```

> 🔑 A migration is **not one deploy, but 4 deploys**. Each one is backward compatible.
> Otherwise rollback is impossible.

---

## 📋 Typical Scenarios

### 1. Add a new column
```sql
-- ✅ Good: NULL allowed, no default (DDL is fast)
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- ❌ Bad: NOT NULL DEFAULT → table rewrite
ALTER TABLE users ADD COLUMN phone VARCHAR(20) NOT NULL DEFAULT '';
```

> With Postgres 11+, **NOT NULL + DEFAULT constant** doesn't trigger a rewrite (metadata-only). But a dynamic default still triggers one.

### 2. Rename a column
**Don't do this in a single migration!** The dual-write flow:

```sql
-- DEPLOY 1: add the new column
ALTER TABLE users ADD COLUMN primary_email VARCHAR(255);
```

```python
# DEPLOY 2: have the app write to both
def update_user(user_id, email):
    db.execute("""
      UPDATE users SET email = %s, primary_email = %s WHERE id = %s
    """, (email, email, user_id))

def get_user(user_id):
    # Read: prefer the new one if present, otherwise the old one
    user = db.fetch_one("SELECT email, primary_email FROM users WHERE id = %s", (user_id,))
    return user.primary_email or user.email
```

```sql
-- DEPLOY 3: backfill
UPDATE users SET primary_email = email WHERE primary_email IS NULL;
-- Do this in batches on a big table! (see below)
```

```python
# DEPLOY 4: app reads only from the new column
def get_user(user_id):
    return db.fetch_one("SELECT primary_email FROM users WHERE id = %s", (user_id,))
```

```sql
-- DEPLOY 5 (CONTRACT): drop the old column
ALTER TABLE users DROP COLUMN email;
```

> 🔑 5 deploys, ~2-week process. But **zero downtime**.

### 3. Column type change
```sql
-- ❌ Naive: table rewrite + lock
ALTER TABLE users ALTER COLUMN id TYPE BIGINT;

-- ✅ Expand/contract:
-- 1. Add the new column
ALTER TABLE users ADD COLUMN id_new BIGINT;

-- 2. Sync on every INSERT/UPDATE via a trigger
CREATE TRIGGER sync_id BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION sync_id_func();

-- 3. Backfill in batches
UPDATE users SET id_new = id WHERE id_new IS NULL AND id IN (...);

-- 4. Switch the app to the new column
-- 5. Drop the old column
ALTER TABLE users DROP COLUMN id;
ALTER TABLE users RENAME COLUMN id_new TO id;
```

### 4. Add an index
```sql
-- ❌ Takes a lock (writes blocked)
CREATE INDEX idx_email ON users(email);

-- ✅ Lock-free (online)
CREATE INDEX CONCURRENTLY idx_email ON users(email);
```

> ⚠️ On failure, `CONCURRENTLY` leaves behind an **invalid index**.
> Check: `SELECT * FROM pg_index WHERE indisvalid = false;` → drop + retry.

### 5. Add a constraint
```sql
-- ❌ Locks the entire table
ALTER TABLE users ADD CONSTRAINT users_email_unique UNIQUE (email);

-- ✅ Build a CONCURRENTLY index first, then attach the constraint
CREATE UNIQUE INDEX CONCURRENTLY users_email_unique ON users(email);
ALTER TABLE users ADD CONSTRAINT users_email_unique UNIQUE USING INDEX users_email_unique;
```

```sql
-- ✅ CHECK + VALIDATE pattern for a NOT NULL constraint
ALTER TABLE users ADD CONSTRAINT email_not_null CHECK (email IS NOT NULL) NOT VALID;
ALTER TABLE users VALIDATE CONSTRAINT email_not_null;  -- this doesn't take a lock, it scans
```

### 6. Drop a column
```sql
-- ✅ Fast (metadata-only)
ALTER TABLE users DROP COLUMN old_field;
```

> But first the **app must have stopped using the column** (expand/contract).

### 7. Rename a table
Same expand/contract: create the new table, dual-write, backfill, switch, drop.

---

## 🛠️ Batch Backfill — Without Locking Big Tables

```sql
-- ❌ Naive: update 100M rows in a single transaction
UPDATE users SET primary_email = email WHERE primary_email IS NULL;
-- → 30+ minutes of locking, replication lag, OOM

-- ✅ Batch it, split across transactions
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

> 🔑 **`COMMIT` on every batch**. Monitor replication lag; if the lag grows, increase `pg_sleep`.

---

## 🔧 pg_repack — Table Refactor (Lock-Free)

```bash
# Clean up table bloat, lock-free
pg_repack -d <DB> -t <TABLE>

# Entire DB
pg_repack -d <DB> -a
```

`pg_repack` creates a new table in the background, syncs changes via a trigger, and does an atomic swap at the end.

> ⚠️ **`pg_repack` requires setup**: extension install + replication slot.
> Try it in a test environment before production.

---

## 🛠️ Migration Tools

| Tool | Language | Feature |
|---|---|---|
| **Flyway** | Java/CLI | Versioned migrations, rollback |
| **Liquibase** | Java/CLI | XML/YAML change log |
| **Alembic** | Python (SQLAlchemy) | Auto-generate from model |
| **golang-migrate** | Go/CLI | Multi-DB support |
| **Atlas** | CLI | Declarative schema, drift detection |
| **sqitch** | Perl | Tag-based, rollback |

### Declarative schema with Atlas
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
# Generate a migration via diff
atlas schema diff --to file://schema.hcl --from "postgres://..."

# Apply (with a CI gate)
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
          # Forbidden patterns
          if grep -E "ALTER TABLE.*RENAME COLUMN" migrations/*.sql; then
            echo "::error::Direct column rename is forbidden — use expand/contract"
            exit 1
          fi

          if grep -E "DROP COLUMN" migrations/*.sql; then
            echo "::warning::DROP COLUMN — has it been confirmed the app no longer uses this?"
          fi

          if grep -E "CREATE INDEX" migrations/*.sql | grep -v "CONCURRENTLY"; then
            echo "::error::Use CREATE INDEX CONCURRENTLY instead of CREATE INDEX"
            exit 1
          fi

      - name: Test migration on staging clone
        run: |
          # Try it on a clone of the staging DB
          atlas migrate apply --url $STAGING_CLONE_URL --dry-run
```

---

## 📋 Schema Migration Flow (Safe)

```
1. RFC: why the schema change + plan
2. Write the migration script with Atlas / Flyway
3. Lint: no forbidden patterns
4. Apply on a staging clone → application tests
5. PR review (DBA + dev + QA)
6. Production deploy:
   a. Migration: expand (add the new field)
   b. App deploy: dual-write
   c. Backfill (batch, replication-aware)
   d. App deploy: read from the new field
   e. Migration: contract (drop the old one)
7. Postmortem (if needed)
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Single deploy + single migration | Rollback is impossible | Expand/contract, multiple deploys |
| `ALTER TABLE` takes a lock on a big table | 5+ minutes of downtime | Batch + CONCURRENTLY + pg_repack |
| `DROP COLUMN` directly | App may still be writing to it | App first, then DDL |
| `RENAME COLUMN` directly | App writes using the old name | New field + dual-write + backfill |
| `CREATE INDEX` non-concurrently | Writes get blocked | `CONCURRENTLY` |
| `NOT NULL DEFAULT 'value'` (PG 10 and earlier) | Table rewrite | Metadata-only with PG 11+, OR add → backfill → constraint |
| Backfill in a single transaction | Replication lag, OOM | Batch it, with breathing room |
| Migration run unattended in prod | If it takes a lock, you won't survive | Planned window + monitoring |
| No rollback procedure | No way back if there's a bug | `down` migration or feature flag |
| Tests without the migration | Bugs surface on the new schema | Test the migration on a staging clone in CI |
| App version out of sync with schema | Surprise: "v1.1 is running without the schema" | Backward-compatible rule |
| `ALTER TYPE` directly | Table rewrite | New column + backfill + switch |
| Running `pg_dump` in production during a migration | Lock contention | Don't back up during the migration window |

---

## 📋 Migration Discipline Checklist

```
[ ] Migration tool chosen (Atlas / Flyway / Alembic)
[ ] Migration versioned in the repo
[ ] CI lint: forbidden patterns (RENAME, DROP, non-concurrently INDEX)
[ ] Tested on a staging clone
[ ] Big table: batch backfill
[ ] Replication lag monitored during backfill
[ ] App: backward-compatible (can read old + new schema)
[ ] Expand/contract phases are clear (at least 4 deploys)
[ ] Feature flag: new field optional at first
[ ] PR review: DBA + senior eng
[ ] Migration window: off-peak hours
[ ] Monitoring: lock contention, query latency
[ ] Rollback procedure documented
[ ] Postmortem: any new anti-pattern discovered
[ ] Quarterly: migration retro (which patterns recur)
```

---

## 📚 References

- **PostgreSQL DDL Concurrency** — postgresql.org/docs/current/explicit-locking.html
- **Atlas** — atlasgo.io
- **Flyway** — flywaydb.org
- **gh-ost** (MySQL-specific, but the principles are shared) — github.com/github/gh-ost
- **pg_repack** — github.com/reorg/pg_repack
- **Strong Migrations gem (Rails)** — github.com/ankane/strong_migrations (example patterns)
- [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md)
- [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md)
- [`Backup-Restore-Patterns.md`](Backup-Restore-Patterns.md)
- [`01-Git-Workflow/Trunk-Based-Development.md`](../01-Git-Workflow/Trunk-Based-Development.md) — feature flag

---

> *"A schema migration **can't be crammed into the end of a sprint**.
> Expand/contract isn't 'unnecessary formality' — it's the only
> discipline that preserves your **right to roll back**."*

---

> 🎓 **Learning Path:** This document is used as a "read first" resource in the [`E4`](../22-Learning-Path/block-e-ownership/E4-veritabani-restore.md) module.
