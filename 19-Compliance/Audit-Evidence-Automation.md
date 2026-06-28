---
description: "Audit evidence'ı otomatik toplama disiplini: continuous evidence collection ile SOC 2, ISO 27001, KVKK ve PCI DSS için ortak kanıt pattern'i ve tooling."
tags:
  - Compliance
  - Security
  - Policy as Code
  - CI/CD
  - Observability
---
# Audit Evidence Automation — "Audit Gününe Hazırlık" Bitsin

> *"Audit haftasında 80 saat manual evidence toplayan ekip,
> sertifika günü öğleden sonra çay içemez. **Continuous evidence
> collection** = mühendisin haftada 1 saatini compliance'a verir,
> audit haftası **rapor zaten hazır**."*

Bu rehber audit evidence'ı **otomatik toplama** disiplinini, hangi
tool'larla yapıldığını, ve SOC 2 / ISO 27001 / KVKK / PCI DSS için
shared evidence pattern'ini anlatır.

---

## 🎯 Sorun: Manual Evidence Cehennem

```
Audit haftası, Pazartesi 09:00:
  Auditor: "MFA kullanan tüm user listesini gönder."
  Mühendis: "AWS console'a gir, user list dump et, Excel'e koy..."
  → 4 saat manuel iş

  Auditor: "Q3'te tüm prod PR review edildi mi sample 20'sini gönder."
  Mühendis: "GitHub API → CSV → manual filter..."
  → 6 saat

  Auditor: "Q3 backup restore drill report?"
  Mühendis: "Mail arşivinde X tarihli olmalı..."
  → bulamıyor

  Sonuç: 80 saat manuel evidence + 3 finding (kanıt eksik).
```

---

## ✅ Çözüm: Continuous Evidence Collection

```
Otomatik (haftalık / quarterly):
  ├── AWS IAM dump → S3 immutable
  ├── K8s RBAC dump → S3
  ├── Backup status → S3
  ├── Pentest report → S3
  ├── Vulnerability scan → S3
  ├── Access review → S3
  ├── Threat models → Git (versioned)
  ├── Postmortems → Git
  └── PR audit log → BigQuery

Audit günü:
  Auditor: "MFA listesi?"
  → S3 path linki, son scan'i göster
  → 5 dakika
```

---

## 🛠️ Compliance-as-Code Tool'lar

### SaaS (popüler, başlangıç hızlı)

| Tool | Niche | Multi-framework |
|---|---|---|
| **Drata** | SOC 2 + ISO 27001 odaklı | ✅ |
| **Vanta** | Hızlı startup başlangıç | ✅ |
| **Secureframe** | Mid-market | ✅ |
| **Sprinto** | Hint-tabanlı, ucuz | ✅ |
| **Strike Graph** | Hybrid manuel + auto | ✅ |
| **Tugboat Logic** | Enterprise | ✅ |

> 🔑 **Bütçe varsa**: Drata / Vanta. SOC 2 hazırlık 12 ay → 4-6 ay.

### Self-hosted / OSS

| Tool | Açıklama |
|---|---|
| **Cloud Custodian** | AWS / GCP / Azure policy-as-code |
| **Steampipe** | SQL ile cloud audit |
| **Prowler** | AWS security compliance |
| **OPA + Rego** | Custom compliance |
| **Compliance-as-Code (Anchore)** | Container compliance |

---

## 🏗️ DIY: Otomatik Evidence Pipeline

### Şema
```
┌──────────────────────────────────────────────┐
│     Evidence Sources                          │
├──────────────────────────────────────────────┤
│  AWS IAM API           ↓                      │
│  K8s API (kubectl)     ↓                      │
│  GitHub API            ↓                      │
│  Datadog/Prometheus    ↓                      │
│  PagerDuty             ↓                      │
│  Vault audit log       ↓                      │
│  Trivy scan results    ↓                      │
└────────────────────┬──────────────────────────┘
                     │
                     ▼
       ┌────────────────────────────────┐
       │  GitHub Actions / cron job     │
       │  (haftalık / quarterly)        │
       └──────────────┬─────────────────┘
                      │
                      ▼
       ┌────────────────────────────────┐
       │  S3 immutable bucket            │
       │  (Object Lock + versioning)     │
       │  Path: /YYYY/Qx/CC*/            │
       └──────────────┬─────────────────┘
                      │
                      ▼
       ┌────────────────────────────────┐
       │  Auditor read-only IAM role    │
       │  (audit dönemi süresince)      │
       └────────────────────────────────┘
```

### GitHub Actions örneği — Quarterly evidence
```yaml
# .github/workflows/quarterly-evidence.yml
name: Quarterly Compliance Evidence

on:
  schedule:
    - cron: '0 1 1 1,4,7,10 *'   # Q1, Q2, Q3, Q4 ilk gün

permissions:
  id-token: write   # AWS OIDC
  contents: read

jobs:
  collect:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>

      - uses: aws-actions/configure-aws-credentials@<VERSION>
        with:
          role-to-assume: arn:aws:iam::<ACCT>:role/<COMPLIANCE_ROLE>
          aws-region: <REGION>

      - name: CC6.1 — IAM users + MFA status
        run: |
          mkdir -p evidence/$(date +%Y-Q%q)/CC6
          aws iam list-users \
            --output json > evidence/$(date +%Y-Q%q)/CC6/iam-users.json
          aws iam list-mfa-devices \
            --output json > evidence/$(date +%Y-Q%q)/CC6/mfa-devices.json

          # Hangi user MFA-less
          python3 scripts/compliance/find-no-mfa.py \
            > evidence/$(date +%Y-Q%q)/CC6/users-without-mfa.csv

      - name: CC6.3 — K8s RBAC dump
        run: |
          aws eks update-kubeconfig --name <CLUSTER>
          kubectl get clusterrolebindings -o yaml \
            > evidence/$(date +%Y-Q%q)/CC6/rbac.yaml
          kubectl get rolebindings -A -o yaml \
            >> evidence/$(date +%Y-Q%q)/CC6/rbac.yaml

      - name: CC7.4 — Backup verification
        run: |
          aws backup list-backup-jobs \
            --by-state COMPLETED \
            --by-created-after $(date -d '90 days ago' +%FT%T) \
            > evidence/$(date +%Y-Q%q)/CC7/backups.json

      - name: CC8 — Recent PR merges (sample)
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          # Son 90 günde merge edilen PR'lar (sample 20)
          gh pr list --repo <ORG>/<REPO> --state merged --limit 200 \
            --json number,title,author,mergedAt,reviewers,reviewDecision \
            > evidence/$(date +%Y-Q%q)/CC8/recent-prs.json

      - name: CC9.1 — Threat models
        run: |
          # Repo'da tüm threat-model.md
          find . -name 'threat-model.md' -type f \
            > evidence/$(date +%Y-Q%q)/CC9/threat-models-list.txt

      - name: Vulnerability scan (Trivy)
        run: |
          trivy image --severity CRITICAL,HIGH \
            --format json --output evidence/$(date +%Y-Q%q)/vuln/trivy.json \
            <REGISTRY>/<APP>:latest

      - name: Upload to S3 (immutable)
        run: |
          aws s3 cp evidence/ s3://<COMPLIANCE_BUCKET>/$(date +%Y-Q%q)/ \
            --recursive --acl bucket-owner-full-control

      - name: Slack notify
        if: always()
        run: |
          curl -X POST <SLACK_WEBHOOK> -d "{
            \"text\": \"Quarterly evidence collected: s3://<COMPLIANCE_BUCKET>/$(date +%Y-Q%q)/\"
          }"
```

---

## 🗂️ Evidence Klasör Yapısı

```
s3://<COMPLIANCE_BUCKET>/
└── 2026-Q1/
    ├── CC1-control-environment/
    │   ├── code-of-conduct-acknowledgments.csv
    │   └── quarterly-policy-updates.md
    ├── CC6-logical-access/
    │   ├── iam-users.json
    │   ├── mfa-devices.json
    │   ├── users-without-mfa.csv (boş olmalı)
    │   ├── rbac.yaml
    │   ├── access-review-q1.pdf (manuel manager onay)
    │   └── tls-cert-expiry.json
    ├── CC7-system-operations/
    │   ├── backups.json
    │   ├── backup-restore-drill-report.md
    │   ├── incidents-log.csv
    │   ├── postmortems/
    │   └── falco-alerts-summary.csv
    ├── CC8-change-management/
    │   ├── recent-prs.json
    │   ├── argocd-sync-history.json
    │   └── deployment-frequency.csv
    ├── CC9-risk-mitigation/
    │   ├── threat-models-list.txt
    │   ├── pentest-q1-report.pdf
    │   └── vendor-due-diligence/
    │       ├── stripe-soc2.pdf
    │       └── datadog-iso27001.pdf
    └── vulnerability/
        ├── trivy-prod-images.json
        ├── owasp-zap-scan.html
        └── asv-scan-report.pdf (PCI için)
```

---

## 🔒 S3 Object Lock (Immutable)

```bash
# Bucket Object Lock + versioning enable
aws s3api create-bucket --bucket <COMPLIANCE_BUCKET> \
  --object-lock-enabled-for-bucket

aws s3api put-bucket-versioning --bucket <COMPLIANCE_BUCKET> \
  --versioning-configuration Status=Enabled

aws s3api put-object-lock-configuration --bucket <COMPLIANCE_BUCKET> \
  --object-lock-configuration '{
    "ObjectLockEnabled": "Enabled",
    "Rule": {
      "DefaultRetention": {
        "Mode": "COMPLIANCE",
        "Years": 7
      }
    }
  }'
```

→ 7 yıl boyunca **kimse** silemez (admin dahil). Compliance retention.

---

## 🔍 Auditor Erişimi

```yaml
# IAM role: read-only, time-limited
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::<COMPLIANCE_BUCKET>",
        "arn:aws:s3:::<COMPLIANCE_BUCKET>/*"
      ],
      "Condition": {
        "DateLessThan": {"aws:CurrentTime": "2026-12-31T23:59:59Z"}
      }
    }
  ]
}
```

→ Auditor S3 üzerinden self-service, internal sistemlere dokunmadan.

---

## 📊 Evidence Coverage Dashboard

```
┌─────────────────────────────────────────────┐
│  SOC 2 Type II — 2026-Q4 Evidence Coverage  │
├─────────────────────────────────────────────┤
│  CC1  (Control Env)    ✅ 100%               │
│  CC2  (Communication)  ✅ 100%               │
│  CC3  (Risk Assess)    🟡 80% (1 gap)        │
│  CC4  (Monitoring)     ✅ 100%               │
│  CC5  (Control Act)    ✅ 100%               │
│  CC6  (Logical Access) ✅ 100%               │
│  CC7  (System Ops)     ✅ 100%               │
│  CC8  (Change Mgmt)    🟡 90% (postmortem 2 eksik) │
│  CC9  (Risk Mitigation) ✅ 100%              │
│                                              │
│  Overall:              🟢 96%                │
└─────────────────────────────────────────────┘
```

→ Quarterly review: **gap'ler görünür**, action item'a alınır.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Audit haftası evidence toplamak | 80 saat stres | Continuous + automated |
| Evidence Confluence'ta | Versioning + retention zayıf | S3 Object Lock |
| Auditor şirket ağına direkt | Compromise vektörü | S3 read-only IAM |
| Manuel screenshot toplama | Tutarsız + zaman | API dump + script |
| 30 gün retention | < 1 yıl ihlal | 7+ yıl (Object Lock) |
| PII evidence içinde | KVKK ihlal | Mask + filtered |
| Evidence Git'te (büyük dosya) | Repo şişer | S3 + Git'te sadece metadata |
| Tek cron job, hata olursa kimse görmez | Coverage gap | Slack notify + monitoring |
| Drata kuruldu, custom check yok | Sadece OOTB control | Custom evidence + Drata combined |
| Multi-framework evidence ayrı | Duplicate iş | Shared evidence (SOC2 + ISO + KVKK) |

---

## 📋 Audit Evidence Automation Checklist

```
[ ] S3 immutable bucket (Object Lock + 7yr retention)
[ ] Quarterly cron (GitHub Actions / Cloud scheduler)
[ ] Evidence collected per-control (CC* / Annex A.*)
[ ] AWS / K8s / GitHub / Datadog API'leri dump
[ ] PII mask + filter
[ ] Slack notification on collection
[ ] Evidence dashboard (coverage %)
[ ] Auditor IAM role (read-only, time-limited)
[ ] Failure alert (cron job hata verirse)
[ ] Manual evidence entegrasyonu (PDF screenshots, manager onayları)
[ ] Multi-framework: SOC 2 + ISO 27001 + KVKK shared
[ ] Drata / Vanta entegrasyon (varsa)
[ ] Quarterly: coverage review meeting
[ ] Annual: evidence retention purge (7+ yıl sonrası)
```

---

## 📚 Referanslar

- **Drata** — drata.com
- **Vanta** — vanta.com
- **Cloud Custodian** — cloudcustodian.io
- **Steampipe** — steampipe.io
- **Prowler** — prowler.cloud
- **AWS Audit Manager** — aws.amazon.com/audit-manager
- [`SOC2-Type2-Prep.md`](SOC2-Type2-Prep.md)
- [`ISO-27001-Controls.md`](ISO-27001-Controls.md)
- [`KVKK-Practical.md`](KVKK-Practical.md)
- [`PCI-DSS-4.md`](PCI-DSS-4.md)
- [`08-Security/Kubernetes-Hardening.md`](../08-Security/Kubernetes-Hardening.md) — audit log

---

> *"Evidence automation 'compliance ekibi'nin işi değil — **mühendisin
> haftalık 1 saatlik disiplin**. Audit gününe sıkıştıran ekip
> tükenmiş; **continuous** ekip, audit gününde **rapor zaten orada**
> der."*
