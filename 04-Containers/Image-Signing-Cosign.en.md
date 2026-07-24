---
description: "Setting up container image signing with Cosign keyless OIDC in production: threat model, steps, GitHub Actions, and admission verification."
tags:
  - Containers
  - Security
  - SBOM
  - CI/CD
  - Threat Modeling
---
# Image Signing — Cosign + Keyless OIDC

> *"Pushing your image to a registry without signing it means 'I have
> no idea who put this here.' If an attacker pushes a **fake image**
> to the registry, how does the cluster tell the difference? **Only
> the signature** tells the difference."*

This guide covers the concrete steps for setting up container image
signing — specifically **Cosign keyless** — in production, its GitHub
Actions integration, and admission verification.

---

## 🎯 Why Sign?

### Threat
```
[Attacker]
   │
   ▼
[Compromise registry]  ──► [Push fake image: <REGISTRY>/<APP>:1.4.0]
                                        │
                                        ▼
                                  [Cluster pulls]
                                        │
                                        ▼
                                  [Compromised pod runs]
```

### Solution
- Build → **sign** with cosign
- Cluster admission → **verify signature**
- Unsigned image → **deploy rejected**

---

## 🔑 Keyless vs Key-Based

| Method | Pro | Con |
|---|---|---|
| **Keyless** (OIDC) | Ephemeral cert, no persistent key, audit in Rekor | Requires internet access (Sigstore) |
| **Key-based** | Offline, air-gapped compatible | Private key security (Vault mandatory) |

> 🔑 **2026 recommendation**: Keyless. Standardize on it for public/internal repos.

---

## 🚀 Cosign Quick Start

### Install
```bash
brew install cosign
# or
go install github.com/sigstore/cosign/v2/cmd/cosign@<VERSION>
```

### Keyless sign (GitHub Actions OIDC)
```yaml
# .github/workflows/release.yml
name: Build, Sign, Push

on:
  push:
    tags: ['v*']

permissions:
  id-token: write     # required for OIDC
  contents: read
  packages: write     # ghcr.io push

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      digest: ${{ steps.build.outputs.digest }}
    steps:
      - uses: actions/checkout@<VERSION>

      - uses: docker/login-action@<VERSION>
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - id: build
        uses: docker/build-push-action@<VERSION>
        with:
          push: true
          tags: ghcr.io/<ORG>/<APP>:${{ github.ref_name }}

      - uses: sigstore/cosign-installer@<VERSION>

      - name: Sign image (keyless)
        env:
          COSIGN_EXPERIMENTAL: "true"
        run: |
          cosign sign --yes \
            ghcr.io/<ORG>/<APP>@${{ steps.build.outputs.digest }}
```

→ The **cert** is obtained from GitHub OIDC, the signature gets recorded in Rekor (transparent log).

### Verify (CLI)
```bash
COSIGN_EXPERIMENTAL=1 cosign verify \
  --certificate-identity-regexp="https://github.com/<ORG>/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/<ORG>/<APP>:1.4.0
```

→ Output: signature valid, which GitHub Actions workflow signed it.

---

## 🛂 Cluster Admission — Kyverno

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signatures
spec:
  validationFailureAction: Enforce
  webhookTimeoutSeconds: 30
  rules:
    - name: verify-cosign
      match:
        any:
          - resources:
              kinds: [Pod]
      verifyImages:
        - imageReferences:
            - "ghcr.io/<ORG>/*"
          attestors:
            - entries:
                - keyless:
                    subject: "https://github.com/<ORG>/*"
                    issuer: "https://token.actions.githubusercontent.com"
          mutateDigest: true     # convert tag → digest
          required: true
```

→ Unsigned image deploy → **rejected**.

---

## 📦 Attestation — Metadata Signing

Signing alone isn't enough — sign the **metadata** too (SBOM, build provenance, scan):

```yaml
- name: Generate SBOM
  uses: anchore/sbom-action@<VERSION>
  with:
    image: ghcr.io/<ORG>/<APP>@${{ steps.build.outputs.digest }}
    format: cyclonedx-json
    output-file: sbom.json

- name: Sign + attest SBOM
  env:
    COSIGN_EXPERIMENTAL: "true"
  run: |
    cosign attest --yes \
      --predicate sbom.json \
      --type cyclonedx \
      ghcr.io/<ORG>/<APP>@${{ steps.build.outputs.digest }}
```

### Verify attestation
```bash
COSIGN_EXPERIMENTAL=1 cosign verify-attestation \
  --type cyclonedx \
  --certificate-identity-regexp="https://github.com/<ORG>/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/<ORG>/<APP>@<DIGEST>
```

---

## 🛡️ SLSA Provenance

SLSA L3 = it's verifiable "who produced this image, from which commit, with which build":

```yaml
provenance:
  permissions:
    id-token: write
    contents: read
    actions: read
    packages: write
  uses: slsa-framework/slsa-github-generator/.github/workflows/builder_container_slsa3.yml@<VERSION>
  with:
    image: ghcr.io/<ORG>/<APP>
    registry-username: ${{ github.actor }}
  secrets:
    registry-password: ${{ secrets.GITHUB_TOKEN }}
```

→ Image + SLSA provenance + SBOM — all attached + verify-able.

---

## 🔒 Key-Based (Air-Gapped Scenarios)

No internet / offline lab:
```bash
# Generate key pair
cosign generate-key-pair
# → cosign.key (private), cosign.pub (public)

# Sign
cosign sign --key cosign.key <REGISTRY>/<APP>:<TAG>

# Verify
cosign verify --key cosign.pub <REGISTRY>/<APP>:<TAG>
```

> 🔑 Keep `cosign.key` in a secure location (Vault, KMS). Compromise = all signatures could be forged.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| No signing | Attacker can push a fake image | cosign sign on every release |
| Tag-based deploy (`:latest`) | Tag is mutable | Digest pin |
| Key-based + key in Git | Compromise = total | Keyless OIDC or in Vault |
| Sign only, no attestation | No SBOM verify | cosign attest |
| No admission verify | Unsigned image enters the cluster | Kyverno verifyImages |
| `mutateDigest: false` | Tied to tag, mutable risk | `mutateDigest: true` |
| No internal registry, every image public | Compromise vector | Internal mirror + scan |
| Shared build runner | Side-channel | Ephemeral runner |
| Pinned action tag (`@v1`) | Tag is movable | SHA pin (`@a1b2c3...`) |
| Verify failure gets logged but accepted | Signature is meaningless | Enforce mode |

---

## 📋 Image Signing Checklist

```
[ ] CI: cosign sign on every release (keyless OIDC)
[ ] CI: SBOM generate (Syft / Trivy)
[ ] CI: SBOM cosign attest
[ ] CI: SLSA provenance generator
[ ] Cluster: Kyverno verifyImages enforce
[ ] mutateDigest: true (tag → digest)
[ ] Internal registry (ghcr / Harbor)
[ ] Pinned action SHA (auto-update via Renovate)
[ ] Build runner ephemeral
[ ] Verify CLI command in the runbook
[ ] Quarterly: signing pipeline drill (inject a fake image, was it caught?)
[ ] Documentation: how a new service signs
[ ] Admission failure → SIEM alert
```

---

## 📚 References

- **Sigstore Docs** — docs.sigstore.dev
- **Cosign** — github.com/sigstore/cosign
- **Rekor (transparent log)** — rekor.sigstore.dev
- **Fulcio (CA)** — github.com/sigstore/fulcio
- **SLSA** — slsa.dev
- **CycloneDX** — cyclonedx.org
- [`Dockerfile-Best-Practices.md`](Dockerfile-Best-Practices.md)
- [`08-Security/Container-Image-Scanning.md`](../08-Security/Container-Image-Scanning.md)
- [`08-Security/SLSA-and-SBOM.md`](../08-Security/SLSA-and-SBOM.md)
- [`08-Security/Policy-as-Code-OPA-Kyverno.md`](../08-Security/Policy-as-Code-OPA-Kyverno.md)
- [`17-Templates/kyverno-policies/`](../17-Templates/kyverno-policies/) — verify-image-signature.yaml

---

> *"Signing isn't 'paranoid security' — it's **the signature of the
> modern supply chain**. An unsigned image = an **anonymous
> package**: nobody knows who put it there, **opening it is risky**."*

---

> 🎓 **Learning Path:** This document is used as a "Read first" resource in the [`D4`](../22-Learning-Path/block-d-orchestration/D4-supply-chain.md) module.
