#!/usr/bin/env bash
# verify.sh — K04: iki katman da düzeldi mi? Çıkış 0 = çözüldü.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

if ! command -v kubectl >/dev/null 2>&1 || ! kubectl cluster-info >/dev/null 2>&1; then
  echo "  ⚠️  kubectl/cluster yok — bu lab canlı bir cluster'da doğrulanır."
  # mekanik yedek: env manifestleri düzeltilmiş mi?
  if [ -f env/deployment.yaml ]; then
    grep -q 'does-not-exist' env/deployment.yaml && no "env/deployment.yaml hâlâ bozuk tag içeriyor" || ok "deployment tag düzeltilmiş (mekanik)"
  else
    no "env/ yok — lab çalıştırılmadı. Bir kind/k3s cluster kur, 'bash setup.sh' çalıştır, sonra düzelt."
  fi
  echo "----------------------------------------"
  [ "$FAIL" -eq 0 ] && { echo "GEÇTİ ✅ (mekanik) — cluster'da bash verify.sh ile tam doğrula."; exit 0; } || { echo "BAŞARISIZ ❌  ($FAIL hata)"; exit 1; }
fi

# 1) Pod Running (image düzeldi)
ready="$(kubectl -n k04 get pods -l app=app -o jsonpath='{.items[*].status.containerStatuses[*].ready}' 2>/dev/null || true)"
echo "$ready" | grep -q 'true' && ok "Pod Running/Ready (ImagePullBackOff çözüldü)" || no "Pod hâlâ hazır değil — image tag'ini düzelt"

# 2) Servise erişilebiliyor (NetworkPolicy izni eklendi)
if kubectl -n k04 run k04probe --image=busybox:1.36 --restart=Never --rm -i --timeout=60s -- \
     wget -qO- --timeout=4 http://app-svc >/tmp/k04probe 2>/dev/null; then
  ok "app-svc'ye erişilebiliyor (NetworkPolicy izni var)"
else
  no "app-svc'ye erişilemiyor — default-deny'yi dengeleyen izin kuralı ekle"
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol) — teshis.md'de her katmanın kanıtını yaz."; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata) — hints/hint-1.md'den başla."; exit 1; fi
