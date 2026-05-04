# 06 · GitOps

> *"Cluster'ında ne çalıştığını öğrenmek için `kubectl get` kullanan ekip,
> Git tarihinde değil prod'da yaşıyor demektir."*

Git = single source of truth. Bir agent (ArgoCD/Flux) cluster'ı sürekli
istenen duruma çeker.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`ArgoCD-Setup.md`](ArgoCD-Setup.md) | ArgoCD kurulumu, AppProject, RBAC, SSO, notifications |
| _`Flux-vs-ArgoCD.md`_ *(yakında)* | İkisinin felsefesi, ne zaman hangisi |
| [`ApplicationSet-Patterns.md`](ApplicationSet-Patterns.md) | Çok-cluster, çok-tenant deploy: matrix/git generator/cluster generator |
| [`App-of-Apps-Pattern.md`](App-of-Apps-Pattern.md) | Self-managed ArgoCD; bootstrap akışı |
| [`Helm-vs-Kustomize-vs-Raw.md`](Helm-vs-Kustomize-vs-Raw.md) | Manifest derivation: avantaj/dezavantaj tablo |
| _`Secrets-in-GitOps.md`_ *(yakında)* | SOPS, Sealed Secrets, External Secrets Operator karşılaştırma |

## OpenGitOps prensipleri

```
1. Declarative          → "ne olmalı" Git'te yazılı, "nasıl" değil
2. Versioned & Immutable → Git tek doğruluk kaynağı; tag'ler immutable
3. Pulled Automatically  → agent çeker, sen push'lamazsın
4. Continuously Reconciled → drift sürekli düzeltilir
```

## Repo yapısı (önerilen)

İki repo yaklaşımı en yaygın:

```
app-source/                  ← uygulama kodu
└── (your-app)
    └── Dockerfile, src/, ...

k8s-config/                  ← deployment manifestleri (ayrı repo)
├── apps/
│   ├── payments/
│   │   ├── base/            ← kustomize base
│   │   └── overlays/
│   │       ├── dev/
│   │       ├── staging/
│   │       └── prod/
│   └── catalog/
├── infrastructure/          ← cluster-level addon'lar
│   ├── ingress-nginx/
│   ├── cert-manager/
│   └── external-secrets/
└── argocd/
    ├── projects/            ← AppProject CRD'leri
    └── applicationsets/     ← ApplicationSet CRD'leri
```

> CI app-source'da imaj build edip k8s-config'e tag bump PR'ı atar.
> ArgoCD k8s-config'i izler ve cluster'a uygular.

## Promotion akışı

```
   feature PR              merge to main             tag bump PR
   ┌──────────┐            ┌──────────┐              ┌──────────┐
   │ app-src  │ ─CI build──▶│ registry │ ───────────▶│ k8s-cfg  │
   │   PR     │            │  v1.2.3  │              │  dev tag │
   └──────────┘            └──────────┘              └────┬─────┘
                                                          │ ArgoCD
                                                          ▼
                                                       DEV cluster
                                                          │ smoke OK
                                                          ▼
                                                   PR: dev → staging
                                                          │ ArgoCD
                                                          ▼
                                                     STAGING cluster
                                                          │ canary OK
                                                          ▼
                                                   PR: staging → prod
                                                          │ ArgoCD + Argo Rollouts
                                                          ▼
                                                       PROD cluster
```
