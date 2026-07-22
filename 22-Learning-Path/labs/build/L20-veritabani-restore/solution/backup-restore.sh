#!/usr/bin/env bash
# solution/backup-restore.sh — L20 referans akış. ÖNCE KENDİN DENE.
# starter/ dizininden çalıştır: bash ../solution/backup-restore.sh
set -euo pipefail

echo "== 1) kaynağı doğrula (beklenen: 1000) =="
docker compose exec -T db psql -U postgres -d shop -tAc 'SELECT count(*) FROM orders;'

echo "== 2) backup al (veri dahil — --schema-only DEĞİL) =="
docker compose exec -T db pg_dump -U postgres -d shop > backup.sql
echo "backup.sql boyutu: $(wc -c < backup.sql) bayt"

echo "== 3) restore et (temiz hedef) + süreyi ölç (bu süre = RTO) =="
time docker compose exec -T db_restore psql -U postgres -d shop < backup.sql

echo "== 4) bütünlüğü kanıtla (beklenen: 1000) =="
docker compose exec -T db_restore psql -U postgres -d shop -tAc 'SELECT count(*) FROM orders;'

echo "Bitti. report.txt'e satır sayısını, RTO'yu, RPO'yu ve erişim/şifreleme kontrolünü yaz."
