---
description: "Kubernetes manifest strategy: a decision tree and comparison of Helm, Kustomize, and Raw YAML along the axes of templating, multi-env, and reusability."
tags:
  - GitOps
  - Kubernetes
  - Helm
  - IaC
  - Template
---
# Helm vs Kustomize vs Raw YAML — Manifest Strategy Decision Guide

> *"Three tools, three different philosophies. The wrong choice leaves
> you wanting to 'rewrite everything from scratch' 6 months later.
> **The right choice** buys you 6 comfortable years."*

This guide compares the 3 major approaches to managing Kubernetes
manifests — Helm, Kustomize, Raw YAML. A clear decision tree plus
practical examples.

---

## 🎯 Philosophy of the Three Approaches

| Approach | Philosophy | In one sentence |
|---|---|---|
| **Raw YAML** | "Manifesto = manifest" | Copy-paste YAML files + sed/envsubst |
| **Kustomize** | "Patch + overlay" | Change the base manifest layer by layer per environment |
| **Helm** | "Template + package" | Go templating + values.yaml + chart packaging |

---

## 📊 Detailed Comparison

| Dimension | **Raw YAML** | **Kustomize** | **Helm** |
|---|---|---|---|
| **Templating** | None | None (patch-based) | Go templates `{{ }}` |
| **Variable substitution** | envsubst / sed | Replacements + vars | `.Values` |
| **Multi-env** | Manual copy | base + overlays | `values-<env>.yaml` |
| **Reusability** | Low (copy-paste) | Medium (component) | High (chart + dep) |
| **Versioning** | Git tag | Git tag | Chart version + repo |
| **Distribution** | Git | Git | OCI registry, Helm repo |
| **Diff readability** | ✅ Good (raw YAML) | ✅ Good | ⚠️ Requires render |
| **Learning curve** | 🟢 Zero | 🟧 Medium | 🟥 High |
| **Built-in K8s** | ✅ `kubectl apply` | ✅ `kubectl apply -k` | ❌ requires helm CLI |
| **Helper functions** | None | Limited | Rich (`include`, `template`) |
| **Conditional logic** | None | Limited via patches | If/else native |
| **Hooks** | None | None | `pre-install`, `post-upgrade` |
| **Rollback** | Manual | Manual | `helm rollback` |
| **Dependency** | Manual | Component | Chart dependency |
| **Schema validation** | None | None | JSON schema (`values.schema.json`) |
| **Template debug** | n/a | `kubectl kustomize` | `helm template` |
| **Best for** | Single-env, small | Multi-env, GitOps | Reusable, vendor distribution |

---

## 🌳 Decision Tree

```
START
  │
  ├── Deploying a vendor / open-source application?
  │     │
  │     └── YES → HELM
  │            (cert-manager, ingress-nginx, prometheus, etc.
  │             already ship as Helm charts)
  │
  ├── Single environment, no variation at all?
  │     │
  │     └── YES → RAW YAML
  │            (nothing to learn, stays simple)
  │
  ├── Multi-env (dev/staging/prod) but a similar manifest?
  │     │
  │     └── YES → KUSTOMIZE
  │            (base + overlays = the cleanest pattern)
  │
  ├── Standardizing + reusing internal microservices?
  │     │
  │     └── YES → HELM CHART (internal)
  │            (or a Kustomize component)
  │
  └── Complex conditional + helper logic?
         │
         └── YES → HELM (template power)
```

> 🔑 **Practical combination:** **Helm** for vendor apps, **Kustomize**
> for internal apps. You can use both together.

---

## 🛠️ Raw YAML

### Structure
```
k8s/
├── deployment.yaml
├── service.yaml
├── ingress.yaml
└── configmap.yaml
```

### Multi-env (with envsubst)
```yaml
# deployment.template.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: ${NAMESPACE}
spec:
  replicas: ${REPLICAS}
  template:
    spec:
      containers:
        - name: app
          image: ${REGISTRY}/${APP}:${VERSION}
```

```bash
NAMESPACE=prod REPLICAS=5 VERSION=1.4.0 \
  envsubst < deployment.template.yaml | kubectl apply -f -
```

### ✅ Pro
- Zero learning curve
- Clean diffs
- `kubectl apply -f .` is enough

### ❌ Con
- Multi-env → copy-paste hell
- No reuse
- 10+ services quickly becomes unmaintainable

> 🔑 **When?** Single dev cluster, hobby project, learning. Doesn't scale in production.

---

## 🛠️ Kustomize

K8s 1.14+ native, works with `kubectl apply -k`.

### Structure
```
k8s/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
└── overlays/
    ├── dev/
    │   ├── kustomization.yaml
    │   └── replicas-patch.yaml
    ├── staging/
    │   ├── kustomization.yaml
    │   └── replicas-patch.yaml
    └── prod/
        ├── kustomization.yaml
        ├── replicas-patch.yaml
        └── resources-patch.yaml
```

### `base/kustomization.yaml`
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml

commonLabels:
  app: payments

namespace: payments
```

### `overlays/prod/kustomization.yaml`
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: payments-prod

bases:
  - ../../base

patches:
  - path: replicas-patch.yaml
  - path: resources-patch.yaml

images:
  - name: <REGISTRY>/payments
    newTag: 1.4.0

configMapGenerator:
  - name: payments-config
    behavior: merge
    literals:
      - LOG_LEVEL=info
      - ENVIRONMENT=prod

replicas:
  - name: payments
    count: 5
```

### `overlays/prod/replicas-patch.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payments
spec:
  replicas: 5
  template:
    spec:
      containers:
        - name: payments
          resources:
            requests:
              cpu: 500m
              memory: 1Gi
            limits:
              cpu: 2000m
              memory: 2Gi
```

### Apply
```bash
# Render and check
kubectl kustomize overlays/prod

# Direct apply
kubectl apply -k overlays/prod
```

### ✅ Pro
- K8s native (no extra tool)
- Stays YAML (no template language)
- Diffs are highly readable
- GitOps friendly (ArgoCD, Flux native support)
- Component (reusable patch group)

### ❌ Con
- Limited conditional logic
- No helper functions
- In complex changes, patches pile on top of patches

> 🔑 **When?** Internal microservices, multi-env, GitOps. **The most common internal pattern in 2026.**

---

## 🛠️ Helm

### Structure
```
charts/payments/
├── Chart.yaml
├── values.yaml
├── values.schema.json
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── _helpers.tpl
│   └── NOTES.txt
└── charts/      # subchart dependencies
```

### `Chart.yaml`
```yaml
apiVersion: v2
name: payments
version: 1.4.0
appVersion: "1.4.0"
description: Payments service
type: application
dependencies:
  - name: postgresql
    version: <DEP_VERSION>
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
```

### `values.yaml`
```yaml
replicaCount: 1
image:
  repository: <REGISTRY>/payments
  tag: ""    # use Chart.appVersion
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8080

ingress:
  enabled: false
  hostname: ""
  tls: false

resources:
  requests: {cpu: 100m, memory: 128Mi}
  limits: {cpu: 500m, memory: 512Mi}

postgresql:
  enabled: false
```

### `templates/deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "payments.fullname" . }}
  labels:
    {{- include "payments.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "payments.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "payments.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.service.port }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          {{- if .Values.postgresql.enabled }}
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: {{ include "payments.fullname" . }}-postgresql
                  key: connection-string
          {{- end }}
```

### `templates/_helpers.tpl`
```yaml
{{/* App name */}}
{{- define "payments.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Common labels */}}
{{- define "payments.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
```

### `values-prod.yaml`
```yaml
replicaCount: 5
image:
  tag: 1.4.0

ingress:
  enabled: true
  hostname: payments.<DOMAIN>
  tls: true

resources:
  requests: {cpu: 500m, memory: 1Gi}
  limits: {cpu: 2000m, memory: 2Gi}

postgresql:
  enabled: true
  primary:
    persistence:
      size: 100Gi
```

### Install / upgrade
```bash
helm install payments ./charts/payments -f values-prod.yaml -n payments-prod

helm upgrade payments ./charts/payments -f values-prod.yaml -n payments-prod

helm rollback payments 1 -n payments-prod   # previous revision

# Render preview
helm template payments ./charts/payments -f values-prod.yaml
```

### ✅ Pro
- Templating power (if/else, range, helpers)
- Chart packaging (versioned in an OCI registry)
- The de-facto standard for vendor apps
- Hooks (pre-install DB migration)
- Dependency management (subchart)
- Schema validation (`values.schema.json`)

### ❌ Con
- Go template syntax (steep learning curve)
- Diffs require rendering
- Hard to debug templates
- Helm 2 → 3 migration trauma (behind us now, Helm 3 is stable)
- "The templating language strains YAML"

> 🔑 **When?** Vendor distribution (ingress-nginx, cert-manager, etc.), reusable internal chart, complex conditionals.

---

## 🔀 Practical Hybrid: Helm + Kustomize

Install the Helm chart, then patch it with Kustomize. ArgoCD supports this natively:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  source:
    repoURL: https://github.com/<ORG>/k8s-config
    path: apps/payments
    plugin:
      name: kustomized-helm
```

```yaml
# apps/payments/kustomization.yaml
helmCharts:
  - name: payments
    repo: https://charts.example.com
    version: 1.4.0
    releaseName: payments
    namespace: payments-prod
    valuesFile: values-prod.yaml

patches:
  - path: extra-env-patch.yaml
    target: {kind: Deployment, name: payments}
```

> 🔑 This pattern: vendor chart + your own customization. Combines
> Helm's power with Kustomize's patching.

---

## 🚦 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| Multi-env raw YAML copies | 10 files × 3 envs = 30 manifests | Kustomize base + overlay |
| A Helm chart for "every little thing" | Templating overhead, loses simplicity | Single-env simple service → raw YAML |
| 30 layers of Kustomize patches | Unreadable, undebuggable | Consolidate patches, redesign the base |
| 500-line Helm `values.yaml` | Impossible to override | values-base + values-env split |
| Too many Helm conditionals | Source of template parse errors | Split the chart (with post-rendering) |
| JSON6902 patches in Kustomize | Unreadable | Prefer StrategicMerge |
| Kustomize generator with no versioning | Drift, surprises | configMapGenerator + hash suffix |
| Helm hooks aren't ordered | Lifecycle bugs | Define `helm.sh/hook-weight` |
| Helm chart lives in Git + in a chart repo | No sync | Single source of truth (usually an OCI registry) |
| Inline values in ArgoCD | Hard to diff | Separate values.yaml file |
| Bare K8s manifest + envsubst | Error-prone | Prefer Kustomize |

---

## 📋 Decision Checklist

```
[ ] Which approach did you choose: Raw / Kustomize / Helm / Hybrid?
[ ] Decision rationale documented (ADR / RFC)
[ ] Multi-env strategy: base + overlays / values-<env>.yaml
[ ] Image tag pinning: digest > tag > latest
[ ] Render preview in CI (kubectl kustomize / helm template)
[ ] Compatible with the GitOps tool (does ArgoCD/Flux support it)
[ ] Diff review visible in PR review
[ ] Schema validation (Helm values.schema.json or a validation script)
[ ] Rollback strategy (Helm rollback, kubectl rollout undo, Argo)
[ ] Dependency management: chart deps or kustomize bases
[ ] Secret integration: SOPS / sealed / ESO
[ ] Version bump flow (CI → version bump → tag → deploy)
```

---

## 📚 References

- **Kustomize Docs** — kustomize.io
- **Helm Docs** — helm.sh/docs
- **Helm Best Practices** — helm.sh/docs/chart_best_practices/
- **CNCF App Delivery TAG**
- [`ArgoCD-Setup.md`](ArgoCD-Setup.md)
- [`App-of-Apps-Pattern.md`](App-of-Apps-Pattern.md)
- [`ApplicationSet-Patterns.md`](ApplicationSet-Patterns.md)
- [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md) — secret integration

---

> *"Manifest strategy isn't a 'tool choice' — it's an **engineering
> style decision**. The wrong choice gets noticed 6 months later, the
> right one stays silent for 6 years."*

---

> 🎓 **Learning Path:** This document is used as the "Read first" resource in the [`D5`](../22-Learning-Path/block-d-orchestration/D5-gitops-argocd.md) module.
