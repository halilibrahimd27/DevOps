#!/usr/bin/env bash
# verify.sh — K06: Synced + otomatik düzeltme açık mı? Çıkış 0 = çözüldü.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

if ! command -v kubectl >/dev/null 2>&1 || ! kubectl cluster-info >/dev/null 2>&1; then
  echo "  ❌ kubectl/cluster yok — bu lab canlı ArgoCD ile doğrulanır (L17 önkoşul)."
  echo "DOĞRULANMADI ❌ — kind + ArgoCD (L17) kurup 'bash setup.sh' çalıştır, sonra tekrar dene."; exit 1
fi
if ! kubectl -n argocd get application lab-app >/dev/null 2>&1; then
  echo "  ❌ argocd/lab-app yok — önce L17 + setup.sh."
  echo "DOĞRULANMADI ❌ — L17'yi tamamla ve 'bash setup.sh' çalıştır."; exit 1
fi

# 1) Sync durumu
sync="$(kubectl -n argocd get application lab-app -o jsonpath='{.status.sync.status}' 2>/dev/null || true)"
[ "$sync" = "Synced" ] && ok "Application Synced" || no "Application hâlâ '$sync' — sync et"

# 2) otomatik düzeltme geri açılmış mı
auto="$(kubectl -n argocd get application lab-app -o jsonpath='{.spec.syncPolicy.automated}' 2>/dev/null || true)"
[ -n "$auto" ] && ok "syncPolicy.automated açık (drift kendiliğinden düzelir)" || no "automated politika kapalı — self-heal geri aç"

# 3) drift eşitlenmiş mi (Git değeri 2)
rep="$(kubectl -n lab get deploy lab-app -o jsonpath='{.spec.replicas}' 2>/dev/null || true)"
[ "$rep" = "2" ] && ok "replicas Git değerine (2) çekilmiş" || printf '  ⚠️  replicas=%s (Git 2 ise sync bekleniyor olabilir)\n' "${rep:-?}"

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol) — teshis.md'de syncPolicy'nin rolünü yaz."; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata) — hints/hint-1.md'den başla."; exit 1; fi
