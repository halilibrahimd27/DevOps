#!/usr/bin/env bash
# verify.sh — L09 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

# Öğrencinin Dockerfile/compose'u starter/ (kendi çalışması) veya solution/'da olabilir.
find_file(){ for d in starter solution .; do [ -f "$d/$1" ] && { echo "$d/$1"; return 0; }; done; return 1; }

DF="$(find_file Dockerfile || true)"
CF="$(find_file compose.yaml || true)"

# 1) multi-stage Dockerfile
if [ -n "$DF" ]; then
  stages=$(grep -cE '^[[:space:]]*FROM ' "$DF" || true)
  if [ "$stages" -ge 2 ] && grep -qE 'COPY[[:space:]]+--from=' "$DF"; then
    ok "Dockerfile multi-stage ($stages FROM + COPY --from=)"
  else
    no "Dockerfile multi-stage değil (>=2 FROM ve bir COPY --from= gerekli)"
  fi
  grep -qE '^[[:space:]]*USER ' "$DF" && ok "Dockerfile non-root (USER var)" || no "Dockerfile'da USER yok (root çalışıyor)"
else
  no "Dockerfile bulunamadı (starter/ içinde doldur)"
fi

# 2) compose: app + db, :latest yok
if [ -n "$CF" ]; then
  grep -qE '^\s*app:' "$CF" && grep -qE '^\s*db:' "$CF" && ok "compose app + db servisi var" || no "compose'da app ve db servisi eksik"
  if grep -qE ':latest' "$CF"; then no "compose'da :latest var (sürüm pinle)"; else ok "compose'da :latest yok"; fi
else
  no "compose.yaml bulunamadı"
fi

# 3) report.txt kanıtı
if [ ! -f report.txt ]; then
  no "report.txt yok — naive/slim boyut ve cache açıklamasını yaz"
else
  c=$(grep -cE '[0-9]+(\.[0-9]+)?\s*(MB|GB|MiB|GiB)' report.txt || true)
  [ "$c" -ge 2 ] && ok "report.txt en az iki image boyutu (naive/slim) içeriyor" || no "report.txt'te iki boyut (MB/GB) belirt"
  grep -qiE 'cache|katman|layer' report.txt && ok "report.txt katman cache'i açıklıyor" || no "report.txt'te katman cache açıklaması yok"
fi

# 4) canlı kontrol (opsiyonel)
if command -v curl >/dev/null 2>&1 && curl -s --max-time 3 http://127.0.0.1:8000/health >/dev/null 2>&1; then
  ok "http://127.0.0.1:8000/health canlı yanıt veriyor"
else
  printf '  ⚠️  :8000/health yanıt vermiyor (compose durmuş olabilir) — canlı kontrol atlandı\n'
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
