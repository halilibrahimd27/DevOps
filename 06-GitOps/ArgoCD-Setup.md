# ArgoCD Setup — Production-Grade GitOps Kurulumu

> *"GitOps demek, cluster'da olan ile Git'te yazan **arasında fark
> olmaması** demek. ArgoCD bu farkı sürekli ölçer ve düzeltir — sen
> yazılı niyet, o uygulamaktan sorumludur."*

Bu rehber sıfırdan bir ArgoCD kurulumunu prod-grade seviyeye taşır:
HA, SSO, RBAC, AppProject, Notification, ApplicationSet ile multi-cluster.

---

## 🎯 ArgoCD'nin Yeri

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

ArgoCD **pull-based** çalışır:
- Cluster credential'ları **ArgoCD'de**, CI'da değil
- CI sadece imaj build edip Git'e tag bump PR atar
- ArgoCD her 3 dakikada (default) Git'i çekip cluster'la kıyaslar
- Drift varsa: heal et (auto-sync) veya alarm (manual)

---

## 🏗️ Kurulum (HA, Production)

### Helm chart (önerilen)
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd \
  -n argocd --create-namespace \
  --version <CHART_VERSION> \
  -f argocd-values.yaml
```

### `argocd-values.yaml` (anahtar bölümler)
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
  enabled: false   # bizim için harici OIDC, dex'e gerek yok

redis-ha:
  enabled: true   # production: HA Redis (sentinel)

configs:
  params:
    server.insecure: false
    application.namespaces: "*"   # ArgoCD CRD'leri her ns'de okuyabilir
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

> 🔑 **Notlar:**
> - `controller.replicas: 1` 2026'da hâlâ önerilen; sharding GA değil
> - Redis-HA olmadan ArgoCD restart'larda cache kaybeder
> - `ingress.backend-protocol: GRPC` — `argocd` CLI gRPC kullanır

---

## 🔐 SSO (OIDC) — İlk Gün Yap

Default `admin` user **yasak**. SSO'ya bağla.

### Initial admin password (sadece bir kez)
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```
İlk login → SSO config → admin user devre dışı:
```yaml
configs:
  cm:
    admin.enabled: false
```

### OIDC config (örn: Keycloak / Auth0 / Google Workspace)
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

### RBAC — grup-based
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

> 🔑 `policy.default: role:read-only` — her authenticated user en azından
> görebilir; ihlal edici değilim. Yazma yetkisi grup-bazlı.

---

## 🗂️ AppProject — İzolasyon

Default `default` AppProject çok geniş. Her ekibe/scope'a kendi project:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: payments-team
  namespace: argocd
spec:
  description: Payments team applications

  # Hangi Git repo'lardan source çekilebilir
  sourceRepos:
    - https://github.com/<ORG>/k8s-config
    - https://charts.example.com

  # Hangi cluster + namespace'lere deploy edilebilir
  destinations:
    - server: https://kubernetes.default.svc
      namespace: payments-*
    - name: prod-cluster
      namespace: payments-prod

  # Hangi resource'lar izinli (whitelist)
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

  # RBAC: bu projeye kim erişebilir
  roles:
    - name: developer
      policies:
        - p, proj:payments-team:developer, applications, sync, payments-team/*, allow
        - p, proj:payments-team:developer, applications, get, payments-team/*, allow
      groups:
        - <ORG>:payments-team
```

---

## 📦 İlk Application — Hello World

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
      prune: true       # Git'ten silinen kaynak cluster'dan da silinir
      selfHeal: true    # cluster'da manuel değişiklik → geri al
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

> 🔑 **`automated.selfHeal: true`** GitOps'un ruhu. Manuel `kubectl edit`
> değişikliği ArgoCD geri alır → drift = 0.

---

## 🧬 ApplicationSet — Multi-Cluster / Multi-Tenant

ApplicationSet bir CRD ile **N tane Application** üretir. Multi-cluster
deploy'ın anahtarı.

### Cluster generator (registered cluster'lar için)
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

### Git generator (Git'teki klasör başına 1 app)
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

### Auto-sync (önerilen prod için)
```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```
- Git push → 3 dk içinde cluster'da
- Manuel drift otomatik düzelir

### Manual sync (gated environments)
```yaml
syncPolicy: {}   # automated yok
```
- Operatör elle `argocd app sync <app>` der
- Production change-review akışı için

### Sync waves (sıralı deploy)
```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"   # önce CRD, sonra namespace, sonra app
```

| Wave | Tipik içerik |
|---|---|
| `-1` | CRD'ler, RBAC |
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

Tipik kullanım: DB migration job PreSync, smoke test PostSync.

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

### Prometheus metrics (built-in, scrape et)
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

### Anahtar alarmlar
```yaml
groups:
  - name: argocd
    rules:
      - alert: ArgoCDAppOutOfSync
        expr: argocd_app_info{sync_status!="Synced"} == 1
        for: 30m
        annotations:
          summary: "{{ $labels.name }} OutOfSync 30+ dk"

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

ArgoCD'nin kendi başına secret çözümü yok. Üç ana yaklaşım:

| Yaklaşım | Pro | Con |
|---|---|---|
| **External Secrets Operator** + Vault | Cluster + secret kaynağı ayrı, audit | İlk kurulum ek iş |
| **Sealed Secrets** | Git'te şifreli commit | Tek key, rotation karmaşık |
| **SOPS** + helm-secrets / Argo-vault-plugin | Multi-recipient, age key | Plugin install + key dağıtımı |

> Detay: _`Secrets-in-GitOps.md`_ *(yakında)* (Faz ileri) ve
> [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md).

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Git'te + cluster'da manuel `kubectl apply` | Drift, source of truth yok | Sadece Git |
| `default` AppProject her şey için | İzolasyon yok | Per-team AppProject |
| Admin user aktif | Kim yaptı? Audit yok | SSO + admin disable |
| ArgoCD self-managed değil | Argo upgrade'i unutulur | App-of-Apps ile self-managed |
| Tüm cluster'lar aynı app'leri farklı yöntemle | Drift, manuel iş | ApplicationSet cluster generator |
| Auto-sync `selfHeal: false` | Drift kalır, niyet ≠ gerçek | `selfHeal: true` (prod'da bilinçli istisna) |
| Application namespace = `default` | Namespace cleanup imkansız | Per-app dedicated namespace |
| Notification yok | Sync failed → kimse görmez | Slack + alert |
| Production'a `automated` sync direct | Risk: kötü PR direkt prod | Promotion: dev/auto → staging/auto → prod/manual ya da sync window |
| Helm chart inline values | Diff zor okunur | values.yaml ayrı, kustomize ile patch |
| Secret Git'te plaintext | İhlal an meselesi | SOPS / Sealed / ESO |
| ArgoCD auth: token tüm CI'da | Compromise → cluster sahibi | SSO + per-pipeline minimal RBAC |

---

## 📋 Production-Grade Checklist

```
[ ] HA: server x3, repoServer x3, redis-ha
[ ] Ingress + TLS (cert-manager)
[ ] SSO (OIDC), admin disabled
[ ] RBAC: grup-based, default read-only
[ ] AppProject: per-team izolasyon
[ ] App-of-Apps: ArgoCD kendisi de Git'ten yönetiliyor
[ ] ApplicationSet: multi-cluster sync (ingress, cert-manager, ESO)
[ ] Auto-sync + selfHeal (prod'da gated mı bilinçli karar)
[ ] Sync waves: CRD → namespace → app sıralı
[ ] Hooks: DB migration PreSync
[ ] Notifications: Slack + alert (sync failed, out-of-sync 30dk)
[ ] Prometheus metrics + ServiceMonitor
[ ] Alert: AppUnhealthy, AppOutOfSync, ControllerDown
[ ] Backup: ArgoCD CRD'leri Git'te zaten; Redis durum yedekli
[ ] Secret: ESO veya SOPS — Git'te plaintext yok
[ ] ArgoCD upgrade: minor versiyonu quarterly takip
[ ] DR: cluster çökerse ArgoCD'yi yeniden bootstrap dokumante
```

---

## 📚 Referanslar

- **ArgoCD Docs** — argo-cd.readthedocs.io
- **ApplicationSet Generators** — argocd-applicationset.readthedocs.io
- **OpenGitOps Principles** — opengitops.dev
- **GitOps Working Group (CNCF)**
- [`App-of-Apps-Pattern.md`](App-of-Apps-Pattern.md)
- [`ApplicationSet-Patterns.md`](ApplicationSet-Patterns.md)
- [`Helm-vs-Kustomize-vs-Raw.md`](Helm-vs-Kustomize-vs-Raw.md)
- [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md)
- [`08-Security/Policy-as-Code-OPA-Kyverno.md`](../08-Security/Policy-as-Code-OPA-Kyverno.md) — admission ile uyum

---

> *"GitOps cluster'ı bir **fonksiyon** yapar: input Git, output cluster
> state. Aralarına manuel müdahale eklediğin an, fonksiyon değil
> **dilek listesi**."*
