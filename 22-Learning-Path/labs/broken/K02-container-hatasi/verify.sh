#!/usr/bin/env bash
# verify.sh — K02: port eşlemesi düzeldi mi? Çıkış 0 = çözüldü.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

CF="env/compose.yaml"
if [ ! -f "$CF" ]; then
  echo "  ❌ env/compose.yaml yok — önce: bash setup.sh"
  echo "BAŞARISIZ ❌"; exit 1
fi

# 1) eşleme container tarafı 5000'e düzeltilmiş mi
if grep -qE '"8080:5000"' "$CF"; then
  ok "port eşlemesi 8080:5000 (container portu app ile uyumlu)"
elif grep -qE '"8080:80"' "$CF"; then
  no "eşleme hâlâ 8080:80 — container tarafı yanlış"
else
  printf '  ⚠️  beklenmedik ports satırı — app 5000 dinliyor, host:5000 eşle\n'
fi

# 2) canlı kontrol (docker varsa)
if command -v docker >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
  body="$(curl -s --max-time 5 http://127.0.0.1:8080/health 2>/dev/null || true)"
  if [ "$body" = "ok" ]; then ok "8080/health → ok (canlı)"; else no "8080/health 'ok' değil (gelen: '${body:-boş}') — compose up ettin mi?"; fi
else
  printf '  ⚠️  docker/curl yok — canlı kontrol atlandı\n'
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol) — teshis.md'de üç daraltma komutunu yaz."; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata) — hints/hint-1.md'den başla."; exit 1; fi
