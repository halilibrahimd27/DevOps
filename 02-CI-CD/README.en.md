---
description: "CI/CD section index: pipeline patterns, GitHub Actions and GitLab CI recipes, caching, reusable workflows, and slow-CI remediation protocols."
tags:
  - CI/CD
  - Git
  - Roadmap
---
# 02 · CI/CD

> *"Every commit should be deployable; every deploy should be reversible."*

Pipeline patterns for Continuous Integration & Continuous Delivery,
GitHub Actions / GitLab CI recipes, and "slow CI" remediation protocols.

## Contents

| File | Topic |
|---|---|
| [`Pipeline-Patterns.md`](Pipeline-Patterns.md) | Build → Test → Scan → Sign → Deploy layering |
| [`GitHub-Actions-Recipes.md`](GitHub-Actions-Recipes.md) | Reusable workflows, matrix builds, OIDC AWS auth, environment protection |
| [`GitLab-CI-Recipes.md`](GitLab-CI-Recipes.md) | DAG pipelines, dynamic child pipelines, dotenv artifacts |
| [`Caching-Strategies.md`](Caching-Strategies.md) | Layer cache, npm/pip/cargo/go cache, BuildKit cache mount |
| [`Reusable-Workflows.md`](Reusable-Workflows.md) | Org-wide templates, callable workflows, composite actions |
| [`Pipeline-Performance.md`](Pipeline-Performance.md) | Protocol for cutting "10-minute CI" down to 90 seconds |
| [`Mobile-CICD-Flutter.md`](Mobile-CICD-Flutter.md) | End-to-end CI/CD checklist for Flutter/Android/iOS (signing, store deploy) |

## Pipeline anatomy (reference)

```
   PR Opened
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

## Speed targets (apply to every good pipeline)

| Stage | Good | Bad |
|---|---|---|
| Lint | < 30 sec | > 2 min |
| Unit test | < 2 min | > 5 min |
| Build image | < 3 min (cached) | > 10 min |
| E2E smoke | < 5 min | > 15 min |
| **Total PR feedback** | **< 10 min** | > 30 min |

> Once you cross 10 minutes, developers start to context-switch; at 30 min
> it turns into "I'll open the PR, grab a coffee, and be back" → flow dies.
