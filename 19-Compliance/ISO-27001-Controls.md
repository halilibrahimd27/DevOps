---
description: "ISO/IEC 27001:2022 Annex A kontrollerinin mühendislik eşlemesi: hangi kontrol Kyverno policy, GitHub Actions ve tooling ile karşılanır, SOC 2 ile karşılaştırma."
---
# ISO 27001 — Annex A Kontrolleri (Mühendislik Eşlemesi)

> *"ISO 27001 'kâğıt sertifikası' iddia eden ekip, Annex A'nın 93
> kontrolünün hangisi mühendislikte yaşar, hangisi politikada,
> bilmezler. **Mühendislik vs governance** ayrımı net değilse,
> sertifika **fasada**."*

Bu rehber ISO/IEC 27001:2022 Annex A'nın **mühendislik tarafında**
yaşayan kontrollerini somut tooling + Kyverno policy / GitHub Actions
karşılığıyla eşler.

> ⚠️ **Yasal danışmanlık değildir.** ISO 27001 audit firma + ISMS
> (Information Security Management System) governance ekibiyle yapılır.

---

## 🎯 ISO 27001 vs SOC 2

| Boyut | ISO 27001 | SOC 2 |
|---|---|---|
| Kapsam | International, ISMS odaklı | US-centric, service org |
| Süre | Annual recertification | Type II 6-12 ay observation |
| Müşteri | Global enterprise | B2B SaaS, US-heavy |
| Maliyet | Genelde daha pahalı | Daha ucuz |
| TR pazarı | Devlet + büyük kurumsal | SaaS startup'lar |

> 🔑 **Pratik**: SOC 2 + ISO 27001 → mühendislik kontrolleri **%80 ortak**.

---

## 📋 ISO 27001:2022 — 4 Kontrol Tema'sı (93 kontrol)

| Tema | Kontrol sayısı | Mühendislik etki |
|---|---|---|
| **Organizational** | 37 | Çoğu policy/governance |
| **People** | 8 | HR, training |
| **Physical** | 14 | Datacenter, donanım |
| **Technological** | 34 | **Mühendislik ana alanı** |

> 🎯 Mühendis odağı: **Technological** kontrolleri (A.8.x).

---

## 🛠️ Annex A.5 — Organizational

### A.5.1 Information Security Policies
- **Mühendislik karşılığı**: Security policies repo'da (Markdown), versioned, PR review

### A.5.7 Threat Intelligence
- Mühendislik: CVE feed (NVD, GitHub Advisory), Dependency-Track

### A.5.10 Acceptable Use
- Mühendislik: BYOD policy, MDM enforcement

### A.5.23 Cloud Services Security
- Mühendislik: Cloud Carbon Footprint (vendor lock-in görünür), cost limit alert

### A.5.30 ICT Readiness for Business Continuity
- Mühendislik: DR plan, backup restore drill, RTO/RPO yazılı

---

## 👥 Annex A.6 — People (geçiyoruz, mühendislik dışı)

---

## 🏢 Annex A.7 — Physical (datacenter)

### A.7.6 Working in Secure Areas
- Mühendislik: Bastion host, VPN/Tailscale, "BeyondCorp"

### A.7.10 Storage Media
- Mühendislik: Disk encryption (LUKS, BitLocker), KMS-backed cloud disk

---

## 🔧 Annex A.8 — Technological (Ana Alan)

### A.8.1 User Endpoint Devices
- **Kontrol**: Laptop encryption, MDM
- **Kanıt**: MDM enrollment status, FileVault enforcement

### A.8.2 Privileged Access Rights
- **Kontrol**: Just-in-time access, MFA
- **Kanıt**:
  ```bash
  # Quarterly: privileged user listesi
  aws iam list-users --query 'Users[?Tags[?Key==`role` && Value==`admin`]]'
  ```

### A.8.3 Information Access Restriction
- **Kontrol**: Least privilege RBAC
- **Kanıt**: K8s RBAC + AWS IAM policies in Git

### A.8.5 Secure Authentication
- **Kontrol**: MFA + strong password
- **Kanıt**:
  - OIDC with MFA enforcement
  - Auth0 / Keycloak config in Git
  - Phishing-resistant (FIDO2 / WebAuthn) hedefe

### A.8.6 Capacity Management
- **Kontrol**: Forecasting + monitoring
- **Kanıt**: HPA + Prometheus + capacity dashboard
- **Doc**: [`11-SRE/Capacity-Planning.md`](../11-SRE/Capacity-Planning.md)

### A.8.7 Protection Against Malware
- **Kontrol**: Image scanning, EDR
- **Kanıt**: Trivy CI gate + Falco runtime
- **Doc**: [`08-Security/Container-Image-Scanning.md`](../08-Security/Container-Image-Scanning.md)

### A.8.8 Management of Technical Vulnerabilities
- **Kontrol**: CVE response, patching
- **Kanıt**: Renovate + Dependabot, CVE SLA (CRIT < 7 gün, HIGH < 30 gün)

### A.8.9 Configuration Management
- **Kontrol**: IaC, drift detection
- **Kanıt**: Terraform + ArgoCD self-heal + drift alert
- **Doc**: [`06-GitOps/`](../06-GitOps/)

### A.8.10 Information Deletion
- **Kontrol**: Right to erasure, retention
- **Kanıt**: KVKK/GDPR retention policy + cron cleaner
- **Doc**: [`KVKK-Practical.md`](KVKK-Practical.md)

### A.8.11 Data Masking
- **Kontrol**: PII de-identification
- **Kanıt**: Test env'de anonymized DB, log PII filter

### A.8.12 Data Leakage Prevention
- **Kontrol**: DLP
- **Kanıt**: gitleaks pre-commit + GitHub Secret Scanning + AWS Macie

### A.8.13 Information Backup
- **Kontrol**: Backup + restore test
- **Kanıt**: WAL-G + S3 + quarterly restore drill
- **Doc**: [`10-Databases-Production/Backup-Restore-Patterns.md`](../10-Databases-Production/Backup-Restore-Patterns.md)

### A.8.15 Logging
- **Kontrol**: Audit log
- **Kanıt**: Cluster + cloud + app audit → SIEM, 1+ yıl retention
- **Doc**: [`08-Security/Kubernetes-Hardening.md`](../08-Security/Kubernetes-Hardening.md)

### A.8.16 Monitoring Activities
- **Kontrol**: SIEM, anomaly detection
- **Kanıt**: Wazuh / Splunk / Loki + Falco alarmları
- **Doc**: [`08-Security/Runtime-Security.md`](../08-Security/Runtime-Security.md)

### A.8.17 Clock Synchronization
- **Kontrol**: NTP / chrony
- **Kanıt**: Tüm node'larda NTP + monitoring

### A.8.18 Privileged Utility Programs
- **Kontrol**: Container privileged mode, host access kısıt
- **Kanıt**: Kyverno disallow-privileged + PSS restricted

### A.8.20 Network Controls
- **Kontrol**: NetworkPolicy, firewall
- **Kanıt**: Default-deny NetPol + Cilium L7 policy
- **Doc**: [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md)

### A.8.21 Security of Network Services
- **Kontrol**: TLS, WAF
- **Kanıt**: cert-manager + Let's Encrypt + ModSecurity
- **Doc**: [`09-Networking/Ingress-NGINX-Patterns.md`](../09-Networking/Ingress-NGINX-Patterns.md)

### A.8.22 Segregation of Networks
- **Kontrol**: VPC, subnet isolation
- **Kanıt**: Terraform VPC module + NetworkPolicy

### A.8.23 Web Filtering
- **Kontrol**: Egress control, FQDN allowlist
- **Kanıt**: Cilium FQDN policy

### A.8.24 Use of Cryptography
- **Kontrol**: Encryption standards
- **Kanıt**: TLS 1.2+ + AES-256 + KMS-backed
- **Doc**: [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md)

### A.8.25 Secure Development Lifecycle
- **Kontrol**: SSDLC
- **Kanıt**: Pre-commit + SAST + SCA + threat model + IR
- **Doc**: [`08-Security/DevSecOps-Pipeline.md`](../08-Security/DevSecOps-Pipeline.md)

### A.8.26 Application Security Requirements
- **Kontrol**: Threat model per service
- **Kanıt**: STRIDE / LINDDUN dokümanları
- **Doc**: [`08-Security/Threat-Modeling.md`](../08-Security/Threat-Modeling.md)

### A.8.28 Secure Coding
- **Kontrol**: Coding standards
- **Kanıt**: Linter config, code review checklist
- **Doc**: [`01-Git-Workflow/Code-Review-Checklist.md`](../01-Git-Workflow/Code-Review-Checklist.md)

### A.8.29 Security Testing
- **Kontrol**: Pen test, vulnerability scan
- **Kanıt**: Annual external pen test + quarterly internal scan + Game day
- **Doc**: [`11-SRE/Chaos-Engineering.md`](../11-SRE/Chaos-Engineering.md)

### A.8.31 Separation of Development, Testing, Production
- **Kontrol**: Env isolation
- **Kanıt**: Per-env cluster veya namespace + per-env IAM role

### A.8.32 Change Management
- **Kontrol**: Change approval
- **Kanıt**: PR review (CODEOWNERS) + ArgoCD audit trail
- **Doc**: [`01-Git-Workflow/PR-Templates-and-Automation.md`](../01-Git-Workflow/PR-Templates-and-Automation.md)

### A.8.33 Test Information
- **Kontrol**: Test data — gerçek prod data değil
- **Kanıt**: Anonymized test DB, masked PII

### A.8.34 Protection of Information Systems During Audit Testing
- **Kontrol**: Audit test prod'a zarar vermesin
- **Kanıt**: Read-only audit role, time-limited

---

## 📋 ISMS Documentation

ISO 27001 = **ISMS sertifikası**. Mühendislik kontroller**inin**, ISMS dokümanı içinde yer alması gerekir:

```
ISMS Documents/
├── 1-policies/
│   ├── information-security-policy.md
│   ├── access-control-policy.md
│   ├── incident-response-policy.md
│   ├── change-management-policy.md
│   ├── backup-policy.md
│   └── crypto-policy.md
├── 2-procedures/
│   ├── new-employee-onboarding.md
│   ├── access-provisioning.md
│   ├── vulnerability-management.md
│   ├── data-deletion-procedure.md
│   └── incident-response-runbook.md
├── 3-records/
│   ├── 2026-q1-access-review.csv
│   ├── 2026-q1-vulnerability-scan.json
│   ├── 2026-q1-backup-drill-report.md
│   └── 2026-q1-incident-log.csv
└── 4-statement-of-applicability.md
```

> 🔑 **Statement of Applicability (SoA)**: 93 kontrol → hangisi uygulanır, hangisi uygulanmaz + gerekçe. ISO 27001 audit'in özü.

---

## 🔄 Continuous Compliance — Otomatik Kanıt

```yaml
# .github/workflows/iso27001-evidence.yml
name: ISO 27001 Quarterly Evidence

on:
  schedule:
    - cron: '0 1 1 1,4,7,10 *'   # Q1, Q2, Q3, Q4 ilk gün

jobs:
  collect:
    steps:
      - name: A.8.2 Privileged users
        run: aws iam list-users ... > evidence/a8-2-privileged.json

      - name: A.8.3 RBAC dump
        run: kubectl get clusterrolebindings -o yaml > evidence/a8-3-rbac.yaml

      - name: A.8.13 Backup status
        run: aws backup list-backup-jobs > evidence/a8-13-backups.json

      - name: A.8.15 Audit log retention
        run: aws s3api get-object-lock-configuration --bucket <AUDIT_BUCKET>

      - name: Push to immutable archive
        run: aws s3 cp evidence/ s3://<COMPLIANCE_BUCKET>/$(date +%Y/Q%q)/ --recursive
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| ISO 27001 = sertifika asma | ISMS yaşamıyor | Continuous compliance |
| SoA dokümanı belirsiz | Audit fail | Net "applies / does not apply" |
| Kontroller var, ISMS doc yok | Audit "yazılı policy yok" | Markdown repo'da |
| Annual audit gününe sıkıştırma | Stres + kalitesiz | Quarterly evidence |
| SOC 2 + ISO 27001 ayrı tooling | Maintenance ikiye katlandı | Compliance-as-Code shared |
| Auditor'a "git logs" gösterme | Anlamsız | Yapılandırılmış evidence |
| Eski control framework (2013) | 2022 revizyonu farklı | ISO 27001:2022 referansı |

---

## 📋 ISO 27001 Hazırlık Checklist

```
[ ] ISMS scope tanımlı
[ ] Statement of Applicability yazılı
[ ] Tüm Annex A.8 (Technological) kontrolleri eşlenmiş
[ ] Politika dokümanları Markdown + Git'te
[ ] Procedure dokümanları (operasyonel adımlar)
[ ] Record management (quarterly evidence)
[ ] Risk register
[ ] Internal audit (annual, sertifikalı denetçi)
[ ] Management review (yıllık, yöneticiler)
[ ] Continuous improvement (PDCA döngü)
[ ] Vendor / sub-processor list + DPA
[ ] Mühendis on-boarding: ISO 27001 farkındalık
[ ] Audit firma seçimi (akredite, BSI / DNV / TÜV / SGS)
[ ] Drata / Vanta / Sprinto entegrasyonu (opsiyonel)
```

---

## 📚 Referanslar

- **ISO/IEC 27001:2022** — iso.org
- **ISO/IEC 27002:2022** (kontroller detayı)
- **NIST SP 800-53** (alternative framework)
- **CIS Controls** v8
- **OWASP ASVS** (uygulama güvenlik kontroleri)
- [`KVKK-Practical.md`](KVKK-Practical.md)
- [`GDPR-Engineering.md`](GDPR-Engineering.md)
- [`SOC2-Type2-Prep.md`](SOC2-Type2-Prep.md)
- [`08-Security/`](../08-Security/) — tüm security deep-dive'lar

---

> *"ISO 27001 = **ISMS yaşıyor mu** denetimi. Sertifika kâğıt değil,
> **mühendislik disiplininin** dış kanıtı. SoA + continuous evidence
> + procedure docs olmadan, sertifika **fasada**."*
