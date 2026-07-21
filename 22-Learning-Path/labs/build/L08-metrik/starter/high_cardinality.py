#!/usr/bin/env python3
"""high_cardinality.py — Prometheus text-format exporter.
CARD ortam değişkeni kadar FARKLI user_id etiketiyle seri üretir.
CARD'ı 10 -> 1000 -> 100000 yapıp seri sayısının patlamasını gör.

Çalıştır:  CARD=1000 python3 high_cardinality.py   # :9110 dinler
Prometheus'ta:  count({__name__="lab_requests_total"})
"""
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

CARD = int(os.environ.get("CARD", "10"))
PORT = int(os.environ.get("PORT", "9110"))


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/metrics":
            self.send_response(404); self.end_headers(); return
        lines = ["# HELP lab_requests_total ornek sayac",
                 "# TYPE lab_requests_total counter"]
        # ❌ ANTI-PATTERN: user_id etiketi sinirsiz cardinality yaratir
        for i in range(CARD):
            lines.append('lab_requests_total{user_id="u%d"} 1' % i)
        body = ("\n".join(lines) + "\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *a):
        pass


if __name__ == "__main__":
    print("cardinality exporter :%d  (CARD=%d seri)" % (PORT, CARD))
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
