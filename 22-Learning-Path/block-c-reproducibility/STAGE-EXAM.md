---
description: "Blok C sınavı: Python otomasyon, container, CI, Terraform, bütçe alarmı — C→D geçiş kapısı. Sıfırdan, elle dokunmadan yeniden kurulabiliyor mu?"
level: C
tags: [Learning Path, Stage Exam]
---
# 📝 Blok C Sınavı — Tekrarlanabilirlik

> *"C → D geçiş sinyali: sistemini sıfırdan, elle hiçbir şeye dokunmadan yeniden kurabiliyor musun?"*

**Kapı:** Blok C sonu (C4'ten sonra, D1'den önce) · **Ön koşul:** [`C0`](C0-ops-python.md)–[`C4`](C4-bulut-butce-alarmi.md) kabul kriterleri geçilmiş

> ℹ️ Tüm `bash labs/...` komutlarını **`22-Learning-Path/` kökünden** çalıştır.

Blok C'nin tek iddiası şudur: **aynı girdiyle aynı sistemi ikinci kez kurabilmek.**
Bu sınav onu ölçer. Her soru bir modülün kabul kriterine izlenebilir.

> 🏁 **Sınav ≠ capstone.** Bu sınav bilgi/beceri kapısıdır. Bloğun büyük teslim
> projesi [`Capstone 1`](../capstones/CAP1-blok-c-sonu.md)'dir — orada A6
> uygulamasını uçtan uca tekrarlanabilir hâle getirirsin. Sınavı geç, sonra
> capstone'a otur.

---

## 1️⃣ Kavram soruları (yazılı)

| # | Soru | İzlenebilirlik (modül → kabul kriteri) |
|---|---|---|
| 1 | Bir işi niçin Bash yerine Python'da (ya da tersi) yazarsın? Bir karar kuralı ver. | C0 → "niçin Python/Bash" kriteri |
| 2 | `except: pass` ile hata yutmak niçin tehlikeli? Bir arıza senaryosu ver. | C0 → `except: pass` kriteri |
| 3 | Bir Docker katmanı niçin cache'lenir / niçin geçersizleşir? `COPY` sırası niçin önemli? | C1 → katman cache kriteri |
| 4 | `:latest` etiketi niçin yasak? Yerine ne kullanılır (SHA/semver) ve niçin? | C2 → sürümlü etiket kriteri |
| 5 | "Pipeline yeşil" tam olarak **neyi** kanıtlar, neyi kanıtlamaz? | C2 → "yeşil neyi doğruladı" kriteri |
| 6 | Terraform state nedir? Niçin paylaşılan + kilitlenen bir yerde durmalı? | C3 → state kriteri |
| 7 | Hangi bulut servisleri free tier, hangileri saat/GB başına ücretli? İki örnek ver. | C4 → free tier kriteri |

**Geçme:** 7 sorunun **en az 6'sı** doğru + gerekçeli. 4. soru (`:latest` yasağı)
**zorunlu doğru** — mutable tag supply-chain riskidir ve D4'ün önkoşuludur.

---

## 2️⃣ Uygulamalı görev — "sıfırdan, elle dokunmadan"

**Görev A — İki kırık lab (çekirdek):**

- [ ] [`K02 — container hatası`](../labs/broken/K02-container-hatasi/README.md): `bash labs/broken/K02-container-hatasi/verify.sh` çözümden sonra sıfır hatayla geçiyor
- [ ] [`K03 — terraform state`](../labs/broken/K03-terraform-state/README.md): `bash labs/broken/K03-terraform-state/verify.sh` çözümden sonra sıfır hatayla geçiyor
- [ ] Her ikisi için kök sebep + teşhis akışını yazdın (K03 = bayat state kilidi → `force-unlock`)

**Görev B — Tekrarlanabilirlik kanıtı:**
[`C3`](C3-terraform.md)/[`L11`](../labs/build/L11-terraform/README.md) (LocalStack) kurulumunu kullan.

- [ ] `terraform apply` ile ortam sıfırdan kuruluyor → `terraform destroy` → tekrar `apply` **aynı** sonucu üretiyor
- [ ] Bir commit → CI → registry akışı yeşil ([`L10`](../labs/build/L10-ci/README.md)); image sürümlü etiketle yayımlanıyor (`:latest` yok)

**Görev C — Bütçe alarmı gerçekten çalışıyor:**
[`C4`](C4-bulut-butce-alarmi.md)/[`L12`](../labs/build/L12-bulut-butce-alarmi/README.md).

- [ ] Bütçe/faturalama alarmı kurulu, bir bildirim kanalına bağlı ve **tetiklenerek** test edildi
- [ ] Küçük bir kaynak açıldı ve `destroy` ile kapatıldı — **açık kaynak kalmadığı** doğrulandı

---

## 🚫 Bu sınavı kendine karşı kaybetme

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| `:latest` ile "çalışıyor işte" | Hangi sürümün çalıştığı belirsiz; rollback imkânsız | SHA/semver ile pin'le |
| `apply` sonrası elle bir ayar düzeltmek | Artık "sıfırdan tekrarlanabilir" değil | Düzeltmeyi kod'a al, tekrar `apply` |
| `destroy` etmeden bırakmak | C4'ün tam uyardığı maliyet tuzağı | Her lab sonunda `destroy` + doğrula |
| Bütçe alarmını kurup test etmemek | Test edilmemiş alarm, alarm değildir | Eşiği düşürüp **tetikle**, bildirimi gör |
| `except: pass` ile betiği "sustur"mak | Arıza sessizce yutulur | Hatayı yakala, logla, sıfır-dışı çıkış ver |

---

## ✅ Geçtin mi?

- [ ] Kavram: 7/7'nin en az 6'sı + 4. soru zorunlu doğru
- [ ] Uygulama: K02 + K03 yeşil; `apply→destroy→apply` idempotent; CI yeşil & sürümlü image
- [ ] Bütçe: alarm tetiklenerek test edildi; `destroy` sonrası açık kaynak yok

Geçemediysen: container'da C1, CI'da C2, state'te C3, bütçede C4'e dön.

## ⏭️ Sırada
Geçtiysen önce [`Capstone 1`](../capstones/CAP1-blok-c-sonu.md), sonra
[`D1 — K8s Temel`](../block-d-orchestration/D1-k8s-temel.md).

---

> *"Tekrarlanabilirlik bir özellik değil, bir kanıttır. K8s'e (Blok D) bir soyutlama daha eklemeden önce, elindeki sistemi iki kez aynı şekilde kurabildiğini kanıtla."*
