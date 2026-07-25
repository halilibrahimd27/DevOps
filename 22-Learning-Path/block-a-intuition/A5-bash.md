---
description: "Bash — iş görecek kadar kabuk: değişken, döngü, koşul, pipe ve güvenli script yazımı."
level: A
module: A5
estimated_hours: 12
prerequisites: [A1, A4]
tags: [Learning Path, Bash]
---
# A5 — Bash: İş Görecek Kadar Kabuk

> *"Bash'i dil olarak öğrenmiyorsun; günlük işi otomatikleştirecek kadar öğreniyorsun."*

**Blok:** A — Sezgi · **Süre:** ~12 saat · **Ön koşul:** [`A1`](A1-linux-temeli.md), [`A4`](A4-git-temeli.md)

## 🎯 Bu modülü bitirdiğinde
- Argüman alan, değişken/koşul/döngü içeren ve hata durumunda **duran** (`set -euo pipefail`) bir script yazarsın.
- Komutları pipe ile zincirler, bir log dosyasını tek satırda özetlersin.
- Bir script'in nerede ve niçin patladığını `bash -n`/`bash -x`/`shellcheck` ile bulup düzeltirsin.

## 🧠 Niye bu, niye şimdi
A1'de komutları tek tek çalıştırdın. Aynı beş komutu her sabah elle yazmak ise
üçüncü günde hataya davetiyedir. Bash, o beş komutu **tek, tekrarlanabilir, isimli**
bir işe çevirir. Patikadaki her lab `setup.sh`/`verify.sh` gibi kabuk scriptleriyle
çalışır; A6'da servisleri elle ayağa kaldırırken tekrar eden işi Bash'e devredersin.
Otomasyonun en ilkel ve en her yerde bulunan biçimi budur — Terraform (C3) ve CI (C2)
gelene kadar tek otomasyon aracın.

## 📖 Nasıl çalışılır
Gövdeyi oku ve **her örneği bir dosyaya yaz, `chmod +x` ver, çalıştır.** Bash'i
kafadan değil, çalıştırıp çıktısını görerek öğren. Her script'i yazdıktan sonra
`bash -n script.sh` ile sözdizimini, takıldığında `bash -x script.sh` ile satır satır
akışını kontrol et. Bu iki komut senin gözündür.

## 📚 Kavram haritası
| Terim | Bir cümlede |
|---|---|
| **Shebang** (`#!/usr/bin/env bash`) | Dosyanın ilk satırı; onu hangi yorumlayıcının çalıştıracağını söyler |
| **Değişken** | `AD=değer` (eşittin yanında boşluk YOK); kullanımı `"$AD"` |
| **Quoting** | `"$AD"` — değişkeni tırnak içinde kullan; en sık yapılan hata tırnaksız bırakmak |
| **Exit code** | Her komutun 0–255 arası dönüş kodu; `0` = başarı, diğeri = hata (`$?`) |
| **Pipe** (`\|`) | Bir komutun çıktısını diğerinin girdisine bağlar |
| **Redirect** (`>`, `>>`, `2>`) | Çıktıyı/hatayı dosyaya yönlendirir |
| **Komut ikamesi** `$(...)` | Bir komutun çıktısını değişkene/satıra gömer |
| **`set -euo pipefail`** | Script'i ilk hatada durduran güvenlik kemeri |

---

## 1️⃣ İlk script: shebang, izin, çalıştırma

Bir script, sırayla çalıştırılacak komutların bulunduğu bir metin dosyasıdır. İlk
satırı **shebang**'dır ve onu kimin çalıştıracağını söyler:

```bash
#!/usr/bin/env bash
echo "merhaba, $(whoami)"
```

```bash
chmod +x selam.sh      # çalıştırılabilir yap (A1'deki x izni)
./selam.sh             # çalıştır
# merhaba, <KULLANICI>
```

`#!/usr/bin/env bash`, sabit bir yol (`/bin/bash`) yerine `bash`'i `PATH`'ten bulur —
farklı sistemlerde taşınabilir. `./` gerekir çünkü kabuk, bulunduğun dizini `PATH`'te
aramaz (A1'deki `PATH` konusu; güvenlik için böyle).

## 2️⃣ Değişken ve quoting — en sık yapılan hata

```bash
AD="Ali Veli"          # eşittin İKİ yanında da boşluk YOK
echo "Merhaba $AD"      # Merhaba Ali Veli
echo 'Merhaba $AD'      # Merhaba $AD  (tek tırnak: hiç genişletmez)
```

Kural: **değişkeni her zaman çift tırnak içinde kullan** — `"$AD"`. Tırnaksız
bırakırsan Bash değeri boşluklardan böler ve içindeki `*` gibi karakterleri dosya
adlarına genişletir:

```bash
DOSYA="rapor 2024.txt"
rm $DOSYA               # ❌ "rapor" ve "2024.txt" adında İKİ dosya silmeye çalışır
rm "$DOSYA"             # ✅ tek dosya, adında boşlukla
```

> 🔒 Tırnaksız değişken sadece bir "stil" hatası değil, bir **güvenlik açığı**dır. Dış
> girdiden (dosya adı, kullanıcı verisi) gelen bir değeri tırnaksız kullanmak, komut
> enjeksiyonuna kapı açar. Kural basit: **her `$` çift tırnak içinde.**

## 3️⃣ Exit code: her komutun bir cevabı var

Her komut, bittiğinde 0–255 arası bir kod döner. `0` başarı, sıfırdan farklısı
başarısızlık demektir. Bir önceki komutun kodu `$?`'de durur:

```bash
grep "hata" app.log
echo $?                # 0 → bulundu, 1 → bulunamadı, 2 → grep'in kendisi patladı
```

Exit code, script'in **karar verme** biçimidir; koşullar ve `set -e` bunun üstüne kurulur.

```bash
mkdir /tmp/deneme && cd /tmp/deneme   # && : soldaki başarılıysa sağı çalıştır
komut_a || echo "a başarısız"          # || : soldaki BAŞARISIZSA sağı çalıştır
```

## 4️⃣ Koşul: test, `[[ ]]`, if

```bash
if [[ -f "$DOSYA" ]]; then
  echo "$DOSYA var"
elif [[ -d "$DOSYA" ]]; then
  echo "$DOSYA bir dizin"
else
  echo "$DOSYA yok"
fi
```

En sık kullanılan testler:

| Test | Doğru olduğunda |
|---|---|
| `[[ -f yol ]]` | Dosya var ve normal dosya |
| `[[ -d yol ]]` | Dizin var |
| `[[ -z "$x" ]]` | `$x` boş |
| `[[ -n "$x" ]]` | `$x` dolu |
| `[[ "$a" == "$b" ]]` | Metinler eşit |
| `[[ "$a" -eq "$b" ]]` | Sayılar eşit |

> `[[ ]]` (çift köşeli, Bash'e özel) `[ ]`'ten daha güvenlidir: içinde tırnaksız
> değişken bölünmez. Yeni yazdığın her koşulda `[[ ]]` kullan.

## 5️⃣ Döngü: for, while, satır satır okuma

```bash
for svc in nginx postgresql app; do
  systemctl is-active "$svc"          # her servisin durumu (systemctl'i A6'da öğreneceksin;
done                                  # burada önemli olan `for` döngüsü kalıbı)
```

Bir dosyayı **satır satır** güvenle okumak (log işlemenin temeli):

```bash
while IFS= read -r line; do
  echo "satır: $line"
done < app.log
```

`IFS=` ve `read -r` birlikte: baştaki/sondaki boşlukları koru, `\` kaçışını bozma.
Bu kalıbı ezberle — dosya okumanın doğru yolu budur.

## 6️⃣ Fonksiyon ve argümanlar

Script'ine dışarıdan değer geçirirsin; bunlar `$1`, `$2`… olarak gelir. `$@` hepsi,
`$#` sayısıdır.

```bash
#!/usr/bin/env bash
deploy() {
  local app="$1"                       # local: değişkeni fonksiyona hapset
  local ver="$2"
  echo "deploy: ${app} sürüm ${ver}"
}

if [[ $# -lt 2 ]]; then                 # argüman sayısı kontrolü
  echo "kullanım: $0 <APP> <VERSION>" >&2   # hata mesajı stderr'e
  exit 1
fi
deploy "$1" "$2"
```

`$0` script'in kendi adı; kullanım (usage) mesajlarında ona başvur. Hata mesajını
`>&2` ile stderr'e yaz — böylece pipe'a karışmaz (A1'deki stdio ayrımı).

## 7️⃣ Güvenli script: `set -euo pipefail`

Varsayılan Bash **affedicidir** ve bu tehlikelidir: bir komut patlar, script hiçbir
şey olmamış gibi devam eder. Her ciddi script'in başına şu satırı koy:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

| Bayrak | Ne yapar | Niçin |
|---|---|---|
| `-e` | Bir komut başarısız olunca **hemen dur** | Yarım kalmış, tutarsız durumdan kaçın |
| `-u` | Tanımsız değişken kullanımını **hata say** | `rm -rf "$DIR/"` — `$DIR` boşsa felaket; `-u` onu yakalar |
| `-o pipefail` | Pipe'ın **herhangi** bir halkası patlarsa başarısız say | `cmd \| tee` — `cmd` patlasa bile normalde 0 döner; bu onu düzeltir |

`-e`'nin bir istisnası: bir komutun başarısız **olabileceğini** biliyorsan, açıkça
işaretle:

```bash
if grep -q "hata" app.log; then echo "hata var"; fi   # grep'in 1 dönmesi normal
komut_riskli || true                                    # "bu patlarsa umursama"
```

> 🔒 Sırları script'e gömme, argüman olarak da geçme. Komut satırı argümanları
> `ps aux` çıktısında **herkese görünür**. Sırrı ortam değişkeninden oku
> (`"$DB_PASSWORD"`) ya da bir dosyadan; script'in içine yazma (D3'te bunu
> derinleştireceğiz). Geçici dosyayı `mktemp` ile aç ve çıkışta temizle:

```bash
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT      # script nasıl biterse bitsin tmp'yi sil
```

## 8️⃣ Metin işleme: log'u tek satırda özetle

Pipe, küçük araçları birbirine bağlayıp güçlü bir zincir kurar. Bir erişim log'unda
en çok 404 alan ilk 5 yolu bul:

```bash
grep ' 404 ' access.log \
  | awk '{print $7}' \
  | sort | uniq -c \
  | sort -rn | head -5
#   87 /eski-sayfa
#   40 /favicon.ico
#   ...
```

Halka halka: `grep` süz → `awk` 7. alanı (yol) al → `sort | uniq -c` say →
`sort -rn` çoktan aza sırala → `head -5` ilk beş. Bu zinciri kur, her halkanın
çıktısını tek tek görerek anla. Log okumanın (B1) temeli budur.

## 9️⃣ Debug: patlayınca ne yaparsın

| Araç | Ne için |
|---|---|
| `bash -n script.sh` | Çalıştırmadan **sözdizimini** kontrol et (lab QA'sı bunu kullanır) |
| `bash -x script.sh` | Her satırı, genişlemiş değişkenleriyle **çalışırken** göster |
| `shellcheck script.sh` | Tırnaksız değişken, yanlış test gibi klasik hataları statik yakalar |

`shellcheck`'i kur ve her script'i ona sok — yazdığın hataların çoğunu sen görmeden yakalar.

---

## 🚫 Anti-pattern tablosu
| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tırnaksız değişken (`rm $x`) | Boşlukta bölünür, `*` genişler, enjeksiyona açık | Her `$` çift tırnak içinde: `"$x"` |
| `set -euo pipefail` yok | Komut patlar, script yarım durumda devam eder | Her ciddi script'in ilk satırından sonra ekle |
| Sırrı script'e gömmek / argüman geçmek | `ps`/geçmiş/git ile sızar | Ortam değişkeni veya dosyadan oku (D3) |
| `AD = değer` (eşittin yanında boşluk) | Bash bunu komut sanır, çalışmaz | `AD=değer` — boşluk yok |
| `for f in $(ls)` ile dosya gezmek | Boşluklu/özel adlarda bozulur | `for f in *.log` (glob) veya `find ... -print0 \| xargs -0` |
| `cat dosya \| grep x` | Gereksiz `cat`; bir işlem fazla | `grep x dosya` |
| Hata mesajını stdout'a yazmak | Pipe'a/veri akışına karışır | `echo "hata" >&2` (stderr) |
| `bash -x` yerine `echo` serpiştirmek | Yavaş, dağınık, unutulur | `bash -x` ile satır satır izle, `shellcheck` ile tara |
| Geçici dosyayı elle adlandırmak (`/tmp/x`) | Çakışma + çıkışta çöp kalır | `mktemp` + `trap ... EXIT` ile temizle |

## 📖 İleri okuma (şimdi değil, sonra)
> Bunlar yönlendirilmiş bir adım değil, **ihtiyaç anında** açacağın referanslardır
> (dört-alanlı dış-kaynak sözleşmesi yönlendirilmiş okuma linkleri içindir, bu tür
> tekil arama için değil). Süre: her biri 2–5 dk, tek bir soruya bakarsın.

| Kaynak | Ne için | Ne zaman açarsın |
|---|---|---|
| `man bash` / `help set` | Her davranışın resmi referansı | Bir bayrağın ne yaptığını merak ettiğinde |
| [ShellCheck wiki](https://www.shellcheck.net/wiki/) | `shellcheck`'in verdiği uyarı kodunun (ör. SC2086) açıklaması | `shellcheck` bir uyarı verdiğinde, o kodu ara |

## 🔨 Lab
👉 [`labs/build/L05-bash/`](../labs/build/L05-bash/README.md) — (Görev taslağı: iki argüman alan,
`set -euo pipefail` kullanan, bir log dosyasını özetleyip sonucu bir rapor dosyasına
yazan ve `shellcheck`'ten temiz geçen bir script.)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] En az bir argüman alan, argüman eksikse kullanım mesajı basıp `exit 1` yapan ve `bash -n` ile temiz geçen bir script yazdın.
- [ ] Bir log dosyasını **tek satırlık** pipe zinciriyle özetleyen bir komut yazdın ve çıktısını gösterdin.
- [ ] `set -euo pipefail`'in üç bayrağının her birinin niçin gerekli olduğunu, birer örnekle **yazılı** açıkladın.
- [ ] `shellcheck script.sh` bir script'inde en az bir uyarı buldu, uyarıyı düzelttin ve temiz çıktı aldın.

## 🧪 Kendini test et
1. `rm $DOSYA` ile `rm "$DOSYA"` arasındaki fark nedir? `DOSYA="a b"` iken her biri ne yapar?
2. **Senaryo:** Bir script `set -e` olmadan yazıldı; ortasındaki `cd /veri` komutu başarısız oldu ama script devam edip `rm -rf ./*` çalıştırdı. Ne oldu, `set -euo pipefail` bunu nasıl önlerdi?
3. **Tasarım:** Bir DB parolasına ihtiyaç duyan bir yedek script'i yazacaksın. Parolayı nereye koyarsın, nereye **asla** koymazsın, niçin?

<details><summary>Cevaplar</summary>

1. `rm $DOSYA` tırnaksız: Bash `"a b"` değerini boşlukta böler ve `a` ile `b` adında **iki** dosya silmeye çalışır (ve `*` gibi karakterler varsa dosya adlarına genişler). `rm "$DOSYA"` tırnaklı: değeri tek bir bütün olarak alır, adında boşluk olan **tek** dosyayı siler. Kural: her `$` çift tırnak içinde.

2. `cd /veri` başarısız oldu (dizin yok), ama script yanlış (hâlâ eski) dizinde kaldı ve `rm -rf ./*` orada çalışarak yanlış dosyaları sildi. `set -e` olsaydı `cd` patladığı anda script dururdu ve `rm` hiç çalışmazdı. `set -u` de ayrıca boş bir `$DIR` değişkenini yakalardı. İkisi birlikte bu felaket sınıfını kapatır.

3. Parolayı **ortam değişkeninden** (`"$DB_PASSWORD"`) ya da izinleri kısıtlı bir dosyadan okurum. **Asla** script'in içine sabit yazmam (git'e sızar), komut satırı argümanı olarak geçmem (`ps aux`'ta herkese görünür) ve log'a basmam. Sır yönetimini D3'te derinleştireceğiz; ilke burada başlar: sır koda girmez.

</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| `command not found: ./script.sh` | Çalıştırma izni yok veya yanlış dizin | `chmod +x script.sh`; `./` ile çalıştır |
| `AD: command not found` | `AD = değer` (boşluklu atama) | `AD=değer` — eşittin yanında boşluk yok |
| Değişken beklenmedik bölündü | Tırnaksız `$x` | Her yerde `"$x"` kullan |
| `unbound variable` | `set -u` + tanımsız değişken | Değişkeni tanımla veya `"${x:-varsayılan}"` ver |
| Pipe patladı ama script devam etti | `pipefail` yok | `set -o pipefail` ekle |
| Script yarısında sessizce durdu | `set -e` + beklenen bir hata | Beklenen başarısızlığı `\|\| true` veya `if` ile işaretle |
| Neden patladığını göremiyorum | Kör çalıştırma | `bash -x script.sh` ile satır satır izle |

## 💼 Portfolyo çıktısı
Yeniden kullanılabilir birkaç yardımcı script (özetleyici, doğrulayıcı) — A6 ve
sonrasında kendi işini otomatikleştirmenin altyapısı. Bunları A4'te öğrendiğin Git
ile bir repoda tut.

## ⏭️ Sırada
[`A6 — Elle Deploy`](A6-elle-deploy.md)

---

> *"Bir işi ikinci kez elle yapıyorsan, üçüncüsü için onu bir script'e koy."*
