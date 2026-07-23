---
description: "A guide to the Internal Developer Platform (IDP) concept from a cultural and product perspective before technology: the self-service golden path, build vs buy, and a concrete roadmap."
tags:
  - Platform Engineering
  - Culture
  - Roadmap
  - Kubernetes
---
# Internal Developer Platform — Why, How, In What Order

> *"A developer asks in 14 tickets: 'How do I spin up a new service?'
> When the answer lives across 47 pages of Confluence, either the
> **documentation** or the **platform** is falling short."*

This guide covers the Internal Developer Platform (IDP) concept from
a **cultural + product** perspective before getting into technology,
then gives a concrete roadmap.

---

## 🎯 What Is an IDP? (Plain Definition)

> **IDP**: An internal product that offers an *opinionated* "golden
> path," used by the developer in *self-service* fashion.

```
┌────────────────────────────────────────────────────────┐
│                  Internal Developer Portal             │
│              (Backstage / Port / Cortex)               │
│                                                        │
│   "New service"  · "Where's my cluster"  · "Logs"      │
└──────────┬─────────────────────────────────────────────┘
           │
   ┌───────┼─────────────┬─────────────┬────────────┐
   ▼       ▼             ▼             ▼            ▼
[Kubernetes][CI/CD]    [Cloud]    [Monitoring]   [Secrets]
   ↑       ↑             ↑             ↑            ↑
   └───── Platform Engineering Team (builds, maintains) ──┘
```

The developer doesn't have to "know infrastructure"; they open a
service, deploy, and check logs through the **portal**.

---

## 🚦 Why Do You Need an IDP?

### Symptoms of the Problem
- Every new service waits 2 weeks in the DevOps ticket queue
- One single person is the "kubectl context" gatekeeper
- Onboarding takes a month
- The answer to "how do I deploy this?" varies across the company
- Production docs get updated once every 6 months (stale by the time of rotation)

### What an IDP Promises
- **Self-service** → DevOps tickets drop by 80%
- **Opinionated** → everyone does the same thing the same way
- **Audit + observability** → who does what, logged automatically
- **Onboarding in 1 week** → the portal shows the developer "what you can touch"

---

## ⚖️ DevOps Team vs Platform Team

| **DevOps team** (anti-pattern) | **Platform team** (healthy) |
|---|---|
| "Take the ticket, execute it" | Offers self-service tools |
| Hoards knowledge (gatekeeper) | Shares knowledge (enabler) |
| Single-person-dependent (bus factor 1) | Tools are documented, multi-owned |
| "Firefighter" | Fire preventer |
| Developer = enemy | Developer = customer |
| No backlog, just answers tickets | Has a roadmap, measures NPS |

> 🔑 **Philosophy shift:** The platform team builds an **internal
> product**; product engineers = customers. Customer satisfaction is
> measured and improved.

---

## 🌳 Platform Decision Tree

```
START
  │
  ├── Fewer than 50 engineers at the company?
  │      │
  │      └── YES → Vendor SaaS (Port, Cortex)
  │             "Build" cost isn't economical
  │
  ├── 50 – 500 engineers?
  │      │
  │      └── YES → Backstage (self-host) + Crossplane / Terraform
  │             Open source, flexibility
  │
  └── > 500 engineers?
         │
         └── YES → Backstage + custom plugins, dedicated platform org
                In-house build, vendor-neutral
```

---

## 🪜 IDP Maturity Model

### Level 1: "Wiki + Slack"
- Docs live in Confluence
- Ask "@platform-team on Slack"
- New service: 2 weeks

### Level 2: "Scripts + Tooling"
- `cookiecutter` templates
- Bash scripts like "new-service.sh"
- New service: 3 days

### Level 3: "Self-Service Portal"
- Backstage Catalog + Scaffolder
- Standardized golden paths
- New service: 30 minutes

### Level 4: "Platform-as-Product"
- NPS measurement, developer feedback loop
- Platform team's roadmap, OKRs
- Cost transparency (Kubecost)
- New service: 5 minutes

### Level 5: "Compositional Platform"
- User picks their own building blocks (DB, queue, cache)
- Compliance is automatic (SLSA, SOC2 controls)
- Multi-tenant, multi-cloud
- New service: 2 minutes + "compose"

> 🎯 **Realistic target (2026, mid-to-large company):** Level 3-4. Level 5 is rare.

---

## 🏗️ "Spin Up a New Microservice" — Golden Path Anatomy

```
$ portal.<ORG>.com → "New Service"
  │
  ▼
[Form]
  ? Service type:    [REST API ▼ | gRPC | Worker | Cron]
  ? Language:        [Go ▼ | Python | Node | Java]
  ? Database needed: [Postgres ▼ | MongoDB | None]
  ? Service name:    payments-api
  ? Owner team:      @payments-team
  ? Cloud:           AWS
  ? Region:          eu-west-1
  ? Environment:     [dev, staging, prod]

  [Create]
  │
  ▼
[Backend: done in the background over 5-10 minutes]
  ✓ GitHub repo created (from template)
    - Dockerfile, src/, README, CODEOWNERS, CI workflow
  ✓ Branch protection + required reviews
  ✓ Terraform PR (RDS, IAM role, S3 bucket)
  ✓ ArgoCD Application (in the k8s-config repo)
  ✓ Datadog dashboard (template for the service)
  ✓ PagerDuty rotation (owner team)
  ✓ Slack channel #payments-api-alerts
  ✓ Registered in Backstage Catalog
  ✓ TechDocs (auto-generated README)
  ✓ Vault path provisioned (secret store)
  ✓ Welcome PR: "Your service's first endpoint is ready, you can deploy"
  │
  ▼
[Result]
  Developer: "git clone <REPO> && deploy"
  Total time: ~10 minutes
  Developer's platform knowledge required: 0
```

---

## 🛠️ Backstage — A Practical Start

### Installation (Helm)
```bash
helm install backstage backstage/backstage \
  -n backstage --create-namespace \
  --set ingress.enabled=true \
  --set ingress.host=portal.<DOMAIN>
```

### Catalog: Service Inventory
```yaml
# catalog-info.yaml (at the root of every repo)
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: payments-api
  description: Payments REST API
  annotations:
    github.com/project-slug: <ORG>/payments-api
    backstage.io/techdocs-ref: dir:.
    pagerduty.com/integration-key: <KEY>
    grafana/dashboard-selector: "tag in (payments,api)"
spec:
  type: service
  lifecycle: production
  owner: payments-team
  system: payments
  providesApis:
    - payments-rest-api
  dependsOn:
    - resource:postgres-payments-db
```

### Scaffolder Template: New Service
```yaml
# templates/golang-rest-api/template.yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: golang-rest-api
  title: Go REST API
spec:
  parameters:
    - title: Service info
      properties:
        serviceName: {type: string, pattern: '^[a-z][a-z0-9-]+$'}
        ownerTeam: {type: string}
        databaseNeeded: {type: boolean, default: false}

  steps:
    - id: fetch
      name: Fetch template
      action: fetch:template
      input:
        url: ./skeleton
        values: {serviceName: '${{ parameters.serviceName }}'}

    - id: publish
      name: Create GitHub repo
      action: publish:github
      input:
        repoUrl: github.com?owner=<ORG>&repo=${{ parameters.serviceName }}
        defaultBranch: main
        gitCommitMessage: 'Initial commit from scaffolder'

    - id: register
      name: Register in catalog
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps.publish.output.repoContentsUrl }}
        catalogInfoPath: '/catalog-info.yaml'

  output:
    links:
      - title: Repository
        url: ${{ steps.publish.output.remoteUrl }}
      - title: View in Catalog
        icon: catalog
        entityRef: ${{ steps.register.output.entityRef }}
```

### TechDocs: Markdown as Docs
```yaml
# The repo's mkdocs.yml
site_name: 'Payments API'
plugins:
  - techdocs-core
nav:
  - Home: index.md
  - Architecture: arch.md
  - Runbook: runbook.md
```

Backstage pulls the repo, renders the markdown, and makes it searchable.

---

## 🎯 IDP's "Must-Have" Components

| Component | Why |
|---|---|
| **Service catalog** | See services, ownership, and dependencies from a single place |
| **Golden path / scaffolder** | "Spin up a new service" in 5 minutes |
| **TechDocs** | Docs live next to the code, so they don't go stale |
| **Search** | "Which service uses Postgres?" answered in 5 seconds |
| **Dashboards** | The service owner sees metrics, logs, and deploys |
| **Cost insights** | Who's spending how much (Kubecost, FinOps) |
| **On-call** | PagerDuty rotation is visible from the portal |
| **Compliance** | "Which service is under SOC2 control?" — automatic |

---

## 📊 Platform-as-Product Metrics

| Metric | Target | How it's measured |
|---|---|---|
| **NPS** (developer satisfaction) | > 30 | Quarterly survey |
| **Lead time: idea → prod** | < 1 day | Tracked in Backstage |
| **MTTR** (issue → resolved) | < 4 hours | PagerDuty + tracking |
| **Onboarding time** | < 1 week | Measured on new engineers |
| **Self-service rate** | > 80% | DevOps tickets / total requests |
| **Platform availability** | > 99.9% | Backstage uptime |
| **Adoption rate** | > 90% | Services registered in portal / total |

> 🔑 **Rule:** A platform that doesn't set targets can't answer the
> question "is this even needed?"

---

## 🚧 Build vs Buy Tradeoff

### Build (Backstage)
- ✅ Flexible, custom plugins
- ✅ Open source, no vendor lock-in
- ✅ Fully integrated into the internal ecosystem
- ❌ Maintenance burden (upgrades, security patches)
- ❌ Plugin writing/maintenance
- ❌ First value only after 2-3 months

### Buy (Port, Cortex, OpsLevel)
- ✅ Setup: one day
- ✅ Vendor-managed, they handle upgrades
- ✅ First value in 1 week
- ❌ Monthly SaaS cost ($X / dev / month)
- ❌ Custom features require a request to the vendor
- ❌ Vendor lock-in

> 🔑 **In practice:** **Start with buy**, **migrate to Backstage
> later**. Test the hypothesis at low cost.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Do this instead |
|---|---|---|
| Platform is "mandatory" — non-users get pushed out | Creates internal vendor lock-in | Self-service + escape hatch |
| Not measuring NPS | You don't know why developers aren't using it | Quarterly survey |
| "You can't ship to prod without going through us" | Bottleneck, demoralizing | Self-service + audit |
| Every guardrail is a hard block | Bypasses start happening (shadow IT) | Soft warning + exception PR |
| Platform team has no backlog of its own | Purely reactive — just answers tickets | Roadmap, OKRs, demo cycle |
| Backstage instance is set up, nobody uses it | No adoption marketing | Mandatory onboarding, demos, evangelism |
| Catalog has no auto-discovery, it's manual | Service list is a month stale | GitHub crawler / pipeline-driven |
| Documentation lives in Confluence, code lives elsewhere | Docs go stale | TechDocs (markdown next to the code) |
| No single sign-on | Separate login for every tool | OIDC for everyone |
| No cost transparency | Nobody knows "who's spending what" | Kubecost, a FinOps section |
| Platform team is 2 people serving 500 engineers | Burnout, quality drops | Minimum 1:50 ratio |
| 5 different portals (CI, CD, monitoring, secrets, ...) | Context switching | One portal, embedded plugins |

---

## 📋 IDP Adoption Roadmap

```
[ ] Quarter 1 — Discovery
    [ ] Developer survey: what are the top 5 friction points?
    [ ] Manually build the catalog for the top 10 services
    [ ] Baseline metrics: lead time, ticket count, NPS

[ ] Quarter 2 — MVP
    [ ] Backstage / Port setup (HA, SSO)
    [ ] First golden path: the most commonly created service type
    [ ] Automatically register the top 10 services in the catalog
    [ ] TechDocs for the first 5 services
    [ ] Dashboard: per-service Datadog / Grafana embed

[ ] Quarter 3 — Adoption
    [ ] 2-3 more golden paths
    [ ] CI/CD integration (deploy button)
    [ ] PagerDuty rotation visible from the portal
    [ ] Onboarding: a "portal tour" for new devs
    [ ] Measure NPS (target: > 30)

[ ] Quarter 4 — Optimization
    [ ] Cost insights (Kubecost)
    [ ] Compliance dashboards (SOC2 controls visible)
    [ ] Service mesh integration
    [ ] Measure platform team OKRs
```

---

## 📚 References

- **Team Topologies** (Skelton, Pais) — Stream-aligned and Platform team examples
- **Backstage** — backstage.io
- **Port** — getport.io
- **Cortex** — cortex.io
- **OpsLevel** — opslevel.com
- **Platform Engineering** — platformengineering.org
- **CNCF Platforms WG** — github.com/cncf/sig-app-delivery
- [`Backstage-Setup.md`](Backstage-Setup.md)
- [`Golden-Paths.md`](Golden-Paths.md)
- [`Platform-as-Product.md`](Platform-as-Product.md)
- [`00-Culture/Team-Topologies.md`](../00-Culture/Team-Topologies.md)

---

> *"Platform engineering is an internal product delivered **to other
> engineers**. Once the investment pays off, the developer asks 'how
> did we ever live the old way' — that's the purest sign of success."*
