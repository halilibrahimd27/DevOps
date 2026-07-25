---
description: "Design of a fail-fast but developer-friendly DevSecOps pipeline with security checks at every stage from pre-commit to runtime: shift-left and defense in depth."
tags:
  - Security
  - CI/CD
  - Containers
  - Policy as Code
---
# DevSecOps Pipeline — From Shift-Left to Runtime

> *"Security review at the very end, starting 2 weeks before deploy day"
> — that world is over. In 2026 security happens **on every commit**, continuously.*

Design of a **fail-fast** but developer-friendly pipeline with security
checks at every stage from pre-commit all the way to runtime.

---

## 🎯 Design principles

1. **Shift-left** — the earlier a problem is caught, the cheaper it is to fix
2. **Fail-fast** — critical findings break the pipeline
3. **Developer-friendly** — false-positive fatigue = a bypass culture
4. **Auditable** — every security decision is logged, who approved is clear
5. **Defense in depth** — a single defense is not enough, layer them

---

## 📊 Pipeline Stages

```
PRE-COMMIT  →  PR / CI  →  BUILD  →  DEPLOY  →  RUNTIME
   │            │            │          │          │
   │            │            │          │          └── Falco / Tetragon
   │            │            │          │              eBPF runtime
   │            │            │          │              audit log
   │            │            │          │
   │            │            │          └── Kyverno admission
   │            │            │              verify signature, policy gate
   │            │            │              least-privilege RBAC
   │            │            │
   │            │            └── Image vuln scan (Trivy)
   │            │                Signature (cosign)
   │            │                SBOM (syft)
   │            │
   │            └── SAST (Semgrep)
   │                SCA (OSV-Scanner)
   │                IaC scan (Checkov)
   │                Secret scan (gitleaks)
   │
   └── pre-commit hooks
       IDE plugin (Snyk/Semgrep)
```

---

## 1️⃣ Pre-commit (Developer machine)

**Goal:** catch the problem before a commit is even formed, while the developer is still at the keyboard.

### `.pre-commit-config.yaml`

```yaml
repos:
  # Format / lint
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-merge-conflict
      - id: check-added-large-files
        args: ['--maxkb=500']

  # Secret detection
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks

  # Python
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  # Terraform
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.92.0
    hooks:
      - id: terraform_fmt
      - id: terraform_tflint
      - id: terraform_trivy
        args:
          - --args=--severity HIGH,CRITICAL

  # YAML
  - repo: https://github.com/adrienverge/yamllint
    rev: v1.35.1
    hooks:
      - id: yamllint
```

```bash
# One-command setup (every developer)
pip install pre-commit
pre-commit install
pre-commit run --all-files     # check existing files
```

### IDE plugins (make them part of the default install)
- **VS Code:** Snyk Vulnerability Scanner, Semgrep
- **JetBrains:** Snyk, SonarLint
- **Vim/Neovim:** ALE + linter plugins

---

## 2️⃣ CI: When a PR Is Opened

### A. Secret Detection

```yaml
# .github/workflows/security.yml
name: Security

on:
  pull_request:
  push:
    branches: [main]

jobs:
  secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }}   # optional
```

> 🚨 **If a leak is found:** the PR is auto-blocked + a ticket is auto-opened
> for the service whose secret must be rotated. Just "delete the commit" is not enough —
> the secret was already in Git history, it counts as leaked.

### B. SAST (Static Application Security Testing)

```yaml
  sast:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: returntocorp/semgrep-action@v1
        with:
          config: >
            p/security-audit
            p/owasp-top-ten
            p/cwe-top-25
        env:
          SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
```

GitHub native: **CodeQL** (default-suite catches SQL injection, XSS, path traversal).

```yaml
  codeql:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript, python, go
      - uses: github/codeql-action/analyze@v3
```

### C. SCA (Software Composition Analysis)

CVE/license scanning for dependencies (3rd-party libraries).

```yaml
  sca:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: google/osv-scanner-action@<VERSION>
        with:
          scan-args: |-
            --recursive
            ./
```

Alternatives:
- **Trivy fs** — `trivy fs --scanners vuln,license .`
- **Snyk** — `snyk test --severity-threshold=high`
- **Dependabot** (GitHub native, opens PRs automatically)

### D. IaC Scan

For Terraform / CloudFormation / K8s YAML.

```yaml
  iac-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: bridgecrewio/checkov-action@master
        with:
          directory: terraform/
          quiet: true
          soft_fail: false
          framework: terraform
          output_format: sarif
          output_file_path: checkov.sarif
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with: { sarif_file: checkov.sarif }
```

Alternatives: KICS, `trivy config` (tfsec was consolidated into Trivy in 2023).

---

## 3️⃣ Build: Image Signing + SBOM + Vuln Scan

### Standard flow

```yaml
build-and-sign:
  needs: [secrets, sast, sca, iac-scan]
  uses: <ORG>/<REPO>/.github/workflows/docker-build-push.yml@main
  with:
    image-name: <APP_NAME>
  secrets: inherit
  permissions:
    contents: read
    id-token: write       # cosign keyless OIDC
    packages: write
```

(Full template: [`17-Templates/github-actions/docker-build-push.yml`](../17-Templates/github-actions/docker-build-push.yml))

This workflow:
- ✅ Multi-platform build (amd64 + arm64)
- ✅ BuildKit cache (fast)
- ✅ Trivy vulnerability scan (CRITICAL/HIGH fail)
- ✅ Cosign keyless OIDC signing
- ✅ SBOM generation (CycloneDX)
- ✅ SBOM as cosign attestation (verifiable in-cluster)
- ✅ SARIF upload (shows up in the GitHub Security tab)

---

## 4️⃣ Deploy: Admission Control

### With Kyverno

Guarantee that only secure images get deployed to the cluster.

```yaml
# Kyverno ClusterPolicy — signed images only
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-signature
spec:
  validationFailureAction: Enforce
  rules:
    - name: verify-cosign
      match:
        any: [{ resources: { kinds: [Pod] } }]
      verifyImages:
        - imageReferences: ["ghcr.io/<ORG>/*"]
          attestors:
            - entries:
                - keyless:
                    subject: "https://github.com/<ORG>/*"
                    issuer: "https://token.actions.githubusercontent.com"
          mutateDigest: true
          required: true
```

Full set: [`17-Templates/kyverno-policies/`](../17-Templates/kyverno-policies/README.md)

### Pod Security Standards

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: <NS>
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
```

The `restricted` profile automatically blocks:
- runAsRoot
- privileged containers
- hostNetwork/hostPID
- privilege escalation
- writable root filesystem (the vast majority)

---

## 5️⃣ Runtime: Continuous Monitoring

### Falco — eBPF-based runtime threat detection

```yaml
# Helm install
helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  --set tty=true \
  --set falcosidekick.enabled=true \
  --set falcosidekick.config.slack.webhookurl=<SLACK_WEBHOOK>
```

Catches with canonical rules:
- Interactive shell entry into a container
- Reading a sensitive file (`/etc/shadow`, `/etc/passwd`)
- Privilege escalation attempt
- Outbound connection to an unexpected IP

### Tetragon (eBPF, a more modern alternative)

```bash
# From the Cilium project, kernel-level observability
helm install tetragon cilium/tetragon -n kube-system
```

### Audit log

API server audit log into a central logging system:

```yaml
# kube-apiserver audit policy (example)
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: Metadata
    omitStages:
      - RequestReceived
  - level: RequestResponse
    verbs: ["create", "update", "patch", "delete"]
    resources:
      - group: ""
        resources: ["secrets", "configmaps"]
```

---

## 🛡️ Threat Model — Minimum control set

| Attack type | Defense in the pipeline |
|---|---|
| Hardcoded credential | gitleaks (pre-commit + CI) |
| Vulnerable dependency | OSV-Scanner, Trivy fs, Dependabot |
| Code-level vulnerability (XSS, SQLi) | Semgrep, CodeQL |
| Misconfigured IaC (open S3, weak SG) | Checkov, tfsec, KICS |
| Vulnerable container base image | Trivy image scan, Chainguard images |
| Tampered/replaced image | Cosign signature verification (Kyverno) |
| Supply chain (compromised dep, build) | SBOM, SLSA provenance, hermetic build |
| Privilege escalation in cluster | PSS restricted, NetworkPolicy, Kyverno |
| Runtime exploit | Falco / Tetragon, audit log |
| Lateral movement | NetworkPolicy default-deny, mesh mTLS |

---

## 📈 Metrics — Is the pipeline healthy?

Track:
- **MTTR for critical CVEs** — how many days from a new CVE to fixed in prod?
- **% of builds blocked by security gate** — is the pipeline working? (too high: too strict; too low: too loose)
- **% of images signed and verified** — target 100%
- **Time from PR open to merge** — security scanning must not slow it down (target < 10 min)
- **False positive rate** — the developer-tolerance balance

---

## ⚠️ Anti-patterns

- ❌ "Security review at the very last stage" — late is expensive
- ❌ Dependence on a single tool — no defense in depth
- ❌ Scanning that drowns you in false positives — developers build an "ignore" reflex
- ❌ Security exists in the pipeline but **bypass authority** sits with every team lead — bypass goes mainstream
- ❌ "We'll show it at the audit" style logging — visible but never actually used
- ❌ No severity threshold — if `LOW` also fails you, you lose the team
- ❌ No runtime monitoring — everything that got through the pipeline is assumed safe

---

## 🎯 12-Week Adoption Plan

| Week | To do |
|---|---|
| 1-2 | pre-commit + secret detection + IDE plugins |
| 3-4 | SAST (Semgrep / CodeQL) into the PR pipeline |
| 5-6 | SCA (OSV-Scanner) + Dependabot automation |
| 7-8 | IaC scan (Checkov) on PRs; block violations |
| 9-10 | Cosign signing + Kyverno verify policy |
| 11 | Falco/Tetragon runtime monitoring |
| 12 | Threat model + audit log + metric dashboard |

---

## 📋 Checklist

Before going to production, check every line — if one is missing, the pipeline is not complete.

**Pre-commit**
- [ ] `pre-commit install` runs for everyone who clones the repo (a required step in CONTRIBUTING).
- [ ] gitleaks pre-commit hook is active; it stops a secret commit locally.
- [ ] IDE plugins (Snyk/Semgrep/SonarLint) are included in the standard install image.

**CI / PR**
- [ ] The gitleaks CI job blocks the PR when a leak is found and opens a secret-rotation ticket.
- [ ] SAST (Semgrep + CodeQL) runs for at least javascript/python/go.
- [ ] SCA (OSV-Scanner or Trivy fs) + Dependabot is active, license scanning is on.
- [ ] IaC scan (Checkov) with `soft_fail: false` blocks HIGH/CRITICAL violations.
- [ ] All SARIF outputs are uploaded to the GitHub Security tab.
- [ ] A severity threshold is defined: LOW findings do NOT BREAK the pipeline (only reported).

**Build**
- [ ] Trivy image scan fails the build on a CRITICAL/HIGH finding.
- [ ] Every image is signed with Cosign keyless OIDC (`id-token: write` permission present).
- [ ] SBOM (CycloneDX) is produced and attached to the image as a cosign attestation.
- [ ] Base image is minimal/distroless (e.g. Chainguard) and regularly updated.

**Deploy / Admission**
- [ ] Kyverno `verify-signature` policy is in `validationFailureAction: Enforce` mode.
- [ ] An unsigned or unverifiable image cannot enter the cluster (tested).
- [ ] Pod Security Standards `restricted` is enforced on namespaces.
- [ ] NetworkPolicy default-deny is defined; only necessary traffic is open.
- [ ] Bypass authority is with a limited set of people and every bypass lands in the audit log.

**Runtime**
- [ ] Falco or Tetragon is running; alerts go to a channel (Slack/SIEM).
- [ ] The kube-apiserver audit log flows to a central logging system and is retained.
- [ ] Every attack type in the threat-model table has at least one active control.
- [ ] Metrics (signed image %, CVE MTTR, gate block %) are watched on a dashboard.

---

## 📚 Continue

- [OWASP DevSecOps Guideline](https://owasp.org/www-project-devsecops-guideline/)
- [SLSA framework](https://slsa.dev)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [Sigstore documentation](https://docs.sigstore.dev)
- [`17-Templates/kyverno-policies/`](../17-Templates/kyverno-policies/README.md) — ready-made policies

---

## 📚 References

- [`SLSA-and-SBOM.md`](SLSA-and-SBOM.md) — supply chain provenance, SBOM and attestation in depth.
- [`Container-Image-Scanning.md`](Container-Image-Scanning.md) — Trivy/image scanning and base image selection.
- [`Policy-as-Code-OPA-Kyverno.md`](Policy-as-Code-OPA-Kyverno.md) — admission control and Kyverno policy details.
- [`Runtime-Security.md`](Runtime-Security.md) — Falco/Tetragon and eBPF runtime defense.
- [`Threat-Modeling.md`](Threat-Modeling.md) — systematically deriving the attack surface.
- [SLSA framework](https://slsa.dev) — supply chain integrity levels (official).

---

> *"DevSecOps is not 'the security team's job' but the gates baked into the pipeline: an unsigned image, an unscanned dependency, and a policy-less cluster go to red, not to prod."*

---

> 🎓 **Learning Path:** This document is used as a "Read first" resource in the [`D4`](../22-Learning-Path/block-d-orchestration/D4-supply-chain.md) module.
