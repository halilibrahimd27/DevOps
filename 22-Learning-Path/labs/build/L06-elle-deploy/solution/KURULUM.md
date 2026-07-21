# KURULUM — lab-app elle deploy (referans)

> **Önce kendin yap.** Bu dosya, takıldığında bakman içindir. Komutları körü körüne
> kopyalarsan lab'ın amacı — soyutlamaların çözdüğü acıyı hissetmek — kaybolur.
> Yollar örnektir; dağıtımına göre uyarla.

## 1. Uygulama + servis kullanıcısı
```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin labsvc
sudo mkdir -p /opt/lab-app /var/log/lab-app /etc/lab-app
sudo cp app.py /opt/lab-app/app.py
sudo chown -R labsvc:labsvc /opt/lab-app /var/log/lab-app
```

## 2. PostgreSQL
```bash
sudo apt-get update && sudo apt-get install -y postgresql
sudo -u postgres psql <<'SQL'
CREATE DATABASE labdb;
CREATE USER labuser WITH PASSWORD 'REPLACE_WITH_YOUR_OWN';
GRANT CONNECT ON DATABASE labdb TO labuser;
SQL
```
> Parolayı burada gördüğün `REPLACE_WITH_YOUR_OWN` yerine **kendin** koy ve yalnız
> `EnvironmentFile`'a yaz — koda ya da git'e değil.

## 3. Ortam dosyası (parola burada, mod 600)
```bash
sudo cp app.env.example /etc/lab-app/app.env
sudo nano /etc/lab-app/app.env         # PGPASSWORD'ü gerçek değerle değiştir
sudo chown labsvc:labsvc /etc/lab-app/app.env
sudo chmod 600 /etc/lab-app/app.env
```

## 4. systemd unit
```bash
sudo cp lab-app.service /etc/systemd/system/lab-app.service
sudo systemctl daemon-reload
sudo systemctl enable --now lab-app
systemctl status lab-app --no-pager
curl -s http://127.0.0.1:8000/health   # ok
```

## 5. nginx ters vekil
```bash
sudo apt-get install -y nginx
sudo cp nginx-lab-app.conf /etc/nginx/sites-available/lab-app
sudo ln -sf ../sites-available/lab-app /etc/nginx/sites-enabled/lab-app
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
curl -s http://127.0.0.1/health        # ok  (port 80, nginx üzerinden)
```

## 6. Firewall
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw enable
# 8000 dışarı kapalı: uygulama zaten 127.0.0.1 dinliyor, ufw'de de açmadık.
ss -tlnp | grep -E ':80|:8000'         # nginx 0.0.0.0:80, app 127.0.0.1:8000
```

## 7. Reboot testi
```bash
sudo reboot
# geri geldiğinde:
systemctl is-enabled lab-app   # enabled
systemctl is-active  lab-app   # active
curl -s http://127.0.0.1/health
```

## 8. En çok zamanı ne aldı?
Genelde: paket kurulumu değil, **sıralama ve izinler** — systemd `After=`, dosya
sahipliği, nginx symlink, firewall. C1'de göreceğin container tam olarak bunu bir
`Dockerfile` + `compose.yaml`'a dondurur: her deploy'da aynı adımları elle
tekrarlamak yerine tek komutla ayağa kalkar. L06'nın acısı, C1'in değerini ölçer.
