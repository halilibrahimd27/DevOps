#!/usr/bin/env bash
# verify.sh — K07: erişim geri geldi mi + incident belgeleri var mı? Çıkış 0 = çözüldü.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

if ! command -v kubectl >/dev/null 2>&1 || ! kubectl cluster-info >/dev/null 2>&1 || ! kubectl get ns inc >/dev/null 2>&1; then
  echo "  ⚠️  kubectl/cluster/inc yok — canlı erişim doğrulanamadı; incident belgeleri denetlenir."
  if [ -f timeline.md ] && grep -qiE 'utc|[0-9]{2}:[0-9]{2}' timeline.md; then
    ok "timeline.md var (zaman damgalı)"
  else
    no "timeline.md yok/zaman damgasız — UTC dakika hassasiyetli bir timeline yaz"
  fi
  if [ -f postmortem.md ] && grep -qiE 'kök sebep|root cause' postmortem.md && grep -qiE 'sahip|owner|son tarih|due' postmortem.md; then
    ok "postmortem.md var (kök sebep + sahipli eylem maddesi)"
  else
    no "postmortem.md yok/eksik — kök sebep + sahip/son tarihli eylem maddesi ekle"
  fi
  echo "----------------------------------------"
  [ "$FAIL" -eq 0 ] && { echo "GEÇTİ ✅ (mekanik — belgeler tam; erişimi cluster'da doğrula)"; exit 0; } \
                    || { echo "BAŞARISIZ ❌  ($FAIL hata) — incident belgelerini tamamla."; exit 1; }
fi

# 1) pod'lar çalışıyor mu (ARIZA 1 giderildi: config key doğru)
avail="$(kubectl -n inc get deploy api -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
[ "${avail:-0}" -ge 1 ] 2>/dev/null && ok "api Deployment hazır ($avail replica) — config arızası giderilmiş" \
  || no "api pod'ları hazır değil (CreateContainerConfigError?) — configMapKeyRef key'ini kontrol et"

# 2) Service endpoint'i dolu mu (ARIZA 2 giderildi: selector doğru)
ep="$(kubectl -n inc get endpoints api -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || true)"
[ -n "$ep" ] && ok "api Service'inin endpoint'i var (selector arızası giderilmiş)" \
  || no "api endpoints boş — Service selector'ı pod etiketleriyle eşleşmiyor"

# 3) incident belgeleri
if [ -f timeline.md ] && grep -qiE 'utc|[0-9]{2}:[0-9]{2}' timeline.md; then
  ok "timeline.md var (zaman damgalı)"
else
  no "timeline.md yok/zaman damgasız — UTC dakika hassasiyetli bir timeline yaz"
fi
if [ -f postmortem.md ] && grep -qiE 'kök sebep|root cause' postmortem.md && grep -qiE 'sahip|owner|son tarih|due' postmortem.md; then
  ok "postmortem.md var (kök sebep + sahipli eylem maddesi)"
else
  no "postmortem.md yok/eksik — kök sebep + sahip/son tarihli eylem maddesi ekle"
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol) — postmortem'de 'niçin daha erken yakalanmadı'yı unutma."; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata) — hints/hint-1.md'den başla."; exit 1; fi
