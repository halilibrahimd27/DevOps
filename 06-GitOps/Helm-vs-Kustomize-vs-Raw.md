# Helm vs Kustomize vs Raw YAML — Manifest Stratejisi Karar Rehberi

> *"Üç araç, üç farklı felsefe. Yanlış seçim 6 ay sonra 'her şeyi
> baştan yazmak' istemenize sebep olur. **Doğru seçim** sizi 6 yıl
> rahat ettirir."*

Bu rehber Kubernetes manifest'lerini yönetmek için 3 büyük yaklaşımı —
Helm, Kustomize, Raw YAML — karşılaştırır. Net karar ağacı + pratik
örneklerle.

---

## 🎯 Üç Yaklaşımın Felsefesi

| Yaklaşım | Felsefe | Bir cümlede |
|---|---|---|
| **Raw YAML** | "Manifesto = manifest" | YAML dosyaları kopyala-yapıştır + sed/envsubst |
| **Kustomize** | "Patch + overlay" | Base manifest'i farklı ortam için katman katman değiştir |
| **Helm** | "Template + paket" | Go templating + values.yaml + chart paketleme |

---

## 📊 Detaylı Karşılaştırma

| Boyut | **Raw YAML** | **Kustomize** | **Helm** |
|---|---|---|---|
| **Templating** | Yok | Yok (patch-based) | Go templates `{{ }}` |
| **Variable substitution** | envsubst / sed | Replacements + vars | `.Values` |
| **Multi-env** | Manuel kopya | base + overlays | `values-<env>.yaml` |
| **Reusability** | Düşük (copy-paste) | Orta (component) | Yüksek (chart + dep) |
| **Versioning** | Git tag | Git tag | Chart version + repo |
| **Distribution** | Git | Git | OCI registry, Helm repo |
| **Diff readability** | ✅ İyi (raw YAML) | ✅ İyi | ⚠️ Render gerekli |
| **Öğrenme eğrisi** | 🟢 Sıfır | 🟧 Orta | 🟥 Yüksek |
| **Built-in K8s** | ✅ `kubectl apply` | ✅ `kubectl apply -k` | ❌ helm CLI gerekli |
| **Helper functions** | Yok | Sınırlı | Zengin (`include`, `template`) |
| **Conditional logic** | Yok | Patch ile sınırlı | If/else native |
| **Hooks** | Yok | Yok | `pre-install`, `post-upgrade` |
| **Rollback** | Manuel | Manuel | `helm rollback` |
| **Dependency** | Manuel | Component | Chart dependency |
| **Schema validation** | Yok | Yok | JSON schema (`values.schema.json`) |
| **Template debug** | n/a | `kubectl kustomize` | `helm template` |
| **Best for** | Tek-env, ufak | Multi-env, GitOps | Reusable, vendor distribution |

---

## 🌳 Karar Ağacı

```
START
  │
  ├── Vendor / open-source uygulama deploy ediyorsun?
  │     │
  │     └── EVET → HELM
  │            (cert-manager, ingress-nginx, prometheus, vb.
  │             zaten Helm chart olarak dağıtılır)
  │
  ├── Tek environment, hiç değişiklik yok mu?
  │     │
  │     └── EVET → RAW YAML
  │            (öğrenmesi zor değil, basit kalır)
  │
  ├── Multi-env (dev/staging/prod) ama benzer manifest?
  │     │
  │     └── EVET → KUSTOMIZE
  │            (base + overlays = en temiz pattern)
  │
  ├── Internal microservice'leri standardize et + reuse?
  │     │
  │     └── EVET → HELM CHART (internal)
  │            (ya da Kustomize component)
  │
  └── Karmaşık conditional + helper logic?
         │
         └── EVET → HELM (template power)
```

> 🔑 **Pratik kombinasyon:** Vendor app'ler için **Helm**, internal app'ler için
> **Kustomize**. İkisini birlikte kullanabilirsin.

---

## 🛠️ Raw YAML

### Yapı
```
k8s/
├── deployment.yaml
├── service.yaml
├── ingress.yaml
└── configmap.yaml
```

### Multi-env (envsubst ile)
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
- Hiç öğrenme yok
- Diff temiz
- `kubectl apply -f .` yeter

### ❌ Con
- Multi-env → kopya cehennemi
- Reuse yok
- 10+ servis hızla unmaintainable

> 🔑 **Ne zaman?** Tek dev cluster, hobby project, learning. Production'da scale etmez.

---

## 🛠️ Kustomize

K8s 1.14+ native, `kubectl apply -k` ile çalışır.

### Yapı
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
# Render et + bak
kubectl kustomize overlays/prod

# Direct apply
kubectl apply -k overlays/prod
```

### ✅ Pro
- K8s native (extra tool yok)
- YAML kalır (template language yok)
- Diff'lerin okuma kalitesi
- GitOps friendly (ArgoCD, Flux native destek)
- Component (reusable patch grubu)

### ❌ Con
- Sınırlı conditional logic
- Helper function yok
- Karmaşık değişikliklerde patch upst patch çoğalır

> 🔑 **Ne zaman?** İnternal microservice'ler, multi-env, GitOps. **2026'da en yaygın internal pattern.**

---

## 🛠️ Helm

### Yapı
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
  tag: ""    # Chart.appVersion kullan
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

helm rollback payments 1 -n payments-prod   # önceki revision

# Render preview
helm template payments ./charts/payments -f values-prod.yaml
```

### ✅ Pro
- Templating gücü (if/else, range, helpers)
- Chart paketleme (OCI registry'de versioned)
- Vendor app'lerin de-facto standardı
- Hooks (pre-install DB migration)
- Dependency management (subchart)
- Schema validation (`values.schema.json`)

### ❌ Con
- Go template syntax (öğrenmesi zor)
- Diff render etmek gerekir
- Template debug zor
- Helm 2 → 3 migration travmaları (artık geçti, Helm 3 stable)
- "Templating language YAML'ı yorar"

> 🔑 **Ne zaman?** Vendor distribution (ingress-nginx, cert-manager, vb.), reusable internal chart, kompleks conditional.

---

## 🔀 Pratik Hibrit: Helm + Kustomize

Helm chart kur, sonra Kustomize ile patch'le. ArgoCD bunu native destekler:

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

> 🔑 Bu pattern: vendor chart + kendi customization'ın. Helm'in gücünü Kustomize'ın
> patching ile birleştir.

---

## 🚦 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Multi-env raw YAML kopyaları | 10 dosya × 3 env = 30 manifest | Kustomize base + overlay |
| Helm chart "her küçük şeye" | Templating overhead, basitlik kayıp | Tek-env basit servis → raw YAML |
| Kustomize patch'leri 30 katman | Okumaz, debug edilmez | Patch'leri konsolide, base'i yeniden tasarla |
| Helm `values.yaml` 500 satır | Override imkansız | values-base + values-env split |
| Helm conditional çok | Template parse hata kaynağı | Chart'ı böl (post-rendering ile) |
| Kustomize'a JSON6902 patch | Okumaz | StrategicMerge tercih et |
| Kustomize generator + version yok | Drift, surprise | configMapGenerator + hash suffix |
| Helm hook'ları sıralı değil | Lifecycle bug'ları | `helm.sh/hook-weight` tanımla |
| Helm chart Git'te + chart repo'da | Senkron yok | Tek kaynak (genelde OCI registry) |
| Inline values ArgoCD'de | Diff zor | values.yaml ayrı dosya |
| Bare K8s manifest + envsubst | Hata-prone | Kustomize tercih |

---

## 📋 Karar Verme Checklist

```
[ ] Hangi yaklaşımı seçtin: Raw / Kustomize / Helm / Hibrit?
[ ] Karar gerekçesi yazılı (ADR / RFC)
[ ] Multi-env stratejisi: base + overlays / values-<env>.yaml
[ ] Image tag pinning: digest > tag > latest
[ ] CI'da render preview (kubectl kustomize / helm template)
[ ] GitOps tool ile uyumlu (ArgoCD/Flux destekliyor mu)
[ ] Diff incelemesi PR review'da görülebiliyor mu
[ ] Schema validation (Helm values.schema.json veya validation script)
[ ] Rollback stratejisi (Helm rollback, kubectl rollout undo, Argo)
[ ] Dependency yönetimi: chart deps veya kustomize bases
[ ] Secret entegrasyonu: SOPS / sealed / ESO
[ ] Sürüm bump akışı (CI → version bump → tag → deploy)
```

---

## 📚 Referanslar

- **Kustomize Docs** — kustomize.io
- **Helm Docs** — helm.sh/docs
- **Helm Best Practices** — helm.sh/docs/chart_best_practices/
- **CNCF App Delivery TAG**
- [`ArgoCD-Setup.md`](ArgoCD-Setup.md)
- _`App-of-Apps-Pattern.md`_ *(yakında)*
- _`ApplicationSet-Patterns.md`_ *(yakında)*
- [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md) — secret entegrasyonu

---

> *"Manifest stratejisi 'tool seçimi' değil, **mühendislik tarz
> kararıdır**. Yanlış seçim 6 ay sonra fark edilir, doğru seçim
> 6 yıl ses çıkarmaz."*
