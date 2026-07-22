# K08 — Çözüm

> **Önce kendin dene.** Önce **teşhis akışı**, sonra kök sebep. Bu lab'da asıl ölçülen
> şey tek komut değil, "restore başarılı döndü" yanılgısına karşı **kanıt disiplinin**.

## Teşhis akışı

1. **Restore'u çıkış koduyla değil satır sayısıyla ölç.**
   Gece backup'ı hatasız döndü ama hedefte 0 satır. İlk refleks "komut çalıştı" değil,
   "veri geldi mi?" olmalı:
   ```bash
   docker compose -f env/compose.yaml exec -T db_restore \
     psql -U postgres -d shop -tAc "SELECT count(*) FROM orders;"
   ```

2. **Üç backup'ı tek tek, dosya seviyesinde ayır.** Restore'u denemeden çoğu tanıyı
   dosyadan görürsün:
   ```bash
   grep -c '^COPY ' env/backups/nightly.sql   # 0 → veri bloğu yok (schema-only)
   tail -n 3 env/backups/weekly.sql           # '\.' yok → COPY sonlanmamış (kesik)
   ls -l env/backups/monthly.sql              # ---------- → izin 000 (erişilemez)
   ```

3. **Her hipotezi restore ile doğrula.** nightly → 0 satır; weekly → `psql` hata
   (`unterminated COPY`/`missing data`); monthly → `Permission denied`.

## Kök sebep (üç bağımsız katman)

| Dosya | Arıza | Belirti | Ders |
|---|---|---|---|
| `nightly.sql` | `pg_dump --schema-only` — veri yok | restore 0 hata, **0 satır** | "Başarılı döndü" ≠ veri geldi; `count(*)` ile doğrula |
| `weekly.sql` | dump sonu kesik — `COPY` sonlanmamış | restore **hata verir** | Bozuk/eksik dosya gürültülüdür; yine de geç bulunur |
| `monthly.sql` | izin `000` — okunamıyor | `Permission denied` | Erişemediğin backup = incident anında **yok** |

Tek gerçekten kullanılabilir backup **monthly** — ama erişimi açılmadan işe yaramaz.
Üçünü de körlemesine denemek, ilk "başarılı" görünende (nightly) durup boş veriyle
prod'u açmana yol açar. Gerçek arıza budur.

## Düzeltme

```bash
# erişim arızasını gider
chmod u+r env/backups/monthly.sql

# temiz hedef (önceki denemelerin kalıntısını at)
docker compose -f env/compose.yaml exec -T db_restore \
  psql -U postgres -d shop -c "DROP TABLE IF EXISTS orders;"

# tam backup'ı restore et + süreyi ölç (RTO)
time docker compose -f env/compose.yaml exec -T db_restore \
  psql -U postgres -d shop < env/backups/monthly.sql

# kanıt: 1000
docker compose -f env/compose.yaml exec -T db_restore \
  psql -U postgres -d shop -tAc "SELECT count(*) FROM orders;"
```

## Teslimat (`teshis.md`)

- Üç backup'ın tek satırlık tanısı (yukarıdaki tablo).
- Hangisini kullandın ve niçin (monthly + izin düzeltmesi).
- **Restore'u niçin satır sayısıyla doğrulamak gerekir** — çıkış kodu boş backup'ı
  ele vermez.
- (Bonus) bu üç arızanın her biri hangi kontrolle **önceden** yakalanırdı: her backup
  sonrası otomatik test-restore + satır sayısı; backup dosyası erişim denetimi.

## Ders

Backup'ın alınması onun geri yüklenebildiğini kanıtlamaz; erişilebildiğini ve **tam**
olduğunu da kanıtlamaz. Üç ayrı sessiz tuzak — eksik dump, bozuk dump, erişilemez dump —
yalnızca restore'u temiz bir ortama yapıp **satır sayısıyla** doğruladığında ortaya
çıkar. "Başarılı döndü" bir umuttur; `count(*) = 1000` bir kanıttır.
