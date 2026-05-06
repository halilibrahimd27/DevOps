---
hide:
  - toc
  - navigation
title: Ana Sayfa
description: >-
  Production'da işleyen modern DevOps + DevSecOps + SRE pratiklerinin Türkçe başucu kitabı.
  Junior'dan principal'a · 21 konu · 125+ deep-dive · 65K+ satır · MIT lisans.
---

<div class="hero" markdown>

# DevOps Notebook { .hero__title }

### Türkçe DevOps · DevSecOps · SRE · Platform Engineering başucu kitabı { .hero__subtitle }

Production'da kafayı yedikten sonra damıtılmış pratikler. Konferans slaytı değil, **oncall'da işine yarayan referans**.

[:material-rocket-launch: Hızlı başla](#hizli-basla){ .md-button .md-button--primary }
[:material-github: GitHub'da gör](https://github.com/halilibrahimd27/DevOps){ .md-button }
[:material-star: Yıldız bırak ⭐](https://github.com/halilibrahimd27/DevOps/stargazers){ .md-button }

</div>

<div class="hero-stats" markdown>

| | | | | |
|---|---|---|---|---|
| **21** | **125+** | **9** | **25+** | **65K+** |
| ana bölüm | deep-dive | cheatsheet | template | satır |

</div>

---

## :material-help-circle-outline: Bu repo neden var?

Çoğu Türkçe DevOps kaynağı ya yüzeysel listedir, ya "müşteri başına bir şirket" tonunda satışçıdır. Bu repo ne ikincisidir, ne de "modern dünyada artık geleneksel yaklaşımlar..." tarzında LLM lapa ses tonuyla yazılmıştır.

<div class="grid cards" markdown>

-   :material-target:{ .lg .middle } __Eylemsel__

    ---

    Her bölüm "ne yapılacak / nasıl yapılacak / niye yapılacak" sırasıyla. Buzzword listesi yok, *bugün* açıp uygulanacak adımlar var.

-   :material-shield-lock-outline:{ .lg .middle } __Placeholder güvenli__

    ---

    Gerçek IP/credential yok. `<TARGET_IP>`, `<NAMESPACE>`, `<KMS_KEY_ID>` placeholder konvansiyonu. CI'da otomatik enforce.

-   :material-flag-checkered:{ .lg .middle } __2026 stack__

    ---

    CloudNativePG, Karpenter, OpenTofu, Cilium ambient, Gateway API, vLLM. Eskimiş tool tavsiyesi yok.

-   :material-account-tie:{ .lg .middle } __Junior → Principal__

    ---

    Her klasör "öğrenme yolu → uygulama → cheatsheet → şablon" akışını izler. Sıfırdan başlayan da, ekip kuran da kullanır.

-   :material-thumbs-up-down-outline:{ .lg .middle } __Yorum-yargılı__

    ---

    Bir tool 2026'da artık önerilmiyorsa "yapma" denir. Neutral değil. PSP yasak, Helm + Kustomize OK, Spinnaker uzak dur.

-   :material-flag-tr:{ .lg .middle } __Türkçe ve TR-spesifik__

    ---

    KVKK, BDDK, Wazuh entegrasyonu, Iyzico stack notları, TR maaş context'i. Sadece İngilizce çeviri değil — yerel mühendislik.

</div>

---

## :material-rocket: Hızlı başla { #hizli-basla }

Sen kim hissediyorsun, oradan başla:

<div class="grid cards" markdown>

-   :material-account-school:{ .lg .middle } __Yeni başlıyorum__

    ---

    "DevOps nedir, nereden başlamalı?"

    [:octicons-arrow-right-24: Modern DevOps 2026 yol haritası](RoadMap/Modern-DevOps-2026.md)

-   :material-fire:{ .lg .middle } __Yangın söndürüyorum__

    ---

    Şu an production'da bir şey patladı.

    [:octicons-arrow-right-24: Incident Response](11-SRE/Incident-Response.md)
    · [:octicons-arrow-right-24: Cheatsheets](16-Cheatsheets/)

-   :material-package-variant:{ .lg .middle } __Yeni servis kuracağım__

    ---

    Konteyner + K8s + CI/CD pipeline.

    [:octicons-arrow-right-24: K8s Production Checklist](05-Kubernetes/Production-Checklist.md)

-   :material-shield-lock:{ .lg .middle } __Güvenlik review geliyor__

    ---

    DevSecOps, K8s hardening, SLSA/SBOM.

    [:octicons-arrow-right-24: DevSecOps Pipeline](08-Security/DevSecOps-Pipeline.md)

-   :material-cash-multiple:{ .lg .middle } __Cloud faturası patladı__

    ---

    FinOps cost allocation, right-sizing, spot strategy.

    [:octicons-arrow-right-24: FinOps başlangıç](12-FinOps/Cloud-Cost-Allocation.md)

-   :material-scale-balance:{ .lg .middle } __KVKK / GDPR / SOC2 audit__

    ---

    Compliance mühendislik kontrolüyle.

    [:octicons-arrow-right-24: KVKK Practical](19-Compliance/KVKK-Practical.md)

-   :material-database:{ .lg .middle } __Postgres prod'a alıyorum__

    ---

    Patroni HA, zero-downtime migration.

    [:octicons-arrow-right-24: Postgres Guide](10-Databases-Production/Postgres-Production-Guide.md)

-   :material-eye:{ .lg .middle } __Observability stack__

    ---

    OpenTelemetry, Prometheus, SLO.

    [:octicons-arrow-right-24: OTel Adoption](07-Observability/OpenTelemetry-Adoption.md)

-   :material-account-heart-outline:{ .lg .middle } __Oncall burnout__

    ---

    Soft skills, oncall sürdürülebilirliği.

    [:octicons-arrow-right-24: Oncall Sustainability](20-Soft-Skills/Oncall-Sustainability.md)

</div>

---

## :material-bookshelf: Kategoriler

<div class="grid cards" markdown>

-   :material-account-group: __Kültür & İnsan__

    ---

    DORA/SPACE, Team Topologies, blameless postmortem, on-call kültürü.

    [:octicons-arrow-right-24: 00 — Kültür](00-Culture/)

-   :material-source-branch: __Build & Ship__

    ---

    Git/Trunk-based, CI/CD, IaC, Containers, Kubernetes, GitOps.

    [01 — Git](01-Git-Workflow/) · [02 — CI/CD](02-CI-CD/) · [03 — IaC](03-IaC/)

    [04 — Containers](04-Containers/) · [05 — K8s](05-Kubernetes/) · [06 — GitOps](06-GitOps/)

-   :material-eye-outline: __Run & Observe__

    ---

    Observability, Security, Networking, Databases, SRE.

    [07 — Observability](07-Observability/) · [08 — Security](08-Security/) · [09 — Networking](09-Networking/)

    [10 — Databases](10-Databases-Production/) · [11 — SRE](11-SRE/)

-   :material-trending-up: __Modern Trendler__

    ---

    FinOps, Platform Engineering, Sustainability, AI/LLMOps.

    [12 — FinOps](12-FinOps/) · [13 — Platform](13-Platform-Engineering/)

    [14 — Sustainability](14-Sustainability/) · [15 — AI/LLMOps](15-AI-LLMOps/)

-   :material-toolbox: __Hazır Cebinde__

    ---

    9 cheatsheet, 25+ production-ready template, kariyer hazırlığı.

    [16 — Cheatsheets](16-Cheatsheets/) · [17 — Templates](17-Templates/) · [18 — Career](18-Career/)

-   :material-scale-balance: __Hukuki & Soft Skills__

    ---

    KVKK · GDPR · ISO 27001 · SOC 2 · oncall sustainability · stakeholder.

    [19 — Compliance](19-Compliance/) · [20 — Soft Skills](20-Soft-Skills/)

</div>

---

## :material-vs: Farkı ne?

| Boyut | Bu Repo | Diğer TR DevOps kaynakları |
|---|---|---|
| **Derinlik** | 250-600 satır deep-dive | 50-100 satırlık liste |
| **Güncellik** | 2026 (CloudNativePG, Karpenter, OpenTofu, Cilium ambient) | 2020-2022 (eski tool) |
| **DevSecOps** | 10 derin doküman | 1-2 sayfa |
| **Anti-pattern + Checklist** | Her dokümanda zorunlu | Yok |
| **Compliance (TR/EU)** | KVKK + GDPR + SOC2 + ISO + NIS2 + EU AI Act | Eksik |
| **Soft skills** | 9 doküman | Yok |
| **Placeholder güvenli** | Gerçek IP/credential yok | Bazen var (kopya-yapıştır risk) |
| **Glossary** | TR↔EN tam terim sözlüğü | Yok |

---

## :material-handshake: Katkı

PR memnuniyetle. [`CONTRIBUTING.md`](https://github.com/halilibrahimd27/DevOps/blob/main/CONTRIBUTING.md) okuyun. Stil rehberi: [`CLAUDE.md`](https://github.com/halilibrahimd27/DevOps/blob/main/CLAUDE.md).

> :material-lightbulb-on-outline: **Issue açarken**: "K8s hardening'de X eksik" gibi spesifik öneri ver. Genel "daha çok içerik ekle" issue'ları otomatik [`good first issue`](https://github.com/halilibrahimd27/DevOps/labels/good%20first%20issue) etiketine paslanır.

| Süre | Yardımın |
|---|---|
| **5 sn** | Sağ üstteki :material-star: butonu |
| **30 sn** | Repo'yu LinkedIn/X/Slack'te paylaş |
| **5 dk** | Eksik bulduğun konu için [issue aç](https://github.com/halilibrahimd27/DevOps/issues/new/choose) |
| **30 dk** | Bir cheatsheet'e PR |
| **2 saat** | Yeni bir deep-dive — `CONTRIBUTING.md` okuyup PR aç |

---

<p class="footer-quote" markdown>
*Bu repo'nun hedefi: bir DevOps mühendisinin **3 yıl boyunca** açıp baktığında değer bulduğu bir referans olmak.*

**:material-flag-tr: Made with discipline in Türkiye · 2026**
</p>
