#!/usr/bin/env bash
# pipeline.sh (referans çözüm) — yerel test → build → SHA-tag → push.
# Önce KENDİN dene.
set -euo pipefail

REGISTRY="localhost:5000"
IMAGE="lab-app"
TAG="$(git rev-parse --short HEAD 2>/dev/null || echo dev)"   # :latest DEĞİL

echo "== 1/3 test =="
pytest -q

echo "== 2/3 build =="
docker build -t "$REGISTRY/$IMAGE:$TAG" .

echo "== 3/3 push =="
docker push "$REGISTRY/$IMAGE:$TAG"

echo "OK → $REGISTRY/$IMAGE:$TAG"
# Not: her adım fail edince (set -e) sonrakiler ÇALIŞMAZ. Kırık test → build yok.
