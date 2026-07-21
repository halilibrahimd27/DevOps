# L07 — Log okuma: journalctl ile arıza bul, sırrı sızdırma

> Modül: [`B1`](../../../block-b-visibility/B1-log-okuma.md) · Süre: ~1–2 saat · Kırık lab: yok

A6'da kurduğun uygulamayı **üç farklı şekilde** bozar, her birini yalnız
`journalctl` süzgeçleriyle bulursun. Sonra bir log satırının bir sırrı
(parola/token) nasıl sızdırdığını görüp güvenli hâle getirirsin. "Göremediğin
sistemi yönetemezsin" — log okumak bunun ilk yarısıdır.

## Gerekenler
- L06'daki `lab-app` çalışır durumda (systemd + journald). `journalctl` erişimi.

## Görev

1. **Üç arıza üret** (birer birer, her seferinde düzeltip devam et):
   - (a) `EnvironmentFile`'ı bozup servisi başlat → başlatma hatası.
   - (b) Uygulama portunu nginx'inkiyle çakıştır → bind hatası.
   - (c) Log dizini iznini kaldır → çalışırken yazma hatası.
2. **Her birini yalnız journalctl ile bul.** Şu süzgeçleri kullan ve hangisinin
   işe yaradığını `report.txt`'e yaz:
   - `journalctl -u lab-app -e` (son satırlar)
   - `journalctl -u lab-app -p err` (yalnız hata seviyesi)
   - `journalctl -u lab-app --since "10 min ago"` (zaman penceresi)
   - `journalctl -u lab-app -b` (bu boot) / `-b -1` (önceki boot)
3. **Sır sızıntısı.** `starter/leaky.py`'yi çalıştır — log'a bir parola basar.
   Bunun neden tehlikeli olduğunu ve nasıl düzeltileceğini (`***` maskeleme /
   sırrı hiç loglamama) `report.txt`'e yaz. Düzeltilmiş satırı `guvenli-log.txt`'e koy.

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `report.txt` üç arızayı ve her birini bulan `journalctl` süzgecini gösteriyor.
- [ ] `report.txt` sır sızıntısını ve düzeltmesini açıklıyor.
- [ ] `guvenli-log.txt` içinde açık parola/token **yok**.

## İpucu (çözüm değil)
- Servis başlamıyor mu, çalışırken mi ölüyor? `journalctl -u lab-app -p err` +
  `systemctl status` ikilisi ayrımı hemen verir.
- "Ne loglanır": zaman, seviye, olay, ilişki kimliği (request id). "Ne loglanmaz":
  parola, token, tam kart no, kişisel veri (🇹🇷 KVKK).
- Maskeleme kaynakta yapılır: sırrı log'a hiç vermemek, `***` basmaktan iyidir.

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
