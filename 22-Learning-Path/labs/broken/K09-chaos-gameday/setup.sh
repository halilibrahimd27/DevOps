#!/usr/bin/env bash
# setup.sh — K09: 'HA görünen ama değil' bir web servisi kurar (game day için).
#   ZAFİYET 1: strategy.type=Recreate → rollout restart TÜM pod'ları aynı anda indirir → tam kesinti.
#   ZAFİYET 2: readinessProbe YOK → Service, henüz hazır olmayan pod'lara trafik gönderir → 5xx.
#   (PDB de yok → gönüllü kesinti/drain tüm replica'ları birden alabilir.)
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "Bu lab kubectl + yerel bir cluster (kind/k3s) gerektirir." >&2; exit 1
fi
if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "Erişilebilir bir cluster yok. Önce: kind create cluster --name lab-e5" >&2; exit 1
fi

WORK="$(pwd)/env"
rm -rf "$WORK"; mkdir -p "$WORK"

cat > "$WORK/deployment.yaml" <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: chaos
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: chaos
  labels: { app: web }
spec:
  replicas: 3
  strategy:
    type: Recreate            # ZAFİYET 1: hepsini birden indirir → dağıtımda tam kesinti
  selector:
    matchLabels: { app: web }
  template:
    metadata:
      labels: { app: web }
    spec:
      containers:
        - name: web
          image: nginxinc/nginx-unprivileged:1.27-alpine
          ports:
            - containerPort: 8080
          # ZAFİYET 2: readinessProbe yok → hazır olmayan pod'a trafik gider
YAML

cat > "$WORK/service.yaml" <<'YAML'
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: chaos
spec:
  selector: { app: web }
  ports:
    - port: 80
      targetPort: 8080
YAML

kubectl apply -f "$WORK/deployment.yaml" >/dev/null
kubectl apply -f "$WORK/service.yaml" >/dev/null
kubectl -n chaos rollout status deploy/web --timeout=90s >/dev/null 2>&1 || true

echo "Kuruldu (namespace: chaos, servis: web, 3 replica)."
echo "Hipotez: '3 replica → dağıtım/restart sırasında kesintisiz.'"
echo "Deneyi yürüt (README'deki probe döngüsü + 'kubectl -n chaos rollout restart deploy/web')."
echo "Kesinti görürsen: deployment stratejisine ve pod hazırlık (readiness) kontrolüne bak."
