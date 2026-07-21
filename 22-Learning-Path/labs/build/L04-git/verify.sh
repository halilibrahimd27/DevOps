#!/usr/bin/env bash
# verify.sh — L04 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

if [ ! -d repo/.git ]; then
  echo "  ❌ repo/ yok — starter/init-lab.sh çalıştır ve görevi yap."
  echo "BAŞARISIZ ❌"; exit 1
fi

# 1) En az 3 commit (başlangıç + iki taraf)
NCOMMIT="$(git -C repo rev-list --count --all 2>/dev/null || echo 0)"
if [ "${NCOMMIT:-0}" -ge 3 ]; then ok "yeterli commit var ($NCOMMIT)"; else no "en az 3 commit bekleniyordu, $NCOMMIT var"; fi

# 2) Merge commit
if [ -n "$(git -C repo log --merges --oneline 2>/dev/null)" ]; then
  ok "merge commit mevcut (conflict çözülmüş)"
else
  no "merge commit yok — feature dalını main'e merge et"
fi

# 3) Conflict işareti kalmamış (temiz çözüm)
if git -C repo grep -qE '^(<<<<<<<|=======|>>>>>>>)' -- . 2>/dev/null; then
  no "notlar.md'de hâlâ conflict işareti var (<<<<<<< vb.)"
else
  ok "çalışma ağacında conflict işareti kalmamış"
fi

# 4) report.txt merge↔rebase ayrımı
if [ -f report.txt ] && grep -qi "merge" report.txt && grep -qiE "rebase|doğrusal|linear" report.txt; then
  ok "report.txt merge↔rebase farkını açıklıyor"
else
  no "report.txt merge commit vs rebase(doğrusal) ayrımını içermeli"
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
