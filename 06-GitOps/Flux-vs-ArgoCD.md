---
description: "Flux ve ArgoCD GitOps araçlarının 2026 karşılaştırması: felsefe, UI, multi-cluster, Helm/Kustomize desteği ve hangi senaryoda hangisi tercih edilir."
tags:
  - GitOps
  - ArgoCD
  - Kubernetes
  - CI/CD
---
# Flux vs ArgoCD — GitOps Tool Karar Rehberi

> *"İki tool da CNCF Graduated, ikisi de production-ready, ikisi de
> 'evet biz GitOps yapıyoruz' iddiasını destekler. Aralarındaki fark
> **felsefe** — UI'lı vs UI'sız, monorepo vs çoklu, push vs pull."*

Bu rehber 2026 itibarıyla Flux ve ArgoCD'yi karşılaştırır, hangi
senaryoda hangisinin tercih edildiğini açıklar.

---

## 🎯 Tek Cümlede

| Tool | Felsefe |
|---|---|
| **ArgoCD** | "GitOps + güçlü UI + Application CRD" |
| **Flux** | "GitOps + Kubernetes-native + minimal API" |

---

## 📊 Detaylı Karşılaştırma

| Boyut | **ArgoCD** | **Flux** |
|---|---|---|
| **CNCF Status** | Graduated (2022) | Graduated (2022) |
| **Sahibi** | Intuit (Argo project) | Weaveworks → CNCF |
| **UI** | ✅ Zengin web UI | ❌ Yok (CLI + Headlamp / k9s) |
| **Multi-cluster** | ✅ Cluster CRD | ✅ Aynı cluster veya remote |
| **Helm support** | ✅ | ✅ |
| **Kustomize support** | ✅ | ✅ |
| **OCI artifact (image as config)** | ⚠️ Plugin | ✅ Native |
| **Sync trigger** | Pull (default) + manual UI | Pull only |
| **Image automation** | ❌ (Argo Image Updater addon) | ✅ Native (Flux Image Reflector) |
| **Sealed Secrets / SOPS** | Plugin | ✅ Native (Flux SOPS) |
| **ApplicationSet / multi-app** | ✅ ApplicationSet CRD | ✅ Kustomization recursion |
| **Notifications** | ✅ Slack, Webhook | ✅ Notification controller |
| **RBAC** | OIDC + custom RBAC | K8s RBAC |
| **HA / Scalability** | İyi (controller sharding roadmap) | Mükemmel (modular controller'lar) |
| **Memory footprint** | ~200-500 MB | ~150-300 MB |
| **Setup karmaşası** | Orta (Helm + values) | Düşük (`flux bootstrap`) |
| **Öğrenme eğrisi** | Orta-yüksek (UI + CRD'ler) | Yumuşak (CLI workflow) |
| **Topluluk** | Çok büyük (10K+ stars) | Büyük |

---

## 🏛️ Mimari Farklar

### ArgoCD
```
[ArgoCD Server (UI + API)]
        │
        ├── Repository Server  (Git çekme + manifest render)
        ├── Application Controller (sync engine)
        ├── ApplicationSet Controller
        ├── Notifications Controller
        └── Redis (cache, state)

→ Tek namespace'de monolith-leaning. UI = ana etkileşim.
```

### Flux
```
[Source Controller]    Git/Helm/OCI'den çek
[Kustomize Controller] kustomize render + apply
[Helm Controller]      helm release manage
[Notification Controller] alert/event ship
[Image Reflector]      registry tarat
[Image Automation]     yeni tag → Git'e PR/commit

→ Modular controller'lar. Her biri ayrı bağımsız scaling.
```

---

## 🌳 Karar Ağacı

```
START
  │
  ├── UI önemli mi? (dev'lerin platform UI'ında deploy görmesi)
  │     │
  │     ├── EVET → ArgoCD
  │     │
  │     └── HAYIR → devam
  │
  ├── Image automation (yeni tag → otomatik deploy) önemli mi?
  │     │
  │     ├── EVET → Flux (native)
  │     │
  │     └── HAYIR → devam
  │
  ├── SOPS / OCI artifact native lazım mı?
  │     │
  │     ├── EVET → Flux
  │     │
  │     └── HAYIR → devam
  │
  ├── Backstage / Crossplane / IDP tooling entegrasyonu var mı?
  │     │
  │     ├── ArgoCD'ye yatkın → ArgoCD
  │     │
  │     └── Net değil → ArgoCD (daha geniş plugin)
  │
  └── Multi-tenant cluster paylaşımı yoğun mu?
        │
        └── EVET → ArgoCD (AppProject + RBAC granular)
            HAYIR → ya Flux ya Argo
```

---

## 🚀 Use Case Senaryoları

### Senaryo 1: SaaS başlangıç
- 1 cluster, 5-10 servis
- Geliştirici "Argo UI'da gördüm" istiyor
- → **ArgoCD**

### Senaryo 2: Platform team büyük org
- 5 cluster, 100+ app
- Her ekibin kendi namespace'i
- AppProject ile izolasyon kritik
- → **ArgoCD** (ApplicationSet + AppProject)

### Senaryo 3: Image-driven deployment
- CI image build → otomatik prod deploy istiyor
- "Image tag bump için manuel PR yok"
- → **Flux** (Image Automation native)

### Senaryo 4: Minimalist GitOps
- Az dependency, modular
- UI gerek yok, CLI yeterli
- → **Flux**

### Senaryo 5: SOPS-heavy (encrypted Git)
- Tüm secret'lar SOPS ile commit
- → **Flux** (native decryption)

### Senaryo 6: Crossplane + GitOps
- Cloud resource'ları K8s CRD ile yönetim
- → **ArgoCD** veya Flux ikisi de OK; ArgoCD topluluğu daha büyük

---

## 🛠️ İki Tool'un Yan Yana Çalışması

Aynı cluster'da **ikisi de mümkün**:
- ArgoCD: app deployment
- Flux: image automation + secret rotation

Ama **drift riski** var. Genelde **birini seç**.

---

## 🔄 Migration: Flux → ArgoCD (veya tersi)

### Aşamalı yaklaşım
```
1. Hafta — Hazırlık
   - Yeni tool paralel kur
   - Test ortamında çalıştır
   - Equivalent CRD mapping (Flux Kustomization → ArgoCD Application)

2-4. Hafta — Yeni servisler yeni tool'da
   - Mevcut hâlâ eski'de
   - Pattern öğrenilir

5-12. Hafta — Mevcut göç
   - Servis başına PR: eski CRD silinir, yeni kurulur
   - GitOps sürekli, downtime yok

13. Hafta — Eski tool kaldır
```

### Equivalence mapping
| Flux | ArgoCD |
|---|---|
| `Kustomization` | `Application` |
| `HelmRelease` | `Application` (helm source) |
| `GitRepository` | `Application.spec.source` |
| `OCIRepository` | Plugin |
| `ImageUpdateAutomation` | Argo Image Updater |
| `Receiver` (webhook) | Argo Webhook |
| `Alert` + `Notification` | Notifications Controller |

---

## 📊 2026 Trend

### ArgoCD ekosistemi büyük
- **Argo Workflows**, **Argo Rollouts**, **Argo Events** ile birleşik suite
- Backstage / Roadie / Cortex entegrasyonu zengin
- Akuity (managed ArgoCD) ticari destek

### Flux ekosistemi modular
- Weaveworks → CNCF Sandbox geçişi sonrası comminty-driven
- Modular controller'lar K8s-native
- D2iQ / Microsoft Flux on AKS

> 🎯 **Pragmatik 2026 önerisi**: Yeni başlayan ekibe **ArgoCD** (UI + topluluk + plugin). Minimalist / image-automation odaklı **Flux**.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tool seçimi marketing'le | Production fit değil | Karar ağacı + PoC |
| ArgoCD UI'ı admin-only | Adoption düşük | Dev'lere read-only erişim |
| ArgoCD cluster-admin tek SA | Compromise = cluster down | AppProject + RBAC |
| Flux UI yok diye headache | CLI alışkanlığı yok | Headlamp / k9s entegrasyon |
| İki tool aynı cluster'da | Drift, debug zor | Tek tool seç |
| Migration big-bang | Production kırılma | Aşamalı 12 hafta |
| Notification yok | Sync fail görünmez | Slack/PagerDuty integration |
| Self-managed yok | Tool upgrade unutulur | App-of-Apps + GitOps |
| Multi-cluster manifest copy-paste | Drift | ApplicationSet (Argo) / Kustomization recursion (Flux) |

---

## 📋 GitOps Tool Adoption Checklist

```
[ ] Karar ağacı + PoC ile tool seçildi
[ ] HA: 3+ replica controller
[ ] Self-managed (App-of-Apps / Flux bootstrap)
[ ] RBAC: OIDC entegrasyonu, default-deny
[ ] Notification: Slack + alert
[ ] Per-team izolasyon (AppProject / namespace)
[ ] Multi-cluster strategy (varsa)
[ ] Secret management: SOPS / ESO / Sealed
[ ] Image automation gerekiyorsa: Flux veya Argo Image Updater
[ ] Backup: Git zaten kaynak; controller state minimum
[ ] Upgrade prosedürü: rolling, test cluster önce
[ ] Documentation: yeni servis nasıl onboard
[ ] Quarterly: drift / sync metrik review
```

---

## 📚 Referanslar

- **ArgoCD Docs** — argo-cd.readthedocs.io
- **Flux Docs** — fluxcd.io
- **OpenGitOps** — opengitops.dev
- **CNCF GitOps WG** — github.com/cncf/sig-app-delivery
- **Akuity** — akuity.io (Argo managed)
- **Weaveworks Cloud** (legacy) — Flux origin
- [`ArgoCD-Setup.md`](ArgoCD-Setup.md)
- [`ApplicationSet-Patterns.md`](ApplicationSet-Patterns.md)
- [`App-of-Apps-Pattern.md`](App-of-Apps-Pattern.md)
- [`Helm-vs-Kustomize-vs-Raw.md`](Helm-vs-Kustomize-vs-Raw.md)
- [`Secrets-in-GitOps.md`](Secrets-in-GitOps.md)

---

> *"Tool seçimi 'doğru cevap' değil, **doğru fit** sorusudur. UI
> seven ekibe ArgoCD; minimalism seven ekibe Flux. **Ekibinin
> alışkanlığını** dinleyen seçim, **2 yıl** sonra hâlâ doğru."*
