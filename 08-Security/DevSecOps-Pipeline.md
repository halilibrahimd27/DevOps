# DevSecOps Pipeline — Shift-Left'ten Runtime'a

> *"Security review en sonda, deploy gününden 2 hafta önce başlar"
> dünyası bitti. 2026'da güvenlik **her commit'te**, sürekli.*

Pre-commit'ten runtime'a kadar her aşamada güvenlik kontrolü olan,
**fail-fast** ama developer-friendly bir pipeline tasarımı.

---

## 🎯 Tasarım prensipleri

1. **Shift-left** — sorun ne kadar erken yakalanırsa, çözmesi o kadar ucuz
2. **Fail-fast** — kritik bulgular pipeline'ı kırar
3. **Developer-friendly** — false positive yorgunluğu = bypass kültürü
4. **Auditable** — her güvenlik kararı log'lanmış, kim onayladı belli
5. **Defense in depth** — tek bir savunma yetmez, katmanlı

---

## 📊 Pipeline Aşamaları

```
PRE-COMMIT  →  PR / CI  →  BUILD  →  DEPLOY  →  RUNTIME
   │            │            │          │          │
   │            │            │          │          └── Falco / Tetragon
   │            │            │          │              eBPF runtime
   │            │            │          │              audit log
   │            │            │          │
   │            │            │          └── Kyverno admission
   │            │            │              imza doğrula, policy gate
   │            │            │              least-privilege RBAC
   │            │            │
   │            │            └── Image vuln scan (Trivy)
   │            │                Imza (cosign)
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

## 1️⃣ Pre-commit (Geliştirici makinesi)

**Hedef:** sorunu commit oluşmadan, geliştirici daha klavyede iken yakala.

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
# Tek komut kurulum (her geliştirici)
pip install pre-commit
pre-commit install
pre-commit run --all-files     # mevcut dosyaları check
```

### IDE plugin'leri (varsayılan kurulumda olsun)
- **VS Code:** Snyk Vulnerability Scanner, Semgrep
- **JetBrains:** Snyk, SonarLint
- **Vim/Neovim:** ALE + linter eklentileri

---

## 2️⃣ CI: PR Açıldığında

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
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }}   # opsiyonel
```

> 🚨 **Eğer leak bulunursa:** PR otomatik blocked + secret rotate edilmesi gereken
> servis için ticket otomatik açılsın. Sadece "delete commit" yetmez —
> secret zaten Git tarihindeydi, leaked sayılır.

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

GitHub native: **CodeQL** (default-suite SQL injection, XSS, path traversal yakalar).

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

Bağımlılıkları (3rd-party libraries) için CVE/lisans tarama.

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

Alternatifler:
- **Trivy fs** — `trivy fs --scanners vuln,license .`
- **Snyk** — `snyk test --severity-threshold=high`
- **Dependabot** (GitHub native, otomatik PR açar)

### D. IaC Scan

Terraform / CloudFormation / K8s YAML için.

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

Alternatifler: tfsec, KICS, Trivy config.

---

## 3️⃣ Build: Imaj İmzalama + SBOM + Vuln Scan

### Standart akış

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

(Tam template: [`17-Templates/github-actions/docker-build-push.yml`](../17-Templates/github-actions/docker-build-push.yml))

Bu workflow:
- ✅ Multi-platform build (amd64 + arm64)
- ✅ BuildKit cache (hızlı)
- ✅ Trivy vulnerability scan (CRITICAL/HIGH fail)
- ✅ Cosign keyless OIDC signing
- ✅ SBOM generation (CycloneDX)
- ✅ SBOM as cosign attestation (cluster'da doğrulanabilir)
- ✅ SARIF upload (GitHub Security tab'ında görünür)

---

## 4️⃣ Deploy: Admission Control

### Kyverno ile

Cluster'a sadece güvenli imajların deploy edilmesini garanti et.

```yaml
# Kyverno ClusterPolicy — sadece imzalı imaj
apiVersion: kyverno.io/v2beta1
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

Tam set: [`17-Templates/kyverno-policies/`](../17-Templates/kyverno-policies/)

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

`restricted` profili otomatik blocks:
- runAsRoot
- privileged containers
- hostNetwork/hostPID
- privilege escalation
- writable root filesystem (büyük çoğunluğu)

---

## 5️⃣ Runtime: Continuous Monitoring

### Falco — eBPF tabanlı runtime threat detection

```yaml
# Helm install
helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  --set tty=true \
  --set falcosidekick.enabled=true \
  --set falcosidekick.config.slack.webhookurl=<SLACK_WEBHOOK>
```

Kanonik kurallar yakalar:
- Container'a interactive shell girişi
- Sensitive file (`/etc/shadow`, `/etc/passwd`) okuma
- Privilege escalation girişimi
- Outbound connection beklenmedik IP'ye

### Tetragon (eBPF, daha modern alternatif)

```bash
# Cilium projesinden, kernel-level observability
helm install tetragon cilium/tetragon -n kube-system
```

### Audit log

API server audit log'u merkezi log sisteme:

```yaml
# kube-apiserver audit policy (örnek)
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

## 🛡️ Threat Model — Asgari kontrol seti

| Saldırı türü | Pipeline'daki savunma |
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

## 📈 Metrikler — Pipeline'ın sağlıklı mı?

Track et:
- **MTTR for critical CVEs** — yeni CVE'den prod'da çözmeye kaç gün?
- **% of builds blocked by security gate** — pipeline çalışıyor mu? (çok yüksekse: çok katı; çok düşükse: gevşek)
- **% of images signed and verified** — hedef %100
- **Time from PR open to merge** — security tarama yavaşlatmamalı (< 10 dk hedef)
- **False positive rate** — geliştirici tolerans dengesi

---

## ⚠️ Anti-pattern'ler

- ❌ "Security review en son aşamada" — geç pahalı
- ❌ Tek bir tool'a bağımlılık — defense in depth yok
- ❌ False positive boğan tarama — geliştirici "ignore" reflexi geliştirir
- ❌ Pipeline'da güvenlik var ama **bypass yetkisi** her takım liderinde — bypass mainstream olur
- ❌ "Audit'te göstereceğiz" tarzı log — gerçekten kullanılmayan ama görünür
- ❌ Severity threshold yok — `LOW` da fail ettiriyorsanız ekibi kaybedersiniz
- ❌ Runtime monitoring yok — pipeline'dan geçen her şey güvenli sayılır

---

## 🎯 12 Haftalık Adoption Planı

| Hafta | Yapılacak |
|---|---|
| 1-2 | pre-commit + secret detection + IDE plugin'ler |
| 3-4 | SAST (Semgrep / CodeQL) PR pipeline'a |
| 5-6 | SCA (OSV-Scanner) + Dependabot otomasyonu |
| 7-8 | IaC scan (Checkov) PR'a; ihlaller block |
| 9-10 | Cosign signing + Kyverno verify policy |
| 11 | Falco/Tetragon runtime monitoring |
| 12 | Threat model + audit log + metric dashboard |

---

## 📚 Devamı

- [OWASP DevSecOps Guideline](https://owasp.org/www-project-devsecops-guideline/)
- [SLSA framework](https://slsa.dev)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [Sigstore documentation](https://docs.sigstore.dev)
- [`17-Templates/kyverno-policies/`](../17-Templates/kyverno-policies/) — hazır policy'ler
