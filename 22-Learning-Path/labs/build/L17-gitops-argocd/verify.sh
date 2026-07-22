#!/usr/bin/env bash
# verify.sh — L17 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

# ÖĞRENCİNİN çalıştığı starter/ denetlenir (solution/ referanstır)
APP="$(cat starter/application.yaml 2>/dev/null)"

echo "$APP" | grep -qE 'argoproj.io' && echo "$APP" | grep -qE 'kind:\s*Application' && ok "ArgoCD Application manifesti var" || no "argoproj.io Application manifesti eksik"
echo "$APP" | grep -qE 'repoURL' && echo "$APP" | grep -qE 'path:' && ok "source (repoURL + path) tanımlı" || no "source.repoURL/path eksik"
echo "$APP" | grep -qE 'destination' && ok "destination tanımlı" || no "destination eksik"
echo "$APP" | grep -qE 'syncPolicy' && ok "syncPolicy tanımlı" || no "syncPolicy eksik"

if [ ! -f report.txt ]; then
  no "report.txt yok — Synced/Healthy + drift OutOfSync + git-truth yaz"
else
  grep -qiE 'synced|healthy' report.txt && ok "report.txt Synced/Healthy içeriyor" || no "report.txt'te Synced/Healthy yok"
  grep -qiE 'outofsync|drift|sap' report.txt && ok "report.txt drift/OutOfSync içeriyor" || no "report.txt'te drift/OutOfSync yok"
  grep -qiE 'git|gerçek kaynak|source of truth|geri al' report.txt && ok "report.txt 'Git tek gerçek kaynak' sonucunu içeriyor" || no "report.txt'te git-truth açıklaması yok"
fi

if command -v kubectl >/dev/null 2>&1 && kubectl -n argocd get applications >/dev/null 2>&1; then
  ok "kubectl: argocd applications erişilebilir (canlı)"
else
  printf '  ⚠️  kubectl/argocd yok — canlı kontrol atlandı\n'
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
