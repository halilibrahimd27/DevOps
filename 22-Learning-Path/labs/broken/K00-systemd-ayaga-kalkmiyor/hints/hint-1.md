# Hint 1 — yön

Servis başlamıyorsa **systemd sana neden başlamadığını söyler.** Tahmin etme, sor:

```bash
systemctl status k00-app --no-pager
journalctl -u k00-app -e
```

İlk hata satırını dikkatle oku. systemd, uygulamayı **çalıştırmadan önce** bazı
şeyleri hazırlar — dosya sıralaması hata mesajında saklıdır.
