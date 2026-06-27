---
description: "Container imaj imzalamayi Cosign keyless OIDC ile production'da kurma: tehdit modeli, adimlar, GitHub Actions ve admission verification."
---
# Image Signing — Cosign + Keyless OIDC

> *"İmajını imzalamadan registry'ye push'lamak, 'kim koymuş bilemem'
> demektir. Saldırgan registry'ye **fake imaj** push'larsa, cluster
> nasıl ayırt eder? **Sadece imza** ayırt eder."*

Bu rehber container imaj imzalamayı — özellikle **Cosign keyless** —
production'da kurmak için somut adımları, GitHub Actions entegrasyonunu
ve admission verification'ı anlatır.

---

## 🎯 Niye Imzala?

### Tehdit
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

### Çözüm
- Build → **sign** with cosign
- Cluster admission → **verify signature**
- İmzasız imaj → **deploy reddedilir**

---

## 🔑 Keyless vs Key-Based

| Yöntem | Pro | Con |
|---|---|---|
| **Keyless** (OIDC) | Anlık cert, kalıcı key yok, audit Rekor'da | Internet erişimi gerek (Sigstore) |
| **Key-based** | Offline, air-gapped uyumlu | Private key güvenlik (Vault zorunlu) |

> 🔑 **2026 önerisi**: Keyless. Public/internal repo'larda standardize.

---

## 🚀 Cosign Quick Start

### Install
```bash
brew install cosign
# veya
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
  id-token: write     # OIDC için zorunlu
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

→ **Cert** GitHub OIDC'den alınır, imza Rekor (transparent log) kayıt olur.

### Verify (CLI)
```bash
COSIGN_EXPERIMENTAL=1 cosign verify \
  --certificate-identity-regexp="https://github.com/<ORG>/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/<ORG>/<APP>:1.4.0
```

→ Output: imza valid, hangi GitHub Actions workflow'u tarafından imzalandı.

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
          mutateDigest: true     # tag → digest dönüştür
          required: true
```

→ İmzasız imaj deploy → **reddedilir**.

---

## 📦 Attestation — Metadata Imza

İmza yetmez — **metadata** da imzala (SBOM, build provenance, scan):

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

SLSA L3 = "Bu imaj kim tarafından, hangi commit'ten, hangi build'le üretildi" doğrulanabilir:

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

→ İmaj + SLSA provenance + SBOM hepsi attached + verify-able.

---

## 🔒 Key-Based (Air-Gapped Senaryolar)

Internet yok / offline lab:
```bash
# Key pair üret
cosign generate-key-pair
# → cosign.key (private), cosign.pub (public)

# Sign
cosign sign --key cosign.key <REGISTRY>/<APP>:<TAG>

# Verify
cosign verify --key cosign.pub <REGISTRY>/<APP>:<TAG>
```

> 🔑 `cosign.key` güvenli yerde dur (Vault, KMS). Compromise = tüm imzalar sahte olabilir.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Imza yok | Saldırgan fake image push edebilir | cosign sign her release |
| Tag-based deploy (`:latest`) | Tag mutable | Digest pin |
| Key-based + key Git'te | Compromise = total | Keyless OIDC veya Vault'ta |
| Sadece sign, attestation yok | SBOM verify yok | cosign attest |
| Admission verify yok | İmzasız imaj cluster'a girer | Kyverno verifyImages |
| `mutateDigest: false` | Tag'e bağlı, mutable risk | `mutateDigest: true` |
| Internal registry yok, public her image | Compromise vektörü | Internal mirror + scan |
| Build runner paylaşımlı | Side-channel | Ephemeral runner |
| Pinned action tag (`@v1`) | Tag taşınabilir | SHA pin (`@a1b2c3...`) |
| Verify failure log'a düşer ama kabul edilir | Imza anlamsız | Enforce mode |

---

## 📋 Image Signing Checklist

```
[ ] CI: cosign sign her release (keyless OIDC)
[ ] CI: SBOM generate (Syft / Trivy)
[ ] CI: SBOM cosign attest
[ ] CI: SLSA provenance generator
[ ] Cluster: Kyverno verifyImages enforce
[ ] mutateDigest: true (tag → digest)
[ ] Internal registry (ghcr / Harbor)
[ ] Pinned action SHA (Renovate ile auto-update)
[ ] Build runner ephemeral
[ ] Verify CLI komutu runbook'ta
[ ] Quarterly: signing pipeline drill (fake imaj enjekte, yakalandı mı?)
[ ] Documentation: yeni servis nasıl sign eder
[ ] Admission failure → SIEM alert
```

---

## 📚 Referanslar

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

> *"İmza 'paranoyak güvenlik' değil — **modern supply chain'in
> imzasıdır**. İmzalanmamış imaj = **anonim koli**: kim koydu
> bilinmez, **açmak risklidir**."*
