---
description: "The legal-compliance dimension of DevSecOps: turning KVKK, GDPR, ISO 27001, SOC 2, EU AI Act, NIS2 and PCI DSS into continuous compliance via code, pipelines and K8s policy."
tags:
  - Compliance
  - Security
  - KVKK
  - GDPR
  - Policy as Code
---
# 19 · Compliance & Legal

> *"Compliance isn't a 'wall to hang certificates on'; it's an
> **engineering control**. A team that crams for audit day walks
> around exhausted for 6 months after every audit."*

The legal-compliance dimension of DevSecOps. Covers how KVKK, GDPR,
ISO 27001, SOC 2, EU AI Act, NIS2, and PCI DSS get turned into
**continuous compliance** through code, pipelines, and K8s policy.

## Contents

| File | Topic |
|---|---|
| [`KVKK-Practical.md`](KVKK-Practical.md) | Engineering controls for KVKK (data inventory, DPIA, incident notification) |
| [`GDPR-Engineering.md`](GDPR-Engineering.md) | Where GDPR touches engineering (right-to-erasure, DPA) |
| [`ISO-27001-Controls.md`](ISO-27001-Controls.md) | Annex A controls and which tool/policy satisfies each |
| [`SOC2-Type2-Prep.md`](SOC2-Type2-Prep.md) | Trust Service Criteria, observation period, evidence collection |
| [`EU-AI-Act.md`](EU-AI-Act.md) | AI system classes, high-risk compliance obligations |
| [`NIS2-Directive.md`](NIS2-Directive.md) | EU NIS2 — critical infrastructure security requirements |
| [`PCI-DSS-4.md`](PCI-DSS-4.md) | PCI DSS v4 changes for systems handling card data |
| [`Audit-Evidence-Automation.md`](Audit-Evidence-Automation.md) | Not "preparing for audit day" — automated evidence collection |

## Philosophy

> Compliance = **engineering control** + **evidence**. The control
> lives in code (Kyverno policy, audit log, SBOM, SLSA provenance).
> Evidence is generated automatically from CI/CD. **Audit day** just
> collects what already exists.

## Turkey-specific notes

- **KVKK**: audits by Turkey's data-protection authority (KVK Kurumu), the 72-hour
  breach notification requirement, registration in the Data Controllers'
  Registry (VERBİS) — a concrete example of translating a non-EU
  data-protection regime into engineering controls
- **BDDK / SPK**: financial-sector specific — Turkey's banking and capital
  markets regulators
- **Turkish Presidency Digital Transformation Office** (CBDDO) standards
- **Cross-border data transfer**: legal requirements for cloud services

## Compliance ↔ Other Sections

| Compliance need | Which engineering control satisfies it | Where in the repo |
|---|---|---|
| Audit log | Cluster + cloud + app audit | [`08-Security/Kubernetes-Hardening.md`](../08-Security/Kubernetes-Hardening.md) |
| Encryption at rest | etcd KMS, DB TDE, S3 SSE | [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md) |
| Encryption in transit | mTLS, TLS 1.2+ | [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md) |
| Access control | OIDC + RBAC + MFA | [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md) |
| Vulnerability mgmt | Trivy + Renovate + Dependency-Track | [`08-Security/Container-Image-Scanning.md`](../08-Security/Container-Image-Scanning.md) |
| Change control | Git + ArgoCD + signed commits | [`06-GitOps/ArgoCD-Setup.md`](../06-GitOps/ArgoCD-Setup.md) |
| Incident response | Runbook + IC role + postmortem | [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md) |
| Backup + DR | WAL-G + restore drill | [`10-Databases-Production/Postgres-Production-Guide.md`](../10-Databases-Production/Postgres-Production-Guide.md) |
| Threat modeling | STRIDE + LINDDUN | [`08-Security/Threat-Modeling.md`](../08-Security/Threat-Modeling.md) |

## Anti-patterns

- ❌ Cramming for audit day — start 3 months earlier, hand evidence collection to automation
- ❌ "Compliance is the security team's job" — engineers put controls into code
- ❌ "We have the certificate" → without continuous enforcement it drifts within 6 months
- ❌ Compliance docs live in Confluence, code lives elsewhere — Markdown belongs next to the code
- ❌ Fancy slide decks so you can tell the auditor "we do this" — evidence = log + policy + pipeline
