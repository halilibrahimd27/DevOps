#!/usr/bin/env bash
# verify.sh — L05 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

SCRIPT="./summarize.sh"
LOG="starter/sample.log"

if [ ! -f "$SCRIPT" ]; then
  echo "  ❌ $SCRIPT yok — starter/summarize.sh.template'i doldurup ./summarize.sh olarak kaydet."
  echo "BAŞARISIZ ❌"; exit 1
fi

# 1) set -euo pipefail
if grep -qE 'set -euo pipefail|set -o pipefail' "$SCRIPT"; then ok "sağlamlık: set -euo pipefail var"; else no "set -euo pipefail yok"; fi

# 2) argüman doğrulama: 0 argümanla çağır → sıfırdan farklı dönmeli
if bash "$SCRIPT" >/dev/null 2>&1; then no "argümansız çağrıda hata vermedi (arg doğrulama eksik)"; else ok "argümansız çağrıda doğru şekilde hata verdi"; fi

# 3) normal çalışma → out.txt üret, exit 0
rm -f out.txt
if bash "$SCRIPT" "$LOG" out.txt >/dev/null 2>&1 && [ -f out.txt ]; then
  ok "iki argümanla sıfır çıkış + out.txt üretti"
  grep -qi "toplam satır" out.txt && ok "rapor 'toplam satır' içeriyor" || no "rapor 'toplam satır' içermiyor"
  grep -qi "ERROR" out.txt && ok "rapor ERROR sayımı içeriyor" || no "rapor ERROR sayımı içermiyor"
else
  no "iki argümanla çalıştırma başarısız / out.txt üretmedi"
fi

# 4) shellcheck (varsa)
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -S warning "$SCRIPT" >/dev/null 2>&1; then ok "shellcheck temiz"; else no "shellcheck uyarı verdi (shellcheck $SCRIPT ile bak)"; fi
else
  printf '  ⚠️  shellcheck kurulu değil — bu kontrol atlandı\n'
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
