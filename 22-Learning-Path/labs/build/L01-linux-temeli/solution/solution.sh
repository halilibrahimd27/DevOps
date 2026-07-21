#!/usr/bin/env bash
# solution.sh — L01 referans çözüm. ÖNCE KENDİN DENE, sonra buraya bak.
# Bu script görevin nasıl yapıldığını gösterir; ezberlemek yerine her satırın
# NİÇİN orada olduğunu anla.
set -euo pipefail

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$LAB_DIR"
PG="playground"
REPORT="report.txt"

# 1) Process'i bul ve incele
PID="$(pgrep -f l01-daemon | head -n1)"
echo "== L01 raporu ==" > "$REPORT"
echo "process: l01-daemon PID=$PID" >> "$REPORT"
# Çalışma dizini ve açık dosyalar (Linux):
#   ls -l /proc/$PID/cwd    → çalışma dizini
#   ls -l /proc/$PID/fd/    → açık dosya tanıtıcıları
[ -e "/proc/$PID/cwd" ] && echo "cwd: $(readlink -f /proc/$PID/cwd)" >> "$REPORT" || true

# 2) İzinleri düzelt — dizinler 750, dosyalar 640
find "$PG" -type d -exec chmod 0750 {} +
find "$PG" -type f -exec chmod 0640 {} +
# gizli.txt zaten 640 oldu; ayrıca doğrula
chmod 0640 "$PG/gizli.txt"

# 3) Kanıt cümleleri
cat >> "$REPORT" <<'EOF'
df farkı: `df -h` disk BLOK doluluğunu (kaç GB), `df -i` INODE doluluğunu
(kaç dosya/dizin girişi) gösterir. Blok boşken inode dolabilir (milyonlarca
minik dosya) — ikisi ayrı "disk dolu" anlamıdır.
kullanıcı/grup/sudo: kullanıcı = kimliğin; grup = paylaşılan erişim kümesi;
sudo = geçici yetki yükseltme. Servis kullanıcısını login'siz yaparız çünkü
ele geçirilse bile interaktif kabuk açamaz — saldırı yüzeyini daraltır.
EOF

# 4) Servis kullanıcısı (idempotent)
NOLOGIN="$(command -v nologin || echo /usr/sbin/nologin)"
if ! id l01svc >/dev/null 2>&1; then
  sudo useradd --system --no-create-home --shell "$NOLOGIN" l01svc
fi

echo "Çözüm uygulandı. Doğrula:  bash verify.sh"
