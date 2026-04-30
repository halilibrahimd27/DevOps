<div align="center">

# 🛠️ DevOps Notebook

### *Production'da işleyen modern DevOps pratiklerinin Türkçe başucu kitabı*

CI/CD · Kubernetes · IaC · GitOps · SRE · DevSecOps · FinOps · Platform Engineering · LLMOps

[![Made with Markdown](https://img.shields.io/badge/Made%20with-Markdown-1f6feb?style=flat-square&logo=markdown&logoColor=white)](#)
[![Topics](https://img.shields.io/badge/topics-19-blueviolet?style=flat-square)](#-içindekiler)
[![Cheatsheets](https://img.shields.io/badge/cheatsheets-9-success?style=flat-square)](16-Cheatsheets/)
[![Templates](https://img.shields.io/badge/copy--paste%20templates-15%2B-orange?style=flat-square)](17-Templates/)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![Awesome](https://awesome.re/badge-flat2.svg)](#)

**Türkçe** · *2026 itibarıyla güncel* · *placeholder'lı, copy-paste güvenli*

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

## 🚀 Hızlı Başlangıç

| Sen kim hissediyorsun? | Buradan başla |
|---|---|
| 🆕 **Yeni başlıyorum, "DevOps nedir?"** | [`RoadMap/Modern-DevOps-2026.md`](RoadMap/Modern-DevOps-2026.md) |
| 🏗️ **Sıfırdan altyapı kuracağım** | [`RoadMap/Advanced RoadMap.md`](RoadMap/Advanced%20RoadMap.md) → [`05-Kubernetes/Production-Checklist.md`](05-Kubernetes/Production-Checklist.md) |
| 🔥 **Şu an yangın söndürüyorum** | [`16-Cheatsheets/`](16-Cheatsheets/) → [`11-SRE/Incident-Response.md`](11-SRE/Incident-Response.md) |
| 📦 **Yeni servis konteynerleştireceğim** | [`04-Containers/Dockerfile-Best-Practices.md`](04-Containers/Dockerfile-Best-Practices.md) → [`17-Templates/dockerfiles/`](17-Templates/dockerfiles/) |
| 🚀 **CI/CD pipeline yazacağım** | [`02-CI-CD/Pipeline-Patterns.md`](02-CI-CD/Pipeline-Patterns.md) → [`17-Templates/github-actions/`](17-Templates/github-actions/) |
| 🛡️ **Güvenlik review'ı geliyor** | [`08-Security/DevSecOps-Pipeline.md`](08-Security/DevSecOps-Pipeline.md) → [`08-Security/Kubernetes-Hardening.md`](08-Security/Kubernetes-Hardening.md) |
| 💰 **Cloud faturası patladı** | [`12-FinOps/Cloud-Cost-Allocation.md`](12-FinOps/Cloud-Cost-Allocation.md) |
| 🎯 **Mülakata hazırlanıyorum** | [`18-Career/`](18-Career/) |

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

### 🧰 Operasyonel Notlar (Mevcut)
| Klasör | Konu |
|---|---|
| [`Ansible/`](Ansible/) | Ansible playbook ve sistem hazırlığı notları |
| [`Kubectl/`](Kubectl/) | Jenkins, logging, secret/credential örnekleri |
| [`Terrafrom/`](Terrafrom/) | Proxmox + manuel VM Terraform örnekleri |
| [`Network/`](Network/) | Wazuh SIEM + ağ segmentasyonu |
| [`monitoring/`](monitoring/) | Prometheus/Grafana/Uptime Kuma stack'i |
| [`databases/`](databases/) | DB'ler için backup/health check/security setup |
| [`nginx/`](nginx/) | NGINX prod konfig örnekleri |
| [`infra-devops/`](infra-devops/) | Azure'da Kubespray + multi-master Kubernetes |
| [`haproxy-openmanager/`](haproxy-openmanager/) | HAProxy yöneticisi |
| [`crypter/`](crypter/) | Config şifreleme yardımcıları |
| [`System/`](System/) | Sistem-seviyesi rehberler |
| [`Testing/`](Testing/) | Draft/test materyali |

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

*Bu repo'nun hedefi: bir DevOps mühendisinin **3 yıl boyunca** açıp baktığında değer bulduğu bir referans olmak.*

**Beğendiyseniz ⭐ verin, eksiği varsa [`Issue`](https://github.com/halilibrahimd27/DevOps/issues) açın.**

</div>
