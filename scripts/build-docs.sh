#!/usr/bin/env bash
# build-docs.sh — MkDocs için site_src/ staging klasörünü doldurur.
#
# Niye var:
#   1. MkDocs docs_dir = repo kökü olamaz; staging klasörü gerek
#   2. README.md GitHub'a göre yazılmış (badge'li, div'li) — MkDocs'ta lapa görünür.
#      Onun yerine docs/index.md (Material grid cards'lı hero) homepage olur.
#   3. awesome-pages plugin için klasör başlıkları .pages dosyalarıyla kısaltılır.
#
# Kullanım (lokal):
#   bash scripts/build-docs.sh
#   python -m mkdocs build --clean
#
# CI'da Pages workflow zaten çağırır.

set -euo pipefail

STAGE="site_src"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "📦 Staging docs to $STAGE/"
rm -rf "$STAGE"
mkdir -p "$STAGE"

# 1) Hero homepage — docs/index.md (Material grid cards'lı, README değil)
if [ -f docs/index.md ]; then
  cp docs/index.md "$STAGE/index.md"
  echo "  + index.md (hero homepage)"
fi

# 2) Kök seviyesi md dosyaları
for f in CHANGELOG.md Glossary.md; do
  if [ -f "$f" ]; then
    cp "$f" "$STAGE/"
    echo "  + $f"
  fi
done

# 3) Numaralı klasörler (00-20)
for d in 0[0-9]-* 1[0-9]-* 20-*; do
  if [ -d "$d" ]; then
    cp -r "$d" "$STAGE/"
    echo "  + $d/"
  fi
done

# 4) Ek klasörler
for d in RoadMap System Ansible Kubectl Terraform Network; do
  if [ -d "$d" ]; then
    cp -r "$d" "$STAGE/"
    echo "  + $d/"
  fi
done

# 5) Assets (theme için)
if [ -d assets ]; then
  cp -r assets "$STAGE/"
  echo "  + assets/"
fi

# 6) Klasör başlıkları için .pages dosyaları (awesome-pages plugin)
echo ""
echo "🏷️  Klasör başlıkları (.pages):"

declare -A TITLES=(
  ["00-Culture"]="00 · Kültür"
  ["01-Git-Workflow"]="01 · Git"
  ["02-CI-CD"]="02 · CI/CD"
  ["03-IaC"]="03 · IaC"
  ["04-Containers"]="04 · Containers"
  ["05-Kubernetes"]="05 · Kubernetes"
  ["06-GitOps"]="06 · GitOps"
  ["07-Observability"]="07 · Observability"
  ["08-Security"]="08 · Security"
  ["09-Networking"]="09 · Networking"
  ["10-Databases-Production"]="10 · Databases"
  ["11-SRE"]="11 · SRE"
  ["12-FinOps"]="12 · FinOps"
  ["13-Platform-Engineering"]="13 · Platform"
  ["14-Sustainability"]="14 · Sustainability"
  ["15-AI-LLMOps"]="15 · AI/LLMOps"
  ["16-Cheatsheets"]="16 · Cheatsheets"
  ["17-Templates"]="17 · Templates"
  ["18-Career"]="18 · Career"
  ["19-Compliance"]="19 · Compliance"
  ["20-Soft-Skills"]="20 · Soft Skills"
  ["RoadMap"]="🗺️ Yol Haritası"
  ["System"]="🛠️ System Setup"
  ["Ansible"]="Ansible"
  ["Kubectl"]="kubectl"
  ["Terraform"]="Terraform"
  ["Network"]="Network/SIEM"
)

for dir in "${!TITLES[@]}"; do
  if [ -d "$STAGE/$dir" ]; then
    printf "title: %s\n" "${TITLES[$dir]}" > "$STAGE/$dir/.pages"
    echo "  + $dir/.pages → ${TITLES[$dir]}"
  fi
done

# 7) Top-level nav sırası (.pages root) — index.md "🏠 Ana Sayfa" olarak override
cat > "$STAGE/.pages" <<'PAGES_EOF'
nav:
  - "🏠 Ana Sayfa": index.md
  - RoadMap
  - 00-Culture
  - 01-Git-Workflow
  - 02-CI-CD
  - 03-IaC
  - 04-Containers
  - 05-Kubernetes
  - 06-GitOps
  - 07-Observability
  - 08-Security
  - 09-Networking
  - 10-Databases-Production
  - 11-SRE
  - 12-FinOps
  - 13-Platform-Engineering
  - 14-Sustainability
  - 15-AI-LLMOps
  - 16-Cheatsheets
  - 17-Templates
  - 18-Career
  - 19-Compliance
  - 20-Soft-Skills
  - System
  - Ansible
  - Kubectl
  - Terraform
  - Network
  - "📖 Sözlük": Glossary.md
  - "📋 Changelog": CHANGELOG.md
PAGES_EOF
echo "  + .pages (root nav)"

# 8) RoadMap iç dosya başlıkları (junior'a hitap için yeniden sıralı)
if [ -d "$STAGE/RoadMap" ]; then
  cat > "$STAGE/RoadMap/.pages" <<'EOF'
title: 🗺️ Yol Haritası
nav:
  - README.md
  - "Modern DevOps 2026 — Felsefe + 2026 Stack": Modern-DevOps-2026.md
  - "GitOps A→Z (Mid+)": RoadMap.md
  - "Advanced — AWS/EKS Implementation (Senior)": Advanced RoadMap.md
  - "Planning Şablonu (Tech Lead)": Planning.md
EOF
  echo "  + RoadMap/.pages (yeniden sıralı, Modern-DevOps-2026 başta)"
fi

# 9) System klasörü uzun dosya isimleri kısaltma
if [ -d "$STAGE/System" ]; then
  cat > "$STAGE/System/.pages" <<'EOF'
title: 🛠️ System Setup
EOF
  echo "  + System/.pages"
fi

# Sayım
MD_COUNT=$(find "$STAGE" -name "*.md" | wc -l)
echo ""
echo "✅ Staged: $MD_COUNT markdown dosyası"
