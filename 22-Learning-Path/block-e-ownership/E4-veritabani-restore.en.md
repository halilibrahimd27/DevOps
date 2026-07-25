---
description: "Database in production — especially restore: an untested backup is not a backup."
level: E
module: E4
estimated_hours: 14
prerequisites: [A6, D2]
tags: [Learning Path, Databases]
---
# E4 — Database in Production: Especially Restore

> *"An untested backup is not a backup — it's just a hope."*

**Block:** E — Ownership · **Duration:** ~14h · **Prerequisite:** [`A6`](../block-a-intuition/A6-elle-deploy.md), [`D2`](../block-d-orchestration/D2-k8s-production.md)

## 🎯 When you finish this module
- You back up a database and **actually test the restore.**
- You measure and report restore time (RTO) and data-loss window (RPO).
- You explain why a zero-downtime schema change requires careful ordering.

## 🧠 Why this, why now
In A6 you set up a DB; in D2 you saw production settings. But the real ownership test
is this: **when data is gone, can you bring it back?** This connects directly to
the D → E transition signal (something you built broke, and you brought it back).

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`10-Databases-Production/Backup-Restore-Patterns.md`](../../10-Databases-Production/Backup-Restore-Patterns.md) | backup/restore patterns | ~30 min |
| [`10-Databases-Production/Zero-Downtime-Migrations.md`](../../10-Databases-Production/Zero-Downtime-Migrations.md) | schema changes | ~25 min |

## 🔨 Lab
👉 [`labs/build/L20-veritabani-restore/`](../labs/build/L20-veritabani-restore/README.md)

## 💥 Broken lab
👉 [`labs/broken/K08-restore-basarisiz/`](../labs/broken/K08-restore-basarisiz/README.md) — Symptom: "Restore doesn't work /
data comes back incomplete." (Realistic root cause hidden: corrupt/incomplete backup / wrong order / version mismatch.)

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] A backup was taken and **restored to a clean environment**; data integrity was verified with a query (row count/checksum)
- [ ] RTO (restore time) and RPO (data-loss window) were measured and written down
- [ ] Backup access control + at-rest encryption was documented (who can access it, is it encrypted)
- [ ] Why a zero-downtime schema change must be done in multiple ordered steps (e.g., add the column first → dual-write → backfill → drop the old one last) was explained in one written sentence
- [ ] `bash labs/broken/K08-restore-basarisiz/verify.sh` passes with zero errors after the fix

## 🧪 Test yourself
1. Why doesn't the sentence "backups run every night" provide assurance on its own?
2. What's the difference between RTO and RPO; which one is generally more expensive to push toward zero?
3. Backup files sit in a publicly accessible bucket. What's the problem?

<details><summary>Answers</summary>

1. Because taking a backup doesn't prove it can be restored. A backup that's corrupt, incomplete, or taken with the wrong version only reveals itself when you actually try to restore it — an untested backup is just a hope. Patterns are in [`10-Databases-Production/Backup-Restore-Patterns.md`](../../10-Databases-Production/Backup-Restore-Patterns.md).
2. RTO = time to recover (the downtime target); RPO = the acceptable data-loss window. Pushing RPO toward zero (synchronous replication / continuous WAL) is generally more expensive, because every write has to be written to a second location instantly too.
3. A backup is the entire database — a public bucket leaks all of it, and it's usually the copy with the weakest access control. A backup must be protected at least as well as the live DB: access restrictions + at-rest encryption. The schema-change side is in [`10-Databases-Production/Zero-Downtime-Migrations.md`](../../10-Databases-Production/Zero-Downtime-Migrations.md).
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| Restore runs but data is missing | Wrong order / partial backup / version mismatch | Verify ordered dependencies and version compatibility; use a full backup |
| Restore takes too long (RTO exceeded) | Wrong method (logical dump, large DB) | Switch to physical backup + PITR (Point-In-Time Recovery — rewinding to a specific moment via WAL); measure restore time ahead of time |
| Backups run but nobody has tested them | Restore procedure isn't written down | Do a full restore rehearsal on a calm day, write down the steps |
| Backup access isn't audited | No encryption/access control | Restrict access, encrypt at rest, tie access to an audit log |

## 💼 Portfolio output
A tested restore procedure + RTO/RPO report.

## ⏭️ Up next
[`E5 — Advanced Broken Lab / Chaos`](E5-chaos.md)

---

> *"Test your backup on a calm Tuesday afternoon, not in the worst possible moment."*
