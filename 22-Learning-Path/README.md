---
description: "Sıfırdan DevSecOps öğrenme patikası — oku, inşa et, doğrula, geç. Okuma listesi değil, müfredat."
tags: [Learning Path]
---
# 🎓 Öğrenme Patikası — Sıfırdan DevSecOps

> *"Bu bir okuma listesi değil, müfredattır. Okuma listesi 'şunu oku' der; müfredat: oku → inşa et → doğrula → geçemediysen dön → geçtiysen ilerle."*

Bu patika, DevSecOps hakkında hiçbir şey bilmeyen birinin sıfırdan başlayıp
adım adım ilerleyebileceği bir müfredattır. Her adımda ne okuyacağın, ne inşa
edeceğin, nasıl doğrulayacağın ve sonra nereye gideceğin yazılıdır. Hedef:
**hiçbir noktada "şimdi ne yapacağım?" diye sormamak.**

Bu repo (`The DevSecOps Handbook`) 21 konu klasöründe 125+ deep-dive barındırır.
Patika o dokümanların **omurgası ve sıralayıcısıdır** — kopyası değil. Bir konu
zaten bir deep-dive'da anlatılıyorsa, modül ona **link verir.**

---

## 🎯 Bu patika kimin için

- **Yeni mezun / kariyer değiştiren** — hiçbir ön bilgi varsaymaz, A1'den başlar.
- **Backend / yazılım geliştirici** — kod bilir, işletim/ağ/deploy tarafını doldurur.
- **Sistem yöneticisi / IT** — Linux/ağ bilir, otomasyon ve orkestrasyona geçer.

Nereden gireceğini [`PLACEMENT.md`](PLACEMENT.md) belirler — "biliyorum" dediğin
için değil, **kontrol testiyle.**

---

## 🧭 Nasıl kullanılır

1. [`PLACEMENT.md`](PLACEMENT.md) → giriş rampanı seç, kontrol testini geç.
2. [`STUDY-METHOD.md`](STUDY-METHOD.md) → okuma/yapma oranı, dış kaynak sözleşmesi.
3. [`PROGRESS-TEMPLATE.md`](PROGRESS-TEMPLATE.md) → kendine kopyala, ilerlemeni işaretle.
4. [`CURRICULUM.md`](CURRICULUM.md) → blok sırasını ve bağımlılık grafiğini gör.
5. İlk modülünü aç, **kabul kriterlerini geçmeden sonrakine geçme.**
6. Her bloğun sonunda o bloğun `STAGE-EXAM.md`'sini çöz (blok klasöründe) —
   sinyali "anladım" değil, komut çıktısı + yazılı gerekçe kanıtlar. Blok C/D/E
   sonunda ayrıca bir [`capstone`](capstones/) teslim projesi vardır.

Takıldığında yalnız değilsin: her modülde `🆘 Takıldıysan` tablosu var; genel
hatalar [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md)'de (Faz 9). Para harcamadan
önce [`COST-GUARDRAILS.md`](COST-GUARDRAILS.md) oku — **her lab önce yerelde çalışır.**

---

## 🧱 Altı blok — teknolojiye göre değil, bağımlılığa göre

Sıralama araç sayısına değil, **sorumluluk yarıçapına** göre kurulur. Her adımın
gerekçesi: *bir sonrakini anlamak için bu şart.*

| Blok | Ad | Ne kazanırsın |
|---|---|---|
| **A** | Sezgi | Bir uygulamayı **elle** ayağa kaldırırsın — container yok. |
| **B** | Görebilmek | Log ve metrikle bir arızayı **kanıtlarsın**, tahmin etmezsin. |
| **C** | Tekrarlanabilirlik | Container, CI, Terraform — sistemi sıfırdan yeniden kurarsın. |
| **D** | Orkestrasyon | K8s — **güvenlik ilk günden içeride** (RBAC, NetworkPolicy). |
| **E** | Sahiplik | SLO, on-call, incident, restore — bozulanı sen geri getirirsin. |
| **F** | Karar | Maliyet, uyum, platform, yazma — "hayır" diyebilmek. |

Detay + mermaid bağımlılık grafiği: [`CURRICULUM.md`](CURRICULUM.md).

---

## ⏱️ Ne kadar sürer

Süreyi kısa göstermek güven kaybetmenin en hızlı yoludur. Haftada **10–12 saat**
çalışan biri için kaba aralık: **~40–48 hafta** (toplam ~477 saat, capstone'lar dahil).
Bu bir yarış değil; kabul kriterlerini gerçekten geçmek takvimden önemlidir.

> ⛔ Bu patika sana bir **ünvan** vaat etmez ("şu kadar ayda şu ünvana ulaşırsın"
> türü ifadeler burada yoktur). Ünvan; deneyim, kurum ve piyasayla belirlenir. Patika
> **yetkinlik** verir: her bloğu bitirdiğinde belirli bir şeyi *yapabiliyor* olursun.

---

## 🧗 Dürüst tavan — dipnot değil, ana metin

> Son iki kapı kendi kendine geçilemez. Seçmediğin bir arıza, sahibi olduğun bir
> sistem ve gerçek kullanıcı gerekir. Bu noktada yapılacak şey daha çok okumak değil:
> işe girmek, on-call rotasyonuna girmek, incident'e gönüllü olmak. Bu patika seni
> oraya kadar getirir; **sonrasını üretim ortamı öğretir.**

Erken koyulan konular (service mesh, multi-cluster, IDP…) kasıtlı olarak
ertelenmiştir — [`NOT-YET.md`](NOT-YET.md)'e bak. Bir yol haritasının asıl zararı
eksik bıraktıkları değil, **erken koyduklarıdır.**

---

## 🗺️ Bu klasörde ne var

| Dosya | Ne için |
|---|---|
| [`CURRICULUM.md`](CURRICULUM.md) | Blok tablosu, bağımlılık grafiği, geçiş sinyalleri |
| [`PLACEMENT.md`](PLACEMENT.md) | Üç giriş rampası + kontrol testi |
| [`STUDY-METHOD.md`](STUDY-METHOD.md) | Nasıl çalışılır, dış kaynak sözleşmesi |
| [`PROGRESS-TEMPLATE.md`](PROGRESS-TEMPLATE.md) | Kendine kopyalayacağın ilerleme dosyası |
| [`COST-GUARDRAILS.md`](COST-GUARDRAILS.md) | Yerel alternatifler + bulut bütçe alarmı |
| [`NOT-YET.md`](NOT-YET.md) | "Henüz değil" listesi ve gerekçeleri |
| [`PORTFOLIO.md`](PORTFOLIO.md) | Hangi modül/capstone hangi CV satırına karşılık gelir |
| `block-a … block-f/` | Modül dosyaları (A1…F5) |
| `capstones/` | Blok C/D/E sonu teslim projeleri |
| `labs/` | İnşa lab'ları + kırık lab'lar |

---

> *"Bir sonraki soyutlamanın neyi çözdüğünü, o soyutlamadan önceki acıyı yaşamış olan bilir. Bu patika o sırayı korur."*
