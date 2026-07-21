#!/usr/bin/env bash
# verify.sh — K03: state kilidi açıldı mı? Çıkış 0 = çözüldü.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

if [ ! -d env ]; then
  echo "  ❌ env/ yok — önce: bash setup.sh"
  echo "BAŞARISIZ ❌"; exit 1
fi

# 1) bayat kilit dosyası kalkmış mı
if [ -f env/.terraform.tfstate.lock.info ]; then
  no "kilit dosyası hâlâ duruyor (env/.terraform.tfstate.lock.info) — force-unlock et"
else
  ok "state kilidi kaldırılmış (kilit dosyası yok)"
fi

# 2) canlı kontrol: plan artık kilit hatası vermiyor mu
TF=""
command -v terraform >/dev/null 2>&1 && TF=terraform
[ -z "$TF" ] && command -v tofu >/dev/null 2>&1 && TF=tofu
if [ -n "$TF" ]; then
  out="$( ( cd env && "$TF" plan -input=false -lock-timeout=3s ) 2>&1 || true )"
  if echo "$out" | grep -qi 'acquiring the state lock'; then
    no "terraform plan hâlâ kilit hatası veriyor"
  else
    ok "terraform plan kilit hatası vermiyor (canlı)"
  fi
else
  printf '  ⚠️  terraform/tofu yok — canlı plan kontrolü atlandı\n'
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol) — teshis.md'de kilit ID'sini nereden okuduğunu yaz."; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata) — hints/hint-1.md'den başla."; exit 1; fi
