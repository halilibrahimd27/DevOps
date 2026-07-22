#!/usr/bin/env bash
# setup.sh — K07: inc/api'yi BİLEREK iki bağımsız arızayla kurar.
#   (1) configMapKeyRef var olmayan key ister → pod'lar CreateContainerConfigError
#   (2) Service selector pod etiketiyle uyuşmaz → endpoint boş
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v kubectl >/dev/null 2>&1 || ! kubectl cluster-info >/dev/null 2>&1; then
  echo "Bu lab kubectl + çalışan bir cluster (kind/k3s) gerektirir." >&2
  exit 1
fi

kubectl create namespace inc --dry-run=client -o yaml | kubectl apply -f - >/dev/null

kubectl -n inc apply -f - >/dev/null <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
data:
  mode: "production"          # key adı: 'mode'
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server        # pod etiketi: api-server
    spec:
      containers:
        - name: api
          image: nginxinc/nginx-unprivileged:1.27-alpine
          ports:
            - containerPort: 8080
          env:
            - name: APP_MODE
              valueFrom:
                configMapKeyRef:
                  name: api-config
                  key: app_mode  # ARIZA 1: CM'de 'mode' var, 'app_mode' yok
---
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector:
    app: api                   # ARIZA 2: pod'lar 'api-server' etiketli, buraya uymuyor
  ports:
    - port: 80
      targetPort: 8080
YAML

echo "Kuruldu. Belirti: inc/api Service'ine erişilemiyor."
echo "Zaman damgalı not tutmaya başla (timeline.md). Teşhise endpoints'ten başla:"
echo "  kubectl -n inc get endpoints api"
