---
description: "DevSecOps section index: shift-left pipeline, secrets management, image scanning, Kubernetes hardening, SLSA/SBOM, policy-as-code, and zero-trust guides."
tags:
  - Security
  - Kubernetes
  - CI/CD
  - Roadmap
---
# 08 · Security (DevSecOps)

> *"Those who say, when a breach happens in production, 'that's not
> security team's problem, it's everyone's problem' — they'd already
> seen the warning 6 months before the breach."*

Shift-left + runtime defense + supply chain integrity. In 2026, security
is not a "feature" — it's a starting requirement.

## Contents

| File | Topic |
|---|---|
| [`DevSecOps-Pipeline.md`](DevSecOps-Pipeline.md) | Pre-commit → SAST → SCA → IaC scan → image scan → runtime |
| [`Secrets-Management.md`](Secrets-Management.md) | Vault, ESO, SOPS, Sealed Secrets comparison + decision tree |
| [`Container-Image-Scanning.md`](Container-Image-Scanning.md) | Trivy/Grype usage, CVE prioritization, fail/warn policy |
| [`Kubernetes-Hardening.md`](Kubernetes-Hardening.md) | CIS Benchmark, Pod Security Standards, NetworkPolicy default-deny |
| [`SLSA-and-SBOM.md`](SLSA-and-SBOM.md) | Supply chain integrity, in-toto attestation, cosign attest |
| [`Policy-as-Code-OPA-Kyverno.md`](Policy-as-Code-OPA-Kyverno.md) | Kyverno vs OPA Gatekeeper, sample policy catalog |
| [`Threat-Modeling.md`](Threat-Modeling.md) | STRIDE / LINDDUN, lightweight threat model template |
| [`Zero-Trust-Networking.md`](Zero-Trust-Networking.md) | mTLS everywhere, service mesh authZ, BeyondCorp pattern |

## "Shift-Left" flow

```
┌────────── PRE-COMMIT ──────────┐  ┌──── BUILD ────┐  ┌─── DEPLOY ───┐  ┌─── RUNTIME ───┐
│ pre-commit hooks               │  │ SAST           │  │ Image scan   │  │ eBPF tracing  │
│  - gitleaks (secret detect)    │  │  - Semgrep     │  │  - Trivy     │  │  - Falco      │
│  - format check                │  │  - CodeQL      │  │ Sign verify  │  │  - Tetragon   │
│ IDE plugin                     │  │ SCA            │  │  - cosign    │  │ Network       │
│  - Snyk / Semgrep / GitGuardian│  │  - OSV-Scanner │  │ Policy gate  │  │  - NetPol     │
│                                │  │  - Trivy fs    │  │  - Kyverno   │  │  - Cilium     │
│                                │  │ License        │  │  - OPA Gatek │  │ Audit         │
│                                │  │ SBOM generate  │  │ K8s sec ctx  │  │  - audit log  │
└────────────────────────────────┘  └────────────────┘  └──────────────┘  └───────────────┘
       Developer machine                 CI                   CD             Production
```

## Minimum hygiene 2026

- ✅ All images are **signed** (cosign keyless OIDC)
- ✅ Unsigned images are **not deployed** in the cluster (Kyverno verifyImages)
- ✅ **SBOM** is generated with every image (CycloneDX/SPDX)
- ✅ **Secret scan** runs on every PR in CI
- ✅ Secrets managed via **Vault** (or managed equivalent) + **External Secrets Operator**
- ✅ **NetworkPolicy default-deny** in every namespace
- ✅ **Pod Security Standards: restricted** (at least in non-system namespaces)
- ✅ Cloud auth via **OIDC** (no long-lived access keys)
- ✅ **MFA** mandatory (Git provider, cloud, registry)
- ✅ Centralized **audit log** (cluster, cloud, app)

## Red lines

- 🔴 `latest` tag in prod → must be blocked via policy
- 🔴 `:` password in env var as clear-text → must be moved to vault
- 🔴 `*:*` IAM policy → violates least privilege, audit failure
- 🔴 Public S3 bucket → find via IAM Access Analyzer
- 🔴 Kubernetes API public access → private cluster + bastion
- 🔴 Container runAsRoot:0 → blocked by restricted PSS
