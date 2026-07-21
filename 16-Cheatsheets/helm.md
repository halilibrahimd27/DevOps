---
description: "Helm 3+ için komut notları: repo yönetimi, chart template debug, release kurulumu/upgrade, hook'lar ve OCI registry. Tiller'sız, namespace bazlı release."
tags:
  - Cheatsheet
  - Helm
  - Kubernetes
  - Containers
---
# Helm Cheatsheet

> Helm 3+ varsayılır. Tiller'sız, namespace bazlı release.

## 📦 Repo Yönetimi

```bash
# Repo ekle
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Listele / güncelle / sil
helm repo list
helm repo update
helm repo remove bitnami

# Search
helm search repo postgresql
helm search hub ingress           # ArtifactHub'ı arar
```

## 🔍 Inspect

```bash
# Chart bilgisi
helm show chart bitnami/postgresql
helm show values bitnami/postgresql > postgresql-defaults.yaml
helm show readme bitnami/postgresql
helm show all bitnami/postgresql

# Specific version
helm show values bitnami/postgresql --version 12.5.0
```

## 🚀 Install / Upgrade

```bash
# Install
helm install <RELEASE> bitnami/postgresql -n <NS> --create-namespace

# Custom values
helm install <RELEASE> bitnami/postgresql -f values.yaml -n <NS>

# Multiple values files (sonraki öncekini override eder)
helm install <RELEASE> bitnami/postgresql -f values.yaml -f values-prod.yaml

# CLI override
helm install <RELEASE> bitnami/postgresql \
  --set primary.persistence.size=20Gi \
  --set auth.username=appuser \
  --set image.tag=16

# Specific version
helm install <RELEASE> bitnami/postgresql --version 12.5.0

# Dry run (manifestleri görmek)
helm install <RELEASE> bitnami/postgresql --dry-run --debug

# Upgrade (atomic = fail durumunda otomatik rollback)
helm upgrade --install <RELEASE> bitnami/postgresql \
  -f values.yaml \
  --atomic \
  --timeout 5m

# Force re-install
helm upgrade <RELEASE> bitnami/postgresql --force

# Reset values (önceki değerleri sıfırla)
helm upgrade <RELEASE> bitnami/postgresql --reset-values
```

## 📋 List / Status / History

```bash
# Tüm release'ler
helm list
helm list -A                       # tüm namespace'ler
helm list --all                    # failed/uninstalled dahil

# Release durumu
helm status <RELEASE>
helm status <RELEASE> -n <NS> --show-resources

# Hooks/notes
helm get notes <RELEASE>
helm get values <RELEASE>          # uygulanan values
helm get values <RELEASE> --all    # default + override
helm get manifest <RELEASE>        # uygulanan manifestler

# History (rollback için)
helm history <RELEASE>
```

## ↩️ Rollback / Uninstall

```bash
# Rollback (önceki revision'a)
helm rollback <RELEASE>
helm rollback <RELEASE> 3          # specific revision
helm rollback <RELEASE> --wait --timeout 5m

# Uninstall
helm uninstall <RELEASE>
helm uninstall <RELEASE> --keep-history       # rollback için
helm uninstall <RELEASE> -n <NS>
```

## 🛠️ Chart Geliştirme

```bash
# Yeni chart iskeleti oluştur
helm create my-app

# Chart yapısı:
# my-app/
# ├── Chart.yaml          ← chart metadata
# ├── values.yaml         ← default values
# ├── values.schema.json  ← values doğrulama
# ├── templates/
# │   ├── deployment.yaml
# │   ├── service.yaml
# │   ├── ingress.yaml
# │   ├── _helpers.tpl
# │   └── NOTES.txt
# ├── charts/             ← dependencies
# └── tests/

# Lint
helm lint my-app
helm lint my-app -f values.yaml

# Template render (apply etmeden manifestleri gör)
helm template my-app
helm template <RELEASE> my-app -f values.yaml
helm template <RELEASE> my-app --debug --show-only templates/deployment.yaml

# Package
helm package my-app
helm package my-app --destination ./dist

# Dependency
helm dependency update my-app    # Chart.yaml'daki dependencies'i indir
helm dependency build my-app     # Chart.lock'tan
```

## 🔬 Debug

```bash
# Render edilen manifest'i debug
helm install <RELEASE> my-app --dry-run --debug

# Belirli bir resource'u render et
helm template <RELEASE> my-app --show-only templates/deployment.yaml

# Failed release'in hatasına bak
helm status <RELEASE>
kubectl get events -n <NS> --sort-by='.lastTimestamp'

# Hook'lar (preInstall vb)
helm install <RELEASE> my-app --no-hooks      # hook'ları skip et
```

## 📝 Templating Basics

### `_helpers.tpl`
```yaml
{{/*
Common labels
*/}}
{{- define "my-app.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}
```

### Template kullanımı
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        env:
        {{- range $k, $v := .Values.env }}
        - name: {{ $k }}
          value: {{ $v | quote }}
        {{- end }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        {{- with .Values.probes }}
        livenessProbe:
          {{- toYaml .liveness | nindent 10 }}
        readinessProbe:
          {{- toYaml .readiness | nindent 10 }}
        {{- end }}
```

### Conditional
```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
# ...
{{- end }}
```

### Range
```yaml
volumes:
{{- range .Values.extraVolumes }}
- name: {{ .name }}
  {{- toYaml . | nindent 2 }}
{{- end }}
```

### Functions
```yaml
{{ "Hello" | upper }}                    # HELLO
{{ .Values.tag | default "latest" }}
{{ .Values.host | required ".host required" }}
{{ tpl .Values.template . }}             # nested templating
{{ now | date "2006-01-02" }}
{{ randAlphaNum 16 }}
{{ .Values.config | toYaml | nindent 4 }}
```

## 🔐 OCI Registry

```bash
# Registry'e push (Helm 3.8+)
helm registry login <REGISTRY>
helm push my-app-1.0.0.tgz oci://<REGISTRY>/charts

# Pull
helm pull oci://<REGISTRY>/charts/my-app --version 1.0.0

# Install from OCI
helm install <RELEASE> oci://<REGISTRY>/charts/my-app --version 1.0.0
```

## 🪝 Hooks

```yaml
# templates/post-install-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-migrate
  annotations:
    "helm.sh/hook": post-install,post-upgrade
    "helm.sh/hook-weight": "1"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: my-app:{{ .Chart.AppVersion }}
        command: ["./migrate"]
      restartPolicy: Never
```

## ⚡ Faydalı one-liner'lar

```bash
# Tüm namespace'lerdeki release'lerin chart versiyonu
helm list -A -o json | jq '.[] | "\(.namespace)/\(.name)\t\(.chart)"'

# Outdated chart'lar
helm list -A | tail -n +2 | awk '{print $1, $2, $9}' | \
  while read name ns chart; do
    repo=$(echo $chart | cut -d'-' -f1)
    helm search repo $repo --version $(echo $chart | cut -d'-' -f2-)
  done

# Release'in tüm secret'larını gör (Helm internal)
kubectl get secret -A -l owner=helm

# Manuel Helm 2 → 3 migration (legacy)
helm-2to3 convert <RELEASE>
```

## 🆘 Acil senaryolar

| Sorun | Çözüm |
|---|---|
| `another operation in progress` | Helm 3'te `helm rollback <RELEASE>` veya secret'ı manuel temizle: `kubectl delete secret -l name=<RELEASE>` |
| Failed install hayalet kaldı | `helm uninstall <RELEASE> --no-hooks` |
| Values değiştirdim ama uygulanmadı | `helm upgrade --reset-values` veya `--force` |
| Dependency güncellenmiyor | `helm dependency update`, sonra `Chart.lock`'u commit'le |
| Manifests render olmuyor | `helm template ... --debug --show-only` ile spesifik dosya |
| Hook never finishes | `helm install --no-hooks` ile bypass + manuel hook çalıştır |
