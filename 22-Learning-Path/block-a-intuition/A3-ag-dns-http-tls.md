---
description: "Ağ II: DNS → HTTP → TLS/sertifika — bir isim nasıl bir güvenli bağlantıya dönüşür, bu sırayla."
level: A
module: A3
estimated_hours: 16
prerequisites: [A2]
tags: [Learning Path, Networking]
---
# A3 — Ağ II: DNS → HTTP → TLS/Sertifika

> *"Bir adresi tarayıcıya yazdığın andan şifreli bağlantıya kadar geçen yolu bilen, yarısı DNS olan üretim arızalarının yarısını çözer."*

**Blok:** A — Sezgi · **Süre:** ~16 saat · **Ön koşul:** [`A2`](A2-ag-tcp-ip.md)

## 🎯 Bu modülü bitirdiğinde
- Bir isim çözümlemesini (DNS) adım adım izler, nerede yanlış cevap geldiğini gösterirsin.
- Bir HTTP isteğinin/yanıtının anatomisini (metod, durum kodu, başlık) okuyabilirsin.
- Bir TLS sertifikasının kimin için, kim tarafından, ne zamana kadar geçerli olduğunu doğrularsın.

## 🧠 Niye bu, niye şimdi
Bu sıra kasıtlıdır: TLS'i anlamak için HTTP'yi, HTTP'yi anlamak için DNS'i bilmen
gerekir. A6'da kuracağın gerçek servis bir isimle çağrılacak ve bir sertifika
sunacak — o zinciri buradan tanırsın. Üretimdeki "site açılmıyor / sertifika hatası"
vakalarının çoğu bu üç halkadan birinde kopar; hangisinde olduğunu görmek beceridir.
Atlamadan, bu sırayla.

## 📖 Nasıl çalışılır
Gövdeyi oku, her komutu çalıştır. Araçlar: `dig` (DNS), `curl` (HTTP), `openssl`
(TLS) — hemen her Linux'ta var ya da tek paketle gelir. Kendi servisini A6'da
kuracaksın; şimdilik yoklamaları var olan bir isim üzerinde yap (örn. `example.com` —
IETF'in test/örnek için ayırdığı alan adı, gerçek bir kuruma ait değil).

## 📚 Kavram haritası
| Terim | Bir cümlede |
|---|---|
| **DNS** | İsmi (`example.com`) IP'ye çeviren dağıtık defter |
| **Resolver** | Senin adına DNS sorusunu soran sunucu (`/etc/resolv.conf`) |
| **A / AAAA / CNAME** | İsim→IPv4 / İsim→IPv6 / İsim→başka isim kayıtları |
| **TTL** | Bir DNS cevabının kaç saniye önbellekte tutulacağı |
| **HTTP metod** | İsteğin niyeti: `GET` (oku), `POST` (gönder), `PUT`, `DELETE` |
| **Durum kodu** | Yanıtın sonucu: `2xx` tamam, `3xx` yönlendir, `4xx` sen, `5xx` sunucu |
| **TLS** | Bağlantıyı şifreleyen ve karşı tarafın kimliğini doğrulayan katman |
| **Sertifika** | Bir ismin, bir CA (otorite) tarafından imzalanmış kimlik belgesi |

---

## 1️⃣ DNS: isim nasıl IP olur

Makineler IP ile konuşur (A2), insanlar isimle. DNS bu ikisi arasındaki çeviridir.
Bir isim çözümlendiğinde, resolver bir zinciri yürür: kök → TLD (`.com`) → alan adının
yetkili sunucusu. Sen çoğu zaman bu zincirin sonucunu **önbellekten** alırsın.

```bash
dig example.com                 # tam DNS sorgusu ve cevabı
# ;; ANSWER SECTION:
# example.com.   3600  IN  A   192.0.2.10        ← isim → IP, TTL=3600 sn (192.0.2.0/24: RFC 5737 örnek blok)
dig +short example.com          # yalnız cevabı
dig AAAA example.com            # IPv6 kaydı
dig example.com @1.1.1.1        # belirli bir resolver'a sor (Cloudflare)
```

Senin makinen soruyu kime soruyor? Buna `/etc/resolv.conf` (ya da systemd-resolved)
karar verir:

```bash
cat /etc/resolv.conf            # nameserver <IP> satırları — kime soruyorum
resolvectl status               # systemd-resolved kullanan sistemlerde
```

### Kayıt türleri (bilmen gerekenler)

| Kayıt | Ne yapar | Örnek |
|---|---|---|
| `A` | İsim → IPv4 | `example.com → 192.0.2.10` |
| `AAAA` | İsim → IPv6 | `example.com → 2001:db8::10` |
| `CNAME` | İsim → başka isim (takma ad) | `www.example.com → example.com` |
| `MX` | Alan adının posta sunucusu | (e-posta yönlendirmesi) |
| `TXT` | Serbest metin (doğrulama, SPF) | (alan sahipliği kanıtı) |

### Çözümleme zinciri: kök → TLD → yetkili

Bir ismin ilk kez çözülmesi bir zincir yürür. `dig +trace example.com` bunu adım adım
gösterir:

1. **Kök sunucular** (`.`) — "`.com`'a kim bakıyor?" sorusunu yanıtlar (TLD sunucularını verir).
2. **TLD sunucusu** (`.com`) — "`example.com`'un yetkili sunucusu kim?" sorusunu yanıtlar.
3. **Yetkili (authoritative) sunucu** — asıl kaydı (`A`, `AAAA`…) veren yer.

Senin resolver'ın (`/etc/resolv.conf`'taki sunucu) bu zinciri senin yerine yürüten
**recursive** çözücüdür; sen sonucu genelde önbellekten alırsın. Bir kaydı değiştirdiğinde
"neden hâlâ eski cevap geliyor" sorusunun cevabı bu katmanlardan birindeki **önbellek** +
**TTL**'dir. `dig example.com @<yetkili_ns>` ile doğrudan yetkiliye sorarak, sorunun
gerçek kayıtta mı yoksa yol üstündeki bir önbellekte mi olduğunu ayırırsın.

### DNS neden bu kadar sık arıza sebebidir

```bash
dig +short example.com          # boş dönüyorsa: kayıt yok / yanlış resolver
getent hosts example.com        # sistemin gerçekte nasıl çözdüğü (/etc/hosts dahil)
```

İki tuzak: **(1) TTL/önbellek** — kaydı değiştirdin ama eski cevap hâlâ önbellekte;
TTL dolana kadar yayılmaz. **(2) `/etc/hosts` gölgelemesi** — bu dosyadaki bir satır
DNS'ten önce gelir; birinin unuttuğu bir `/etc/hosts` girdisi "neden yanlış IP'ye
gidiyor" gizeminin klasik cevabıdır.

> A2'deki "`ping IP` çalışıyor, `ping isim` çalışmıyor" gözlemini hatırla: o an sorun
> tam olarak buradaydı — DNS. Şimdi onu `dig` ile kanıtlayabilirsin.

## 2️⃣ HTTP: isteğin ve yanıtın anatomisi

İsim IP'ye döndü, TCP bağlantısı kuruldu (A2). Şimdi konuşulan dil HTTP. Bir HTTP
alışverişi bir **istek** ve bir **yanıt**tan oluşur; her ikisinin de başlıkları ve
(çoğu zaman) bir gövdesi vardır.

```bash
curl -v http://example.com      # -v: istek + yanıt başlıklarını ham gösterir
# > GET / HTTP/1.1               ← istek satırı: metod + yol + sürüm
# > Host: example.com            ← istek başlığı
# < HTTP/1.1 200 OK              ← yanıt satırı: sürüm + durum kodu
# < Content-Type: text/html      ← yanıt başlığı
curl -I https://example.com     # -I: yalnız yanıt başlıkları (HEAD isteği)
curl -s -o /dev/null -w "%{http_code}\n" https://example.com   # yalnız durum kodu
```

### Metodlar ve idempotency

Metod, isteğin **niyetini** söyler. En çok göreceklerin:

| Metod | Niyet | Idempotent mi? |
|---|---|---|
| `GET` | Oku, yan etkisiz | Evet (tekrarı aynı sonuç) |
| `POST` | Yeni kaynak/işlem oluştur | **Hayır** (tekrar = ikinci kayıt) |
| `PUT` | Kaynağı tümüyle değiştir | Evet |
| `DELETE` | Kaynağı sil | Evet (silinmiş yine silinmiş) |

**Idempotency** — "aynı isteği iki kez göndermek zarar verir mi?" — pratik bir sorudur:
bir istek zaman aşımına uğrayıp tekrar denendiğinde `GET`/`PUT`/`DELETE` güvenlidir,
`POST` ise çift kayıt üretebilir. Retry/otomasyon tasarlarken (C2, E bloğu) bu ayrım
önemlidir.

### Oturum: cookie nasıl taşınır

HTTP **durumsuzdur** (her istek bağımsız). "Giriş yaptım, hatırlanıyorum" hissi
**cookie** ile olur: sunucu `Set-Cookie` ile bir oturum kimliği verir, tarayıcı sonraki
her istekte `Cookie` başlığıyla geri gönderir. Bir "neden sürekli çıkış yapıyorum" ya da
"oturum başka kullanıcıya karışıyor" arızasında ilk bakılan yer bu iki başlıktır.

### Durum kodları — sınıfını oku, ezberleme

| Sınıf | Anlam | Sık örnek |
|---|---|---|
| `2xx` | Başarılı | `200 OK`, `201 Created` |
| `3xx` | Yönlendirme | `301` kalıcı, `302` geçici taşındı |
| `4xx` | **İstemci** hatası (sen) | `400` bozuk istek, `401` kimliksiz, `403` yasak, `404` yok |
| `5xx` | **Sunucu** hatası | `500` içeride patladı, `502/503` arka uç yok/meşgul |

Ayrımı içselleştir: **`4xx` senin isteğinde bir sorun** (yanlış yol, eksik kimlik),
**`5xx` sunucuda bir sorun** (uygulama patladı, arka uç ayakta değil). Bir `502 Bad
Gateway`, nginx'in arkasındaki uygulamaya ulaşamadığını söyler — A6'da bu ikisini
kendin bağlayınca bu kod anlam kazanacak.

### Başlıklar hikâyeyi anlatır

`Host` başlığı hangi siteyi istediğini söyler (tek IP çok site barındırabilir).
`Content-Type` gövdenin türünü, `Location` bir `3xx`'in nereye yönlendirdiğini,
`Set-Cookie` oturum bilgisini taşır. Bir arızada başlıkları okumak, tahmin etmekten
her zaman iyidir.

## 3️⃣ TLS: şifreleme + kimlik

HTTP düz metindir; aradaki herkes okuyabilir. HTTPS = HTTP + **TLS**. TLS iki iş yapar:
**(1) şifreleme** (kimse dinleyemesin) ve **(2) kimlik doğrulama** (karşındaki gerçekten
`example.com` mu?). İkincisi **sertifika** ile olur.

Bir sertifika şunu söyler: *"Bu ismin (`example.com`) sahibi olduğunu, güvenilen bir
otorite (CA) doğruladı; şu tarihe kadar geçerli."* Tarayıcın/işletim sistemin, güvendiği
CA'ların listesini taşır; sertifika o zincire kadar imzalıysa yeşil kilit.

```bash
# Sertifikanın kime ait, kim imzaladı, ne zamana kadar geçerli
echo | openssl s_client -connect example.com:443 -servername example.com 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates
# subject=CN=example.com          ← kimin için
# issuer=C=US, O=DigiCert Inc...   ← kim imzaladı (CA)
# notBefore=... notAfter=...       ← geçerlilik penceresi

curl -v https://example.com 2>&1 | grep -E "subject:|issuer:|expire"
```

### El sıkışma nasıl olur — kabaca

TCP bağlantısı kurulduktan sonra (A2) TLS el sıkışması başlar:

1. **ClientHello** — istemci desteklediği TLS sürümünü ve şifre setlerini önerir.
2. **ServerHello + sertifika** — sunucu seçimini bildirir ve **sertifikasını** sunar.
3. **Doğrulama** — istemci sertifikayı güven zincirine (CA) kadar doğrular: imza geçerli
   mi, isim eşleşiyor mu, süresi dolmuş mu?
4. **Anahtar anlaşması** — iki taraf, sonraki trafiği şifreleyecek ortak bir oturum
   anahtarında anlaşır. Bundan sonrası şifrelidir.

Kritik nokta: adım 3, `notAfter`/isim/zincir kontrollerinin yapıldığı yerdir — üç sertifika
hatası tam da burada patlar. `openssl s_client -connect <host>:443 -servername <host>`
bu el sıkışmayı elle yürütüp her adımın çıktısını gösterir; `-servername` (SNI) doğru
sertifikanın sunulması için gereklidir (tek IP çok site barındırabilir).

### En sık üç sertifika hatası

| Hata | Ne demek | Sebep |
|---|---|---|
| **certificate has expired** | `notAfter` geçmiş | Yenileme unutuldu — bir **zaman** hatası |
| **name does not match** | Sertifikadaki isim ≠ istenen isim | Yanlış sertifika sunuluyor — bir **isim** hatası |
| **unable to get local issuer** | İmza zinciri tamamlanamıyor | Ara (intermediate) sertifika eksik — bir **zincir** hatası |

> Epigrafın söylediği bu: sertifika hataları çoğu zaman bir güvenlik saldırısı değil,
> bir **zaman / isim / zincir** hatasıdır. Hangisi olduğunu `openssl` çıktısından okumak,
> paniklemeden çözmenin yoludur. (Bu üç ayrım, D3 secret yönetiminde ve F2 uyumda geri gelecek.)

## 4️⃣ Zinciri birleştir: bir URL'yi girince ne olur

`https://example.com/health` yazdığında sırayla:

1. **DNS** — `example.com` bir IP'ye çözülür (`dig`).
2. **TCP** — o IP'nin `443` portuna bağlanılır, üç el sıkışma (A2).
3. **TLS** — sertifika sunulur, doğrulanır, şifreli kanal kurulur.
4. **HTTP** — `GET /health HTTP/1.1` gönderilir, yanıt (`200`, gövde) döner.

Her adım ayrı bir arıza noktasıdır. Teşhiste **hangi adımda durduğunu** bul; hepsini
tek seferde çözmeye çalışma:

```bash
dig +short example.com                              # 1. DNS çözülüyor mu
nc -vz example.com 443                               # 2. Porta TCP var mı (A2)
echo | openssl s_client -connect example.com:443 -servername example.com 2>/dev/null | head   # 3. TLS kuruluyor mu
curl -sS -o /dev/null -w "%{http_code}\n" https://example.com/health   # 4. HTTP ne diyor
```

Bu dört komut, "site açılmıyor"u dört ayrı, kanıtlanabilir soruya böler. Bir mühendisin
tahmin yerine yaptığı budur.

## 5️⃣ Teşhis refleksi — pratik örnekler

| Belirti | Hangi halka | İlk komut |
|---|---|---|
| "Sunucu bulunamadı" / isim çözülmüyor | DNS | `dig +short <isim>` boş mu |
| Bağlantı zaman aşımı | TCP/ağ (A2) | `nc -vz <isim> 443` |
| "Bağlantı güvenli değil" / sertifika uyarısı | TLS | `openssl s_client ...` → expired/name/chain? |
| `502`/`503` sayfa | HTTP/arka uç | `curl -v` → sunucu ayakta, arka uç yok |
| `404` | HTTP/uygulama | Yol yanlış; `curl -v` ile istenen yolu gör |

---

## 🚫 Anti-pattern tablosu
| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Sertifika hatasını `-k`/`--insecure` ile geçmek | Doğrulamayı kapatır, hatayı gizler; alışkanlık olur | Hatayı oku (zaman/isim/zincir), kök sebebi düzelt |
| DNS değişikliği "hemen yayılır" sanmak | TTL dolana kadar eski cevap önbellekte kalır | TTL'i bil, düşük TTL ile değişiklik planla, `dig` ile doğrula |
| `4xx` ve `5xx`'i "hata" diye tek görmek | İstemci mi sunucu mu ayrımını kaybeder | `4xx` = isteğe bak, `5xx` = sunucuya/arka uca bak |
| Unutulmuş `/etc/hosts` girdisi | DNS'i sessizce gölgeler, yanlış IP'ye gönderir | `getent hosts <isim>` ile gerçek çözümü doğrula |
| HTTP üzerinden sır/parola göndermek | Aradaki herkes okur | Her zaman TLS; düz HTTP yalnız yerel/geçici |
| Sertifika süresini elle takip etmek | Er ya da geç unutulur, üretim düşer | Otomatik yenileme + son kullanma **alarmı** (E2'de) |
| `ping` ile HTTPS'i test etmek | `ping` ICMP; TLS/HTTP hakkında hiçbir şey söylemez | Katmanı `curl`/`openssl` ile test et |

## 📖 İleri okuma (şimdi değil, sonra)
| Kaynak | Ne için | Ne zaman |
|---|---|---|
| `man dig`, `man curl`, `man openssl` | Alt komutların tam referansı | Bir bayrağı merak ettiğinde |
| [`08-Security/`](../../08-Security/) klasörü | TLS/PKI'nin güvenlik derinliği | **D bloğundan sonra** — sertifika yönetimi orada |

## 🔨 Lab
👉 [`labs/build/L03-dns-http-tls/`](../labs/build/L03-dns-http-tls/) — (Görev taslağı: bir ismi
çöz, HTTP yanıt başlıklarını oku, sertifikanın süresini/sahibini doğrula; DNS ile
TLS'i bilerek bozup her birini ayrı ayrı teşhis et.)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] Bir alan adını `dig +short` ile çözüp cevabını (IP + TTL) okudun; `/etc/resolv.conf` ile hangi resolver'a sorduğunu gösterdin.
- [ ] Bir HTTP yanıtının durum kodunu ve en az iki başlığını `curl -v`/`curl -I` ile okuyup, kodun `2xx/3xx/4xx/5xx` sınıfının ne anlattığını **yazdın**.
- [ ] Bir TLS sertifikasının subject/issuer/geçerlilik tarihlerini `openssl` ile çıkardın; expired/name/chain hatalarından hangisinin ne demek olduğunu **yazdın**.
- [ ] "Site açılmıyor"u dört komutla (DNS → TCP → TLS → HTTP) ayrı sorulara böldüğün bir teşhis dizisi çalıştırdın.

## 🧪 Kendini test et
1. `dig +short shop.example.com` boş dönüyor ama `dig +short example.com` bir IP veriyor. Ne çıkarırsın, sıradaki iki kontrolün ne?
2. **Senaryo:** Tarayıcı "bağlantınız gizli değil" diyor. `openssl s_client` çıktısında `notAfter` dünün tarihi. Sorun ne, nasıl doğrularsın, kalıcı çözüm ne?
3. **Tasarım:** Bir iç servis (yalnız şirket ağında) HTTPS sunacak ama internete açık bir CA'dan sertifika alamıyor. Kimliği nasıl doğrularsın, tradeoff ne?

<details><summary>Cevaplar</summary>

1. `shop` alt alan adının **A/CNAME kaydı yok** (ya da yanlış). Kontroller: (a) `dig shop.example.com ANY`/`CNAME` — kayıt hiç mi yok, yanlış mı; (b) `dig shop.example.com @<yetkili_ns>` — sorunu resolver önbelleği mi yoksa gerçekten eksik kayıt mı ayır. IP çözülmeyen bir isme HTTP/TLS denemek boşunadır; zincir DNS'te kopmuş.

2. **Sertifikanın süresi dolmuş** (`notAfter` geçmiş) — bir zaman hatası, saldırı değil. Doğrula: `openssl s_client -connect <host>:443 2>/dev/null | openssl x509 -noout -dates` ile `notAfter`'ı gör. Kalıcı çözüm: sertifikayı yenile **ve** yenilemeyi otomatikleştir + son kullanma alarmı kur (E2). Elle takip er ya da geç unutulur.

3. İç servis için kendi (özel) CA'nı kurup sertifikayı onunla imzala, sonra bu CA'yı istemci makinelerin/servislerin güven deposuna ekle. Tradeoff: tam kontrol ve internet bağımsızlığı kazanırsın ama CA'yı sen yönetirsin — anahtar güvenliği, süre yenileme, güven dağıtımı senin sorumluluğun. `-k`/`--insecure` bir çözüm değildir; doğrulamayı kapatmak yerine doğru güveni kur.

</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| `dig` boş `ANSWER` | Kayıt yok / yanlış resolver / önbellek | `dig <isim> @1.1.1.1`, `getent hosts <isim>` |
| Yanlış IP'ye gidiyor | `/etc/hosts` gölgeliyor | `getent hosts <isim>`; `/etc/hosts`'u kontrol et |
| `curl` takılıyor, cevap yok | TCP/ağ katmanı (A2) | `nc -vz <isim> 443`, sonra `ip route` |
| `curl: (60) SSL certificate problem` | expired / name / chain | `openssl s_client ...` ile hangisi olduğunu belirle |
| `502 Bad Gateway` | Ön uç ayakta, arka uç yok | Arka uç servisini kontrol et (A6'da bağlayacaksın) |
| `dig: command not found` | Paket eksik | `sudo apt install dnsutils` (Debian/Ubuntu) |

## 💼 Portfolyo çıktısı
Doğrudan çıktı yok; A6'da servis + isim + sertifika kurulumunda ve E-blok incident
çalışmalarında kullanılır.

## ⏭️ Sırada
[`A4 — Git Temeli`](A4-git-temeli.md)

---

> *"Sertifika hatası bir güvenlik değil, çoğu zaman bir zaman/isim/zincir hatasıdır — hangisi olduğunu görebilmek beceridir."*
