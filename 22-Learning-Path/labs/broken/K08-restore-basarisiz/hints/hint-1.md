# Hint 1 — yön

Restore komutu `exit 0` döndü ama `orders` **0 satır**. İlk ders burada: restore'un
başarısını **çıkış koduyla değil, satır sayısıyla** ölçersin. `psql` bir dosyayı
sorunsuz "çalıştırabilir" — dosyanın içinde hiç veri yoksa yine 0 döner ve sana hata
vermez.

Elinde tek backup yok, **üç** var (`env/backups/`). İlkini kullanıp geçme. Her birini
ayrı ayrı temiz hedefe dene ve **her denemeden sonra** say:

```bash
ls -l env/backups
# her denemeden önce hedefi temizle, sonra restore et, sonra:
docker compose -f env/compose.yaml exec -T db_restore \
  psql -U postgres -d shop -tAc "SELECT count(*) FROM orders;"
```

Üçü aynı derecede güvenilir değil: biri sessizce boş gelir, biri gürültüyle patlar,
biri hiç okunamaz. Hangisinin hangisi olduğunu bir sonraki adımda ayır.
