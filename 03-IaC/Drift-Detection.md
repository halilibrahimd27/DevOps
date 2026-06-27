---
description: "Terraform/OpenTofu drift detection rehberi: Git ile cloud arasındaki farkı sürekli yakalama, otomasyon, alarm ve remediation pattern'leri somut araçlarla."
---
# Drift Detection — Git'te Yazan ile Cloud'da Olan Arasındaki Fark

> *"Console'dan tıklayarak EBS değiştirdin, Terraform bilmiyor. **Drift**.
> Bir sonraki `terraform apply` o değişikliği geri alır → incident.
> **Sürekli detect** + **alarm** olmadan IaC iddiası boştur."*

Bu rehber Terraform/OpenTofu drift detection'ı, otomasyon, ve
remediation pattern'lerini somut araçlarla anlatır.

---

## 🎯 Drift Nedir?

```
[Git: main.tf]              [AWS Console / API]
   │                              │
   │ "EBS = 100 GB"               │ "EBS değiştirildi → 200 GB"
   │                              │
   ▼                              ▼
   ├──────── DRIFT ───────────────┤
   │                              │
   │ Sonraki `terraform apply`:   │
   │ "Plan: EBS 200 → 100 (revert)"│ ← incident potansiyeli
```

> 🔑 **Drift** = manuel müdahale (genelde acil incident'ta) → IaC tutarsız.

---

## 🧬 Drift Türleri

### 1. **Configuration drift** (en yaygın)
- Manuel UI tıklamasıyla resource değiştirildi
- Console'dan rule eklendi, IaC bilmiyor

### 2. **Provider drift**
- Provider versiyonu bug fix → değer farkı
- Default value değişmiş

### 3. **Imported drift**
- Terraform-managed olmayan resource'lar var
- "These resources exist but not in state"

### 4. **Phantom drift**
- Provider bug → fark gösteriyor ama gerçek fark yok
- `lifecycle.ignore_changes` ile susturulabilir

---

## 🛠️ Drift Detection Yöntemleri

### 1. `terraform plan` (manuel)
```bash
terraform init
terraform plan
# Output: "Your infrastructure matches the configuration." (no drift)
# Veya: "X changes detected" → drift
```

### 2. `terraform plan -detailed-exitcode`
```bash
terraform plan -detailed-exitcode
# Exit 0: no changes (no drift)
# Exit 1: error
# Exit 2: changes (drift OR pending change)
```

### 3. CI/CD'de scheduled
```yaml
# .github/workflows/drift-detect.yml
name: Drift Detection

on:
  schedule:
    - cron: '0 6 * * *'   # her sabah 06:00

jobs:
  drift:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@<VERSION>
      - uses: aws-actions/configure-aws-credentials@<VERSION>
        with:
          role-to-assume: arn:aws:iam::<ACCT>:role/terraform-readonly
          aws-region: <REGION>

      - uses: hashicorp/setup-terraform@<VERSION>
      - run: terraform init
      - id: plan
        run: terraform plan -detailed-exitcode -no-color
        continue-on-error: true

      - if: steps.plan.outputs.exitcode == '2'
        name: Notify Slack on drift
        run: |
          curl -X POST <SLACK_WEBHOOK> -d "{
            \"text\": \"🚨 Drift detected in prod!\\n${{ steps.plan.outputs.stdout }}\"
          }"
```

### 4. Atlantis / Spacelift / env0 — Continuous
- **Atlantis**: PR'da plan + apply otomatik
- **Spacelift**: scheduled plan + drift alert UI
- **env0**: drift detection native

---

## 🔄 Remediation Stratejileri

### Strateji 1: Cloud → Code (config'i Git'e import)
```bash
# Eğer manuel değişiklik kalıcı olmalıysa, Git'e yansıt
terraform import aws_instance.web i-1234567890abcdef0

# state'i güncelle
terraform refresh
```

> ⚠️ Manuel değişikliği "ödüllendiriyor" — **anti-pattern bazen**.

### Strateji 2: Code → Cloud (revert manuel değişiklik)
```bash
# Drift'i Git'tekine zorla
terraform apply
# Manuel değişiklik geri alınır
```

> 🔑 **Çoğu durumda doğru**. Manuel değişiklik incident'ta yapıldı, kalıcılık RFC ile gelmeli.

### Strateji 3: lifecycle.ignore_changes (kasıtlı)
```hcl
resource "aws_autoscaling_group" "web" {
  desired_capacity = 3   # Terraform'da tanımlı

  lifecycle {
    ignore_changes = [desired_capacity]
    # Auto-scaling drift'i ignore et
  }
}
```

→ HPA / cluster autoscaler değiştirir, Terraform "drift" olarak görmesin.

---

## 🚨 Alarm Stratejisi

### Per-environment severity
| Environment | Drift detect frequency | Action |
|---|---|---|
| **Dev** | Haftalık | Slack info |
| **Staging** | Günlük | Slack warn |
| **Prod** | 4 saatte 1 | PagerDuty page |

### Slack alert template
```
🚨 Terraform Drift — prod
Resource: aws_security_group.web
Change: ingress rule manually added
Detected: 2026-05-04 14:30 UTC
Action required: review + apply or import
Plan: <PR_LINK>
```

---

## 🛠️ Drift Detection Tool'ları

| Tool | Yaklaşım |
|---|---|
| **Atlantis** | PR-driven plan; cron drift detection |
| **Spacelift** | Continuous plan + UI drift dashboard |
| **env0** | Drift detection native + remediation |
| **driftctl** | Resource-level drift (Terraform-managed olmayanları yakalar) |
| **AWS Config** | Cloud-side resource state tracking |
| **CloudCustodian** | Policy + drift detection + remediation |

### driftctl (CLI)
```bash
# State'te olan ama AWS'te olmayan resource'lar
driftctl scan --to aws+tf

# Output:
# Total resources: 142
# Total managed: 138
# Total unmanaged: 4         ← drift
# Total missing: 0
# Total changed: 0
# Coverage: 97%
```

→ Unmanaged resource → manuel oluşturulmuş, Terraform bilmiyor.

---

## 🧪 Continuous Drift CI Pattern

```yaml
# .github/workflows/drift-continuous.yml
name: Continuous Drift Detection

on:
  schedule:
    - cron: '0 */4 * * *'   # 4 saatte bir
  workflow_dispatch:

jobs:
  drift-prod:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>
      - uses: aws-actions/configure-aws-credentials@<VERSION>
        with:
          role-to-assume: arn:aws:iam::<PROD_ACCT>:role/terraform-readonly
      - uses: hashicorp/setup-terraform@<VERSION>
      - working-directory: environments/prod
        run: |
          terraform init
          terraform plan -detailed-exitcode -no-color > plan.txt
          EXITCODE=$?
          
          if [ $EXITCODE -eq 2 ]; then
            # Drift detected
            cat plan.txt
            curl -X POST $SLACK_WEBHOOK -d "{...}"
            curl -X POST $PAGERDUTY -d "{...}"
            exit 1
          fi

  drift-staging:
    # ... benzer ama Slack-only

  drift-dev:
    # ... haftalık
```

---

## 📋 Anti-Drift Discipline

### 1. **Console erişimi kısıtla**
- Production console **read-only** developer'a
- Write erişim sadece break-glass (audit edilen)

### 2. **GitOps for IaC**
- Atlantis: PR → plan → review → apply
- Manual `terraform apply` yasak

### 3. **Drift response runbook**
```
1. Slack alarm geldi
2. Plan output incele
3. Drift kasıtlı mı?
   - EVET (incident fix): RFC + Git'e yansıt + apply
   - HAYIR (yanlış manuel): code → cloud zorla
4. Postmortem (hangi süreç başarısız oldu?)
```

### 4. **Audit log**
- AWS CloudTrail / GCP Audit Log → kim ne değiştirdi
- "Console'dan kim açtı?" cevap 1 dakikada

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Drift detection yok | Sürpriz revert | Continuous detection |
| Console'dan değişiklik normal | IaC kayıp | GitOps + console read-only |
| Drift alarmı sadece Slack | Görünmez | PagerDuty (prod) |
| Manuel `terraform apply` | Drift kabullenir | Atlantis / Spacelift |
| State backup yok | Recovery imkansız | S3 versioning |
| `ignore_changes` aşırı | Real drift kaçar | Spesifik field'lar için |
| Drift response runbook yok | Karar tutarsız | Yazılı playbook |
| Provider version unpinned | Phantom drift | `~> X.Y` pin |
| Drift tarihçesi yok | Pattern keşfi yok | Quarterly review |
| `terraform refresh` blind | State corrupt | Plan + review önce |

---

## 📋 Drift Detection Checklist

```
[ ] Continuous drift detection (Atlantis / Spacelift / cron)
[ ] Per-environment frequency: prod 4h, staging 1d, dev 1w
[ ] Drift alarm: Slack + PagerDuty (prod)
[ ] State backend: S3 + versioning + lock
[ ] Provider version pin (`~> X.Y`)
[ ] `lifecycle.ignore_changes` minimum + dokümante
[ ] driftctl: unmanaged resource detection
[ ] CloudTrail / Audit log: kim değiştirdi
[ ] Console read-only (production developer)
[ ] Drift response runbook yazılı
[ ] Quarterly: drift pattern review (sık tekrar olanlar)
[ ] Atlantis / Spacelift: PR-driven workflow
[ ] Manuel apply yasak (audit + alarm)
```

---

## 📚 Referanslar

- **Atlantis** — runatlantis.io
- **Spacelift** — spacelift.io
- **driftctl** — driftctl.com
- **AWS Config** — aws.amazon.com/config
- **CloudCustodian** — cloudcustodian.io
- [`Terraform-Best-Practices.md`](Terraform-Best-Practices.md)
- [`Terraform-Module-Layout.md`](Terraform-Module-Layout.md)
- [`OpenTofu-Migration.md`](OpenTofu-Migration.md)
- [`Crossplane-Intro.md`](Crossplane-Intro.md) — drift native heal
- [`06-GitOps/ArgoCD-Setup.md`](../06-GitOps/ArgoCD-Setup.md) — K8s side drift

---

> *"Drift 'kötü' değil — **görünmez** olduğunda kötü. Continuous
> detection + alarm + runbook ile **drift = öğrenme fırsatı**;
> 'biri ne zaman manuel açtı?' cevabı **kanıtla**."*
