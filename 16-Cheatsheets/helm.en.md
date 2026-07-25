---
description: "Command notes for Helm 3+: repo management, chart template debug, release install/upgrade, hooks, and OCI registry. No Tiller, namespace-scoped releases."
tags:
  - Cheatsheet
  - Helm
  - Kubernetes
  - Containers
---
# Helm Cheatsheet

> Assumes Helm 3+. No Tiller, namespace-scoped releases.

## 📦 Repo Management

```bash
# Add repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# List / update / remove
helm repo list
helm repo update
helm repo remove bitnami

# Search
helm search repo postgresql
helm search hub ingress           # searches ArtifactHub
```

## 🔍 Inspect

```bash
# Chart info
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

# Multiple values files (later overrides earlier)
helm install <RELEASE> bitnami/postgresql -f values.yaml -f values-prod.yaml

# CLI override
helm install <RELEASE> bitnami/postgresql \
  --set primary.persistence.size=20Gi \
  --set auth.username=appuser \
  --set image.tag=16

# Specific version
helm install <RELEASE> bitnami/postgresql --version 12.5.0

# Dry run (see the manifests)
helm install <RELEASE> bitnami/postgresql --dry-run --debug

# Upgrade (atomic = auto rollback on failure)
helm upgrade --install <RELEASE> bitnami/postgresql \
  -f values.yaml \
  --atomic \
  --timeout 5m

# Force re-install
helm upgrade <RELEASE> bitnami/postgresql --force

# Reset values (clear previous values)
helm upgrade <RELEASE> bitnami/postgresql --reset-values
```

## 📋 List / Status / History

```bash
# All releases
helm list
helm list -A                       # all namespaces
helm list --all                    # includes failed/uninstalled

# Release status
helm status <RELEASE>
helm status <RELEASE> -n <NS> --show-resources

# Hooks/notes
helm get notes <RELEASE>
helm get values <RELEASE>          # applied values
helm get values <RELEASE> --all    # default + override
helm get manifest <RELEASE>        # applied manifests

# History (for rollback)
helm history <RELEASE>
```

## ↩️ Rollback / Uninstall

```bash
# Rollback (to previous revision)
helm rollback <RELEASE>
helm rollback <RELEASE> 3          # specific revision
helm rollback <RELEASE> --wait --timeout 5m

# Uninstall
helm uninstall <RELEASE>
helm uninstall <RELEASE> --keep-history       # for rollback
helm uninstall <RELEASE> -n <NS>
```

## 🛠️ Chart Development

```bash
# Create a new chart scaffold
helm create my-app

# Chart structure:
# my-app/
# ├── Chart.yaml          ← chart metadata
# ├── values.yaml         ← default values
# ├── values.schema.json  ← values validation
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

# Template render (see manifests without applying)
helm template my-app
helm template <RELEASE> my-app -f values.yaml
helm template <RELEASE> my-app --debug --show-only templates/deployment.yaml

# Package
helm package my-app
helm package my-app --destination ./dist

# Dependency
helm dependency update my-app    # download dependencies from Chart.yaml
helm dependency build my-app     # from Chart.lock
```

## 🔬 Debug

```bash
# Debug the rendered manifest
helm install <RELEASE> my-app --dry-run --debug

# Render a specific resource
helm template <RELEASE> my-app --show-only templates/deployment.yaml

# Look at the failed release's error
helm status <RELEASE>
kubectl get events -n <NS> --sort-by='.lastTimestamp'

# Hooks (preInstall etc.)
helm install <RELEASE> my-app --no-hooks      # skip the hooks
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

### Template usage
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
# Push to registry (Helm 3.8+)
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

## ⚡ Handy one-liners

```bash
# Chart version of releases across all namespaces
helm list -A -o json | jq '.[] | "\(.namespace)/\(.name)\t\(.chart)"'

# Outdated charts
helm list -A | tail -n +2 | awk '{print $1, $2, $9}' | \
  while read name ns chart; do
    repo=$(echo $chart | cut -d'-' -f1)
    helm search repo $repo --version $(echo $chart | cut -d'-' -f2-)
  done

# See all of a release's secrets (Helm internal)
kubectl get secret -A -l owner=helm

# Manual Helm 2 → 3 migration (legacy)
helm-2to3 convert <RELEASE>
```

## 🆘 Emergency scenarios

| Issue | Fix |
|---|---|
| `another operation in progress` | In Helm 3, `helm rollback <RELEASE>` or clear the secret manually: `kubectl delete secret -l name=<RELEASE>` |
| Failed install left a ghost | `helm uninstall <RELEASE> --no-hooks` |
| Changed values but they didn't apply | `helm upgrade --reset-values` or `--force` |
| Dependency won't update | `helm dependency update`, then commit `Chart.lock` |
| Manifests not rendering | specific file via `helm template ... --debug --show-only` |
| Hook never finishes | bypass with `helm install --no-hooks` + run the hook manually |
