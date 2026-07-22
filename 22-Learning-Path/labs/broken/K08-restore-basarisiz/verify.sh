#!/usr/bin/env bash
# verify.sh — K08: db_restore'a tam veri (1000) geri geldi mi + teşhis yazıldı mı?
#   Çıkış 0 = çözüldü. docker yoksa mekanik yedek kontrole düşer.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

have_docker=1
command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1 || have_docker=0

if [ "$have_docker" = 0 ] || [ ! -f env/compose.yaml ]; then
  echo "  ⚠️  docker/compose ya da ortam yok — mekanik yedek kontrol."
  # monthly düzeltilmiş mi (okunabilir) — erişim arızasını çözdün mü?
  if [ -f env/backups/monthly.sql ]; then
    if [ -r env/backups/monthly.sql ]; then ok "monthly.sql okunabilir (erişim arızası giderilmiş)"; \
    else no "monthly.sql hâlâ okunamıyor — chmod u+r ile erişimi aç"; fi
  else
    echo "  ⚠️  env/backups yok — önce bash setup.sh."
  fi
  [ -f teshis.md ] && grep -qiE 'schema-only|schema_only|şema|veri yok|izin|permission|kesik|bozuk' teshis.md \
    && ok "teshis.md var (backup tanıları)" || no "teshis.md yok/eksik — üç backup'ın tanısını yaz"
  echo "----------------------------------------"
  [ "$FAIL" -eq 0 ] && { echo "GEÇTİ ✅ (mekanik) — cluster/docker'da 1000 satırı tam doğrula."; exit 0; } \
                    || { echo "BAŞARISIZ ❌  ($FAIL hata) — hints/hint-1.md'den başla."; exit 1; }
fi

# canlı doğrulama: db_restore'da orders 1000 mi?
cnt="$(docker compose -f env/compose.yaml exec -T db_restore \
        psql -U postgres -d shop -tAc 'SELECT count(*) FROM orders;' 2>/dev/null | tr -d '[:space:]')"
if [ "${cnt:-x}" = "1000" ]; then
  ok "db_restore.orders = 1000 (tam veri geri geldi)"
else
  no "db_restore.orders = ${cnt:-'?'} (beklenen 1000) — tam backup'ı restore et, count ile doğrula"
fi

# teşhis belgesi
if [ -f teshis.md ] && grep -qiE 'schema-only|schema_only|şema|veri yok|izin|permission|kesik|bozuk' teshis.md; then
  ok "teshis.md var (üç backup'ın tanısı)"
else
  no "teshis.md yok/eksik — nightly/weekly/monthly tanılarını + 'count ile doğrula' dersini yaz"
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol) — RTO'yu ölçtüysen teshis.md'ye ekle."; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata) — hints/hint-1.md'den başla."; exit 1; fi
