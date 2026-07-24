---
description: "Terraform/OpenTofu drift detection guide: continuously catching the gap between Git and cloud, automation, alerting, and remediation patterns with concrete tools."
tags:
  - IaC
  - Terraform
  - GitOps
  - Observability
---
# Drift Detection — The Gap Between What Git Says and What's in the Cloud

> *"You changed an EBS volume by clicking in the console, and Terraform
> has no idea. **Drift.** The next `terraform apply` reverts that change → incident.
> Without **continuous detection** + **alerting**, any IaC claim is empty."*

This guide covers Terraform/OpenTofu drift detection, automation, and
remediation patterns with concrete tools.

---

## 🎯 What Is Drift?

```
[Git: main.tf]              [AWS Console / API]
   │                              │
   │ "EBS = 100 GB"               │ "EBS changed → 200 GB"
   │                              │
   ▼                              ▼
   ├──────── DRIFT ───────────────┤
   │                              │
   │ Next `terraform apply`:      │
   │ "Plan: EBS 200 → 100 (revert)"│ ← potential incident
```

> 🔑 **Drift** = manual intervention (usually during an urgent incident) → IaC inconsistent.

---

## 🧬 Types of Drift

### 1. **Configuration drift** (most common)
- A resource was changed by a manual UI click
- A rule was added from the console, IaC doesn't know

### 2. **Provider drift**
- Provider version bug fix → value difference
- A default value changed

### 3. **Imported drift**
- There are resources not managed by Terraform
- "These resources exist but not in state"

### 4. **Phantom drift**
- Provider bug → shows a difference but there's no real difference
- Can be silenced with `lifecycle.ignore_changes`

---

## 🛠️ Drift Detection Methods

### 1. `terraform plan` (manual)
```bash
terraform init
terraform plan
# Output: "Your infrastructure matches the configuration." (no drift)
# Or: "X changes detected" → drift
```

### 2. `terraform plan -detailed-exitcode`
```bash
terraform plan -detailed-exitcode
# Exit 0: no changes (no drift)
# Exit 1: error
# Exit 2: changes (drift OR pending change)
```

### 3. Scheduled in CI/CD
```yaml
# .github/workflows/drift-detect.yml
name: Drift Detection

on:
  schedule:
    - cron: '0 6 * * *'   # every morning at 06:00

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
- **Atlantis**: automatic plan + apply on the PR
- **Spacelift**: scheduled plan + drift alert UI
- **env0**: native drift detection

---

## 🔄 Remediation Strategies

### Strategy 1: Cloud → Code (import the config into Git)
```bash
# If the manual change should be permanent, reflect it into Git
terraform import aws_instance.web i-1234567890abcdef0

# update state
terraform refresh
```

> ⚠️ It "rewards" the manual change — **sometimes an anti-pattern**.

### Strategy 2: Code → Cloud (revert the manual change)
```bash
# Force the drift back to what's in Git
terraform apply
# The manual change is reverted
```

> 🔑 **Correct in most cases.** The manual change was made during an incident; permanence should come via an RFC.

### Strategy 3: lifecycle.ignore_changes (deliberate)
```hcl
resource "aws_autoscaling_group" "web" {
  desired_capacity = 3   # defined in Terraform

  lifecycle {
    ignore_changes = [desired_capacity]
    # ignore auto-scaling drift
  }
}
```

→ HPA / cluster autoscaler changes it, so Terraform shouldn't see it as "drift".

---

## 🚨 Alert Strategy

### Per-environment severity
| Environment | Drift detect frequency | Action |
|---|---|---|
| **Dev** | Weekly | Slack info |
| **Staging** | Daily | Slack warn |
| **Prod** | Every 4 hours | PagerDuty page |

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

## 🛠️ Drift Detection Tools

| Tool | Approach |
|---|---|
| **Atlantis** | PR-driven plan; cron drift detection |
| **Spacelift** | Continuous plan + UI drift dashboard |
| **env0** | Native drift detection + remediation |
| **driftctl** | Resource-level drift (catches resources not managed by Terraform) |
| **AWS Config** | Cloud-side resource state tracking |
| **CloudCustodian** | Policy + drift detection + remediation |

### driftctl (CLI)
```bash
# Resources in state but not in AWS
driftctl scan --to aws+tf

# Output:
# Total resources: 142
# Total managed: 138
# Total unmanaged: 4         ← drift
# Total missing: 0
# Total changed: 0
# Coverage: 97%
```

→ Unmanaged resource → created manually, Terraform doesn't know about it.

---

## 🧪 Continuous Drift CI Pattern

```yaml
# .github/workflows/drift-continuous.yml
name: Continuous Drift Detection

on:
  schedule:
    - cron: '0 */4 * * *'   # every 4 hours
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
    # ... similar but Slack-only

  drift-dev:
    # ... weekly
```

---

## 📋 Anti-Drift Discipline

### 1. **Restrict console access**
- Production console **read-only** for developers
- Write access only via break-glass (audited)

### 2. **GitOps for IaC**
- Atlantis: PR → plan → review → apply
- Manual `terraform apply` forbidden

### 3. **Drift response runbook**
```
1. Slack alert arrived
2. Review the plan output
3. Is the drift deliberate?
   - YES (incident fix): RFC + reflect into Git + apply
   - NO (wrong manual change): force code → cloud
4. Postmortem (which process failed?)
```

### 4. **Audit log**
- AWS CloudTrail / GCP Audit Log → who changed what
- "Who opened it from the console?" answered in 1 minute

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| No drift detection | Surprise revert | Continuous detection |
| Console changes treated as normal | IaC lost | GitOps + console read-only |
| Drift alert only in Slack | Invisible | PagerDuty (prod) |
| Manual `terraform apply` | Accepts drift | Atlantis / Spacelift |
| No state backup | Recovery impossible | S3 versioning |
| Excessive `ignore_changes` | Real drift slips through | Only for specific fields |
| No drift response runbook | Inconsistent decisions | Written playbook |
| Provider version unpinned | Phantom drift | `~> X.Y` pin |
| No drift history | No pattern discovery | Quarterly review |
| Blind `terraform refresh` | State corruption | Plan + review first |

---

## 📋 Drift Detection Checklist

```
[ ] Continuous drift detection (Atlantis / Spacelift / cron)
[ ] Per-environment frequency: prod 4h, staging 1d, dev 1w
[ ] Drift alert: Slack + PagerDuty (prod)
[ ] State backend: S3 + versioning + lock
[ ] Provider version pin (`~> X.Y`)
[ ] `lifecycle.ignore_changes` minimal + documented
[ ] driftctl: unmanaged resource detection
[ ] CloudTrail / Audit log: who changed it
[ ] Console read-only (production developer)
[ ] Drift response runbook written
[ ] Quarterly: drift pattern review (frequently recurring ones)
[ ] Atlantis / Spacelift: PR-driven workflow
[ ] Manual apply forbidden (audit + alert)
```

---

## 📚 References

- **Atlantis** — runatlantis.io
- **Spacelift** — spacelift.io
- **driftctl** — driftctl.com
- **AWS Config** — aws.amazon.com/config
- **CloudCustodian** — cloudcustodian.io
- [`Terraform-Best-Practices.md`](Terraform-Best-Practices.md)
- [`Terraform-Module-Layout.md`](Terraform-Module-Layout.md)
- [`OpenTofu-Migration.md`](OpenTofu-Migration.md)
- [`Crossplane-Intro.md`](Crossplane-Intro.md) — native drift heal
- [`06-GitOps/ArgoCD-Setup.md`](../06-GitOps/ArgoCD-Setup.md) — K8s-side drift

---

> *"Drift isn't 'bad' — it's bad when it's **invisible**. With continuous
> detection + alerting + a runbook, **drift = a learning opportunity**;
> the answer to 'when did someone open this manually?' comes **with evidence**."*
