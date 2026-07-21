#!/usr/bin/env bash
# serve-localhost.sh — HTTP servisini YALNIZ 127.0.0.1:8080'de dinletir.
# Dış arayüzde (0.0.0.0) değil — bilerek. ss ile farkı gör.
set -euo pipefail
PORT="${1:-8080}"
echo "127.0.0.1:$PORT dinleniyor (yalnız localhost). Durdurmak için Ctrl-C."
echo "Başka bir terminalde:  ss -tlnp | grep :$PORT"
exec python3 -m http.server "$PORT" --bind 127.0.0.1
