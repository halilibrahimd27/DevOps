#!/usr/bin/env bash
# verify.sh — L14 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

ALL="$(cat starter/*.yaml solution/*.yaml 2>/dev/null)"
DEP="$(cat starter/deployment.yaml solution/deployment.yaml 2>/dev/null)"

echo "$DEP" | grep -qE 'requests:' && echo "$DEP" | grep -qE 'limits:' && ok "Deployment request + limit içeriyor" || no "Deployment'ta request/limit eksik"
echo "$DEP" | grep -qE 'readinessProbe' && ok "readinessProbe var" || no "readinessProbe eksik"
echo "$DEP" | grep -qE 'livenessProbe' && ok "livenessProbe var" || no "livenessProbe eksik"
echo "$ALL" | grep -qE 'kind:\s*HorizontalPodAutoscaler' && ok "HPA manifesti var" || no "HPA manifesti eksik"
echo "$ALL" | grep -qE 'kind:\s*PodDisruptionBudget' && ok "PDB manifesti var" || no "PDB manifesti eksik"

if [ ! -f report.txt ]; then
  no "report.txt yok — HPA öncesi/sonrası replika + OOMKilled açıklaması yaz"
else
  grep -qiE 'replica|replicas|hpa|ölçek' report.txt && ok "report.txt HPA ölçeklenmesini içeriyor" || no "report.txt'te HPA ölçeklenme kanıtı yok"
  grep -qiE 'oomkill|limit|request|bellek|memory' report.txt && ok "report.txt request/limit + OOMKilled'ı açıklıyor" || no "report.txt'te request/limit/OOMKilled açıklaması yok"
fi

if command -v kubectl >/dev/null 2>&1 && kubectl -n lab get hpa lab-app >/dev/null 2>&1; then
  ok "kubectl: HPA lab-app mevcut (canlı)"
else
  printf '  ⚠️  kubectl/HPA yok — canlı kontrol atlandı\n'
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
