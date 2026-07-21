#!/usr/bin/env bash
# gen-cert-and-serve.sh — kendinden imzalı sertifika üretir ve yerel HTTPS sunar.
# İnternet gerekmez; her şey 127.0.0.1 / lab.example (RFC 2606 sahte isim) üzerinde.
set -euo pipefail
WORK="$(cd "$(dirname "$0")/.." && pwd)/tls"
mkdir -p "$WORK"
CERT="$WORK/lab.crt"
KEY="$WORK/lab.key"

if [ ! -f "$CERT" ]; then
  openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$KEY" -out "$CERT" -days 30 \
    -subj "/CN=lab.example" \
    -addext "subjectAltName=DNS:lab.example" >/dev/null 2>&1
  echo "Sertifika üretildi: $CERT (CN=lab.example, 30 gün geçerli)"
fi

echo "HTTPS servisi başlıyor: https://127.0.0.1:8443  (Ctrl-C ile durdur)"
echo "Test:  curl --resolve lab.example:8443:127.0.0.1 -kIs https://lab.example:8443/"
exec openssl s_server -accept 8443 -cert "$CERT" -key "$KEY" -www -quiet
