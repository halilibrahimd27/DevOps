#!/usr/bin/env bash
# verify.sh — L18 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

# 0) Prometheus ayakta mı (opsiyonel, bilgi amaçlı)
if command -v curl >/dev/null 2>&1 && curl -s --max-time 3 http://127.0.0.1:9090/-/healthy >/dev/null 2>&1; then
  ok "Prometheus :9090 sağlıklı yanıt veriyor"
else
  printf '  ⚠️  Prometheus :9090 yanıt vermiyor (durdurulmuş olabilir) — canlı kontrol atlandı\n'
fi

if [ ! -f report.txt ]; then
  echo "  ❌ report.txt yok — SLI sorgusunu, SLO'yu ve error budget hesabını yaz."
  echo "BAŞARISIZ ❌"; exit 1
fi

# 1) SLI sorgusu (başarı oranı)
if grep -qE 'http_requests_total' report.txt && grep -qiE 'rate\(|başar|success|oran' report.txt; then
  ok "başarı-oranı SLI sorgusu var"
else
  no "SLI sorgusu yetersiz (http_requests_total + rate/başarı oranı bekleniyor)"
fi

# 2) SLO hedefi (%99.x)
grep -qE '99(\.[0-9]+)?\s*%|%\s*99(\.[0-9]+)?' report.txt && ok "SLO hedefi (%99.x) yazılı" || no "bir SLO yüzdesi yaz (ör. %99.9)"

# 3) error budget: sayı + dakika
if grep -qiE 'budget|bütçe' report.txt && grep -qiE '[0-9]+(\.[0-9]+)?\s*(dk|dakika|min)' report.txt; then
  ok "error budget dakika olarak hesaplanmış"
else
  no "error budget'ı dakika/ay olarak hesapla (ör. ~43 dk)"
fi

# 4) tükenme/yanma sonucu
grep -qiE 'tüken|yak|yan|burn|dondur|yayın dur|freeze' report.txt && ok "bütçe tükendiğinde ne değişeceği yazılı" || no "bütçe tükenince ne değişir? (yayın durur mu) bir cümle yaz"

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
