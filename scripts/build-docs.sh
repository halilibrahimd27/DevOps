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

# Bu script associative array (declare -A) kullanır → Bash 4.0+ gerekir.
# macOS varsayılanı Bash 3.2 — `brew install bash` ile güncelle veya `bash` PATH'te 4+ olsun.
if (( BASH_VERSINFO[0] < 4 )); then
  echo "HATA: Bash ${BASH_VERSION} bulundu; bu script Bash 4.0+ gerektirir (declare -A)." >&2
  echo "      macOS: 'brew install bash' sonra 'bash scripts/build-docs.sh' (Homebrew bash'i)." >&2
  exit 1
fi

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

# 1a) Hakkımda / About — docs/about.md (portfolyo sayfası)
if [ -f docs/about.md ]; then
  cp docs/about.md "$STAGE/about.md"
  echo "  + about.md (portfolyo / about)"
fi

# 1b) Etiket indeksi — docs/tags.md (Material tags plugin tags_file)
if [ -f docs/tags.md ]; then
  cp docs/tags.md "$STAGE/tags.md"
  echo "  + tags.md (etiket indeksi)"
fi

# 2) Kök seviyesi md dosyaları
# Not: CHANGELOG.md bilinçli olarak siteye STAGE EDİLMEZ (portfolyo sitesinde nav sekmesi
# olarak yersiz duruyor). Dosya repo'da kalır (GitHub'da + sürüm geçmişi için).
for f in Glossary.md; do
  if [ -f "$f" ]; then
    cp "$f" "$STAGE/"
    echo "  + $f"
  fi
done

# 3) Numaralı klasörler (00-21)
for d in 0[0-9]-* 1[0-9]-* 2[0-9]-*; do
  if [ -d "$d" ]; then
    cp -r "$d" "$STAGE/"
    echo "  + $d/"
  fi
done

# 4) Ek klasörler (RoadMap top-level öğrenme yolu; saha notları 21-Field-Notes/ altında)
for d in RoadMap; do
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
  ["21-Field-Notes"]="21 · Saha Notları"
  ["RoadMap"]="🗺️ Yol Haritası"
)

for dir in "${!TITLES[@]}"; do
  if [ -d "$STAGE/$dir" ]; then
    printf "title: %s\n" "${TITLES[$dir]}" > "$STAGE/$dir/.pages"
    echo "  + $dir/.pages → ${TITLES[$dir]}"
  fi
done

# 7) Top-level nav sırası (.pages root)
cat > "$STAGE/.pages" <<'PAGES_EOF'
nav:
  - index.md
  - "👤 Hakkımda": about.md
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
  - 21-Field-Notes
  - "📖 Sözlük": Glossary.md
  - "🏷️ Etiketler": tags.md
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
  - "Advanced — AWS/EKS Implementation (Senior)": advanced-roadmap.md
  - "Advanced — Faz Detayları": advanced
  - "Planning Şablonu (Tech Lead)": Planning.md
EOF
  echo "  + RoadMap/.pages (yeniden sıralı, Modern-DevOps-2026 başta)"
fi

# RoadMap içindeki büyük "advanced-roadmap" alt-dosyalarına başlık (varsa)
if [ -d "$STAGE/RoadMap/advanced" ]; then
  printf "title: Advanced — AWS/EKS\n" > "$STAGE/RoadMap/advanced/.pages"
  echo "  + RoadMap/advanced/.pages"
fi

# 9) Saha Notları alt-klasör başlıkları
if [ -d "$STAGE/21-Field-Notes" ]; then
  declare -A FN_TITLES=(
    ["ansible"]="Ansible"
    ["kubectl"]="kubectl"
    ["network"]="Network / SIEM"
    ["system"]="System Setup"
    ["terraform"]="Terraform"
  )
  for sub in "${!FN_TITLES[@]}"; do
    if [ -d "$STAGE/21-Field-Notes/$sub" ]; then
      printf "title: %s\n" "${FN_TITLES[$sub]}" > "$STAGE/21-Field-Notes/$sub/.pages"
    fi
  done
  echo "  + 21-Field-Notes/*/.pages"
fi

# Sayım
MD_COUNT=$(find "$STAGE" -name "*.md" | wc -l)
echo ""
echo "✅ Staged: $MD_COUNT markdown dosyası"
