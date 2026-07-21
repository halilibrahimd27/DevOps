---
description: "Bir uygulamayı elle ayağa kaldır: VM, nginx, bir DB, systemd unit ve log — container YOK. Patikanın çıpası."
level: A
module: A6
estimated_hours: 27
prerequisites: [A1, A2, A3, A4, A5]
tags: [Learning Path, Deployment]
---
# A6 — Bir Uygulamayı Elle Ayağa Kaldır (Container YOK)

> *"Sonraki her soyutlamanın neyi çözdüğünü, o soyutlamadan önceki acıyı yaşamış olan bilir. Bu modül o acıdır."*

**Blok:** A — Sezgi · **Süre:** ~27 saat · **Ön koşul:** [`A1`](A1-linux-temeli.md), [`A2`](A2-ag-tcp-ip.md), [`A3`](A3-ag-dns-http-tls.md), [`A4`](A4-git-temeli.md), [`A5`](A5-bash.md)

## 🎯 Bu modülü bitirdiğinde
- Bir VM üzerinde nginx + bir veritabanı + bir uygulamayı **elle**, adım adım ayağa kaldırırsın.
- Uygulamayı bir `systemd` unit'i olarak tanımlar, yeniden başlatmada (reboot) ayakta kalmasını sağlarsın.
- Servis loglarını `journalctl` ve nginx log dosyalarından bulur, okur ve bir arızayı bu bilgiyle daraltırsın.

## 🧠 Niye bu, niye şimdi
Bu modül kasıtlı olarak zahmetlidir ve **kolaylaştırılmamalıdır.** Deploy elle yapılır,
bozulur, elle düzeltilir. Container (C1), Terraform (C3) ve K8s (D1) sonradan geldiğinde,
her birinin *tam olarak hangi elle-işi* ortadan kaldırdığını buradan bileceksin.
"Neden container?" sorusunun cevabı, bu modülde çektiğin acıdır: bağımlılık kurulumu,
"benim makinemde çalışıyordu", port çakışması, servis boot'ta gelmiyor. C3'te bu adımların
tamamını Terraform ile otomatikleştireceğiz — ama otomatikleştirdiğin şeyi bir kez elle
yapmadan, otomasyonun ne yaptığını göremezsin.

## 📖 Nasıl çalışılır
Ücretsiz, yerel bir Linux VM'inde çalış. Seçenekler (birini seç):
- **Multipass** (`multipass launch --name lab`) — en hızlı, Ubuntu VM.
- **Vagrant + VirtualBox** — taşınabilir, `Vagrantfile` ile tekrarlanabilir.
- **Proxmox / KVM** — kendi sunucun varsa (bkz. [`21-Field-Notes/`](../../21-Field-Notes/)).

Her komutu **VM içinde** çalıştır, ana makinende değil. Bir adım bozulduğunda önce log'a
bak, hint arama. Bozulma bu modülün dersidir. Yaptığın her adımı bir `KURULUM.md`
dosyasına not al — A4'te öğrendiğin Git ile versiyonla; bu notlar C3'te Terraform'a
çevireceğin şablondur.

## 📚 Ne kuracaksın — mimarî
```
İnternet / tarayıcı
        │  :80 / :443
        ▼
   ┌─────────┐      :80/tcp açık, gerisi kapalı
   │  nginx  │  ── reverse proxy (isteği uygulamaya geçirir)
   └────┬────┘
        │  127.0.0.1:<APP_PORT>  (sadece localhost'tan)
        ▼
   ┌─────────┐      systemd unit: boot'ta gelir, çökerse restart
   │  <APP>  │  ── uygulama (Flask/Node — basit bir servis)
   └────┬────┘
        │  127.0.0.1:5432
        ▼
   ┌──────────────┐
   │ PostgreSQL   │  ── veritabanı (sadece localhost dinler)
   └──────────────┘
```

---

## 1️⃣ VM'i hazırla

```bash
multipass launch --name lab --cpus 2 --memory 2G --disk 10G
multipass shell lab                    # VM içine gir
sudo apt update && sudo apt -y upgrade # paket listesini tazele
```

VM'in içindesin. Bundan sonraki her şey burada. `hostname` ve `ip a` (A2) ile nerede
olduğunu doğrula.

## 2️⃣ Veritabanı: PostgreSQL

```bash
sudo apt -y install postgresql
sudo systemctl status postgresql       # çalışıyor mu (A1'deki durum kontrolü)
```

Uygulama için ayrı bir kullanıcı ve veritabanı oluştur — `postgres` süper kullanıcısını
uygulamaya verme (least-privilege):

```bash
sudo -u postgres psql <<'SQL'
CREATE USER appuser WITH PASSWORD '<DB_PASSWORD>';
CREATE DATABASE appdb OWNER appuser;
SQL
```

Bağlantıyı **uygulamanın kullanacağı** kullanıcıyla test et:

```bash
psql "postgresql://appuser:<DB_PASSWORD>@127.0.0.1:5432/appdb" -c "SELECT 1;"
# ?column? \n --- \n 1
```

`SELECT 1` dönüyorsa DB ayakta, kullanıcı doğru, port açık. Dönmüyorsa A2'ye dön:
`connection refused` (servis yok/port kapalı) mı, `timed out` (firewall) mu, kimlik
hatası mı? Belirtiyi ayır.

## 3️⃣ Uygulamayı elle çalıştır — ve öl

Basit bir uygulaman olsun (örnek: DB'den bir sayaç okuyup HTTP'de döndüren bir Flask/
Node servisi; deposunu A4'teki Git ile klonla). Önce **elle, ön planda** çalıştır:

```bash
cd /opt/app
DB_URL="postgresql://appuser:<DB_PASSWORD>@127.0.0.1:5432/appdb" ./app
# Uygulama 127.0.0.1:<APP_PORT> dinliyor...
```

Başka bir terminalden iste (A3'teki `curl`):

```bash
curl -s http://127.0.0.1:<APP_PORT>/health   # {"status":"ok"}
```

Şimdi terminali kapat (`Ctrl+C`) ve tekrar iste: **`connection refused`.** Uygulama
öldü. İşte sorun: bir servisin, onu başlatan oturuma bağlı yaşamaması gerekir. Bunu
`systemd` çözer.

> 🔒 Parolayı komut satırında görüyorsun — bu geçici. Kalıcı çözümde parola bir ortam
> dosyasına gider ve dosyanın izinleri kısıtlanır (aşağıda). Sırrı `ps`'te görünür
> bırakma (A5 güvenlik notu).

## 4️⃣ systemd unit: servisi kalıcı yap

Uygulamayı bir servise çevir. Önce uygulamaya **kendi, ayrıcalıksız kullanıcısını** ver:

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin appsvc
```

Ortam (sır) dosyası — izinleri kilitle:

```bash
echo 'DB_URL=postgresql://appuser:<DB_PASSWORD>@127.0.0.1:5432/appdb' \
  | sudo tee /etc/app.env >/dev/null
sudo chown appsvc:appsvc /etc/app.env
sudo chmod 600 /etc/app.env            # yalnız sahibi okur (A1 izin modeli)
```

Unit dosyası — `/etc/systemd/system/app.service`:

```ini
[Unit]
Description=<APP> uygulaması
After=network.target postgresql.service

[Service]
User=appsvc
EnvironmentFile=/etc/app.env
WorkingDirectory=/opt/app
ExecStart=/opt/app/app
Restart=on-failure
# güvenlik sıkılaştırma:
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/app/data

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload           # yeni unit'i oku
sudo systemctl enable --now app        # şimdi başlat + boot'ta gelsin
sudo systemctl status app              # active (running) görmeli
```

Şimdi VM'i yeniden başlat (`sudo reboot`), geri gir, `curl .../health` — **uygulama
kendiliğinden ayakta.** `enable`'ın yaptığı budur; `--now` ise "ayrıca şimdi de başlat".

> 🔒 `User=appsvc`, `NoNewPrivileges`, `ProtectSystem=strict` bir seçim değil, kural.
> Uygulama `root` çalışırsa, ele geçirildiğinde saldırgan tüm VM'i alır; ayrıcalıksız
> bir kullanıcıyla patlama yarıçapı uygulamanın kendi dizinine iner. Bu, D1'de K8s
> `securityContext`/`runAsNonRoot` olarak geri gelecek aynı ilkedir.

## 5️⃣ nginx: reverse proxy

Uygulamayı doğrudan internete açma; önüne nginx koy. nginx 80/443'ü dinler, isteği
`127.0.0.1:<APP_PORT>`'a geçirir:

```bash
sudo apt -y install nginx
```

`/etc/nginx/sites-available/app`:

```nginx
server {
    listen 80;
    server_name <DOMAIN>;

    location / {
        proxy_pass http://127.0.0.1:<APP_PORT>;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled/app
sudo nginx -t                          # config sözdizimini DOĞRULA (deploy etmeden)
sudo systemctl reload nginx            # kesintisiz yeniden yükle
curl -s http://127.0.0.1/health        # artık :80 üzerinden geliyor
```

Uygulama artık yalnız `127.0.0.1`'i dinlemeli (dışa kapalı); tek dış kapı nginx. Bunu
A2'deki `ss -tlnp` ile doğrula: uygulama portu `127.0.0.1`'de, nginx `0.0.0.0:80`'de.

## 6️⃣ Güvenlik duvarı: en az açıklık

```bash
sudo ufw default deny incoming         # varsayılan: her şeyi kapat
sudo ufw allow 22/tcp                  # SSH (kendini kilitleme!)
sudo ufw allow 80/tcp                  # nginx
sudo ufw enable
sudo ufw status
```

DB portu (5432) ve uygulama portu **dışarı kapalı** kalır — onlar yalnız localhost
içinde konuşur. A2'deki "en-az-açıklık güvenlik duvarı" ilkesi burada somutlaşır.

## 7️⃣ Log: sistem sana ne anlatıyor

Bir şey bozulduğunda ilk baktığın yer log'dur (B1'in ön provası):

```bash
sudo journalctl -u app -e             # uygulamanın systemd logu, sona git
sudo journalctl -u app -f             # canlı takip (bir istek at, gör)
sudo tail -f /var/log/nginx/access.log /var/log/nginx/error.log
```

Bir arızayı daralt: `curl` 502 dönüyorsa → nginx `error.log`'a bak → "connection
refused to 127.0.0.1:<APP_PORT>" görürsün → demek uygulama ölü → `systemctl status app`
→ `journalctl -u app` → kök sebep (örn. DB parolası yanlış). Bu zincir, B ve E
bloğunun tüm teşhis işinin çekirdeğidir.

## 8️⃣ (Opsiyonel) TLS

A3'te sertifikanın ne olduğunu öğrendin. Yerel VM'de kendinden imzalı bir sertifika
ile pratik yapabilirsin; internete açık gerçek bir alan adın varsa `certbot` ile
ücretsiz Let's Encrypt sertifikası al. TLS'in derinliği C ve D bloklarında; burada
amaç `443` dinleyen, sertifikayı sunan bir nginx görmek.

---

## 🚫 Anti-pattern tablosu
| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Uygulamayı `nohup ./app &` ile arka plana atmak | Boot'ta gelmez, çökünce kalkmaz, log dağınık | `systemd` unit + `enable` + `Restart=on-failure` |
| Servisi `root` çalıştırmak | Ele geçirilince tüm VM gider | `User=<ayrıcalıksız>` + systemd sıkılaştırma |
| Uygulamayı doğrudan `0.0.0.0:80`'e açmak | TLS/rate-limit/log tek yerde değil, açık yüzey | nginx reverse proxy; uygulama yalnız `127.0.0.1` |
| Parolayı unit'e/koda gömmek | git'e ve `systemctl cat`'e sızar | `EnvironmentFile` + `chmod 600` |
| DB'yi `postgres` süper kullanıcısıyla bağlamak | Uygulama açığı tüm DB'yi verir | Ayrı `appuser`, yalnız kendi DB'sine yetki |
| Firewall'ı hiç kurmamak / her portu açmak | DB/iç portlar internete bakar | `deny incoming` + sadece 22/80/443 |
| `nginx -t` çalıştırmadan `reload` | Bozuk config servisi düşürür | Önce `nginx -t`, sonra `reload` |
| Kurulumu belgelememek | İkinci kurulum sıfırdan acı | Her adımı `KURULUM.md`'ye yaz, Git'le versiyonla |

## 📖 Kıvam referansı
| Kaynak | Ne için | Süre |
|---|---|---|
| [`21-Field-Notes/ansible/system-preparation.md`](../../21-Field-Notes/ansible/system-preparation.md) | Gerçek bir sistem hazırlama notunun nasıl göründüğü | ~20 dk |

## 🔨 Lab
👉 `labs/build/L06-elle-deploy/` — Faz 5'te oluşturulacak. (Görev taslağı: sıfır VM'den
başlayıp DB + uygulama + systemd unit + nginx + firewall'ı elle kur, reboot'tan sağ
çıkar, tüm adımları `KURULUM.md`'ye yaz.)

## 💥 Kırık lab
👉 `labs/broken/K00-systemd-ayaga-kalkmiyor/` — Faz 5'te. Belirti: "systemd servisi
ayağa kalkmıyor." Sebep gizli (port çakışması / yanlış `ExecStart` path / izin / eksik
`EnvironmentFile`). K8s bilgisi gerektirmez; debugging sezgisi tam burada başlar.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] `systemctl is-enabled app` → `enabled` ve `systemctl is-active app` → `active`; VM reboot sonrası uygulama kendiliğinden ayakta.
- [ ] `curl -s http://127.0.0.1/health` nginx üzerinden `200` ve beklenen gövdeyi döndürüyor; `ss -tlnp` ile uygulamanın yalnız `127.0.0.1`, nginx'in `0.0.0.0:80` dinlediğini gösterdin.
- [ ] K00 kırık lab'ını en fazla `hint-1`/`hint-2` ile çözdün; kök sebebi ve teşhis akışını yazdın.
- [ ] "Hangi adımlar en çok zamanı aldı ve container (C1) bunu tam olarak nasıl değiştirir" sorusunu birkaç cümleyle **yazdın**.

## 🧪 Kendini test et
1. `systemctl enable app` ile `systemctl start app` arasındaki fark nedir? Hangisi reboot sonrası ayakta kalmayı sağlar?
2. **Senaryo:** `curl http://127.0.0.1/health` → `502 Bad Gateway`. Servis boot'ta gelmiyor. İlk üç kontrolün ne, hangi sırayla?
3. **Tasarım:** Uygulamayı neden doğrudan `:80`'e açmak yerine nginx'in arkasına koyarsın? En az iki gerekçe yaz.

<details><summary>Cevaplar</summary>

1. `start` uygulamayı **şimdi** başlatır ama kalıcı değildir; reboot sonra gelmez. `enable`, unit'i boot hedefine (`multi-user.target`) bağlar, böylece her açılışta otomatik başlar. Reboot'tan sağ çıkmayı `enable` sağlar; `enable --now` ikisini birden yapar.

2. (a) `sudo systemctl status app` → servis `active` mi, yoksa `failed` mi? (b) `active` değilse `sudo journalctl -u app -e` → uygulama neden çıktı (port çakışması? DB bağlanamadı? path yanlış?). (c) `active` ise sorun proxy'de: `sudo tail /var/log/nginx/error.log` → nginx uygulamaya bağlanabiliyor mu, `ss -tlnp` ile uygulama gerçekten o portu dinliyor mu? 502 = "nginx var ama arkadaki uygulamaya ulaşamıyor".

3. En az iki: (a) **Tek dış kapı** — TLS sonlandırma, rate limiting, erişim logu tek yerde toplanır; uygulama sade kalır. (b) **Güvenlik** — uygulama yalnız `127.0.0.1` dinler, doğrudan internete açık değil; saldırı yüzeyi nginx'e iner. (c) Birden çok uygulamayı tek IP/port üzerinden yola göre yönlendirebilirsin. (d) Uygulamayı yeniden başlatırken/değiştirirken bağlantıları nginx tarafında yönetebilirsin.

</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| `systemctl status app` → `failed` | `ExecStart` path yanlış / dosya çalıştırılamıyor | `journalctl -u app -e`; path ve `chmod +x`'i kontrol et |
| `active` ama `curl` → `connection refused` | Uygulama farklı adres/portu dinliyor | `ss -tlnp` ile gerçek dinlenen adresi gör (A2) |
| `502 Bad Gateway` | nginx uygulamaya ulaşamıyor | `error.log`; uygulama `127.0.0.1:<APP_PORT>` ayakta mı |
| Uygulama başlıyor, hemen ölüyor | DB'ye bağlanamıyor / `EnvironmentFile` eksik | `journalctl -u app`; `psql` ile bağlantıyı ayrıca test et |
| Reboot sonrası servis yok | `enable` edilmemiş | `systemctl enable app`; `is-enabled` ile doğrula |
| SSH'tan atıldın, VM'e giremiyorsun | `ufw` 22'yi kapattı | VM konsolundan (Multipass/Proxmox) gir, `ufw allow 22` |
| `Address already in use` | Port çakışması (K00'ın klasik sebebi) | `ss -tlnp \| grep <PORT>` ile kim tuttuğunu bul |

## 💼 Portfolyo çıktısı
Elle deploy edilmiş, systemd ile yönetilen, nginx arkasında çalışan bir servis +
`KURULUM.md` kurulum notların. Bu, C3'te Terraform'a ve D1'de K8s'e dönüştüreceğin
temeldir — "bir şeyi elden ele üretime aldım" diyebileceğin ilk somut çıktı.

## ⏭️ Sırada
[`B1 — Log Okuma`](../block-b-visibility/B1-log-okuma.md)

---

> *"Kolaylaştırılmış bir A6, bütün patikanın altını oyar. Zahmet burada bilerek bırakılmıştır."*
