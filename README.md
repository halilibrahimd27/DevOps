<div align="center">

# 🛠️ The DevSecOps Handbook

*Production'a yönelik modern DevOps · DevSecOps · SRE pratikleri — derin TR/EU regülasyon kapsamıyla, eylemsel bir handbook.*

Kubernetes · CI/CD · GitOps · IaC · Observability · Security · SRE · Platform Engineering · FinOps · LLMOps · Compliance

[![Site](https://img.shields.io/badge/canlı_site-halilibrahimd27.github.io%2Fdevsecops-handbook-8A2BE2?style=flat-square)](https://halilibrahimd27.github.io/devsecops-handbook/)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/halilibrahimd27/devsecops-handbook?style=flat-square)](https://github.com/halilibrahimd27/devsecops-handbook/commits/main)

[Site](https://halilibrahimd27.github.io/devsecops-handbook/) · [İçindekiler](#-i̇çindekiler) · [Hızlı Başlangıç](#-hızlı-başlangıç) · [Sözlük](Glossary.md) · [Katkı](CONTRIBUTING.md)

</div>

---

> **Niçin var:** Çoğu DevOps kaynağı ya yüzeysel bir listedir, ya da satışçı
> bir tondadır. Bu repo, production senaryolarına göre yazılmış ve gerçek kurulum
> deneyimiyle ([21-Field-Notes](21-Field-Notes/)) desteklenen pratikleri Türkçe ve
> eylemsel tutar. Konferans slaytı değil, on-call'da işine yarayan referans.

> **Kim için:** sıfırdan başlayan bir junior'dan, ekip kuran bir staff/principal'a
> kadar. Her bölüm "öğren → uygula → cheatsheet → şablon" akışını izler.

---

## 🎯 Ne içerir

- **125 deep-dive doküman** — çoğu 250-600 satır, eylemsel ve yargılı
- **~66.000 satır** Türkçe içerik — DevOps + DevSecOps + SRE + Platform
- **21 ana konu** (00–20) + **Saha Notları** + **Yol Haritası**
- Her deep-dive'da **anti-pattern tablosu** ("yapma" listesi) ve **production checklist**
- **9 cheatsheet** + **19 kopyala-yapıştır şablon** (Kubernetes, GitHub Actions, Dockerfile, Kyverno, runbook)
- **Compliance**: KVKK, GDPR, ISO 27001, SOC 2, EU AI Act, NIS2, PCI DSS — mühendislik kontrolleriyle
- **Soft skills**: on-call sürdürülebilirliği, stakeholder yönetimi, mentoring, "hayır" demek, RFC yazımı
- **TR-spesifik**: KVKK, BDDK, yerli vendor ve TR pazarı bağlamı

---

## 🚀 Hızlı Başlangıç

| Durumun | Buradan başla |
|---|---|
| 🆕 **"DevOps nedir?" — yeni başlıyorum** | [RoadMap/Modern-DevOps-2026.md](RoadMap/Modern-DevOps-2026.md) |
| 🏗️ **Sıfırdan altyapı kuracağım** | [RoadMap/advanced-roadmap.md](RoadMap/advanced-roadmap.md) → [05-Kubernetes/Production-Checklist.md](05-Kubernetes/Production-Checklist.md) |
| 🔥 **Şu an yangın söndürüyorum** | [16-Cheatsheets/](16-Cheatsheets/) → [11-SRE/Incident-Response.md](11-SRE/Incident-Response.md) |
| 📦 **Yeni servis konteynerleştireceğim** | [04-Containers/Dockerfile-Best-Practices.md](04-Containers/Dockerfile-Best-Practices.md) → [17-Templates/dockerfiles/](17-Templates/dockerfiles/) |
| 🚀 **CI/CD pipeline yazacağım** | [02-CI-CD/Pipeline-Patterns.md](02-CI-CD/Pipeline-Patterns.md) → [17-Templates/github-actions/](17-Templates/github-actions/) |
| 🛡️ **Güvenlik review'ı geliyor** | [08-Security/DevSecOps-Pipeline.md](08-Security/DevSecOps-Pipeline.md) → [08-Security/Kubernetes-Hardening.md](08-Security/Kubernetes-Hardening.md) |
| 💰 **Cloud faturası patladı** | [12-FinOps/Cloud-Cost-Allocation.md](12-FinOps/Cloud-Cost-Allocation.md) → [12-FinOps/Right-Sizing.md](12-FinOps/Right-Sizing.md) |
| 🎯 **Mülakata hazırlanıyorum** | [18-Career/](18-Career/) |
| ⚖️ **KVKK/GDPR/SOC2 audit geliyor** | [19-Compliance/KVKK-Practical.md](19-Compliance/KVKK-Practical.md) → [19-Compliance/](19-Compliance/) |
| 🪫 **On-call'da tükeniyorum** | [20-Soft-Skills/Oncall-Sustainability.md](20-Soft-Skills/Oncall-Sustainability.md) |
| 📖 **Türkçe terim aradım** | [Glossary.md](Glossary.md) |
| 🤖 **AI ile DevOps yapmak istiyorum** | [15-AI-LLMOps/AI-Augmented-Operations.md](15-AI-LLMOps/AI-Augmented-Operations.md) |
| 📈 **K8s upgrade'i yapacağım** | [05-Kubernetes/Upgrade-Strategy.md](05-Kubernetes/Upgrade-Strategy.md) |
| 🌳 **GitOps adopt ediyorum** | [06-GitOps/ArgoCD-Setup.md](06-GitOps/ArgoCD-Setup.md) → [06-GitOps/Flux-vs-ArgoCD.md](06-GitOps/Flux-vs-ArgoCD.md) |
| 🔍 **Postgres prod'a alıyorum** | [10-Databases-Production/Postgres-Production-Guide.md](10-Databases-Production/Postgres-Production-Guide.md) |
| 👀 **Observability stack kuruyorum** | [07-Observability/OpenTelemetry-Adoption.md](07-Observability/OpenTelemetry-Adoption.md) |
| 🧩 **Internal Developer Platform** | [13-Platform-Engineering/Internal-Developer-Platform.md](13-Platform-Engineering/Internal-Developer-Platform.md) |
| 🌱 **Yeşil yazılım yapacağım** | [14-Sustainability/Green-Software-Principles.md](14-Sustainability/Green-Software-Principles.md) |

---

## 📚 İçindekiler

### 🧭 Yol Haritası & Felsefe
| Bölüm | Konu |
|---|---|
| [RoadMap/](RoadMap/) | Yol haritaları + **Modern DevOps 2026** kültür/metodoloji rehberi + 28 günlük AWS/EKS implementation |
| [00-Culture/](00-Culture/) | DevOps kültürü, blameless postmortem, on-call playbook, DORA/SPACE, Team Topologies |

### 🏗️ Build & Ship
| Bölüm | Konu |
|---|---|
| [01-Git-Workflow/](01-Git-Workflow/) | Trunk-based, conventional commits, PR/code review checklist |
| [02-CI-CD/](02-CI-CD/) | Pipeline pattern'ler, GitHub Actions/GitLab CI tarifleri, caching, reusable workflows |
| [03-IaC/](03-IaC/) | Terraform best practices, OpenTofu geçişi, Pulumi vs Terraform, Crossplane |
| [04-Containers/](04-Containers/) | Dockerfile best practices, multi-stage, distroless/Chainguard, BuildKit, image imzalama |
| [05-Kubernetes/](05-Kubernetes/) | Production checklist, resource limits, HPA/VPA/KEDA, Gateway API, multi-tenancy, upgrade |
| [06-GitOps/](06-GitOps/) | ArgoCD setup, Flux vs ArgoCD, ApplicationSet, App-of-Apps |

### 🔭 Run & Observe
| Bölüm | Konu |
|---|---|
| [07-Observability/](07-Observability/) | OpenTelemetry, Prometheus best practices, SLO engineering, alerting, profiling |
| [08-Security/](08-Security/) | DevSecOps pipeline, secrets, image scan, K8s hardening, SLSA/SBOM, OPA/Kyverno, threat modeling |
| [09-Networking/](09-Networking/) | Service mesh comparison, Cilium/eBPF, Ingress patterns, DNS strategies |
| [10-Databases-Production/](10-Databases-Production/) | Postgres prod guide, backup/restore, HA (Patroni/Stolon), zero-downtime migrations |
| [11-SRE/](11-SRE/) | SLI/SLO/error budget, incident response, runbook template, chaos engineering, capacity |
| [12-FinOps/](12-FinOps/) | Cost allocation, right-sizing, spot strategy, RI/SP, Kubecost |

### 🌟 Modern Trendler
| Bölüm | Konu |
|---|---|
| [13-Platform-Engineering/](13-Platform-Engineering/) | IDP, Backstage, golden paths, service catalog |
| [14-Sustainability/](14-Sustainability/) | Green Software Foundation principles, carbon-aware computing, SCI ölçümü |
| [15-AI-LLMOps/](15-AI-LLMOps/) | LLM in production, prompt engineering for ops, RAG architecture, AI-augmented ops |

### 🎒 Hazır Cebinde
| Bölüm | Konu |
|---|---|
| [16-Cheatsheets/](16-Cheatsheets/) | kubectl · docker · git · helm · terraform · aws-cli · linux-troubleshooting · networking · vim |
| [17-Templates/](17-Templates/) | GitHub Actions · K8s manifest · Dockerfile · Terraform module · Kyverno policy · runbook |
| [18-Career/](18-Career/) | DevOps/SRE mülakat soruları, system design hazırlığı |

### ⚖️ Hukuki Çerçeve & İnsan Tarafı
| Bölüm | Konu |
|---|---|
| [19-Compliance/](19-Compliance/) | KVKK, GDPR, ISO 27001, SOC 2, **EU AI Act**, NIS2, PCI DSS — mühendislik kontrolüyle |
| [20-Soft-Skills/](20-Soft-Skills/) | On-call sürdürülebilirliği, stakeholder yönetimi, security ekibiyle çalışma, "hayır" demek |
| [Glossary.md](Glossary.md) | Türkçe ↔ İngilizce DevOps terim sözlüğü |
| [CLAUDE.md](CLAUDE.md) | Yazım stili & editorial rehber (katkı yapanlar için) |

### 🗒️ Saha Notları
| Bölüm | Konu |
|---|---|
| [21-Field-Notes/](21-Field-Notes/) | Gerçek kurulumlardan ham notlar: Ansible hazırlık, Terraform/Proxmox, K8s install, Wazuh SIEM, kubectl. Cilalı deep-dive değil; "olduğu gibi çalışan" saha kayıtları. |

---

## 🗺️ Görsel Mimari Haritası

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            CULTURE  &  PEOPLE                            │
│       Trunk-based  ·  Blameless PM  ·  DORA/SPACE  ·  CALMS              │
└─────────────────────────────────────────────────────────────────────────┘
        │                      │                          │
        ▼                      ▼                          ▼
┌──────────────┐      ┌──────────────────┐       ┌──────────────────┐
│   BUILD      │      │     SHIP         │       │       RUN        │
│              │      │                  │       │                  │
│  Git +       │      │  CI/CD pipeline  │       │  Kubernetes      │
│  Conventional│      │  Image build &   │       │  GitOps reconcile│
│  commits     │      │  sign (cosign)   │       │  Service Mesh    │
│  PR review   │ ───▶ │  IaC plan/apply  │ ────▶ │  HPA / KEDA      │
│  Lint/test   │      │  ArgoCD sync     │       │                  │
│              │      │  Progressive del │       │  ┌────────────┐  │
└──────────────┘      └──────────────────┘       │  │ Workloads  │  │
                                                  │  └─────┬──────┘  │
                                                  └────────┼─────────┘
                                                           ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       OBSERVE  &  IMPROVE                                │
│   OpenTelemetry  →  Metrics / Logs / Traces / Profiles                  │
│   SLO + Error Budget  ·  Alerting  ·  Postmortem  ·  Chaos              │
└─────────────────────────────────────────────────────────────────────────┘
        │                      │                          │
        ▼                      ▼                          ▼
┌──────────────┐      ┌──────────────────┐       ┌──────────────────┐
│   SECURE     │      │    OPTIMIZE      │       │    EVOLVE        │
│              │      │                  │       │                  │
│  DevSecOps   │      │   FinOps         │       │  Platform Eng    │
│  Shift-left  │      │  Right-sizing    │       │   IDP / Backstage│
│  SBOM/SLSA   │      │  Spot · RI/SP    │       │   Golden paths   │
│  Policy-as-  │      │  Cost allocation │       │   LLMOps         │
│  Code (OPA/  │      │                  │       │   Sustainability │
│  Kyverno)    │      │                  │       │                  │
└──────────────┘      └──────────────────┘       └──────────────────┘
```

---

## ⭐ Repo Felsefesi

1. **Türkçe yazılır.** Çeviriden kaybolan nüansların yeri yok.
2. **Eylemsel.** Her bölüm "ne / nasıl / niye" sırasıyla yazılır.
3. **Placeholder güvenli.** Gerçek IP/domain/credential yer almaz; `<TARGET_IP>`, `<NAMESPACE>`, `<REGISTRY>` gibi yer tutucular kullanılır.
4. **Yargılı.** Bir tool/paradigma 2026'da önerilmiyorsa "bunu yapma" diye yazılır; nötr değildir.
5. **Anti-pattern açık.** "Şunu yapma" tabloları her deep-dive'da vardır.
6. **Fayda odaklı.** Buzzword listesi değil, bugün açıp uygulanacak adımlar.

---

## 🔗 Yan Repolar

Bu repodan ayrılan tamamlayıcı projeler:

| Repo | Konu |
|---|---|
| [databases-stack](https://github.com/halilibrahimd27/databases-stack) | Tek `docker compose up` ile MariaDB+PostgreSQL+MongoDB+Redis self-hosted stack — admin paneller, Prometheus exporter, otomatik backup |
| [file-crypter](https://github.com/halilibrahimd27/file-crypter) | AES-256 CBC + PBKDF2 ile dosya/klasör şifreleme — terminalden tek komut |
| [wakapi-admin](https://github.com/halilibrahimd27/wakapi-admin) | Wakapi self-hosted stack + custom admin panel |
| [api-sentinel](https://github.com/halilibrahimd27/api-sentinel) | 3. parti API schema değişiklik tespiti — plugin tabanlı, severity-aware |
| [cheat-sheet](https://github.com/halilibrahimd27/cheat-sheet) | Offensive security komut referansı — OSCP/OSWE/OSEP hazırlık |

---

## 🤝 Katkı

PR'lar memnuniyetle. Önce [CONTRIBUTING.md](CONTRIBUTING.md) ve yazım rehberi [CLAUDE.md](CLAUDE.md)'yi oku.

> *Issue açarken spesifik ol:* "Kubernetes hardening'de X eksik" gibi. "Daha çok içerik ekle" tarzı genel issue'lar [good first issue](https://github.com/halilibrahimd27/devsecops-handbook/labels/good%20first%20issue) etiketiyle paslanır.

## 📜 Lisans

[MIT](LICENSE) — özgürce kullan.

---

*Hedef: bir DevOps mühendisinin yıllar boyunca açıp baktığında değer bulduğu bir referans olmak.*

Yazan & sürdüren: **Halil İbrahim Dürmüş** — [@halilibrahimd27](https://github.com/halilibrahimd27) · [LinkedIn](https://www.linkedin.com/in/halilibrahimd)
