---
description: "Index of the Platform Engineering section: overview and file guide covering the Internal Developer Platform, Backstage setup, golden paths, service catalog, and platform-as-product topics."
tags:
  - Platform Engineering
  - Roadmap
  - Culture
---
# 13 · Platform Engineering

> *"The DevOps team is answering 14 tickets while the developer smokes
> a cigarette waiting. This isn't sustainable."* — the bitter truth of corporate DevOps

Internal Developer Platform (IDP) = an opinionated "golden path" that
developers use in self-service mode.

## Table of Contents

| File | Topic |
|---|---|
| [`Internal-Developer-Platform.md`](Internal-Developer-Platform.md) | What IDP is, why it starts with Backstage, build vs buy |
| [`Backstage-Setup.md`](Backstage-Setup.md) | Backstage setup, plugins, scaffolder templates |
| [`Golden-Paths.md`](Golden-Paths.md) | Templates for "spin up a new service → in 5 min" |
| [`Service-Catalog.md`](Service-Catalog.md) | Service ownership, dependency graph, on-call mapping |
| [`Platform-as-Product.md`](Platform-as-Product.md) | Treat the developer like a customer; NPS, SLA, roadmap |

## Philosophy

> The platform team's product is an internal product delivered **to
> other engineers**. Customer = developer. Customer satisfaction =
> developer productivity.

## Platform vs DevOps team

| DevOps team (anti-pattern) | Platform team (healthy) |
|---|---|
| "Take the ticket, run it" | Offers self-service tools |
| Hoards knowledge (gatekeeper) | Shares knowledge (enabler) |
| Single-person dependent (bus factor 1) | Tools are documented, multi-owned |
| "Firefighter" | Fire preventer |
| Developer's adversary | Developer's customer |

## Minimum Backstage setup

```
Backstage core
├── Catalog            ← service inventory + ownership
├── Scaffolder         ← golden path templates
├── TechDocs           ← markdown-as-docs
├── Search             ← global cross-resource search
├── Kubernetes plugin  ← cluster overview
└── Cost Insights      ← Kubecost/AWS integration
```

## "Golden Path" example — new microservice

```
$ backstage scaffold create

? Template:           [ Go REST API + Postgres ]
? Service name:       payments
? Owner team:         @payments-team
? Cloud:              AWS
? Region:             eu-west-1

[What Backstage does behind the scenes]
├── GitHub repo opened       (from the template)
├── CODEOWNERS, README, CI   added
├── Terraform PR             (RDS, IAM)
├── ArgoCD Application       in the k8s-config repo
├── Datadog dashboard        created
├── PagerDuty rotation       assigned
├── Slack #payments-alerts   opened
├── Backstage Catalog        entry registered
└── On-boarding doc          created (TechDocs)

⏱️ Total time: ~8 minutes
```

## Build vs buy decision tree

```
Company size?
├── < 50 engineers → Vendor SaaS (Port, Cortex)
├── 50-500        → Backstage self-host + Crossplane
└── 500+          → In-house build on a custom platform
```

## Anti-patterns

- ❌ Making the platform "mandatory" instead of a "service" — everyone ends up feeling vendor-locked-in
- ❌ Not measuring NPS — you don't know why developers aren't using it
- ❌ "You can't ship to production without going through us" — a bottleneck, demoralizing
- ❌ All guardrails are hard blocks — without an escape hatch, bypasses start happening
- ❌ The platform team has no backlog of its own, it just answers tickets
