#!/usr/bin/env bash
# verify.sh — K05: OOM bitti + Pod Ready mi? Çıkış 0 = çözüldü.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

if ! command -v kubectl >/dev/null 2>&1 || ! kubectl cluster-info >/dev/null 2>&1; then
  echo "  ⚠️  kubectl/cluster yok — mekanik yedek kontrol."
  if [ -f env/deployment.yaml ]; then
    grep -qE 'memory:\s*"?32Mi' env/deployment.yaml && no "memory limit hâlâ 32Mi (OOM sürer)" || ok "memory limit yükseltilmiş (mekanik)"
    grep -qE 'port:\s*9999' env/deployment.yaml && no "readinessProbe hâlâ 9999 portunda" || ok "probe portu düzeltilmiş (mekanik)"
  else
    no "env/ yok — lab çalıştırılmadı. Bir kind/k3s cluster kur, 'bash setup.sh' çalıştır, sonra düzelt."
  fi
  echo "----------------------------------------"
  [ "$FAIL" -eq 0 ] && { echo "GEÇTİ ✅ (mekanik) — cluster'da tam doğrula."; exit 0; } || { echo "BAŞARISIZ ❌  ($FAIL hata)"; exit 1; }
fi

# 1) Pod Ready
ready="$(kubectl -n k05 get pods -l app=app -o jsonpath='{.items[*].status.containerStatuses[*].ready}' 2>/dev/null || true)"
echo "$ready" | grep -q 'true' && ok "Pod Ready (probe geçiyor)" || no "Pod hâlâ Ready değil — probe portunu düzelt"

# 2) OOMKilled devam etmiyor (son sonlanma sebebi OOM değil)
reason="$(kubectl -n k05 get pods -l app=app -o jsonpath='{.items[*].status.containerStatuses[*].lastState.terminated.reason}' 2>/dev/null || true)"
if echo "$reason" | grep -q 'OOMKilled'; then
  # Ready ise ve artık restart olmuyorsa eski OOM olabilir; canlı restart sayısına bak
  rc="$(kubectl -n k05 get pods -l app=app -o jsonpath='{.items[*].status.containerStatuses[*].restartCount}' 2>/dev/null || echo 0)"
  printf '  ⚠️  geçmişte OOMKilled var (restartCount=%s) — Ready ve artık artmıyorsa düzelmiştir\n' "$rc"
else
  ok "son sonlanma sebebi OOMKilled değil"
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol) — teshis.md'de OOM + probe kanıtını yaz."; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata) — hints/hint-1.md'den başla."; exit 1; fi
