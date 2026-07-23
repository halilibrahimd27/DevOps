<div align="center">

# 🛠️ The DevSecOps Handbook

*Production-focused modern DevOps · DevSecOps · SRE practices — an actionable handbook with deep TR/EU regulatory coverage.*

Kubernetes · CI/CD · GitOps · IaC · Observability · Security · SRE · Platform Engineering · FinOps · LLMOps · Compliance

[![Site](https://img.shields.io/badge/canlı_site-halilibrahimd27.github.io%2Fdevsecops-handbook-8A2BE2?style=flat-square)](https://halilibrahimd27.github.io/devsecops-handbook/)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/halilibrahimd27/devsecops-handbook?style=flat-square)](https://github.com/halilibrahimd27/devsecops-handbook/commits/main)

[Site](https://halilibrahimd27.github.io/devsecops-handbook/) · [Table of Contents](#-table-of-contents) · [Quick Start](#-quick-start) · [Glossary](Glossary.md) · [Contributing](CONTRIBUTING.md)

</div>

---

> **Why it exists:** Most DevOps resources are either a shallow list or
> written in a sales pitch tone. This repo keeps practices grounded in
> production scenarios and backed by real deployment experience
> ([21-Field-Notes](21-Field-Notes/)) — actionable, not a conference slide
> deck. It's the reference that's actually useful during an on-call shift.

> **Who it's for:** from a junior starting from zero to a staff/principal
> engineer building out a team. Every section follows the "learn → apply →
> cheatsheet → template" flow.

---

## 🎯 What's inside

- **125 deep-dive documents** — most 250-600 lines, actionable and opinionated
- **~66,000 lines** of content — DevOps + DevSecOps + SRE + Platform
- **21 main topics** (00–20) + **Field Notes** + **Roadmap**
- Every deep-dive has an **anti-pattern table** (a "don't do this" list) and a **production checklist**
- **9 cheatsheets** + **19 copy-paste templates** (Kubernetes, GitHub Actions, Dockerfile, Kyverno, runbook)
- **Compliance**: KVKK, GDPR, ISO 27001, SOC 2, EU AI Act, NIS2, PCI DSS — with engineering controls
- **Soft skills**: on-call sustainability, stakeholder management, mentoring, saying "no", writing RFCs
- **TR/EU-specific**: KVKK, BDDK, local vendor and Turkish market context

---

## 🚀 Quick Start

| Your situation | Start here |
|---|---|
| 🎓 **I'm starting from zero, guide me** | **[22-Learning-Path/](22-Learning-Path/README.md)** — a curriculum that never leaves you asking "what now": read → build → verify → next module |
| 🗺️ **Bird's-eye view of the field — "what's used in 2026?"** | [RoadMap/Modern-DevOps-2026.md](RoadMap/Modern-DevOps-2026.md) |
| 🏗️ **I'm building infrastructure from scratch** | [RoadMap/advanced-roadmap.md](RoadMap/advanced-roadmap.md) → [05-Kubernetes/Production-Checklist.md](05-Kubernetes/Production-Checklist.md) |
| 🔥 **I'm firefighting right now** | [16-Cheatsheets/](16-Cheatsheets/) → [11-SRE/Incident-Response.md](11-SRE/Incident-Response.md) |
| 📦 **I'm containerizing a new service** | [04-Containers/Dockerfile-Best-Practices.md](04-Containers/Dockerfile-Best-Practices.md) → [17-Templates/dockerfiles/](17-Templates/dockerfiles/) |
| 🚀 **I'm writing a CI/CD pipeline** | [02-CI-CD/Pipeline-Patterns.md](02-CI-CD/Pipeline-Patterns.md) → [17-Templates/github-actions/](17-Templates/github-actions/) |
| 🛡️ **A security review is coming up** | [08-Security/DevSecOps-Pipeline.md](08-Security/DevSecOps-Pipeline.md) → [08-Security/Kubernetes-Hardening.md](08-Security/Kubernetes-Hardening.md) |
| 💰 **The cloud bill blew up** | [12-FinOps/Cloud-Cost-Allocation.md](12-FinOps/Cloud-Cost-Allocation.md) → [12-FinOps/Right-Sizing.md](12-FinOps/Right-Sizing.md) |
| 🎯 **I'm prepping for an interview** | [18-Career/](18-Career/) |
| ⚖️ **A KVKK/GDPR/SOC2 audit is coming up** | [19-Compliance/KVKK-Practical.md](19-Compliance/KVKK-Practical.md) → [19-Compliance/](19-Compliance/) |
| 🪫 **I'm burning out on-call** | [20-Soft-Skills/Oncall-Sustainability.md](20-Soft-Skills/Oncall-Sustainability.md) |
| 📖 **I looked up a Turkish term** | [Glossary.md](Glossary.md) |
| 🤖 **I want to use AI for DevOps** | [15-AI-LLMOps/AI-Augmented-Operations.md](15-AI-LLMOps/AI-Augmented-Operations.md) |
| 📈 **I'm doing a K8s upgrade** | [05-Kubernetes/Upgrade-Strategy.md](05-Kubernetes/Upgrade-Strategy.md) |
| 🌳 **I'm adopting GitOps** | [06-GitOps/ArgoCD-Setup.md](06-GitOps/ArgoCD-Setup.md) → [06-GitOps/Flux-vs-ArgoCD.md](06-GitOps/Flux-vs-ArgoCD.md) |
| 🔍 **I'm taking Postgres to production** | [10-Databases-Production/Postgres-Production-Guide.md](10-Databases-Production/Postgres-Production-Guide.md) |
| 👀 **I'm setting up an observability stack** | [07-Observability/OpenTelemetry-Adoption.md](07-Observability/OpenTelemetry-Adoption.md) |
| 🧩 **Internal Developer Platform** | [13-Platform-Engineering/Internal-Developer-Platform.md](13-Platform-Engineering/Internal-Developer-Platform.md) |
| 🌱 **I'm doing green software** | [14-Sustainability/Green-Software-Principles.md](14-Sustainability/Green-Software-Principles.md) |

---

## 📚 Table of Contents

### 🧭 Roadmap & Philosophy
| Section | Topic |
|---|---|
| [22-Learning-Path/](22-Learning-Path/) | 🎓 **Learning Path** — a curriculum a complete beginner can follow without getting lost: 6 blocks, 29 modules, labs + broken labs + certification gates (read → build → verify) |
| [RoadMap/](RoadMap/) | Roadmaps + the **Modern DevOps 2026** culture/methodology guide + a 28-day AWS/EKS implementation |
| [00-Culture/](00-Culture/) | DevOps culture, blameless postmortems, on-call playbook, DORA/SPACE, Team Topologies |

### 🏗️ Build & Ship
| Section | Topic |
|---|---|
| [01-Git-Workflow/](01-Git-Workflow/) | Trunk-based, conventional commits, PR/code review checklist |
| [02-CI-CD/](02-CI-CD/) | Pipeline patterns, GitHub Actions/GitLab CI recipes, caching, reusable workflows |
| [03-IaC/](03-IaC/) | Terraform best practices, migrating to OpenTofu, Pulumi vs Terraform, Crossplane |
| [04-Containers/](04-Containers/) | Dockerfile best practices, multi-stage builds, distroless/Chainguard, BuildKit, image signing |
| [05-Kubernetes/](05-Kubernetes/) | Production checklist, resource limits, HPA/VPA/KEDA, Gateway API, multi-tenancy, upgrades |
| [06-GitOps/](06-GitOps/) | ArgoCD setup, Flux vs ArgoCD, ApplicationSet, App-of-Apps |

### 🔭 Run & Observe
| Section | Topic |
|---|---|
| [07-Observability/](07-Observability/) | OpenTelemetry, Prometheus best practices, SLO engineering, alerting, profiling |
| [08-Security/](08-Security/) | DevSecOps pipeline, secrets, image scanning, K8s hardening, SLSA/SBOM, OPA/Kyverno, threat modeling |
| [09-Networking/](09-Networking/) | Service mesh comparison, Cilium/eBPF, Ingress patterns, DNS strategies |
| [10-Databases-Production/](10-Databases-Production/) | Postgres prod guide, backup/restore, HA (Patroni/Stolon), zero-downtime migrations |
| [11-SRE/](11-SRE/) | SLI/SLO/error budget, incident response, runbook template, chaos engineering, capacity |
| [12-FinOps/](12-FinOps/) | Cost allocation, right-sizing, spot strategy, RI/SP, Kubecost |

### 🌟 Modern Trends
| Section | Topic |
|---|---|
| [13-Platform-Engineering/](13-Platform-Engineering/) | IDP, Backstage, golden paths, service catalog |
| [14-Sustainability/](14-Sustainability/) | Green Software Foundation principles, carbon-aware computing, SCI measurement |
| [15-AI-LLMOps/](15-AI-LLMOps/) | LLM in production, prompt engineering for ops, RAG architecture, AI-augmented ops |

### 🎒 In Your Pocket
| Section | Topic |
|---|---|
| [16-Cheatsheets/](16-Cheatsheets/) | kubectl · docker · git · helm · terraform · aws-cli · linux-troubleshooting · networking · vim |
| [17-Templates/](17-Templates/) | GitHub Actions · K8s manifest · Dockerfile · Terraform module · Kyverno policy · runbook |
| [18-Career/](18-Career/) | DevOps/SRE interview questions, system design prep |

### ⚖️ Legal & Human Side
| Section | Topic |
|---|---|
| [19-Compliance/](19-Compliance/) | KVKK, GDPR, ISO 27001, SOC 2, **EU AI Act**, NIS2, PCI DSS — with engineering controls |
| [20-Soft-Skills/](20-Soft-Skills/) | On-call sustainability, stakeholder management, working with the security team, saying "no" |
| [Glossary.md](Glossary.md) | Turkish ↔ English DevOps terminology glossary |
| [CLAUDE.md](CLAUDE.md) | Writing style & editorial guide (for contributors) |

### 🗒️ Field Notes
| Section | Topic |
|---|---|
| [21-Field-Notes/](21-Field-Notes/) | Raw notes from real deployments: Ansible prep, Terraform/Proxmox, K8s install, Wazuh SIEM, kubectl. Not a polished deep-dive; field records of "what actually worked." |

---

## 🗺️ Architecture Map

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

## ⭐ Repo Philosophy

1. **Distilled.** A table and three bullets beat five paragraphs of prose.
2. **Actionable.** Every section is written in "what / how / why" order.
3. **Placeholder-safe.** No real IPs/domains/credentials; placeholders like `<TARGET_IP>`, `<NAMESPACE>`, `<REGISTRY>` are used instead.
4. **Opinionated.** If a tool/paradigm isn't recommended in 2026, it says so — "don't do this," not neutral hedging.
5. **Anti-patterns called out.** Every deep-dive has a "don't do this" table.
6. **Benefit-driven.** Not a buzzword list — steps you can open and apply today.

---

## 🔗 Companion Repos

Complementary projects spun off from this repo:

| Repo | Topic |
|---|---|
| [databases-stack](https://github.com/halilibrahimd27/databases-stack) | A self-hosted MariaDB+PostgreSQL+MongoDB+Redis stack with a single `docker compose up` — admin panels, Prometheus exporter, automatic backups |
| [file-crypter](https://github.com/halilibrahimd27/file-crypter) | File/folder encryption with AES-256 CBC + PBKDF2 — a single command from the terminal |
| [wakapi-admin](https://github.com/halilibrahimd27/wakapi-admin) | Wakapi self-hosted stack + custom admin panel |
| [api-sentinel](https://github.com/halilibrahimd27/api-sentinel) | Third-party API schema change detection — plugin-based, severity-aware |
| [cheat-sheet](https://github.com/halilibrahimd27/cheat-sheet) | Offensive security command reference — OSCP/OSWE/OSEP prep |

---

## 🤝 Contributing

PRs are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and the writing guide [CLAUDE.md](CLAUDE.md) first.

> *Be specific when opening an issue:* something like "X is missing from Kubernetes hardening." Generic issues like "add more content" get tagged [good first issue](https://github.com/halilibrahimd27/devsecops-handbook/labels/good%20first%20issue) and passed along.

## 📜 License

[MIT](LICENSE) — use it freely.

---

*Goal: to be a reference a DevOps engineer opens and still finds valuable years later.*

Written & maintained by: **Halil İbrahim Dürmüş** — [@halilibrahimd27](https://github.com/halilibrahimd27) · [LinkedIn](https://www.linkedin.com/in/halil-ibrahim-durmus/)
