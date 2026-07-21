# L02 — Referans çözüm

> **Önce kendin dene.** Ağ hatalarını ayırt etmek okuyarak değil, üreterek öğrenilir.

## 1. Localhost'a bağla ve doğrula

```bash
bash starter/serve-localhost.sh &        # 127.0.0.1:8080
ss -tlnp | grep ':8080'
# 127.0.0.1:8080 karşısında LISTEN görürsün. 0.0.0.0:8080 GÖRMEZSİN —
# yani bu servise dışarıdan (başka makineden) erişilemez.
```

Farkı görmek için `--bind 0.0.0.0` ile yeniden başlatıp `ss` çıktısını
karşılaştır: `0.0.0.0:8080` = tüm arayüzlerden erişilebilir.

## 2. Refused üret (anında)

```bash
nc -z -w3 127.0.0.1 9999 ; echo "çıkış kodu: $?"
# Anında döner. Kernel "o portta dinleyen yok" der → TCP RST.
```

`curl http://127.0.0.1:9999` → `Connection refused`. **Anahtar:** hızlı cevap =
makineye ulaştın, port kapalı. Servis çökmüş veya yanlış portu deniyorsun.

## 3. Timeout üret (asılı kalır)

```bash
nc -z -w3 10.255.255.1 80 ; echo "çıkış kodu: $?"
# ~3 sn bekler, sonra timeout. Paket hedefe varamıyor / cevap dönmüyor.
```

**Anahtar:** yavaş/bekleyen cevap = paket kayboluyor. Route yok, yanlış subnet,
ya da firewall paketi `DROP` ediyor (reddetmek yerine sessizce yutuyor).

## 4. Fark — teşhis refleksi

| Belirti | Ne demek | İlk bakılacak |
|---|---|---|
| **Connection refused** (anında) | Makineye ulaştın, port kapalı | Servis ayakta mı? Doğru port mu? (`ss -tlnp`) |
| **Timeout** (asılı kalır) | Paket hedefe varamıyor | Route, subnet, security group / firewall (`ip route`, `ping`) |

> Reddedilmek iyi haberdir: en azından oraya vardın. Timeout, yolun ortasında
> kaybolduğun anlamına gelir.
