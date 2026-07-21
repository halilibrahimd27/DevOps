#!/usr/bin/env bash
# init-lab.sh — L04 için tek commit'li temiz bir başlangıç reposu kurar.
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$LAB_DIR/repo"

rm -rf "$REPO"
mkdir -p "$REPO"
cd "$REPO"
git init -q
git config user.email "lab@lab.example"
git config user.name "Lab Kullanıcısı"
cat > notlar.md <<'EOF'
# Notlar
durum: taslak
EOF
git add notlar.md
git commit -q -m "başlangıç: notlar.md"
git branch -M main

cat <<EOF
Repo kuruldu: $REPO  (dal: main, 1 commit)
Sıradaki:  cd repo
  1) feature-merge dalında notlar.md'nin 'durum:' satırını değiştir
  2) main'de aynı satırı FARKLI değiştir
  3) merge et → conflict'i çöz
Sonra rebase ile tekrarla. Bitince: bash ../verify.sh
EOF
