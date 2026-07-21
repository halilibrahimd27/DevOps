#!/usr/bin/env bash
# setup.sh — K00 ortamını BİLEREK BOZUK kurar.
# Kök sebep gizlidir; README yalnız belirtiyi verir. sudo ile çalıştır.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "sudo ile çalıştır:  sudo bash setup.sh" >&2
  exit 1
fi
if ! command -v systemctl >/dev/null 2>&1; then
  echo "Bu lab systemd gerektirir (bir Linux VM kullan)." >&2
  exit 1
fi

# Servis kullanıcısı
id k00svc >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin k00svc

# Uygulama (basit stdlib http servisi, APP_PORT'u ortamdan okur)
install -d -o k00svc -g k00svc /opt/k00-app
cat > /opt/k00-app/app.py <<'PY'
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
PORT = int(os.environ.get("APP_PORT", "8080"))
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200 if self.path == "/health" else 404)
        self.end_headers()
        self.wfile.write(b"ok" if self.path == "/health" else b"nf")
    def log_message(self, *a): pass
HTTPServer(("127.0.0.1", PORT), H).serve_forever()
PY
chown k00svc:k00svc /opt/k00-app/app.py

# systemd unit — DİKKAT: EnvironmentFile var olmayan bir dosyaya işaret ediyor.
# (Bu kasıtlı bozukluktur; '-' öneki yok, yani zorunlu → unit başlamaz.)
cat > /etc/systemd/system/k00-app.service <<'UNIT'
[Unit]
Description=k00-app (kirik lab)
After=network.target

[Service]
User=k00svc
EnvironmentFile=/etc/k00-app/app.env
ExecStart=/usr/bin/python3 /opt/k00-app/app.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

# /etc/k00-app/app.env BİLEREK oluşturulmadı.

systemctl daemon-reload
systemctl enable k00-app >/dev/null 2>&1 || true
systemctl start k00-app || true

echo "Kuruldu. Belirti: k00-app ayağa kalkmıyor."
echo "Teşhise başla:  systemctl status k00-app   /   journalctl -u k00-app -e"
