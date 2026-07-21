#!/usr/bin/env bash
# pipeline.sh (referans) — test → build → SCAN(kapı) → SBOM → SIGN → verify → push.
# Önce KENDİN dene.
set -euo pipefail

REGISTRY="localhost:5000"
IMAGE="lab-app"
TAG="$(git rev-parse --short HEAD 2>/dev/null || echo dev)"
IMG="$REGISTRY/$IMAGE:$TAG"

echo "== test =="
pytest -q

echo "== build =="
docker build -t "$IMG" .

echo "== scan (KAPI) =="
# HIGH/CRITICAL varsa exit 1 → set -e pipeline'ı durdurur, push OLMAZ
trivy image --exit-code 1 --severity HIGH,CRITICAL "$IMG"

echo "== sbom =="
trivy image --format cyclonedx -o sbom.json "$IMG"

echo "== sign + verify =="
# cosign.key/cosign.pub önceden: cosign generate-key-pair (cosign.key COMMIT ETME)
cosign sign   --key cosign.key "$IMG"
cosign verify --key cosign.pub "$IMG"

echo "== push =="
docker push "$IMG"
echo "OK → $IMG (taranmış + imzalı)"
