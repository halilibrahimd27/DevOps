---
description: "Trivy ekseninde shift-left container image tarama rehberi: OS/dil CVE, IaC misconfig, secret ve SBOM taramasi; CI gate'ten admission ve runtime drift'e."
---
# Container Image Scanning — CVE'yi Üretime Sokmamak

> *"CVE'yi prod'da bulmaktansa, prod'a sokmamak — 1000 kat ucuz, 100
> kat hızlı, 0 oncall."*

Image scan **shift-left** güvenliğin kapı bekçisidir. Bu rehber Trivy
ekseninde modern bir tarama akışı kurar: pre-build → CI gate → registry
scan → admission → runtime drift.

---

## 🎯 Tarama Çeşitleri

| Tarama tipi | Ne bakar | Araç |
|---|---|---|
| **OS package CVE** | apk/apt/yum paket sürümleri ve CVE'leri | Trivy, Grype, Snyk |
| **Language deps (SCA)** | npm, pip, Maven, Go modules CVE | Trivy, OSV-Scanner, Snyk |
| **Misconfig (IaC)** | Dockerfile, K8s, Terraform | Trivy, Checkov, KICS |
| **Secrets** | Image katmanlarında hardcoded secret | Trivy, gitleaks |
| **License** | GPL bulaşması, ticari ihlal riski | Trivy, FOSSA, Snyk |
| **Malware** | Truva atı, kripto madencisi | ClamAV, Cloudsmith Quarantine |
| **SBOM** | Yazılım malzeme listesi (üretim) | Syft, Trivy SBOM |

---

## 🔧 Trivy: Tek Komut, Çoklu Tarama

Aqua Security Trivy 2026'da en yaygın **açık kaynak** tarayıcı. Hızlı, network-bağımsız, CI/CD ve K8s entegrasyonu mükemmel.

### Yerel kullanım
```bash
# Image scan
trivy image <REGISTRY>/<APP>:<TAG>

# Sadece CRITICAL/HIGH
trivy image --severity CRITICAL,HIGH <REGISTRY>/<APP>:<TAG>

# Fix'i olmayan CVE'leri yoksay (boş gürültü)
trivy image --ignore-unfixed <REGISTRY>/<APP>:<TAG>

# JSON output (CI parse için)
trivy image --format json -o trivy.json <REGISTRY>/<APP>:<TAG>

# SARIF output (GitHub Security tab için)
trivy image --format sarif -o trivy.sarif <REGISTRY>/<APP>:<TAG>

# Filesystem scan (Dockerfile yazmadan önce)
trivy fs --scanners vuln,secret,config .

# K8s manifest scan
trivy config k8s/

# Çalışan cluster scan
trivy k8s --report summary cluster
```

### Önbellek + offline mod
Air-gapped ortamlarda DB'yi önceden indir:
```bash
trivy image --download-db-only
trivy image --skip-db-update --offline-scan <IMAGE>
```

---

## 🚦 CI Gate: Severity Eşikleri

> 🔑 **Felsefe:** "Hiç CVE'siz" gerçekçi değil. Önemli olan **fix'i olan
> CRITICAL/HIGH** ile **fix yapamayacağın** noise arasında ayrım koymak.

### Politika örneği
| Severity | Fix var mı? | CI behavior |
|---|---|---|
| CRITICAL | EVET | **Fail** (deploy yok) |
| CRITICAL | HAYIR | Warn, exception ile geçer |
| HIGH | EVET | **Fail** (default) |
| HIGH | HAYIR | Warn |
| MEDIUM | * | Sadece raporla, fail etme |
| LOW | * | Görmezden gel |

### GitHub Actions
```yaml
name: Image Security Scan

on:
  pull_request:
    paths: ['Dockerfile', 'src/**', 'package*.json', 'go.sum']

permissions:
  contents: read
  security-events: write   # SARIF upload için

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
Bazı CVE'ler kabullenilir (false positive, exploitable değil, fix yok):
```
# .trivyignore
CVE-2024-12345    # base image alpine glibc, exploit yok bizde
CVE-2025-67890 exp:2026-09-01    # 6 ay süreli istisna
```

> ⚠️ Her ignore satırı **sahibi olmalı + gerekçesi yorum**. PR review'da kontrol et.

---

## 🏗️ Build-Time Best Practices (CVE'yi en başta sokma)

### 1. Distroless / minimal base image
```dockerfile
# ❌ debian:latest → 800+ paket, 1500+ CVE
FROM debian:latest

# ✅ distroless/static → 0 shell, ~10 paket
FROM gcr.io/distroless/static-debian12:nonroot
COPY app /app
USER nonroot:nonroot
ENTRYPOINT ["/app"]
```

### 2. Chainguard / Wolfi
**2026 önerisi**: Chainguard Images (Wolfi base) — neredeyse 0 CVE, daily rebuild.

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

> Nihai imaj **build araçları** içermez → SCA hedef yüzeyi düşer.

### 4. `.dockerignore` agresif
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
Aksi halde `COPY . .` ile secret/junk image'a girer.

### 5. Pin everything
```dockerfile
FROM golang:1.23.4-alpine3.20 AS builder    # ✅ digest tag
FROM golang:1.23-alpine                      # ⚠️ minor değişebilir
FROM golang:latest                           # ❌ asla
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
- **GitHub Container Registry**: native Trivy entegrasyonu, `Security` sekmesi
- **Quay.io**: Clair-tabanlı, automatic scan
- **Harbor** (self-hosted): Trivy adapter ile
- **AWS ECR**: Inspector entegrasyonu
- **GCP Artifact Registry**: Container Analysis API

### Harbor + Trivy entegrasyon
```yaml
# Harbor proje ayarı: "Automatically scan images on push"
# Webhook ile retag/replikasyon kuralı:
# - Trigger: vulnerability scan completed
# - Endpoint: Slack / SIEM
```

---

## 🛡️ Admission-Time: Imaj Doğrulama (Kyverno)

CVE-yüklü imaj registry'de duruyor olabilir; cluster onu **deploy etmemeli**.

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

### Yasaklı tag/registry
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
        message: "Sadece <REGISTRY> ve gcr.io/distroless izinli"
        pattern:
          spec:
            containers:
              - image: "<REGISTRY>/* | gcr.io/distroless/*"
```

Hazır şablonlar: [`17-Templates/kyverno-policies/`](../17-Templates/kyverno-policies/).

---

## 🧰 Alternatif Araçlar — Karşılaştırma

| Araç | Tip | Lisans | Güçlü yan | Zayıf yan |
|---|---|---|---|---|
| **Trivy** | CLI + K8s operator | Apache 2 | Hız, çok-tarama, OSS | Vendor data sometimes lags |
| **Grype** | CLI | Apache 2 | Anchore SBOM stack ile entegre | UI yok |
| **Snyk** | SaaS + CLI | Ticari (free tier) | UI iyi, IDE plugin | Ücretli, vendor lock |
| **Anchore Enterprise** | Self-hosted | Ticari | Policy-as-code, compliance reporting | Kurulum yükü |
| **Aqua Enterprise** | SaaS + on-prem | Ticari | Runtime + admission entegre | Yüksek maliyet |
| **Sysdig Secure** | SaaS | Ticari | Runtime + admission + IR | Pricey |
| **Clair** | Kütüphane | Apache 2 | Quay/Harbor entegre | CLI değil, integration ile |
| **Docker Scout** | Docker Desktop | Free + paid | Docker Hub entegre | Aktif gelişim |

> 🔑 **Pratik öneri (2026):**
> - OSS / startup → **Trivy**
> - Compliance ağırlıklı kurumsal → **Anchore Enterprise** veya **Aqua**
> - Dev ergonomi öncelikli → **Snyk** (IDE plugin)

---

## 🔄 Continuous Re-Scan: Drift Detection

Imaj 6 ay önce temizdi, **yeni CVE açıkladılar** — kimse fark etmiyor.

### Trivy Operator (K8s)
Cluster'da tüm imajları periyodik tarar:
```bash
helm install trivy-operator aqua/trivy-operator \
  -n trivy-system --create-namespace \
  --set "trivy.severity=CRITICAL,HIGH" \
  --set "operator.scanJobTimeout=10m"
```

```yaml
# VulnerabilityReport CR otomatik oluşur
apiVersion: aquasecurity.github.io/v1alpha1
kind: VulnerabilityReport
# kubectl get vulnerabilityreports -A
```

Prometheus exporter → Grafana dashboard:
```
trivy_vulnerabilities_total{severity="CRITICAL", namespace="<NS>"}
```

### Alert: yeni CRITICAL CVE bulunduğunda
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
          summary: "Yeni CRITICAL CVE: {{ $labels.image }}"
          runbook: "<RUNBOOK_URL>/cve-response"
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| `FROM debian:latest` | Geniş paket → çok CVE | distroless / Chainguard |
| `FROM image:latest` | Reproducibility yok | Digest pin |
| Scan sadece release branch'te | Geliştirici fark etmeden CVE merge ediyor | Her PR'da |
| "MEDIUM/LOW da fail etsin" | Boş gürültü, ekip ignore eder | CRITICAL+HIGH+fix-available |
| `.trivyignore` boş yorum | Niye ignore edildiği unutulur | Yorum + sahip + expiry |
| Image scan yok, "runtime'da yakalarız" | Falco late-stage, expensive | Build-time +runtime ikisi de |
| Scan sonucu Slack'e atılıp unutulur | Kimse takip etmiyor | Issue otomatik açılır + owner atanır |
| Vendor scan'i OSS scan ile birbirine yakınlamıyor | Hangisine güveneceksin? | İkisini de çalıştır, false positive azalır |
| Dockerfile'da `apk add --no-cache curl wget vim` | Saldırı yüzeyi büyür | Sadece runtime gereken paketler |
| `USER root` (veya yok) | RCE → host'a yakın | `USER nonroot` + `runAsNonRoot:true` |

---

## 📋 Image Security Checklist

```
[ ] Tüm base imajlar minimal/distroless
[ ] Multi-stage build, runtime'da build araç YOK
[ ] Digest pin (sha256:...) kritik imajlarda
[ ] .dockerignore agresif, secret yok
[ ] USER nonroot, root için exception yok
[ ] CI: Trivy scan her PR'da
[ ] Exit code: CRITICAL/HIGH+fix-available → fail
[ ] SARIF GitHub Security tab'a upload
[ ] SBOM her build'de üretiliyor (CycloneDX/SPDX)
[ ] Cosign ile sign (keyless OIDC)
[ ] Kyverno verifyImages enforce ediyor
[ ] Sadece allow-listed registry deploy
[ ] :latest tag yasak (Kyverno disallow-latest-tag)
[ ] Trivy operator cluster'da periyodik tarar
[ ] CVE alert → Slack + Issue auto-create
[ ] .trivyignore satırları sahipli + expiry'li
[ ] Quarterly base image güncellemesi (otomatik dependabot/renovate)
```

---

## 📚 Referanslar

- **Trivy Docs** — aquasec.github.io/trivy
- **Chainguard Images** — chainguard.dev/chainguard-images
- **NIST SP 800-190** — Application Container Security Guide
- **CIS Docker Benchmark v1.7**
- [`Kubernetes-Hardening.md`](Kubernetes-Hardening.md) — admission policy
- [`SLSA-and-SBOM.md`](SLSA-and-SBOM.md) — supply chain integrity
- [`04-Containers/Dockerfile-Best-Practices.md`](../04-Containers/Dockerfile-Best-Practices.md)
- [`17-Templates/dockerfiles/`](../17-Templates/dockerfiles/) — minimal Dockerfile şablonları

---

> *"CVE bulundu" demek "exploit edilebilir" demek değildir; ama
> ölçeklendirilebilir bir filtreyle **muhtemelen exploit edilebilir
> olanlar**'a odaklanmak — security ekibinin uyumadığı tek tampon."*
