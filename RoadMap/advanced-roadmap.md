---
description: "Sıfır altyapıdan 28 günde production-grade kurulum rehberi: AWS, Terraform, EKS, ArgoCD, observability, güvenlik ve backup/DR'ı faz faz anlatan ana sayfa."
tags:
  - Roadmap
  - AWS
  - Terraform
  - Kubernetes
  - ArgoCD
  - Observability
---
# 🏗️ **DevOps Altyapısı Sıfırdan Implementation Guide**
*Hiçbir şeyin kurulu olmadığını varsayarak adım adım DevOps altyapısı kuracağız.*

---

> *"Bir senior'ın ofise gelip 28 günde sıfırdan production-grade AWS/EKS platformu kurma günlüğü."*

Bu rehber, sıfır altyapıdan başlayıp **AWS + Terraform + EKS + ArgoCD +
observability + güvenlik + backup/DR**'a kadar uçtan uca bir kurulumu 28 günlük
plana yayar. Tek dosya 8500+ satıra ulaştığı için **faz faz okunabilir
sayfalara** bölündü; sırayla ya da ihtiyacın olan fazdan ilerleyebilirsin.

> 🆕 **Hızlı başlamak isteyenler:** önce [30 Dakikalık Hızlı Kurulum](advanced/13-quickstart-30min.md)'a göz at.

---

## 🗺️ 28 Günlük Plan — Bölümler

| # | Bölüm | Gün |
|---|---|---|
| 0 | [Ön Koşullar ve Hazırlık](advanced/00-prerequisites.md) | — |
| 1 | [AWS Hesap ve İlk Kurulumlar](advanced/01-aws-account-setup.md) | 1-2 |
| 2 | [Terraform & Infrastructure as Code](advanced/02-terraform-iac.md) | 3-5 |
| 3 | [Containerization & Registry](advanced/03-containerization.md) | 6-7 |
| 4 | [CI/CD Pipeline Kurulumu](advanced/04-cicd-pipeline.md) | 8-10 |
| 5 | [Kubernetes Advanced Setup](advanced/05-kubernetes-advanced.md) | 11-13 |
| 6 | [Observability Stack](advanced/06-observability.md) | 14-16 |
| 7 | [Secrets Management & Security](advanced/07-secrets-security.md) | 17-18 |
| 8 | [Backup & Disaster Recovery](advanced/08-backup-dr.md) | 19-20 |
| 9 | [GitOps & Deployment Automation](advanced/09-gitops-automation.md) | 21-22 |
| 10 | [Cost Optimization & Performance](advanced/10-cost-performance.md) | 23-24 |
| 11 | [Documentation & Team Processes](advanced/11-documentation-processes.md) | 25-26 |
| 12 | [Final Setup ve Validation](advanced/12-final-validation.md) | 27-28 |
| ⚡ | [30 Dakikalık Hızlı Kurulum](advanced/13-quickstart-30min.md) | — |

---

## 🎯 Bitirince ne elde edeceksin

- Terraform ile yönetilen, çok-AZ'lı bir **EKS cluster**
- GitOps (ArgoCD) ile otomatik deployment
- Prometheus + Grafana + Loki ile **observability**
- Secrets management, network policy, RBAC ile **güvenlik temeli**
- Backup/DR planı, runbook'lar ve maliyet optimizasyonu

> *"Plan uzun görünüyor; ama her faz kendi başına bir kazanım. Bir faz bitir, bırak, devam et."*
