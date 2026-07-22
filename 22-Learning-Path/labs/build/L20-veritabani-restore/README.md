# L20 — Backup al, **temiz bir ortama restore et**, bütünlüğü kanıtla

> Modül: [`E4`](../../../block-e-ownership/E4-veritabani-restore.md) · Süre: ~3 saat · Kırık lab: [`K08`](../../broken/K08-restore-basarisiz/)

"Backup her gece alınıyor" bir güvence değildir. Güvence, o backup'ın **temiz bir
ortama gerçekten geri yüklenebildiğini** görmektir. Burada seed'li bir Postgres'ten
backup alır, onu **boş** ikinci bir Postgres'e restore eder, satır sayısıyla
bütünlüğü kanıtlar; sonra restore süreni (RTO) ve veri kaybı pencereni (RPO) ölçer.

## Gerekenler
- `docker` + `docker compose` (yerel; bulut **gerekmez**).

## Görev

1. **Yığını başlat.** `db` (kaynak, 1000 satır seed) + `db_restore` (boş hedef).
   ```bash
   cd starter && docker compose up -d
   # db:          127.0.0.1:5432   (seed.sql ile 1000 satır)
   # db_restore:  127.0.0.1:5433   (boş)
   ```
2. **Kaynağı doğrula.** `db`'de `orders` tablosunda **1000** satır olduğunu gör:
   ```bash
   docker compose exec db psql -U postgres -d shop -c "SELECT count(*) FROM orders;"
   ```
3. **Backup al** (`db` → dosya). `pg_dump` kullan, **--schema-only DEĞİL** (veri dahil):
   ```bash
   docker compose exec db pg_dump -U postgres -d shop > backup.sql
   ```
4. **Restore et** (dosya → `db_restore`, temiz ortam) ve **süreyi ölç**:
   ```bash
   time docker compose exec -T db_restore psql -U postgres -d shop < backup.sql
   ```
   `time` çıktısındaki süre senin ölçülen **RTO**'ndur.
5. **Bütünlüğü kanıtla.** `db_restore`'da da **1000** satır olmalı:
   ```bash
   docker compose exec db_restore psql -U postgres -d shop -c "SELECT count(*) FROM orders;"
   ```
6. **Raporla.** `report.txt`'e yaz:
   - restore sonrası satır sayısı (= 1000) ve kaynakla eşleştiği,
   - **RTO** (ölçülen restore süresi) ve **RPO** (gecelik backup için ~24 saatlik pencere; niçin),
   - **erişim + at-rest şifreleme** kontrolü: bu backup dosyasına kim erişebilir, şifreli mi, gerçek ortamda nerede saklanmalı.

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `report.txt` restore sonrası satır sayısını (1000) ve kaynakla eşleştiğini içeriyor.
- [ ] `report.txt` ölçülen **RTO** ve **RPO**'yu (pencere + niçin) içeriyor.
- [ ] `report.txt` backup'ın erişim + at-rest şifreleme kontrolünü içeriyor.

## İpucu (çözüm değil)
- Restore "çalıştı" ama satır sayısı 0 ise backup'ını `--schema-only` almış olabilirsin
  — dump dosyasının içinde `COPY`/`INSERT` veri satırları var mı bak.
- RTO = geri gelme süresi (kesinti hedefi). RPO = kabul edilen veri kaybı penceresi.
  Gecelik tek backup → en kötü durumda ~24 saatlik veri kaybı riski.
- Backup, veritabanının tamamıdır; en az canlı DB kadar korunmalı — açık dosya/bucket
  tüm veriyi sızdırır.

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
