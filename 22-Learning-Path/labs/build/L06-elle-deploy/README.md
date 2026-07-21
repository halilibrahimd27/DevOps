# L06 — Bir uygulamayı **elle** ayağa kaldır (container YOK)

> Modül: [`A6`](../../../block-a-intuition/A6-elle-deploy.md) · Süre: ~4–6 saat · Kırık lab: [`K00`](../../broken/K00-systemd-ayaga-kalkmiyor/)

Bu lab **kasıtlı olarak zahmetlidir.** Sıfır bir VM'den başlayıp bir uygulamayı,
veritabanını, systemd unit'ini, nginx ters vekilini ve firewall'ı **elle** kurarsın.
Container yok. Amaç: sonraki her soyutlamanın (Docker, K8s) **neyi çözdüğünü** kendi
elinle acısını çekerek bilmek. Kolaylaştırma; her adımı `KURULUM.md`'ye yaz.

## Gerekenler
- Temiz bir Linux VM (Ubuntu/Debian önerilir). **Kök/sudo erişimi.** Proxmox, Multipass,
  Vagrant, bir bulut VM veya yerel VM — hepsi olur.
- `python3` (uygulama stdlib ile çalışır), `postgresql`, `nginx`, `systemd`, bir firewall (`ufw`).

## Görev

1. **Uygulamayı yerleştir.** `starter/app.py`'yi VM'e kopyala (örn. `/opt/lab-app/app.py`).
   Uygulama stdlib HTTP servisidir: `/health` → `200 ok`, `/db` → `pg_isready` sonucu.
   Yalnız `127.0.0.1:8000` dinlemeli (dışarıya nginx bakacak).
2. **Veritabanı.** PostgreSQL kur, bir veritabanı ve bir **sınırlı yetkili** kullanıcı
   yarat. Parolayı **asla** koda gömme — systemd `EnvironmentFile`'dan ver.
3. **systemd unit.** `/etc/systemd/system/lab-app.service` yaz: uygulamayı servis
   kullanıcısıyla çalıştır, `EnvironmentFile` ile ortam ver, `Restart=on-failure`,
   `enable` et. `systemctl status` ile ayakta olduğunu gör.
4. **nginx ters vekil.** nginx'i `80` portunda dinlet, `127.0.0.1:8000`'e proxy'le.
   `curl http://127.0.0.1/health` → `200`.
5. **Firewall.** Yalnız `22` (SSH) ve `80` (HTTP) açık olsun; uygulamanın `8000`'i
   dışarıya **kapalı** kalsın.
6. **Reboot testi.** VM'i yeniden başlat. Uygulama **elle müdahale olmadan** geri gelmeli.
7. **Belgele.** Her komutu ve dosyayı `KURULUM.md`'ye yaz — birinin sıfırdan tekrar
   edebileceği kadar net. (`starter/KURULUM.template.md` iskelettir.)

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor (VM'in üstünde çalıştır).
- [ ] `systemctl is-enabled lab-app` → `enabled`, `is-active` → `active`.
- [ ] `curl -s http://127.0.0.1/health` → `ok` (nginx üzerinden, port 80).
- [ ] `ss -tlnp`: nginx `0.0.0.0:80`, uygulama yalnız `127.0.0.1:8000`.
- [ ] `KURULUM.md` sıfırdan tekrar edilebilir adımları içeriyor.
- [ ] Reboot sonrası servis kendiliğinden ayakta.

## İpucu (çözüm değil)
- systemd sıralaması: `After=network.target postgresql.service`.
- Parola: `EnvironmentFile=/etc/lab-app/app.env` (mod `600`, servis kullanıcısına ait).
- nginx: `proxy_pass http://127.0.0.1:8000;` + `proxy_set_header Host $host;`.
- "Reboot'tan sağ çıktı mı" testi `enable` etmeyi unutup unutmadığını gösterir —
  `is-active` yetmez, `is-enabled` şart.

Bu lab bozulacak; bozulunca [`K00`](../../broken/K00-systemd-ayaga-kalkmiyor/) seni bekliyor.
Takılırsan `solution/`'a bak — ama **önce kendin uğraş**.
