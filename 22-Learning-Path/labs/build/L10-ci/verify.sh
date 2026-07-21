#!/usr/bin/env bash
# verify.sh — L10 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

find_file(){ for d in starter solution .; do [ -f "$d/$1" ] && { echo "$d/$1"; return 0; }; done; return 1; }
PL="$(find_file pipeline.sh || true)"

# 1) pipeline.sh var ve üç adım + set -e içeriyor
if [ -n "$PL" ]; then
  grep -qE 'set -e' "$PL" && ok "pipeline set -e ile ilk hatada duruyor" || no "pipeline'da 'set -e' yok"
  n=0
  grep -qiE 'pytest|test' "$PL" && n=$((n+1))
  grep -qiE 'docker build|build' "$PL" && n=$((n+1))
  grep -qiE 'docker push|push' "$PL" && n=$((n+1))
  [ "$n" -ge 3 ] && ok "pipeline test+build+push adımlarını içeriyor" || no "pipeline'da test/build/push adımlarından biri eksik"
  if grep -qE ':latest' "$PL"; then
    no "pipeline ':latest' kullanıyor — SHA/semver ile etiketle"
  else
    grep -qE 'rev-parse|GITHUB_SHA|SHA|[0-9]+\.[0-9]+\.[0-9]+' "$PL" && ok "image SHA/semver ile etiketleniyor (:latest değil)" || no "sürümlü etiket (SHA/semver) görünmüyor"
  fi
else
  no "pipeline.sh bulunamadı (starter/pipeline.sh.template'i doldur)"
fi

# 2) report.txt kanıtı
if [ ! -f report.txt ]; then
  no "report.txt yok — kırık adım teşhisi + 'yeşil neyi doğrular' yaz"
else
  grep -qiE 'test|assert|aşama|stage|patla|fail' report.txt && ok "report.txt kırık adım teşhisini içeriyor" || no "report.txt'te kırık adım teşhisi yok"
  grep -qiE 'doğrula|garanti|kapsam|coverage|bug' report.txt && ok "report.txt 'yeşil neyi doğrular' sorusunu yanıtlıyor" || no "report.txt'te 'yeşil pipeline neyi doğrular' yok"
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
