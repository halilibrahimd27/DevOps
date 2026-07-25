---
description: "Blok E sınavı: SLO/error budget, alerting, incident+postmortem, test edilmiş restore, chaos — E→F geçiş kapısı. Sahiplik kanıtı."
level: E
tags: [Learning Path, Stage Exam]
---
# 📝 Blok E Sınavı — Sahiplik

> *"D → E geçiş sinyali: kendi kurduğun bir şey senin hatanla bozuldu ve sen geri getirdin mi?"*

**Kapı:** Blok E sonu (E5'ten sonra, F1'den önce) · **Ön koşul:** [`E1`](E1-sli-slo-error-budget.md)–[`E5`](E5-chaos.md) kabul kriterleri geçilmiş

> ℹ️ Her `verify.sh`'i `22-Learning-Path/` kökünden (`bash labs/broken/…/verify.sh`) çalıştır. K08 belge/erişim kontrolüyle yerelde de anlamlıdır; K07 incident belgelerini, K09 canlı cluster'ı denetler — ortam yoksa `verify.sh` yeşil dönmez.

Blok E, "çalıştıran"dan "sahip"e geçiştir. Bu sınav sahipliğin **mekaniğini**
ölçebilir: SLO tanımlı mı, alarm ateşleniyor mu, restore gerçekten test edildi mi.
Her soru bir modülün kabul kriterine izlenebilir.

> 🧗 **Dürüst tavan (ana metin, dipnot değil):** Bu sınav sahipliğin *mekaniğini*
> kanıtlar; sahipliğin *kendisini* değil. Onun için seçmediğin bir arıza, sahibi
> olduğun bir sistem ve gerçek kullanıcı gerekir. Bu kapıdan sonrası daha çok okumak
> değil: işe girmek, on-call'a girmek, incident'e gönüllü olmak. Bkz.
> [`README.md`](../README.md) → Dürüst tavan.

---

## 1️⃣ Kavram soruları (yazılı)

| # | Soru | İzlenebilirlik (modül → kabul kriteri) |
|---|---|---|
| 1 | Bir SLI nasıl seçilir? Bir SLO'dan error budget'ı (dk/ay) nasıl hesaplarsın? | E1 → SLI/SLO/error budget kriteri |
| 2 | Error budget tükendiğinde ne değişir? (yayın durur mu, öncelik ne olur?) | E1 → budget tükenme kriteri |
| 3 | Bir alarmın "gece 3'te uyandırmalı mı?" testi nedir? page / ticket / log ayrımı? | E2 → alarm sınıflandırma kriteri |
| 4 | Bir "gürültü alarmı" örneği ver; niçin sessize alınır/kaldırılır? Eskalasyon ne zaman devreye girer? | E2 → gürültü + eskalasyon kriteri |
| 5 | "Suçlamasız (blameless) postmortem" ne demek? İçinde hangi üç şey **zorunlu** bulunur? | E3 → postmortem kriteri |
| 6 | "Test edilmemiş backup, backup değildir" niçin? RTO ile RPO farkı ne? | E4 → restore + RTO/RPO kriteri |
| 7 | Bir backup için hangi güvenlik kontrolleri sorulur? (kim erişebilir, at-rest şifreli mi) | E4 → backup erişim/at-rest kriteri |
| 8 | Sınırlı blast radius'lu bir game day niçin hipotez → deney → sonuç olarak yürütülür? | E5 → game day kriteri |

**Geçme:** 8 sorunun **en az 7'si** doğru. Soru 6 ve 7 (restore + backup güvenliği)
**zorunlu doğru** — güvenlik ipliğinin E'deki halkası budur.

---

## 2️⃣ Uygulamalı görev — sahipliğin mekaniği

**Görev A — Üç kırık lab (çekirdek):**

- [ ] [`K07 — incident simülasyonu`](../labs/broken/K07-incident-sim/README.md): `verify.sh` yeşil; UTC dakika hassasiyetli timeline ile yönetildi
- [ ] [`K08 — restore başarısız`](../labs/broken/K08-restore-basarisiz/README.md): `verify.sh` yeşil; restore gerçekten çalıştı
- [ ] [`K09 — chaos game day`](../labs/broken/K09-chaos-gameday/README.md): `verify.sh` yeşil; sınırlı blast radius korundu

**Görev B — SLO'ya bağlı alarm (E1+E2):**
[`L18`](../labs/build/L18-sli-slo/README.md) + [`L19`](../labs/build/L19-alerting/README.md).

- [ ] Bir servis için bir SLI Prometheus'ta ölçülüyor; bir SLO + error budget (dk/ay) yazılı hesaplandı
- [ ] SLO'ya bağlı bir alarm kuralı **bir kez ateşlendi** ve çözüldü — Alertmanager/panel kanıtı
- [ ] Her alarm page/ticket/log olarak sınıflandırıldı; eskalasyon yazılı tanımlı

**Görev C — Restore gerçekten test edildi (zorunlu, güvenlik ipliği):**
[`E4`](E4-veritabani-restore.md)/[`L20`](../labs/build/L20-veritabani-restore/README.md).

- [ ] Bir backup **temiz bir ortama** restore edildi; veri bütünlüğü bir sorguyla (satır sayısı/checksum) doğrulandı
- [ ] RTO ve RPO ölçülüp yazıldı
- [ ] Backup'ın erişim + at-rest şifreleme kontrolü yazıldı

**Görev D — Postmortem + eylem maddesi:** K07'den suçlamasız bir postmortem yaz:
sayısal etki + kök sebep + "niçin daha erken yakalanmadı" + en az bir izlenebilir
eylem maddesi (sahip + son tarih).

---

## 🚫 Bu sınavı kendine karşı kaybetme

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Test edilmemiş backup'a güvenmek | Gerçek felakette restore çalışmaz — E4'ün ana dersi | Temiz ortama restore et, bütünlüğü **sorgula** |
| Postmortem'de kişi suçlamak | İnsanlar bir daha bilgi paylaşmaz; kök sebep gizlenir | Sistem/süreç odaklı, blameless yaz |
| Eylem maddesi olmayan postmortem | Aynı incident tekrar eder | Sahip + son tarihli izlenebilir madde çıkar |
| Her şeyi page yapan alerting | Alarm yorgunluğu → gerçek page kaçırılır | page/ticket/log sınıflandır; gürültüyü sustur |
| Blast radius'suz "chaos" | Kendi production'ını gerçekten bozarsın | Sınırlı kapsam + hipotez → deney → sonuç |
| Mekaniği geçip "sahibim" demek | Dürüst tavan: gerçek sahiplik üretim ortamında | Mekaniği kanıtla, gerisini iş/on-call öğretir |

---

## ✅ Geçtin mi?

- [ ] Kavram: 8/8'in en az 7'si + soru 6 & 7 zorunlu doğru
- [ ] Uygulama: K07 + K08 + K09 yeşil; SLO'ya bağlı alarm ateşlendi; restore temiz ortamda doğrulandı
- [ ] Yazma: blameless postmortem + izlenebilir eylem maddesi (sahip + son tarih)

Geçemediysen: SLO'da E1, alerting'de E2, incident/postmortem'de E3, restore'da E4,
chaos'ta E5'e dön.

## ⏭️ Sırada
Geçtiysen önce [`Capstone 3`](../capstones/CAP3-blok-e-sonu.md), sonra
[`F1 — Maliyet (FinOps)`](../block-f-judgment/F1-maliyet-finops.md) — ama önce
dürüst tavanı oku: buradan sonrası **üretim ortamının** işidir.

---

> *"Sahiplik, bir sistemi kurmak değil; o bozulduğunda çağrılan ve geri getiren kişi olmaktır. Bu sınav o kasların çalıştığını gösterir; kasları gerçekten yoran şey ilk gerçek incident'indir."*
