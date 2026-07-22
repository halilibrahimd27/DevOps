#!/usr/bin/env bash
# setup.sh — K08 ortamını BİLEREK BOZUK üç backup'la kurar.
#   backups/nightly.sql  → pg_dump --schema-only (şema var, VERİ YOK) → restore 0 satır (sessiz)
#   backups/weekly.sql   → tam dump'ın sonu kesilmiş (COPY sonlanmamış) → restore HATA verir (gürültülü)
#   backups/monthly.sql  → gerçek tam dump (1000 satır) AMA izin 000 → okunamaz (erişim)
# Tek gerçekten kullanılabilir backup: monthly (izni düzeltilince).
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "Bu lab docker gerektirir." >&2; exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "Bu lab 'docker compose' (v2) gerektirir." >&2; exit 1
fi

WORK="$(pwd)/env"
rm -rf "$WORK"; mkdir -p "$WORK/backups"

cat > "$WORK/seed.sql" <<'SQL'
-- kaynak DB: restore doğrulaması için sabit 1000 satır
CREATE TABLE orders (
  id         serial PRIMARY KEY,
  customer   text NOT NULL,
  amount     numeric(10,2) NOT NULL,
  created_at timestamptz DEFAULT now()
);
INSERT INTO orders (customer, amount)
SELECT 'musteri-' || g, (g % 500 + 1)::numeric(10,2)
FROM generate_series(1, 1000) AS g;
SQL

cat > "$WORK/compose.yaml" <<'YAML'
# K08 — kaynak (seed'li) + boş restore hedefi. Sürümler pinli; :latest kullanma.
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: labpass    # lab-only, gerçek sır değil
      POSTGRES_DB: shop
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - ./seed.sql:/docker-entrypoint-initdb.d/seed.sql:ro
  db_restore:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: labpass    # lab-only, gerçek sır değil
      POSTGRES_DB: shop
    ports:
      - "127.0.0.1:5433:5432"
YAML

echo "== kaynak + hedef ayağa kaldırılıyor =="
docker compose -f "$WORK/compose.yaml" up -d

echo "== kaynak DB hazır olana kadar bekle =="
ready=0
for _ in $(seq 1 60); do
  if docker compose -f "$WORK/compose.yaml" exec -T db pg_isready -U postgres >/dev/null 2>&1; then
    ready=1; break
  fi
  sleep 2
done
[ "$ready" = 1 ] || { echo "db zamanında hazır olmadı." >&2; exit 1; }
# init script'in seed'i yüklemesi için tabloyu bekle
for _ in $(seq 1 30); do
  if docker compose -f "$WORK/compose.yaml" exec -T db psql -U postgres -d shop -tAc \
       'SELECT count(*) FROM orders;' >/dev/null 2>&1; then break; fi
  sleep 1
done

echo "== üç backup üretiliyor (biri eksik, biri bozuk, biri erişilemez) =="
# 1) eksik veri: yalnız şema
docker compose -f "$WORK/compose.yaml" exec -T db \
  pg_dump -U postgres -d shop --schema-only > "$WORK/backups/nightly.sql"

# gerçek tam dump (geçici) → weekly (bozuk) + monthly (iyi ama izinsiz) türetilir
docker compose -f "$WORK/compose.yaml" exec -T db \
  pg_dump -U postgres -d shop > "$WORK/backups/_full.sql"

# 2) bozuk/eksik: dump'ın son 4 satırını at → COPY bloğu sonlanmaz (\.)
total="$(wc -l < "$WORK/backups/_full.sql")"
keep=$(( total - 4 ))
[ "$keep" -lt 1 ] && keep=1
sed -n "1,${keep}p" "$WORK/backups/_full.sql" > "$WORK/backups/weekly.sql"

# 3) iyi ama erişilemez: tam dump, izin 000
cp "$WORK/backups/_full.sql" "$WORK/backups/monthly.sql"
rm -f "$WORK/backups/_full.sql"
chmod 000 "$WORK/backups/monthly.sql"

echo
echo "Kuruldu. env/backups/ içinde nightly.sql, weekly.sql, monthly.sql var."
echo "Belirti: gece backup'ından restore edildi ama db_restore'da 0 satır."
echo "Teşhise şuradan başla — her backup'ı ayrı dene ve HER SEFERİNDE satır say:"
echo "  docker compose -f env/compose.yaml exec -T db_restore \\"
echo "    psql -U postgres -d shop -tAc 'SELECT count(*) FROM orders;'"
