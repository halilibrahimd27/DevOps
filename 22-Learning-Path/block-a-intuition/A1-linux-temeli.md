---
description: "Linux temeli: process, filesystem, izin ve kullanıcı/grup — her şeyin üstünde durduğu zemin."
level: A
module: A1
estimated_hours: 16
prerequisites: [A0]
tags: [Learning Path, Linux]
---
# A1 — Linux Temeli: Process, Filesystem, İzin, Kullanıcı/Grup

> *"Bir mühendisin altındaki her soyutlama eninde sonunda bir Linux process'ine iner."*

**Blok:** A — Sezgi · **Süre:** ~16 saat · **Ön koşul:** [`A0`](A0-baslamadan-once.md) (çalışan bir terminal)

## 🎯 Bu modülü bitirdiğinde
- Çalışan bir process'i bulur, kaynağını (CPU/bellek/açık dosya) inceler ve durdurabilirsin.
- Bir dosyanın izin/sahiplik dizisini okur, `chmod`/`chown` ile güvenli biçimde düzeltirsin.
- Kullanıcı, grup ve `sudo` arasındaki sınırı bir güvenlik sınırı olarak açıklayabilirsin.

## 🧠 Niye bu, niye şimdi
Sonraki her modül (ağ, deploy, container, K8s) bir Linux kutusunun içinde çalışır.
Process, dosya ve izin modelini görmeden hiçbir arızayı okuyamazsın. Bir container
bir process'tir; bir `Permission denied` bir izin bit'idir; bir "disk dolu" bir
inode ya da blok sayımıdır. Bu yüzden patika buradan başlar ve hiçbir ön bilgi
varsaymaz — komutu ezberlemeni değil, **sistemin sana ne söylediğini duymanı** ister.

## 📖 Nasıl çalışılır
Bu modülün gövdesi reponun **öğretici** içeriğidir; bir link listesi değil. Her bölümü
oku, komutu **kendi makinende çalıştır**, çıktıyı kendi gözünle gör. Yerel bir Linux'a
ihtiyacın var: fiziksel makine, WSL2 (Windows üstünde gerçek Linux çekirdeği çalıştıran
katman) ya da bir sanal makine (VirtualBox + Ubuntu Server). Kurulum yolu
[`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md)'de. (Container'ı bilerek saymadık — o bir
Blok C kavramı; A1'de gerçek bir işletim sistemini elle görmen gerekiyor.)
Okuma/yapma oranı için [`STUDY-METHOD.md`](../STUDY-METHOD.md)'ye bak — kural basit:
**okuduğun her komutu çalıştırmadan sonraki bölüme geçme.**

## 📚 Kavram haritası
| Terim | Bir cümlede |
|---|---|
| **Process** | Çekirdeğin çalıştırdığı, bir PID'si olan program örneği |
| **PID / PPID** | Process'in kimliği / onu başlatan üst process'in kimliği |
| **Signal** | Çekirdeğin bir process'e gönderdiği kesme (`TERM`, `KILL`, `HUP`) |
| **Inode** | Bir dosyanın metadata'sını (izin, sahip, boyut) tutan kayıt; isim değil |
| **Mode bits** | Bir dosyanın `rwx` izin dizisi (okuma/yazma/çalıştırma) |
| **UID / GID** | Kullanıcı kimliği / grup kimliği — izinlerin dayandığı sayılar |
| **`sudo`** | Başka bir kullanıcının (genelde `root`) yetkisiyle tek komut çalıştırma |

---

## 1️⃣ Zihinsel model: her şey process ve dosya

Linux'ta çalışan bir sistemi iki soruyla anlarsın: **hangi process'ler çalışıyor** ve
**hangi dosyalara dokunuyorlar**. Neredeyse her "çalışmıyor" bu ikisinden birine iner:
process ölmüştür/başlamamıştır ya da bir dosyaya (config, port, soket, log) erişemez.

Unix felsefesinin kalbi şudur: **çoğu kaynak bir dosya gibi görünür.** Bir disk
(`/dev/sda`), bir ağ soketi, hatta çalışan bir process'in kendi bilgisi (`/proc/<PID>/`)
dosya sistemi üzerinden okunur. Bu yüzden "dosya izinlerini" öğrenmek aslında "sisteme
erişimi" öğrenmektir.

```bash
# Şu an oturumunu taşıyan process zincirini gör
ps -o pid,ppid,user,comm --forest
# pid  ppid user comm
# 1811 1810 halil bash      ← senin kabuğun
# 1899 1811 halil   \_ ps   ← ps, kabuğun çocuğu
```

Her process'in bir **anası** (PPID) vardır. Zincirin tepesinde PID 1 (`systemd` ya da
`init`) durur — sistemdeki her şeyin atası. A6'da bir servisi `systemd` altına
koyduğunda, onu tam da bu ağacın kalıcı bir dalı yapıyor olacaksın.

## 2️⃣ Process: bulmak, incelemek, durdurmak

### Çalışanı görmek

```bash
ps aux                      # tüm process'lerin anlık listesi (kullanıcı, %CPU, %MEM, komut)
ps aux | grep -i nginx      # bir isme göre daralt
pgrep -a nginx              # aynı iş, doğrudan: PID + komut satırı
top                         # canlı, sürekli tazelenen tablo (q ile çık)
htop                        # top'un okunabilir hâli (kurulu değilse: sudo apt install htop)
```

`top` içinde `%CPU` ve `%MEM` sütunlarını izle; `P` ile CPU'ya, `M` ile belleğe göre
sırala. "Makine yavaş" dendiğinde ilk bakılan yer burasıdır: **hangi process kaynağı
yiyor?**

### Bir process'in içine bakmak

Her process `/proc/<PID>/` altında kendini gösterir:

```bash
PID=$(pgrep -n nginx)               # en son başlayan nginx'in PID'i
cat /proc/$PID/cmdline | tr '\0' ' '  # hangi tam komutla başlatıldı
ls -l /proc/$PID/cwd                 # hangi dizinde çalışıyor
ls -l /proc/$PID/fd                  # açık dosya tanıtıcıları (log, soket, DB bağlantısı)
```

Açık dosyaları göstermenin standart yolu `lsof`:

```bash
sudo lsof -p $PID           # bu process hangi dosyaları/soketleri açık tutuyor
sudo lsof -i :8080          # 8080 portunu KİM dinliyor (A2'de tekrar göreceğiz)
```

> Bir dosyayı `rm` ile sildin ama disk boşalmadı mı? Bir process onu hâlâ açık
> tutuyordur. `lsof | grep deleted` bunu ortaya çıkarır. "Sildim ama gitmedi"nin
> klasik sebebi budur.

### Durdurmak — sinyal göndermek

`kill` aslında "öldür" değil, "sinyal gönder" demektir. Doğru sinyali seçmek önemlidir:

```bash
kill -TERM $PID     # kibar: "işini bitir ve kapan" (varsayılan) — SIGTERM
kill -HUP  $PID     # "config'ini yeniden oku" (çoğu servis destekler) — SIGHUP
kill -KILL $PID     # zorla: çekirdek process'i anında yok eder — SIGKILL (-9)
```

| Sinyal | Ne yapar | Ne zaman |
|---|---|---|
| `TERM` (15) | Nazik kapatma; process temizlik yapabilir | **Varsayılan seçimin bu olsun** |
| `HUP` (1) | Config reload (nginx ve çoğu _daemon_ — arka planda sürekli çalışan servis) | Yeniden başlatmadan ayar yenilemek |
| `KILL` (9) | Anında sonlandırma; temizlik YOK | Yalnız `TERM`'e cevap vermeyince |

> 🚫 `kill -9`'u refleks yapma. `KILL` process'e "kapan" deme şansı bile tanımaz:
> yarım yazılmış dosyalar, bırakılmamış kilitler, bozulmuş durum kalabilir. Önce
> `TERM`, cevap yoksa `KILL`.

## 3️⃣ Filesystem: yol, inode, alan

### Yolu okumak

Linux'ta tek bir ağaç vardır, kökü `/`. Windows'taki gibi `C:`/`D:` yoktur; diskler
bu ağacın bir noktasına **bağlanır** (mount). Standart yerleşim (FHS):

| Yol | Ne var |
|---|---|
| `/etc` | Sistem geneli config (metin dosyaları) |
| `/var/log` | Loglar (B1'de burayı çok kurcalayacaksın) |
| `/home/<KULLANICI>` | Kullanıcı dosyaları |
| `/usr/bin`, `/bin` | Çalıştırılabilir programlar |
| `/tmp` | Geçici; yeniden başlatmada silinebilir |
| `/proc`, `/sys` | Çekirdeğin canlı hâli (gerçek dosya değil) |

```bash
pwd                 # neredeyim (print working directory)
ls -la              # bu dizinde ne var — gizli (.) dosyalar dahil, uzun biçim
find /etc -name "*.conf" -type f 2>/dev/null   # isimle dosya ara, hataları yut
find /var/log -mmin -10                         # son 10 dakikada değişen dosyalar
```

### Alan: "disk dolu" iki farklı şeydir

```bash
df -h               # dosya sistemlerinin doluluğu (blok bazında) — human readable
df -i               # inode doluluğu — DOSYA SAYISI bazında
du -sh /var/log/*   # hangi alt dizin ne kadar yer kaplıyor
```

`df -h` %100 gösteriyorsa disk blokları dolmuştur. Ama `df -h` bol yer gösterip sistem
yine de "no space left" diyorsa, **inode'lar** bitmiştir: çok sayıda küçük dosya (örn.
milyonlarca session dosyası) blok değil, inode tüketir. Bu ayrımı bilmek B3'teki kırık
lab'da işine yarayacak.

```bash
# En çok yer kaplayan ilk 10 şeyi bul (klasik "disk neden doldu" avı)
sudo du -x -h / 2>/dev/null | sort -rh | head -10
```

## 4️⃣ İzin modeli: rwx, octal, sahiplik

`ls -l` çıktısının ilk sütunu bir dosya hakkındaki her şeyi söyler:

```
-rw-r--r--  1 halil  developers  1240  ...  app.conf
│└┬┘└┬┘└┬┘    └─┬─┘  └────┬────┘
│ │   │  └ diğerleri (other): r--   → sahip ve grup dışı herkes
│ │   └── grup (group):       r--   → developers grubu
│ └────── sahip (user):       rw-   → halil
└──────── tür: - dosya, d dizin, l sembolik link
```

Üç izin, üç kitle için: **sahip / grup / diğerleri**. Her biri `r` (oku), `w` (yaz),
`x` (çalıştır — dizinde "içine gir"). Octal karşılığı: `r=4, w=2, x=1`, toplanır.

| Sembolik | Octal | Anlamı |
|---|---|---|
| `rwx` | 7 | oku + yaz + çalıştır |
| `rw-` | 6 | oku + yaz |
| `r--` | 4 | yalnız oku |
| `rw-r--r--` | 644 | sahip yazar, herkes okur (tipik config) |
| `rw-r-----` | 640 | sahip yazar, grup okur, diğerleri hiç (sır dosyası) |
| `rwx------` | 700 | yalnız sahip her şeyi yapar (özel dizin) |

```bash
chmod 640 app.conf          # octal ile: rw-r-----
chmod g+r,o-rwx app.conf    # sembolik ile: aynı sonuç, adım adım
stat app.conf               # izni, sahibi, zaman damgalarını tam gösterir
```

### Sahiplik

```bash
chown halil:developers app.conf   # sahip=halil, grup=developers
chown :developers app.conf        # yalnız grubu değiştir
sudo chown -R app:app /srv/app    # bir dizin ağacını baştan aşağı bir servise ver
```

> 🚫 **`chmod 777` bir çözüm değil, bir teslim bayrağıdır.** "Permission denied"
> görünce `777` vermek arızayı gizler, sebebini bulmaz: dosyayı herkese açık yazılır
> yapar, güvenlik sınırını yok eder. Doğrusu: **hangi kullanıcı erişmeye çalışıyor,
> hangi bit eksik** — onu bul, yalnız onu ver.

### `umask`: yeni dosyalar hangi izinle doğar

```bash
umask               # örn. 0022 → yeni dosyalar 644, yeni dizinler 755 doğar
```

`umask` "izin ekleme" değil, "izin kırpma" maskesidir: `666`'dan (dosya tavanı) maskeyi
düşürür. `0022` maskesi grup/diğerleri için `w`'yi kırpar. Bir servisin dosyaları neden
hep dünyaya-okunur doğuyor sorusunun cevabı çoğu zaman buradadır.

## 5️⃣ Kullanıcı, grup ve `sudo`: güvenlik sınırı

### Kimim, neye üyeyim

```bash
id                  # uid, gid ve üye olduğun tüm gruplar
whoami              # yalnız kullanıcı adı
groups              # yalnız grup üyeliklerin
getent passwd halil # kullanıcının kaydı (kabuk, home dizini, UID)
```

Kullanıcılar `/etc/passwd`, gruplar `/etc/group`, parola hash'leri `/etc/shadow`
(yalnız root okur) içinde. Bir servis kullanıcısı (örn. `www-data`, `postgres`)
genelde **login yapamayan**, yalnız kendi işini gören bir kullanıcıdır — A6'da bunu
bizzat kuracaksın.

### `su` vs `sudo`: neden `sudo` kazandı

```bash
su -                # başka kullanıcıya (varsayılan root) tam geç — onun parolası gerekir
sudo <komut>        # TEK komutu root olarak çalıştır — KENDİ parolan + sudoers izni
sudo -u postgres psql   # root değil, belirli bir kullanıcı olarak çalıştır
```

`sudo` üç sebeple standarttır: (1) root parolasını paylaşmazsın, (2) her `sudo` çağrısı
**loglanır** (`/var/log/auth.log`) — kim, ne zaman, hangi komutu, (3) yetkiyi komut
düzeyinde daraltabilirsin. Kimin neyi `sudo` ile çalıştırabileceği `/etc/sudoers`
(ve `visudo`) ile yönetilir.

> Bu, patikadaki ilk **güvenlik sınırıdır** ve iplik burada başlar: bir kullanıcının
> yapabildiği = kimliği (UID) + üyelikleri (GID) + `sudo` yetkisi. D1'de bunun
> Kubernetes karşılığını (RBAC: kim, hangi kaynakta, ne yapabilir) göreceksin — aynı
> soru, farklı sistem. "En az yetki" (least privilege) ilkesi burada, tek makinede
> başlar.

### Neden root'tan kaçınırız

Root her sınırı aşar; bir hata ya da ele geçirilmiş bir process root ise **her şeyi**
yapabilir. Bu yüzden: günlük iş normal kullanıcıyla, yükseltme gerektiğinde tekil
`sudo` ile. Servisler `root` değil, kendi sınırlı kullanıcılarıyla çalışır. Bu alışkanlık
container (D bloğu) dünyasında "root çalıştırma" anti-pattern'i olarak geri gelecek.

## 6️⃣ Girdi/çıktı, yönlendirme ve ortam

Her process üç standart akışla doğar: **stdin** (0, girdi), **stdout** (1, normal çıktı),
**stderr** (2, hata çıktısı). Bunları yönlendirebilmek, "çıktıyı bir dosyaya al", "hatayı
ayır", "iki komutu birbirine bağla" demenin yoludur — ve teşhis için vazgeçilmezdir.

```bash
komut > out.txt         # stdout'u dosyaya yaz (üzerine)
komut >> out.txt        # stdout'u dosyaya EKLE (sonuna)
komut 2> err.txt        # yalnız stderr'i dosyaya
komut > out.txt 2>&1    # stdout + stderr'i aynı dosyaya
komut 2>/dev/null       # hataları at (sessizle) — dikkatli kullan
komutA | komutB         # A'nın stdout'unu B'nin stdin'ine bağla (pipe)
```

> `2>&1` sırası önemlidir: "stderr'i, stdout'un **o an gittiği yere** yönlendir".
> `> out.txt 2>&1` doğru; `2>&1 > out.txt` stderr'i eski yerde bırakır. Bir komutun
> hatasını göremiyorsan, çoğu zaman stderr'i yanlış yönlendirmişsindir.

Pipe (`|`) Unix'in kalbidir: küçük araçları zincirleyip büyük iş yaparsın. A5'te bunun
üstüne script kuracaksın; şimdilik zinciri gör:

```bash
ps aux | grep nginx | grep -v grep | awk '{print $2}'   # nginx PID'lerini süz
journalctl -u <SERVİS> | grep -i error | tail -20        # son 20 hata satırı (B1'de derinleşir)
```

### Ortam değişkenleri ve `PATH`

Her process bir **ortam** (environment) taşır: `KEY=VALUE` çiftleri. En kritiği `PATH` —
kabuk bir komutu hangi dizinlerde arayacağını buradan bilir:

```bash
echo "$PATH"            # komutların arandığı dizinler (: ile ayrık)
which <komut>           # bir komut PATH'te nerede bulunuyor
export APP_ENV=prod     # bu kabuk (ve çocukları) için bir değişken tanımla
env | sort              # tüm ortam değişkenleri
```

"command not found" hatasının sık sebebi, komutun `PATH`'te olmamasıdır (özellikle
`sudo` altında `PATH` farklı olabilir). Sırları (parola, token) ortam değişkenine koymak
yaygındır ama dikkat: `env` çıktısı ve `/proc/<PID>/environ` onları sızdırabilir — sır
yönetimi D3'ün konusu.

---

## 🚫 Anti-pattern tablosu
| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| `kill -9` refleksi | Temizlik yapılmadan ölür; bozuk durum/kilit kalır | Önce `TERM`, yanıt yoksa `KILL` |
| `chmod 777` ile "çözmek" | İzin sınırını yok eder, arızayı gizler | Eksik biti bul, yalnız onu ver (`640`/`750`) |
| Her işi root ile yapmak | Tek hata tüm sistemi vurur | Normal kullanıcı + tekil `sudo` |
| `df -h`'a bakıp inode'u unutmak | "Yer var ama yazamıyorum"u açıklayamazsın | Blok için `df -h`, dosya sayısı için `df -i` |
| Servisi root kullanıcısıyla koşturmak | Ele geçirilirse yetki sınırsız | Servise özel, login'siz kullanıcı |
| `ps aux | grep x` sonucunu körlemesine `kill`'lemek | Yanlış PID'i (hatta `grep`'i) öldürebilirsin | `pgrep`/`pkill` ya da PID'i doğrula |
| Parolayı `/etc/passwd`'de aramak | Hash'ler `/etc/shadow`'da, `passwd` sadece meta | Doğru dosyayı bil; sırrı loglama/kopyalama |
| Sembolik linki gerçek dosya sanmak | Yanlış hedefi düzenler/silersin | `ls -l` ile `->` hedefini gör |

## 📖 İleri okuma (şimdi değil, sonra)
| Kaynak | Ne için | Ne zaman |
|---|---|---|
| [`16-Cheatsheets/linux-troubleshooting.md`](../../16-Cheatsheets/linux-troubleshooting.md) | USE method + sistematik arıza daraltma | **B3'ten sonra** — şimdi erken |
| `man <komut>` (örn. `man ps`, `man chmod`) | Her komutun resmi, tam referansı | Bir bayrağı merak ettiğinde |

> Not: `man` sayfaları sistemindedir, dış link değildir. Bir komutu ezberlemek yerine
> `man` içinde `/` ile aratmayı alışkanlık edin — bu tek başına bir beceridir.

## 🔨 Lab
👉 [`labs/build/L01-linux-temeli/`](../labs/build/L01-linux-temeli/README.md) — (Görev taslağı: verilen bir
process'i bul-incele-durdur; bir dizin ağacının izinlerini `750`/`640` düzenine çek;
bir servis kullanıcısı yarat.)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] Bir process'i isimle bulup PID'ini, çalışma dizinini ve **en az bir açık dosyasını** gösteren komut dizisini çalıştırdın (`pgrep` → `/proc/<PID>/` veya `lsof -p`) ve bu üç değeri `report.txt`'e yazdın.
- [ ] Bir dosyanın iznini `chmod 640`'a çekip `stat` (veya `ls -l`) ile doğruladın; sahibini `chown` ile değiştirip gösterdin.
- [ ] `df -h` ile `df -i` çıktılarını yan yana koyup "disk dolu"nun iki farklı anlamını **yazılı** açıkladın.
- [ ] Kullanıcı vs grup vs `sudo` sınırını, "en az yetki" ilkesine bağlayarak kendi cümlelerinle **yazdın** (3-5 cümle).

## 🧪 Kendini test et
1. `ls -l` çıktısında `-rw-r-----` gördün. Bunu octal olarak yaz ve üç kitleden (sahip/grup/diğerleri) her birinin ne yapabildiğini söyle.
2. **Senaryo:** Bir servis "adres zaten kullanımda / port dolu" diyerek başlamıyor. Dokümana bakmadan ilk üç komutun ne olur?
3. **Tasarım:** Bir web sunucusu yalnız `/srv/app/config.yml`'i okuyabilmeli ama değiştirememeli; loglarını `/var/log/app/` altına yazabilmeli. Kullanıcı, grup ve izinleri nasıl kurarsın, niçin?

<details><summary>Cevaplar</summary>

1. **`640`.** Sahip: oku+yaz (`rw-`). Grup: yalnız oku (`r--`). Diğerleri: hiçbir şey (`---`). Tipik bir "grup içi paylaşılan, dünyaya kapalı" config/sır dosyası düzeni.

2. Sırayla daralt: **(a)** portu kim tutuyor — `sudo lsof -i :<PORT>` ya da `sudo ss -ltnp | grep :<PORT>`; **(b)** o process nedir/kimin — çıkan PID'i `ps -p <PID> -o pid,user,comm`; **(c)** servisin kendi logu ne diyor — `journalctl -u <SERVİS> -n 50` (B1'de derinleşecek). Tahmin değil, kanıt: hangi process portu tutuyor, onu gör.

3. Servise özel, login'siz bir kullanıcı+grup aç (örn. `appuser:appgroup`). `config.yml`'i `chown root:appgroup` + `chmod 640` yap → servis grup üzerinden **okur**, yazamaz. Log dizinini `chown appuser:appgroup /var/log/app` + `chmod 750` yap → servis kendi loguna yazar. Böylece servis config'i değiştiremez (ele geçirilse bile ayarı bozamaz) ama işini görür — **en az yetki**.

</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| `Permission denied` | Eksik `r`/`w`/`x` biti ya da yanlış sahiplik | `ls -l` ile bitleri oku, `id` ile kimliğini gör; `777` verme, eksik biti ver |
| `kill` "No such process" | PID değişti / process zaten öldü / yanlış PID | `pgrep -a <isim>` ile güncel PID'i al |
| `sudo: command not found` | `PATH` `sudo` altında farklı | Tam yol ver (`sudo /usr/sbin/<komut>`) ya da `sudo -i` |
| "No space left" ama `df -h` boş | İnode'lar tükendi | `df -i`; çok sayıda küçük dosya bırakan dizini bul |
| Sildim, disk boşalmadı | Bir process dosyayı açık tutuyor | `lsof | grep deleted` → process'i yeniden başlat |
| `chown: invalid user` | Kullanıcı/grup yok | `getent passwd <ad>` / `getent group <ad>` ile var mı bak |

## 💼 Portfolyo çıktısı
Doğrudan portfolyo çıktısı yok; temel yetkinlik. Kanıt, sonraki blokların çıktılarında
(A6 elle deploy, B3 kırık lab teşhis akışı) görünür.

## ⏭️ Sırada
[`A2 — Ağ I: TCP/IP, Port, Routing`](A2-ag-tcp-ip.md)

---

> *"Linux'u bilmek araç ezberlemek değil; sistemin sana ne söylediğini duyabilmektir."*
