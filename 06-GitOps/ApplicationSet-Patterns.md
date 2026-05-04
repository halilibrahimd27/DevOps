# ApplicationSet — Multi-Cluster ve Multi-Tenant GitOps

> *"5 cluster, 3 environment, 50 servis = 750 ArgoCD Application
> manifest'i. Manuel = imkansız. **ApplicationSet** bunu **3 dosya**ya
> indirir."*

Bu rehber ArgoCD ApplicationSet'i — Application factory — pattern'leriyle
açıklar: cluster generator, git generator, matrix, list, scm provider.
Multi-cluster GitOps'un anahtarı.

---

## 🎯 ApplicationSet Nedir?

> **ApplicationSet**: Bir CRD ile **N tane Application** üretir.
> "Generator" ile değişken seti tanımlar, "template" ile her Application'ı şekillendirir.

```
ApplicationSet (1 dosya)
   ├── Generator: 5 cluster
   ├── Template: cluster başına 1 Application
   ↓
   5 ayrı ArgoCD Application otomatik üretilir
   ↓
   5 cluster'da ingress-nginx deploy edilir
```

---

## 🧬 6 Generator Türü

### 1. **List** — Statik liste
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

### 2. **Cluster** — ArgoCD'de kayıtlı cluster'lar
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

> 🔑 `tier: production` label'lı her cluster'a ingress-nginx otomatik kurulur. Yeni cluster eklendiğinde otomatik dahil olur.

### 3. **Git Directory** — Git repo'da klasör başına 1 Application
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

> 🔑 Yeni servis klasörü açıldı, otomatik Application yaratıldı. **Manifest-driven** GitOps.

### 4. **Git File** — JSON/YAML config dosyası
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

### 5. **Matrix** — Generator çarpımı
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

> 🔑 N cluster × M app = N×M Application. Multi-cluster + multi-tenant'ın anahtarı.

### 6. **SCM Provider** — GitHub/GitLab org tarama
```yaml
generators:
  - scmProvider:
      github:
        organization: <ORG>
        tokenRef:
          secretName: github-token
          key: token
      filters:
        - repositoryMatch: ^app-.*    # sadece "app-*" repo'lar
        - pathsExist: [k8s/]            # k8s/ klasörü olan repo'lar
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

> 🔑 Org'a yeni repo eklendi (template'den) → otomatik ArgoCD Application. Backstage/IDP ile birleştirilir.

---

## 🛠️ Pratik Pattern'ler

### Pattern 1: Platform addons her cluster'a
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

### Pattern 2: Tenant başına namespace
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

### Pattern 3: Branch başına preview environment
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

> 🔑 PR açıldı → preview env auto-deploy. PR kapandı → namespace silinir. **Vercel-tarzı** dev experience K8s'de.

---

## 🛡️ Sync Policies — Aşamalı Rollout

### `goTemplate` — daha iyi templating
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

### `strategy.rollingSync` — ApplicationSet aşamalı sync
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

> 🔑 Önce dev'de sync, sonra staging, sonra prod. **Otomatik promotion**.

---

## 🚧 Best Practices

### 1. Repo yapısı
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
ArgoCD self-managed olsun: ArgoCD'nin kendi Application'ı + ApplicationSet'leri Git'te.

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

### 3. Cluster register
```bash
# ArgoCD CLI ile cluster ekle
argocd cluster add <CONTEXT> --label tier=production --label region=eu-west-1
```

### 4. Project-based izolasyon
ApplicationSet AppProject ile birleşir:
```yaml
template:
  spec:
    project: payments-team   # bu project'in izinli destination'larında
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| 100 manuel Application | Maintenance imkansız | ApplicationSet |
| ApplicationSet'ler `default` project | Hiç izolasyon yok | Per-team AppProject |
| Cluster generator selector yok | Yeni cluster eklendiğinde patlar | `selector: {matchLabels:}` |
| Git directory + manuel exception | Drift | Filter ile düzgün scope |
| `automated.selfHeal: false` ApplicationSet | Drift birikir | true (ya da bilinçli istisna) |
| Preview env'ler temizlenmiyor | Resource israf | `prune: true` + PR closed event |
| Matrix generator çok büyük (1000 app) | API server boğulur | Pagination veya filter |
| ApplicationSet rollout aşamalı değil | Tüm cluster aynı anda → bug yayılır | RollingSync strategy |
| Helm values inline | Diff zor | values.yaml ayrı dosya |
| Generator parametreleri hardcoded | Yeni env eklerken her yer değişir | List generator + tek yerde tut |

---

## 📋 ApplicationSet Adoption Checklist

```
[ ] ApplicationSet controller HA (3 replica)
[ ] Repo yapısı net (apps/, infrastructure/, argocd/)
[ ] AppProject ile izolasyon
[ ] Platform addons → cluster generator
[ ] Apps → git directory generator
[ ] Multi-cluster → matrix generator
[ ] Preview envs → pullRequest generator (opsiyonel)
[ ] App-of-Apps + ApplicationSet kombinasyonu
[ ] RollingSync strategy (dev → staging → prod)
[ ] Cluster label policy (tier, region, env)
[ ] Generator değişiklikleri PR review'dan geçer
[ ] Self-managed: ApplicationSet'ler de Git'te
[ ] Drift: selfHeal aktif
[ ] Documentation: yeni team nasıl onboard olur
```

---

## 📚 Referanslar

- **ApplicationSet Docs** — argocd-applicationset.readthedocs.io
- **Argo CD Generators** — argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/
- **GitOps Patterns** — opengitops.dev
- [`ArgoCD-Setup.md`](ArgoCD-Setup.md)
- _`App-of-Apps-Pattern.md`_ *(yakında)*
- [`Helm-vs-Kustomize-vs-Raw.md`](Helm-vs-Kustomize-vs-Raw.md)
- [`08-Security/Policy-as-Code-OPA-Kyverno.md`](../08-Security/Policy-as-Code-OPA-Kyverno.md) — multi-cluster policy

---

> *"ApplicationSet, **YAML çoğaltıcı** değil — **manifest factory**.
> 'Yeni cluster ekledim, kim hangi addon'ı kuracak?' sorusuna cevap
> verir: **kimse, otomatik kurar**."*
