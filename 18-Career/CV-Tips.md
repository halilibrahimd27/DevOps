---
description: "DevOps/SRE/Platform CV yazım rehberi: görev yerine etki odaklı yazım, STAR formülü, ATS uyumu ve Türk pazarı ile global pazar farkları üzerine pratik notlar."
---
# DevOps / SRE CV Tips — Türk Pazarı + Global

> *"CV'ni 'görev listesi' olarak yazan ekipte kalır; **etki listesi**
> olarak yazan üst pozisyona çıkar. 'Kubernetes kurdum' der; başkası
> '$50K maliyet azaltarak Kubernetes migration'ı 6 hafta erken bitirdim'
> der. **İkinci CV** mülakata çağrılır."*

Bu rehber DevOps/SRE/Platform pozisyonu için CV yazımının somut
pratiklerini, TR ve global pazar farklarını, ATS uyumunu ve "etki
yazımı" disiplinini anlatır.

---

## 🎯 İlk İlke: Görev → Etki

### ❌ Görev-bazlı (zayıf)
```
- Kubernetes cluster'ı kurdum
- CI/CD pipeline'ı yazdım
- Monitoring ekledim
```

### ✅ Etki-bazlı (güçlü)
```
- 3 region'da multi-cluster K8s migration'ı yönettim;
  deploy süresi 45 dk → 8 dk (-82%), prod incident -%40
- 30 microservice için CI pipeline'ı standardize ettim
  (Conventional Commits + cosign + Trivy gate);
  release lead time 3 gün → 1 saat
- OpenTelemetry adoption'ını 5 ekipte sürdüm;
  P99 latency dashboard'u sayesinde 4 critical bottleneck tespit, müşteri NPS +12
```

> 🔑 **STAR formula**: Situation + Task + Action + Result. Result mutlaka **sayı** içersin.

---

## 📐 CV Yapısı (1-2 sayfa)

```
[BAŞLIK]                 — Adın, pozisyon (Senior SRE), iletişim
[ÖZET]                   — 3-4 cümle, "ne yaparım, neden farklıyım"
[DENEYİM]                — En son işten geriye, etki-odaklı bullet
[YETENEKLER]             — Tool/teknoloji, kategori bazında
[EĞİTİM + SERTİFİKA]     — Önemliyse vurgulu (CKA, AWS SAA, vb.)
[YAN PROJE / KONFERANS]  — Public speaking / blog / OSS contribution
[İLETİŞİM]               — Email + LinkedIn + GitHub
```

> 🔑 **1 sayfa** 5 yıl altı için. **2 sayfa** kıdemli için max. 3+ sayfa = okunmaz.

---

## 🏷️ Başlık + Özet

```
Halil İbrahim Demir
Senior SRE / Platform Engineer
İstanbul, Türkiye · halil@example.com · linkedin.com/in/halilibrahimd27 · github.com/halilibrahimd27
```

### Özet (3-4 cümle, etki vurgulu)
```
8 yıllık DevOps / SRE deneyimi. K8s, GitOps (ArgoCD), DevSecOps stack'leri
production'da kuran ve sürdüren mühendis. Son rolde 3 region multi-cluster
mimari + cosign-signed CI/CD ile MTTR'ı %60 azaltarak SOC2 Type II
compliance'ını 4 ay erken bitiren ekibi yönettim.
```

> 🔑 Özet **hedef pozisyona** uyarlı yazılır. "Senior SRE"ye başvuruyorsan SRE keyword'leri; "Platform Eng"e başvuruyorsan IDP / Backstage.

---

## 💼 Deneyim Bölümü

### Şablon
```
[ŞİRKET] · [ROL]                                         [TARİH]
City · Country · [employment type]

[1-2 cümle: ekip büyüklüğü, sahip olduğun kapsam]

- [Etki bullet 1: STAR + sayı]
- [Etki bullet 2]
- [Etki bullet 3-5: en güçlülerini en üste]
```

### Örnek
```
DevHub.io · Senior SRE                                  Mar 2023 — 5 / 2026
İstanbul · Remote · Full-time

50 mühendisli SaaS B2B şirketinde 4-kişilik SRE ekibi liderliği.
Kapsam: 3 region K8s, 80+ microservice, $80K/ay AWS spend.

- 3 region'da K8s 1.27 → 1.30 zero-downtime migration; 6 hafta erken
  bitirdik (planlanan 12 hafta), $0 incident maliyeti
- DevSecOps pipeline (cosign + Trivy + Kyverno) standardize ettim;
  CVE response süresi 14 gün → 2 gün, SOC2 audit finding -%75
- Backstage IDP launch'unu yönettim; yeni servis onboard süresi 3 gün
  → 18 dk, DevOps ticket'ları %40 azaldı
- Postgres HA migration (single → CloudNativePG): zero-downtime,
  RPO 24h → 5 dk; 4 müşteri SLA upgrade etti
- On-call burnout sinyalleri tespit edip rotasyon yeniledim;
  NPS 22 → 51, ekipten istifa olmadı
```

---

## 🛠️ Yetenekler — Kategorize

```
Container & Orchestration:  Kubernetes, Docker, Helm, Kustomize, ArgoCD, Flux
Cloud:                       AWS (advanced), GCP (intermediate), Azure (basic)
IaC:                         Terraform, OpenTofu, Crossplane, Pulumi
CI/CD:                       GitHub Actions, GitLab CI, Argo Workflows
Observability:               Prometheus, Grafana, Loki, OpenTelemetry, Datadog
Security:                    Trivy, cosign, Kyverno, OPA, Vault, Falco
Databases:                   PostgreSQL (advanced), MySQL, Redis, MongoDB
Languages:                   Go (advanced), Python (advanced), Bash, JavaScript
Methodology:                 GitOps, Trunk-based, Blameless postmortem, SLO/SLI
```

> 🔑 **Honest leveling**: "advanced / intermediate / basic". "Expert" iddiası mülakatta sorgulanır.

---

## 📜 Sertifikalar — Önemli Olanlar

| Sertifika | Niche |
|---|---|
| **CKA** (Certified Kubernetes Administrator) | K8s ops, geniş kabul |
| **CKAD** (Application Developer) | K8s app developer |
| **CKS** (Security) | K8s security, premium |
| **AWS SAA** (Solutions Architect Associate) | AWS temel |
| **AWS DevOps Pro** | DevOps spesifik |
| **GCP Professional Cloud Architect** | GCP |
| **HashiCorp Terraform Associate** | IaC |
| **HashiCorp Vault Associate** | Secrets |
| **CNCF Prometheus** | Monitoring |

> 🔑 **TR pazarı**: CKA + AWS SAA en sık. CKS + AWS DevOps Pro **fark yaratır**.

---

## 🤖 ATS (Applicant Tracking System) Uyumu

Çoğu büyük şirket ATS kullanır → CV otomatik parse edilir, keyword eşleşmesine göre filtrelenir.

### Yapma
- ❌ Tablo, sütun, image (parse fail)
- ❌ Renkli pasta grafikler (yetenek bar)
- ❌ Header/footer'da bilgi (genelde okunmaz)
- ❌ Stylized font / Unicode karakterler

### Yap
- ✅ Plain markdown veya Word (PDF tercih)
- ✅ Standard section title (Experience, Skills, Education)
- ✅ Spesifik keyword (job description'dan al)
- ✅ Tek sütun layout

### Keyword optimization
Job description'a bak:
> "We use Kubernetes, Argo CD, Terraform, AWS..."

CV'de bu keyword'ler **görünür yerlerde** olmalı. (Yalan söyleme — gerçekten kullandığın araçlar.)

---

## 🌍 TR Pazarı vs Global Farkları

| Boyut | TR yerli | Global remote |
|---|---|---|
| **Dil** | Türkçe + İngilizce | İngilizce |
| **Photo** | Bazen yer alır | **Asla** (US discrimination law) |
| **Doğum tarihi** | Geleneksel | **Asla** (US discrimination law) |
| **Hobi** | Kişisel ilgi göstergesi | Genelde gereksiz |
| **Maaş** | Beklenti soruluyor | Range önerilir |
| **Sertifika** | "İlerlemek için" işareti | Spesifik teknik için |
| **Açıklama** | Görev listesi yaygın | Etki + sayı zorunlu |

> 🔑 **Global pozisyon için**: photo yok, DOB yok, "personal info" minimum.

---

## 💰 Maaş Müzakeresi (Türkçe Bağlam)

### Önce: market değerini bul
- **Glassdoor** TR — sınırlı veri
- **Levels.fyi** — global, TR remote için iyi
- **CompTechCo** Türkiye SaaS report
- **Reddit r/CSCareerQuestionsTR** — anonymous data
- **LinkedIn salary insights** — pozisyon bazında

### Range belirle
```
Mevcut maaş × 1.20-1.40 (TR yerli içine değişim)
veya
Market median × 1.0-1.15 (yetenek seviyene göre)
```

### Müzakerede
- Range ver (örn: "85-100 net"), tek sayı verme
- Total compensation (bonus, stock, vesting) sor
- Counter-offer geldiğinde 1-2 gün düşünmek normal
- "Mevcut işimde stay-bonus var, decision yapmak için..." — leverage

### TR yerli pazarı 2026 referans (orta-üst pozisyon)
```
Junior DevOps / SRE:           45-75K net/ay
Mid (3-5 yıl):                 75-130K net/ay
Senior (5+ yıl):               130-200K net/ay
Staff / Principal:             200-300K+ net/ay (rare)
Lead / Manager:                160-250K + bonus

Remote global (USD):
Junior:       3-5K USD/ay
Mid:          5-10K USD/ay
Senior:       10-18K USD/ay
Staff:        18-30K+ USD/ay
```

> ⚠️ Bu rakamlar **2026 başı tahmin**. Şirket büyüklüğü, sektör (FinTech > eCommerce > traditional), remote-only vs hybrid → ±%30.

---

## 🎤 LinkedIn Optimization

### Profile
- Photo: profesyonel, gülümseyen, solid background
- Banner: tematik (örn: K8s logosu, kendi blog)
- Headline: SEO + niche
  - ❌ "DevOps Engineer at X"
  - ✅ "Senior SRE → Kubernetes, GitOps, DevSecOps · 8yr · İstanbul / Remote"
- About: 3-4 paragraph, hikâye + etki
- Featured: blog, conference talk, side project

### Activity
- Haftalık 2-3 kısa post (teknik insight)
- Yorum yapmak: pasif takipten daha güçlü
- "Open to work" tag — pasif iken kalsın açık (recruiter görür)

### Connection strategy
- Quality > quantity (1000 random vs 200 alakalı)
- Recruiter'ları kabul et (gelecekteki fırsat)
- Eski meslektaşlarla bağlantıyı sürdür

---

## 🧭 GitHub Profile — Yan CV

### README.md (kişisel repo)
```markdown
# Hi 👋, I'm Halil

Senior SRE focused on K8s, GitOps, DevSecOps.
Building reliable systems @ DevHub.io.

## What I work on
- 🚀 Internal Developer Platform (Backstage + Crossplane)
- 🛡️ DevSecOps pipeline (cosign + Kyverno + Falco)
- 📊 Observability stack (OpenTelemetry + Loki + Tempo)

## Recent writing
- [DevOps Notebook (TR)](https://github.com/.../DevOps) — production-grade Türkçe
- [Blog: Why we migrated from Helm to Kustomize](https://<YOUR_BLOG>/helm-to-kustomize)

## Reach me
- alarm@example.com (general)
- LinkedIn: ...
```

### Pinned repos
- 4-6 tane, kendi yazdığın veya katkıda bulunduğun
- README + clear use case
- Stars önemli ama **gerçek değer** > marketing

### Contribution graph
- Yeşil dolu: aktif geliştirici
- Boş: ilgi azalmış görünür
- **Gerçek katkı**, fake commit yok

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| 5 sayfa CV | Recruiter 30 saniyede karar verir | 1-2 sayfa |
| "Responsible for..." | Pasif, görev | "Led / Built / Reduced..." |
| Sayı yok | "İyi yaptım" sözü | %, $, sayısal etki |
| Tüm tool'lar listesi (50+) | Yüzeysel görünür | Top 15 + level |
| Sertifika spam (10+) | Quantity > quality | 3-5 alakalı sertifika |
| Photo + DOB + medeni durum (global pozisyon) | Discrimination violation | TR-only için OK |
| Türkçe-EN karışık | Tutarsız | Tek dil seç |
| Generic özet | Hedef pozisyona uymuyor | Per-application customize |
| Side project yok | Sadece iş = pasif | Blog / OSS / talk |
| LinkedIn boş | Recruiter göremez | Aktif profil |
| Eski tech listele (Jenkins, Puppet) | "Stuck in past" | Modern tech ön plan |
| ATS-unfriendly format | Filtre kapanır | Plain PDF |

---

## 📋 CV Hazırlama Checklist

```
[ ] 1-2 sayfa, plain PDF
[ ] Özet pozisyona göre customize
[ ] Her bullet STAR + sayı
[ ] Top yetenek kategorize, leveling
[ ] CKA / AWS SAA en az birinin var
[ ] LinkedIn profile güncel
[ ] GitHub README + pinned repos
[ ] Side project / blog / talk
[ ] Recruiter'a gönderirken: cover letter (kısa, 3 paragraf)
[ ] ATS-friendly (table/image yok)
[ ] Job description keyword'leri organic kullanım
[ ] Spell check + Türkçe / EN tutarlı
[ ] Referans listesi hazır (3 kişi)
[ ] Mock interview (peer ile)
[ ] Salary range research (Levels.fyi / Glassdoor)
```

---

## 📚 Referanslar

- **Levels.fyi** — global SWE salary
- **Glassdoor** — şirket kültür + maaş
- **r/CSCareerQuestionsTR** — TR pazarı
- **Pragmatic Engineer Blog** — Gergely Orosz, sektör trend
- **Staff Engineer's Path** — Tanya Reilly
- **The Manager's Path** — Camille Fournier
- [`SRE-Interview-Prep.md`](SRE-Interview-Prep.md)
- [`DevOps-Interview-Questions.md`](DevOps-Interview-Questions.md)
- [`System-Design-Cheatsheet.md`](System-Design-Cheatsheet.md)

---

> *"CV 'kayıt' değil, **pazarlama dokümanıdır**. Recruiter 30
> saniyede karar verir; o saniyelerde **etki + sayı + alakalı
> keyword** görmeyen CV → arşive gider."*
