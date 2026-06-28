---
description: "App-of-Apps pattern: ArgoCD'yi tek bir root Application ile bootstrap edip kendi kendini yöneten self-managed GitOps akışına dönüştürme rehberi."
tags:
  - GitOps
  - ArgoCD
  - Kubernetes
  - Platform Engineering
---
# App-of-Apps Pattern — ArgoCD'yi Kendi Kendinden Yönet

> *"ArgoCD'yi `helm install` ile manuel kuran ekip, bir gün
> 'ArgoCD'yi kim upgrade ediyor?' sorusunda yetim kalır.
> **App-of-Apps** = ArgoCD'nin kendisi de Git'ten yönetilir."*

Bu rehber **App-of-Apps** pattern'ini, **bootstrap**'i, ve ArgoCD'yi
kendi kendine self-managed hale getirmenin somut akışını açıklar.

---

## 🎯 Pattern Nedir?

```
[Root Application]              ← bootstrap, manuel oluşturulan tek kaynak
   │
   │ (ArgoCD sync)
   ▼
[child-app-1, child-app-2, ...] ← her biri ayrı Application
   │
   ▼
[K8s resources deploy]
```

> **App-of-Apps**: Tek bir "root" Application Git repo'daki diğer
> Application manifest'lerini deploy eder. Bu Application'lar da kendi
> resource'larını deploy eder. Sonuç: **1 manuel kaynak**, geri kalan
> her şey GitOps.

---

## 🆚 ApplicationSet vs App-of-Apps

| Boyut | App-of-Apps | ApplicationSet |
|---|---|---|
| **Mekanizma** | Application içinde Application manifest | CRD ile generator-driven |
| **Lookup** | Statik (Git'te yazılı) | Dinamik (cluster, git, scm) |
| **Best for** | Bootstrap, infrastructure | Multi-cluster, multi-tenant pattern |
| **Karmaşıklık** | Düşük | Orta |
| **2026 önerisi** | Bootstrap için | Apps için |

> 🔑 **Kombinasyon**: App-of-Apps ile bootstrap → içinde ApplicationSet'ler. Ekipte hem stabilite hem flexibility.

---

## 🏗️ Repo Yapısı

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
│   │   └── platform-tools.yaml      # tek Application: backstage
│   └── root-app.yaml                # bu kaynak manuel apply edilir
├── infrastructure/                   # Helm charts / kustomize
│   ├── cert-manager/
│   ├── ingress-nginx/
│   ├── external-secrets/
│   └── ...
├── monitoring/
│   ├── prometheus-stack/
│   ├── grafana/
│   └── loki/
└── apps/                              # tenant uygulamaları
    └── ...
```

---

## 🚀 Bootstrap Akışı

### Adım 1: Manuel ArgoCD install
```bash
helm install argocd argo/argo-cd \
  -n argocd --create-namespace \
  --version <CHART_VERSION> \
  -f argocd-values.yaml
```

### Adım 2: Root Application apply
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
    path: argocd/applications        # ApplicationSet/App manifestleri burada
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

### Adım 3: Sonra her şey GitOps
- Yeni infra eklendi → `argocd/applications/` altına ApplicationSet PR
- ArgoCD root-app'i sync eder → yeni ApplicationSet doğar → kaynaklar deploy

> 🔑 **Tek manuel kaynak**: root-app.yaml. Geri kalan her şey **kod**.

---

## 🔄 Self-Managed ArgoCD

ArgoCD kendi kendisini de yönetebilir:

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
      prune: false      # ⚠️ ArgoCD kendi kendini silmesin
      selfHeal: true
    syncOptions:
      - ServerSideApply=true
```

> 🔑 **`prune: false`**: ArgoCD kendi kaynaklarını yanlışlıkla silmesin.
> Diğer her şey için `prune: true` OK.

### ArgoCD upgrade akışı
1. PR: `targetRevision: <YENİ_VERSION>`
2. CI lint + test
3. Merge → ArgoCD self-app sync
4. ArgoCD pod'ları rolling restart
5. Yeni versiyona geçti

> ⚠️ **Major upgrade'de** önce staging cluster'da test et — breaking change olabilir.

---

## 🧬 İçinde ApplicationSet'ler

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

> 🔑 `sync-wave` ile sıralı: cert-manager (wave 0) ingress-nginx'ten önce.

---

## 🏛️ AppProject ile İzolasyon

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

## 🚧 Tipik Akış: Yeni Servis Ekleme

```
1. Dev: app repo'da kod + Dockerfile + k8s manifest
2. CI: image build + push to registry
3. CI: bump image tag in k8s-config repo (PR)
4. PR review (CODEOWNERS)
5. Merge → ArgoCD root-app reconcile
6. apps-prod ApplicationSet → yeni servis tespit
7. ArgoCD child Application yaratır
8. Sync → cluster'a deploy
9. Notification: Slack #deployments
```

> 🔑 Mühendisin tek dokunduğu: **PR**. Geri kalan otomatik.

---

## 🛡️ Recovery: ArgoCD Cluster Kaybı

Cluster baştan kurulurken:
```bash
# 1. Yeni cluster ayağa kalktı
# 2. ArgoCD manuel install (Helm)
helm install argocd argo/argo-cd ...

# 3. Root Application apply
kubectl apply -f argocd/root-app.yaml

# 4. ArgoCD root'u sync eder, içeriği reconcile başlar
# 5. ApplicationSet'ler doğar
# 6. Tüm cluster (infrastructure + apps) Git state'ine ulaşır
```

**Toplam DR süresi**: ArgoCD install (5 dk) + Root apply (1 dk) + reconcile (~30 dk).

> 🔑 **Cluster ölümlü, Git ebedi.** App-of-Apps'in en güçlü yanı: cluster'ı **Git'ten yeniden doğurabiliyorsun**.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| ArgoCD manuel install + manuel app'ler | Drift, "kim ne yaptı" belirsiz | App-of-Apps + GitOps |
| Root-app `prune: true` | ArgoCD kendi kaynaklarını silebilir | `prune: false` self için |
| Tek root-app 50 child | YAML fazla, debug zor | İç ApplicationSet'lere böl |
| Manuel `kubectl apply` cluster'da | Drift, GitOps amacı yok | Tüm değişiklik PR ile |
| AppProject kullanılmıyor | İzolasyon yok, herkes her yere | Per-team project |
| `default` project çok şey yapar | Privilege creep | Minimal default + spesifik project'ler |
| Sync wave kullanılmıyor | CRD yokken Application sync hata verir | Wave -1, 0, 1, 2 sırası |
| Self-managed ArgoCD upgrade test yok | Major bug prod'a | Lab cluster'da önce test |
| Root-app branch'i `main` değil | Fork drift | `main` veya release tag |
| ApplicationSet generator filter eksik | İstemediğin şey deploy oluyor | `selector: {matchLabels:}` |

---

## 📋 App-of-Apps Adoption Checklist

```
[ ] Manuel kaynak sadece root-app.yaml + helm install
[ ] argocd/applications/ klasörü içeriği reconcile
[ ] Self-managed ArgoCD (kendi Application'ı var)
[ ] AppProject per-team izolasyon
[ ] ApplicationSet kullanımı (multi-cluster, multi-tenant)
[ ] Sync wave: CRD → namespace → app
[ ] Notification: ArgoCD → Slack/PagerDuty
[ ] Prune: app'lerde true, self için false
[ ] DR test: cluster sıfırla → App-of-Apps'le geri çağır
[ ] Documentation: yeni ekip nasıl onboard oluyor
[ ] Bootstrap script: yeni cluster için tek komut
[ ] Quarterly: ArgoCD upgrade (major versiyonu)
[ ] CODEOWNERS k8s-config repo'da
[ ] Branch protection main + required reviews
```

---

## 📚 Referanslar

- **ArgoCD Cluster Bootstrapping** — argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/
- **Argo Best Practices** — github.com/argoproj/argo-cd/blob/master/docs/operator-manual/best-practices.md
- **OpenGitOps** — opengitops.dev
- [`ArgoCD-Setup.md`](ArgoCD-Setup.md)
- [`ApplicationSet-Patterns.md`](ApplicationSet-Patterns.md)
- [`Helm-vs-Kustomize-vs-Raw.md`](Helm-vs-Kustomize-vs-Raw.md)
- [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md) — secret management

---

> *"App-of-Apps 'fancy bir pattern' değil, **GitOps disiplinin
> kendisi**. Manuel kaynak sayını **1**'e indirir; kalan her şey
> Git'in kontrolünde olur."*
