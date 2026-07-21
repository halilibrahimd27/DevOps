# K01 — Çözüm

> **Önce kendin dene.** Aşağıda önce **teşhis akışı** var; kök sebep sonra.
> B3'ün amacı: bir arızayı **kanıtla**, tahmin etme.

## Teşhis akışı (üç komutla daralt)

1. **Başlamadı mı, öldü mü?**
   ```bash
   systemctl status k01-app --no-pager
   ```
   `activating`/`failed` döngüsü → başlıyor ama hemen ölüyor. Sorun app'in
   *çalışma zamanında*.

2. **Neden öldü?**
   ```bash
   journalctl -u k01-app -p err -e
   ```
   `OSError: [Errno 98] Address already in use` → port alınamıyor.

3. **Portu kim tutuyor?**
   ```bash
   ss -tlnp | grep ':8080'      # veya: sudo lsof -i :8080
   ```
   8080'i `python -m http.server` (yani `k01-decoy`) tutuyor — senin uygulaman değil.

Bu üç komut belirtiyi (yanıt yok) kök sebebe (port çakışması) **kanıtla** bağladı.

## Kök sebep

`k01-decoy` servisi 8080'i önce kapıyor. `k01-app` aynı porta bağlanamayınca
`Restart=on-failure` yüzünden sürekli deneyip başarısız oluyor. `curl :8080/health`
ya decoy'dan `404` alıyor ya da hiç `ok` görmüyor.

## Düzeltme

```bash
sudo systemctl disable --now k01-decoy   # gereksiz servisi kaldır
sudo systemctl restart k01-app
```

## Belirtinin gittiğini kanıtla (sadece "düzelttim" deme)

```bash
systemctl is-active k01-app             # active
ss -tlnp | grep ':8080'                 # k01-app dinliyor
curl -s http://127.0.0.1:8080/health    # ok
```

## Niye böyle oluyor

Bir port aynı adres+port çiftinde tek bir dinleyiciyi kabul eder. İki servis aynı
portu isterse ikincisi `EADDRINUSE` alır. Gerçek hayatta bu; eski bir process'in
ölmemesi, iki farklı uygulamanın çakışması ya da yanlış yapılandırma yüzünden olur.

## Ders

"Yanıt vermiyor" belirtisi, servisin ayakta *sanılıp* aslında bağlanamadığı bir
durumu gizleyebilir. `status → journalctl → ss` üçlüsü, "ne bozuk" sorusunu
dakikada daraltır. Önce kanıt, sonra düzeltme.
