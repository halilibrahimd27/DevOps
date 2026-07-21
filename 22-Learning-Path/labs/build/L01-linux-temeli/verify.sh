#!/usr/bin/env bash
# verify.sh — L01 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

PG="playground"

# 1) Playground var mı
if [ -d "$PG" ]; then ok "playground/ mevcut"; else no "playground/ yok — önce starter/setup-playground.sh çalıştır"; fi

# 2) Dizin izinleri 750
if [ -d "$PG" ]; then
  bad_dirs="$(find "$PG" -type d ! -perm 0750 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$bad_dirs" = "0" ]; then ok "tüm dizinler 750"; else no "$bad_dirs dizin 750 değil"; fi
  bad_files="$(find "$PG" -type f ! -perm 0640 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$bad_files" = "0" ]; then ok "tüm dosyalar 640"; else no "$bad_files dosya 640 değil"; fi
fi

# 3) report.txt kanıtları
if [ -f report.txt ]; then
  grep -qiE "PID[= ]?[0-9]+" report.txt && ok "report.txt process PID içeriyor" || no "report.txt PID satırı yok"
  grep -qi "inode" report.txt && ok "report.txt df -h/df -i farkını açıklıyor" || no "report.txt df -h/-i farkı yok (inode geçmeli)"
else
  no "report.txt yok"
fi

# 4) Servis kullanıcısı (varsa; sudo yoksa uyarı, hata değil)
if id l01svc >/dev/null 2>&1; then
  shell="$(getent passwd l01svc | cut -d: -f7)"
  case "$shell" in
    *nologin|*false) ok "l01svc kullanıcısı login'siz ($shell)";;
    *) no "l01svc var ama shell login yapabiliyor: $shell";;
  esac
else
  printf '  ⚠️  l01svc kullanıcısı yok (sudo gerekiyordu) — bu kontrol atlandı\n'
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then
  echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else
  echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1
fi
