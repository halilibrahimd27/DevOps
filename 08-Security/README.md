# 08 · Security (DevSecOps)

> *"Production'da ihlal olduğunda 'security takımının sorunu değil, hepimizin
> sorunu' diyenler — ihlalden 6 ay önce uyarıyı çoktan görüyordu."*

Shift-left + runtime defense + supply chain integrity. 2026'da güvenlik
"feature" değil, başlangıç şartı.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`DevSecOps-Pipeline.md`](DevSecOps-Pipeline.md) | Pre-commit → SAST → SCA → IaC scan → image scan → runtime |
| [`Secrets-Management.md`](Secrets-Management.md) | Vault, ESO, SOPS, Sealed Secrets karşılaştırma + decision tree |
| [`Container-Image-Scanning.md`](Container-Image-Scanning.md) | Trivy/Grype kullanımı, CVE prioritization, fail/warn policy |
| [`Kubernetes-Hardening.md`](Kubernetes-Hardening.md) | CIS Benchmark, Pod Security Standards, NetworkPolicy default-deny |
| [`SLSA-and-SBOM.md`](SLSA-and-SBOM.md) | Supply chain integrity, in-toto attestation, cosign attest |
| [`Policy-as-Code-OPA-Kyverno.md`](Policy-as-Code-OPA-Kyverno.md) | Kyverno vs OPA Gatekeeper, örnek policy katalog |
| [`Threat-Modeling.md`](Threat-Modeling.md) | STRIDE / LINDDUN, lightweight threat model template |
| [`Zero-Trust-Networking.md`](Zero-Trust-Networking.md) | mTLS her yerde, service mesh authZ, BeyondCorp pattern'i |

## "Shift-Left" akışı

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
       Geliştirici makinesi              CI                   CD             Production
```

## Asgari hijyen 2026

- ✅ Tüm imajlar **imzalı** (cosign keyless OIDC)
- ✅ Cluster'da imzasız imaj **deploy edilmiyor** (Kyverno verifyImages)
- ✅ Her image'la birlikte **SBOM** üretiliyor (CycloneDX/SPDX)
- ✅ CI'da **secret scan** her PR'da çalışıyor
- ✅ **Vault** (veya managed equivalent) + **External Secrets Operator** ile secret'lar
- ✅ **NetworkPolicy default-deny** her namespace'de
- ✅ **Pod Security Standards: restricted** (en azından non-system namespace'lerde)
- ✅ **OIDC** ile cloud auth (uzun-ömürlü access key yok)
- ✅ **MFA** zorunlu (Git provider, cloud, registry)
- ✅ **Audit log** merkezi (cluster, cloud, app)

## Kırmızı çizgiler

- 🔴 `latest` tag prod'da → policy ile engellenmeli
- 🔴 `:` parolası env var'da clear-text → vault'a taşınmalı
- 🔴 `*:*` IAM policy → least privilege uygulamaması, audit hatası
- 🔴 Public S3 bucket → IAM Access Analyzer ile bul
- 🔴 Kubernetes API public erişim → private cluster + bastion
- 🔴 Container runAsRoot:0 → restricted PSS engelliyor
