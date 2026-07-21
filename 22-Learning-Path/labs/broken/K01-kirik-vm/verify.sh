#!/usr/bin/env bash
# verify.sh — K01: port çakışması çözüldü mü? Çıkış 0 = çözüldü.
set -u
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

if ! command -v systemctl >/dev/null 2>&1; then
  echo "  ❌ systemctl yok — bu lab bir systemd VM'de çalışır."
  echo "BAŞARISIZ ❌"; exit 1
fi

# 1) uygulama aktif
[ "$(systemctl is-active k01-app 2>/dev/null)" = "active" ] && ok "k01-app active" || no "k01-app active değil"

# 2) health = ok (decoy değil, uygulama cevap veriyor)
if command -v curl >/dev/null 2>&1; then
  body="$(curl -s --max-time 5 http://127.0.0.1:8080/health 2>/dev/null || true)"
  if [ "$body" = "ok" ]; then ok "8080/health → ok (decoy değil, uygulama)"; else no "8080/health 'ok' değil (gelen: '${body:-boş}')"; fi
fi

# 3) decoy artık portu tutmuyor
if [ "$(systemctl is-active k01-decoy 2>/dev/null)" = "active" ]; then
  no "k01-decoy hâlâ çalışıyor — 8080 çakışması sürüyor"
else
  ok "k01-decoy durduruldu (port serbest)"
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol) — teshis.md'de üç daraltma komutunu yaz."; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata) — hints/hint-1.md'den başla."; exit 1; fi
