# 02 · CI/CD

> *"Her commit deploy edilebilir olmalı; her deploy reversible olmalı."*

Continuous Integration & Continuous Delivery için pipeline patternleri,
GitHub Actions / GitLab CI tarifleri ve "yavaş CI" tedavi protokolleri.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`Pipeline-Patterns.md`](Pipeline-Patterns.md) | Build → Test → Scan → Sign → Deploy katmanlama |
| _`GitHub-Actions-Recipes.md`_ *(yakında)* | Reusable workflow, matrix build, OIDC AWS auth, ortam koruması |
| _`GitLab-CI-Recipes.md`_ *(yakında)* | DAG pipeline, dynamic child, dotenv artifact'lar |
| _`Caching-Strategies.md`_ *(yakında)* | Layer cache, npm/pip/cargo/go cache, BuildKit cache mount |
| _`Reusable-Workflows.md`_ *(yakında)* | Org-wide template, callable workflow, composite action |
| _`Pipeline-Performance.md`_ *(yakında)* | "10 dakikalık CI"yi 90 saniyeye indirme protokolü |
| [`Mobile-CICD-Flutter.md`](Mobile-CICD-Flutter.md) | Flutter/Android/iOS için end-to-end CI/CD checklist (signing, store deploy) |

## Pipeline anatomisi (referans)

```
   PR Açıldı
      │
      ▼
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  LINT    │──▶│  UNIT    │──▶│   SAST   │──▶│   DEP    │
│  fast    │   │  TEST    │   │  scan    │   │   scan   │
└──────────┘   └──────────┘   └──────────┘   └──────────┘
                                  │
                                  ▼
                          ┌────────────────┐
                          │  BUILD IMAGE   │  (BuildKit, cache)
                          └────────────────┘
                                  │
                                  ▼
                          ┌────────────────┐
                          │  TRIVY scan    │  (image vulnerability)
                          └────────────────┘
                                  │
                                  ▼
                          ┌────────────────┐
                          │ COSIGN sign    │  (keyless OIDC)
                          └────────────────┘
                                  │
                                  ▼
                          ┌────────────────┐
                          │  E2E / SMOKE   │  (kind/preview env)
                          └────────────────┘
                                  │
                                  ▼
                            Merge to main
                                  │
                                  ▼
                          ┌────────────────┐
                          │  GitOps push   │  (image tag bump)
                          └────────────────┘
                                  │
                                  ▼
                            ArgoCD reconcile
                                  │
                                  ▼
                          Progressive rollout
                          (canary 5% → 25% → 100%)
```

## Hız hedefleri (her iyi pipeline'a uygulanır)

| Aşama | İyi | Kötü |
|---|---|---|
| Lint | < 30 sn | > 2 dk |
| Unit test | < 2 dk | > 5 dk |
| Build image | < 3 dk (cached) | > 10 dk |
| E2E smoke | < 5 dk | > 15 dk |
| **Toplam PR feedback** | **< 10 dk** | > 30 dk |

> 10 dakika aşıldığında geliştiriciler context-switch'e başlar; 30 dk'da
> "PR açıp kahve içeyim, dönerim" haline gelir → akış ölür.
