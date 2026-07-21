# L07 — Referans çözüm

> **Önce kendin dene.** journalctl süzgeçleri parmak hafızasına ancak arıza
> ararken girer.

## Üç arıza, üç süzgeç

| Arıza | Belirti | Bulan komut | Neden o komut |
|---|---|---|---|
| (a) Bozuk `EnvironmentFile` | Servis hiç başlamıyor | `journalctl -u lab-app -e` + `systemctl status lab-app` | Başlatma hataları unit journalinde, en sonda |
| (b) Port çakışması (8000 dolu) | Başlıyor, hemen ölüyor | `journalctl -u lab-app -p err` | Yalnız hata seviyesi → `Address already in use` net görünür |
| (c) Log dizini izinsiz | Çalışıyor ama yazamıyor | `journalctl -u lab-app --since "5 min ago"` | Zaman penceresi, gürültüyü keser |

Genel refleks:
```bash
systemctl status lab-app --no-pager        # başlamıyor mu, ölüyor mu?
journalctl -u lab-app -p err -e            # hata satırları
journalctl -u lab-app --since "10 min ago" # yeni olaylar
journalctl -u lab-app -b -1                 # önceki boot (reboot sonrası)
```

## Sır sızıntısı

`starter/leaky.py` şu satırı basar:
```
... INFO kullanici giris denemesi, parola=<DB_PASSWORD>
```
Bu satır journald'a, oradan log dosyalarına ve muhtemelen merkezi bir SIEM'e gider.
Sır artık **birçok yerde** ve geri alınamaz — log rotasyonu bile geç kalır.

**Düzeltme — kaynakta:**
```python
# Sırrı hiç loglama; en fazla var/yok:
logging.info("giris denemesi, parola_saglandi=%s", bool(password))
```

Güvenli satır (`guvenli-log.txt`):
```
2026-01-01T10:00:00 INFO giris denemesi, parola_saglandi=True
```

> Ne loglanır: zaman, seviye, olay, request id. Ne loglanmaz: parola, token, tam
> kart no, kişisel veri. 🇹🇷 KVKK: kişisel veriyi log'a düşürmek de bir "işleme"dir
> — gerekmiyorsa hiç yazma.
