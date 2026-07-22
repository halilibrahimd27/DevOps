# Hint 3 — neredeyse cevap

Üç backup, tek gerçek kurtarma yolu: **monthly** (tam veri) — ama önce erişimini aç.

```bash
# 1) erişim arızasını gider
chmod u+r env/backups/monthly.sql

# 2) hedefi temiz başlat (önceki denemelerden kalıntı kalmasın)
docker compose -f env/compose.yaml exec -T db_restore \
  psql -U postgres -d shop -c "DROP TABLE IF EXISTS orders;"

# 3) tam backup'ı restore et
docker compose -f env/compose.yaml exec -T db_restore \
  psql -U postgres -d shop < env/backups/monthly.sql

# 4) satır sayısıyla DOĞRULA (kabul kriteri bu, çıkış kodu değil)
docker compose -f env/compose.yaml exec -T db_restore \
  psql -U postgres -d shop -tAc "SELECT count(*) FROM orders;"   # 1000
```

Neden diğer ikisi olmaz:
- **nightly.sql** = `--schema-only` → 0 satır (sessiz).
- **weekly.sql** = sonu kesik dump → restore hata verir (gürültülü).

`teshis.md`'ye üç dosyanın tanısını, hangisini kullandığını ve "restore'u satır
sayısıyla doğrulamak" dersini yaz. Tam teşhis akışı: `solution.md`.
