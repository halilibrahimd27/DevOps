<div align="center">

# 🛠️ DevOps Notebook — Türkçe DevSecOps Rehberi

### *Production'da işleyen modern DevOps + DevSecOps + SRE pratiklerinin Türkçe başucu kitabı*

**Kubernetes · CI/CD · GitOps · DevSecOps · SRE · IaC · Platform Engineering · FinOps · Observability · LLMOps · Compliance**

[![GitHub Stars](https://img.shields.io/github/stars/halilibrahimd27/DevOps?style=for-the-badge&color=yellow&logo=github)](https://github.com/halilibrahimd27/DevOps/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/halilibrahimd27/DevOps?style=for-the-badge&color=blue&logo=github)](https://github.com/halilibrahimd27/DevOps/network/members)
[![GitHub Watchers](https://img.shields.io/github/watchers/halilibrahimd27/DevOps?style=for-the-badge&color=green&logo=github)](https://github.com/halilibrahimd27/DevOps/watchers)
[![Last Commit](https://img.shields.io/github/last-commit/halilibrahimd27/DevOps?style=for-the-badge&color=purple)](https://github.com/halilibrahimd27/DevOps/commits/main)

[![Topics](https://img.shields.io/badge/topics-21-blueviolet?style=flat-square)](#-içindekiler)
[![Deep Dives](https://img.shields.io/badge/deep--dives-125%2B-success?style=flat-square)](#-içindekiler)
[![Cheatsheets](https://img.shields.io/badge/cheatsheets-9-success?style=flat-square)](16-Cheatsheets/)
[![Templates](https://img.shields.io/badge/copy--paste%20templates-25%2B-orange?style=flat-square)](17-Templates/)
[![Lines](https://img.shields.io/badge/markdown-64K%2B%20lines-informational?style=flat-square)](#-içindekiler)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![Awesome](https://awesome.re/badge-flat2.svg)](#)

**🇹🇷 Türkçe** · *2026 itibarıyla güncel* · *placeholder'lı, production-safe*

### **🚀 Türkiye'nin en kapsamlı Türkçe DevSecOps kaynağı**

> **⭐ Yıldız bırakırsan repo daha çok kişiye ulaşır.** Repo'nun büyümesi senin yıldızınla başlar.

[**📚 İçindekiler**](#-içindekiler) · [**🚀 Hızlı Başlangıç**](#-hızlı-başlangıç) · [**🤝 Katkı**](#-katkı) · [**📖 Sözlük**](Glossary.md) · [**📣 Discussions**](https://github.com/halilibrahimd27/DevOps/discussions)

</div>

---

> **Niçin var:** Çoğu DevOps kaynağı ya yüzeysel listedir, ya da
> "müşteri başına bir şirket" tonunda satışçıdır. Bu repo, **production'da
> kafayı yedikten sonra damıtılmış pratikleri** Türkçe ve eylemsel
> tutar. Konferans slaytı değil, oncall'da işine yarayan referans.

> **Kim için:** sıfırdan başlayan bir junior'dan, ekip kurmaya çalışan
> bir staff/principal'a kadar. Her klasör kendi içinde "öğrenme yolu →
> uygulama → cheatsheet → şablon" akışını izler.

---

## 🎯 Bu Repo Sana Ne Verir?

- ✅ **125+ deep-dive doküman** — her biri 250-600 satır, production-tested
- ✅ **64,000+ satır Türkçe içerik** — DevOps + DevSecOps + SRE + Platform
- ✅ **21 ana bölüm** — kültür, Git, CI/CD, IaC, Containers, Kubernetes, GitOps, Observability, Security, Networking, Databases, SRE, FinOps, Platform Engineering, Sustainability, AI/LLMOps, Cheatsheets, Templates, Career, Compliance, Soft Skills
- ✅ **Anti-pattern tablosu** — her dokümanda "yapma" listesi
- ✅ **Production checklist** — "yarın işine başlayabilirsin"
- ✅ **9 cheatsheet** + **25+ copy-paste template** (Kubernetes, GitHub Actions, Dockerfile, Kyverno, runbook)
- ✅ **Compliance**: KVKK, GDPR, ISO 27001, SOC 2, EU AI Act, NIS2, PCI DSS — mühendislik açısından
- ✅ **Soft skills**: oncall sustainability, stakeholder management, mentoring, "hayır" demek, RFC yazımı
- ✅ **TR-spesifik**: Iyzico, BDDK, KVK Kurumu, Wazuh entegrasyonu, TR pazarı maaş context'i

### 🆚 Diğer Türkçe DevOps Kaynakları ile

| Boyut | Bu Repo | Diğerleri (genelde) |
|---|---|---|
| **Derinlik** | 250-600 satır deep-dive | Yüzeysel liste (50-100 satır) |
| **Güncellik** | 2026 (CloudNativePG, Karpenter, OpenTofu, Cilium ambient) | 2020-2022 (eski tool'lar) |
| **DevSecOps kapsamı** | 8 derin doküman (security amiral gemisi) | Genelde 1-2 sayfa |
| **Anti-pattern + Checklist** | Her dokümanda zorunlu | Yok |
| **Compliance (TR/EU)** | KVKK + GDPR + SOC2 + ISO + NIS2 + EU AI Act | Eksik |
| **Soft skills** | 8 doküman (oncall, stakeholder, mentoring) | Yok |
| **Placeholder güvenli** | Gerçek IP/credential yok | Bazen var (kopyala-yapıştır risk) |
| **Glossary** | TR↔EN tam terim sözlüğü | Yok |

---

## 🚀 Hızlı Başlangıç

| Sen kim hissediyorsun? | Buradan başla |
|---|---|
| 🆕 **Yeni başlıyorum, "DevOps nedir?"** | [`RoadMap/Modern-DevOps-2026.md`](RoadMap/Modern-DevOps-2026.md) |
| 🏗️ **Sıfırdan altyapı kuracağım** | [`RoadMap/Advanced RoadMap.md`](RoadMap/Advanced%20RoadMap.md) → [`05-Kubernetes/Production-Checklist.md`](05-Kubernetes/Production-Checklist.md) |
| 🔥 **Şu an yangın söndürüyorum** | [`16-Cheatsheets/`](16-Cheatsheets/) → [`11-SRE/Incident-Response.md`](11-SRE/Incident-Response.md) |
| 📦 **Yeni servis konteynerleştireceğim** | [`04-Containers/Dockerfile-Best-Practices.md`](04-Containers/Dockerfile-Best-Practices.md) → [`17-Templates/dockerfiles/`](17-Templates/dockerfiles/) |
| 🚀 **CI/CD pipeline yazacağım** | [`02-CI-CD/Pipeline-Patterns.md`](02-CI-CD/Pipeline-Patterns.md) → [`17-Templates/github-actions/`](17-Templates/github-actions/) |
| 🛡️ **Güvenlik review'ı geliyor** | [`08-Security/DevSecOps-Pipeline.md`](08-Security/DevSecOps-Pipeline.md) → [`08-Security/Kubernetes-Hardening.md`](08-Security/Kubernetes-Hardening.md) |
| 💰 **Cloud faturası patladı** | [`12-FinOps/Cloud-Cost-Allocation.md`](12-FinOps/Cloud-Cost-Allocation.md) → [`12-FinOps/Right-Sizing.md`](12-FinOps/Right-Sizing.md) |
| 🎯 **Mülakata hazırlanıyorum** | [`18-Career/`](18-Career/) |
| ⚖️ **KVKK/GDPR/SOC2 audit geliyor** | [`19-Compliance/KVKK-Practical.md`](19-Compliance/KVKK-Practical.md) → [`19-Compliance/`](19-Compliance/) |
| 🔥 **On-call'da burnout oluyorum** | [`20-Soft-Skills/Oncall-Sustainability.md`](20-Soft-Skills/Oncall-Sustainability.md) |
| 📖 **Türkçe terim aradım** | [`Glossary.md`](Glossary.md) |
| 🤖 **AI ile DevOps yapmak istiyorum** | [`15-AI-LLMOps/AI-Augmented-Operations.md`](15-AI-LLMOps/AI-Augmented-Operations.md) |
| 📈 **K8s upgrade'i yapacağım** | [`05-Kubernetes/Upgrade-Strategy.md`](05-Kubernetes/Upgrade-Strategy.md) |
| 🌳 **GitOps adopt ediyorum** | [`06-GitOps/ArgoCD-Setup.md`](06-GitOps/ArgoCD-Setup.md) → [`06-GitOps/Flux-vs-ArgoCD.md`](06-GitOps/Flux-vs-ArgoCD.md) |
| 🔍 **Postgres prod'a alıyorum** | [`10-Databases-Production/Postgres-Production-Guide.md`](10-Databases-Production/Postgres-Production-Guide.md) |
| 👀 **Observability stack kuruyorum** | [`07-Observability/OpenTelemetry-Adoption.md`](07-Observability/OpenTelemetry-Adoption.md) |
| 🏗️ **Internal Developer Platform** | [`13-Platform-Engineering/Internal-Developer-Platform.md`](13-Platform-Engineering/Internal-Developer-Platform.md) |
| 🌱 **Yeşil yazılım yapacağım** | [`14-Sustainability/Green-Software-Principles.md`](14-Sustainability/Green-Software-Principles.md) |

---

## 📚 İçindekiler

### 🧭 Yol Haritası & Felsefe
| Bölüm | Konu |
|---|---|
| [`RoadMap/`](RoadMap/) | Yol haritaları + **Modern DevOps 2026** kültür/metodoloji rehberi |
| [`00-Culture/`](00-Culture/) | DevOps kültürü, blameless postmortem, on-call playbook, DORA/SPACE, Team Topologies |

### 🏗️ Build & Ship
| Bölüm | Konu |
|---|---|
| [`01-Git-Workflow/`](01-Git-Workflow/) | Trunk-based, conventional commits, PR/code review checklist |
| [`02-CI-CD/`](02-CI-CD/) | Pipeline pattern'ler, GitHub Actions/GitLab CI tarifleri, caching, reusable workflows |
| [`03-IaC/`](03-IaC/) | Terraform best practices, OpenTofu geçişi, Pulumi vs Terraform, Crossplane |
| [`04-Containers/`](04-Containers/) | Dockerfile best practices, multi-stage, distroless/Chainguard, BuildKit, image imzalama |
| [`05-Kubernetes/`](05-Kubernetes/) | Production checklist, resource limits, HPA/VPA/KEDA, Gateway API, multi-tenancy, upgrade |
| [`06-GitOps/`](06-GitOps/) | ArgoCD setup, Flux vs ArgoCD, ApplicationSet, App-of-Apps |

### 🔭 Run & Observe
| Bölüm | Konu |
|---|---|
| [`07-Observability/`](07-Observability/) | OpenTelemetry, Prometheus best practices, SLO engineering, alerting done right, profiling |
| [`08-Security/`](08-Security/) | DevSecOps pipeline, secrets, image scan, K8s hardening, SLSA/SBOM, OPA/Kyverno, threat modeling |
| [`09-Networking/`](09-Networking/) | Service mesh comparison, Cilium/eBPF, Ingress patterns, DNS strategies |
| [`10-Databases-Production/`](10-Databases-Production/) | Postgres prod guide, backup/restore, HA (Patroni/Stolon), zero-downtime migrations |
| [`11-SRE/`](11-SRE/) | SLI/SLO/error budget, incident response, runbook template, chaos engineering, capacity |
| [`12-FinOps/`](12-FinOps/) | Cost allocation, right-sizing, spot strategy, RI/SP, Kubecost |

### 🌟 Modern Trendler
| Bölüm | Konu |
|---|---|
| [`13-Platform-Engineering/`](13-Platform-Engineering/) | IDP, Backstage, golden paths, service catalog |
| [`14-Sustainability/`](14-Sustainability/) | Green Software Foundation principles, carbon-aware computing, SCI ölçümü |
| [`15-AI-LLMOps/`](15-AI-LLMOps/) | LLM in production, prompt eng for ops, RAG architecture, AI-augmented ops |

### 🎒 Hazır Cebinde
| Bölüm | Konu |
|---|---|
| [`16-Cheatsheets/`](16-Cheatsheets/) | kubectl · docker · git · helm · terraform · aws-cli · linux-troubleshooting · networking · vim |
| [`17-Templates/`](17-Templates/) | GitHub Actions · K8s manifest · Dockerfile · Terraform module · Kyverno policy · runbook |
| [`18-Career/`](18-Career/) | DevOps/SRE interview soruları, system design hazırlığı |

### ⚖️ Hukuki Çerçeve & İnsan Tarafı
| Bölüm | Konu |
|---|---|
| [`19-Compliance/`](19-Compliance/) | KVKK, GDPR, ISO 27001, SOC 2, **EU AI Act**, NIS2, PCI DSS — mühendislik kontrolüyle |
| [`20-Soft-Skills/`](20-Soft-Skills/) | On-call sürdürülebilirliği, stakeholder yönetimi, security ekibi ile çalışma, "hayır" demek |
| [`Glossary.md`](Glossary.md) | Türkçe ↔ İngilizce DevOps terim sözlüğü |
| [`CLAUDE.md`](CLAUDE.md) | Yazım stili & editorial rehber (katkı yapanlar için) |

### 🧰 Operasyonel Notlar
| Klasör | Konu |
|---|---|
| [`Ansible/`](Ansible/) | Ansible playbook ve sistem hazırlığı notları |
| [`Kubectl/`](Kubectl/) | Logging ve secret/credential örnekleri |
| [`Terraform/`](Terraform/) | Proxmox + manuel VM Terraform örnekleri |
| [`Network/`](Network/) | Wazuh SIEM + ağ segmentasyonu |
| [`System/`](System/) | Sistem-seviyesi rehberler (K8s install, GitHub Actions, external access) |

### 🔗 Yan Repolar (bu repo'dan ayrılan tamamlayıcı projeler)

| Repo | Konu |
|---|---|
| **[databases-stack](https://github.com/halilibrahimd27/databases-stack)** | Tek `docker compose up` ile MariaDB+PostgreSQL+MongoDB+Redis self-hosted stack — admin paneller, Prometheus exporters, 15-dakikalık backup automation, Google Drive sync |
| **[file-crypter](https://github.com/halilibrahimd27/file-crypter)** | AES-256 CBC + PBKDF2 ile dosya/klasör şifreleme — terminalden tek komut |
| **[wakapi-admin](https://github.com/halilibrahimd27/wakapi-admin)** | Wakapi self-hosted stack + custom admin panel (realtime active users, domain tag system, AI editor detection) |
| **[api-sentinel](https://github.com/halilibrahimd27/api-sentinel)** | 3. parti API schema değişiklik tespiti — plugin tabanlı, severity-aware monitoring |
| **[cheat-sheet](https://github.com/halilibrahimd27/cheat-sheet)** | Offensive security komut referansı — 2000+ pentest komutu, OSCP/OSWE/OSEP prep |

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
2. **Eylemsel.** Her bölüm "ne yapılacak / nasıl yapılacak / niye yapılacak" sırasıyla yazılır.
3. **Placeholder güvenli.** Hiçbir gerçek IP/domain/credential yer almaz. `<TARGET_IP>`, `<NAMESPACE>`, `<REGISTRY>` gibi yer tutucular kullanılır.
4. **Yorum-yargılı.** Bir tool/paradigma 2026'da artık önerilmiyorsa "bunu yapma" diye söylenir, neutral değildir.
5. **Anti-pattern'leri açıkça yazar.** Doğrudan "şunu yapma" tabloları her klasörde vardır.
6. **Yıldız kovalamaz, faydayı kovalar.** Buzzword listeleri yerine *bugün* açıp uygulanacak adımlar.

---

## 🤝 Katkı

PR'lar memnuniyetle. [`CONTRIBUTING.md`](CONTRIBUTING.md) okuyun.

> 🔍 *Issue açarken:* "Kubernetes hardening'de X eksik" gibi spesifik
> önerin varsa belirt. "Daha çok içerik ekle" tarzı genel issue'lar
> [`good first issue`](https://github.com/halilibrahimd27/DevOps/labels/good%20first%20issue) etiketiyle başkasına paslanır.

## 📜 Lisans

[MIT](LICENSE) — özgürce kullanın, yıldızlamayı unutmayın ⭐

---

<div align="center">

## 🌟 Repo'yu desteklemek istiyorsan

| Süre | Yardımın |
|---|---|
| **5 saniye** | Sağ üstteki **⭐ Star** butonuna tıkla |
| **30 saniye** | Repo'yu Twitter/LinkedIn/Slack'te paylaş |
| **5 dakika** | Eksik bulduğun bir konu için [issue](../../issues/new/choose) aç |
| **30 dakika** | Bir cheatsheet'e katkı PR'ı |
| **2 saat** | Yeni bir deep-dive yaz, [`CONTRIBUTING.md`](CONTRIBUTING.md) okuyup PR aç |

---

*Bu repo'nun hedefi: bir DevOps mühendisinin **3 yıl boyunca** açıp baktığında değer bulduğu bir referans olmak.*

**Star history:**

[![Star History Chart](https://api.star-history.com/svg?repos=halilibrahimd27/DevOps&type=Date)](https://star-history.com/#halilibrahimd27/DevOps&Date)

</div>

---

<details>
<summary><strong>🔍 Keywords (Google + GitHub Search için)</strong></summary>

Türkçe DevOps rehberi · Türkçe DevSecOps · Kubernetes Türkçe · DevOps mülakat · SRE rehberi · GitOps Türkçe · CI/CD pipeline Türkçe · Docker best practices Türkçe · Helm vs Kustomize · ArgoCD setup · Flux vs ArgoCD · Postgres production · CloudNativePG · Patroni HA · Prometheus best practices · OpenTelemetry · Grafana Loki Tempo · SLO error budget · incident response · postmortem template · chaos engineering · KVKK uyumu · GDPR mühendislik · ISO 27001 · SOC 2 Type II · EU AI Act · NIS2 directive · PCI DSS v4 · Backstage IDP · Internal Developer Platform · platform engineering · golden path · service catalog · FinOps Türkçe · Kubecost · spot instance · savings plan · right-sizing · sustainability · green software · carbon-aware computing · LLMOps · RAG architecture · prompt engineering · vLLM · self-hosted LLM · Cilium eBPF · Gateway API · service mesh · zero trust networking · cosign image signing · SLSA SBOM · Kyverno OPA · threat modeling · STRIDE LINDDUN · Falco runtime security · Trivy vulnerability scanning · Vault secrets management · External Secrets Operator · trunk-based development · conventional commits · stacked diffs · code review · oncall sustainability · stakeholder management · mentoring junior · DevOps cheatsheet · K8s production checklist · DevOps interview Turkish · SRE interview · system design Türkçe.

</details>

<div align="center">

**🇹🇷 Made with discipline in Türkiye · 2026**

</div>

