#!/usr/bin/env bash
# setup.sh — K02 ortamını BİLEREK BOZUK kurar. Kök sebep gizlidir.
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "Bu lab docker + docker compose gerektirir." >&2
  exit 1
fi

WORK="$(pwd)/env"
rm -rf "$WORK"; mkdir -p "$WORK"

# Uygulama: 5000 portunu dinler, /health -> ok
cat > "$WORK/app.py" <<'PY'
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
PORT = int(os.environ.get("APP_PORT", "5000"))   # uygulama 5000 dinler
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200); self.end_headers(); self.wfile.write(b"ok")
        else:
            self.send_response(404); self.end_headers()
    def log_message(self, *a): pass
print(f"listening on 0.0.0.0:{PORT}", flush=True)
HTTPServer(("0.0.0.0", PORT), H).serve_forever()
PY

cat > "$WORK/Dockerfile" <<'DOCK'
FROM python:3.12-slim
WORKDIR /app
COPY app.py .
CMD ["python", "app.py"]
DOCK

# BOZUK: host 8080 -> container 80 eşleniyor. Ama app 5000 dinliyor.
# Yani 80'de kimse yok → 8080 boş yanıt verir. (Kök sebep bu eşleme.)
cat > "$WORK/compose.yaml" <<'COMPOSE'
services:
  app:
    build: .
    ports:
      - "8080:80"
COMPOSE

echo "Kuruldu → $WORK"
if docker compose version >/dev/null 2>&1; then
  ( cd "$WORK" && docker compose up -d --build ) || true
  echo "Belirti: curl http://127.0.0.1:8080/health boş/kapalı yanıt verir."
  echo "Teşhise başla: docker compose ps  /  docker compose logs  /  compose port eşlemesi."
else
  echo "docker compose bulunamadı — 'env/' hazır, kendi ortamında incele."
fi
