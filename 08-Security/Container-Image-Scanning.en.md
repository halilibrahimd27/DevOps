---
description: "A shift-left container image scanning guide built around Trivy: OS/language CVEs, IaC misconfig, secret and SBOM scanning; from CI gate to admission and runtime drift."
tags:
  - Security
  - Containers
  - SBOM
  - CI/CD
---
# Container Image Scanning — Keeping CVEs Out of Production

> *"Rather than finding the CVE in prod, keep it out of prod — 1000x
> cheaper, 100x faster, 0 oncall."*

Image scanning is the gatekeeper of **shift-left** security. This guide
builds a modern scanning flow around Trivy: pre-build → CI gate → registry
scan → admission → runtime drift.

---

## 🎯 Types of Scanning

| Scan type | What it checks | Tool |
|---|---|---|
| **OS package CVE** | apk/apt/yum package versions and CVEs | Trivy, Grype, Snyk |
| **Language deps (SCA)** | npm, pip, Maven, Go modules CVEs | Trivy, OSV-Scanner, Snyk |
| **Misconfig (IaC)** | Dockerfile, K8s, Terraform | Trivy, Checkov, KICS |
| **Secrets** | Hardcoded secrets in image layers | Trivy, gitleaks |
| **License** | GPL contamination, commercial-violation risk | Trivy, FOSSA, Snyk |
| **Malware** | Trojans, crypto miners | ClamAV, Cloudsmith Quarantine |
| **SBOM** | Software bill of materials (generation) | Syft, Trivy SBOM |

---

## 🔧 Trivy: One Command, Multiple Scans

Aqua Security Trivy is the most widely used **open source** scanner in 2026. Fast, network-independent, with excellent CI/CD and K8s integration.

### Local usage
```bash
# Image scan
trivy image <REGISTRY>/<APP>:<TAG>

# Only CRITICAL/HIGH
trivy image --severity CRITICAL,HIGH <REGISTRY>/<APP>:<TAG>

# Ignore CVEs with no fix (empty noise)
trivy image --ignore-unfixed <REGISTRY>/<APP>:<TAG>

# JSON output (for CI parsing)
trivy image --format json -o trivy.json <REGISTRY>/<APP>:<TAG>

# SARIF output (for the GitHub Security tab)
trivy image --format sarif -o trivy.sarif <REGISTRY>/<APP>:<TAG>

# Filesystem scan (before writing the Dockerfile)
trivy fs --scanners vuln,secret,config .

# K8s manifest scan
trivy config k8s/

# Scan of a running cluster
trivy k8s --report summary cluster
```

### Cache + offline mode
In air-gapped environments, download the DB ahead of time:
```bash
trivy image --download-db-only
trivy image --skip-db-update --offline-scan <IMAGE>
```

---

## 🚦 CI Gate: Severity Thresholds

> 🔑 **Philosophy:** "Zero CVEs" isn't realistic. What matters is drawing
> the line between **CRITICAL/HIGH with a fix** and noise **you can't fix anyway**.

### Example policy
| Severity | Fix available? | CI behavior |
|---|---|---|
| CRITICAL | YES | **Fail** (no deploy) |
| CRITICAL | NO | Warn, passes with an exception |
| HIGH | YES | **Fail** (default) |
| HIGH | NO | Warn |
| MEDIUM | * | Report only, don't fail |
| LOW | * | Ignore |

### GitHub Actions
```yaml
name: Image Security Scan

on:
  pull_request:
    paths: ['Dockerfile', 'src/**', 'package*.json', 'go.sum']

permissions:
  contents: read
  security-events: write   # for SARIF upload

jobs:
  trivy-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>

      - name: Build image
        run: docker build -t <APP>:${{ github.sha }} .

      - name: Trivy scan (fail on CRITICAL/HIGH with fix)
        uses: aquasecurity/trivy-action@<VERSION>
        with:
          image-ref: <APP>:${{ github.sha }}
          format: sarif
          output: trivy.sarif
          severity: CRITICAL,HIGH
          exit-code: 1
          ignore-unfixed: true
          vuln-type: 'os,library'

      - name: Upload SARIF to GitHub Security tab
        if: always()
        uses: github/codeql-action/upload-sarif@<VERSION>
        with:
          sarif_file: trivy.sarif

      - name: Trivy SBOM (CycloneDX)
        uses: aquasecurity/trivy-action@<VERSION>
        with:
          image-ref: <APP>:${{ github.sha }}
          format: cyclonedx
          output: sbom.json

      - name: Upload SBOM as artifact
        uses: actions/upload-artifact@<VERSION>
        with:
          name: sbom
          path: sbom.json
```

### Exceptions: `.trivyignore`
Some CVEs get accepted (false positive, not exploitable, no fix):
```
# .trivyignore
CVE-2024-12345    # base image alpine glibc, no exploit for us
CVE-2025-67890 exp:2026-09-01    # 6-month exception
```

> ⚠️ Every ignore line must **have an owner + a reason in the comment**. Check it during PR review.

---

## 🏗️ Build-Time Best Practices (Don't Let the CVE In, In the First Place)

### 1. Distroless / minimal base image
```dockerfile
# ❌ debian:latest → 800+ packages, 1500+ CVEs
FROM debian:latest

# ✅ distroless/static → 0 shell, ~10 packages
FROM gcr.io/distroless/static-debian12:nonroot
COPY app /app
USER nonroot:nonroot
ENTRYPOINT ["/app"]
```

### 2. Chainguard / Wolfi
**2026 recommendation**: Chainguard Images (Wolfi base) — almost 0 CVEs, daily rebuild.

```dockerfile
FROM cgr.dev/chainguard/static:latest
COPY app /app
ENTRYPOINT ["/app"]
```

### 3. Multi-stage build
```dockerfile
# Builder
FROM golang:1.23 AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /app .

# Runtime: minimal
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /app /app
USER nonroot
ENTRYPOINT ["/app"]
```

> The final image contains **no build tools** → the SCA target surface shrinks.

### 4. Aggressive `.dockerignore`
```
.git/
.github/
.env
.env.*
*.pem
node_modules/
__pycache__/
.venv/
```
Otherwise `COPY . .` drags secrets/junk into the image.

### 5. Pin everything
```dockerfile
FROM golang:1.23.4-alpine3.20 AS builder    # ✅ digest tag
FROM golang:1.23-alpine                      # ⚠️ minor version can change
FROM golang:latest                           # ❌ never
FROM golang@sha256:abc123...                 # ✅✅ digest pin
```

### 6. Non-root user
```dockerfile
RUN addgroup -S app && adduser -S -G app app
USER app
```

---

## 📦 Registry-Side Scanning

### Docker Hub / GHCR / Quay
- **GitHub Container Registry**: native Trivy integration, `Security` tab
- **Quay.io**: Clair-based, automatic scan
- **Harbor** (self-hosted): via the Trivy adapter
- **AWS ECR**: Inspector integration
- **GCP Artifact Registry**: Container Analysis API

### Harbor + Trivy integration
```yaml
# Harbor project setting: "Automatically scan images on push"
# Retag/replication rule via webhook:
# - Trigger: vulnerability scan completed
# - Endpoint: Slack / SIEM
```

---

## 🛡️ Admission-Time: Image Verification (Kyverno)

A CVE-laden image may well be sitting in the registry; the cluster must **not deploy it**.

### Verify image signature (cosign)
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
            - "<REGISTRY>/*"
          attestors:
            - entries:
                - keyless:
                    subject: "https://github.com/<ORG>/*"
                    issuer: "https://token.actions.githubusercontent.com"
```

### Disallowed tag/registry
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-image-registries
spec:
  validationFailureAction: Enforce
  rules:
    - name: only-trusted-registries
      match:
        any:
          - resources:
              kinds: [Pod]
      validate:
        message: "Only <REGISTRY> and gcr.io/distroless are allowed"
        pattern:
          spec:
            containers:
              - image: "<REGISTRY>/* | gcr.io/distroless/*"
```

Ready-made templates: [`17-Templates/kyverno-policies/`](../17-Templates/kyverno-policies/README.md).

---

## 🧰 Alternative Tools — Comparison

| Tool | Type | License | Strength | Weakness |
|---|---|---|---|---|
| **Trivy** | CLI + K8s operator | Apache 2 | Speed, multi-scan, OSS | Vendor data sometimes lags |
| **Grype** | CLI | Apache 2 | Integrates with the Anchore SBOM stack | No UI |
| **Snyk** | SaaS + CLI | Commercial (free tier) | Good UI, IDE plugin | Paid, vendor lock-in |
| **Anchore Enterprise** | Self-hosted | Commercial | Policy-as-code, compliance reporting | Setup overhead |
| **Aqua Enterprise** | SaaS + on-prem | Commercial | Integrated runtime + admission | High cost |
| **Sysdig Secure** | SaaS | Commercial | Runtime + admission + IR | Pricey |
| **Clair** | Library | Apache 2 | Integrates with Quay/Harbor | Not a CLI, integration-only |
| **Docker Scout** | Docker Desktop | Free + paid | Docker Hub integration | Actively evolving |

> 🔑 **Practical recommendation (2026):**
> - OSS / startup → **Trivy**
> - Compliance-heavy enterprise → **Anchore Enterprise** or **Aqua**
> - Dev-ergonomics-first → **Snyk** (IDE plugin)

---

## 🔄 Continuous Re-Scan: Drift Detection

The image was clean 6 months ago, **a new CVE got disclosed** — nobody notices.

### Trivy Operator (K8s)
Periodically scans all images in the cluster:
```bash
helm install trivy-operator aqua/trivy-operator \
  -n trivy-system --create-namespace \
  --set "trivy.severity=CRITICAL,HIGH" \
  --set "operator.scanJobTimeout=10m"
```

```yaml
# VulnerabilityReport CR is created automatically
apiVersion: aquasecurity.github.io/v1alpha1
kind: VulnerabilityReport
# kubectl get vulnerabilityreports -A
```

Prometheus exporter → Grafana dashboard:
```
trivy_vulnerabilities_total{severity="CRITICAL", namespace="<NS>"}
```

### Alert: when a new CRITICAL CVE is found
```yaml
groups:
  - name: container-security
    rules:
      - alert: NewCriticalCVEInProduction
        expr: |
          increase(trivy_vulnerabilities_total{severity="CRITICAL"}[1h]) > 0
        for: 5m
        labels:
          severity: page
        annotations:
          summary: "New CRITICAL CVE: {{ $labels.image }}"
          runbook: "<RUNBOOK_URL>/cve-response"
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| `FROM debian:latest` | Broad package set → many CVEs | distroless / Chainguard |
| `FROM image:latest` | No reproducibility | Digest pin |
| Scan only on the release branch | Developers merge CVEs without noticing | On every PR |
| "Make MEDIUM/LOW fail too" | Empty noise, the team starts ignoring it | CRITICAL+HIGH+fix-available |
| `.trivyignore` with no comment | Why it was ignored gets forgotten | Comment + owner + expiry |
| No image scan, "we'll catch it at runtime" | Falco is late-stage, expensive | Both build-time and runtime |
| Scan result dumped to Slack and forgotten | Nobody follows up | An issue auto-opens + an owner is assigned |
| Never cross-checking vendor scan against OSS scan | Which one do you trust? | Run both, false positives drop |
| `apk add --no-cache curl wget vim` in the Dockerfile | Attack surface grows | Only packages the runtime actually needs |
| `USER root` (or missing) | RCE → close to the host | `USER nonroot` + `runAsNonRoot:true` |

---

## 📋 Image Security Checklist

```
[ ] All base images are minimal/distroless
[ ] Multi-stage build, NO build tools in the runtime image
[ ] Digest pin (sha256:...) on critical images
[ ] Aggressive .dockerignore, no secrets
[ ] USER nonroot, no exceptions for root
[ ] CI: Trivy scan on every PR
[ ] Exit code: CRITICAL/HIGH+fix-available → fail
[ ] SARIF uploaded to the GitHub Security tab
[ ] SBOM produced on every build (CycloneDX/SPDX)
[ ] Signed with Cosign (keyless OIDC)
[ ] Kyverno verifyImages enforces it
[ ] Only allow-listed registries can deploy
[ ] :latest tag banned (Kyverno disallow-latest-tag)
[ ] Trivy operator periodically scans the cluster
[ ] CVE alert → Slack + Issue auto-create
[ ] .trivyignore lines have an owner + an expiry
[ ] Quarterly base image updates (automated via dependabot/renovate)
```

---

## 📚 References

- **Trivy Docs** — aquasec.github.io/trivy
- **Chainguard Images** — chainguard.dev/chainguard-images
- **NIST SP 800-190** — Application Container Security Guide
- **CIS Docker Benchmark v1.7**
- [`Kubernetes-Hardening.md`](Kubernetes-Hardening.md) — admission policy
- [`SLSA-and-SBOM.md`](SLSA-and-SBOM.md) — supply chain integrity
- [`04-Containers/Dockerfile-Best-Practices.md`](../04-Containers/Dockerfile-Best-Practices.md)
- [`17-Templates/dockerfiles/`](../17-Templates/dockerfiles/README.md) — minimal Dockerfile templates

---

> *"A CVE was found" doesn't mean "it's exploitable"; but using a
> scalable filter to focus on the ones **likely to be
> exploitable** — the one buffer that lets the security team sleep."*

---

> 🎓 **Learning Path:** This document is used as a "Read first" resource in the [`D4`](../22-Learning-Path/block-d-orchestration/D4-supply-chain.md) module.
