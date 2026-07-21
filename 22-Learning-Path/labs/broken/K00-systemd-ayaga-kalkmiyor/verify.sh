#!/usr/bin/env bash
# verify.sh — K00: servis düzeltildi mi? Çıkış 0 = çözüldü.
set -u
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

if ! command -v systemctl >/dev/null 2>&1; then
  echo "  ❌ systemctl yok — bu lab bir systemd VM'de çalışır."
  echo "BAŞARISIZ ❌"; exit 1
fi

# 1) servis aktif
if [ "$(systemctl is-active k00-app 2>/dev/null)" = "active" ]; then
  ok "k00-app active"
else
  no "k00-app hâlâ active değil (systemctl status k00-app)"
fi

# 2) health cevabı
if command -v curl >/dev/null 2>&1; then
  body="$(curl -s --max-time 5 http://127.0.0.1:8080/health 2>/dev/null || true)"
  echo "$body" | grep -qi "ok" && ok "http://127.0.0.1:8080/health → ok" || no "health 'ok' dönmüyor"
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol) — kök sebebi ve bulduğun komutu bir cümleyle yaz."; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata) — hints/hint-1.md'den başla."; exit 1; fi
