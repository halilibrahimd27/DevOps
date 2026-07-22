# Hint 2 — daralt

Üç backup'ı **dosya seviyesinde** incele; restore'u denemeden önce çoğu şeyi görürsün.

**nightly.sql — veri var mı?**
```bash
grep -c '^COPY ' env/backups/nightly.sql      # 0 → hiç veri bloğu yok
```
`pg_dump --schema-only` ile alınmış: tablolar oluşur, satır **gelmez**. Restore
sorunsuz döner, `count(*)` = 0. Sessiz arıza budur.

**weekly.sql — tam mı?**
```bash
tail -n 3 env/backups/weekly.sql              # sonunda '\.' yok
```
Dump'ın sonu kesilmiş; `COPY` bloğu `\.` ile kapanmıyor. Restore denersen `psql`
gürültüyle hata verir (`unterminated COPY` / `missing data`). Bozuk/eksik dosya.

**monthly.sql — okunabiliyor mu?**
```bash
ls -l env/backups/monthly.sql                 # ----------  (izin 000)
docker compose -f env/compose.yaml exec -T db_restore \
  psql -U postgres -d shop < env/backups/monthly.sql   # Permission denied
```
Dosya iyi ama **izin yok**. Erişemediğin bir backup, incident anında yok hükmündedir.

Üç bulgunu da not al. Yalnız biri gerçekten kullanılabilir — hangisi ve niçin?
