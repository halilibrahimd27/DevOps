#!/usr/bin/env bash
# verify.sh — L03 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

# 0) Sertifika üretilmiş mi (starter çalışmış mı)
if [ -f tls/lab.crt ]; then ok "yerel sertifika üretilmiş (tls/lab.crt)"; else no "tls/lab.crt yok — starter/gen-cert-and-serve.sh çalıştır"; fi

if [ ! -f report.txt ]; then
  echo "  ❌ report.txt yok — kanıtı yaz."
  echo "BAŞARISIZ ❌"; exit 1
fi

# 1) Cert son geçerlilik tarihi
if grep -qiE "notAfter|geçerlilik|enddate" report.txt; then ok "cert son geçerlilik tarihi kaydedilmiş"; else no "cert notAfter/son geçerlilik tarihi yok"; fi

# 2) Cert subject/CN
if grep -qiE "subject|CN=|lab.example" report.txt; then ok "cert subject/CN kaydedilmiş"; else no "cert subject/CN yok"; fi

# 3) DNS katmanı
if grep -qiE "NXDOMAIN|resolve|çöz" report.txt; then ok "DNS çözme hatası açıklanmış"; else no "DNS (NXDOMAIN/resolve) katmanı yok"; fi

# 4) TLS katmanı ayrı sebep
if grep -qiE "certificate verify|el sıkış|handshake|kimlik|TLS" report.txt; then ok "TLS doğrulama hatası ayrı sebep olarak açıklanmış"; else no "TLS katmanı ayrı açıklanmamış"; fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
