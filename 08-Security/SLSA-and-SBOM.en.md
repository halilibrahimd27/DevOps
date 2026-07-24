---
description: "Software supply chain security: SLSA levels, SBOM, provenance and attestation; defense against xz-utils-style attacks with Sigstore/cosign/Rekor."
tags:
  - Security
  - SBOM
  - CI/CD
  - Compliance
---
# SLSA & SBOM — Supply Chain Integrity

> *"The code is yours, the dependencies are other people's, the build is CI's, the runtime is the
> cluster's. If one of them gets tampered with, **who's to blame**? If you don't have an answer,
> you don't have a supply chain."*

SolarWinds (2020), Codecov (2021), Log4Shell (2021), xz-utils (2024) —
attacks no longer target the **source code**, they target the **supply chain**. This
guide explains how you defend against that with SLSA and SBOM.

---

## 🎯 Core Concepts

| Term | Meaning | Why it matters |
|---|---|---|
| **Supply chain** | The Source → Build → Package → Deploy → Run chain | Every link is an attack vector |
| **SBOM** (Software Bill of Materials) | A list of "what's inside this artifact" | When a new CVE drops, find the affected ones in 5 minutes |
| **SLSA** (Supply-chain Levels for Software Artifacts) | Build pipeline security levels (L1-L4) | Consistent, auditable builds |
| **Provenance** | "Who produced this artifact, when, from which commit, in which build" | Makes forgery impossible |
| **Attestation** | A signed metadata claim | Provenance + scan + license info |
| **in-toto** | The attestation framework standard | The format SLSA runs on top of |
| **Sigstore** | Open source signing infrastructure | cosign, Rekor, Fulcio |
| **Cosign** | Container/artifact signing tool | A real "signature" via keyless OIDC |
| **Rekor** | Transparent log (immutable) | The audit ledger of everything signed |
| **Fulcio** | Short-lived cert authority | OIDC → short-lived cert |

---

## 🪜 SLSA Levels

| Level | Goal | Controls |
|---|---|---|
| **L0** | No guarantees at all | — |
| **L1** | Build procedure documented | CI script in Git, manual or automated |
| **L2** | Hosted build platform + version control + signed provenance | GitHub Actions / GitLab CI + ephemeral runner |
| **L3** | Hardened build, isolated, source-to-build verified | Reusable workflow + non-falsifiable provenance |
| **L4** *(deprecated in v1.0, planned for v1.1)* | Two independent reviewers + hermetic build | Bazel-style hermetic build |

> 🔑 **Practical goal (2026):** For most organizations **SLSA L2-L3** is reachable
> and useful. L4 hermetic build is very extreme.

---

## 📦 SBOM — "Software Bill of Materials"

### Formats

| Format | Sponsor | Usage |
|---|---|---|
| **CycloneDX** | OWASP | Industry standard, Trivy default |
| **SPDX** | Linux Foundation | Compliance, license-focused |
| **SWID Tags** | NIST | Weak adoption |

> **Practical:** Produce both. Trivy supports `--format cyclonedx` and `--format spdx-json`.

### Why do you need it?
1. **CVE response time:** When a Log4Shell-style CVE drops, saying "I have 47 affected services" takes 30 minutes → with SBOM, 30 seconds.
2. **Compliance:** US Executive Order 14028 (federal software), EU Cyber Resilience Act (2024) — SBOM is mandatory.
3. **License audit:** GPL contamination, commercial violation.
4. **Vendor management:** Knowing what a supplier's software contains.

### SBOM generation
```bash
# Syft (Anchore)
syft <REGISTRY>/<APP>:<TAG> -o cyclonedx-json > sbom.json
syft dir:. -o spdx-json > sbom-spdx.json

# Trivy
trivy image --format cyclonedx -o sbom.json <IMAGE>
trivy image --format spdx-json -o sbom-spdx.json <IMAGE>

# Docker built-in (Buildx)
docker buildx build --sbom=true --provenance=true -t <APP> .
```

### Where do you put the SBOM?
- ✅ **Attached attestation in the container registry** (cosign attest)
- ✅ Release artifact (GitHub Releases attachment)
- ✅ Internal SBOM database (Dependency-Track, OWASP)
- ❌ CI artifact only — deleted after 90 days, gone when you need it

### SBOM diff: what changed in the dependencies?
```bash
# Difference between two versions of the same image
sbom-diff sbom-v1.json sbom-v2.json

# CycloneDX CLI
cyclonedx diff sbom-v1.json sbom-v2.json
```

Comment the SBOM diff on the PR → "this new dep was added, why?" automatic review.

---

## ✍️ Signing with Cosign

### Keyless signing (recommended, 2026 standard)
Traditional: a permanent private key sits somewhere (risky). **Keyless**: get an **instant** cert via GitHub OIDC, sign, the cert is discarded → logged to Rekor.

```yaml
# .github/workflows/release.yml
permissions:
  id-token: write     # for OIDC
  contents: read
  packages: write

jobs:
  build-sign:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>

      - uses: docker/login-action@<VERSION>
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/build-push-action@<VERSION>
        id: build
        with:
          tags: ghcr.io/<ORG>/<APP>:${{ github.sha }}
          push: true

      - name: Install cosign
        uses: sigstore/cosign-installer@<VERSION>

      - name: Sign image (keyless)
        env:
          COSIGN_EXPERIMENTAL: "true"
        run: |
          cosign sign --yes \
            ghcr.io/<ORG>/<APP>@${{ steps.build.outputs.digest }}

      - name: Generate + sign SBOM attestation
        run: |
          syft ghcr.io/<ORG>/<APP>@${{ steps.build.outputs.digest }} \
            -o cyclonedx-json > sbom.json
          cosign attest --yes \
            --predicate sbom.json \
            --type cyclonedx \
            ghcr.io/<ORG>/<APP>@${{ steps.build.outputs.digest }}

      - name: Generate + sign SLSA provenance
        uses: slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@<VERSION>
        with:
          image: ghcr.io/<ORG>/<APP>
          digest: ${{ steps.build.outputs.digest }}
```

### Verify
```bash
# Public verify (searches in Sigstore Rekor)
COSIGN_EXPERIMENTAL=1 cosign verify \
  --certificate-identity-regexp="https://github.com/<ORG>/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/<ORG>/<APP>:<TAG>

# SBOM attestation
COSIGN_EXPERIMENTAL=1 cosign verify-attestation \
  --type cyclonedx \
  --certificate-identity-regexp="https://github.com/<ORG>/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/<ORG>/<APP>@<DIGEST>
```

### Key-based signing (multi-cloud, no IdP)
```bash
cosign generate-key-pair          # cosign.key + cosign.pub
cosign sign --key cosign.key <IMAGE>
cosign verify --key cosign.pub <IMAGE>
```

> ⚠️ Key-based: keep the private key in a secure place (Vault, KMS). Keyless is preferred.

---

## 🛂 SLSA L3 Provenance — Non-Falsifiable Build

SLSA L3 means: "Which commit, which runner, and which flags you built this artifact with is **not falsifiable**." That is, an attacker can't forge the provenance.

### slsa-github-generator
```yaml
# Container build via reusable workflow
jobs:
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

Output: SLSA provenance attached as a cosign attestation:
```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "predicateType": "https://slsa.dev/provenance/v1",
  "subject": [{"name": "ghcr.io/<ORG>/<APP>", "digest": {"sha256": "..."}}],
  "predicate": {
    "buildDefinition": {
      "buildType": "https://slsa.dev/container-based-build/v0.1?draft",
      "externalParameters": {
        "source": {"uri": "git+https://github.com/<ORG>/<REPO>@refs/tags/v1.2.3"},
        "configPath": ".github/workflows/release.yml"
      }
    },
    "runDetails": {
      "builder": {"id": "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/..."},
      "metadata": {"invocationId": "...", "startedOn": "2026-05-04T15:42:00Z"}
    }
  }
}
```

---

## 🚧 Admission: Reject Any Image That Isn't Signed + SLSA Provenance

### Kyverno: signed + provenance verify
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-slsa-provenance
spec:
  validationFailureAction: Enforce
  webhookTimeoutSeconds: 30
  rules:
    - name: verify-cosign-and-slsa
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
          attestations:
            - predicateType: https://slsa.dev/provenance/v1
              attestors:
                - entries:
                    - keyless:
                        subject: "https://github.com/slsa-framework/*"
                        issuer: "https://token.actions.githubusercontent.com"
```

---

## 🧬 Dependency Graph + Vulnerability Tracking

### OWASP Dependency-Track
Self-hosted SBOM repository + CVE tracking. When a new CVE is disclosed, it automatically notifies every affected service.

```bash
# Minimal setup with docker-compose
docker run -d --name dtrack-apiserver \
  -p 8080:8080 \
  dependencytrack/apiserver

docker run -d --name dtrack-frontend \
  -p 8081:8080 \
  dependencytrack/frontend
```

SBOM upload in CI:
```bash
curl -X POST "https://<DTRACK>/api/v1/bom" \
  -H "X-API-Key: <KEY>" \
  -H "Content-Type: application/json" \
  -d "{
    \"projectName\": \"<APP>\",
    \"projectVersion\": \"<VERSION>\",
    \"bom\": \"$(base64 -w0 sbom.json)\"
  }"
```

### GitHub Dependency Graph
Native, free, available for public/private repos. Integrated with Dependabot.

---

## 🔬 Bonus: Reproducible Builds

> "From the same source code, with the same build environment, a **bit-for-bit identical** binary."

This is the strictest supply chain trust. If an attacker injects something during the build, the second build comes out different → it gets detected.

### For containers
- **Buildkit**: normalize the timestamp with `--build-arg SOURCE_DATE_EPOCH`
- **Bazel**: hermetic build native
- **Nix**: fully reproducible

```dockerfile
# Deterministic timestamp with SOURCE_DATE_EPOCH
ARG SOURCE_DATE_EPOCH
ENV SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH}
```

```bash
# Same SHA, two different runners, same output digest
SOURCE_DATE_EPOCH=$(git log -1 --pretty=%ct) docker buildx build ...
```

> For most organizations reproducible build is "nice-to-have". L3 is enough; if L4 is the goal, yes.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| No SBOM | On a new CVE there's no answer to "are we affected?" | SBOM on every build, attached in the registry |
| SBOM as a CI artifact, 90-day TTL | Deleted right when you need it | Cosign attest, persistent in the registry |
| No image signing | Attacker pushes a fake image to the registry | cosign sign + admission verify |
| Key-based signing, key in a single place | Compromise → all signatures forgeable | Keyless OIDC, ephemeral cert |
| No provenance, "I built it" | Falsifiable | slsa-github-generator |
| No Dependabot/Renovate | Old dep → CVEs pile up | Automatic PR + auto-merge minor |
| `npm install` registry not mirrored | Upstream takedown → build breaks | Internal artifact mirror (Artifactory, Nexus, GHA cache) |
| Build runner self-hosted **shared** | Side-channel attack | Ephemeral runner, fresh VM per job |
| `curl | bash` install | Compromise → RCE for everyone | Pinned version + checksum |
| `RUN apt-get update` cache cooked | No reproducibility | Hermetic build or `apt-mark hold` |
| GHA `@main` or `@v1` | Tag is mutable, movable | SHA pin: `@a1b2c3d4...` |

---

## 📋 Supply Chain Hygiene Checklist

```
[ ] Build only via reusable workflows (not through PRs)
[ ] GHA actions SHA-pinned (kept current with Renovate / dependabot)
[ ] Build runner ephemeral (fresh VM per job)
[ ] Source: protected branch + signed commits + 2-reviewer
[ ] Dependency: Renovate / Dependabot, CVE auto-PR
[ ] Lock file (package-lock.json, go.sum, Pipfile.lock) committed
[ ] In CI: SAST (Semgrep/CodeQL), SCA (Trivy/OSV-Scanner)
[ ] Container build: Buildkit, multi-stage, distroless/Chainguard
[ ] SBOM: CycloneDX + SPDX, cosign attest to the registry
[ ] Image sign: cosign keyless (GitHub OIDC)
[ ] SLSA provenance: slsa-github-generator
[ ] Admission: Kyverno verifyImages + verify provenance
[ ] SBOM repository: Dependency-Track (or equivalent)
[ ] CVE alerting: new CVE → affected-service list automatically
[ ] Internal mirror: package registry, container registry (cached)
[ ] Quarterly: supply chain review, attack surface map updated
[ ] Drill: inject a "fake dep" — does the pipeline catch it?
```

---

## 📚 References

- **SLSA Spec** — slsa.dev
- **Sigstore Docs** — docs.sigstore.dev
- **CycloneDX** — cyclonedx.org
- **SPDX** — spdx.dev
- **OWASP Dependency-Track** — dependencytrack.org
- **NIST SSDF** (Secure Software Development Framework)
- **EU Cyber Resilience Act** — 2024 in force, 2027 full application
- **Executive Order 14028** — US federal software SBOM mandate
- [`Container-Image-Scanning.md`](Container-Image-Scanning.md)
- [`Kubernetes-Hardening.md`](Kubernetes-Hardening.md) — admission gating
- [`19-Compliance/`](../19-Compliance/) (Phase 4) — legal framework

---

> *"You write the code, but the image is 50 million lines of other people's code.
> SBOM is the **visibility** of the supply chain; SLSA is its **integrity**;
> without both, modern production can't answer the question 'how do we trust this?'"*
