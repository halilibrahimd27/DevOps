#!/usr/bin/env bash
# setup.sh — K04 ortamını BİLEREK BOZUK kurar (iki katman: image tag + NetworkPolicy).
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "Bu lab kubectl + yerel bir cluster (kind/k3s) gerektirir." >&2
  exit 1
fi
if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "Erişilebilir bir cluster yok. Önce: kind create cluster --name lab-d1" >&2
  exit 1
fi

WORK="$(pwd)/env"
rm -rf "$WORK"; mkdir -p "$WORK"

# BOZUK 1: image tag mevcut değil → ImagePullBackOff
cat > "$WORK/deployment.yaml" <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: k04
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: k04
  labels: { app: app }
spec:
  replicas: 1
  selector:
    matchLabels: { app: app }
  template:
    metadata:
      labels: { app: app }
    spec:
      containers:
        - name: web
          image: nginxinc/nginx-unprivileged:0.0-does-not-exist   # BOZUK: yok olan tag
          ports:
            - containerPort: 8080
YAML

cat > "$WORK/service.yaml" <<'YAML'
apiVersion: v1
kind: Service
metadata:
  name: app-svc
  namespace: k04
spec:
  selector: { app: app }
  ports:
    - port: 80
      targetPort: 8080
YAML

# BOZUK 2: default-deny var ama İZİN kuralı YOK → Pod Running olsa bile erişilemez
cat > "$WORK/networkpolicy.yaml" <<'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: k04
spec:
  podSelector: {}
  policyTypes: ["Ingress"]
  # ingress kuralı YOK → hiçbir gelen bağlantı kabul edilmez (izin kuralı eksik)
YAML

kubectl apply -f "$WORK/deployment.yaml" >/dev/null
kubectl apply -f "$WORK/service.yaml" >/dev/null
kubectl apply -f "$WORK/networkpolicy.yaml" >/dev/null

echo "Kuruldu (namespace: k04)."
echo "Belirti 1: kubectl -n k04 get pods → ImagePullBackOff"
echo "Belirti 2: image düzeltilse bile servise erişilemez (ağ katmanı)."
echo "Teşhise başla: kubectl -n k04 describe pod  /  get events  /  get networkpolicy"
