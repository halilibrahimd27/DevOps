---
description: "Terraform/OpenTofu 2026 production guide: remote state, versioned modules, plan in PR, manual apply, for_each, sensitive marking, and continuous drift monitoring."
tags:
  - IaC
  - Terraform
  - CI/CD
  - Security
---
# Terraform Best Practices

> *"Terraform `apply -auto-approve` is one of the most expensive
> keyboard combinations in human history."*

A 2026 production guide for Terraform / OpenTofu. For newcomers and for
teams saying "we messed up, we learned our lesson" alike.

---

## 🎯 General Principles

1. **State remote, never in Git** — local state = a data-loss timer
2. **Modules versioned** — a Git tag instead of `path = "../modules/x"`
3. **Plan visible in the PR** — Atlantis or GitHub Actions
4. **Apply is not automatic** — manually approved, audit-logged
5. **`for_each` > `count`** — always
6. **Sensitive marking** — variable + output
7. **Drift is continuously monitored** — daily/weekly plan
8. **Modules < 200 lines** — split as they grow

---

## 📁 Repo Layout

### Single-cloud, small-to-mid org

```
infra/
├── modules/                    # reusable, versioned (usually a separate repo)
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   ├── eks/
│   ├── rds/
│   └── observability/
├── environments/               # composition
│   ├── prod/
│   │   ├── main.tf            # module calls
│   │   ├── variables.tf
│   │   ├── backend.tf
│   │   ├── providers.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── dev/
└── stacks/                     # cross-environment
    ├── networking/
    └── identity/
```

### Multi-cloud, large org

A separate repo per cloud, plus a "core" repo for cross-cloud concerns:

```
infra-aws/
infra-gcp/
infra-azure/
infra-cloudflare/
infra-core/        # cross-cloud DNS, identity, monitoring
```

---

## 🔐 Backend (Remote State)

### S3 + DynamoDB (AWS)

```hcl
terraform {
  required_version = ">= 1.9.0"
  backend "s3" {
    bucket         = "<COMPANY>-tfstate-<ACCOUNT>-<REGION>"
    key            = "envs/prod/network.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
    kms_key_id     = "alias/terraform-state"
  }
}
```

State bucket hardening:
- ✅ Versioning **enabled** (for rollback)
- ✅ Encryption (KMS preferred over SSE-S3)
- ✅ Public access block: **all**
- ✅ Access log → separate bucket
- ✅ Lifecycle: noncurrent → glacier after 30d, delete after 365d
- ✅ MFA delete

### Backend Bootstrap Problem

If the state backend creates itself via Terraform: **chicken-and-egg**.
Solution:
- First time, create the bucket+table with the `local` backend
- Then switch to remote with `terraform init -migrate-state`
- Or: a separate, small "bootstrap" repo (keep its own state in Git, only this one)

---

## 📦 Module Design

### Standard layout

```hcl
# main.tf — resources
resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  tags = merge(var.tags, { Name = var.name })
}

# variables.tf — input contract
variable "name" {
  type        = string
  description = "VPC name"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block (e.g., 10.0.0.0/16)"
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid CIDR."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

# outputs.tf — module API
output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC ID"
}

# versions.tf — provider dependencies
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}
```

### Module Versioning

```hcl
module "vpc" {
  source  = "git::https://github.com/<ORG>/terraform-modules.git//vpc?ref=v1.2.3"
  # or Terraform Registry:
  # source  = "<ORG>/vpc/aws"
  # version = "~> 1.2.0"

  name       = "prod"
  cidr_block = "10.0.0.0/16"
}
```

### Rules When Writing a Module

- **Single responsibility** — a module should do one thing
- **DRY but not over-abstracted** — if the same block repeats in 3 places, make it a module
- **Immutable inputs** — changing an input = `terraform apply`
- **README.md** — auto-generate with `terraform-docs`
- **Examples/** — `examples/basic/`, `examples/with-flow-logs/`

---

## 🔁 `for_each` vs `count`

### `count` (legacy)

```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = "<AMI>"
  instance_type = "t3.micro"
  tags          = { Name = "web-${count.index}" }
}
```

**Problem:** Setting `count = 2` deletes `web[2]`. But if you want to
delete `web[1]`, you shift every index → moving `web[2]` to `web[1]`.
The plan produces a huge diff and replaces resources.

### `for_each` (modern, **preferred**)

```hcl
resource "aws_instance" "web" {
  for_each      = toset(["api", "worker", "scheduler"])
  ami           = "<AMI>"
  instance_type = "t3.micro"
  tags          = { Name = each.key }
}
```

**Advantage:** access by name — `aws_instance.web["api"]`. Adding or
removing one doesn't affect the others.

### Map of objects

```hcl
variable "subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
}

# terraform.tfvars
subnets = {
  "public-a"  = { cidr = "10.0.1.0/24", az = "us-east-1a" }
  "public-b"  = { cidr = "10.0.2.0/24", az = "us-east-1b" }
}

resource "aws_subnet" "this" {
  for_each          = var.subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = { Name = each.key }
}
```

---

## 🎛️ Variables & Locals

### Variables (input)

```hcl
variable "environment" {
  type        = string
  description = "Environment name"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev/staging/prod."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to attach to resources"
  default     = {}
  validation {
    condition = alltrue([
      contains(keys(var.tags), "Team"),
      contains(keys(var.tags), "CostCenter"),
    ])
    error_message = "tags must include Team and CostCenter."
  }
}

variable "db_password" {
  type        = string
  sensitive   = true              # masked in plan/apply output
  description = "DB master password"
}
```

### Locals (computed)

```hcl
locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "infra-prod"
  })

  cluster_name = "${var.project}-${var.environment}"

  # complex calculations
  subnets = {
    for i, az in var.azs :
    "subnet-${i}" => {
      az   = az
      cidr = cidrsubnet(var.vpc_cidr, 8, i)
    }
  }
}
```

---

## 🚦 Lifecycle

```hcl
resource "aws_instance" "web" {
  # ...
  lifecycle {
    create_before_destroy = true                    # zero-downtime replace
    prevent_destroy       = true                    # prevent destroy (for DBs)
    ignore_changes        = [tags["LastModifiedBy"]] # don't count this tag as drift
    replace_triggered_by  = [aws_security_group.web.id]
  }
}
```

### When to use `prevent_destroy`?
- Production database (RDS, Aurora)
- KMS key
- Account-level resource (Organization, IAM root)
- S3 bucket (full of data)

### When to use `ignore_changes`?
- Fields AWS auto-updates (e.g., `last_modified`)
- `desired_capacity` changed by AutoScaling

---

## 🛡️ Sensitive Data

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}

output "db_endpoint" {
  value     = aws_db_instance.main.endpoint
  sensitive = true       # not visible via `terraform output`
}

# Ephemeral (Terraform 1.10+) — not even written to state
ephemeral "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/password"
}
```

> ⚠️ Sensitive but still written to state (encrypted). For a real secret,
> use an ephemeral resource or a runtime fetch (Vault provider).

---

## 🔍 Drift Detection

A scheduled plan in CI to catch manual changes:

```yaml
# .github/workflows/drift-detection.yml
on:
  schedule:
    - cron: '0 8 * * 1-5'      # every weekday at 08:00 UTC

jobs:
  detect:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        env: [dev, staging, prod]
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1
      - run: |
          cd environments/${{ matrix.env }}
          terraform init -input=false
          terraform plan -detailed-exitcode -out=tfplan -no-color > plan.txt
          # exit code: 0=no changes, 1=error, 2=changes detected
          if [ $? -eq 2 ]; then
            cat plan.txt | head -200 | curl -X POST -H 'Content-Type: text/plain' \
              --data-binary @- $SLACK_WEBHOOK
          fi
```

---

## 🧪 Testing

### Static analysis

```bash
# Format
terraform fmt -recursive -check

# Validate (syntax)
terraform validate

# tflint (style + best practice)
tflint --init && tflint --recursive

# tfsec / Checkov / KICS (security)
tfsec .
checkov -d . --framework terraform
```

> ℹ️ **tfsec → Trivy:** tfsec was consolidated into Trivy in 2023 (no new checks are coming); for new setups use `trivy config .`.

### Compliance

```bash
# OPA / Conftest (policy as code)
conftest test plan.json --policy policies/

# Sentinel (Terraform Cloud)
```

### Integration tests

```hcl
# Terratest (Go) — does the module actually create the resource?
func TestVPC(t *testing.T) {
  opts := &terraform.Options{
    TerraformDir: "./examples/basic",
    Vars: map[string]interface{}{
      "name": "test",
    },
  }
  defer terraform.Destroy(t, opts)
  terraform.InitAndApply(t, opts)
  vpcId := terraform.Output(t, opts, "vpc_id")
  assert.Contains(t, vpcId, "vpc-")
}
```

---

## 🔄 CI/CD Workflow

```
Developer push → PR open
                  │
                  ▼
            terraform fmt + validate
                  │
                  ▼
            tflint + tfsec/checkov
                  │
                  ▼
            terraform plan (comment in PR)
                  │
                  ▼
            Reviewer approval + merge
                  │
                  ▼
            terraform apply (manual approval gate)
                  │
                  ▼
            State backup
                  │
                  ▼
            Notification (Slack)
```

> 📚 [`17-Templates/github-actions/terraform-plan.yml`](../17-Templates/github-actions/terraform-plan.yml) — ready-made workflow

---

## ⚠️ Anti-patterns

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Local state | Remote (S3/GCS/Azure) + locking |
| `terraform apply -auto-approve` interactive | Plan + manual review + apply tfplan |
| State in Git | `*.tfstate` in `.gitignore` |
| "later, I'll get to it" after `terraform import` | Write the matching code in a PR immediately |
| Module path-based reference | Versioned with a Git tag |
| `count` everywhere | `for_each` (named) |
| Provider version unpinned | `~> 5.0` or `>= 5.0, < 6.0` |
| Single monolithic state | Service/env per state |
| `ignore_changes = ["*"]` | Specific fields |
| Sensitive variable plain | `sensitive = true` + Vault/SM |
| "Straight to production without going through dev first" | Promote: dev → staging → prod |

---

## 🎯 OpenTofu or Terraform?

| Topic | Terraform | OpenTofu |
|---|---|---|
| License | BSL (commercial restrictive) | Apache 2.0 |
| Maintainer | HashiCorp / IBM | Linux Foundation |
| Community | Broad, mature | New but growing fast |
| Enterprise features | Cloud, Sentinel | Cloud (no extras), Conftest/OPA |
| Backwards compat | Latest version | Up to ~1.9, then divergence |

> As of 2026, if you're starting a new project: **OpenTofu**. Migrating
> an existing project is usually painless (binary swap).

---

## 📋 Checklist

Every item must be checked before going to production. An unchecked
item = an open risk.

### State & Backend
- [ ] State is in a remote backend (S3/GCS/Azure Blob) — NO local state
- [ ] State locking is active (DynamoDB / GCS native / Azure lease)
- [ ] Versioning enabled on the state bucket (for rollback)
- [ ] State encryption with KMS (not SSE-S3)
- [ ] Bucket public access block: all + access logging to a separate bucket
- [ ] `*.tfstate` and `*.tfstate.backup` are in `.gitignore`
- [ ] A separate state key per env/service (NO monolithic state)

### Code & Modules
- [ ] `required_version` and all providers pinned (`~> 5.0` / `>= 5.0, < 6.0`)
- [ ] `.terraform.lock.hcl` committed (with multi-platform hashes)
- [ ] Modules referenced via Git tag / Registry version — NO path-based refs
- [ ] `for_each` is used (instead of `count` wherever possible)
- [ ] All `variable`s have `type` + `description`, critical ones have `validation`
- [ ] `terraform fmt -recursive -check` is clean
- [ ] `terraform validate` and `tflint --recursive` error-free

### Security
- [ ] Sensitive variables/outputs marked `sensitive = true`
- [ ] Real secrets come from Vault/Secrets Manager or an ephemeral resource
- [ ] tfsec/Checkov scan runs in CI, NO critical findings
- [ ] OPA/Conftest policy gate runs against the plan
- [ ] Provider credentials via OIDC/role-assume (NO long-lived keys)

### Lifecycle & Safe Apply
- [ ] `prevent_destroy = true` on critical resources (RDS, KMS, prod bucket)
- [ ] Changes requiring replacement use `create_before_destroy`
- [ ] `ignore_changes` on specific fields (NO `["*"]`)
- [ ] Plan is visible in the PR (Atlantis / GHA comment)
- [ ] Apply is behind a manual approval gate, audit-logged — NO `-auto-approve`
- [ ] A state backup step before apply is in the pipeline

### Operations
- [ ] Drift detection scheduled (daily/weekly) + alarm (Slack/PagerDuty)
- [ ] Promote order is enforced: dev → staging → prod
- [ ] Modules have `README.md` (terraform-docs) and `examples/`
- [ ] Integration tests (Terratest/`tofu test`) for critical modules
- [ ] Backend bootstrap chicken-and-egg solution documented (`-migrate-state`)

---

## 📚 Further Reading

- [Terraform official docs](https://www.terraform.io/docs)
- [OpenTofu docs](https://opentofu.org)
- [Awesome Terraform](https://github.com/shuaibiyy/awesome-terraform)
- [`17-Templates/github-actions/terraform-plan.yml`](../17-Templates/github-actions/terraform-plan.yml)
- [`16-Cheatsheets/terraform.md`](../16-Cheatsheets/terraform.md)

---

## 📚 References

- [Module Layout](Terraform-Module-Layout.md) — module skeleton and versioning details
- [Drift Detection](Drift-Detection.md) — scheduled plan and alarm setup
- [OpenTofu Migration](OpenTofu-Migration.md) — migration steps via binary swap
- [Pulumi vs Terraform](Pulumi-vs-Terraform.md) — IaC tool comparison
- [Policy as Code (OPA/Kyverno)](../08-Security/Policy-as-Code-OPA-Kyverno.md) — policy gate on the plan
- [Secrets Management](../08-Security/Secrets-Management.md) — real secret management with Vault/SM

---

> *"What makes Terraform safe isn't the code; it's the locked remote state, the plan visible in the PR, the manual apply behind an approval gate, and continuous drift monitoring — without those, what you have is just an expensive weapon."*

---

> 🎓 **Learning Path:** This document is used as the "Read first" resource in the [`C3`](../22-Learning-Path/block-c-reproducibility/C3-terraform.md) module.
