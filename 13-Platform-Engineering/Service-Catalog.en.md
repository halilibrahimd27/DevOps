---
description: "A guide to the practical ways of keeping a service inventory with Backstage Catalog, assigning ownership, viewing the dependency graph, and mapping on-call."
tags:
  - Platform Engineering
  - SRE
  - Incident Response
---
# Service Catalog — Service Inventory, Ownership, Dependency Graph

> *"You have 50 microservices. If you can't answer 'who owns service
> X?' in 5 minutes, **there's no service — just orphaned YAML
> files**. The catalog is your team's **discoverability**."*

This guide covers the practical ways to keep services in inventory
with Backstage Catalog (or an alternative), assign ownership, and
view the dependency graph.

---

## 🎯 What Is a Service Catalog?

> **Service Catalog**: An inventory that lets you see all services,
> ownership, dependencies, documentation, and lifecycle **in one
> place**.

```
[Catalog UI]
  │
  ├── Component (service, library, website)
  │     ├── Owner: payments-team
  │     ├── Lifecycle: production
  │     ├── System: payments
  │     ├── DependsOn: postgres-payments, auth-svc
  │     ├── ProvidesAPIs: payments-rest-api
  │     └── ConsumesAPIs: notification-api
  │
  ├── Resource (DB, queue, cache)
  ├── API (OpenAPI / GraphQL spec)
  ├── System (group of services)
  └── User / Group (ownership)
```

---

## 📋 Backstage Catalog Entity Types

| Kind | What |
|---|---|
| `Component` | Runnable code (service, web, library) |
| `Resource` | A consumed resource (DB, S3, Vault path) |
| `API` | The API spec a service exposes |
| `System` | Related components (e.g., "payments domain") |
| `Domain` | Multiple systems (e.g., "Commerce") |
| `User` | A person |
| `Group` | A team |
| `Location` | Catalog source (Git URL) |

---

## 📝 catalog-info.yaml Example

At the root of every service repo:
```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: payments-api
  description: "Payments REST API + Stripe integration"
  annotations:
    github.com/project-slug: <ORG>/payments-api
    backstage.io/techdocs-ref: dir:.
    pagerduty.com/integration-key: <KEY>
    grafana/dashboard-selector: "tag in (payments,api)"
    sentry.io/project-slug: payments-api
    sonarqube.org/project-key: <ORG>_payments-api
    datadoghq.com/dashboard-url: 'https://app.datadoghq.com/dash/integration/payments'
    backstage.io/kubernetes-id: payments-api
    backstage.io/kubernetes-namespace: payments
  tags:
    - go
    - rest
    - payments
  links:
    - url: https://payments.<DOMAIN>
      title: Production
      icon: web
    - url: https://staging-payments.<DOMAIN>
      title: Staging
      icon: web
spec:
  type: service
  lifecycle: production
  owner: group:payments-team
  system: payments
  providesApis:
    - payments-rest-api
  consumesApis:
    - auth-rest-api
    - notification-rest-api
  dependsOn:
    - resource:postgres-payments
    - resource:redis-payments
    - component:auth-service
---
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: payments-rest-api
  description: "Payments API (REST)"
spec:
  type: openapi
  lifecycle: production
  owner: group:payments-team
  system: payments
  definition: |
    openapi: 3.0.0
    info:
      title: Payments API
      version: 1.4.0
    paths:
      /v1/charges:
        post: ...
---
apiVersion: backstage.io/v1alpha1
kind: Resource
metadata:
  name: postgres-payments
  description: "Payments primary DB"
spec:
  type: database
  lifecycle: production
  owner: group:platform-team
  system: payments
```

---

## 👥 Ownership Model

### Single-Owner Rule
- Every service must have **one** owner team
- "Co-owned" → confusion, nobody actually owns it
- The Group entity is defined in Backstage:

```yaml
apiVersion: backstage.io/v1alpha1
kind: Group
metadata:
  name: payments-team
  description: "Payments squad"
spec:
  type: team
  parent: commerce-domain
  children: []
  members:
    - alice
    - bob
    - carol
```

### Ownership Transfer
Transferring a service from one team to another:
1. RFC: why + date
2. catalog-info.yaml `owner` field gets updated
3. CODEOWNERS gets updated
4. PagerDuty rotation transfer
5. Slack channel transfer / archive
6. Documentation update

---

## 🔗 Dependency Graph

### Visual Discovery
In the Backstage UI, the **System Diagram**:

```
          ┌─────────┐
          │ Frontend │
          └────┬────┘
               │
        ┌──────┼──────┐
        ▼      ▼      ▼
    ┌──────┐ ┌──────┐ ┌──────┐
    │ Auth │ │Payment│ │Catalog│
    └──┬───┘ └──┬───┘ └──┬───┘
       │        │        │
       ▼        ▼        ▼
    ┌──────┐ ┌──────┐ ┌──────┐
    │Users │ │ DB   │ │ DB   │
    │ DB   │ │ Redis│ │ ES   │
    └──────┘ └──────┘ └──────┘
```

### Identifying Dependencies
- **Static**: `dependsOn`, `consumesApis` in catalog-info.yaml
- **Dynamic**: trace data (OTel) → automatic graph
- **Verify**: is the dependency changed in the PR correct (CI gate)

### Cross-Team Dependency Alert
```yaml
# Auto-detect: a team added a dependency on another team's service
- alert: NewCrossTeamDependency
  expr: backstage_dependencies_added{across_team="true"} > 0
  annotations:
    summary: "Cross-team dependency: {{ $labels.from }} → {{ $labels.to }}"
```

---

## 🚦 Lifecycle Management

| Lifecycle | What it means | Example |
|---|---|---|
| `experimental` | Beta, not ready for use | New AI feature |
| `production` | Actively used | Most services |
| `deprecated` | Sunset planned | Old v1 API |
| `archived` | No longer running | An old 2018 service |

### Deprecation Flow
```yaml
spec:
  lifecycle: deprecated
  links:
    - url: <NEW_SERVICE_URL>
      title: "Replacement: payments-v2"
```

→ The Catalog UI shows a deprecated tag, and users get redirected to
the new service.

---

## 🔍 Catalog Discovery

### Automatic Discovery (Recommended)
```yaml
# app-config.yaml
catalog:
  providers:
    github:
      providerId:
        organization: '<ORG>'
        catalogPath: '/catalog-info.yaml'
        filters:
          branch: 'main'
          repository: '.*'
        schedule:
          frequency: { minutes: 30 }
```

→ Any repo in the org with a `catalog-info.yaml` gets included
automatically.

### CI Gate: catalog-info Required
```yaml
# .github/workflows/catalog-validate.yml
- name: Validate catalog-info.yaml exists
  run: test -f catalog-info.yaml || (echo "::error::catalog-info.yaml missing" && exit 1)

- name: Validate schema
  run: backstage-cli catalog:validate catalog-info.yaml

- name: Validate owner exists
  run: |
    OWNER=$(yq '.spec.owner' catalog-info.yaml)
    # Hit the Backstage API, check whether the owner exists
```

---

## 📊 Catalog Health Metrics

### Quality KPIs
| Metric | Target |
|---|---|
| **Services registered in the catalog** | 95%+ |
| **catalog-info.yaml + ownership** | 100% |
| **TechDocs integrated** | 80%+ |
| **Lifecycle field populated** | 100% |
| **Dependencies defined** | 70%+ |
| **API spec provided (Component)** | 50%+ |
| **Quarterly orphaned services** (unowned) | < 5% |

### Gap Report
```sql
-- Services in Backstage with missing fields
SELECT name FROM components
WHERE owner IS NULL OR system IS NULL OR lifecycle IS NULL;
```

---

## 🛠️ Search

```typescript
// Backstage search plugin
const searchClient = useApi(searchApiRef);
const results = await searchClient.query({
  term: 'payments',
  filters: {
    kind: ['Component', 'API'],
    'spec.type': ['service'],
  },
});
```

→ Cross-resource search: "payments" → component, API, dashboard, doc.

---

## 🔄 Service Onboarding (Catalog Side)

### New Service Flow
```
1. A repo is created from the scaffolder template
   → catalog-info.yaml is included automatically
2. The catalog provider discovers it within 30 minutes
3. It appears in the Backstage UI
4. PagerDuty / Datadog plugins are connected
```

### Bringing an Existing Service into the Catalog
```bash
# Add catalog-info.yaml to the service repo
gh repo clone <ORG>/legacy-service
cd legacy-service
cat > catalog-info.yaml <<EOF
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: legacy-service
spec:
  type: service
  lifecycle: production
  owner: group:legacy-maintenance-team
EOF
git add catalog-info.yaml
git commit -m "chore: register in Backstage catalog"
gh pr create
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Do this instead |
|---|---|---|
| Catalog is manual YAML, kept outside the repo | Drift, goes stale | Per-repo catalog-info.yaml |
| No owner / "co-owned" | Shared responsibility = nobody's | One team, explicit |
| Lifecycle always "production" | Deprecated stuff still shows "production" | Annual review, deprecate |
| Dependencies not defined | Graph is incomplete | dependsOn / consumesApis |
| Orphaned services in the catalog | Orphaned, goes stale | Quarterly orphan review |
| No TechDocs link | Docs live in Confluence, go stale | TechDocs annotation |
| No API spec | Consumers ask "what's the endpoint?" | OpenAPI / GraphQL spec |
| Too many custom annotations | UI gets cluttered | Standardize the annotation list |
| Discovery is manual, not automatic | New services get added by hand | GitHub provider |
| Catalog adoption < 50% | The tool isn't producing real value | Make onboarding mandatory |
| No search | "Which service does X?" goes unanswered | Enable the search plugin |

---

## 📋 Service Catalog Discipline Checklist

```
[ ] Backstage Catalog installed (or equivalent)
[ ] Automatic discovery (GitHub provider)
[ ] All prod services registered (>95%)
[ ] Every service has an owner team
[ ] Group entities defined
[ ] Lifecycle field set for every service
[ ] System / Domain hierarchy
[ ] dependsOn / consumesApis defined (>70%)
[ ] API spec integrated (OpenAPI / GraphQL)
[ ] TechDocs annotation
[ ] PagerDuty / Datadog / Sentry integration
[ ] CI gate: catalog-info.yaml required
[ ] Quarterly: orphan services review
[ ] Quarterly: deprecated services cleanup
[ ] Adoption metric dashboard (% registered)
[ ] Onboarding: new-engineer catalog tour
[ ] Search works (cross-resource)
```

---

## 📚 References

- **Backstage Catalog Docs** — backstage.io/docs/features/software-catalog
- **Backstage System Model** — backstage.io/docs/features/software-catalog/system-model
- **Roadie** — roadie.io (Backstage SaaS)
- **Cortex** — cortex.io (Catalog-first IDP)
- [`Internal-Developer-Platform.md`](Internal-Developer-Platform.md)
- [`Backstage-Setup.md`](Backstage-Setup.md)
- [`Golden-Paths.md`](Golden-Paths.md)
- [`Platform-as-Product.md`](Platform-as-Product.md)
- [`00-Culture/Team-Topologies.md`](../00-Culture/Team-Topologies.md)

---

> *"The catalog isn't a 'fancy directory' — it's the **organization's
> service map**. It's the one place an engineer can say 'I know
> everything here' after 6 months; **the fallback for a team that
> grew without a map**."*
