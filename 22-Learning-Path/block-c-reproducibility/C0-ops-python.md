---
description: "Ops için Python: bir otomasyon betiği, API çağrısı ve veri işleme yazacak kadar — dil öğretmek değil, iş görmek."
level: C
module: C0
estimated_hours: 30
prerequisites: [A5]
tags: [Learning Path, Python]
---
# C0 — Ops için Python

> *"Bash bir satırı, Python bir aracı yazdırır. İkisinin sınırını bilmek ops mühendisliğidir."*

**Blok:** C — Tekrarlanabilirlik · **Süre:** ~30 saat · **Ön koşul:** [`A5`](../block-a-intuition/A5-bash.md)

## 🎯 Bu modülü bitirdiğinde
- Argüman alan, hatayı düzgün ele alan ve okunabilir bir CLI aracı yazarsın.
- Bir HTTP API'ye istek atar, dönen JSON'ı işleyip bir çıktı üretirsin.
- Bir işin Bash'te mi Python'da mı yazılacağına gerekçeyle karar verirsin.

## 🧠 Niye bu, niye şimdi
A5'te Bash'in nerede tıkandığını gördün (karmaşık veri, JSON, API). C2'deki CI
adımları ve sonraki otomasyon işleri çoğu zaman bir Python betiğine dayanır. Bu
yüzden C0, A5 ile C2 arasında bir köprüdür.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`A5 — Bash`](../block-a-intuition/A5-bash.md) | Bash nerede tıkanır — Python'un başladığı sınır | ~15 dk |
| [`STUDY-METHOD.md`](../STUDY-METHOD.md) | dış kaynak sözleşmesi — resmi Python turu buradan | ~10 dk |

Repoda Python'u öğreten bir doküman **yok** (bilinçli boşluk). Bu modülün gövdesi
ops için gereken temeli **kendi başına verir**: aşağıdaki **Python sözdizimi köprüsü**
+ örnekler, lab'ı dışarıya çıkmadan bitirmene yeter. Amaç dili baştan sona öğrenmek
değil, **iş görecek kadarı**.

Sözdizimini köprünün ötesinde derinleştirmek **opsiyoneldir** — lab için şart değil.
Gidersen, resmi Python turu bir dış kaynaktır ve dört-alanlı sözleşmeye uyar
([`STUDY-METHOD.md`](../STUDY-METHOD.md)):

| Kaynak | Niye gidiyorsun | Orada ne yapacaksın | Süre | Dönünce doğrulama |
|---|---|---|---|---|
| Resmi Python turu (`docs.python.org/3/tutorial`) | Sözdizimini köprünün ötesine taşımak (opsiyonel) | Bölüm 3–5'i (sayı/metin/liste, `if`/`for`, sözlük) okuyup örnekleri kendi yorumlayıcında çalıştır | ~2 saat | Bir `dict`'i `for` ile gezip f-string ile yazdıran 5 satırı **bakmadan** yazabiliyorsun |

## 🐍 Python nerede, Bash nerede
Python'u bir dil olarak değil, **Bash'in tıkandığı yeri açan bir araç** olarak öğren.

| İş | Nerede |
|---|---|
| Dosya taşı, komut zincirle, basit süzgeç (`grep`/`awk`) | **Bash** |
| Çok adımlı akış, derin `if/else`, düzgün hata yönetimi | **Python** |
| JSON / API cevabı işlemek | **Python** (Bash'te `jq` bir yere kadar) |
| Tekrar kullanılacak, test edilecek, başkasının okuyacağı araç | **Python** |

Kural: bir Bash betiği 30 satırı geçtiyse ya da içinde JSON ayrıştırıyorsan dur — bu iş Python'a geçmiş demektir.

## 🧩 Python sözdizimi — Bash'ten gelenler için
Aşağıdaki örnekleri okuyabilmen için Bash'ten farklı **altı şey** yeter. Bunları bilirsen
lab'ı dışarı çıkmadan bitirirsin; gerisi ihtiyaç anında aranır.

| Bash | Python | Not |
|---|---|---|
| `VAR=deger` / `$VAR` | `var = "deger"` / `var` | `$` yok; değişkene doğrudan adıyla erişilir |
| `if [ ... ]; then … fi` | `if ...:` + **girinti** | Blok `:` ile açılır; `fi`/`done` yok — bloğu **girinti** belirler |
| `for x in ...; do … done` | `for x in ...:` + girinti | aynı mantık, `do`/`done` yok |
| (harici komut çağırmak) | `import json` | hazır yetenek `import` ile gelir, ayrı süreç değil |
| `${arr[0]}` | `d["anahtar"]` / `liste[0]` | sözlük (`dict`) ve liste — anahtar/indeksle eriş |
| `"merhaba $ad"` | `f"merhaba {ad}"` | f-string: `{}` içine değişken/ifade koyulur |

İki şey daha:
- **`with open(...) as f:`** — dosyayı/bağlantıyı açar, blok bitince **otomatik kapatır**;
  Bash'teki gibi elle temizlik yapmana gerek kalmaz. Örnek 2'deki `urlopen` bu yüzden `with` ile.
- **Girinti kutsaldır.** Bloğu süsleme parantezi değil, satır başındaki boşluk belirler.
  Karışık tab/boşluk → `IndentationError`. Bir dosyada tek stil kullan (4 boşluk).

Bu kadarıyla aşağıdaki üç örneği satır satır okuyabilirsin.

## 1️⃣ İlk araç: argüman + hata + çıkış kodu
İyi bir ops aracı argüman alır, hatayı yutmaz ve **çıkış koduyla konuşur** (0 = başarı,
≠0 = hata). Bu, aracın bir pipeline'da (C2) kullanılabilmesinin ön şartıdır.

```python
#!/usr/bin/env python3
import argparse, sys

def main():
    p = argparse.ArgumentParser(description="Bir dizindeki büyük dosyaları listeler")
    p.add_argument("path")
    p.add_argument("--min-mb", type=int, default=100)
    args = p.parse_args()
    ok = do_scan(args.path, args.min_mb)   # işin kendisi
    if not ok:
        print("HATA: dizin okunamadı", file=sys.stderr)
        sys.exit(1)            # pipeline bunu görür ve adımı kırar

if __name__ == "__main__":
    main()
```

`argparse` sana bedavaya `--help`, tip kontrolü ve okunur hata verir; argümanları elle `sys.argv`'den ayıklama.

## 2️⃣ Bir API'ye istek, JSON işleme
Ops işinin yarısı bir API'ye sorup cevabı işlemektir. İki kural: **timeout koy** (yoksa
betik sonsuza asılır) ve **durum kodunu kontrol et**.

```python
import json, urllib.request

req = urllib.request.Request(
    "https://api.example.com/v1/status",
    headers={"Authorization": "Bearer <TOKEN>"},
)
with urllib.request.urlopen(req, timeout=10) as r:
    data = json.load(r)

for svc in data["services"]:
    if svc["state"] != "healthy":
        print(f"{svc['name']}: {svc['state']}")
```

`requests` kütüphanesi bunu daha kısa yazar ama bir bağımlılıktır; küçük işlerde stdlib `urllib` yeter. Hangisini seçtiğini gerekçelendir.

## 3️⃣ Hatayı yutma, çıkış koduyla konuş
En sık ops hatası: `except: pass`. Bu hatayı görünmez yapar; betik "başarılı" görünür ama iş yapılmamıştır.

```python
try:
    result = do_work()
except FileNotFoundError as e:
    print(f"HATA: {e}", file=sys.stderr)
    sys.exit(2)              # yalnız beklediğin hatayı yakala, hepsini değil
```

`sys.exit(kod)` ile çağırana **ne olduğunu** söyle — sessiz başarısızlık en pahalı hatadır.

## 4️⃣ Bağımlılık ve okunabilirlik
- **Sanal ortam:** `python3 -m venv .venv && source .venv/bin/activate`. Sistem Python'una paket kurma.
- **Sabitle:** kullandığın paketi `requirements.txt`'e yaz — C2 pipeline'ı aynı sürümü kursun.
- **Küçük tut:** amacın ürün değil, tekrar eden işi bitirmek. Bir betik bir şey yapsın, onu iyi yapsın.

## 🔨 Lab
Ayrı bir lab dizini yok — bu modülün pratiği aşağıdaki **kabul kriterleridir**:
`argparse`'li bir CLI + JSON çeken bir betik yaz. Burada yazdığın aracı sonra
[`C2`](C2-ci.md) CI lab'ında ([`L10`](../labs/build/L10-ci/)) pipeline'a koyarsın.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] `argparse` ile argüman + hata yönetimi olan, sıfır/sıfır-dışı çıkış kodu döndüren çalışan bir CLI aracı yazdın
- [ ] Bir API'den JSON çekip özetleyen, timeout + durum kontrolü olan bir betik yazdın — çıktısı gösterilebiliyor
- [ ] "Bu işi niçin Bash yerine Python'da (ya da tersi) yazdım" — yazılı gerekçe
- [ ] `except: pass` ile hata yutmanın niçin tehlikeli olduğunu kendi cümlelerinle **yazdın** (aracının README/notuna)

## 🧪 Kendini test et
1. Bir betiği ne zaman Bash'ten Python'a taşırsın? İki somut sinyal ver.
2. `except: pass` niçin ops'ta bir hata değil, bir tuzaktır?
3. Aracın ileride bir **CI adımında** çalışacak (CI'ı [`C2`](C2-ci.md)'de göreceksin — şimdilik "her commit'te otomatik çalışan komut dizisi" kadarını bil). Onu bu dizide sorunsuz kullanılır ("pipeline dostu") yapan iki şey ne, niye?

<details><summary>Cevaplar</summary>

1. (a) Bash betiği 30+ satıra çıkıp `if/else` derinleştiğinde; (b) JSON/API cevabı ayrıştırdığında (`jq` bir yere kadar). Üçüncü sinyal: araç test edilecek ya da başkası okuyacaksa.
2. Hatayı görünmez yapar: betik başarılı görünür (çıkış 0) ama iş yapılmamıştır — en pahalı hata sessiz olandır. Yalnız beklediğin hatayı yakala, gerisini çağırana `sys.exit(≠0)` ile bildir.
3. (a) **Çıkış kodu:** 0 başarı, ≠0 hata — pipeline buna bakarak adımı kırar/geçirir; (b) **stderr:** hatayı stdout'tan ayrı yazmak log ile çıktının karışmasını önler. İkisi olmadan araç sessizce başarısız olur.
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| `ModuleNotFoundError` | Paket sistem Python'unda / venv aktif değil | venv oluştur + aktive et; `pip install`; `requirements.txt`'e yaz |
| Betik bir API çağrısında asılı kalıyor | timeout yok | `urlopen(..., timeout=10)`; her ağ çağrısına timeout koy |
| Betik "başarılı" ama iş yapılmamış | `except: pass` hatayı yutmuş | Yalnız beklenen hatayı yakala; `sys.exit(≠0)` ile bildir |
| CLI argümanları elle ayıklanıyor, kırılgan | `sys.argv` ile manuel ayıklama | `argparse` kullan — bedava `--help` + tip kontrolü |

## 💼 Portfolyo çıktısı
Küçük ama gerçek bir ops aracı (örn. bir sağlık kontrolü / rapor betiği).

## ⏭️ Sırada
[`C1 — Container`](C1-container.md)

---

> *"Python'u yazılımcı gibi değil, operasyoncu gibi öğren: amacın ürün değil, tekrar eden işi bitirmek."*
