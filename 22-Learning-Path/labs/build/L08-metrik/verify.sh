#!/usr/bin/env bash
# verify.sh — L08 mekanik doğrulama. Çıkış 0 = geçti.
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
  echo "  ❌ report.txt yok — PromQL sorgularını ve cardinality gözlemini yaz."
  echo "BAŞARISIZ ❌"; exit 1
fi

# 1) en az iki altın sinyal sorgusu
n=0
for q in "node_cpu_seconds_total" "node_network_receive_bytes_total" "node_memory" "rate("; do
  grep -q "$q" report.txt && n=$((n+1))
done
[ "$n" -ge 2 ] && ok "en az iki altın sinyal PromQL sorgusu var ($n işaret)" || no "iki altın sinyal sorgusu yetersiz (node_cpu/network/memory/rate)"

# 2) cardinality gözlemi + sayı
grep -qiE "cardinal|seri|series" report.txt && ok "cardinality gözlemi kaydedilmiş" || no "cardinality açıklaması yok"
grep -qE "[0-9]{3,}" report.txt && ok "seri sayısı (rakam) belirtilmiş" || no "seri patlamasını sayıyla göster (ör. 100000)"

# 3) sebep: sınırsız etiket
grep -qiE "user_id|sınırsız|unbounded|kimlik" report.txt && ok "sebep (sınırsız etiket) açıklanmış" || no "cardinality sebebini yaz (sınırsız değerli etiket)"

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
