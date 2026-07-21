#!/usr/bin/env python3
"""lab-app — stdlib HTTP servisi. Bağımlılık yok, elle deploy içindir.
Yalnız 127.0.0.1'de dinler; dış dünyaya nginx bakar.

Ortam değişkenleri (systemd EnvironmentFile'dan gelir):
  APP_HOST (varsayılan 127.0.0.1)
  APP_PORT (varsayılan 8000)
Uç noktalar:
  /health -> 200 "ok"
  /db     -> pg_isready çıktısı (PostgreSQL erişilebilir mi)
"""
import os
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer

HOST = os.environ.get("APP_HOST", "127.0.0.1")
PORT = int(os.environ.get("APP_PORT", "8000"))


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body):
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(body.encode())

    def do_GET(self):
        if self.path == "/health":
            self._send(200, "ok")
        elif self.path == "/db":
            try:
                out = subprocess.run(["pg_isready"], capture_output=True, text=True, timeout=5)
                self._send(200 if out.returncode == 0 else 503, out.stdout or out.stderr)
            except FileNotFoundError:
                self._send(503, "pg_isready bulunamadi")
        else:
            self._send(404, "not found")

    def log_message(self, fmt, *args):
        # journald zaten zaman damgası ekler; stderr'e sade yaz
        print("%s - %s" % (self.address_string(), fmt % args))


if __name__ == "__main__":
    print("lab-app dinliyor: %s:%d" % (HOST, PORT))
    HTTPServer((HOST, PORT), Handler).serve_forever()
