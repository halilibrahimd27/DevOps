---
description: "Üç giriş rampası ve kontrol testi: nereden başlayacağın 'biliyorum' ile değil, testle belirlenir."
tags: [Learning Path]
---
# 🚪 Yerleştirme — Nereden Başlarsın

> *"Kimse gerçekte sıfırdan başlamıyor. Ama 'biliyorum' demek atlama gerekçesi değildir — kontrol testi gerekçedir."*

Bu sayfa üç giriş rampası sunar. Üçü de **aynı gövdeye** bağlanır; fark sadece
nereden girdiğindir. Bir bloğu atlamak istiyorsan, o bloğun **kontrol testini**
geçmen gerekir. Geçemezsen atlamıyorsun — orası senin başlangıcın.

---

## 🎯 Üç rampa

| Rampa | Nereden girer | Koşul |
|---|---|---|
| Yeni mezun / kariyer değiştiren | **A1** | Koşulsuz — buradan başla. |
| Backend / yazılım geliştirici | A1–A5 hızlı kontrol → **A6** | A1–A5 kontrol testini geçersen doğrudan A6. |
| Sistem yöneticisi / IT | A1–A3 atlanabilir → **A6, B1** | A1–A3 kontrol testini geçersen A4–A5'i tazeleyip A6'ya. |

> ⚠️ Hiçbir rampa **A6'yı atlamaz.** A6 (bir uygulamayı elle ayağa kaldırma) tüm
> patikanın çıpasıdır; sonraki her soyutlama ona geri referans verir.

---

## 🧪 Kontrol testleri

Her kontrol testi iki parçadır: **hızlı sorular** (kavram) + **uygulamalı görev**
(kanıt). İkisini de geçmeden ilgili bloğu atlama. Ölçüt "biliyorum" değil, komutun
çalışması ve çıktının doğru olmasıdır.

> 📝 Buradaki kontrol testleri bir bloğu **atlamak** içindir. Bir bloğu bitirdikten
> sonra bir sonrakine geçerken çözdüğün kapı ise o bloğun `STAGE-EXAM.md`'sidir
> (örn. [`Blok A sınavı`](block-a-intuition/STAGE-EXAM.md)). Aynı ölçüt: komut
> çalışır, çıktı doğru, gerekçe yazılı. Kontrol testinden takılırsan atlamıyorsun —
> o blok senin başlangıcın.

### A1–A3 kontrol (Sistem yöneticisi rampası)

Sistem yöneticisi Linux ve ağ bilir; A1–A3'ü atlayabilir ama **kanıtlarsa.** Geçersen
A4–A5'i tazeleyip A6'ya geçersin; geçemezsen ilgili modülden başlarsın.

- **Kavram (yazılı, doküman kapalı):**
  1. `640` iznini `rwx` + octal olarak açıkla; sahip/grup/diğerleri her biri ne yapar? (→ A1)
  2. "disk dolu"nun iki anlamı (`df -h` vs `df -i`) nedir? (→ A1)
  3. "Connection refused" ile "timed out" farkı; her biri hangi katmanı işaret eder? (→ A2)
  4. Bir alan adının çözümlenme zinciri (`dig` → resolver) + `2xx/3xx/4xx/5xx` ne anlatır? (→ A3)
- **Uygulama (komut + çıktı):**
  - `ss -ltnp` (veya `lsof -i`) ile dinlenen bir portu bulup **process'e eşleştir** (→ A2).
  - Bir alan adını `dig +short` ile çöz, `curl -I` ile durum kodunu oku, `openssl` ile
    sertifikanın subject/issuer/geçerlilik tarihini çıkar (→ A3).
- **Geçme:** Dört kavram sorusu doğru + gerekçeli **ve** uygulamalı adımlar dokümana
  bakmadan, üç–dört komutla. Bir soruda bile takılırsan o modülden başla.

### A1–A5 kontrol (Geliştirici rampası)

Geliştirici kod ve Git bilir; A1–A5'i atlayıp A6'ya geçebilir ama **kanıtlarsa.**

- **Kavram (yazılı, doküman kapalı):**
  1. Yukarıdaki A1–A3 kontrolünün dört sorusu.
  2. "Paylaşılanı rebase etme" altın kuralı niçin var? Merge ile rebase geçmişi nasıl
     farklılaşır? (→ A4)
  3. `set -euo pipefail`'in üç bayrağı ayrı ayrı neyi engeller? (→ A5)
- **Uygulama (komut + çıktı):**
  - A1–A3 kontrolünün uygulamalı adımları.
  - İki branch'te bilerek bir conflict üret, **elle** çöz, `git log --oneline --graph`
    ile sonucu göster (→ A4).
  - Bir log dosyasını **tek satırlık** pipe zinciriyle özetle; `shellcheck` temiz bir
    script yaz (→ A5).
- **Geçme:** Tüm kavram soruları doğru + gerekçeli **ve** conflict + log özeti
  yardımsız tamamlanır. `bash -n` ve `shellcheck` temiz.

> ⚠️ Geçtiğin kontrol seni yalnız o bloğun **modüllerinden** muaf tutar; **A6'dan
> değil.** A6 çıpadır — hiçbir rampa onu atlamaz.

---

## 🧭 Emin değilsen

Emin değilsen **atlamayı deneme — A1'den başla.** Bildiğin modüller hızlı geçer;
bilmediğini sandığın yerlerde boşlukları kapatırsın. Boşluk testi (patikanın temel
ilkesi): *Sadece bu modüle ve ön koşullarına sahip biri bunu tamamlayabilmeli.*

---

> *"Yanlış rampadan girmenin bedeli, üç hafta sonra bir duvara çarpıp niye çarptığını bilmemektir."*
