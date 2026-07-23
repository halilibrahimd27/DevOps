---
description: "A guide to designing golden paths, the heart of an Internal Developer Platform: opinionated, automated 'new service in 5 minutes' roadmaps, what they cover, and how to measure adoption."
tags:
  - Platform Engineering
  - GitOps
  - CI/CD
  - Template
---
# Golden Paths — "New Service in 5 Minutes"

> *"If a developer asks 'how do I spin up a new service?' and you
> send them a Confluence link, it means **you don't have a golden
> path**. The answer should be **one form**; everything else is
> automatic."*

This guide covers **golden paths** — the heart of an Internal
Developer Platform, "opinionated roadmaps" — how to design them, what
they should cover, and how to measure adoption.

---

## 🎯 What Is a Golden Path?

> **Golden Path**: The **team-standardized** way of doing a task
> (spin up a new service, add a DB, deploy) that is both
> **opinionated** and **automated**.

```
[Developer] → "I'm going to build a new Go REST API"
                     │
                     ▼
              [Backstage Form]
                     │
                     ▼ (5-10 minutes of automation)
                ┌────┴─────────────────────────────────────┐
                │                                          │
                │  ✓ GitHub repo (Dockerfile, CI, lint)    │
                │  ✓ Branch protection + CODEOWNERS        │
                │  ✓ Terraform PR (RDS, IAM, S3)           │
                │  ✓ ArgoCD Application                    │
                │  ✓ Datadog dashboard + alarms            │
                │  ✓ PagerDuty rotation assigned           │
                │  ✓ Slack channel created                 │
                │  ✓ Registered in Backstage Catalog       │
                │  ✓ Vault path provisioned                │
                │  ✓ Welcome PR: first endpoint            │
                └──────────────────────────────────────────┘
```

**Result**: The developer writes only the **business logic**.
Infrastructure = self-service.

---

## 🚦 "Path" vs "Paved Path"

| **Path** (the way) | **Paved Path** (the paved way) |
|---|---|
| "You could do this..." | Configuration that happens automatically |
| Documentation | Done with one click |
| Manual steps | One form + scaffolding |
| Prone to going stale | Code = alive, doesn't go stale |

> 🔑 **Golden = "gold-standard value" + "paved"** = what the team
> recommends & what's easy.

---

## 🪜 Golden Path Maturity Model

| Level | State | Time to new service |
|---|---|---|
| **L0** | Everything manual, "go ask so-and-so" | 2 weeks |
| **L1** | Cookiecutter / template repo | 3 days |
| **L2** | CLI tool: `mycli new-service` | 4 hours |
| **L3** | Backstage scaffolder + one form | 30 minutes |
| **L4** | Form + full automation (Terraform, ArgoCD, Datadog, ...) | 5-10 minutes |
| **L5** | "Compose": user picks components (DB type, queue, cache) | 5 minutes |

---

## 🛠️ Typical Golden Path Catalog

Every company builds its own collection. Common ones:

### 1. **New Microservice**
- Go REST API + Postgres
- Python FastAPI + Postgres
- Node Express + MongoDB
- Java Spring Boot + Kafka

### 2. **New Frontend**
- React + Next.js + Tailwind
- Vue + Nuxt
- Angular

### 3. **New Worker / Job**
- Background worker (Celery, BullMQ, Sidekiq)
- Cron job (K8s CronJob)
- Stream processor (Kafka consumer)

### 4. **New Infrastructure**
- Add a DB instance
- Create an S3 bucket
- Set up VPC peering

### 5. **New Library / SDK**
- Internal Go module
- npm package
- Shared TypeScript types

### 6. **Production Onboarding**
- "Existing service goes prod-ready" path: SLO + alerts + dashboard + runbook + on-call assignment

---

## 📋 Golden Path Template Anatomy

### Backstage scaffolder template (example)
```yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: golang-rest-api
  title: Go REST API
  description: New Go REST API + Postgres + ArgoCD + monitoring
  tags: [recommended, go, rest, postgres]
spec:
  owner: platform-team
  type: service

  parameters:
    - title: Service Information
      required: [serviceName, ownerTeam, description]
      properties:
        serviceName:
          type: string
          pattern: '^[a-z][a-z0-9-]+$'
          ui:autofocus: true
          description: "Lowercase + dash, e.g., payments-api"
        description:
          type: string
        ownerTeam:
          type: string
          enum: [platform-team, payments-team, catalog-team, growth-team]
        slackChannel:
          type: string
          pattern: '^[a-z][a-z0-9-]+$'

    - title: Cloud Resources
      properties:
        cloud:
          type: string
          enum: [aws, gcp]
          default: aws
        region:
          type: string
          enum: [eu-west-1, eu-central-1, us-east-1]
        databaseNeeded:
          type: boolean
          default: false
        cacheNeeded:
          type: boolean
          default: false
        queueNeeded:
          type: boolean
          default: false

    - title: SLO & On-Call
      properties:
        sloAvailability:
          type: string
          enum: ['99.9', '99.95', '99.99']
          default: '99.9'
        onCallRotation:
          type: string

  steps:
    - id: validate
      name: Validate inputs
      action: custom:validate-service-name

    - id: fetch-skeleton
      name: Fetch repo template
      action: fetch:template
      input:
        url: ./skeleton
        values:
          serviceName: ${{ parameters.serviceName }}
          ownerTeam: ${{ parameters.ownerTeam }}
          dbNeeded: ${{ parameters.databaseNeeded }}

    - id: create-repo
      name: Create GitHub repo
      action: publish:github
      input:
        repoUrl: github.com?owner=<ORG>&repo=${{ parameters.serviceName }}
        defaultBranch: main
        protectDefaultBranch: true
        requiredApprovingReviewCount: 1
        requireCodeOwnerReviews: true
        deleteBranchOnMerge: true
        gitCommitMessage: 'Initial scaffold from golden path'

    - id: register-catalog
      name: Register in Backstage Catalog
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps.create-repo.output.repoContentsUrl }}
        catalogInfoPath: '/catalog-info.yaml'

    - id: terraform-pr
      name: Open Terraform PR (cloud resources)
      action: github:create-pr
      input:
        repoUrl: github.com?owner=<ORG>&repo=infra-terraform
        branchName: 'add-${{ parameters.serviceName }}'
        title: 'Add resources for ${{ parameters.serviceName }}'
        body: |
          Auto-generated by Backstage scaffolder.

          - DB: ${{ parameters.databaseNeeded }}
          - Cache: ${{ parameters.cacheNeeded }}
          - Queue: ${{ parameters.queueNeeded }}

    - id: argocd-app
      name: Create ArgoCD Application
      action: github:create-pr
      input:
        repoUrl: github.com?owner=<ORG>&repo=k8s-config
        branchName: 'add-app-${{ parameters.serviceName }}'
        title: 'ArgoCD Application: ${{ parameters.serviceName }}'

    - id: pagerduty-rotation
      name: Create PagerDuty rotation
      action: pagerduty:create-rotation
      input:
        name: '${{ parameters.serviceName }}-oncall'
        team: '${{ parameters.ownerTeam }}'

    - id: slack-channel
      name: Create Slack channel
      action: slack:create-channel
      input:
        name: '${{ parameters.serviceName }}-alerts'

    - id: vault-path
      name: Provision Vault path
      action: vault:create-path
      input:
        path: 'kv/${{ parameters.serviceName }}'
        team: '${{ parameters.ownerTeam }}'

    - id: dashboard
      name: Create Datadog dashboard
      action: datadog:create-dashboard
      input:
        template: 'service-default'
        service: '${{ parameters.serviceName }}'

  output:
    links:
      - title: Repository
        url: ${{ steps.create-repo.output.remoteUrl }}
      - title: View in Catalog
        icon: catalog
        entityRef: ${{ steps.register-catalog.output.entityRef }}
      - title: Terraform PR
        url: ${{ steps.terraform-pr.output.prUrl }}
      - title: ArgoCD Application
        url: 'https://argocd.<DOMAIN>/applications/${{ parameters.serviceName }}'
      - title: PagerDuty Rotation
        url: ${{ steps.pagerduty-rotation.output.rotationUrl }}
      - title: Datadog Dashboard
        url: ${{ steps.dashboard.output.dashboardUrl }}
```

---

## 🏗️ Skeleton Repo Contents

```
templates/golang-rest-api/skeleton/
├── catalog-info.yaml          # Backstage Catalog entry
├── README.md                  # getting started
├── Dockerfile                 # multi-stage, distroless
├── .dockerignore
├── .gitignore
├── go.mod
├── main.go                    # health check + example endpoint
├── Makefile                   # standard commands
├── .github/
│   ├── CODEOWNERS
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug.yml
│   │   └── feature.yml
│   └── workflows/
│       ├── ci.yml             # build + test + scan
│       └── release.yml        # cosign sign + image push
├── k8s/
│   ├── base/
│   │   ├── kustomization.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── networkpolicy.yaml
│   └── overlays/
│       ├── dev/
│       ├── staging/
│       └── prod/
├── docs/
│   ├── index.md
│   ├── architecture.md
│   ├── runbook.md
│   └── slo.md
├── mkdocs.yml                 # TechDocs
└── tests/
    └── e2e/
```

> 🔑 The skeleton is **opinionated**. Test framework, CI, security
> scan, K8s manifests are all default. The developer can't ask "which
> one do I pick?" — **this is the standard**.

---

## 🎯 Design Principles

### 1. **Opinionated, with an Escape Hatch**
- We say "we only use this DB" → but **exceptions are possible via a PR**
- **Convention by default** instead of a hard block

### 2. **Hidden Complexity**
- The developer doesn't need to know Helm/Kustomize/Terraform
- What the engineer never sees: the scaffolder is setting up all the PRs, secrets, and alarms

### 3. **Quarterly Review**
- The template gets updated when new technology shows up
- Stale feature flags and deprecated libraries get cleaned out

### 4. **NPS Measurement**
- After every path run: a "Was this easy?" survey
- Continuous improvement

---

## 📊 Adoption Metrics

| Metric | Target |
|---|---|
| **Path usage count** (3 months) | > 80% of new services created via a path |
| **Average onboarding time** | < 30 minutes |
| **NPS** (per path) | > 30 |
| **Path bypass rate** | < 10% (accepted exceptions) |
| **Stale paths** (60+ days without an update) | 0 |
| **Standardized service %** | > 90% (has catalog-info.yaml) |

---

## 🔄 Path Lifecycle

```
PROPOSE → BUILD → BETA → GA → MAINTAIN → DEPRECATE
```

### Propose (1-2 weeks)
- RFC: why is a new path needed?
- Does a similar path already exist?
- Which 3+ services will use it?

### Build (2-4 weeks)
- Skeleton + scaffolder template
- Documentation
- 1-2 pilot services

### Beta (4-8 weeks)
- 5-10 teams use it
- Feedback gets collected and acted on
- Tagged "Beta" in the UI

### GA (ongoing)
- Path gets the "recommended" tag
- Adoption is measured
- The old method gets **deprecated**

### Maintain
- Quarterly review
- Dependency updates (automatic via Renovate)
- NPS tracking

### Deprecate
- Path is no longer recommended
- Migration path to the new version
- 6-month sunset

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Do this instead |
|---|---|---|
| Path is "the one true way" | Bypasses start happening | Escape hatch + exception PR |
| Too many paths (20+) | Clutter, choice paradox | 5-10 well-curated ones |
| Path went stale, nobody noticed | New services inherit the staleness | Quarterly review + NPS |
| Hardcoded version in the skeleton | Skips Renovate, drift | Variable + auto-bump |
| "Manual for now, automate later" | Never actually gets automated | Path = automated or it doesn't exist |
| New service reaches prod without a path | Not standardized | Deploying without a path is forbidden (warn → block) |
| Adoption isn't measured | No proof "the path is actually used" | Dashboard + NPS |
| No feature flag in the skeleton | Half-finished features can't be merged | Default flag stack |
| No tests in the skeleton | Juniors copy-paste, no tests | Default test setup |
| Platform team writes the path **on its own** | Misses actual developer needs | Co-design with the first user |

---

## 📋 Golden Path Production Checklist

```
[ ] Backstage scaffolder installed
[ ] At least 1 production-grade path (e.g., REST API)
[ ] Skeleton: Dockerfile, CI, K8s manifest, tests, docs
[ ] Scaffolder template: GitHub + Terraform + ArgoCD + alerts
[ ] CODEOWNERS assigned automatically
[ ] Branch protection set up automatically
[ ] catalog-info.yaml generated automatically
[ ] TechDocs enabled
[ ] PagerDuty rotation automatic
[ ] Slack channel automatic
[ ] Vault path automatic
[ ] Dashboard automatic
[ ] Welcome PR (first endpoint ready)
[ ] NPS survey per path
[ ] Adoption metric dashboard
[ ] Quarterly path review
[ ] Renovate-driven dependency auto-update (baked into the skeleton)
[ ] Documentation: how to add a new path
[ ] Beta period with a pilot service
[ ] Lifecycle policy (propose → GA → deprecate)
```

---

## 📚 References

- **Spotify Backstage Scaffolder** — backstage.io/docs/features/software-templates/
- **Roadie Skill Exchange** — roadie.io
- **Platform Engineering Maturity** — platformengineering.org/maturity-model
- [`Internal-Developer-Platform.md`](Internal-Developer-Platform.md)
- [`Backstage-Setup.md`](Backstage-Setup.md)
- [`Service-Catalog.md`](Service-Catalog.md)
- [`Platform-as-Product.md`](Platform-as-Product.md)
- [`02-CI-CD/Pipeline-Patterns.md`](../02-CI-CD/Pipeline-Patterns.md) — CI standard

---

> *"A golden path isn't a 'doc shortcut' — it's the **crystallization
> of an engineering decision**. When the goal shifts from 'the best
> way' to **'the easy way'**, everyone picks the easy way; the
> standard spreads **on its own**."*

---

> 🎓 **Learning Path:** This document is used as a "read first"
> resource in the [`F3`](../22-Learning-Path/block-f-judgment/F3-platform-idp.md) module.
