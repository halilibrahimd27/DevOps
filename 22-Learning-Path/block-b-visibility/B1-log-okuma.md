---
description: "Log okuma: journalctl, structured logging ve ne loglanır ne loglanmaz — göremediğin sistemi yönetemezsin."
level: B
module: B1
estimated_hours: 12
prerequisites: [A6]
tags: [Learning Path, Observability]
---
# B1 — Log Okuma: journalctl, Structured Logging

> *"Göremediğin sistemi yönetemezsin. Log, sistemin sana anlattığı ilk hikâyedir."*

**Blok:** B — Görebilmek · **Süre:** ~12 saat · **Ön koşul:** [`A6`](../block-a-intuition/A6-elle-deploy.md)

## 🎯 Bu modülü bitirdiğinde
- `journalctl` ile bir servisin loglarını zamana, servise ve önem düzeyine göre süzersin.
- Yapılandırılmış (structured) log ile düz metin log arasındaki farkı ve niçinini açıklarsın.
- Neyin loglanması, neyin (sır/PII) **loglanmaması** gerektiğine karar verir ve gerekçelendirirsin.

## 🧠 Niye bu, niye şimdi
A6'da kurduğun servis bozulacak — kaçınılmaz. Onu görebilmek için önce logunu okumayı
bilmen gerekir; A6'nın son adımında bir 502'yi log'la daraltmayı gördün, şimdi bunu
disipline çeviriyoruz. B2'deki metrik "ne kadar / ne sıklıkla" der; log ise "tam olarak
ne oldu"yu tek olay çözünürlüğünde anlatır. B3'teki ilk kırık lab bu beceri üstüne
kurulur: log okuyamayan, arızayı tahmin eder.

## 📖 Nasıl çalışılır
A6'daki VM'inde çalış. Uygulamanı bilerek birkaç kez boz (yanlış DB parolası, kapalı
port), her seferinde önce **log'a bak**, sonra düzelt. Log okumayı bir refleks hâline
getir: "bir şey yanlış → önce `journalctl`".

## 📚 Kavram haritası
| Terim | Bir cümlede |
|---|---|
| **journald** | systemd'nin merkezi log toplayıcısı; tüm servis loglarını tek yerde tutar |
| **`journalctl`** | journald'ı sorgulama aracın |
| **Log seviyesi** | `emerg`…`debug` — olayın ne kadar acil olduğu |
| **Structured log** | Anahtar-değer/JSON biçiminde log — insan değil, makine de okur |
| **Correlation ID** | Bir isteği tüm servisler boyunca izlemeni sağlayan kimlik |
| **PII** | Kişisel veri (ad, e-posta, TC no) — log'a girmemesi gereken sınıf |
| **Log rotation** | Eski logları döndürüp silme; diskin dolmasını önler |

---

## 1️⃣ journalctl: dört süzgeç

A6'da `journalctl -u app` gördün. Gerçek iş bu logu **daraltmaktır** — bir arızada
milyon satırı değil, ilgili olanı okursun:

```bash
journalctl -u app -e                      # sadece 'app' servisi, sona git (en yeni)
journalctl -u app -f                       # canlı takip (bir istek at, gör)
journalctl -u app --since "10 min ago"     # zaman penceresi
journalctl -u app -p err                   # yalnız 'err' ve daha acil (öncelik süzgeci)
journalctl -u app --since today -p warning..err   # bugün, warning–err aralığı
```

Bu dördünü birleştir: "son 10 dakikada, app servisinde, error seviyesinde ne oldu?" bir
komuttur — okuyacağın satır sayısı yüzden aza iner.

## 2️⃣ Önem düzeyleri: her satır eşit değil

Syslog seviyeleri (acilden ayrıntıya):

| Seviye | Ne demek | Örnek |
|---|---|---|
| `emerg`/`alert`/`crit` | Sistem kullanılamaz / hemen müdahale | Disk doldu, servis tümden çöktü |
| `err` | Bir işlem başarısız | DB bağlantısı reddedildi |
| `warning` | Sorun değil ama dikkat | Yeniden deneme, yavaşlama |
| `notice`/`info` | Normal, önemli olaylar | "Servis başladı", "istek işlendi" |
| `debug` | Ayrıntılı geliştirme izi | Değişken değerleri |

Bir arızada `-p err` ile başla; hiçbir şey yoksa `-p warning`'e genişlet. Production'da
`debug` **kapalı** olmalı — gürültü sinyali gömer ve diski doldurur.

## 3️⃣ Düz metin mi, structured mı

İki log satırını karşılaştır:

```
# düz metin — insan okur, makine zorlanır
2026-07-21 10:03:12 Kullanici girisi basarisiz oldu, tekrar deneniyor

# structured (JSON) — hem insan hem makine okur
{"ts":"2026-07-21T10:03:12Z","level":"warn","event":"login_failed","user_id":"u_123","attempt":2,"request_id":"r_abc"}
```

Düz metin insan için hoştur ama **süzülemez**: "başarısız login'leri kullanıcıya göre
say" diyemezsin. Structured log'da her alan sorgulanabilir; C1'den sonra kuracağın log
sistemleri (Loki, ELK) tam olarak bu alanlar üzerinden filtreler ve panolar üretir.

> Kural: uygulama loglarını structured (JSON) yaz. Her satırda en az: zaman, seviye,
> olay adı, ve isteği izlemek için bir `request_id`/`correlation_id`. Bu id, bir isteği
> servisten servise izlemenin (ileride tracing) tek yoludur.

## 4️⃣ Ne loglanır

İyi bir log satırı bir soruya cevap verir: *"Ne oldu, kim/ne için, sonuç ne?"*

- **Olaylar** — servis başladı/durdu, deploy oldu, config değişti.
- **Kararlar ve sonuçlar** — "istek reddedildi (yetkisiz)", "yeniden deneme 3/3".
- **Kimlik (referans olarak)** — `user_id: u_123` gibi **takma** kimlik, ismin/e-postanın kendisi değil.
- **Korelasyon** — `request_id`, böylece bir isteğin tüm izini toplarsın.

## 5️⃣ Ne loglanMAZ — kırmızı çizgi

> 🔒 Log bir sızıntı vektörüdür. Log dosyaları çoğu zaman merkezi bir yere akar,
> yedeklenir, uzun süre saklanır ve birçok kişi erişir. Şunlar **asla** log'a girmez:
> parola, token, API anahtarı, oturum çerezi, kredi kartı numarası, kimlik doğrulama
> başlığı (`Authorization:`), ve ham PII (ad-soyad, e-posta, TC kimlik no, telefon).

```
# ❌ felaket
{"event":"login","user":"ayse@example.com","password":"S3cret!","token":"eyJhbGci..."}

# ✅ güvenli
{"event":"login","user_id":"u_123","result":"success","request_id":"r_abc"}
```

> 🇹🇷 **KVKK notu:** Kişisel veriyi log'a yazmak bir **işleme** faaliyetidir ve
> amaç/saklama süresi/erişim kısıtı gerektirir. En temiz çözüm veriyi **hiç loglamamak**:
> gerçek e-posta yerine takma `user_id`, gerektiğinde ayrı, erişimi kısıtlı bir sistemde
> çözümle. "Log'a ne yazılır" bir mühendislik kararı olduğu kadar bir uyum kararıdır
> (bkz. [`19-Compliance/KVKK-Practical.md`](../../19-Compliance/KVKK-Practical.md)).

## 6️⃣ Disk dolması: log'un fiziksel sınırı

Log sonsuz değildir; yazıldığı disk dolar ve **dolu disk bir arıza sebebidir** (K00/K01
kırık lab'larının klasik kök sebeplerinden). journald'ın ne kadar yer tuttuğunu gör ve sınırla:

```bash
journalctl --disk-usage                    # journald ne kadar yer tutuyor
sudo journalctl --vacuum-time=7d           # 7 günden eski logları at
df -h /var/log                             # log diski ne kadar dolu (A1)
```

Uygulama logları için de rotation (döndürme + sıkıştırma + silme) kur — yoksa `/var/log`
dolar, servis yazamaz, sistem tökezler. Bunu bir kez elle kur ki C ve D'de otomatiğin
neyi hallettiğini bil.

## 7️⃣ Log'la arıza daraltma — pratik

A6'nın 502 örneğini genelle. Bir arızada log okuma akışı:

```bash
journalctl -u app --since "15 min ago" -p err   # 1) hata var mı, ne zaman başladı
journalctl -u app -e                             # 2) o hatanın etrafındaki bağlam
sudo tail -50 /var/log/nginx/error.log           # 3) proxy tarafı ne diyor
df -h; journalctl --disk-usage                    # 4) altyapı sınırı mı (disk?)
```

Her adımda bir **hipotez** kur ve log'la **kanıtla** — tahmin etme. "Muhtemelen DB'dir"
değil, "log'da `connection refused to :5432` yazıyor, demek DB". Bu ayrım (kanıt vs
tahmin) B → C geçiş sinyalidir ve B3'te sınanır.

## 8️⃣ Uygulama nereye loglar

Bir servisin logunu bulmak için önce **nereye yazdığını** bilmen gerekir. Üç yaygın yer:

| Nereye | Nasıl okunur | Ne zaman |
|---|---|---|
| **stdout/stderr** | systemd yakalar → `journalctl -u <servis>` | Modern uygulamalar (12-factor) — önerilen |
| **Kendi dosyası** (`/var/log/app/…`) | `tail -f`, `less` | Eski uygulamalar; rotation'ı sen kurarsın |
| **syslog / journald** (`logger`) | `journalctl` | Sistem servisleri, cron |

Modern kural (12-factor app): uygulama loga **dosya açmaz**, sadece stdout/stderr'e yazar;
onu nereye koyacağına *çalıştıran ortam* karar verir (systemd → journald, container →
stdout → log toplayıcı). Bu, C1'den sonra container loglarının niçin `docker logs` ile
okunduğunun temelidir — uygulama aynı, sadece stdout'u farklı yer topluyor.

`journalctl` birden çok servisi tek zaman ekseninde birleştirir — bir arızada nginx ve
uygulama loglarını **beraber** görmek çoğu zaman kilidi açar:

```bash
journalctl -u nginx -u app --since "10 min ago"   # ikisi tek akışta, zamana göre
```

## 9️⃣ Bir arıza oturumu: baştan sona

A6 servisin "500 dönüyor" diye şikayet geldi. Log'la, tahmin etmeden çözelim:

```bash
# 1) Belirtiyi zamanla eşle: ne zaman, ne seviyede?
journalctl -u app --since "20 min ago" -p err
# Jul 21 10:31:02 app[812]: ERROR db connect failed: password authentication failed
```

```bash
# 2) Bağlamı gör: bundan hemen önce ne oldu?
journalctl -u app -e
# ... 10:30:58 config reloaded from /etc/app.env
```

Kanıt zinciri: hata `10:31:02`'de başladı, hemen öncesinde (`10:30:58`) config yeniden
yüklendi → biri `/etc/app.env`'i değiştirdi ve DB parolası artık yanlış. Hipotez artık
tahmin değil, **iki log satırıyla kanıtlı**. Doğrula:

```bash
# 3) DB'yi doğrudan test et (uygulamayı ele) — B'nin daraltma refleksi
psql "postgresql://appuser:<DB_PASSWORD>@127.0.0.1:5432/appdb" -c "SELECT 1;"
# FATAL: password authentication failed for user "appuser"   → kanıtlandı
```

Düzelt (`/etc/app.env`'deki parolayı düzelt, `systemctl restart app`), sonra **belirtinin
gittiğini kanıtla** — sadece "düzelttim" deme:

```bash
curl -s http://127.0.0.1/health          # 200 ok
journalctl -u app --since "1 min ago" -p err   # boş → yeni hata yok
```

Bu akış — belirti → log → kanıt → düzelt → doğrula — B3'teki kırık lab'ın ve E3'teki
postmortem'in çekirdeğidir. Fark yalnızca ölçek.

## 🔟 journalctl'in derinliği: biçim, alan, önyükleme

Dört süzgeç (`-u`, `--since`, `-p`, `-f`) iş görür ama bir arızada seni asıl hızlandıran
üç şey daha var: **çıktı biçimi**, **alan süzgeci** ve **önyükleme (boot) sınırı**.

### Çıktı biçimini değiştir
Aynı logu farklı biçimde okumak farklı soruları açar:

```bash
journalctl -u app -o short-iso        # UTC/ISO zaman damgası (korelasyon için — B2)
journalctl -u app -o json-pretty      # tüm alanları gör (structured log'un ham hâli)
journalctl -u app -o cat              # yalnız mesaj, meta yok — göz taraması için
```

`-o json-pretty`, bir log satırının journald'da *aslında* hangi alanları taşıdığını
gösterir (`_PID`, `_SYSTEMD_UNIT`, `_HOSTNAME`, `PRIORITY`…). Bu alanlar süzülebilir —
işte asıl güç burada.

### Alanla süzmek: `-u`'dan daha keskin
`-u` servise göre süzer; ama bazen "şu tek process" ya da "şu kullanıcı" gerekir:

```bash
journalctl _PID=812                    # yalnız 812 numaralı process'in çıktısı
journalctl _UID=1000                   # belirli bir kullanıcının servisleri (A1 UID)
journalctl _SYSTEMD_UNIT=app.service PRIORITY=3   # app + yalnız 'err' (3=err)
```

Alan süzgeçleri **VE** mantığıyla birleşir. Bir arızada "812 no'lu process bugün ne hata
verdi?" tek satırda ifade edilir — milyon satır yerine on satır okursun.

### Önyükleme ve çekirdek: nereye bakacağını bil
Sistem yeniden başladıysa, "hata restart'tan önce miydi sonra mıydı?" kritik sorudur:

```bash
journalctl -b                          # yalnız BU önyüklemeden beri (restart sonrası)
journalctl -b -1                       # bir ÖNCEKİ önyükleme (çökme öncesi log)
journalctl --list-boots                # önyükleme geçmişi + kimlikleri
journalctl -k                          # yalnız çekirdek (kernel) mesajları = dmesg
```

`-b -1` bir çökmeyi araştırırken paha biçilmez: sistem sertçe kapandıysa, **çöküşten
hemen önceki** logu ancak önceki önyüklemeye bakarak görürsün. `-k` ise OOM killer, disk
G/Ç hatası, donanım uyarısı gibi çekirdek düzeyi sorunları ayıklar (A1'deki `dmesg`'in
journald karşılığı).

## 1️⃣1️⃣ Log kalıcı mı, geçici mi — ve niçin kayboluyor

Yeni bir sistemde `journalctl -b -1` çoğu zaman **boş** döner. Sebebi bir hata değil,
bir **yapılandırma**: journald varsayılan olarak logu belleğe/`/run`'a (geçici) yazar ve
her yeniden başlatmada **silinir**. Kalıcı olması için diskte bir dizin gerekir:

```bash
journalctl --list-boots                # tek satır dönüyorsa log kalıcı DEĞİL
ls /var/log/journal 2>/dev/null || echo "kalıcı journal yok"
sudo mkdir -p /var/log/journal && sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald   # artık restart'lar arası log kalır
```

> Bunu bir arıza *öncesi* kur. Çöken sistemin logu, çökmeden önce diske yazılmadıysa
> kaybolur; "loga bakalım" dediğinde bakacak bir şey kalmaz. Kalıcı journal, teşhisin ön
> koşuludur.

Bir de **hız sınırı (rate limiting)** var: journald saniyede çok fazla satır gelirse
bir kısmını **düşürür** ve `Suppressed N messages` yazar. Bir servis log'a boğuluyorsa
(gürültü) hem sinyal kaybolur hem de gerçekten önemli satır düşebilir:

```bash
journalctl -u app | grep -i "suppressed"   # log düşürülmüş mü?
```

Çözüm satır sınırını yükseltmek değil, **daha az/daha anlamlı loglamaktır** (§2 önem
düzeyleri): production'da `debug` kapalı, her istek için tek özet satır. Bu, "her şeyi
loglama" ilkesinin (kapanış cümlesi) altyapı tarafındaki kanıtıdır.

---

## 🚫 Anti-pattern tablosu
| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Sır/PII/token log'a yazmak | Kalıcı, dağıtık sızıntı; KVKK ihlali | Takma id logla; sırrı hiç yazma |
| Her şeyi `debug` seviyesinde loglamak | Gürültü sinyali gömer, disk dolar | Production'da `info`+; `debug` kapalı |
| Düz metin, süzülemez log | "Kullanıcıya göre say" imkânsız | Structured (JSON) + `request_id` |
| Log rotation kurmamak | `/var/log` dolar, servis yazamaz | `journalctl --vacuum` + uygulama rotation |
| Arızada tüm logu göz gezdirmek | Zaman kaybı, ilgisiz satırda boğulma | `-u` + `--since` + `-p` ile daralt |
| Hipotezi kanıtsız kabul etmek | Yanlış yeri düzeltip zaman kaybedersin | Her hipotezi bir log satırıyla doğrula |
| Zaman damgasını yerel/formatsız yazmak | Sistemler arası korelasyon kırılır | UTC + ISO-8601 (`...T10:03:12Z`) |
| Log'u tek gerçek kaynak sanmak | Eğilimi/oranı göremezsin | Log (olay) + metrik (eğilim) birlikte — B2 |
| Kalıcı journal kurmamak | Çökme sonrası `-b -1` boş; kanıt yok | `/var/log/journal` oluştur, journald restart |
| Log düşürülmesini görmezden gelmek | `Suppressed N messages` = kayıp sinyal | Az/anlamlı logla; `debug` kapalı |

## 📖 İleri okuma (şimdi değil, sonra)
| Kaynak | Ne için | Ne zaman |
|---|---|---|
| [`07-Observability/Logs-Loki-vs-ELK.md`](../../07-Observability/Logs-Loki-vs-ELK.md) | Merkezi log stack'i (Loki/ELK) — birden çok makinede log | **C1'den sonra** — container gelince |
| [`19-Compliance/KVKK-Practical.md`](../../19-Compliance/KVKK-Practical.md) | Log'da PII'nin uyum boyutu | F2 (uyum) öncesi merak seviyesinde |

## 🔨 Lab
👉 [`labs/build/L07-log-okuma/`](../labs/build/L07-log-okuma/) — (Görev taslağı: A6 uygulamanı
üç farklı şekilde boz, her birini yalnız `journalctl` süzgeçleriyle bul; bir de bilerek
sır sızan bir log satırı yaz ve onu güvenli hâle getir.)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] `journalctl -u <servis> --since "..." -p err` ile bir servisin son hatalarını süzdün ve çıktısını gösterdin.
- [ ] Bir olayı (örn. başarısız bir istek) tek bir log satırına kadar, zaman damgasıyla izledin.
- [ ] Bir düz-metin log satırını structured (JSON) biçime çevirdin; hangi alanların sorgulanabilir olduğunu gösterdin.
- [ ] "Hangi alan log'a yazılmamalı ve niçin" sorusunu, en az bir sır ve bir PII örneğiyle **yazılı** yanıtladın.

## 🧪 Kendini test et
1. `journalctl -u app -p err` ile `journalctl -u app` arasındaki fark nedir, hangisini bir arızaya **ilk** çalıştırırsın?
2. **Senaryo:** Bir kullanıcı "3 saat önce hata aldım" diyor. Servisi ve yaklaşık zamanı biliyorsun. İlgili logu bulmak için hangi tek komutu yazarsın?
3. **Tasarım:** Bir login olayını loglayacaksın. Hangi alanları yazarsın, hangilerini **kesinlikle** yazmazsın, niçin?

<details><summary>Cevaplar</summary>

1. `-p err` yalnız `err` ve daha acil satırları gösterir; `-p`'siz hepsini (info/debug dahil) döker. Bir arızaya **önce `-p err`** ile başlarsın — gürültüyü keser, "neyin patladığını" hızla gösterir; boşsa `-p warning`'e genişletirsin.

2. `journalctl -u app --since "3 hours ago" --until "2 hours ago" -p warning` gibi — servisi (`-u`), zaman penceresini (`--since/--until`) ve önem süzgecini (`-p`) birleştir. Böylece milyon satır yerine ilgili birkaç satırı okursun.

3. **Yazarım:** zaman (UTC/ISO), `level`, `event: login`, `result: success/failed`, takma `user_id`, `request_id`, kaba coğrafya/istemci türü (gerekirse). **Yazmam:** parola, token/oturum çerezi, `Authorization` başlığı, ham e-posta/ad-soyad/TC no. Niçin: sırlar ele geçirilince tüm hesabı verir; PII loglamak KVKK açısından gereksiz bir işleme ve sızıntı riskidir. Takma kimlik yeterli izlenebilirliği sağlar, riski taşımaz.

</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| `journalctl -u app` boş | Servis adı yanlış / hiç log yok | `systemctl list-units \| grep app` ile tam adı bul |
| Çok fazla satır, boğuldum | Süzgeç yok | `-u` + `--since` + `-p err` ile daralt |
| `-f` canlı ama hiçbir şey akmıyor | İstek gelmiyor / uygulama sessiz | Başka terminalden `curl` at, tekrar bak |
| Disk doldu uyarısı | Log rotation yok | `journalctl --vacuum-time=7d`; `df -h` |
| Log'da parola gördüm | Uygulama sır logluyor | Uygulamada logu düzelt; **sızan sırrı döndür** |
| Zaman damgaları tutmuyor | Yerel saat / saat kayması | UTC'ye geç; NTP senkronunu kontrol et |

## 💼 Portfolyo çıktısı
Doğrudan bir artefakt değil; bir teşhis alışkanlığı. B3'teki kırık lab'da ve E
bloğundaki incident çalışmalarında yazdığın "arıza günlükleri"nde görünür olacak.

## ⏭️ Sırada
[`B2 — Metrik`](B2-metrik-prometheus.md)

---

> *"Loga her şeyi yazmak da körlüktür: gürültü, sinyali gömer."*
