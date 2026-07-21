#!/usr/bin/env python3
"""L09 örnek uygulaması — A6'daki app'in container'a taşınmış hâli.
/health DB'ye bağlanmayı dener; bağlanırsa {"db": true} döner.
DB bilgisi ENV'den gelir — image'a gömülü değil."""
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

import psycopg2  # noqa: E402  (requirements.txt ile kurulur)

DB = dict(
    host=os.environ.get("DB_HOST", "db"),
    dbname=os.environ.get("DB_NAME", "app"),
    user=os.environ.get("DB_USER", "app"),
    password=os.environ.get("DB_PASSWORD", ""),
)
PORT = int(os.environ.get("APP_PORT", "8000"))


def db_ok() -> bool:
    try:
        conn = psycopg2.connect(connect_timeout=3, **DB)
        conn.close()
        return True
    except Exception:
        return False


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            ok = db_ok()
            self.send_response(200 if ok else 503)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"db": ok}).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, *a):  # sessiz
        pass


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
