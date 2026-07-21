#!/usr/bin/env bash
# summarize.sh — L05 referans çözüm. ÖNCE KENDİN YAZ.
# Bir log dosyasını özetler, sonucu rapor dosyasına yazar. shellcheck-temiz.
set -euo pipefail

usage() {
  echo "kullanım: $0 <log-dosyası> <rapor-dosyası>" >&2
  exit 1
}

[[ $# -eq 2 ]] || usage
LOG="$1"
OUT="$2"

if [[ ! -f "$LOG" ]]; then
  echo "hata: log dosyası bulunamadı: $LOG" >&2
  exit 1
fi

total="$(wc -l < "$LOG" | tr -d ' ')"
errors="$(grep -c 'ERROR' "$LOG" || true)"

{
  echo "== log özeti: $LOG =="
  echo "toplam satır: $total"
  echo "ERROR: $errors"
  echo "seviye dağılımı (en sık 3):"
  grep -oE 'INFO|WARN|ERROR' "$LOG" | sort | uniq -c | sort -rn | head -n3
} > "$OUT"

echo "rapor yazıldı: $OUT"
