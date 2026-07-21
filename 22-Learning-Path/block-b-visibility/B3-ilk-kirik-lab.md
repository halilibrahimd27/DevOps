---
description: "İlk kırık lab: bilerek bozulmuş bir VM sisteminde arızayı log ve metrikle bulup kanıtlamak."
level: B
module: B3
estimated_hours: 12
prerequisites: [B1, B2]
tags: [Learning Path, Debugging]
---
# B3 — İlk Kırık Lab

> *"Tutorial 'şunu kur' der; kırık lab 'şunu tamir et' der. İkincisi mühendis yetiştirir."*

**Blok:** B — Görebilmek · **Süre:** ~12 saat · **Ön koşul:** [`B1`](B1-log-okuma.md), [`B2`](B2-metrik-prometheus.md)

## 🎯 Bu modülü bitirdiğinde
- Ne bozulduğu söylenmeden, yalnızca belirtiden yola çıkıp arızayı sistematik olarak daraltırsın.
- Hipotezini log ve metrikle **kanıtlarsın**, tahmine dayanmazsın.
- Kök sebebe giden teşhis akışını, başkasının izleyebileceği biçimde **yazılı** anlatırsın.

## 🧠 Niye bu, niye şimdi
Kırık lab, B3'ten itibaren patikanın omurgasıdır. Şimdiye kadar hep **kurdun**;
kurabilmek bir beceri ama asıl mühendislik, senin kurmadığın bir şey bozulduğunda onu
**geri getirebilmek**tir. Blok C'ye (karmaşıklık eklemek — container, CI, Terraform)
geçmeden önce, kurduğun sistemi görebildiğini (B1/B2) ve bir arızayı kanıtlayabildiğini
göstermen gerekir. **Bu modül, B → C geçiş sinyalinin sınavıdır:** *"Bir servisin neden
ayağa kalkmadığını, dokümana bakmadan üç komutla daraltabiliyor musun?"*

## 📖 Nasıl çalışılır
K01 kırık lab'ının `README.md`'si sana **yalnızca belirtiyi** söyler ("servis yanıt
vermiyor"). Ne bozulduğunu söylemez — söylemesi bütün dersi öldürür. `hints/` klasörünü
**erken açma**: önce kendin daralt. Takıldığında sırayla `hint-1` (yön) → `hint-2`
(daralt) → `hint-3` (neredeyse cevap). Çözerken bir `teshis.md` tut; her adımda ne
gördüğünü ve ne çıkardığını yaz. O dosya bu modülün asıl çıktısıdır.

## 📚 Kavram haritası
| Terim | Bir cümlede |
|---|---|
| **Belirti (symptom)** | Gözlemlenen yanlış davranış ("502 dönüyor") — sebep değil |
| **Kök sebep (root cause)** | Belirtiyi üreten asıl neden ("DB parolası yanlış") |
| **Hipotez** | Sebep hakkında test edilebilir bir tahmin |
| **Kanıt** | Hipotezi doğrulayan/çürüten somut çıktı (log satırı, metrik) |
| **Daraltma (bisection)** | Sistemi katmanlara bölüp arızayı yarıya indirme |
| **USE method** | Utilization / Saturation / Errors — kaynak darboğazı taraması |

---

## 1️⃣ Tutorial vs kırık lab: niçin bu fark her şey

Bir tutorial mutlu yolu gösterir: adımları takip et, çalışır. Ama production'da adımlar
seni beklemez; bozuk, yarım, çelişkili bir durumla karşılaşırsın ve **sana kimse ne
bozulduğunu söylemez.** Kırık lab bu gerçeği simüle eder. Öğrettiği şey bir komut değil,
bir **tavır**dır: panik yerine yöntem.

## 2️⃣ Teşhis disiplini: belirti → hipotez → kanıt → düzelt

Arızayı çözmek doğaçlama değil, küçük bir bilimsel yöntemdir:

```
1. Belirtiyi netleştir   → "Tam olarak ne yanlış? Ne zaman başladı?"
2. Hipotez kur           → "Sanırım DB'ye bağlanamıyor."
3. Kanıt topla           → journalctl'de 'connection refused to :5432' var mı?
4. Kanıt hipotezi tutuyor mu?
     evet → düzelt, sonra DOĞRULA (belirti gitti mi?)
     hayır → yeni hipotez, 2'ye dön
```

Kritik olan 3. adım: **her hipotezi bir çıktıyla kanıtla.** "Muhtemelen DB'dir" bir
teşhis değil, bir tahmindir; onunla yanlış yeri düzeltip saatler kaybedersin. B1 (log) ve
B2 (metrik) tam olarak bu kanıtı sağlamak için vardı.

## 3️⃣ Daraltma: sistemi katmanlara böl

A6'da kurduğun mimarîyi hatırla — arıza bu zincirin bir halkasındadır:

```
tarayıcı → nginx → uygulama → veritabanı
                    ↑ altta: OS (izin, disk, port, DNS, saat)
```

Her katmanı tek tek sına, arızayı **yarıya indir**:

```bash
curl -s http://127.0.0.1/health        # nginx üzerinden — çalışıyor mu?
curl -s http://127.0.0.1:<APP_PORT>/health   # doğrudan uygulama — çalışıyor mu?
psql "postgresql://.../appdb" -c "SELECT 1;" # DB — bağlanıyor mu?
```

`curl 127.0.0.1/health` patlıyor ama `curl :<APP_PORT>/health` çalışıyorsa → sorun nginx
ile uygulama **arasında** (proxy config, port). İkisi de patlıyorsa → uygulamada veya
altındadır. Böylece arama alanını her adımda ikiye bölersin — dört komutta kök sebebe
inersin.

## 4️⃣ Üç-komut refleksi (A → B geçiş sinyali)

Bir servis ayağa kalkmadığında, dokümana bakmadan attığın ilk üç komut:

```bash
systemctl status <servis>              # 1) çalışıyor mu, failed mı, ne diyor
journalctl -u <servis> -e -p err       # 2) neden çıktı — son hatalar (B1)
ss -tlnp | grep <PORT>                  # 3) port gerçekten dinleniyor mu (A2)
```

Buna bir de kaynak kontrolü eklenir: `df -h` (disk dolu mu — çok yaygın kök sebep) ve
`free -h` (bellek). Bu refleks, geçiş sinyalinin kendisidir — düşünmeden, sırayla gelmeli.

## 5️⃣ Kaynak darboğazı: USE method

Bir sistem "yavaş" ya da "tökezliyor"sa, tek tek servis yerine **kaynaklara** bak. USE
method her kaynak için üç soru sorar:

| | Soru | Komut |
|---|---|---|
| **U**tilization | Ne kadar meşgul? | `top`, `mpstat` |
| **S**aturation | Kuyruk/bekleme var mı? | `uptime` (load), `vmstat` |
| **E**rrors | Hata sayacı artıyor mu? | `dmesg`, `journalctl -p err` |

Derinlik (Brendan Gregg'in USE method'u, 60-saniye protokolü):
[`16-Cheatsheets/linux-troubleshooting.md`](../../16-Cheatsheets/linux-troubleshooting.md).
Bu cheatsheet artık **senin için okunabilir** — A1–A6 ve B1–B2'yi bitirdin; başlangıçta
"duvar" olan bu doküman şimdi araç kutun.

## 6️⃣ Yaygın kök sebep sınıfları

Kırık lab'ların bozukluğu gerçekçidir. En sık görülen sınıflar:

| Sınıf | Belirti | İlk kontrol |
|---|---|---|
| **İzin** (permission denied) | Servis dosyaya/porta erişemiyor | `ls -l`, `journalctl` (A1 izin modeli) |
| **Port çakışması** | `Address already in use` | `ss -tlnp \| grep <PORT>` |
| **Disk dolu** | Yazma hatası, servis çöküyor | `df -h`, `df -i` (inode) |
| **DNS** | "isim çözülemedi", timeout | `dig`, `/etc/resolv.conf` (A3) |
| **systemd unit** | `failed`, yanlış `ExecStart`/path | `systemctl status`, unit dosyası (A6) |
| **Saat kayması** | TLS/sertifika/kimlik hataları | `timedatectl`, NTP |
| **Yanlış config** | Servis başlıyor, yanlış davranıyor | Config diff, `nginx -t` |

> 🔒 `permission denied` bir **güvenlik sınırıdır**, sinir bozucu bir engel değil. Onu
> `chmod 777` veya servisi `root` çalıştırarak "çözmek" arızayı kapatmaz, bir açık açar
> — reponun tüm eleştirdiği hatanın ta kendisi. Doğru düzeltme: **hangi kullanıcının,
> hangi kaynağa, niçin erişmesi gerektiğini** anla ve en dar izni ver (A1/A6 least-privilege).

## 7️⃣ Teşhis akışını yazmak

Kök sebebi bulmak yarısı; onu **yazmak** diğer yarısı. İyi bir teşhis notu şunları içerir:

- **Belirti** — ne gözlemledin (tam çıktıyla).
- **Daraltma adımları** — hangi hipotezi hangi kanıtla eledin.
- **Kök sebep** — asıl neden.
- **Düzeltme** — ne yaptın, ve belirtinin gittiğini nasıl doğruladın.
- **Niçin böyle oldu / tekrar nasıl önlenir** — bir sonraki kişi için.

Bu yapı bir tesadüf değil; E3'teki **blameless postmortem**'in çekirdeğidir. Burada tek
kişilik bir lab için yazdığın şey, orada bir ekip için yazacağın belgenin taslağıdır.

## 8️⃣ Hint disiplini: kendini erken kurtarma

Hint'ler bir başarısızlık değil, ayarlı bir güvenlik ağıdır. Ama **erken açmak** dersi
çalar. Kural: bir hipotezi kanıtla test etmeden hint açma. Sıra:

- `hint-1` → yön ("hangi katmana bak").
- `hint-2` → daralt ("şu komutun çıktısına dikkat et").
- `hint-3` → neredeyse cevap.

`hint-3`'ü açtıysan sorun değil — ama sonra `solution.md`'yi oku ve **teşhis akışını**
(cevabı değil, oraya nasıl gidildiğini) ayrıca çalış. Asıl öğretilen o akıştır.

---

## 🚫 Anti-pattern tablosu
| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Belirtiyi kanıtsız bir sebebe bağlamak | Yanlış yeri düzeltir, saat kaybedersin | Her hipotezi log/metrikle kanıtla |
| Rastgele "şunu da deneyeyim" | İzlenemez, tekrar üretilemez, yeni arıza doğurur | Katman katman daralt (bisection) |
| `permission denied`'ı `chmod 777` ile geçmek | Arızayı kapatır, güvenlik açar | Doğru kullanıcı + en dar izin (A1/A6) |
| Hint'i ilk takılmada açmak | Teşhis kasını çalıştırmadan geçersin | Önce üç-komut refleksi + bir hipotez dene |
| Düzeltip doğrulamamak | Belirti hâlâ orada olabilir | Düzeltmeden sonra belirtinin gittiğini kanıtla |
| Kök sebep yerine belirtiyi düzeltmek | Servisi yeniden başlatmak arızayı geri getirir | Asıl nedeni bul; restart erteleme değil çözüm değil |
| Teşhisi yazmamak | Bir dahaki sefere sıfırdan; ekip öğrenmez | `teshis.md` tut (E3 postmortem tohumu) |
| Sadece tahminle çalışmak | "Muhtemelen DB" ≠ teşhis | Kanıt = B → C geçişinin ta kendisi |

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`16-Cheatsheets/linux-troubleshooting.md`](../../16-Cheatsheets/linux-troubleshooting.md) | USE method + 60-saniye protokolü — teşhis çerçevesi | ~25 dk |

## 💥 Kırık lab
👉 `labs/broken/K01-kirik-vm/` — Faz 5'te oluşturulacak. Belirti: "Servis ayağa
kalkmıyor / yanıt vermiyor." Gerçekçi sebep gizli (yanlış izin / port çakışması / disk
dolu / systemd unit hatası). `README.md` **asla** ne bozulduğunu söylemez — yalnız
belirtiyi verir.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] K01'i çözdün: `bash labs/broken/K01-kirik-vm/verify.sh` sıfır hatayla geçiyor.
- [ ] Kök sebebi log/metrik **kanıtıyla** gösteren bir `teshis.md` yazdın (belirti → daraltma → kök sebep → düzeltme → doğrulama).
- [ ] "Dokümana bakmadan hangi üç komutla daralttın" sorusunu, komutları ve niçinlerini vererek **yazdın** (A → B sinyali).
- [ ] Düzeltmeden sonra belirtinin **gittiğini** ayrı bir komutla kanıtladın (sadece "düzelttim" demedin).

## 🧪 Kendini test et
1. "Belirti" ile "kök sebep" arasındaki fark nedir? "502 dönüyor" hangisidir?
2. **Senaryo:** `curl 127.0.0.1/health` → 502. Sistemi ikiye bölerek kök sebebe inmek için ilk hangi komutu çalıştırırsın ve iki olası sonucu ne anlama gelir?
3. **Tasarım:** Bir arızayı çözdün ama neden olduğunu tam anlamadın; servisi yeniden başlatınca düzeldi. İşin bitti mi? Niçin?

<details><summary>Cevaplar</summary>

1. Belirti = gözlemlenen yanlış davranış; kök sebep = onu üreten asıl neden. "502 dönüyor" bir **belirti**dir — nginx arkadaki uygulamaya ulaşamıyor demek, ama *niçin* ulaşamadığı (uygulama ölü mü, port yanlış mı, DB mi düşürdü) kök sebeptir ve ayrıca bulunmalıdır.

2. `curl -s http://127.0.0.1:<APP_PORT>/health` — nginx'i atlayıp **doğrudan uygulamaya** giderim. (a) Çalışıyorsa: uygulama sağlam, sorun nginx ↔ uygulama arasında (proxy config/port) → aramayı oraya daraltırım. (b) Bu da patlıyorsa: sorun uygulamada veya altında (DB, izin, systemd) → nginx'i eler, uygulamanın loguna inerim. Tek komutla arama alanını yarıya böldüm.

3. **Hayır, iş bitmedi.** Restart belirtiyi geçici kapattı ama kök sebep duruyor — aynı arıza geri gelecek. Kök sebebi kanıtla bul (log/metrik), gerçek düzeltmeyi yap ve `teshis.md`'ye "restart neden yetmez" diye yaz. Restart bir teşhis değil, ertelemedir; bu ayrım E bloğundaki incident disiplininin temelidir.

</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Nereden başlayacağımı bilmiyorum | Belirti netleşmemiş | "Tam olarak ne yanlış?" yaz; üç-komut refleksini uygula |
| Her şey normal görünüyor | Yanlış katmana bakıyorsun | Katmanı değiştir (nginx→app→DB→OS); `df -h`/`free -h` |
| Hipotezim tutmadı | Doğal — eleme sürecinin parçası | Yeni hipotez kur, 2. adıma dön; kanıtla test et |
| Çözdüm ama geri geldi | Belirti düzeltildi, kök sebep değil | Asıl nedeni bul; restart erteleme değildir |
| Tıkandım, ilerleyemiyorum | Teşhis kası henüz gelişiyor | `hints/` sırayla: hint-1 → 2 → 3; sonra `solution.md`'de akışı çalış |

## 💼 Portfolyo çıktısı
Yazdığın `teshis.md` — bir "arıza günlüğü"nün ilk sayfası. E3'te blameless postmortem'e
evrilir; bu tür belgeler, "gerçek bir arızayı yöntemle çözdüm" diyebildiğin somut kanıtlardır.

## ⏭️ Sırada
[`C0 — Ops için Python`](../block-c-reproducibility/C0-ops-python.md)

---

> *"Bir arızayı yardımsız daraltabilmek, bu patikanın öğrettiği asıl beceridir."*
