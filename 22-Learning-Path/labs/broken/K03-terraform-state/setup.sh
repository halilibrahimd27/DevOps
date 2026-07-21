#!/usr/bin/env bash
# setup.sh — K03 ortamını BİLEREK BOZUK kurar: yarıda kalmış bir apply'ın
# geride bıraktığı BAYAT state kilidi. Kök sebep gizlidir.
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v terraform >/dev/null 2>&1 && ! command -v tofu >/dev/null 2>&1; then
  echo "Bu lab terraform (veya tofu) gerektirir." >&2
  exit 1
fi
TF="$(command -v terraform || command -v tofu)"

WORK="$(pwd)/env"
rm -rf "$WORK"; mkdir -p "$WORK"

# Bulutsuz, çevrimdışı çalışan minik config (null provider).
cat > "$WORK/main.tf" <<'TF'
terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
    }
  }
}

resource "null_resource" "demo" {}
TF

( cd "$WORK" && "$TF" init -input=false >/dev/null && "$TF" apply -auto-approve -input=false >/dev/null ) || {
  echo "init/apply başarısız (internet gerekli olabilir) — env/ hazır, elle dene." >&2
}

# BOZUK: yarıda kalmış bir apply'ın bıraktığı gibi BAYAT bir kilit dosyası yaz.
LOCK_ID="a1b2c3d4-0000-4000-8000-000000000000"
cat > "$WORK/.terraform.tfstate.lock.info" <<JSON
{
  "ID": "$LOCK_ID",
  "Operation": "OperationTypeApply",
  "Info": "yarıda kesilen apply (lab)",
  "Who": "labuser@lab",
  "Version": "1.0.0",
  "Created": "2024-01-01T00:00:00Z",
  "Path": "terraform.tfstate"
}
JSON

echo "Kuruldu → $WORK"
echo "Belirti: 'cd env && terraform plan' → 'Error acquiring the state lock' (ID: $LOCK_ID)"
echo "Teşhise başla: hata mesajındaki Lock ID'yi oku; kilidi kim tutuyor?"
