#!/usr/bin/env bash
# setup-playground.sh — L01 için bilerek dağınık bir ortam kurar.
# İzinler yanlış, bir process arka planda çalışıyor. Sen düzelteceksin.
set -euo pipefail

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PG="$LAB_DIR/playground"

rm -rf "$PG"
mkdir -p "$PG/config" "$PG/data" "$PG/logs"
echo "app_name=lab01" > "$PG/config/app.conf"
echo "gizli bir sey" > "$PG/gizli.txt"
echo "2026-01-01 boot ok" > "$PG/logs/app.log"

# Bilerek geniş izinler (777 dizin, 666 dosya, 666 gizli.txt)
chmod -R 0777 "$PG"
chmod 0666 "$PG/gizli.txt"

# Arka planda bulunacak bir process başlat (argv[0] = l01-daemon)
if command -v setsid >/dev/null 2>&1; then
  setsid bash -c 'exec -a l01-daemon sleep 100000' >/dev/null 2>&1 &
else
  bash -c 'exec -a l01-daemon sleep 100000' >/dev/null 2>&1 &
fi
echo "$!" > "$PG/.daemon.pid"

cat <<EOF
Playground kuruldu: $PG
  - İzinler bilerek yanlış (dizinler 777, gizli.txt 666).
  - Arka planda 'l01-daemon' çalışıyor (PID $(cat "$PG/.daemon.pid")).
Görevin: process'i incele, izinleri 750/640'a çek, report.txt yaz.
Bitirdikten sonra:  bash verify.sh
EOF
