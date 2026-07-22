#!/usr/bin/env bash
# verify.sh — L15 mekanik doğrulama. Çıkış 0 = geçti.
set -u
cd "$(dirname "$0")"
PASS=0; FAIL=0
ok(){ printf '  ✅ %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }

# ÖĞRENCİNİN çalıştığı starter/ denetlenir (solution/ referanstır)
DEP="$(cat starter/deployment.yaml 2>/dev/null)"

# 1) secretKeyRef kullanılıyor
echo "$DEP" | grep -qE 'secretKeyRef' && ok "Deployment sırrı secretKeyRef ile alıyor" || no "Deployment'ta secretKeyRef yok — düz metin parolayı değiştir"

# 2) düzelttiğin starter'da düz metin parola KALMAMALI (placeholder hariç)
if grep -E 'value:\s*"' starter/deployment.yaml 2>/dev/null | grep -qvE '<[A-Z_]+>|CHANGEME|placeholder'; then
  no "starter/deployment.yaml'da düz metin parola değeri kalmış görünüyor"
else
  ok "manifestte düz metin parola değeri yok (placeholder OK)"
fi

# 3) report.txt kanıtları
if [ ! -f report.txt ]; then
  no "report.txt yok — base64 açıklaması + tarama çıktısı + GitOps yolu yaz"
else
  grep -qiE 'base64|şifrele|encrypt|encryption' report.txt && ok "report.txt base64≠şifreleme'yi açıklıyor" || no "report.txt'te base64/şifreleme açıklaması yok"
  grep -qiE 'gitleaks|trivy|secret|sızın|leak' report.txt && ok "report.txt sızıntı taraması çıktısı içeriyor" || no "report.txt'te tarama çıktısı yok"
  grep -qiE 'sealed|sops|external secret|vault|kms' report.txt && ok "report.txt GitOps'a sır taşıma yolunu açıklıyor" || no "report.txt'te GitOps sır yöntemi (sealed/sops/vault) yok"
fi

echo "----------------------------------------"
if [ "$FAIL" -eq 0 ]; then echo "GEÇTİ ✅  ($PASS kontrol)"; exit 0
else echo "BAŞARISIZ ❌  ($FAIL hata, $PASS geçti)"; exit 1; fi
