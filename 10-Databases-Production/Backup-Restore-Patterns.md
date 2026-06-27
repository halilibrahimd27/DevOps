---
description: "Postgres backup stratejileri: 3-2-1 kuralı, RPO/RTO hedefleri, logical/physical backup, PITR ve restore tatbikatını otomasyonla disiplin haline getirme."
---
# Postgres Backup & Restore — Test Edilmemiş Backup, Backup Değildir

> *"Backup'ı olmayanların verisi gider; backup'ı olan ama test
> etmemiş olanların **moralleri**. Restore tatbikatı yapmadan
> 'backup'ım var' demek, **fişek atılmamış silah** taşımaktır."*

Bu rehber Postgres için modern backup stratejilerini, **3-2-1
kuralını**, ve restore tatbikatını otomasyonla disiplin haline
getirmeyi anlatır.

---

## 🎯 RPO ve RTO — Önce Hedefini Tanımla

| Terim | Anlam | Örnek |
|---|---|---|
| **RPO** (Recovery Point Objective) | Kabul edilebilir veri kayıp süresi | "Son 5 dakikadan fazla veri kaybedemeyiz" |
| **RTO** (Recovery Time Objective) | Kabul edilebilir downtime | "30 dakikada geri dönmeliyiz" |

> 🔑 RPO = backup sıklığını belirler. RTO = restore stratejisini belirler.

### Tipik hedefler
| Senaryo | RPO | RTO |
|---|---|---|
| Hobby project | 24 saat | 4 saat |
| Internal SaaS | 1 saat | 2 saat |
| Customer-facing prod | 5 dakika | 30 dakika |
| Finansal sistem | 0 (sync replication) | 5 dakika |
| Mission-critical | 0 | 0 (active-active) |

---

## 🪣 Backup Yöntemleri — Karşılaştırma

| Yöntem | RPO | RTO | Boyut | Karmaşık. | Kullanım |
|---|---|---|---|---|---|
| `pg_dump` | 24h | Yavaş (saatler) | Küçük | Düşük | Dev / küçük |
| `pg_basebackup` | 1 gün | Hızlı | Tam DB | Düşük | Tam DB image |
| **WAL-G + S3** | < 5 dk | Orta (PITR) | DB + WAL | Orta | **Çoğu prod sweet-spot** |
| **pgBackRest** | < 5 dk | Hızlı | Inkremental | Orta | Büyük prod |
| Streaming replica | 0 | Anlık (failover) | Tam DB × N | Yüksek | HA prod |
| **Logical replication** | < 1 dk | Orta | Subset | Orta | Selective DR |
| Cloud snapshot (RDS, EBS) | Saatlik | Hızlı | Block-level | Düşük | Managed/cloud |

---

## 1️⃣ `pg_dump` — Basit, Sadece Küçük DB için

```bash
# Single DB
pg_dump -h <DB_HOST> -U <USER> -d <DB> -F c -f /backups/db-$(date +%F).dump

# All DBs
pg_dumpall -h <DB_HOST> -U <USER> -f /backups/all-$(date +%F).sql

# Restore
pg_restore -h <DB_HOST> -U <USER> -d <DB> /backups/db-2026-05-04.dump
```

### ✅ Pro
- Kolay, herkes anlar
- Cross-version migration (downgrade/upgrade)
- Schema-only / data-only seçenek

### ❌ Con
- **Yavaş** (500 GB → saatler)
- Transaction tutarlılığı yetersiz (snapshot)
- Disk I/O yoğun
- PITR (point-in-time recovery) yok

> 🔑 **Production'da kullanma > 50 GB.** `pg_dump` archive amaçlı.

---

## 2️⃣ WAL-G — 2026'da Tavsiye

[WAL-G](https://github.com/wal-g/wal-g) Postgres + S3/GCS/Azure
backup tool'u. **Continuous archiving + base backup + PITR** sağlar.

### Kurulum
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

### Postgres tarafı
```ini
# postgresql.conf
archive_mode = on
archive_command = 'envdir /etc/postgresql/wal-g.env wal-g wal-push %p'
archive_timeout = 60       # 1 dk içinde WAL'ı push et
```

```bash
# İlk full backup
envdir /etc/postgresql/wal-g.env wal-g backup-push /var/lib/postgresql/data

# Cron: günlük base backup
0 2 * * * envdir /etc/postgresql/wal-g.env wal-g backup-push /var/lib/postgresql/data

# WAL otomatik archive_command ile gider
```

### Restore
```bash
# Liste
wal-g backup-list

# Latest
wal-g backup-fetch /var/lib/postgresql/data LATEST

# PITR — belirli zamana
wal-g backup-fetch /var/lib/postgresql/data LATEST
echo "restore_command = 'wal-g wal-fetch %f %p'" >> /var/lib/postgresql/data/postgresql.auto.conf
echo "recovery_target_time = '2026-05-04 14:30:00 UTC'" >> /var/lib/postgresql/data/postgresql.auto.conf
echo "recovery_target_action = 'promote'" >> /var/lib/postgresql/data/postgresql.auto.conf
touch /var/lib/postgresql/data/recovery.signal
systemctl start postgresql
```

### ✅ Pro
- Continuous WAL archiving (RPO < 5 dk)
- Encrypted at rest (S3 SSE + WAL-G GPG)
- Compression (brotli)
- Delta backups (incremental)
- Open source

### ❌ Con
- Setup biraz teknik
- Self-managed (bakım gerekir)

---

## 3️⃣ pgBackRest — Büyük Prod İçin

pgBackRest (Crunchy Data) **çok büyük DB** (TB+) için optimize.

### Avantajlar
- Parallel backup/restore (8+ thread)
- Inkremental + diferansiyel
- Repository encryption
- Backup verification (CRC + readback)
- Stanza (multiple cluster yönetimi)

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

### Kullanım
```bash
# Stanza oluştur
pgbackrest --stanza=main --log-level-console=info stanza-create

# Full backup
pgbackrest --stanza=main --type=full backup

# Incremental (cron her saat)
pgbackrest --stanza=main --type=incr backup

# Restore + PITR
pgbackrest --stanza=main \
  --type=time \
  --target="2026-05-04 14:30:00" \
  restore
```

---

## 4️⃣ Streaming Replication — Sıfır RPO Hedefi

```ini
# Primary: postgresql.conf
wal_level = replica
max_wal_senders = 10
synchronous_standby_names = '*'   # zorunlu sync
synchronous_commit = on

# Standby: postgresql.conf
hot_standby = on
primary_conninfo = 'host=<PRIMARY> user=replicator password=<PWD> application_name=standby1'
```

```sql
-- Primary'de replication user
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD '<PWD>';
```

> 🔑 **`synchronous_commit = on`** ile RPO = 0 ama latency artar (commit standby'a kadar bekler).

### Auto-failover: Patroni / CloudNativePG
- Patroni: standalone, etcd/consul DCS
- CloudNativePG: K8s operator, modern, recommended

Detay: [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md) (sonraki batch).

---

## 🔐 3-2-1 Kuralı

```
3  kopya  (1 production + 2 backup)
2  farklı medium  (örn: disk + S3)
1  off-site  (farklı cloud / region / fiziksel)
```

### Pratik uygulama
```
1. Production DB (primary)
2. Streaming replica (sync, aynı region)
3. WAL-G S3 backup (aynı region) — Copy 1
4. WAL-G S3 backup cross-region replication → us-west-2 — Copy 2
5. Off-site: glacier-tier 90 gün retention
```

> 🔑 **Off-site** kritik — region-wide felaketten korur (rare ama olur).

---

## 🧪 Restore Tatbikatı — En Önemli Disiplin

> "Test edilmemiş backup, **backup değildir**."

### Quarterly drill protokolü
```
1. Boş cluster ayağa kaldır (scratch K8s namespace)
2. Son full backup'ı restore et
3. PITR ile son 1 saatlik WAL'ı uygula
4. Smoke test:
   - Schema integrity
   - Row count makul mü
   - App bağlanabiliyor mu
   - Critical query çalışıyor mu
5. RTO ölçümle
6. Postmortem: gap varsa düzelt
```

### Otomasyon
```yaml
# .github/workflows/backup-drill.yml
name: Quarterly Backup Restore Drill

on:
  schedule:
    - cron: '0 6 1 1,4,7,10 *'   # Q1, Q2, Q3, Q4 ilk gün

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

## 🔒 Backup Güvenliği

| Risk | Mitigasyon |
|---|---|
| Backup S3 bucket public | Bucket policy: deny public, IAM least-privilege |
| Backup unencrypted | S3 SSE + WAL-G GPG / pgBackRest cipher |
| Saldırgan backup'ı sildi | S3 versioning + MFA delete + cross-account |
| Ransomware → backup şifrelendi | Immutable storage (S3 Object Lock) |
| Eski backup hâlâ aktif user data | Retention policy + GDPR uyum |
| Backup credentials Git'te | Vault + ESO |

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

> 🔑 30 gün boyunca **kimse** silemez (admin dahil). Ransomware koruması.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| `pg_dump` 500 GB DB | Saatler sürer, transaction inconsistent | WAL-G veya pgBackRest |
| Backup test edilmemiş | Kriz anında işlemez | Quarterly restore drill |
| Backup aynı region'da | Region down → veri kayıp | Cross-region replication |
| Backup public S3 | Veri sızıntısı | IAM + encryption + private |
| Backup retention sonsuz | Storage maliyeti + KVKK ihlali | Lifecycle policy |
| Backup credentials Git'te | Compromise = backup compromise | Vault + ESO |
| RTO/RPO yazılı değil | Kriz anında karar yok | SLO doc'unda yazılı |
| Manuel backup script | Ekip değiştiğinde unutulur | Cron + monitoring + alert |
| Backup başarısız → kimse görmez | Sessiz kayıp | Alert: backup-success metric |
| Restore prosedürü dokumante değil | Junior gece yapamaz | Runbook + drill |
| `pg_dump` + filesystem snapshot | Inconsistent (snapshot mid-write) | pg_basebackup veya WAL-G |
| Test environment prod backup'ı kullanır | PII leak (KVKK ihlali) | Anonymized restore |

---

## 📋 Backup Strategy Checklist

```
[ ] RPO + RTO yazılı (SLO doc)
[ ] WAL-G veya pgBackRest kurulu
[ ] Continuous WAL archiving aktif
[ ] Daily full backup cron'da
[ ] Backup encryption-at-rest (KMS)
[ ] Backup encryption-in-transit (TLS)
[ ] 3-2-1 kuralı: 3 kopya, 2 medium, 1 off-site
[ ] Cross-region replication
[ ] S3 Object Lock (ransomware koruması)
[ ] S3 versioning + MFA delete
[ ] Retention policy: KVKK/GDPR uyum
[ ] Monitoring: backup-success metric + alert
[ ] Backup boyut trend dashboard
[ ] Quarterly restore drill
[ ] Drill RTO ölçülüyor
[ ] Restore runbook dokümanı
[ ] PITR çalıştığı doğrulanmış
[ ] Backup credentials Vault'ta
[ ] Test environment anonymized DB kullanıyor
[ ] Annual: DR plan tatbikatı (bütün stack)
```

---

## 📚 Referanslar

- **WAL-G** — github.com/wal-g/wal-g
- **pgBackRest** — pgbackrest.org
- **PostgreSQL Backup Documentation** — postgresql.org/docs/current/backup.html
- **3-2-1 Rule** — yaygın industry pratiği
- [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md)
- [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md)
- [`Zero-Downtime-Migrations.md`](Zero-Downtime-Migrations.md)
- [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md) — backup creds
- [`19-Compliance/KVKK-Practical.md`](../19-Compliance/KVKK-Practical.md) — retention policy
- [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md) — DR akışı

---

> *"Backup yapmak kolay; **restore yapmak** maharettir. Test edilen
> backup, müşteri verisinin sigortasıdır. Test edilmemiş ise sadece
> bir **rahatlama hapı**."*
