---
description: "Ağ I: TCP/IP, port ve routing — iki makinenin nasıl konuştuğunu paket seviyesinde görmek."
level: A
module: A2
estimated_hours: 14
prerequisites: [A1]
tags: [Learning Path, Networking]
---
# A2 — Ağ I: TCP/IP, Port, Routing

> *"'Bağlanamıyorum' cümlesinin altında her zaman bir katman, bir port ya da bir rota vardır."*

**Blok:** A — Sezgi · **Süre:** ~14 saat · **Ön koşul:** [`A1`](A1-linux-temeli.md)

## 🎯 Bu modülü bitirdiğinde
- Bir bağlantının hangi katmanda koptuğunu (IP mı, port mu, routing mi) daraltabilirsin.
- Bir makinede hangi portun kim tarafından dinlendiğini bulup açıklayabilirsin.
- İki makine arasındaki yolu (routing) takip eder, nerede durduğunu gösterirsin.

## 🧠 Niye bu, niye şimdi
A1'de tek makineyi tanıdın; gerçek sistemler makineler arası konuşur. DNS, HTTP ve
TLS'i (A3) anlamak için önce paketin, portun ve rotanın ne olduğunu görmen gerekir.
Üretimdeki arızaların büyük kısmı "A, B'ye ulaşamıyor" biçimindedir — ve bunu çözmek,
kopuşun **hangi katmanda** olduğunu daraltmaktır. Bu modül o daraltma refleksini kurar.

## 📖 Nasıl çalışılır
Gövdeyi oku, her komutu kendi makinende çalıştır. İki makine gerekince: bir VM + host
makinen, ya da iki VM işini görür ([`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md)).
(Container tabanlı kurulumu Blok C'de öğrenince tekrar deneyebilirsin — burada henüz gerek yok.)
Modern araç `iproute2` (`ip`, `ss`); `ifconfig`/`netstat` eski ve bazı sistemlerde yok —
`ip`/`ss` öğren.

## 📚 Kavram haritası
| Terim | Bir cümlede |
|---|---|
| **IP adresi** | Bir ağ arayüzünün adresi (örn. `192.168.1.10`) |
| **CIDR / subnet** | Bir adres bloğu ve maskesi (`192.168.1.0/24` = 256 adres) |
| **Port** | Bir makinedeki belirli bir servisi işaret eden 0–65535 arası sayı |
| **Soket** | `<IP>:<port>` çifti — bir bağlantının bir ucu |
| **TCP** | Güvenilir, sıralı, bağlantılı taşıma (el sıkışma yapar) |
| **UDP** | Bağlantısız, "gönder ve unut" taşıma (DNS, bazı metrikler) |
| **Gateway** | Kendi ağın dışına çıkışta paketi teslim ettiğin yönlendirici |
| **Routing table** | "Şu hedef için paketi şu arayüzden/gateway'den gönder" kuralları |

---

## 1️⃣ Katman modeli — yeterince

Ağı dört pratik katmanda düşün. Bir arıza her zaman **bir** katmandadır; işin o katmanı
bulmak:

| Katman | Soru | Araç |
|---|---|---|
| **Link** (fiziksel/arayüz) | Arayüz ayakta mı, IP'si var mı? | `ip addr`, `ip link` |
| **IP** (adres/rota) | Hedefe giden bir yol var mı? | `ping`, `ip route`, `traceroute` |
| **Taşıma** (TCP/UDP + port) | Doğru port açık mı, dinleniyor mu? | `ss`, `nc`, `telnet` |
| **Uygulama** (HTTP/DNS/TLS) | Servis anlamlı cevap veriyor mu? | `curl`, `dig` (A3'te) |

"Bağlanamıyorum" dediğinde bu tabloyu yukarıdan aşağı yürü: **önce arayüz/IP, sonra
rota, sonra port, en son uygulama.** Alttan başlamak, üstteki hatayı boşuna aramaktır.

## 2️⃣ Kendi adresini ve arayüzlerini görmek

```bash
ip addr                 # tüm arayüzler ve IP'leri (kısaca: ip a)
# 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
#    inet 192.168.1.10/24 brd 192.168.1.255 scope global eth0
ip link                 # arayüzlerin UP/DOWN durumu (IP'siz)
```

`192.168.1.10/24` iki bilgi taşır: **adres** (`192.168.1.10`) ve **maske** (`/24`).
`/24`, ilk 24 bit'in ağ kısmı olduğunu söyler → bu ağ `192.168.1.0`–`192.168.1.255`
aralığıdır. Aynı `/24` içindeki iki makine doğrudan konuşur; farklı ağdakiler bir
**gateway** üzerinden.

| CIDR | Adres sayısı | Tipik kullanım |
|---|---|---|
| `/24` | 256 | Küçük bir yerel ağ / subnet |
| `/16` | 65.536 | Büyük bir özel ağ (örn. `10.0.0.0/16`) |
| `/32` | 1 | Tek bir host (kural/route yazarken) |

### Maske ne yapar — bit seviyesinde

`/24`, adresin ilk **24 bit'inin** ağ (network), kalan 8 bit'inin host olduğunu söyler.
`192.168.1.0/24` içinde:

```
192.168.1.  0    → ağ adresi (host bitleri hep 0) — "bu ağın kendisi"
192.168.1.  1    → ilk kullanılabilir host (genelde gateway)
192.168.1.254    → son kullanılabilir host
192.168.1.255    → broadcast (host bitleri hep 1) — "bu ağdaki herkes"
```

Bir makinenin başka bir adrese **doğrudan** mı yoksa gateway üzerinden mi ulaşacağına
maske karar verir: hedef aynı ağ/maske içindeyse doğrudan, değilse gateway'e. "Neden bu
iki makine birbirini görmüyor" sorusunun sık cevabı **yanlış maske**dir — ikisi farklı
ağ sanıp gateway arar.

Özel (private) aralıkları tanı — bunlar internette yönlendirilmez, yereldir:
`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`. C4'te bulut VPC'sini kurarken bu
blokları yeniden göreceksin.

### NAT: özel adres internette nasıl çalışır

Özel adresler internette yönlendirilmezse, `192.168.1.10`'daki makinen bir siteyi nasıl
açıyor? **NAT** (Network Address Translation) sayesinde: gateway (ev/ofis yönlendiricin
ya da bulut NAT geçidi) giden paketin özel kaynak adresini kendi **genel** adresiyle
değiştirir, dönen cevabı da geri çevirir. Böylece binlerce özel adres tek bir genel
adres arkasından çıkar.

Bunun pratik sonucu: bir makineye **dışarıdan** bağlanmak, içeriden dışarı bağlanmaktan
farklıdır. NAT arkasındaki bir servise dışarıdan erişmek için yönlendiricide açık bir
kural (port forward) ya da bir yük dengeleyici gerekir. C4/D bloğunda "servisim çalışıyor
ama internetten erişilemiyor" durumunun kökü çoğu zaman budur.

### ARP ve DHCP — komşunu ve adresini bulmak

Aynı ağdaki iki makine IP ile değil, aslında **donanım (MAC) adresi** ile konuşur. IP'yi
MAC'e çeviren şey **ARP**'tır:

```bash
ip neigh                # ARP tablosu: hangi IP hangi MAC'te (komşularım)
```

Makinen IP'sini nereden aldı? Elle vermediysen **DHCP** ile: ağa katıldığında bir DHCP
sunucusu ona IP, maske, gateway ve DNS sunucusunu kiralar. "Makinede hiç IP yok" ya da
"yanlış ağdan IP almış" arızalarının kaynağı budur — `ip addr` boşsa ya da beklenmedik
bir bloktaysa DHCP'ye bak.

## 3️⃣ Port ve soket: kim dinliyor

Bir makinede birçok servis olabilir; her biri bir **port** dinler. `<IP>:<port>` bir
soketi tanımlar. Web tipik olarak `80` (HTTP) ve `443` (HTTPS), SSH `22`, PostgreSQL
`5432` dinler.

```bash
ss -ltnp                # dinlenen (Listen) TCP portları + hangi process (-p, sudo gerek)
# State   Recv-Q  Local Address:Port   Process
# LISTEN  0       0.0.0.0:80           users:(("nginx",pid=812,fd=6))
sudo ss -ltnp | grep :80    # 80'i kim dinliyor
sudo lsof -i :80            # aynı soru, A1'deki lsof ile
```

`0.0.0.0:80` "tüm arayüzlerde 80'i dinliyorum" demektir; `127.0.0.1:80` ise "yalnız bu
makineden erişilebilirim" (localhost). Bir servise dışarıdan bağlanamıyorsan, sık sebep
budur: servis `127.0.0.1`'e bağlanmış, `0.0.0.0`'a değil.

### Bir portu elle yoklamak

```bash
nc -vz <HEDEF_IP> 5432      # 5432 açık mı? (netcat ile bağlantı denemesi)
# Connection to <HEDEF_IP> 5432 port [tcp/*] succeeded!   ← açık
curl -v telnet://<HEDEF_IP>:5432    # nc yoksa
```

### TCP'nin üç el sıkışması ve bağlantı durumları

TCP bağlantısı kurulurken üç adım olur: `SYN → SYN-ACK → ACK`. Bir bağlantının
durumunu görmek, "takıldı mı, kuruldu mu, kapanıyor mu" sorusunu yanıtlar:

```bash
ss -tan                     # tüm TCP bağlantıları + durumları
# ESTAB   kurulu bağlantı        TIME-WAIT  kapanmış, temizleniyor
# SYN-SENT el sıkışma yarım kaldı (karşı taraf cevap vermiyor!)
```

Çok sayıda `SYN-SENT` görüyorsan: karşı taraf ya kapalı ya güvenlik duvarı sessizce
düşürüyor. Bu ipucu 5️⃣'te işine yarayacak.

## 4️⃣ Routing: paketin yolu

Kendi ağının dışına çıkan her paket **routing table**'a bakılarak yönlendirilir:

```bash
ip route                    # yönlendirme tablosu (kısaca: ip r)
# default via 192.168.1.1 dev eth0        ← "başka her yer" için gateway
# 192.168.1.0/24 dev eth0 proto kernel    ← yerel ağ, doğrudan
```

`default via ...` satırı **varsayılan geçit**tir: hedef başka bir kurala uymuyorsa paket
oraya gider. Yerel ağ dışına hiç çıkamıyorsan (`ping 1.1.1.1` çalışmıyorsa) ilk bakılan
yer budur — bir default route var mı?

```bash
ping -c 3 1.1.1.1           # IP seviyesinde ulaşabiliyor muyum? (1.1.1.1 = Cloudflare DNS)
traceroute 1.1.1.1          # paket hangi durakları geçiyor, nerede duruyor
mtr 1.1.1.1                 # traceroute + ping'in canlı birleşimi (kurulu ise)
```

> `ping 1.1.1.1` çalışıp `ping google.com` çalışmıyorsa: IP'ye ulaşıyorsun ama **isim
> çözümlenmiyor** — sorun ağda değil, DNS'te (A3'ün konusu). Bu tek gözlem, arıza
> aramanı yarı yarıya kısaltır.

## 5️⃣ İki farklı "bağlanamıyorum": reddedildi vs zaman aşımı

Teşhiste en değerli ayrım budur; ikisi bambaşka sebep gösterir:

| Belirti | Ne demek | Muhtemel sebep |
|---|---|---|
| **Connection refused** | Paket ulaştı, ama **kimse o portu dinlemiyor** | Servis çalışmıyor / yanlış port / `127.0.0.1`'e bağlı |
| **Connection timed out** | Cevap **hiç gelmedi** | Güvenlik duvarı sessizce düşürüyor / rota yok / makine kapalı |

```bash
nc -vz <HEDEF_IP> 8080
# ... Connection refused        → hedef makineye VARDIN; servis yok
# ... Connection timed out      → hedefe VARAMADIN; ağ/güvenlik duvarı
```

"Refused" iyi haberdir: ağ çalışıyor, sorun servistedir (A1'e dön: process ayakta mı,
doğru portu mu dinliyor?). "Timeout" ağ/güvenlik duvarı sorununu işaret eder. Bu ayrımı
otomatik yapabilmek, bu modülün sana kazandırdığı asıl reflekstir.

Güvenlik duvarını yoklamak (yereldeyse):

```bash
sudo iptables -L -n -v      # klasik güvenlik duvarı kuralları
sudo nft list ruleset       # modern (nftables) karşılığı
sudo ufw status             # Ubuntu'nun sade ön yüzü (kuruluysa)
```

## 6️⃣ TCP mi UDP mi — ve uçtan uca bir örnek

Çoğu servis (HTTP, SSH, DB) **TCP** kullanır: bağlantı kurulur, paketler sıralı ve
güvenilir gelir, kayıp olursa tekrarlanır. **UDP** ise bağlantısız ve "gönder-unut"tur:
hız için güvenilirliği bırakır. DNS (A3) küçük soruları hızlıca sormak için çoğunlukla
UDP kullanır; canlı video/oyun da UDP eğilimlidir.

Pratik ayrım teşhiste işine yarar: bir TCP portunu `nc -vz` ile net yoklayabilirsin
(el sıkışma başarılı/başarısız). UDP'de "başarılı" sinyali yoktur — cevap gelmezse
"port kapalı mı, paket mi düştü" ayrımı belirsizdir. Bu yüzden UDP servisleri
(örn. DNS) uygulama seviyesinde test edilir (`dig`, A3).

**Uçtan uca bir örnek** — `curl http://<HEDEF_IP>:8080` çalıştırdığında sırayla:

```bash
ip addr                       # 1. Benim bir IP'm var mı, arayüz UP mı?
ip route get <HEDEF_IP>       # 2. Bu hedefe hangi yoldan giderim (doğrudan mı, gateway mi)?
ping -c1 <HEDEF_IP>           # 3. IP seviyesinde ulaşıyor muyum?
nc -vz <HEDEF_IP> 8080        # 4. 8080 portu açık/dinleniyor mu (refused vs timeout)?
curl -v http://<HEDEF_IP>:8080  # 5. Uygulama anlamlı cevap veriyor mu?
```

Her adım bir öncekini varsayar. 3 çalışmıyorsa 4-5'i denemek boşuna; 4 "refused" veriyorsa
sorun serviste (A1), "timeout" veriyorsa ağ/güvenlik duvarındadır. Bu beş komut, "neden
bağlanamıyorum"u tahmin değil **kanıt** hâline getirir — B3'teki ilk kırık lab'ın çekirdeği.

---

## 🚫 Anti-pattern tablosu
| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Servisi `0.0.0.0`'a bağlayıp güvenli sanmak | Tüm arayüzlerden erişilebilir; istemeden dışarı açılır | Gerekmiyorsa `127.0.0.1`; dışa açılış bilinçli olsun |
| "Timeout" ve "refused"u aynı kefeye koymak | İki bambaşka sebebi karıştırır, yanlış yerde arattırır | Önce hangisi olduğunu belirle, sonra dallan |
| Ağ arıza aramasına uygulamadan başlamak | Alttaki IP/port hatasını üstte boşuna ararsın | Aşağıdan yukarı: arayüz → rota → port → uygulama |
| `ping` çalışıyor diye "ağ tamam" demek | `ping` ICMP'dir; TCP portu yine kapalı olabilir | Portu `nc`/`ss` ile ayrıca doğrula |
| `netstat`/`ifconfig`'e yapışmak | Deprecated; bazı sistemlerde yok | `ss` ve `ip` kullan |
| Güvenlik için portu "gizlemek" (obscurity) | Port taraması saniyeler sürer; gizlemek koruma değil | Erişimi kuralla kapat (güvenlik duvarı), gizleme değil |
| Her yeri açan geniş güvenlik duvarı kuralı | Saldırı yüzeyini büyütür | En az açıklık: yalnız gereken port/kaynak |

## 📖 İleri okuma (şimdi değil, sonra)
| Kaynak | Ne için | Ne zaman |
|---|---|---|
| `man ss`, `man ip` | `ss`/`ip` alt komutlarının tam referansı | Bir bayrağı merak ettiğinde |
| [`09-Networking/`](../../09-Networking/) klasörü | Kubernetes-içi ağ (service mesh, eBPF, Gateway API) | **D bloğundan sonra** — hepsi cluster-içi, şimdi çok ileri |

> Not: `09-Networking/` içeriğinin tamamı K8s ağıdır ve bu modülün seviyesinin çok
> ötesindedir. Şimdi açma; D1'den sonra anlamlı olacak.

## 🔨 Lab
👉 [`labs/build/L02-ag-tcp-ip/`](../labs/build/L02-ag-tcp-ip/) — (Görev taslağı: bir servisi
farklı portlarda/arayüzlerde bağla, `ss`/`nc` ile dinleneni doğrula; "refused" ve
"timeout" durumlarını bilerek üret ve ayırt et.)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] `ss -ltnp` (veya `lsof -i`) ile dinlenen bir portu bulup onu dinleyen process'e eşleştirdin — komut + çıktı.
- [ ] Bir bağlantıyı katman katman daralttın: `ip addr` → `ip route` → `ping` → `nc/ss` sırasını bir arıza üzerinde uyguladın ve **hangi katmanda koptuğunu** gösterdin.
- [ ] "Connection refused" ile "connection timed out" arasındaki farkı, her birinin işaret ettiği sebeple birlikte **yazdın**.
- [ ] `127.0.0.1` ve `0.0.0.0` arasındaki farkı, bir servisi "dışarıdan erişilemez" yapan durumu örnekleyerek **yazdın**.

## 🧪 Kendini test et
1. `ss -ltn` çıktısında bir satır `127.0.0.1:5432`, başka biri `0.0.0.0:80` diyor. Bu iki servise başka bir makineden bağlanmayı denersen ne olur, niçin?
2. **Senaryo:** Bir uygulama veritabanına bağlanamıyor. `nc -vz <DB_IP> 5432` "timed out" veriyor. İlk üç kontrolün ne olur?
3. **Tasarım:** Bir DB yalnız uygulama sunucusundan erişilebilir olmalı, internetten asla. Ağ seviyesinde bunu nasıl kurarsın (adresleme + dinleme + güvenlik duvarı)?

<details><summary>Cevaplar</summary>

1. `0.0.0.0:80` başka makineden **erişilebilir** (tüm arayüzlerde dinliyor). `127.0.0.1:5432` yalnız kendi makinesinden erişilebilir; dışarıdan denersen **connection refused** (o arayüzde kimse dinlemiyor). Bir servise "dışarıdan bağlanamıyorum"un en sık sebebi budur.

2. "Timed out" → hedefe **varamıyorsun** (ağ/güvenlik duvarı), servis sorunu değil. (a) Rota var mı: `ping <DB_IP>` / `ip route`. (b) Araya güvenlik duvarı mı giriyor: `traceroute <DB_IP>` nerede duruyor. (c) DB makinesinde port gerçekten dinleniyor mu (oraya erişimin varsa): `sudo ss -ltnp | grep 5432`. "Refused" olsaydı ağ tamam, servise bakardın; "timeout" olduğu için ağ/güvenlik duvarına bakıyorsun.

3. DB'yi yalnız iç ağdaki (private) bir IP'ye bağla, `0.0.0.0`'a değil — ideali özel bir subnet'te. Dinlemeyi uygulama sunucusunun erişebileceği arayüzle sınırla. Güvenlik duvarında `5432`'yi **yalnız** uygulama sunucusunun IP'sine (`/32`) aç, geri kalan her kaynağı reddet. Böylece port taransa bile yalnız o tek kaynaktan ulaşılır — en az açıklık.

</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| `Connection refused` | Servis çalışmıyor / yanlış port / `127.0.0.1`'e bağlı | A1'e dön: process ayakta mı, `ss -ltnp` ile hangi adres/portu tutuyor |
| `Connection timed out` | Güvenlik duvarı düşürüyor / rota yok / makine kapalı | `ping`, `traceroute`, güvenlik duvarı kuralları |
| `ping IP` çalışıyor, `ping isim` çalışmıyor | DNS sorunu, ağ değil | A3'ün konusu; şimdilik IP ile devam et |
| `ss: command not found` | Minimal sistem | `sudo apt install iproute2` (Debian/Ubuntu) |
| `Network is unreachable` | Default route yok | `ip route` — `default via ...` satırı var mı |
| Portu değiştirdim, hâlâ eski davranış | Servis reload edilmedi | Servisi yeniden başlat / `kill -HUP` (A1) |

## 💼 Portfolyo çıktısı
Doğrudan çıktı yok; A6'daki elle deploy'da (servis + port + güvenlik duvarı) ve B3
kırık lab'ında ağ kavramları somut çıktıya dönüşür.

## ⏭️ Sırada
[`A3 — Ağ II: DNS → HTTP → TLS/Sertifika`](A3-ag-dns-http-tls.md)

---

> *"Ağ sihir değildir; her adımı görülebilir, her kopuş bir yerde durur."*
