#!/usr/bin/env bash
# verify.sh — L02 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

if [ ! -f report.txt ]; then
  echo "  ❌ report.txt yok — görevi tamamlayıp kanıtı yaz."
  echo "BAŞARISIZ ❌"; exit 1
fi

# 1) ss kanıtı: 127.0.0.1:8080 LISTEN
if grep -q "127.0.0.1:8080" report.txt && grep -qi "LISTEN" report.txt; then
  ok "report.txt 127.0.0.1:8080 LISTEN satırı içeriyor"
else
  no "report.txt 127.0.0.1:8080 + LISTEN kanıtı içermiyor (ss -tlnp çıktısını yapıştır)"
fi

# 2) refused açıklaması
if grep -qi "refus" report.txt; then ok "refused açıklaması var"; else no "refused açıklaması yok"; fi

# 3) timeout açıklaması
if grep -qi "timeout\|zaman aşım\|asıl" report.txt; then ok "timeout açıklaması var"; else no "timeout açıklaması yok"; fi

# 4) ikisini ayırt eden bir cümle (RST / route / drop / anında kelimelerinden biri)
if grep -qiE "rst|route|drop|firewall|anında|hemen" report.txt; then
  ok "refused↔timeout ayrımı sebebe bağlanmış"
else
  no "ayrımı sebebe bağla (RST / route / drop / firewall / 'anında')"
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
