#!/usr/bin/env python3
"""slo_app.py — Alerting lab: kendi trafiğini üreten minik servis.

L18'deki app'in aynısı; burada ERROR_RATE bilerek yüksek (compose'da %5) →
SLO hata-oranı alarmın gerçekten ateşlensin diye.

Metrik:  http_requests_total{status="200|500"}
"""
import os
import random
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

ERROR_RATE = float(os.environ.get("ERROR_RATE", "0.05"))   # 0.05 = %5
PORT = int(os.environ.get("PORT", "9200"))
RPS = int(os.environ.get("RPS", "50"))

_ok = 0
_err = 0
_lock = threading.Lock()


def _traffic():
    global _ok, _err
    while True:
        with _lock:
            for _ in range(RPS):
                if random.random() < ERROR_RATE:
                    _err += 1
                else:
                    _ok += 1
        time.sleep(1)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/metrics":
            self.send_response(404)
            self.end_headers()
            return
        with _lock:
            o, e = _ok, _err
        body = (
            "# HELP http_requests_total toplam islenen istek sayaci\n"
            "# TYPE http_requests_total counter\n"
            'http_requests_total{status="200"} %d\n'
            'http_requests_total{status="500"} %d\n' % (o, e)
        ).encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *a):
        pass


if __name__ == "__main__":
    threading.Thread(target=_traffic, daemon=True).start()
    print("slo_app :%d  ERROR_RATE=%.4f RPS=%d" % (PORT, ERROR_RATE, RPS))
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
