---
description: "Başlamadan önce: çalışma ortamını kur, terminale alış ve bu patikanın nasıl işlediğini öğren."
level: A
module: A0
estimated_hours: 6
prerequisites: []
tags: [Learning Path, Başlangıç]
---
# A0 — Başlamadan Önce: Ortam, Terminal ve Bu Patika Nasıl İşler

> *"Bir aracı öğrenmeden önce onu tutabilmen gerekir. Bu modül eline terminali verir."*

**Blok:** A — Sezgi · **Süre:** ~6 saat · **Ön koşul:** yok (patikanın gerçek giriş noktası)

## 🎯 Bu modülü bitirdiğinde
- Kendi makinende çalışan bir Linux terminaline sahip olur, içinde komut çalıştırıp çıktısını okuyabilirsin.
- Bir komutu çalıştırır, hata verdiğinde hatayı okur ve `--help`/`man` ile kendi başına yardım bulabilirsin.
- Bu patikanın oku → yap → doğrula → geç döngüsünü ve ilerlemeni nerede işaretleyeceğini bilirsin.

## 🧠 Niye bu, niye şimdi
A1 seni doğrudan process, dosya izni ve kullanıcı modeline sokar. Ama bunu
görebilmen için önce **çalışan bir Linux'un**, **korkmadan komut yazabildiğin bir
terminalin** ve **takıldığında nereye bakacağını bilmen** gerekir. Bu modül o zemini
kurar: ortam + terminal ergonomisi + patikanın kullanım kılavuzu. Bunları A1'e
bırakırsak A1 "hiçbir ön bilgi varsaymaz" sözünü tutamaz. A0 kısadır ama atlanmaz —
çünkü sonraki her komutu buraya kurduğun makinede çalıştıracaksın.

> Ortamın zaten hazırsa (terminal açılıyor, komut çalışıyor, bir editör kullanıyorsun)
> A0 senin için bir kontrol turudur: aşağıdaki kabul kriterlerini 20 dakikada geçip
> A1'e atla. Emin değilsen atlama — [`PLACEMENT.md`](../PLACEMENT.md) bunu testle bağlar.

## 📖 Nasıl çalışılır
Bu modül **öğreticidir**; okuyup geçilecek bir metin değil. Her komutu **kendi
makinende çalıştır**, çıktıyı kendi gözünle gör. İki dosya bu modülün yanında açık
dursun:
- [`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md) → yerel Linux'u kurmanın üç yolu (WSL2 /
  Multipass / VirtualBox). Kurulum adımları orada; burada tekrar etmiyoruz.
- [`STUDY-METHOD.md`](../STUDY-METHOD.md) → okuma/yapma oranı ve dış kaynak sözleşmesi.
  Kural basit: **okuduğun her komutu çalıştırmadan sonraki bölüme geçme.**

## 📚 Kavram haritası
| Terim | Bir cümlede |
|---|---|
| **CLI** | Command-Line Interface — komutları yazarak verdiğin metin arayüzü (fare değil, klavye) |
| **Terminal** | CLI'yi gösteren pencere/uygulama (kabuğu barındıran ekran) |
| **Shell (kabuk)** | Yazdığın komutu alıp çalıştıran program (`bash`, `zsh`) |
| **Prompt** | Kabuğun "komutunu bekliyorum" işareti (`<kullanıcı>@<makine>:~$`) |
| **Komut / argüman / bayrak** | `ls -l /etc` → komut=`ls`, bayrak=`-l`, argüman=`/etc` |
| **Exit code** | Bir komutun bittiğinde bıraktığı sayı: `0` başarılı, `0 değil` hata |
| **Path (yol)** | Bir dosya/dizinin adresi: mutlak (`/etc/hosts`) ya da göreli (`../log`) |

---

## 1️⃣ DevSecOps neyin adı — patikanın şekli

Üç kelimenin birleşimi, üç ayrı işin **aynı ekipte** buluşmasıdır:

| Parça | Soru | Bu patikada |
|---|---|---|
| **Dev** (development) | Uygulama nasıl yazılır/paketlenir? | A4, A5, C1, C2 |
| **Ops** (operations) | Uygulama nasıl çalıştırılır ve ayakta tutulur? | A6, B, D, E |
| **Sec** (security) | Nasıl **baştan** güvenli kurulur? | ayrı bir blok değil — hepsine dağılmış iplik |

"Sec"in ayrı bir blok olmaması kasıtlıdır. Güvenliği sona bırakmak bu reponun
eleştirdiği en yaygın hatadır; bu yüzden güvenlik ilk günden (A1'de kullanıcı/izin,
D1'de RBAC) içeride akar. Ayrıntı: [`CURRICULUM.md`](../CURRICULUM.md) → "Güvenlik
iplik olarak içeride".

Patikanın gövdesi altı bloktur; sıralama teknolojiye göre değil **bağımlılığa** göre
kurulur — her adımın gerekçesi bir sonrakini anlamak için şart olmasıdır:

```
A Sezgi → B Görebilmek → C Tekrarlanabilirlik → D Orkestrasyon → E Sahiplik → F Karar
```

Şimdi haritayı ezberlemen gerekmiyor. Sadece **nereye gittiğini** bil:
[`README.md`](../README.md) patikanın kime, nasıl hizmet ettiğini bir sayfada anlatır.
A0'ın işi seni A1'in kapısına, elinde çalışan bir terminalle bırakmak.

## 2️⃣ Ortamını kur: dört parça

Sıfırdan başlıyorsan sana dört şey gerekir. Üçüncü ve dördüncüsü hızlıdır; asıl iş
ikinciyi kurmaktır.

| Parça | Ne için | Nereden |
|---|---|---|
| **Terminal** | Komut yazacağın pencere | Linux/macOS'ta hazır gelir; Windows'ta WSL2 ile |
| **Yerel Linux** | Patikanın çalıştığı işletim sistemi | [`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md) → 🐧 bölümü |
| **Metin editörü** | Config/script yazacaksın | `nano` (şimdilik) — aşağıda |
| **GitHub hesabı** | A4'te Git'i, C2'de CI'ı burada kullanacaksın | github.com'da ücretsiz hesap |

**Container'ı bilerek saymadık.** Docker bir Blok C kavramıdır; A bloğunda gerçek bir
işletim sistemini elle görmen gerekiyor — soyutlamanın altındaki katmanı. A6'da bir
uygulamayı **elle** (container'sız) ayağa kaldıracaksın; onun için gerçek bir Linux
kutusu şart.

Kurulumu bitirdiğinde bu iki komut çalışmalı — çalışıyorsa ortamın hazırdır:

```bash
uname -a            # çekirdek + mimari: "Linux ... x86_64" ya da "... aarch64" görmelisin
whoami              # şu an hangi kullanıcısın (root DEĞİL, normal bir kullanıcı olmalı)
```

> Apple Silicon Mac ya da ARM tabanlı bir makinedeysen `uname -m` sana `aarch64`/`arm64`
> der. Bu bir sorun değil ama ileride binary indirirken (node_exporter, kubectl…) doğru
> mimariyi seçmen gerekecek. Şimdiden not et: **hangi mimaridesin?**

## 3️⃣ Terminale alış: prompt, komut, kesme

Terminal korkutucu görünür çünkü boştur — sana ne yapacağını söylemez. Oysa dili
basittir. Bir satırı çöz:

```
halil@devbox:~$ ls -l /etc
└─┬─┘ └──┬─┘ │  └┬┘ └─┬─┘
  │      │   │   │    └ argüman: hangi dizin
  │      │   │   └───── bayrak: "uzun biçim"
  │      │   └───────── komut: ne yapılacak
  │      └───────────── makine adı
  └──────────────────── kullanıcı adı
```

Sondaki işaret kim olduğunu söyler:

| İşaret | Anlamı | Dikkat |
|---|---|---|
| `$` | Normal kullanıcısın | Günlük iş burada |
| `#` | **root**'sun (tam yetki) | Her komut geri alınamaz olabilir — iki kez düşün |

`~` senin ev dizinin (`/home/<kullanıcı>`) demektir; prompt'ta hangi dizinde
olduğunu gösterir.

### Bir komutu çalıştırmak ve "bitti"yi anlamak

Komutu yaz, **Enter**'a bas. Kabuk çalıştırır, çıktı ekrana düşer, sonra prompt geri
gelir — prompt geri geldiyse komut **bitmiştir**. Bitip bitmediğini merak ettiğinde
sorabilirsin:

```bash
ls /etc
echo $?             # az önceki komutun exit code'u: 0 = başarılı, başka sayı = hata
```

`$?` senin ilk "işe yaradı mı?" aracın. Şimdilik tek şey yeter: **`0` iyi, `0 değil`
kötü.** Neden ve nasıl kullanıldığı A5'te (Bash) derinleşecek.

### Kontrolü sende tutan tuşlar

Bir komut takılırsa ya da yanlış yazdıysan panik yok — klavye sende:

| Tuş | Ne yapar | Ne zaman |
|---|---|---|
| `Ctrl-C` | Çalışan komutu **kes** | Bir komut bitmiyor/asılı kaldı |
| `Ctrl-D` | Girdi bitti (EOF) / kabuktan çık | Bir oturumu kapatmak |
| `Ctrl-L` | Ekranı temizle (`clear` ile aynı) | Karışan ekranı toparlamak |
| `Ctrl-A` / `Ctrl-E` | Satır başına / sonuna git | Uzun komutu düzeltmek |
| `Tab` | Komut/dosya adını **tamamla** | Yazım hatasından kaçınmak |
| `↑` / `↓` | Önceki komutlarda gezin | Aynı komutu tekrar çalıştırmak |

`Tab` tamamlama ve `↑` geçmişi bir alışkanlık, iki değil: az yazarsın, az hata
yaparsın. `history` komutu tüm geçmişini döker.

### Kopyala-yapıştır: en tehlikeli alışkanlık

İnternetten komut kopyalayacaksın — bu normaldir. Ama iki tuzak var:

1. **Akıllı tırnak.** Web sayfaları `"` yerine `"` `"` gibi süslü tırnak basar; kabuk
   bunları anlamaz, komut kırılır. Şüphede tırnağı elle düz `"`/`'` yaz.
2. **Anlamadan çalıştırmak.** Bir komutu yapıştırmadan önce **ne yaptığını oku.**
   Özellikle `sudo`, `rm`, `| bash` içeren bir satırı körlemesine çalıştırmak, birinin
   makinende root olarak istediğini yapmasına izin vermektir. Kural (Bölüm 5'te
   pekişecek): **çalıştırmadan önce her parçasını `--help`/`man` ile tanı.**

## 4️⃣ Dosya sisteminde gezin: beş komutla dolaş

A1 dosya sistemine derinlemesine iner (izinler, inode, disk alanı). A0'ın işi daha
mütevazı: **kaybolmadan dolaşabilmek.** Beş komut yeter.

```bash
pwd                 # "print working directory" — şu an neredeyim?
ls                  # bu dizinde ne var
cd /etc             # bir dizine git (change directory)
cd ..               # bir üst dizine çık
cat /etc/hostname   # kısa bir dosyanın içeriğini ekrana bas
less /etc/services  # uzun bir dosyayı sayfa sayfa oku — q ile çık, / ile içinde ara
```

Yolları okumanın kuralı:

| Yazım | Neresi |
|---|---|
| `/etc/hosts` | **Mutlak** yol — kökten (`/`) tam adres |
| `log/app.log` | **Göreli** yol — bulunduğun dizine göre |
| `~` | Ev dizinin (`/home/<kullanıcı>`) |
| `.` | Bu dizin |
| `..` | Bir üst dizin |
| `cd -` | Bir önce bulunduğun dizine dön |

> "Kayboldum" diye bir şey yok: `pwd` her zaman nerede olduğunu söyler, `cd ~` seni
> eve döndürür. Bir dizin ağacını görsel görmek istersen `tree` (kurulu değilse
> `sudo apt install tree`) işini görür.

## 5️⃣ Yardım al: kimse ezberlemez

Kıdemli mühendisler komut ezberlemez; **hızlı yardım bulur.** Üç kapı:

```bash
ls --help           # hızlı özet: bayrakların listesi, tek ekran
man ls              # tam kılavuz: her şeyiyle — / ile ara, q ile çık
type ls             # bu komut nedir/nerede (kabuk builtin'i mi, program mı)
```

`--help` "hatırlatma", `man` "resmi ve tam referans"tır. Bir bayrağın ne yaptığını
merak ettiğinde önce `--help`, yetmezse `man`. `man` bir dış link değil, sisteminin
içindedir — internet olmadan da oradadır.

### Bir hata mesajını okumak

Yeni başlayanın en pahalı alışkanlığı hatayı okumadan tekrar denemektir. Oysa hata
mesajı çoğu zaman **çözümün kendisidir**:

```bash
$ cat /etc/shadow
cat: /etc/shadow: Permission denied      # ← son satır sana tam olarak ne olduğunu söyler
```

Kural: **son satırı oku.** Anlamadığın kısmı (buradaki `Permission denied`) aynen
arat. Bu, A1'de bir izin bit'i, D1'de bir RBAC `forbidden` olarak geri gelecek —
hepsinin ortak dili "sistem sana ne söyledi?"dir.

Takıldığında yalnız değilsin: her modülde bir `🆘 Takıldıysan` tablosu, patika genelinde
[`TROUBLESHOOTING.md`](../TROUBLESHOOTING.md) var. Dış aramaya ne zaman/nasıl gidileceği
[`STUDY-METHOD.md`](../STUDY-METHOD.md)'de yazılı — rastgele değil, sözleşmeyle.

## 6️⃣ Bir dosyayı düzenle: `nano`

A6'da bir `systemd` unit'i, bir nginx config'i, bir `.env` dosyası yazacaksın. Bunun
için bir editöre ihtiyacın var. `vim` ve `emacs` güçlüdür ama şimdi öğrenme eğrisi
engel olur — bu yüzden **`nano`** ile başla:

```bash
nano notlar.txt     # dosyayı aç (yoksa oluşturur)
# ... yaz ...
# Ctrl-O  → kaydet (dosya adını sorar, Enter ile onayla)
# Ctrl-X  → çık
```

`nano`'nun alt satırında komutlar zaten yazılıdır (`^O` = `Ctrl-O`). Ezber yok. Sonra
merak edersen `vim`e geçersin; şimdilik amaç editörün engel değil araç olması.

## 7️⃣ Bu patika nasıl işlenir

Bu bir okuma listesi değil, müfredattır. Her modül aynı döngüyü izler:

```
oku → yap (lab / komut) → doğrula (kabul kriteri) → geçtiysen sonraki modül / geçemediysen dön
```

Dört alışkanlık, patikayı işe yarar kılar:

1. **Kabul kriterini geçmeden sonraki modüle geçme.** "Anladım" bir kriter değildir;
   kriter bir komutun çıktısı ya da yazdığın bir cümledir.
2. **İlerlemeni işaretle.** [`PROGRESS-TEMPLATE.md`](../PROGRESS-TEMPLATE.md)'yi kendine
   kopyala; her modülü bitirdiğinde işaretle. Nerede kaldığını bu dosya söyler.
3. **Nereden başlayacağını testle belirle.** Sıfırdan başlıyorsan buradan (A0→A1).
   Zaten Linux/kod biliyorsan [`PLACEMENT.md`](../PLACEMENT.md) bir bloğu **atlamanı**
   sağlar — ama "biliyorum" ile değil, kontrol testiyle.
4. **Her blok bir sınavla kapanır.** Blok sonundaki `STAGE-EXAM.md` (blok klasöründe)
   geçiş kapısıdır: komut çalışır, çıktı doğru, gerekçe yazılı.

Ve değişmez kural: **her lab önce yerelde, para harcamadan çalışır.** Buluta ancak
Blok C'den sonra ve zorunlu bütçe alarmıyla dokunursun — [`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md).

---

## 🚫 Anti-pattern tablosu
| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| İnternetten komutu anlamadan yapıştırmak | `sudo`/`rm`/`\| bash` makinende geri alınamaz zarar verebilir | Çalıştırmadan önce her parçayı `--help`/`man` ile tanı |
| Günlük işi root (`#`) prompt'unda yapmak | Tek yanlış komut tüm sistemi vurur | Normal kullanıcı (`$`), gerektiğinde tekil `sudo` |
| Hata mesajını okumadan tekrar denemek | Hata çoğu zaman çözümün kendisidir | Son satırı oku, anlamadığın kısmı aynen arat |
| Komutları ezberlemeye çalışmak | İnsan hafızası değil, `man`/`--help` içindir | Hızlı yardım bulmayı alışkanlık yap |
| Her karakteri elle yazmak | Yazım hatası + zaman kaybı | `Tab` tamamlama + `↑` geçmiş |
| `vim`i "gerçek editör" diye zorla öğrenmek | Öğrenme eğrisi asıl işi engeller | `nano` ile başla, `vim`i sonraya bırak |
| Ortam hazır olmadan A1'e atlamak | Komutları çalıştıracak yerin yok, her adım takılır | Önce `uname -a`/`whoami` çalışsın, sonra A1 |
| Süslü/akıllı tırnakla komut çalıştırmak | Kabuk `"` `"`'yi tanımaz, komut kırılır | Düz `"`/`'` kullan, şüphede elle yaz |

## ✅ Kabul kriterleri
Hepsi doğrulanmadan A1'e geçme:
- [ ] Kendi makinende bir Linux terminali açtın; `uname -a` ve `whoami` çıktılarını `report.txt`'e (veya ilerleme dosyana) yapıştırdın. `whoami` root değil, normal bir kullanıcı gösteriyor.
- [ ] `pwd`, `ls`, `cd <dizin>`, `cd ..` ile en az iki dizin arasında gezindin; `cat` (veya `less`) ile bir dosyanın içeriğini okudun ve `less`'ten `q` ile çıktın.
- [ ] `nano` (veya bir editör) ile bir dosya oluşturup içine bir satır yazıp kaydettin; `cat <dosya>` ile içeriğin doğru olduğunu gösterdin.
- [ ] `ls --help` ile `man ls`'i açtın (`man`'den `q` ile çıktın) ve ikisi arasındaki farkı bir cümleyle **yazdın**.
- [ ] `PROGRESS-TEMPLATE.md`'yi kendine kopyaladın ve A0'ı tamamlandı olarak işaretledin.

## 🧪 Kendini test et
1. Prompt sonunda `$` yerine `#` görüyorsun. Bu ne demek ve neden daha dikkatli olmalısın?
2. **Senaryo:** Bir komut çalıştırdın, terminal `command not found` dedi. Dokümana bakmadan ilk iki kontrolün ne olur?
3. **Tasarım:** İnternette bir kurulum sayfası sana tek satırda `curl <URL> | sudo bash` çalıştırmanı söylüyor. Çalıştırmadan önce ne yaparsın, niçin?

<details><summary>Cevaplar</summary>

1. `#` prompt'u **root** (tam yetkili kullanıcı) olduğunu gösterir; `$` normal kullanıcıdır. Root her izin sınırını aşar, bu yüzden yanlış bir komut (silme, üzerine yazma) geri alınamaz zarar verebilir. Günlük işi `$`'ta yap, yalnız gerektiğinde tekil `sudo` ile yüksel — ele geçirilmiş/yanlış bir komutun etki alanını böyle daraltırsın.

2. **(a)** Yazımı kontrol et — çoğu "command not found" bir harf hatasıdır; `Tab` ile tamamlamayı dene. **(b)** Komut gerçekten kurulu mu: `type <komut>` / `which <komut>` boş dönüyorsa program yüklü değildir → paket yöneticisiyle kur (`sudo apt install <paket>`). `PATH`'in ne olduğu ve neden komutun "bulunamadığı" A1'de derinleşir.

3. Körlemesine **çalıştırmam.** `| sudo bash` demek "bu URL'nin döndürdüğü ne olursa olsun root olarak çalıştır" demektir — kaynağa tam güven ister. Önce `curl <URL>` çıktısını (`| bash` olmadan) bir dosyaya/ekrana alıp **okurum**; ne yaptığını `--help`/`man` ile satır satır anlarım; kaynağın güvenilirliğinden emin olurum. Ancak o zaman çalıştırırım. Bu, patikanın "anlamadan çalıştırma" kuralının ilk uygulamasıdır.

</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Terminal/WSL2 hiç açılmıyor | Yerel Linux kurulmadı | [`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md) → 🐧 "Yerel Linux'u ayağa kaldır" |
| `command not found` | Komut yüklü değil ya da yanlış yazıldı | `type <komut>`; yoksa `sudo apt install <paket>` |
| `man` açıldı, çıkamıyorum | `man`/`less` sayfa görüntüleyicide | `q` tuşu (quit) |
| `nano`'dan çıkamıyorum | Kaydetme/çıkış tuşu bilinmiyor | `Ctrl-X`; kaydet sorusuna `Y`, dosya adına `Enter` |
| Kopyaladığım komut hep hata veriyor | Süslü (akıllı) tırnak | Tırnağı düz `"`/`'` olarak elle yaz |
| Komut asılı kaldı, prompt gelmiyor | Komut bitmiyor / girdi bekliyor | `Ctrl-C` (kes) ya da `Ctrl-D` (girdi bitti) |

## 💼 Portfolyo çıktısı
Doğrudan portfolyo çıktısı yok; bu bir temel yetkinliktir. Ama kurduğun ortam
**sonraki her lab'ın ön koşuludur** — A1'den F5'e kadar her komutu burada çalıştıracaksın.

## ⏭️ Sırada
[`A1 — Linux Temeli: Process, Filesystem, İzin, Kullanıcı/Grup`](A1-linux-temeli.md)

---

> *"Terminal boş bir ekran değil; sistemle konuştuğun ilk dildir. Bu modül o dilin alfabesidir."*
