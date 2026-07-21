#!/usr/bin/env bash
# verify.sh — L16 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

find_file(){ for d in starter solution .; do [ -f "$d/$1" ] && { echo "$d/$1"; return 0; }; done; return 1; }
PL="$(find_file pipeline.sh || true)"

if [ -n "$PL" ]; then
  if grep -qE 'trivy image' "$PL" && grep -qE 'exit-code 1|--exit-code 1|--exit-code=1' "$PL"; then
    ok "pipeline tarama kapısı içeriyor (trivy + exit-code 1)"
  else
    no "pipeline'da tarama KAPISI yok (trivy image --exit-code 1 --severity HIGH,CRITICAL)"
  fi
  grep -qE 'cosign sign' "$PL" && grep -qE 'cosign verify' "$PL" && ok "pipeline cosign sign + verify içeriyor" || no "pipeline'da cosign sign/verify eksik"
  grep -qiE 'sbom' "$PL" && ok "pipeline SBOM üretiyor" || printf '  ⚠️  pipeline'\''da SBOM adımı görünmüyor (report.txt'\''te açıklanmışsa yeterli)\n'
else
  no "pipeline.sh bulunamadı (starter/pipeline.sh.template'i doldur)"
fi

if [ ! -f report.txt ]; then
  no "report.txt yok — reddetme gerekçesi + SBOM açıklaması yaz"
else
  grep -qiE 'imzasız|taranmam|reddet|admission|kyverno|policy' report.txt && ok "report.txt reddetme gerekçesini içeriyor" || no "report.txt'te 'imzasız/taranmamış niçin reddedilir' yok"
  grep -qiE 'sbom|bileşen|cve|component' report.txt && ok "report.txt SBOM'u açıklıyor" || no "report.txt'te SBOM açıklaması yok"
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
