---
description: "Postgres backup strategies: the 3-2-1 rule, RPO/RTO targets, logical/physical backup, PITR, and turning restore drills into discipline through automation."
tags:
  - Databases
  - PostgreSQL
  - Backup
  - SRE
---
# Postgres Backup & Restore — An Untested Backup Is Not a Backup

> *"Those without a backup lose their data; those who have a backup
> but never tested it lose their **morale**. Saying 'I have a backup'
> without running a restore drill is like carrying an **unloaded gun**."*

This guide covers modern backup strategies for Postgres, the **3-2-1
rule**, and turning restore drills into discipline through automation.

---

## 🎯 RPO and RTO — Define Your Target First

| Term | Meaning | Example |
|---|---|---|
| **RPO** (Recovery Point Objective) | Acceptable data-loss window | "We can't lose more than the last 5 minutes of data" |
| **RTO** (Recovery Time Objective) | Acceptable downtime | "We must be back within 30 minutes" |

> 🔑 RPO = determines backup frequency. RTO = determines restore strategy.

### Typical targets
| Scenario | RPO | RTO |
|---|---|---|
| Hobby project | 24h | 4h |
| Internal SaaS | 1h | 2h |
| Customer-facing prod | 5 min | 30 min |
| Financial system | 0 (sync replication) | 5 min |
| Mission-critical | 0 | 0 (active-active) |

---

## 🪣 Backup Methods — Comparison

| Method | RPO | RTO | Size | Complexity | Use |
|---|---|---|---|---|---|
| `pg_dump` | 24h | Slow (hours) | Small | Low | Dev / small |
| `pg_basebackup` | 1 day | Fast | Full DB | Low | Full DB image |
| **WAL-G + S3** | < 5 min | Medium (PITR) | DB + WAL | Medium | **Sweet spot for most prod** |
| **pgBackRest** | < 5 min | Fast | Incremental | Medium | Large prod |
| Streaming replica | 0 | Instant (failover) | Full DB × N | High | HA prod |
| **Logical replication** | < 1 min | Medium | Subset | Medium | Selective DR |
| Cloud snapshot (RDS, EBS) | Hourly | Fast | Block-level | Low | Managed/cloud |

---

## 1️⃣ `pg_dump` — Simple, Only for Small DBs

```bash
# Single DB
pg_dump -h <DB_HOST> -U <USER> -d <DB> -F c -f /backups/db-$(date +%F).dump

# All DBs
pg_dumpall -h <DB_HOST> -U <USER> -f /backups/all-$(date +%F).sql

# Restore
pg_restore -h <DB_HOST> -U <USER> -d <DB> /backups/db-2026-05-04.dump
```

### ✅ Pro
- Easy, everyone understands it
- Cross-version migration (downgrade/upgrade)
- Schema-only / data-only option

### ❌ Con
- **Slow** (500 GB → hours)
- Weak transaction consistency (snapshot)
- Disk I/O intensive
- No PITR (point-in-time recovery)

> 🔑 **Don't use in production > 50 GB.** `pg_dump` is for archival purposes.

---

## 2️⃣ WAL-G — The 2026 Recommendation

[WAL-G](https://github.com/wal-g/wal-g) is a Postgres + S3/GCS/Azure
backup tool. It provides **continuous archiving + base backup + PITR**.

### Installation
```bash
# Binary install
wget https://github.com/wal-g/wal-g/releases/download/<VERSION>/wal-g-pg-ubuntu-20.04-amd64.tar.gz
tar -xzf wal-g-pg-*.tar.gz
sudo mv wal-g /usr/local/bin/
```

### Config
```bash
# /etc/postgresql/wal-g.env
WALG_S3_PREFIX=s3://<BUCKET>/wal-g/
AWS_REGION=eu-west-1
AWS_ACCESS_KEY_ID=<KEY>
AWS_SECRET_ACCESS_KEY=<SECRET>

WALG_COMPRESSION_METHOD=brotli
WALG_DELTA_MAX_STEPS=6      # incremental backup
WALG_PGP_KEY_PATH=/etc/postgresql/wal-g.gpg   # encryption
```

### Postgres side
```ini
# postgresql.conf
archive_mode = on
archive_command = 'envdir /etc/postgresql/wal-g.env wal-g wal-push %p'
archive_timeout = 60       # push the WAL within 1 min
```

```bash
# First full backup
envdir /etc/postgresql/wal-g.env wal-g backup-push /var/lib/postgresql/data

# Cron: daily base backup
0 2 * * * envdir /etc/postgresql/wal-g.env wal-g backup-push /var/lib/postgresql/data

# WAL is shipped automatically via archive_command
```

### Restore
```bash
# List
wal-g backup-list

# Latest
wal-g backup-fetch /var/lib/postgresql/data LATEST

# PITR — to a specific time
wal-g backup-fetch /var/lib/postgresql/data LATEST
echo "restore_command = 'wal-g wal-fetch %f %p'" >> /var/lib/postgresql/data/postgresql.auto.conf
echo "recovery_target_time = '2026-05-04 14:30:00 UTC'" >> /var/lib/postgresql/data/postgresql.auto.conf
echo "recovery_target_action = 'promote'" >> /var/lib/postgresql/data/postgresql.auto.conf
touch /var/lib/postgresql/data/recovery.signal
systemctl start postgresql
```

### ✅ Pro
- Continuous WAL archiving (RPO < 5 min)
- Encrypted at rest (S3 SSE + WAL-G GPG)
- Compression (brotli)
- Delta backups (incremental)
- Open source

### ❌ Con
- Setup is somewhat technical
- Self-managed (requires maintenance)

---

## 3️⃣ pgBackRest — For Large Prod

pgBackRest (Crunchy Data) is optimized for **very large DBs** (TB+).

### Advantages
- Parallel backup/restore (8+ threads)
- Incremental + differential
- Repository encryption
- Backup verification (CRC + readback)
- Stanza (managing multiple clusters)

### Config
```ini
# /etc/pgbackrest/pgbackrest.conf
[global]
repo1-path=/var/lib/pgbackrest
repo1-type=s3
repo1-s3-bucket=<BUCKET>
repo1-s3-region=eu-west-1
repo1-s3-key=<KEY>
repo1-s3-key-secret=<SECRET>
repo1-cipher-type=aes-256-cbc
repo1-cipher-pass=<PASSWORD>
repo1-retention-full=30
repo1-retention-diff=7

start-fast=y
delta=y
process-max=8

[main]
pg1-path=/var/lib/postgresql/data
pg1-port=5432
```

### Usage
```bash
# Create stanza
pgbackrest --stanza=main --log-level-console=info stanza-create

# Full backup
pgbackrest --stanza=main --type=full backup

# Incremental (cron every hour)
pgbackrest --stanza=main --type=incr backup

# Restore + PITR
pgbackrest --stanza=main \
  --type=time \
  --target="2026-05-04 14:30:00" \
  restore
```

---

## 4️⃣ Streaming Replication — Zero-RPO Target

```ini
# Primary: postgresql.conf
wal_level = replica
max_wal_senders = 10
synchronous_standby_names = '*'   # mandatory sync
synchronous_commit = on

# Standby: postgresql.conf
hot_standby = on
primary_conninfo = 'host=<PRIMARY> user=replicator password=<PWD> application_name=standby1'
```

```sql
-- Replication user on the primary
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD '<PWD>';
```

> 🔑 With **`synchronous_commit = on`** you get RPO = 0 but latency rises (commit waits until it reaches the standby).

### Auto-failover: Patroni / CloudNativePG
- Patroni: standalone, etcd/consul DCS
- CloudNativePG: K8s operator, modern, recommended

Details: [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md) (next batch).

---

## 🔐 The 3-2-1 Rule

```
3  copies  (1 production + 2 backup)
2  different media  (e.g. disk + S3)
1  off-site  (different cloud / region / physical)
```

### Practical implementation
```
1. Production DB (primary)
2. Streaming replica (sync, same region)
3. WAL-G S3 backup (same region) — Copy 1
4. WAL-G S3 backup cross-region replication → us-west-2 — Copy 2
5. Off-site: glacier-tier 90-day retention
```

> 🔑 **Off-site** is critical — it protects against a region-wide disaster (rare but it happens).

---

## 🧪 The Restore Drill — The Most Important Discipline

> "An untested backup **is not a backup**."

### Quarterly drill protocol
```
1. Spin up an empty cluster (scratch K8s namespace)
2. Restore the latest full backup
3. Apply the last 1 hour of WAL via PITR
4. Smoke test:
   - Schema integrity
   - Is the row count reasonable
   - Can the app connect
   - Does a critical query run
5. Measure RTO
6. Postmortem: fix any gaps
```

### Automation
```yaml
# .github/workflows/backup-drill.yml
name: Quarterly Backup Restore Drill

on:
  schedule:
    - cron: '0 6 1 1,4,7,10 *'   # Q1, Q2, Q3, Q4 first day

jobs:
  drill:
    runs-on: self-hosted-internal
    steps:
      - name: Spin up scratch cluster
        run: terraform apply -auto-approve -var=env=drill

      - name: Restore latest backup
        run: |
          kubectl -n drill exec postgres-0 -- \
            envdir /etc/postgresql/wal-g.env \
            wal-g backup-fetch /var/lib/postgresql/data LATEST

      - name: Smoke test
        run: pytest tests/restore_smoke.py

      - name: Measure RTO
        run: echo "RTO: $((SECONDS / 60)) minutes"

      - name: Notify
        if: always()
        run: |
          curl -X POST <SLACK_WEBHOOK> -d "{\"text\":\"Q drill: RTO ${RTO}m\"}"
```

---

## 🔒 Backup Security

| Risk | Mitigation |
|---|---|
| Backup S3 bucket public | Bucket policy: deny public, IAM least-privilege |
| Backup unencrypted | S3 SSE + WAL-G GPG / pgBackRest cipher |
| Attacker deleted the backup | S3 versioning + MFA delete + cross-account |
| Ransomware → backup encrypted | Immutable storage (S3 Object Lock) |
| Old backup still holds active user data | Retention policy + GDPR compliance |
| Backup credentials in Git | Vault + ESO |

### S3 Object Lock (immutable)
```bash
aws s3api put-object-lock-configuration \
  --bucket <BUCKET> \
  --object-lock-configuration '{
    "ObjectLockEnabled": "Enabled",
    "Rule": {
      "DefaultRetention": {
        "Mode": "COMPLIANCE",
        "Days": 30
      }
    }
  }'
```

> 🔑 For 30 days **nobody** can delete it (including admins). Ransomware protection.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| `pg_dump` on a 500 GB DB | Takes hours, transaction inconsistent | WAL-G or pgBackRest |
| Backup never tested | Fails in a crisis | Quarterly restore drill |
| Backup in the same region | Region down → data loss | Cross-region replication |
| Backup in public S3 | Data leak | IAM + encryption + private |
| Infinite backup retention | Storage cost + data-protection violation | Lifecycle policy |
| Backup credentials in Git | Compromise = backup compromise | Vault + ESO |
| RTO/RPO not written down | No decision in a crisis | Documented in the SLO doc |
| Manual backup script | Forgotten when the team changes | Cron + monitoring + alert |
| Backup fails → nobody notices | Silent loss | Alert: backup-success metric |
| Restore procedure undocumented | A junior can't do it at night | Runbook + drill |
| `pg_dump` + filesystem snapshot | Inconsistent (snapshot mid-write) | pg_basebackup or WAL-G |
| Test environment uses the prod backup | PII leak (data-protection violation) | Anonymized restore |

---

## 📋 Backup Strategy Checklist

```
[ ] RPO + RTO written down (SLO doc)
[ ] WAL-G or pgBackRest installed
[ ] Continuous WAL archiving active
[ ] Daily full backup in cron
[ ] Backup encryption-at-rest (KMS)
[ ] Backup encryption-in-transit (TLS)
[ ] 3-2-1 rule: 3 copies, 2 media, 1 off-site
[ ] Cross-region replication
[ ] S3 Object Lock (ransomware protection)
[ ] S3 versioning + MFA delete
[ ] Retention policy: KVKK/GDPR compliance
[ ] Monitoring: backup-success metric + alert
[ ] Backup size trend dashboard
[ ] Quarterly restore drill
[ ] Drill RTO is measured
[ ] Restore runbook document
[ ] PITR verified to work
[ ] Backup credentials in Vault
[ ] Test environment uses an anonymized DB
[ ] Annual: DR plan drill (entire stack)
```

---

## 📚 References

- **WAL-G** — github.com/wal-g/wal-g
- **pgBackRest** — pgbackrest.org
- **PostgreSQL Backup Documentation** — postgresql.org/docs/current/backup.html
- **3-2-1 Rule** — common industry practice
- [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md)
- [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md)
- [`Zero-Downtime-Migrations.md`](Zero-Downtime-Migrations.md)
- [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md) — backup creds
- [`19-Compliance/KVKK-Practical.md`](../19-Compliance/KVKK-Practical.md) — retention policy
- [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md) — DR flow

---

> *"Making a backup is easy; **restoring** is the craft. A tested
> backup is insurance on customer data. An untested one is just a
> **placebo pill**."*

---

> 🎓 **Learning Path:** This document is used as a "read first" resource in the [`E4`](../22-Learning-Path/block-e-ownership/E4-veritabani-restore.md) module.
