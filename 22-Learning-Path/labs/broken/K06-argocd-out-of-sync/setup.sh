#!/usr/bin/env bash
# setup.sh — K06: L17'nin lab-app'inde BİLEREK drift yaratır.
# Önce auto-sync'i kapatır (yoksa ArgoCD driftı anında geri çeker), sonra drift ekler.
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v kubectl >/dev/null 2>&1 || ! kubectl cluster-info >/dev/null 2>&1; then
  echo "Bu lab kubectl + çalışan bir cluster gerektirir." >&2
  exit 1
fi
if ! kubectl get crd applications.argoproj.io >/dev/null 2>&1; then
  echo "ArgoCD kurulu değil. Önce L17'yi tamamla (ArgoCD + lab-app)." >&2
  exit 1
fi
if ! kubectl -n argocd get application lab-app >/dev/null 2>&1; then
  echo "argocd/lab-app Application yok. Önce L17'yi tamamla." >&2
  exit 1
fi

# 1) auto-sync/self-heal'i kapat → drift kendiliğinden düzelmesin
kubectl -n argocd patch application lab-app --type merge \
  -p '{"spec":{"syncPolicy":null}}' >/dev/null

# 2) cluster'da elle drift yarat (Git'te replicas=2, burada 5)
kubectl -n lab scale deploy/lab-app --replicas=5 >/dev/null || true

echo "Kuruldu. lab-app artık OutOfSync ve kendiliğinden düzelmiyor."
echo "Belirti: kubectl -n argocd get application lab-app → OutOfSync"
echo "Teşhise başla: application'ın spec.syncPolicy'sine bak; ArgoCD niçin geri çekmiyor?"
