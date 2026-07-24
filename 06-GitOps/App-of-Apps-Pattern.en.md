---
description: "App-of-Apps pattern: a guide to bootstrapping ArgoCD with a single root Application and turning it into a self-managed GitOps workflow that manages itself."
tags:
  - GitOps
  - ArgoCD
  - Kubernetes
  - Platform Engineering
---
# App-of-Apps Pattern — Make ArgoCD Self-Managed

> *"A team that installs ArgoCD manually with `helm install` eventually
> gets stuck on the question 'who upgrades ArgoCD?'
> **App-of-Apps** means ArgoCD itself is also managed from Git."*

This guide covers the **App-of-Apps** pattern, **bootstrap**, and the
concrete workflow for making ArgoCD self-managed.

---

## 🎯 What Is the Pattern?

```
[Root Application]              ← bootstrap, the single manually created resource
   │
   │ (ArgoCD sync)
   ▼
[child-app-1, child-app-2, ...] ← each one is a separate Application
   │
   ▼
[K8s resources deploy]
```

> **App-of-Apps**: A single "root" Application deploys the other
> Application manifests in the Git repo. Those Applications in turn
> deploy their own resources. Result: **1 manual resource**, everything
> else is GitOps.

---

## 🆚 ApplicationSet vs App-of-Apps

| Dimension | App-of-Apps | ApplicationSet |
|---|---|---|
| **Mechanism** | Application manifest inside an Application | CRD, generator-driven |
| **Lookup** | Static (written in Git) | Dynamic (cluster, git, scm) |
| **Best for** | Bootstrap, infrastructure | Multi-cluster, multi-tenant patterns |
| **Complexity** | Low | Medium |
| **2026 recommendation** | For bootstrap | For apps |

> 🔑 **Combination**: Bootstrap with App-of-Apps → ApplicationSets inside it. Gives the team both stability and flexibility.

---

## 🏗️ Repo Structure

```
k8s-config/
├── argocd/
│   ├── projects/
│   │   ├── platform.yaml
│   │   ├── payments-team.yaml
│   │   └── catalog-team.yaml
│   ├── applications/
│   │   ├── infrastructure.yaml      # ApplicationSet: cert-mgr, ingress, ESO
│   │   ├── monitoring.yaml          # ApplicationSet: prom, grafana, loki
│   │   ├── apps-prod.yaml           # ApplicationSet: tenant apps
│   │   └── platform-tools.yaml      # single Application: backstage
│   └── root-app.yaml                # this resource is applied manually
├── infrastructure/                   # Helm charts / kustomize
│   ├── cert-manager/
│   ├── ingress-nginx/
│   ├── external-secrets/
│   └── ...
├── monitoring/
│   ├── prometheus-stack/
│   ├── grafana/
│   └── loki/
└── apps/                              # tenant applications
    └── ...
```

---

## 🚀 Bootstrap Flow

### Step 1: Manual ArgoCD install
```bash
helm install argocd argo/argo-cd \
  -n argocd --create-namespace \
  --version <CHART_VERSION> \
  -f argocd-values.yaml
```

### Step 2: Apply the root Application
```yaml
# argocd/root-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/<ORG>/k8s-config
    targetRevision: main
    path: argocd/applications        # ApplicationSet/App manifests live here
    directory:
      recurse: true
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=false
```

```bash
kubectl apply -f argocd/root-app.yaml
```

### Step 3: After that, everything is GitOps
- New infra added → open an ApplicationSet PR under `argocd/applications/`
- ArgoCD syncs root-app → the new ApplicationSet appears → resources deploy

> 🔑 **Single manual resource**: root-app.yaml. Everything else is **code**.

---

## 🔄 Self-Managed ArgoCD

ArgoCD can also manage itself:

```yaml
# argocd/applications/argocd-self.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd
  namespace: argocd
spec:
  project: platform
  source:
    repoURL: https://argoproj.github.io/argo-helm
    chart: argo-cd
    targetRevision: <CHART_VERSION>
    helm:
      valueFiles:
        - $values/argocd/values.yaml
  sources:
    - repoURL: https://argoproj.github.io/argo-helm
      chart: argo-cd
      targetRevision: <CHART_VERSION>
      helm:
        valueFiles:
          - $values/argocd/values.yaml
    - repoURL: https://github.com/<ORG>/k8s-config
      targetRevision: main
      ref: values
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: false      # ⚠️ don't let ArgoCD delete itself
      selfHeal: true
    syncOptions:
      - ServerSideApply=true
```

> 🔑 **`prune: false`**: so ArgoCD doesn't accidentally delete its own resources.
> `prune: true` is fine for everything else.

### ArgoCD upgrade flow
1. PR: `targetRevision: <NEW_VERSION>`
2. CI lint + test
3. Merge → ArgoCD self-app sync
4. ArgoCD pods rolling restart
5. Now on the new version

> ⚠️ **For major upgrades**, test on a staging cluster first — there can be breaking changes.

---

## 🧬 ApplicationSets Inside

```yaml
# argocd/applications/infrastructure.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: infrastructure-addons
  namespace: argocd
spec:
  generators:
    - matrix:
        generators:
          - clusters: {}
          - list:
              elements:
                - {addon: cert-manager, ns: cert-manager, wave: "0"}
                - {addon: external-secrets, ns: external-secrets, wave: "0"}
                - {addon: ingress-nginx, ns: ingress-nginx, wave: "1"}
                - {addon: prometheus-stack, ns: monitoring, wave: "2"}

  template:
    metadata:
      name: '{{addon}}-{{name}}'
      annotations:
        argocd.argoproj.io/sync-wave: '{{wave}}'
    spec:
      project: platform
      source:
        repoURL: https://github.com/<ORG>/k8s-config
        path: 'infrastructure/{{addon}}'
      destination:
        server: '{{server}}'
        namespace: '{{ns}}'
      syncPolicy:
        automated: {prune: true, selfHeal: true}
        syncOptions: [CreateNamespace=true]
```

> 🔑 Ordered via `sync-wave`: cert-manager (wave 0) before ingress-nginx.

---

## 🏛️ Isolation with AppProject

```yaml
# argocd/projects/platform.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: platform
  namespace: argocd
spec:
  description: Platform team applications

  sourceRepos:
    - https://github.com/<ORG>/k8s-config
    - https://argoproj.github.io/argo-helm
    - https://charts.bitnami.com/bitnami

  destinations:
    - server: '*'
      namespace: '*'

  clusterResourceWhitelist:
    - {group: "", kind: Namespace}
    - {group: rbac.authorization.k8s.io, kind: "*"}
    - {group: apiextensions.k8s.io, kind: CustomResourceDefinition}

  roles:
    - name: ci
      policies:
        - p, proj:platform:ci, applications, sync, platform/*, allow
      jwtTokens: []
```

```yaml
# argocd/projects/payments-team.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: payments-team
  namespace: argocd
spec:
  description: Payments team apps
  sourceRepos:
    - https://github.com/<ORG>/k8s-config
  destinations:
    - server: https://kubernetes.default.svc
      namespace: payments-*
  clusterResourceWhitelist:
    - {group: "", kind: Namespace}
  roles:
    - name: developer
      policies:
        - p, proj:payments-team:developer, applications, sync, payments-team/*, allow
      groups:
        - <ORG>:payments-team
```

---

## 🚧 Typical Flow: Adding a New Service

```
1. Dev: code + Dockerfile + k8s manifest in the app repo
2. CI: image build + push to registry
3. CI: bump image tag in k8s-config repo (PR)
4. PR review (CODEOWNERS)
5. Merge → ArgoCD root-app reconcile
6. apps-prod ApplicationSet → detects the new service
7. ArgoCD creates the child Application
8. Sync → deploy to cluster
9. Notification: Slack #deployments
```

> 🔑 The only thing the engineer touches: **the PR**. Everything else is automatic.

---

## 🛡️ Recovery: Losing the ArgoCD Cluster

When rebuilding the cluster from scratch:
```bash
# 1. New cluster is up
# 2. ArgoCD manual install (Helm)
helm install argocd argo/argo-cd ...

# 3. Apply the root Application
kubectl apply -f argocd/root-app.yaml

# 4. ArgoCD syncs root, reconcile of the contents begins
# 5. ApplicationSets appear
# 6. The entire cluster (infrastructure + apps) reaches Git state
```

**Total DR time**: ArgoCD install (5 min) + Root apply (1 min) + reconcile (~30 min).

> 🔑 **The cluster is mortal, Git is eternal.** The strongest part of App-of-Apps: you can **rebirth the cluster from Git**.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| Manual ArgoCD install + manual apps | Drift, unclear "who did what" | App-of-Apps + GitOps |
| Root-app `prune: true` | ArgoCD can delete its own resources | `prune: false` for self |
| One root-app with 50 children | Too much YAML, hard to debug | Split into nested ApplicationSets |
| Manual `kubectl apply` on the cluster | Drift, defeats the purpose of GitOps | All changes go through a PR |
| No AppProject in use | No isolation, everyone can reach everywhere | Per-team project |
| `default` project does too much | Privilege creep | Minimal default + specific projects |
| No sync wave in use | Application sync fails when the CRD doesn't exist yet | Wave order -1, 0, 1, 2 |
| No test for self-managed ArgoCD upgrades | Major bugs reach prod | Test on a lab cluster first |
| Root-app branch isn't `main` | Fork drift | `main` or a release tag |
| Missing ApplicationSet generator filter | Things you don't want get deployed | `selector: {matchLabels:}` |

---

## 📋 App-of-Apps Adoption Checklist

```
[ ] Manual resource is only root-app.yaml + helm install
[ ] argocd/applications/ folder contents reconcile
[ ] Self-managed ArgoCD (has its own Application)
[ ] AppProject per-team isolation
[ ] ApplicationSet in use (multi-cluster, multi-tenant)
[ ] Sync wave: CRD → namespace → app
[ ] Notification: ArgoCD → Slack/PagerDuty
[ ] Prune: true for apps, false for self
[ ] DR test: wipe the cluster → bring it back with App-of-Apps
[ ] Documentation: how a new team onboards
[ ] Bootstrap script: single command for a new cluster
[ ] Quarterly: ArgoCD upgrade (major version)
[ ] CODEOWNERS in the k8s-config repo
[ ] Branch protection on main + required reviews
```

---

## 📚 References

- **ArgoCD Cluster Bootstrapping** — argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/
- **Argo Best Practices** — github.com/argoproj/argo-cd/blob/master/docs/operator-manual/best-practices.md
- **OpenGitOps** — opengitops.dev
- [`ArgoCD-Setup.md`](ArgoCD-Setup.md)
- [`ApplicationSet-Patterns.md`](ApplicationSet-Patterns.md)
- [`Helm-vs-Kustomize-vs-Raw.md`](Helm-vs-Kustomize-vs-Raw.md)
- [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md) — secret management

---

> *"App-of-Apps isn't a 'fancy pattern' — it **is** GitOps
> discipline itself. It brings your manual resource count down to
> **1**; everything else stays under Git's control."*
