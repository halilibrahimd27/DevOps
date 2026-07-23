---
description: "GitOps section index: links to ArgoCD, Flux, ApplicationSet, App-of-Apps, Helm/Kustomize, and secret management guides, plus OpenGitOps principles."
tags:
  - GitOps
  - ArgoCD
  - Kubernetes
  - Roadmap
---
# 06 · GitOps

> *"A team that uses `kubectl get` to find out what's running in their
> cluster is living in prod, not in Git history."*

Git = single source of truth. An agent (ArgoCD/Flux) continuously pulls
the cluster to the desired state.

## Contents

| File | Topic |
|---|---|
| [`ArgoCD-Setup.md`](ArgoCD-Setup.md) | ArgoCD setup, AppProject, RBAC, SSO, notifications |
| [`Flux-vs-ArgoCD.md`](Flux-vs-ArgoCD.md) | Philosophy of both, when to use which |
| [`ApplicationSet-Patterns.md`](ApplicationSet-Patterns.md) | Multi-cluster, multi-tenant deploy: matrix/git generator/cluster generator |
| [`App-of-Apps-Pattern.md`](App-of-Apps-Pattern.md) | Self-managed ArgoCD; bootstrap flow |
| [`Helm-vs-Kustomize-vs-Raw.md`](Helm-vs-Kustomize-vs-Raw.md) | Manifest derivation: pros/cons table |
| [`Secrets-in-GitOps.md`](Secrets-in-GitOps.md) | SOPS, Sealed Secrets, External Secrets Operator comparison |

## OpenGitOps principles

```
1. Declarative          → "what should be" is written in Git, not "how"
2. Versioned & Immutable → Git is the single source of truth; tags are immutable
3. Pulled Automatically  → the agent pulls, you don't push
4. Continuously Reconciled → drift is continuously corrected
```

## Repository layout (recommended)

The two-repo approach is most common:

```
app-source/                  ← application code
└── (your-app)
    └── Dockerfile, src/, ...

k8s-config/                  ← deployment manifests (separate repo)
├── apps/
│   ├── payments/
│   │   ├── base/            ← kustomize base
│   │   └── overlays/
│   │       ├── dev/
│   │       ├── staging/
│   │       └── prod/
│   └── catalog/
├── infrastructure/          ← cluster-level addons
│   ├── ingress-nginx/
│   ├── cert-manager/
│   └── external-secrets/
└── argocd/
    ├── projects/            ← AppProject CRDs
    └── applicationsets/     ← ApplicationSet CRDs
```

> CI builds the image in app-source and opens a tag-bump PR to k8s-config.
> ArgoCD watches k8s-config and applies it to the cluster.

## Promotion flow

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
