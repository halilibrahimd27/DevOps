#!/usr/bin/env bash
# verify.sh — L20 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

# 0) canlı kontrol: docker varsa restore GERÇEKTEN çalışmış olmalı (E4'ün tezi:
#    "test edilmemiş backup, backup değildir" — burada satır sayısıyla kanıtlanır).
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  cnt="$(docker compose -f starter/compose.yaml exec -T db_restore \
         psql -U postgres -d shop -tAc 'SELECT count(*) FROM orders;' 2>/dev/null | tr -d '[:space:]')"
  if [ "$cnt" = "1000" ]; then
    ok "db_restore'da orders = 1000 (restore doğrulandı, canlı)"
  else
    no "db_restore.orders = ${cnt:-'?'} (beklenen 1000) — yığını başlat (docker compose up -d) ve tam backup'ı temiz db'ye restore et; count ile doğrula"
  fi
else
  printf '  ⚠️  docker compose yok — canlı restore kontrolü atlandı (report.txt denetlenir; cluster/docker'"'"'da tam doğrula)\n'
fi

if [ ! -f report.txt ]; then
  echo "  ❌ report.txt yok — satır sayısı, RTO, RPO ve erişim/şifreleme kontrolünü yaz."
  echo "BAŞARISIZ ❌"; exit 1
fi

# 1) restore sonrası satır sayısı / bütünlük
grep -qE '\b1000\b' report.txt && ok "report.txt: restore sonrası satır sayısı (1000) yazılı" || no "restore sonrası satır sayısını (1000) ve kaynakla eşleştiğini yaz"

# 2) RTO
grep -qiE '\bRTO\b' report.txt && ok "report.txt: RTO (restore süresi) yazılı" || no "RTO'yu (ölçülen restore süresi) yaz"

# 3) RPO
grep -qiE '\bRPO\b' report.txt && ok "report.txt: RPO (veri kaybı penceresi) yazılı" || no "RPO'yu (veri kaybı penceresi + niçin) yaz"

# 4) erişim + at-rest şifreleme
if grep -qiE 'şifre|encrypt|at-rest|at rest' report.txt && grep -qiE 'erişim|access|kim' report.txt; then
  ok "report.txt: erişim + at-rest şifreleme kontrolü yazılı"
else
  no "backup'ın erişim + at-rest şifreleme kontrolünü yaz (kim erişir, şifreli mi)"
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
