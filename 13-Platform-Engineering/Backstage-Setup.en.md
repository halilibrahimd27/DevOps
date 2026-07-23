---
description: "A guide to setting up Spotify's open-source Backstage developer portal from scratch to prod-grade: catalog, scaffolder, TechDocs, plugins, and OIDC auth steps."
tags:
  - Platform Engineering
  - Kubernetes
  - Security
  - Template
---
# Backstage Setup — The Practical Setup of an IDP

> *"Backstage is not 'the child of Confluence + Jenkins + Datadog'.
> It's designed as a **developer portal** — code, docs, dashboards,
> and service catalog **in one place**. Set it up right and it takes 1 week; set it up wrong and it takes 6 months."*

This guide gives you concrete steps and plugin recommendations for
setting up Spotify's open-source Backstage from scratch, all the way to a prod-grade setup.

---

## 🎯 Backstage Anatomy

```
[Backstage Portal]
├── Catalog          ← service inventory (who owns it, where)
├── Scaffolder       ← "create new service" templates
├── TechDocs         ← markdown-as-docs (per-service)
├── Search           ← global cross-resource search
├── Plugins          ← K8s, Datadog, GitHub, Jira, ...
└── Auth             ← OIDC (Keycloak / Auth0 / GitHub)
```

---

## 🚀 Step 1: Run It Locally

### Pre-requisites
- Node.js 20+
- yarn
- Docker (for PostgreSQL)

### Create app
```bash
npx @backstage/create-app@latest

# Answers to the prompts:
# ? Project name: company-portal
# ? Database: PostgreSQL (for production), SQLite (for local)

cd company-portal
yarn install
yarn dev
# → localhost:3000
```

### First catalog entry
```yaml
# catalog-info.yaml (example from the Backstage repo)
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: example-service
  description: Sample service
  annotations:
    github.com/project-slug: <ORG>/example-service
    backstage.io/techdocs-ref: dir:.
spec:
  type: service
  lifecycle: production
  owner: platform-team
```

---

## 🏗️ Step 2: Production Deployment

### Via Helm chart to K8s
```bash
helm repo add backstage https://backstage.github.io/charts
helm install backstage backstage/backstage \
  -n backstage --create-namespace \
  -f values.yaml
```

### `values.yaml`
```yaml
backstage:
  image:
    repository: <REGISTRY>/backstage
    tag: <VERSION>
    pullPolicy: IfNotPresent

  replicas: 2

  podSecurityContext:
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000

  containerSecurityContext:
    runAsNonRoot: true
    readOnlyRootFilesystem: true

  appConfig:
    app:
      title: "Company Portal"
      baseUrl: "https://portal.<DOMAIN>"
    backend:
      baseUrl: "https://portal.<DOMAIN>"
      cors:
        origin: "https://portal.<DOMAIN>"
      database:
        client: pg
        connection:
          host: ${POSTGRES_HOST}
          port: 5432
          user: ${POSTGRES_USER}
          password: ${POSTGRES_PASSWORD}
          ssl: true

    auth:
      providers:
        oidc:
          development:
            metadataUrl: https://<IDP>/.well-known/openid-configuration
            clientId: ${OIDC_CLIENT_ID}
            clientSecret: ${OIDC_CLIENT_SECRET}

    integrations:
      github:
        - host: github.com
          token: ${GITHUB_TOKEN}

    catalog:
      providers:
        github:
          providerId:
            organization: '<ORG>'
            catalogPath: '/catalog-info.yaml'
            filters:
              branch: 'main'

  resources:
    requests: {cpu: 250m, memory: 512Mi}
    limits: {cpu: 1000m, memory: 2Gi}

ingress:
  enabled: true
  className: nginx
  host: portal.<DOMAIN>
  tls:
    - hosts: [portal.<DOMAIN>]
      secretName: backstage-tls
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod

postgresql:
  enabled: true   # or external Postgres
  auth:
    database: backstage
```

> 🔑 **In production:** prefer an external managed Postgres (RDS / CNPG).

---

## 🔐 Step 3: SSO Authentication

### OIDC (Keycloak / Google / Auth0)
```typescript
// packages/backend/src/plugins/auth.ts
import { providers } from '@backstage/plugin-auth-backend';

export default async function createPlugin(env: PluginEnvironment): Promise<Router> {
  return await createRouter({
    ...env,
    providerFactories: {
      oidc: providers.oidc.create({
        signIn: {
          resolver: providers.oidc.resolvers.emailLocalPartMatchingUserEntityName(),
        },
      }),
    },
  });
}
```

### GitHub login (simple)
```yaml
auth:
  providers:
    github:
      development:
        clientId: ${AUTH_GITHUB_CLIENT_ID}
        clientSecret: ${AUTH_GITHUB_CLIENT_SECRET}
```

---

## 📦 Step 4: Catalog Discovery

### GitHub auto-discovery
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
          repository: '.*'   # scan all repos
        schedule:
          frequency: { minutes: 30 }
          timeout: { minutes: 3 }
```

→ If any repo in the org has a `catalog-info.yaml`, it's automatically added to the catalog.

### Repo template
```yaml
# In every service repo's catalog-info.yaml:
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: payments-api
  annotations:
    github.com/project-slug: <ORG>/payments-api
    backstage.io/techdocs-ref: dir:.
    pagerduty.com/integration-key: <KEY>
    grafana/dashboard-selector: "tag in (payments,api)"
    sentry.io/project-slug: payments-api
    sonarqube.org/project-key: <ORG>_payments-api
spec:
  type: service
  lifecycle: production
  owner: payments-team
  system: payments
  providesApis:
    - payments-rest-api
  dependsOn:
    - resource:postgres-payments-db
    - component:auth-service
```

---

## 🏗️ Step 5: Scaffolder — Golden Path

```yaml
# templates/golang-rest-api/template.yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: golang-rest-api
  title: Go REST API
  description: New Go REST API + DB + ArgoCD app
  tags: [go, rest, postgres]
spec:
  owner: platform-team
  type: service

  parameters:
    - title: Service info
      required: [serviceName, ownerTeam]
      properties:
        serviceName:
          type: string
          pattern: '^[a-z][a-z0-9-]+$'
          ui:autofocus: true
        description: {type: string}
        ownerTeam:
          type: string
          enum: [platform-team, payments-team, catalog-team]
        databaseNeeded: {type: boolean, default: false}

    - title: Cloud + Region
      properties:
        cloud:
          type: string
          enum: [aws, gcp]
        region:
          type: string
          enum: [eu-west-1, eu-central-1, us-east-1]

  steps:
    - id: fetch
      name: Fetch template
      action: fetch:template
      input:
        url: ./skeleton
        values:
          serviceName: ${{ parameters.serviceName }}
          ownerTeam: ${{ parameters.ownerTeam }}
          dbNeeded: ${{ parameters.databaseNeeded }}

    - id: publish
      name: Create GitHub repo
      action: publish:github
      input:
        repoUrl: github.com?owner=<ORG>&repo=${{ parameters.serviceName }}
        defaultBranch: main
        protectDefaultBranch: true
        requiredApprovingReviewCount: 1
        deleteBranchOnMerge: true
        gitCommitMessage: 'Initial commit from scaffolder'
        gitAuthorName: 'Backstage Bot'

    - id: register
      name: Register in catalog
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps.publish.output.repoContentsUrl }}
        catalogInfoPath: '/catalog-info.yaml'

    - id: create-argocd-app
      name: Create ArgoCD application
      action: argocd:create-resources
      input:
        appName: ${{ parameters.serviceName }}-prod
        namespace: ${{ parameters.serviceName }}
        repoUrl: ${{ steps.publish.output.remoteUrl }}
        path: k8s/

    - id: create-db
      name: Provision DB (if needed)
      if: ${{ parameters.databaseNeeded }}
      action: terraform:apply
      input:
        directory: ./terraform/modules/postgres
        vars:
          db_name: ${{ parameters.serviceName }}
          environment: prod

  output:
    links:
      - title: Repository
        url: ${{ steps.publish.output.remoteUrl }}
      - title: View in Catalog
        icon: catalog
        entityRef: ${{ steps.register.output.entityRef }}
      - title: ArgoCD Application
        url: 'https://argocd.<DOMAIN>/applications/${{ parameters.serviceName }}-prod'
```

> 🔑 One form → repo + branch protection + ArgoCD app + DB. Service up in **5 minutes**.

---

## 📚 Step 6: TechDocs (Markdown-as-Docs)

### At the root of the repo:
```yaml
# mkdocs.yml
site_name: 'Payments API'
plugins:
  - techdocs-core
nav:
  - Home: index.md
  - Architecture: architecture.md
  - API Reference: api.md
  - Runbook: runbook.md
  - Postmortem History: postmortems/index.md
```

```
docs/
├── index.md
├── architecture.md
├── api.md
├── runbook.md
└── postmortems/
    ├── index.md
    └── 2026-04-12-payment-down.md
```

### Backstage TechDocs
- Pulls markdown and renders it
- Included in search
- Visible in the Backstage UI

> 🔑 **Docs live next to the code** = they don't go stale. 10x cleaner than Confluence.

---

## 🔌 Step 7: Plugins

### The most valuable plugins (2026)

| Plugin | Niche |
|---|---|
| **Kubernetes** | See a service's K8s pods in the portal |
| **GitHub Actions** | CI status, deploy history |
| **ArgoCD** | Application sync status |
| **Datadog / Grafana** | Embed dashboard |
| **PagerDuty** | On-call rotation visible |
| **SonarQube** | Code quality |
| **Sentry** | Error tracking |
| **Jira / Linear** | Ticket integration |
| **Cost Insights** (Kubecost) | Cost per service |
| **TechDocs** | Markdown docs |
| **Tech Radar** | Technology adoption status |
| **API Docs** | OpenAPI / GraphQL specs |

### Plugin install
```bash
yarn add @backstage/plugin-kubernetes
```

```typescript
// packages/app/src/App.tsx
import { KubernetesPage } from '@backstage/plugin-kubernetes';

<Route path="/kubernetes" element={<KubernetesPage />} />
```

---

## 🛡️ Step 8: Security Hardening

```yaml
# 1. RBAC permissions
permission:
  enabled: true
  policy:
    file: ./permission-policy.csv
```

```csv
# permission-policy.csv
p, role:default/admin, catalog.entity.delete, allow
p, role:default/admin, catalog.entity.create, allow
p, role:default/developer, catalog.entity.read, allow
g, group:default/platform-team, role:default/admin
g, group:default/everyone, role:default/developer
```

```yaml
# 2. CSP headers
backend:
  csp:
    connect-src: ["'self'", 'https:']
    img-src: ["'self'", 'data:', 'https:']

# 3. Rate limit
backend:
  reading:
    allow:
      - host: github.com
      - host: <ORG>.github.io
```

---

## 📊 Step 9: Adoption Metrics

```typescript
// Renders a dashboard (like cost insights in Backstage)
const adoptionMetrics = {
  totalServices: catalog.entities.length,
  servicesWithTechDocs: catalog.entities.filter(e => e.metadata.annotations?.['backstage.io/techdocs-ref']).length,
  goldenPathUsage: scaffolder.executions.last30Days,
  avgOnboardTime: scaffolder.avgDuration,  // target < 10 min
  nps: surveys.lastNPS,                     // target > 30
};
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Do this instead |
|---|---|---|
| `catalog-info.yaml` added manually for every service | 100 services = 100 manual steps | GitHub auto-discovery |
| One root `app-config.yaml` | Hard to maintain | Per-environment config split |
| SQLite in production | Doesn't work with multiple replicas | PostgreSQL |
| Auth disabled "for convenience" | Public catalog → information leak | OIDC + RBAC |
| Too many plugins (50+) | Cluttered UI, performance hit | Only what's actually used |
| Adoption not measured | "We have Backstage" claim, nobody uses it | NPS + metric dashboard |
| Backstage upgrades neglected | Goes stale, security gaps | Quarterly upgrade |
| Custom plugins not in Git | Drift, lost work | Mono-repo + GitOps |
| Saying "Backstage is mandatory" | Bypass culture | Self-service + escape hatch |
| Scaffolder templates go stale | The "how to spin up a new service" doc bloats | Quarterly template review |
| Deprecated services still in the catalog | Wrong information | Lifecycle: production / deprecated / experimental |

---

## 📋 Backstage Production Checklist

```
[ ] PostgreSQL HA (managed or CNPG)
[ ] Backstage replicas: 2+
[ ] Ingress + TLS
[ ] OIDC authentication
[ ] RBAC permissions enabled
[ ] GitHub catalog auto-discovery
[ ] Scaffolder: at least 1 golden path
[ ] TechDocs: for at least 5 services
[ ] Plugin: K8s, ArgoCD, GitHub Actions
[ ] Plugin: PagerDuty (on-call visible)
[ ] Plugin: Cost Insights (Kubecost)
[ ] Search working (cross-resource)
[ ] Catalog ownership: every service has an owner
[ ] Lifecycle metadata up to date
[ ] Backstage itself is in the catalog
[ ] Onboarding doc: how new engineers use it
[ ] NPS quarterly survey
[ ] Adoption dashboard
[ ] Quarterly Backstage upgrade
[ ] DR: cluster down → bootstrap
```

---

## 📚 References

- **Backstage Docs** — backstage.io/docs
- **Backstage Plugin Marketplace** — backstage.io/plugins
- **Spotify Backstage Blog** — backstage.spotify.com
- **CNCF Backstage** — github.com/backstage/backstage
- **Roadie** — roadie.io (Backstage SaaS)
- [`Internal-Developer-Platform.md`](Internal-Developer-Platform.md)
- [`Golden-Paths.md`](Golden-Paths.md)
- [`Service-Catalog.md`](Service-Catalog.md)
- [`00-Culture/Team-Topologies.md`](../00-Culture/Team-Topologies.md)

---

> *"Backstage delivers value not on the day it's **installed**, but on
> the day it's **used**. A team that doesn't measure adoption installs
> **Backstage's shell** and forgets to fill in what's inside."*
