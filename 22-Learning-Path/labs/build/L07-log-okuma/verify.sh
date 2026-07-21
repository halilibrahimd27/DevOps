#!/usr/bin/env bash
# verify.sh — L07 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

if [ ! -f report.txt ]; then
  echo "  ❌ report.txt yok — üç arızayı ve süzgeçlerini yaz."
  echo "BAŞARISIZ ❌"; exit 1
fi

# 1) journalctl kullanımı
grep -qi "journalctl" report.txt && ok "journalctl süzgeçleri kaydedilmiş" || no "report.txt journalctl komutları içermeli"

# 2) en az iki farklı süzgeç türü (-u ile birlikte -p/-e/--since/-b)
n=0
for f in "\-p" "\-e" "\-\-since" "\-b"; do grep -qE "journalctl.*$f|$f " report.txt && n=$((n+1)); done
[ "$n" -ge 2 ] && ok "en az iki farklı journalctl süzgeci kullanılmış ($n)" || no "farklı süzgeçler (-p/-e/--since/-b) yetersiz"

# 3) üç arıza
c=0
for k in "EnvironmentFile\|env\|ortam" "port\|bind\|8000\|çakış" "izin\|permission\|log dizin"; do
  grep -qiE "$k" report.txt && c=$((c+1))
done
[ "$c" -ge 3 ] && ok "üç arıza da açıklanmış" || no "üç arızadan $c tanesi bulundu (env / port / izin)"

# 4) sır sızıntısı + düzeltme
grep -qiE "sır|parola|secret|token|maskele|redact" report.txt && ok "sır sızıntısı ele alınmış" || no "sır sızıntısı açıklaması yok"

# 5) guvenli-log.txt açık sır içermemeli
if [ -f guvenli-log.txt ]; then
  if grep -qiE "parola=|password=|token=[A-Za-z0-9]{8,}" guvenli-log.txt; then
    no "guvenli-log.txt hâlâ açık parola/token içeriyor"
  else
    ok "guvenli-log.txt açık sır içermiyor"
  fi
else
  no "guvenli-log.txt yok — düzeltilmiş satırı koy"
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
