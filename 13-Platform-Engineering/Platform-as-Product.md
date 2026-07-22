---
description: "Platform Engineering'i bir ürün disiplini olarak yönetmenin somut yolları: developer'ı müşteri görme felsefesi, NPS ölçümü, roadmap, OKR, beta program ve evangelism."
tags:
  - Platform Engineering
  - Culture
  - Soft Skills
  - Roadmap
---
# Platform-as-Product — İç Müşteri Memnuniyeti

> *"Platform takımının ürünü 'bir tool' değil, **diğer mühendislere
> sunulan iç bir ürün**. Customer = developer. Müşteri memnuniyeti
> ölçülmeyen ürün, **6 ay sonra bypass'lar** ile dolar."*

Bu rehber Platform Engineering'i bir **ürün disiplini** olarak yönetmenin
somut yollarını — NPS ölçümü, roadmap, OKR, beta program, evangelism —
anlatır.

---

## 🎯 Felsefe Değişimi

| **DevOps takımı** (eski model) | **Platform-as-Product** (yeni) |
|---|---|
| "Ticket'a cevap veriyoruz" | "Ürün geliştiriyoruz" |
| "Bizim aracımız zorunlu" | "Bizim aracımız tercih edilir" |
| Backlog yok, reactive | Roadmap + OKR |
| Kalite ölçülmez | NPS + adoption + lead time |
| Manager ekibi | Product manager (PM) ekipte |
| "Mühendis bizim için çalışsın" | "Biz mühendisin için çalışıyoruz" |

> 🔑 **Ürün düşüncesi**: Müşterinin (developer'ın) **işini kolaylaştırıyor
> muyum?** sorusunu sürekli sor.

---

## 📊 Müşteri (Developer) NPS

> **NPS (Net Promoter Score)**: "Bu platform'u arkadaşına önerir misin?"
> 0-10 arası. Promoter (9-10) - Detractor (0-6) = NPS.

### Quarterly survey
```
1. Backstage portal'ı kullanırken yaşadığın deneyim için 0-10 arası puan?
2. Şu son sprint'te platform sürtünmesi yaşadın mı? (evet/hayır)
3. En büyük sürtünme noktası?
4. En çok beğendiğin platform feature'ı?
5. Önümüzdeki çeyrek için 1 öneri?
```

### Hedefler
| NPS | Anlam |
|---|---|
| > 50 | Mükemmel |
| 30-50 | İyi |
| 0-30 | Orta — iyileştirme gerek |
| < 0 | Kötü — kriz |

### NPS trendi
```
2025-Q1: 12  (kuruldu, çoğu manuel)
2025-Q2: 28  (Backstage adoption başladı)
2025-Q3: 41  (golden path 3 tane)
2025-Q4: 55  (cost insights + on-call entegrasyonu)
2026-Q1: 47  (büyüme, yeni team'ler henüz alışmadı)
```

> 🔑 NPS düşüş = **kırmızı bayrak**. Detractor feedback'lerini incele.

---

## 🗺️ Platform Roadmap

### Yapı (3 horizon)
```
Horizon 1 (0-3 ay): Şu anki adoption + sustain
  - Bug fix, küçük iyileştirme
  - Mevcut path'leri pre-prod path'i ile entegre

Horizon 2 (3-9 ay): Differentiator yetenekler
  - 3 yeni golden path
  - Cost insights v2 (Kubecost entegrasyonu derinleşti)
  - Multi-cluster catalog

Horizon 3 (9-18 ay): Yeni alan
  - Compose pattern: developer kendi component'larını seçer
  - AI-assisted scaffolding
  - Compliance otomasyonu (SOC2 controls görünür)
```

### Roadmap görünür
- Backstage'de "Platform Roadmap" sayfası
- Quarterly demo days (yeni feature'lar)
- Slack #platform-announce channel

---

## 🎯 Platform OKR'ları

### Örnek (Q3-Q4)
```
Objective: Yeni servis onboarding süresini 30 dk altına indir.

Key Results:
- KR1: Backstage scaffolder adoption %85 (mevcut %60)
- KR2: Median onboard süresi < 30 dk (mevcut 45 dk)
- KR3: Onboarding NPS > 40 (mevcut 32)


Objective: Platform sürtünmesini azalt.

Key Results:
- KR1: DevOps ticket sayısı %40 azalsın
- KR2: Self-service oranı > %80
- KR3: Quarterly NPS > 45
```

### OKR adoption
- Quarterly review meeting
- Public dashboard (ekip + yöneticiler görür)
- "Did not hit" KR'lar postmortem (niye?)

---

## 👥 Platform Team Yapısı

### Roller
```
Platform Lead          → Vision, stakeholder management
Platform PM            → Roadmap, customer research
Senior Engineers (2-4) → Build & maintain
DevX Engineer          → Doc, evangelism, onboarding
SRE                    → Reliability of platform itself
```

### Sayı oranı
- **1 platform engineer : 50 product engineer** (sweet spot)
- < 1:50 — platform overworked
- > 1:50 — gereksiz personel

---

## 🎤 Customer Research

### 1. **User Interview** (quarterly)
- 5-10 mühendis ile 30-45 dk konuşma
- "Bu son ay ne yapmaya çalıştın? Nerede sıkıldın?"
- Açık sorular, çözüm önerme **dinleme**

### 2. **Office Hours** (haftalık)
- 2-3 saat platform team available
- Mühendis sorabilir, gelir
- Pattern keşfedilir → roadmap'e

### 3. **Slack Listening**
- #platform-help kanalı
- Sorular pattern keşfeder
- "X yapıyor musun" 5 kez sorulduysa → doc gap

### 4. **Telemetry**
- Backstage tıklama datası
- Scaffolder kullanım
- Search query'leri (en çok ne arandı?)

---

## 📣 Evangelism (Adoption Çeker)

### Internal marketing
| Kanal | Frekans |
|---|---|
| Demo Day | Aylık |
| Newsletter | Haftalık (yeni feature, tip) |
| Lunch & Learn | Aylık (interactive) |
| Onboarding talk | Yeni dev'e zorunlu |
| Platform Office Hours | Haftalık |
| Slack updates | Sürekli |

### "Win" stories paylaş
> "Payments team yeni servisi 12 dakikada açtı (önceden 4 hafta sürerdi)."

→ Diğer team'lere **inspire**.

---

## 🚧 Beta Program

### Yeni feature açma stratejisi
```
1. Internal proposal (RFC)
2. Beta partner team (1-2)
3. 4-8 hafta beta
4. NPS + feedback collect
5. GA decision
6. Tüm team'lere rollout
```

### Beta partner seçimi
- Yeni teknoloji açık ekipler
- Manager ile yazılı anlaşma (zaman vermeli)
- Feedback değerli, "bug raporlarsanız mutlu"

---

## 💸 Cost Transparency

### Platform maliyeti görünür
- "Backstage'i çalıştırmak ekibe X $/ay'a mal oluyor"
- Per-team: "Sizin team'inizin platform kullanımı $Y/ay"
- ROI: "Tasarruf X$, maliyet Y$, net Z$"

### "Build vs use" tartışması
- Platform team'in tasarruf ettiği saat → para çevir
- Ürün takımının kazandığı velocity → para çevir
- "Platform team'imiz kendi maliyetinin 5x değer üretiyor"

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Platform "zorunlu" | Bypass'lar başlar | Self-service + escape hatch |
| NPS ölçülmez | "Adoption iyi gidiyor" iddia | Quarterly NPS |
| Roadmap yok | Reactive ticket maker | OKR + 3-horizon |
| PM yok | Sadece teknik karar | Product mindset |
| Customer research yok | Ürün ne lazımı bilmiyor | User interview + office hours |
| Demo Day yok | Ekip platform'u bilmiyor | Aylık demo |
| Cost transparency yok | "Pahalı mı? Faydalı mı?" cevap yok | Per-team cost dashboard |
| Beta atlanır, big-bang launch | Üretimde bug | Beta → GA |
| Platform team izole | "Bizden geçer" silosu | Pair / shadow ürün takımları |
| Onboarding doc yok / eski | Yeni mühendis self-serve değil | TechDocs + güncel |
| Platform team success ölçümü "tool sayısı" | Kullanılmayan tool var | Adoption + NPS |
| 1 platform : 200 dev | Burnout | 1:50 oranı |

---

## 📋 Platform-as-Product Checklist

```
[ ] Platform PM atanmış (veya rotasyonel)
[ ] Roadmap public (3-horizon)
[ ] OKR quarterly + dashboard
[ ] NPS quarterly survey
[ ] User interview (5+ mühendis quarterly)
[ ] Office hours haftalık
[ ] Demo Day aylık
[ ] Newsletter / Slack updates
[ ] Beta program (yeni feature için)
[ ] Adoption dashboard (path başına, plugin başına)
[ ] Cost transparency (per-team)
[ ] Platform team:dev ratio 1:50 (~)
[ ] Onboarding talk yeni dev'e
[ ] Customer success stories paylaşılır
[ ] Quarterly retro (platform team içi)
[ ] Detractor feedback'leri tek tek incelenir
[ ] Platform değişiklik notification'ı (#platform-announce)
[ ] Backwards-compatibility commitment
[ ] Sunset policy: deprecate → 6 ay → kaldır
```

---

## 📚 Referanslar

- **Team Topologies** (Skelton, Pais)
- **Platform Engineering** — platformengineering.org
- **The Lean Product Playbook** — Dan Olsen
- **Inspired** — Marty Cagan
- **Internal Developer Platform Maturity Model** — platformengineering.org/maturity-model
- [`Internal-Developer-Platform.md`](Internal-Developer-Platform.md)
- [`Backstage-Setup.md`](Backstage-Setup.md)
- [`Golden-Paths.md`](Golden-Paths.md)
- [`Service-Catalog.md`](Service-Catalog.md)
- [`20-Soft-Skills/Stakeholder-Management.md`](../20-Soft-Skills/Stakeholder-Management.md)

---

> *"Platform-as-Product 'yeni hot kelime' değil, **disiplin değişimi**.
> Platform team gerçek **müşteri** olarak gördüğü mühendisin **NPS'ini
> ölçen ekip**, kendi bütçesini **ROI ile savunabilir**."*

---

> 🎓 **Öğrenme Patikası:** Bu doküman [`F3`](../22-Learning-Path/block-f-judgment/F3-platform-idp.md) modülünde "Önce oku" kaynağı olarak kullanılıyor.
