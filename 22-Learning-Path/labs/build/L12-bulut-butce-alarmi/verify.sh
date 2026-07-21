#!/usr/bin/env bash
# verify.sh — L12 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

find_file(){ for d in starter solution .; do [ -f "$d/$1" ] && { echo "$d/$1"; return 0; }; done; return 1; }
BT="$(find_file budget.tf || true)"

# 1) budget.tf: budget + threshold + bildirim kanalı
if [ -n "$BT" ]; then
  grep -qE 'aws_budgets_budget' "$BT" && ok "budget.tf bir aws_budgets_budget tanımlıyor" || no "budget.tf'te aws_budgets_budget yok (template'i doldur)"
  grep -qE 'threshold' "$BT" && ok "budget.tf bir eşik (threshold) içeriyor" || no "budget.tf'te threshold yok"
  grep -qE 'subscriber_email_addresses|subscriber_sns' "$BT" && ok "budget.tf bir bildirim kanalı içeriyor" || no "budget.tf'te bildirim kanalı (email/SNS) yok"
else
  no "budget.tf bulunamadı — ADIM 1: bütçe alarmı"
fi

# 2) report.txt: free tier + kavramlar + alarm testi
if [ ! -f report.txt ]; then
  no "report.txt yok — free tier listesi + VPC/IAM/compute + alarm testi yaz"
else
  grep -qiE 'free tier|ücretsiz|ücretli|free-tier' report.txt && ok "report.txt free/ücretli servisleri listeliyor" || no "report.txt'te free tier listesi yok"
  n=0
  grep -qiE '\bVPC\b' report.txt && n=$((n+1))
  grep -qiE '\bIAM\b' report.txt && n=$((n+1))
  grep -qiE 'compute|EC2|hesaplama' report.txt && n=$((n+1))
  [ "$n" -ge 3 ] && ok "report.txt VPC/IAM/compute'u tanımlıyor" || no "report.txt'te VPC, IAM ve compute tanımlarından biri eksik"
  grep -qiE 'alarm|bütçe|budget|tetik|trigger|bildirim' report.txt && ok "report.txt alarm testini/kanıtını açıklıyor" || no "report.txt'te alarm testi açıklaması yok"
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
