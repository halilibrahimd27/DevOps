# K00 — Çözüm

> **Önce kendin dene.** Aşağıda önce **teşhis akışı** var — asıl öğrenilecek şey o.
> Kök sebep en sonda.

## Teşhis akışı (nasıl bulunur)

1. **Servis başlamıyor → systemd'e sor.**
   ```bash
   systemctl status k00-app --no-pager
   ```
   Çıktıda `Failed to load environment files` / `Changing to the requested working
   directory failed` benzeri bir satır ve `status=219/…` görürsün.

2. **Detayı journalctl'de doğrula.**
   ```bash
   journalctl -u k00-app -e
   ```
   Hata, uygulamanın Python koduna **hiç ulaşmadığını** gösterir — sorun app'te değil,
   systemd'in başlatma ön-hazırlığında.

3. **Unit'in okumaya çalıştığı dosyaları listele.**
   ```bash
   systemctl cat k00-app
   ls -l /opt/k00-app/app.py     # var
   ls -l /etc/k00-app/app.env    # YOK
   ```
   `EnvironmentFile` yolu mevcut değil.

## Kök sebep

Unit `EnvironmentFile=/etc/k00-app/app.env` diyor ama o dosya yok. `-` öneki
olmadığı için systemd bunu **zorunlu** kabul eder ve dosyayı bulamayınca servisi
başlatmaz. Uygulama hiç çalışmaz → port 8080 kapalı → `curl` "connection refused".

## Düzeltme

```bash
sudo install -d /etc/k00-app
printf 'APP_PORT=8080\n' | sudo tee /etc/k00-app/app.env
sudo chown k00svc:k00svc /etc/k00-app/app.env
sudo chmod 600 /etc/k00-app/app.env
sudo systemctl restart k00-app
systemctl is-active k00-app          # active
curl -s http://127.0.0.1:8080/health # ok
```

## Niye böyle oluyor

systemd bir servisi başlatmadan önce ortamı hazırlar: kullanıcı, çalışma dizini,
ortam dosyaları. Bu adımlardan biri başarısızsa `ExecStart` **hiç çalışmaz**.
Bu yüzden "uygulama mı bozuk, systemd hazırlığı mı bozuk" ayrımı ilk refleks olmalı:
`status` + `journalctl` bu ayrımı saniyede verir.

## Ders

"Connection refused" her zaman uygulama hatası değildir — servis o porta hiç
gelmemiş olabilir. Zinciri **başlatma → bağlanma** sırasıyla yürü.
