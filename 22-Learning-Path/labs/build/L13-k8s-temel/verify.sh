#!/usr/bin/env bash
# verify.sh — L13 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

# manifestleri ÖĞRENCİNİN çalıştığı starter/ içinde ara (solution/ referanstır, denetlenmez)
manifests(){ cat starter/*.yaml 2>/dev/null; }
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

# canlı kontrol — NetworkPolicy GERÇEKTEN kesiyor mu? (guard'lı; cluster yoksa atlanır)
# report.txt grep'i öğrencinin YAZDIĞINI doğrular; bu blok politikanın no-op olmadığını
# CANLI sınar — sürüm/CNI nedeniyle policy zorlanmıyorsa yakalar (D1 güvenlik ipliği).
if command -v kubectl >/dev/null 2>&1 && kubectl get ns lab >/dev/null 2>&1; then
  ok "kubectl: lab namespace mevcut (canlı)"
  # Canlı test ancak (a) default-deny NetworkPolicy uygulanmış VE (b) servisin hazır
  # endpoint'i varsa anlamlı; yoksa "erişilemedi" policy'den değil hedef yokluğundandır.
  HAS_NP="$(kubectl -n lab get networkpolicy default-deny-ingress --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  HAS_EP="$(kubectl -n lab get endpoints lab-svc -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)"
  if [ "${HAS_NP:-0}" -ge 1 ] && [ -n "$HAS_EP" ]; then
    # İZİNSİZ Pod (lab ns içinde, ingress-nginx değil) servise erişmeyi DENER; policy kesmeli.
    PROBE="$(kubectl -n lab run np-probe-check --image=busybox:1.36 --restart=Never -i --rm --quiet \
      -- sh -c 'wget -qO- --timeout=3 http://lab-svc >/dev/null 2>&1 && echo REACHED || echo BLOCKED' 2>/dev/null)"
    if printf '%s' "$PROBE" | grep -q BLOCKED; then
      ok "canlı: izinsiz Pod erişimi NetworkPolicy tarafından gerçekten kesildi"
    elif printf '%s' "$PROBE" | grep -q REACHED; then
      no "canlı: izinsiz Pod servise ERİŞTİ — NetworkPolicy zorlanmıyor (kind'i güncelle ya da Calico gibi policy-zorlayan CNI kur)"
    else
      printf '  ⚠️  canlı probe çalıştırılamadı — canlı NetworkPolicy testi atlandı\n'
    fi
  else
    printf '  ⚠️  default-deny NetworkPolicy yok ya da lab-svc endpoint yok — canlı NetworkPolicy testi atlandı\n'
  fi
else
  printf '  ⚠️  kubectl/lab namespace yok — canlı kontrol atlandı\n'
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
