---
description: "A guide to setting up ArgoCD from scratch to production-grade: HA, SSO, RBAC, AppProject, notifications, and multi-cluster pull-based GitOps with ApplicationSet."
tags:
  - GitOps
  - ArgoCD
  - Kubernetes
  - Security
  - Platform Engineering
---
# ArgoCD Setup — Production-Grade GitOps Installation

> *"GitOps means **no difference** between what's in the cluster and what's
> written in Git. ArgoCD continuously measures and corrects that
> difference — you own the written intent, it's responsible for applying it."*

This guide takes an ArgoCD installation from scratch to production-grade:
HA, SSO, RBAC, AppProject, Notifications, and multi-cluster with ApplicationSet.

---

## 🎯 Where ArgoCD Fits

```
[Developer] → [PR] → [Git: k8s-config repo]
                            │
                            │ (ArgoCD pull)
                            ▼
                       ┌──────────┐
                       │ ArgoCD   │ ─── continuously reconciles
                       │ controller│      desired ↔ actual
                       └────┬─────┘
                            │
                ┌───────────┼───────────┐
                ▼           ▼           ▼
            DEV K8s     STAGING K8s    PROD K8s
```

ArgoCD runs **pull-based**:
- Cluster credentials live **in ArgoCD**, not in CI
- CI only builds the image and opens a tag-bump PR to Git
- Every 3 minutes (default), ArgoCD pulls Git and compares it to the cluster
- If there's drift: heal it (auto-sync) or alert (manual)

---

## 🏗️ Installation (HA, Production)

### Helm chart (recommended)
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd \
  -n argocd --create-namespace \
  --version <CHART_VERSION> \
  -f argocd-values.yaml
```

### `argocd-values.yaml` (key sections)
```yaml
global:
  domain: argocd.<DOMAIN>

# HA: 3 replica controller, redis-ha, server multi-replica
controller:
  replicas: 1   # Argo recommends 1 controller for now (sharded HA in roadmap)
  resources:
    requests: {cpu: 250m, memory: 512Mi}
    limits: {cpu: 1000m, memory: 2Gi}

server:
  replicas: 3
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 6
  ingress:
    enabled: true
    ingressClassName: nginx
    hostname: argocd.<DOMAIN>
    tls: true
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
      nginx.ingress.kubernetes.io/backend-protocol: "GRPC"

repoServer:
  replicas: 3

applicationSet:
  enabled: true
  replicas: 2

notifications:
  enabled: true

dex:
  enabled: false   # we use external OIDC, no need for dex

redis-ha:
  enabled: true   # production: HA Redis (sentinel)

configs:
  params:
    server.insecure: false
    application.namespaces: "*"   # lets ArgoCD read its CRDs in every ns
  cm:
    timeout.reconciliation: 180s
    timeout.hard.reconciliation: 0s
    accounts.<ACCOUNT_NAME>: apiKey, login
    resource.exclusions: |
      - apiGroups:
          - cilium.io
        kinds:
          - CiliumIdentity
        clusters:
          - "*"
```

> 🔑 **Notes:**
> - `controller.replicas: 1` is still recommended in 2026; sharding isn't GA yet
> - Without Redis-HA, ArgoCD loses its cache on restarts
> - `ingress.backend-protocol: GRPC` — the `argocd` CLI uses gRPC

---

## 🔐 SSO (OIDC) — Do This on Day One

The default `admin` user is **forbidden**. Wire it to SSO.

### Initial admin password (one-time only)
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```
First login → SSO config → disable the admin user:
```yaml
configs:
  cm:
    admin.enabled: false
```

### OIDC config (e.g., Keycloak / Auth0 / Google Workspace)
```yaml
configs:
  cm:
    url: https://argocd.<DOMAIN>
    oidc.config: |
      name: <PROVIDER_NAME>
      issuer: https://<IDP_URL>
      clientID: argocd
      clientSecret: $oidc.clientSecret
      requestedScopes: ["openid", "profile", "email", "groups"]
      requestedIDTokenClaims:
        groups:
          essential: true
  secret:
    extra:
      oidc.clientSecret: <REDACTED>
```

### RBAC — group-based
```yaml
configs:
  rbac:
    policy.csv: |
      # role definition
      p, role:dev, applications, get, */*, allow
      p, role:dev, applications, sync, dev/*, allow
      p, role:dev, applications, action/*, dev/*, allow

      p, role:platform, applications, *, */*, allow
      p, role:platform, clusters, *, *, allow
      p, role:platform, repositories, *, *, allow

      p, role:read-only, applications, get, */*, allow

      # group → role binding (OIDC group claim)
      g, <ORG>:platform-team, role:platform
      g, <ORG>:dev-team, role:dev
      g, <ORG>:everyone, role:read-only

    policy.default: role:read-only
    scopes: '[groups, email]'
```

> 🔑 `policy.default: role:read-only` — every authenticated user can at least
> view something; that's not a violation. Write access is group-based.

---

## 🗂️ AppProject — Isolation

The default `default` AppProject is too broad. Give each team/scope its own project:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: payments-team
  namespace: argocd
spec:
  description: Payments team applications

  # Which Git repos source can be pulled from
  sourceRepos:
    - https://github.com/<ORG>/k8s-config
    - https://charts.example.com

  # Which cluster + namespaces it can deploy to
  destinations:
    - server: https://kubernetes.default.svc
      namespace: payments-*
    - name: prod-cluster
      namespace: payments-prod

  # Which resources are allowed (whitelist)
  clusterResourceWhitelist:
    - group: ""
      kind: Namespace
    - group: rbac.authorization.k8s.io
      kind: ClusterRole
    - group: rbac.authorization.k8s.io
      kind: ClusterRoleBinding

  namespaceResourceBlacklist:
    - group: ""
      kind: ResourceQuota
    - group: ""
      kind: LimitRange

  # RBAC: who can access this project
  roles:
    - name: developer
      policies:
        - p, proj:payments-team:developer, applications, sync, payments-team/*, allow
        - p, proj:payments-team:developer, applications, get, payments-team/*, allow
      groups:
        - <ORG>:payments-team
```

---

## 📦 First Application — Hello World

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hello-world
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/<ORG>/k8s-config
    targetRevision: main
    path: apps/hello-world/overlays/dev

  destination:
    server: https://kubernetes.default.svc
    namespace: hello-world

  syncPolicy:
    automated:
      prune: true       # resources deleted from Git get deleted from the cluster too
      selfHeal: true    # revert manual changes made in the cluster
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

> 🔑 **`automated.selfHeal: true`** is the spirit of GitOps. ArgoCD reverts
> manual `kubectl edit` changes → drift = 0.

---

## 🧬 ApplicationSet — Multi-Cluster / Multi-Tenant

ApplicationSet is a CRD that generates **N Applications**. It's the key to
multi-cluster deploys.

### Cluster generator (for registered clusters)
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: ingress-nginx-everywhere
  namespace: argocd
spec:
  generators:
    - clusters:
        selector:
          matchLabels:
            tier: production

  template:
    metadata:
      name: 'ingress-nginx-{{name}}'
    spec:
      project: platform
      source:
        repoURL: https://github.com/<ORG>/k8s-config
        targetRevision: main
        path: infrastructure/ingress-nginx
      destination:
        server: '{{server}}'
        namespace: ingress-nginx
      syncPolicy:
        automated: {prune: true, selfHeal: true}
        syncOptions: [CreateNamespace=true]
```

### Git generator (1 app per folder in Git)
```yaml
generators:
  - git:
      repoURL: https://github.com/<ORG>/k8s-config
      revision: main
      directories:
        - path: apps/*/overlays/prod
template:
  metadata:
    name: '{{path[1]}}'  # "apps/<APP>/overlays/prod" → APP
  spec:
    source:
      path: '{{path}}'
    destination:
      namespace: '{{path[1]}}'
```

### Matrix generator (cluster × directory)
```yaml
generators:
  - matrix:
      generators:
        - clusters:
            selector: {matchLabels: {env: prod}}
        - git:
            directories: [{path: apps/*/overlays/prod}]
```

---

## 🚦 Sync Strategies

### Auto-sync (recommended for prod)
```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```
- Git push → in the cluster within 3 min
- Manual drift gets corrected automatically

### Manual sync (gated environments)
```yaml
syncPolicy: {}   # no automated
```
- The operator manually runs `argocd app sync <app>`
- For production change-review workflows

### Sync waves (ordered deploy)
```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"   # CRD first, then namespace, then app
```

| Wave | Typical contents |
|---|---|
| `-1` | CRDs, RBAC |
| `0`  | Namespace, ConfigMap, Secret |
| `1`  | Service, Ingress, NetworkPolicy |
| `2`  | Deployment, StatefulSet |
| `3`  | Job, CronJob |

### Hooks (PreSync, Sync, PostSync, SyncFail)
```yaml
metadata:
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
```

Typical usage: DB migration job on PreSync, smoke test on PostSync.

---

## 🔔 Notifications

```yaml
configs:
  notifications:
    notifiers:
      service.slack: |
        token: $slack-token
    templates:
      template.app-deployed: |
        message: "🚀 {{.app.metadata.name}} deployed to {{.app.spec.destination.namespace}}"
      template.app-sync-failed: |
        message: "❌ {{.app.metadata.name}} sync failed: {{.app.status.operationState.message}}"
    triggers:
      trigger.on-deployed: |
        - when: app.status.sync.status == 'Synced' and app.status.health.status == 'Healthy'
          send: [app-deployed]
      trigger.on-sync-failed: |
        - when: app.status.sync.status == 'OutOfSync' and app.status.operationState.phase in ['Error', 'Failed']
          send: [app-sync-failed]
    subscriptions:
      - recipients: [slack:platform-changes]
        triggers: [on-deployed, on-sync-failed]
```

---

## 📊 Monitoring

### Prometheus metrics (built-in, scrape it)
```yaml
controller:
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true

server:
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
```

### Key alerts
```yaml
groups:
  - name: argocd
    rules:
      - alert: ArgoCDAppOutOfSync
        expr: argocd_app_info{sync_status!="Synced"} == 1
        for: 30m
        annotations:
          summary: "{{ $labels.name }} OutOfSync 30+ min"

      - alert: ArgoCDAppUnhealthy
        expr: argocd_app_info{health_status!="Healthy"} == 1
        for: 15m
        annotations:
          summary: "{{ $labels.name }} unhealthy"

      - alert: ArgoCDSyncFailed
        expr: increase(argocd_app_sync_total{phase="Failed"}[1h]) > 3
        annotations:
          summary: "{{ $labels.name }} 3+ sync failed/hour"

      - alert: ArgoCDControllerDown
        expr: up{job="argocd-application-controller"} == 0
        for: 5m
        annotations:
          summary: "ArgoCD controller down"
```

---

## 🔑 Secrets in GitOps

ArgoCD has no secret solution of its own. Three main approaches:

| Approach | Pro | Con |
|---|---|---|
| **External Secrets Operator** + Vault | Cluster and secret source are separate, audit | Extra work for initial setup |
| **Sealed Secrets** | Encrypted commit in Git | Single key, rotation is complex |
| **SOPS** + helm-secrets / Argo-vault-plugin | Multi-recipient, age key | Plugin install + key distribution |

> Details: [`Secrets-in-GitOps.md`](Secrets-in-GitOps.md) (later phase) and
> [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md).

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| Manual `kubectl apply` in Git + cluster | Drift, no source of truth | Git only |
| `default` AppProject for everything | No isolation | Per-team AppProject |
| Admin user active | Who did it? No audit | SSO + admin disable |
| ArgoCD isn't self-managed | Argo upgrades get forgotten | Self-managed via App-of-Apps |
| All clusters get the same apps through different methods | Drift, manual work | ApplicationSet cluster generator |
| Auto-sync `selfHeal: false` | Drift persists, intent ≠ reality | `selfHeal: true` (a deliberate exception in prod) |
| Application namespace = `default` | Namespace cleanup is impossible | Per-app dedicated namespace |
| No notifications | Sync failed → nobody notices | Slack + alert |
| Direct `automated` sync to production | Risk: a bad PR goes straight to prod | Promotion: dev/auto → staging/auto → prod/manual, or a sync window |
| Inline Helm chart values | Diffs are hard to read | Separate values.yaml, patch with kustomize |
| Secret stored as plaintext in Git | A breach is a matter of time | SOPS / Sealed / ESO |
| ArgoCD auth: one token across all CI | Compromise → cluster ownership | SSO + per-pipeline minimal RBAC |

---

## 📋 Production-Grade Checklist

```
[ ] HA: server x3, repoServer x3, redis-ha
[ ] Ingress + TLS (cert-manager)
[ ] SSO (OIDC), admin disabled
[ ] RBAC: group-based, default read-only
[ ] AppProject: per-team isolation
[ ] App-of-Apps: ArgoCD itself is also managed from Git
[ ] ApplicationSet: multi-cluster sync (ingress, cert-manager, ESO)
[ ] Auto-sync + selfHeal (a deliberate decision on whether prod is gated)
[ ] Sync waves: CRD → namespace → app, in order
[ ] Hooks: DB migration PreSync
[ ] Notifications: Slack + alert (sync failed, out-of-sync 30 min)
[ ] Prometheus metrics + ServiceMonitor
[ ] Alert: AppUnhealthy, AppOutOfSync, ControllerDown
[ ] Backup: ArgoCD CRDs already live in Git; Redis state is backed up
[ ] Secret: ESO or SOPS — no plaintext in Git
[ ] ArgoCD upgrade: track the minor version quarterly
[ ] DR: document how to re-bootstrap ArgoCD if the cluster goes down
```

---

## 📚 References

- **ArgoCD Docs** — argo-cd.readthedocs.io
- **ApplicationSet Generators** — argocd-applicationset.readthedocs.io
- **OpenGitOps Principles** — opengitops.dev
- **GitOps Working Group (CNCF)**
- [`App-of-Apps-Pattern.md`](App-of-Apps-Pattern.md)
- [`ApplicationSet-Patterns.md`](ApplicationSet-Patterns.md)
- [`Helm-vs-Kustomize-vs-Raw.md`](Helm-vs-Kustomize-vs-Raw.md)
- [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md)
- [`08-Security/Policy-as-Code-OPA-Kyverno.md`](../08-Security/Policy-as-Code-OPA-Kyverno.md) — alignment with admission control

---

> *"GitOps turns the cluster into a **function**: input is Git, output is
> cluster state. The moment you insert manual intervention in between, it's
> no longer a function — it's a **wish list**."*

---

> 🎓 **Learning Path:** This document is used as the "Read first" resource in the [`D5`](../22-Learning-Path/block-d-orchestration/D5-gitops-argocd.md) module.
