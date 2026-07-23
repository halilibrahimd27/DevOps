---
description: "Copy-modify-use DevOps template collection: GitHub Actions, Kubernetes, Dockerfile, Terraform, Kyverno, runbook, and Prometheus rules; all placeholders in UPPER_CASE."
tags:
  - Template
  - CI/CD
  - Kubernetes
  - Terraform
  - Security
  - Observability
---
# 17 · Templates

> Copy-paste-modify-use. All placeholders use `<UPPER_CASE>`.

## Table of Contents

| Folder | Content |
|---|---|
| [`github-actions/`](github-actions/) | Reusable workflows: docker build/push, terraform plan, release-please |
| [`kubernetes/`](kubernetes/) | Production-grade Deployment, Service, HPA, NetworkPolicy, PDB |
| [`dockerfiles/`](dockerfiles/) | Multi-stage Dockerfiles: Go, Node.js, Python |
| [`terraform/`](terraform/) | Module skeleton + standard variable structure |
| [`kyverno-policies/`](kyverno-policies/) | Signature verification, label enforcement, image source restriction |
| [`runbooks/`](runbooks/) | Runbook and postmortem templates |
| [`prometheus-rules/`](prometheus-rules/) | SLO recording + alerting rule templates |
| [`gitignore/`](gitignore/) | `.gitignore` examples per stack |

## General rule

- ✅ **No** real IP/domain/credential in any template
- ✅ Comment lines explain the placeholders
- ✅ Every template is **valid** via `kubectl apply` or `terraform plan`
- ✅ "Change this" comments are clearly marked
