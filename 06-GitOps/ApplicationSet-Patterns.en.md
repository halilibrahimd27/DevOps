---
description: "Multi-cluster and multi-tenant GitOps with ArgoCD ApplicationSet: building an Application factory with cluster, git, matrix, list, and SCM generator types."
tags:
  - GitOps
  - ArgoCD
  - Kubernetes
  - Platform Engineering
---
# ApplicationSet — Multi-Cluster and Multi-Tenant GitOps

> *"5 clusters, 3 environments, 50 services = 750 ArgoCD Application
> manifests. Manual = impossible. **ApplicationSet** shrinks this down
> to **3 files**."*

This guide covers ArgoCD ApplicationSet — the Application factory —
through its patterns: cluster generator, git generator, matrix, list,
scm provider. The key to multi-cluster GitOps.

---

## 🎯 What Is ApplicationSet?

> **ApplicationSet**: A single CRD that generates **N Applications**.
> The "generator" defines the set of variables, the "template" shapes each Application.

```
ApplicationSet (1 file)
   ├── Generator: 5 clusters
   ├── Template: 1 Application per cluster
   ↓
   5 separate ArgoCD Applications generated automatically
   ↓
   ingress-nginx deployed across 5 clusters
```

---

## 🧬 6 Generator Types

### 1. **List** — Static list
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: app-by-env
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - env: dev
            url: https://kubernetes.default.svc
          - env: staging
            url: https://staging-cluster:6443
          - env: prod
            url: https://prod-cluster:6443
  template:
    metadata:
      name: 'payments-{{env}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/<ORG>/k8s-config
        targetRevision: main
        path: 'apps/payments/overlays/{{env}}'
      destination:
        server: '{{url}}'
        namespace: 'payments-{{env}}'
      syncPolicy:
        automated: {prune: true, selfHeal: true}
```

### 2. **Cluster** — Clusters registered in ArgoCD
```yaml
generators:
  - clusters:
      selector:
        matchLabels:
          tier: production
template:
  metadata:
    name: 'ingress-nginx-{{name}}'
  spec:
    source:
      path: infrastructure/ingress-nginx
    destination:
      server: '{{server}}'
      namespace: ingress-nginx
```

> 🔑 ingress-nginx is installed automatically on every cluster with the `tier: production` label. New clusters are picked up automatically when added.

### 3. **Git Directory** — 1 Application per folder in the Git repo
```yaml
generators:
  - git:
      repoURL: https://github.com/<ORG>/k8s-config
      revision: main
      directories:
        - path: apps/*/overlays/prod
template:
  metadata:
    name: '{{path[1]}}'   # apps/<APP>/overlays/prod → APP
  spec:
    source:
      repoURL: https://github.com/<ORG>/k8s-config
      targetRevision: main
      path: '{{path}}'
    destination:
      server: https://kubernetes.default.svc
      namespace: '{{path[1]}}'
```

> 🔑 A new service folder is created, an Application is generated automatically. **Manifest-driven** GitOps.

### 4. **Git File** — JSON/YAML config file
```yaml
generators:
  - git:
      repoURL: https://github.com/<ORG>/k8s-config
      revision: main
      files:
        - path: 'apps-config/*.json'
template:
  metadata:
    name: '{{name}}'
  spec:
    source:
      repoURL: '{{repo}}'
      path: '{{path}}'
    destination:
      server: '{{cluster}}'
      namespace: '{{namespace}}'
```

```json
// apps-config/payments.json
{
  "name": "payments",
  "repo": "https://github.com/<ORG>/payments",
  "path": "k8s/prod",
  "cluster": "https://prod-cluster:6443",
  "namespace": "payments-prod"
}
```

### 5. **Matrix** — Generator cross-product
```yaml
generators:
  - matrix:
      generators:
        - clusters:
            selector: {matchLabels: {env: prod}}
        - git:
            directories: [{path: apps/*/overlays/prod}]
template:
  metadata:
    name: '{{path[1]}}-{{name}}'
  spec:
    source:
      path: '{{path}}'
    destination:
      server: '{{server}}'
      namespace: '{{path[1]}}'
```

> 🔑 N clusters × M apps = N×M Applications. The key to multi-cluster + multi-tenant.

### 6. **SCM Provider** — Scanning a GitHub/GitLab org
```yaml
generators:
  - scmProvider:
      github:
        organization: <ORG>
        tokenRef:
          secretName: github-token
          key: token
      filters:
        - repositoryMatch: ^app-.*    # only "app-*" repos
        - pathsExist: [k8s/]            # repos that have a k8s/ folder
template:
  metadata:
    name: '{{repository}}'
  spec:
    source:
      repoURL: '{{url}}'
      targetRevision: '{{branch}}'
      path: k8s/
    destination:
      server: https://kubernetes.default.svc
      namespace: '{{repository}}'
```

> 🔑 A new repo is added to the org (from a template) → automatic ArgoCD Application. Combine it with Backstage/IDP.

---

## 🛠️ Practical Patterns

### Pattern 1: Platform addons on every cluster
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: platform-addons
spec:
  generators:
    - matrix:
        generators:
          - clusters: {}
          - list:
              elements:
                - addon: ingress-nginx
                - addon: cert-manager
                - addon: external-dns
                - addon: external-secrets
                - addon: prometheus-stack
                - addon: cilium
  template:
    metadata:
      name: '{{addon}}-{{name}}'
    spec:
      project: platform
      source:
        repoURL: https://github.com/<ORG>/k8s-config
        path: 'infrastructure/{{addon}}'
      destination:
        server: '{{server}}'
        namespace: '{{addon}}'
      syncPolicy:
        automated: {prune: true, selfHeal: true}
        syncOptions: [CreateNamespace=true]
```

### Pattern 2: Namespace per tenant
```yaml
generators:
  - list:
      elements:
        - tenant: alpha
          plan: premium
        - tenant: beta
          plan: basic
template:
  metadata:
    name: 'tenant-{{tenant}}'
  spec:
    source:
      path: 'tenants/base'
      helm:
        values: |
          tenant: {{tenant}}
          plan: {{plan}}
    destination:
      namespace: 'tenant-{{tenant}}'
```

### Pattern 3: Preview environment per branch
```yaml
generators:
  - pullRequest:
      github:
        owner: <ORG>
        repo: <REPO>
        tokenRef:
          secretName: github-token
          key: token
      requeueAfterSeconds: 60
template:
  metadata:
    name: 'preview-{{branch}}-{{number}}'
  spec:
    source:
      repoURL: 'https://github.com/<ORG>/<REPO>'
      targetRevision: '{{head_sha}}'
      path: k8s/preview
      helm:
        parameters:
          - name: image.tag
            value: 'pr-{{number}}'
    destination:
      namespace: 'preview-pr-{{number}}'
    syncPolicy:
      automated: {prune: true, selfHeal: true}
      syncOptions: [CreateNamespace=true]
```

> 🔑 PR opened → preview env auto-deploys. PR closed → namespace gets deleted. **Vercel-style** dev experience on K8s.

---

## 🛡️ Sync Policies — Staged Rollout

### `goTemplate` — better templating
```yaml
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  template:
    metadata:
      name: '{{ .name }}-{{ .env }}'
    spec:
      source:
        repoURL: '{{ .repo }}'
        helm:
          values: |
            replicaCount: {{ if eq .env "prod" }}5{{ else }}1{{ end }}
```

### `templatePatch` — runtime patch
```yaml
spec:
  templatePatch: |
    metadata:
      labels:
        env: '{{ .env }}'
        owner: '{{ .owner }}'
```

### `strategy.rollingSync` — staged ApplicationSet sync
```yaml
spec:
  strategy:
    type: RollingSync
    rollingSync:
      steps:
        - matchExpressions:
            - key: env
              operator: In
              values: [dev]
        - matchExpressions:
            - key: env
              operator: In
              values: [staging]
        - matchExpressions:
            - key: env
              operator: In
              values: [prod]
```

> 🔑 Sync dev first, then staging, then prod. **Automatic promotion**.

---

## 🚧 Best Practices

### 1. Repo structure
```
k8s-config/
├── argocd/
│   ├── projects/
│   │   ├── payments-team.yaml
│   │   └── platform.yaml
│   └── applicationsets/
│       ├── platform-addons.yaml
│       └── apps-prod.yaml
├── infrastructure/        # cluster addons
│   ├── ingress-nginx/
│   ├── cert-manager/
│   └── ...
├── apps/                  # tenant apps
│   ├── payments/
│   │   ├── base/
│   │   └── overlays/
│   │       ├── dev/
│   │       ├── staging/
│   │       └── prod/
│   └── ...
└── tenants/               # multi-tenant
    └── ...
```

### 2. App-of-Apps + ApplicationSet
Make ArgoCD self-managed: ArgoCD's own Application + its ApplicationSets both live in Git.

```yaml
# argocd/bootstrap.yaml — root Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-bootstrap
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/<ORG>/k8s-config
    path: argocd/applicationsets
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated: {prune: true, selfHeal: true}
```

### 3. Cluster registration
```bash
# Add a cluster with the ArgoCD CLI
argocd cluster add <CONTEXT> --label tier=production --label region=eu-west-1
```

### 4. Project-based isolation
ApplicationSet combines with AppProject:
```yaml
template:
  spec:
    project: payments-team   # within this project's permitted destinations
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| 100 manual Applications | Maintenance becomes impossible | ApplicationSet |
| ApplicationSets living in the `default` project | Zero isolation | Per-team AppProject |
| No selector on the cluster generator | Breaks when a new cluster is added | `selector: {matchLabels:}` |
| Git directory + manual exceptions | Drift | Proper scope via filters |
| `automated.selfHeal: false` on an ApplicationSet | Drift accumulates | true (or a deliberate exception) |
| Preview envs never get cleaned up | Wasted resources | `prune: true` + PR closed event |
| Matrix generator too large (1000 apps) | API server chokes | Pagination or filters |
| ApplicationSet rollout isn't staged | All clusters at once → bugs spread everywhere | RollingSync strategy |
| Helm values inline | Hard to diff | Separate values.yaml |
| Hardcoded generator parameters | Adding a new env means changing it everywhere | List generator + keep it in one place |

---

## 📋 ApplicationSet Adoption Checklist

```
[ ] ApplicationSet controller HA (3 replicas)
[ ] Repo structure is clear (apps/, infrastructure/, argocd/)
[ ] Isolation via AppProject
[ ] Platform addons → cluster generator
[ ] Apps → git directory generator
[ ] Multi-cluster → matrix generator
[ ] Preview envs → pullRequest generator (optional)
[ ] App-of-Apps + ApplicationSet combination
[ ] RollingSync strategy (dev → staging → prod)
[ ] Cluster label policy (tier, region, env)
[ ] Generator changes go through PR review
[ ] Self-managed: ApplicationSets also live in Git
[ ] Drift: selfHeal enabled
[ ] Documentation: how a new team gets onboarded
```

---

## 📚 References

- **ApplicationSet Docs** — argocd-applicationset.readthedocs.io
- **Argo CD Generators** — argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/
- **GitOps Patterns** — opengitops.dev
- [`ArgoCD-Setup.md`](ArgoCD-Setup.md)
- [`App-of-Apps-Pattern.md`](App-of-Apps-Pattern.md)
- [`Helm-vs-Kustomize-vs-Raw.md`](Helm-vs-Kustomize-vs-Raw.md)
- [`08-Security/Policy-as-Code-OPA-Kyverno.md`](../08-Security/Policy-as-Code-OPA-Kyverno.md) — multi-cluster policy

---

> *"ApplicationSet isn't a **YAML duplicator** — it's a **manifest
> factory**. It answers the question 'I added a new cluster, who's
> going to install which addon?': **nobody — it installs itself,
> automatically**."*
