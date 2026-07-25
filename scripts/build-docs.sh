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

# Taşınabilirlik: associative array (declare -A, Bash 4+) yerine "anahtar|değer"
# satırlı indeksli diziler kullanılır → macOS varsayılan Bash 3.2 dahil her yerde çalışır.

STAGE="site_src"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "📦 Staging docs to $STAGE/"
rm -rf "$STAGE"
mkdir -p "$STAGE"

# 1) Hero homepage — docs/index.md (Material grid cards'lı, README değil)
# EN twin (docs/index.en.md) da varsa stage edilir; i18n suffix şeması onu
# /en/ homepage'i yapar (site-kökü göreli linkler staged konumda doğru çözülür).
if [ -f docs/index.md ]; then
  cp docs/index.md "$STAGE/index.md"
  echo "  + index.md (hero homepage)"
fi
if [ -f docs/index.en.md ]; then
  cp docs/index.en.md "$STAGE/index.en.md"
  echo "  + index.en.md (EN homepage twin)"
fi

# 1a) Hakkımda / About — docs/about.md (portfolyo sayfası)
if [ -f docs/about.md ]; then
  cp docs/about.md "$STAGE/about.md"
  echo "  + about.md (portfolyo / about)"
fi
if [ -f docs/about.en.md ]; then
  cp docs/about.en.md "$STAGE/about.en.md"
  echo "  + about.en.md (EN about twin)"
fi

# 1b) Etiket indeksi — docs/tags.md (Material tags plugin tags_file)
if [ -f docs/tags.md ]; then
  cp docs/tags.md "$STAGE/tags.md"
  echo "  + tags.md (etiket indeksi)"
fi

# 2) Kök seviyesi md dosyaları
# Not: CHANGELOG.md bilinçli olarak siteye STAGE EDİLMEZ (portfolyo sitesinde nav sekmesi
# olarak yersiz duruyor). Dosya repo'da kalır (GitHub'da + sürüm geçmişi için).
for f in Glossary.md Glossary.en.md; do
  if [ -f "$f" ]; then
    cp "$f" "$STAGE/"
    echo "  + $f"
  fi
done

# 3) Numaralı klasörler (00-22 — 22-Learning-Path glob'a dahil)
for d in 0[0-9]-* 1[0-9]-* 2[0-9]-*; do
  if [ -d "$d" ]; then
    cp -r "$d" "$STAGE/"
    echo "  + $d/"
  fi
done

# 3a) Öğrenme Patikası: _planning/ çalışma alanı siteye STAGE EDİLMEZ.
# (mkdocs.yml exclude_docs'ta da var — çift emniyet; burada dosya hiç kopyalanmasın.)
if [ -d "$STAGE/22-Learning-Path/_planning" ]; then
  rm -rf "$STAGE/22-Learning-Path/_planning"
  echo "  - 22-Learning-Path/_planning (stage edilmedi)"
fi

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

# 5a) CNAME — custom domain kullanılıyorsa. site_src/ her build'de silinip yeniden
# oluştuğu için CNAME'i buraya kopyalamazsak GitHub Pages her deploy'da custom
# domain ayarını kaybeder. Kökte CNAME yoksa bu adım sessizce atlanır.
if [ -f CNAME ]; then
  cp CNAME "$STAGE/CNAME"
  echo "  + CNAME ($(cat CNAME))"
fi

# 6) Klasör başlıkları için .pages dosyaları (awesome-pages plugin)
echo ""
echo "🏷️  Klasör başlıkları (.pages):"

# "dizin|başlık" satırları (Bash 3.2 uyumlu indeksli dizi; başlık/dizin '|' içermez)
TITLES=(
  "00-Culture|00 · Kültür"
  "01-Git-Workflow|01 · Git"
  "02-CI-CD|02 · CI/CD"
  "03-IaC|03 · IaC"
  "04-Containers|04 · Containers"
  "05-Kubernetes|05 · Kubernetes"
  "06-GitOps|06 · GitOps"
  "07-Observability|07 · Observability"
  "08-Security|08 · Security"
  "09-Networking|09 · Networking"
  "10-Databases-Production|10 · Databases"
  "11-SRE|11 · SRE"
  "12-FinOps|12 · FinOps"
  "13-Platform-Engineering|13 · Platform"
  "14-Sustainability|14 · Sustainability"
  "15-AI-LLMOps|15 · AI/LLMOps"
  "16-Cheatsheets|16 · Cheatsheets"
  "17-Templates|17 · Templates"
  "18-Career|18 · Career"
  "19-Compliance|19 · Compliance"
  "20-Soft-Skills|20 · Soft Skills"
  "21-Field-Notes|21 · Saha Notları"
  "RoadMap|🗺️ Yol Haritası"
)

for entry in "${TITLES[@]}"; do
  dir="${entry%%|*}"
  title="${entry#*|}"
  if [ -d "$STAGE/$dir" ]; then
    printf "title: %s\n" "$title" > "$STAGE/$dir/.pages"
    echo "  + $dir/.pages → $title"
  fi
done

# 7) Top-level nav sırası (.pages root)
# Slim nav: 21 konu "Konular" grubu altında toplanır → üst bar kalabalık/kayan
# tab bar yerine az sayıda anlamlı sekme. about/Glossary/tags plain-entry
# (explicit "Title: file.md" formu i18n EN'de lokalize olmuyordu → 404).
cat > "$STAGE/.pages" <<'PAGES_EOF'
nav:
  - index.md
  - 22-Learning-Path
  - RoadMap
  - "📚 Konular":
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
  - "📖 Referans":
    - Glossary.md
    - tags.md
PAGES_EOF
echo "  + .pages (root nav — slim, Konular grubu)"

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

# 8a) Öğrenme Patikası (22-Learning-Path) — başlık + iç sıra (README önce, sonra
# rehberler, sonra bloklar/capstone/sertifika/lab). EN başlık nav_translations'ta.
if [ -d "$STAGE/22-Learning-Path" ]; then
  cat > "$STAGE/22-Learning-Path/.pages" <<'EOF'
title: 🎓 Öğrenme Patikası
nav:
  - README.md
  - CURRICULUM.md
  - PLACEMENT.md
  - STUDY-METHOD.md
  - PROGRESS-TEMPLATE.md
  - COST-GUARDRAILS.md
  - TROUBLESHOOTING.md
  - NOT-YET.md
  - PORTFOLIO.md
  - block-a-intuition
  - block-b-visibility
  - block-c-reproducibility
  - block-d-orchestration
  - block-e-ownership
  - block-f-judgment
  - capstones
  - certifications
  - labs
EOF
  echo "  + 22-Learning-Path/.pages (başlık + iç sıra)"
  LP_TITLES=(
    "block-a-intuition|Blok A · Sezgi"
    "block-b-visibility|Blok B · Görebilmek"
    "block-c-reproducibility|Blok C · Tekrarlanabilirlik"
    "block-d-orchestration|Blok D · Orkestrasyon"
    "block-e-ownership|Blok E · Sahiplik"
    "block-f-judgment|Blok F · Karar"
    "capstones|Capstone Projeleri"
    "certifications|Sertifika Kapıları"
    "labs|Lab'lar"
  )
  for entry in "${LP_TITLES[@]}"; do
    sub="${entry%%|*}"
    title="${entry#*|}"
    if [ -d "$STAGE/22-Learning-Path/$sub" ]; then
      printf "title: %s\n" "$title" > "$STAGE/22-Learning-Path/$sub/.pages"
    fi
  done
  echo "  + 22-Learning-Path/block-*/.pages"
fi

# 9) Saha Notları alt-klasör başlıkları
if [ -d "$STAGE/21-Field-Notes" ]; then
  FN_TITLES=(
    "ansible|Ansible"
    "kubectl|kubectl"
    "network|Network / SIEM"
    "system|System Setup"
    "terraform|Terraform"
  )
  for entry in "${FN_TITLES[@]}"; do
    sub="${entry%%|*}"
    title="${entry#*|}"
    if [ -d "$STAGE/21-Field-Notes/$sub" ]; then
      printf "title: %s\n" "$title" > "$STAGE/21-Field-Notes/$sub/.pages"
    fi
  done
  echo "  + 21-Field-Notes/*/.pages"
fi

# Sayım
MD_COUNT=$(find "$STAGE" -name "*.md" | wc -l)
echo ""
echo "✅ Staged: $MD_COUNT markdown dosyası"
