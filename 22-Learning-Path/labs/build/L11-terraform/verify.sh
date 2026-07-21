#!/usr/bin/env bash
# verify.sh — L11 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

find_file(){ for d in starter solution .; do [ -f "$d/$1" ] && { echo "$d/$1"; return 0; }; done; return 1; }
MT="$(find_file main.tf || true)"
PV="$(find_file providers.tf || true)"

# 1) main.tf en az bir resource
if [ -n "$MT" ]; then
  grep -qE '^\s*resource\s+"' "$MT" && ok "main.tf en az bir resource tanımlıyor" || no "main.tf'te 'resource' bloğu yok (template'i doldur)"
else
  no "main.tf bulunamadı (starter/main.tf.template'i kopyala ve doldur)"
fi

# 2) provider LocalStack'e yönlü
if [ -n "$PV" ]; then
  grep -qE '4566' "$PV" && ok "provider LocalStack endpoint'ine (4566) yönlendiriyor" || no "providers.tf LocalStack (4566) endpoint'i içermiyor"
else
  no "providers.tf bulunamadı"
fi

# 3) apply çalıştı mı (state) veya report'ta idempotency notu
if [ -f starter/terraform.tfstate ] || [ -f terraform.tfstate ]; then
  ok "terraform.tfstate var — apply çalıştırılmış"
else
  printf '  ⚠️  terraform.tfstate yok — apply çalıştırmadıysan LocalStack ile çalıştır\n'
fi

# 4) report.txt state açıklaması
if [ ! -f report.txt ]; then
  no "report.txt yok — state'in ne olduğunu ve niçin kilitlendiğini yaz"
else
  grep -qiE 'state' report.txt && ok "report.txt state'i açıklıyor" || no "report.txt'te state açıklaması yok"
  grep -qiE 'kilit|lock|paylaş|shared|dynamo|drift' report.txt && ok "report.txt kilit/paylaşım gereğini açıklıyor" || no "report.txt'te state'in niçin kilitlenmesi gerektiği yok"
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
