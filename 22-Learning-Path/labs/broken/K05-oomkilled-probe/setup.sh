#!/usr/bin/env bash
# setup.sh — K05 ortamını BİLEREK BOZUK kurar (iki katman: düşük memory limit + yanlış probe portu).
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

# App: başlangıçta ~40MB tampon ayırır, sonra 8080'de /health -> ok verir.
# BOZUK 1: limit 32Mi → 40MB ayrılınca OOMKilled.
# BOZUK 2: readinessProbe port 9999 (yanlış) → Pod hiç Ready olmaz.
cat > "$WORK/deployment.yaml" <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: k05
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: k05
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
          image: python:3.12-slim
          command: ["python", "-c"]
          args:
            - |
              buf = bytearray(40 * 1024 * 1024)   # ~40MB gerçek uygulama tamponu
              from http.server import BaseHTTPRequestHandler, HTTPServer
              class H(BaseHTTPRequestHandler):
                  def do_GET(self):
                      self.send_response(200); self.end_headers(); self.wfile.write(b"ok")
                  def log_message(self, *a): pass
              print("listening on 8080", flush=True)
              HTTPServer(("0.0.0.0", 8080), H).serve_forever()
          ports:
            - containerPort: 8080
          resources:
            requests: { cpu: "50m", memory: "16Mi" }
            limits:   { cpu: "200m", memory: "32Mi" }   # BOZUK 1: çok düşük → OOMKilled
          readinessProbe:
            httpGet: { path: /health, port: 9999 }      # BOZUK 2: yanlış port
            initialDelaySeconds: 3
            periodSeconds: 5
YAML

cat > "$WORK/service.yaml" <<'YAML'
apiVersion: v1
kind: Service
metadata:
  name: app-svc
  namespace: k05
spec:
  selector: { app: app }
  ports:
    - port: 80
      targetPort: 8080
YAML

kubectl apply -f "$WORK/deployment.yaml" >/dev/null
kubectl apply -f "$WORK/service.yaml" >/dev/null

echo "Kuruldu (namespace: k05)."
echo "Belirti 1: Pod CrashLoopBackOff (RESTARTS artıyor)."
echo "Belirti 2: restart durdurulsa da Pod Ready olmaz (Service trafik göndermez)."
echo "Teşhise başla: kubectl -n k05 describe pod  → Last State / Reason"
