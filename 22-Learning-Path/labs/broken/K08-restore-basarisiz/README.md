# K08 — "Restore ettik ama veri yok" — çok-katmanlı restore arızası

> Modül: [`E4`](../../../block-e-ownership/E4-veritabani-restore.md) · Tür: kırık lab · Süre: ~60–120 dk

## Belirti

Prod `shop` veritabanının `orders` tablosu boşaldı. Ekip "her gece backup alıyoruz"
diyor; `env/backups/` altında **üç** dosya var. Gece backup'ından restore ettin,
komut hatasız döndü, uygulama açıldı — ama **hiç sipariş yok**:

```bash
# restore "başarılı" göründü, ama:
docker compose -f env/compose.yaml exec -T db_restore \
  psql -U postgres -d shop -tAc "SELECT count(*) FROM orders;"
# 0
```

Kaynakta **1000** satır olması gerekiyordu. Elindeki backup'lardan veriyi temiz
hedefe (`db_restore`) geri getir. README ne bozulduğunu söylemez — belirti bu kadar.

> ⚠️ Burada **tek** bir arıza yok. İlk denediğin backup seni yanıltabilir; üç dosyanın
> hepsi aynı derecede güvenilir değil. "Restore başarılı döndü" bir kanıt değildir.

## Gerekenler
- `docker` + `docker compose` (yerel; bulut **gerekmez**).

## Kur

```bash
bash setup.sh
```

Bu; seed'li bir kaynak `db` (1000 satır) + boş bir `db_restore` hedefi ayağa kaldırır
ve `env/backups/` altına gerçek ekip gibi üç backup dosyası bırakır.

## Görevin

1. **Her backup'ı test et, körlemesine güvenme.** Üç dosyanın hangisi gerçekten tam
   veriyi geri getiriyor? Her restore denemesini **satır sayısıyla** doğrula — çıkış
   kodu değil, `count(*)`.
2. **Kök sebe(pler)i kanıtla.** Boş gelen / hata veren / erişilemeyen backup'ların her
   biri niçin öyle? Tahmine değil, dosyanın içeriğine/izinlerine bak.
3. **Veriyi geri getir.** `db_restore`'da `orders` **1000** satır olana kadar devam et.
4. **Doğrula:**
   ```bash
   bash verify.sh    # sıfır çıkış = 1000 satır restore edildi + teşhis yazıldı
   ```
5. **`teshis.md` yaz:** her backup dosyası için tek satır tanı (hangisi neden kötü),
   hangisini kullandın, ve **restore'u niçin satır sayısıyla doğrulamak gerektiği**.

## Kurallar

- **Önce kendin dene.** `hints/`'i sırayla aç; `solution.md` en son.
- Restore'un `exit 0` dönmesi "veri geldi" demek değildir. Kabul kriterin `count(*)`,
  çıkış kodu değil.
- Backup, veritabanının tamamıdır: en zayıf erişim kontrollü kopya odur. Erişemediğin
  bir backup, incident anında **yok** hükmündedir.
