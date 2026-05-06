#!/usr/bin/env bash
# build-docs.sh — MkDocs için site_src/ staging klasörünü doldurur.
#
# Niye var: MkDocs docs_dir = repo kökü olamaz. Bu script kök seviyedeki
# md dosyalarını ve numaralı klasörleri site_src/'a kopyalar; sonra
# mkdocs build site_src/'tan okur.
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

# Kök seviyesi md'ler (build için gerekenler)
for f in README.md CHANGELOG.md Glossary.md; do
  if [ -f "$f" ]; then
    cp "$f" "$STAGE/"
    echo "  + $f"
  fi
done

# Numaralı klasörler (00-20)
for d in 0[0-9]-* 1[0-9]-* 20-*; do
  if [ -d "$d" ]; then
    cp -r "$d" "$STAGE/"
    echo "  + $d/"
  fi
done

# Ek klasörler
for d in RoadMap System Ansible Kubectl Terraform Network; do
  if [ -d "$d" ]; then
    cp -r "$d" "$STAGE/"
    echo "  + $d/"
  fi
done

# Assets ve overrides — theme için
if [ -d assets ]; then
  cp -r assets "$STAGE/"
  echo "  + assets/"
fi

if [ -d overrides ]; then
  cp -r overrides "$STAGE/"
  echo "  + overrides/"
fi

# index.md → README'nin kopyası (MkDocs homepage olarak okur)
if [ -f "$STAGE/README.md" ]; then
  cp "$STAGE/README.md" "$STAGE/index.md"
  echo "  + index.md (README kopyası)"
fi

# Sayım
MD_COUNT=$(find "$STAGE" -name "*.md" | wc -l)
echo ""
echo "✅ Staged: $MD_COUNT markdown dosyası"
