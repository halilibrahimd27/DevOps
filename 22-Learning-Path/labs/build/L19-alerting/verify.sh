#!/usr/bin/env bash
# verify.sh — L19 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

# 0) canlı kontrol (opsiyonel): Alertmanager'da active alarm var mı
if command -v curl >/dev/null 2>&1 && curl -s --max-time 3 http://127.0.0.1:9093/-/healthy >/dev/null 2>&1; then
  if curl -s --max-time 3 http://127.0.0.1:9093/api/v2/alerts 2>/dev/null | grep -qi 'labelname\|alertname\|active\|firing\|\[\]'; then
    ok "Alertmanager :9093 yanıt veriyor (alarm durumu sorgulanabilir)"
  fi
else
  printf '  ⚠️  Alertmanager :9093 yanıt vermiyor (durdurulmuş olabilir) — canlı kontrol atlandı\n'
fi

# 1) alarm kuralı
if [ -f starter/alerts.yml ] && grep -q 'http_requests_total' starter/alerts.yml && grep -qiE 'alert\s*:' starter/alerts.yml; then
  ok "starter/alerts.yml: http_requests_total üzerine bir alarm kuralı var"
else
  no "starter/alerts.yml eksik/yetersiz (alert: + http_requests_total bekleniyor)"
fi

# 2) alertmanager yapılandırması
if [ -f starter/alertmanager.yml ] && grep -qiE '^\s*route\s*:' starter/alertmanager.yml && grep -qiE 'receiver' starter/alertmanager.yml; then
  ok "starter/alertmanager.yml: route + receiver var"
else
  no "starter/alertmanager.yml eksik (route + receiver bekleniyor)"
fi

if [ ! -f report.txt ]; then
  echo "  ❌ report.txt yok — alarm kanıtını, sınıflandırmayı ve eskalasyonu yaz."
  echo "BAŞARISIZ ❌"; exit 1
fi

# 3) alarm ateşleme kanıtı
grep -qiE 'firing|pending|active|ateş|alarm' report.txt && ok "report.txt: alarm ateşleme kanıtı var" || no "alarmın ateşlediğini (FIRING/active) report.txt'e kanıtla"

# 4) page/ticket/log sınıflandırması
if grep -qiE 'page' report.txt && grep -qiE 'ticket' report.txt && grep -qiE 'log' report.txt; then
  ok "report.txt: page/ticket/log sınıflandırması var"
else
  no "alarmları page/ticket/log diye sınıflandır (biri gürültü örneği)"
fi

# 5) eskalasyon
grep -qiE 'eskalasyon|escalat|yüksel|ack|15 ?dk|15 ?dakika' report.txt && ok "report.txt: eskalasyon kuralı yazılı" || no "çözülmezse kime/ne zaman yükselir (eskalasyon) yaz"

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
