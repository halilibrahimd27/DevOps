#!/usr/bin/env bash
# K09 doğrulama — game day. set -euo pipefail KULLANILMAZ (öğrenci dostu).
cd "$(dirname "$0")" || exit 1
pass=0; fail=0
ok(){ echo "✅ $*"; pass=$((pass+1)); }
no(){ echo "❌ $*"; fail=$((fail+1)); }

command -v kubectl >/dev/null 2>&1 || { echo "ℹ️  kubectl yok — bu lab kubectl + yerel cluster gerektirir."; exit 1; }
kubectl cluster-info >/dev/null 2>&1 || { echo "ℹ️  erişilebilir cluster yok (kind create cluster)."; exit 1; }
kubectl get ns chaos >/dev/null 2>&1 || { echo "❌ chaos namespace yok — önce: bash setup.sh"; exit 1; }

STRAT="$(kubectl -n chaos get deploy web -o jsonpath='{.spec.strategy.type}' 2>/dev/null)"
[ "$STRAT" = "RollingUpdate" ] \
  && ok "strategy RollingUpdate (Recreate düzeltildi)" \
  || no "strategy hâlâ '$STRAT' — RollingUpdate olmalı"

if kubectl -n chaos get deploy web -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}' 2>/dev/null | grep -q .; then
  ok "readinessProbe tanımlı"
else
  no "readinessProbe yok — hazır olmayan pod trafik alır"
fi

READY="$(kubectl -n chaos get deploy web -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
[ "${READY:-0}" -ge 2 ] 2>/dev/null \
  && ok "en az 2 replica hazır ($READY)" \
  || no "yeterli hazır replica yok (${READY:-0})"

[ -f gameday.md ] \
  && ok "gameday.md raporu var" \
  || no "gameday.md yok — hipotez→deney→sonuç→zafiyet→eylem maddesi yaz"

echo
if [ "$fail" -eq 0 ]; then
  echo "🎉 GEÇTİ — 'HA' iddiası artık kanıtlı: dağıtım kesintisiz + rapor var."
  exit 0
else
  echo "$fail eksik. solution.md'deki 'Düzeltme' ve 'Deneyi tekrarla' bölümlerine bak."
  exit 1
fi
