# Hint 3 — neredeyse cevap

`EnvironmentFile=/etc/k00-app/app.env` satırındaki dosya **yok.** Unit'te `-` öneki
olmadığı için bu dosya **zorunlu**; systemd onu bulamayınca servisi hiç başlatmaz.

Doğru düzeltme: dosyayı **oluştur** (uygulamanın beklediği `APP_PORT` ile):

```bash
sudo install -d /etc/k00-app
printf 'APP_PORT=8080\n' | sudo tee /etc/k00-app/app.env
sudo chown k00svc:k00svc /etc/k00-app/app.env
sudo chmod 600 /etc/k00-app/app.env
sudo systemctl restart k00-app
```

> "`-` önekiyle opsiyonel yaparım" da bir seçenek gibi görünür ama yanlış: env
> dosyası gerçekten gerekiyorsa onu susturmak sorunu gizler, çözmez.
