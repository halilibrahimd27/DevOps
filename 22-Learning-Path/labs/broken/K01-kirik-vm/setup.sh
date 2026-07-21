#!/usr/bin/env bash
# setup.sh — K01 ortamını BİLEREK BOZUK kurar.
# Kök sebep gizlidir. sudo ile çalıştır.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "sudo ile çalıştır:  sudo bash setup.sh" >&2
  exit 1
fi
if ! command -v systemctl >/dev/null 2>&1; then
  echo "Bu lab systemd gerektirir (bir Linux VM kullan)." >&2
  exit 1
fi

id k01svc >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin k01svc

# Uygulama: /health -> ok  (127.0.0.1:8080)
install -d -o k01svc -g k01svc /opt/k01-app
cat > /opt/k01-app/app.py <<'PY'
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
PORT = int(os.environ.get("APP_PORT", "8080"))
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200); self.end_headers(); self.wfile.write(b"ok")
        else:
            self.send_response(404); self.end_headers(); self.wfile.write(b"nf")
    def log_message(self, *a): pass
HTTPServer(("127.0.0.1", PORT), H).serve_forever()
PY
chown k01svc:k01svc /opt/k01-app/app.py

# DECOY: başka bir servis 8080'i BİLEREK önce kapıyor (kök sebep bu çakışmadır).
cat > /etc/systemd/system/k01-decoy.service <<'UNIT'
[Unit]
Description=k01-decoy (8080'i tutan gereksiz servis)
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 127.0.0.1
Restart=always

[Install]
WantedBy=multi-user.target
UNIT

# Asıl uygulama — aynı portu (8080) ister → çakışma
cat > /etc/systemd/system/k01-app.service <<'UNIT'
[Unit]
Description=k01-app (kirik lab)
After=network.target k01-decoy.service

[Service]
User=k01svc
Environment=APP_PORT=8080
ExecStart=/usr/bin/python3 /opt/k01-app/app.py
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable k01-decoy k01-app >/dev/null 2>&1 || true
systemctl start k01-decoy || true
sleep 1
systemctl start k01-app || true

echo "Kuruldu. Belirti: k01-app 8080'de beklenen 'ok'u vermiyor."
echo "Teşhise başla:  systemctl status k01-app  /  journalctl -u k01-app -p err  /  ss -tlnp"
