# L20 — Referans çözüm

> **Önce kendin dene.** Restore'u elle yapmadan "backup'ım var" bir güvence değil,
> bir varsayımdır.

## Akış

Komutların tamamı [`backup-restore.sh`](backup-restore.sh)'de. Özet:

```bash
cd starter && docker compose up -d

# 1) kaynak: 1000 satır
docker compose exec db psql -U postgres -d shop -c "SELECT count(*) FROM orders;"

# 2) backup (veri dahil)
docker compose exec db pg_dump -U postgres -d shop > backup.sql

# 3) restore + süre ölç → RTO
time docker compose exec -T db_restore psql -U postgres -d shop < backup.sql

# 4) bütünlük: hedefte de 1000
docker compose exec db_restore psql -U postgres -d shop -c "SELECT count(*) FROM orders;"
```

## RTO ve RPO

- **RTO** (Recovery Time Objective): burada `time` çıktısındaki restore süresi. Küçük
  bir DB'de saniyeler; production'da yöntem (logical dump vs fiziksel + PITR) ve boyut
  belirler. RTO'yu **önceden** ölçmezsen, incident anında öğrenirsin.
- **RPO** (Recovery Point Objective): kabul edilen veri kaybı penceresi. Gecelik tek
  backup → en kötü durumda son backup'tan bu yana geçen ~24 saatlik veri kaybolabilir.
  RPO'yu küçültmek (sık backup / sürekli WAL arşivi / senkron replikasyon) daha pahalıdır.

## Erişim + at-rest şifreleme

`backup.sql` veritabanının **tamamıdır** — genelde en zayıf erişim kontrollü kopyadır.
Kontrol:
- **Erişim:** dosyaya/bucket'a kim erişebilir? Prensip: canlı DB'ye erişemeyen backup'a
  da erişememeli. Açık bir bucket tüm veriyi sızdırır.
- **At-rest şifreleme:** backup diskte/nesne deposunda şifreli mi (SSE / KMS)? Yedek,
  canlı DB kadar korunmalı.
- **Yer:** production'da backup, kaynaktan **ayrı bir arıza alanında** (farklı bölge/hesap)
  tutulmalı — aynı diskteki backup, diski kaybettiğinde işe yaramaz.

## Sık hata: `--schema-only`

`pg_dump --schema-only` yalnız tabloları oluşturur, veriyi almaz. Restore "başarılı"
görünür ama satır sayısı **0** çıkar. Bu, [`K08`](../../../broken/K08-restore-basarisiz/)
kırık lab'ının tam olarak öğrettiği tuzaktır: restore'u satır sayısıyla doğrulamazsan,
boş bir backup'ı "çalışıyor" sanırsın.

## Ders

Backup'ın alınması onun geri yüklenebildiğini kanıtlamaz. Kanıt, **temiz bir ortama
restore + satır/checksum doğrulaması**dır. RTO ve RPO'yu sakin bir günde ölç; incident
anında değil.
