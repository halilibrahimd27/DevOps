---
description: "Kopyala-değiştir-kullan DevOps template koleksiyonu: GitHub Actions, Kubernetes, Dockerfile, Terraform, Kyverno, runbook ve Prometheus kuralları; tüm placeholder'lar UPPER_CASE."
tags:
  - Template
  - CI/CD
  - Kubernetes
  - Terraform
  - Security
  - Observability
---
# 17 · Templates

> Copy-paste-değiştir-kullan. Tüm placeholder'lar `<UPPER_CASE>` ile.

## İçindekiler

| Klasör | İçerik |
|---|---|
| [`github-actions/`](github-actions/README.md) | Reusable workflow'lar: docker build/push, terraform plan, release-please |
| [`kubernetes/`](kubernetes/README.md) | Production-grade Deployment, Service, HPA, NetworkPolicy, PDB |
| [`dockerfiles/`](dockerfiles/README.md) | Multi-stage Dockerfile'lar: Go, Node.js, Python |
| [`terraform/`](terraform/README.md) | Module skeleton + standard variable yapısı |
| [`kyverno-policies/`](kyverno-policies/README.md) | Imza doğrulama, label enforcement, image source kısıtlama |
| [`runbooks/`](runbooks/) | Runbook ve postmortem template |
| [`prometheus-rules/`](prometheus-rules/README.md) | SLO recording + alerting rule template'leri |
| [`gitignore/`](gitignore/README.md) | Stack başına `.gitignore` örnekleri |

## Genel kural

- ✅ Hiçbir template'te gerçek IP/domain/credential **yoktur**
- ✅ Yorum satırları placeholder'ları açıklar
- ✅ Her template `kubectl apply` veya `terraform plan` ile **valid**
- ✅ "Bunu değiştir" yorumları belirgin
