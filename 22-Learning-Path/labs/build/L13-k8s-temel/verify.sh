#!/usr/bin/env bash
# verify.sh — L13 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

# manifestleri starter/ (öğrenci) veya solution/ içinde ara
manifests(){ cat starter/*.yaml solution/*.yaml 2>/dev/null; }
ALL="$(manifests)"

check_kind(){ echo "$ALL" | grep -qE "^kind:\s*$1" && ok "$1 manifesti var" || no "$1 manifesti eksik"; }
check_kind Deployment
check_kind Service
check_kind Ingress
check_kind Role
check_kind RoleBinding
check_kind NetworkPolicy

# RBAC en az yetki: delete pods OLMAMALI
if echo "$ALL" | grep -A6 'kind: Role' | grep -qE 'verbs:.*delete'; then
  no "Role 'delete' içeriyor — en az yetki ilkesini ihlal ediyor"
else
  ok "Role en az yetkili (delete yok)"
fi

# report kanıtı
if [ ! -f report.txt ]; then
  no "report.txt yok — auth can-i + NetworkPolicy kanıtı yaz"
else
  grep -qiE 'can-i|forbidden|yes|no|reddedil' report.txt && ok "report.txt yetki (auth can-i) sonucunu içeriyor" || no "report.txt'te 'auth can-i' sonucu yok"
  grep -qiE 'networkpolicy|engellendi|deny|kesil|timeout' report.txt && ok "report.txt NetworkPolicy erişim kesme kanıtını içeriyor" || no "report.txt'te NetworkPolicy kanıtı yok"
fi

# canlı kontrol (opsiyonel)
if command -v kubectl >/dev/null 2>&1 && kubectl get ns lab >/dev/null 2>&1; then
  ok "kubectl: lab namespace mevcut (canlı)"
else
  printf '  ⚠️  kubectl/lab namespace yok — canlı kontrol atlandı\n'
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
