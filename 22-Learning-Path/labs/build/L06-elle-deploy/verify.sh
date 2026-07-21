#!/usr/bin/env bash
# verify.sh — L06 mekanik doğrulama. VM'in ÜSTÜNDE çalıştır. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

# 1) systemd durumu
if command -v systemctl >/dev/null 2>&1; then
  [ "$(systemctl is-enabled lab-app 2>/dev/null)" = "enabled" ] && ok "lab-app enabled (reboot'ta gelir)" || no "lab-app enabled değil (systemctl enable lab-app)"
  [ "$(systemctl is-active lab-app 2>/dev/null)" = "active" ] && ok "lab-app active" || no "lab-app active değil (systemctl status lab-app)"
else
  printf '  ⚠️  systemctl yok — bu VM lab için uygun mu? systemd kontrolleri atlandı\n'
fi

# 2) nginx üzerinden health (port 80)
if command -v curl >/dev/null 2>&1; then
  body="$(curl -s --max-time 5 http://127.0.0.1/health 2>/dev/null || true)"
  echo "$body" | grep -qi "ok" && ok "curl :80/health → ok (nginx proxy çalışıyor)" || no "http://127.0.0.1/health 'ok' dönmedi (nginx→app zinciri)"
fi

# 3) dinleme ayrımı: nginx 80 dışa, app yalnız localhost
if command -v ss >/dev/null 2>&1; then
  ss -tlnH 2>/dev/null | grep -qE '(:80 |0\.0\.0\.0:80|\*:80)' && ok "nginx 80'de dinliyor" || no "80 portunda dinleyen yok"
  if ss -tlnH 2>/dev/null | grep -q '127.0.0.1:8000'; then ok "uygulama yalnız 127.0.0.1:8000 (dışa kapalı)"; else no "app 127.0.0.1:8000 dinlemiyor (veya dışa açık)"; fi
fi

# 4) KURULUM.md
if [ -f KURULUM.md ] || [ -f ../KURULUM.md ]; then ok "KURULUM.md yazılmış"; else no "KURULUM.md yok — adımları belgele"; fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
