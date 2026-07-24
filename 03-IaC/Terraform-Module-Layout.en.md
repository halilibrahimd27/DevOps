---
description: "Terraform/OpenTofu repo layout and module design guide: mono/multi-repo models, vpc/eks/rds module skeletons, versioning and composition pattern examples."
tags:
  - IaC
  - Terraform
  - Template
  - Networking
---
# Terraform Module Layout — Repo Layout + Module Design

> *"A single `main.tf` for 50 services turned into 5000 lines. **No
> modules**, copy-paste hell. The right module layout = **10x easier
> maintenance**."*

This guide covers repo layout, module design, versioning, and
composition patterns for Terraform/OpenTofu with concrete examples.

---

## 📐 3 Repo Layout Models

### Model A: Single Repo (mono)
```
infra/
├── modules/                      ← reusable
│   ├── vpc/
│   ├── eks/
│   ├── rds/
│   └── s3/
├── environments/
│   ├── dev/
│   │   └── main.tf
│   ├── staging/
│   │   └── main.tf
│   └── prod/
│       └── main.tf
└── README.md
```

> ✅ Small-to-mid team, single cloud, single region.

### Model B: Repo per Module + Versioned
```
infra-modules-vpc/
├── main.tf
├── variables.tf
├── outputs.tf
├── README.md
└── examples/
    └── basic/

infra-modules-eks/
├── ...

infra-environments/
├── dev/
├── staging/
└── prod/
```

→ Each module gets its own independent semver. `module "vpc" { source = "git::...//modules/vpc?ref=v1.4.0" }`.

> ✅ Large org, multi-team, multi-cloud.

### Model C: Terraform Cloud / Spacelift Workspaces
- Each environment = a separate workspace
- State backend: Terraform Cloud / Spacelift
- Uses a module registry

> ✅ Enterprise, high governance needs.

---

## 🧱 Module Anatomy

### Standard layout
```
modules/rds/
├── main.tf              # main resources
├── variables.tf         # input
├── outputs.tf           # output
├── versions.tf          # Terraform + provider version
├── README.md            # how to use
├── examples/
│   ├── basic/
│   │   ├── main.tf
│   │   └── README.md
│   └── ha/
│       ├── main.tf
│       └── README.md
└── tests/
    └── basic_test.go    # terratest
```

### Example: VPC module

#### `variables.tf`
```hcl
variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid CIDR."
  }
}

variable "name" {
  description = "VPC name"
  type        = string
}

variable "availability_zones" {
  description = "List of AZs"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

#### `main.tf`
```hcl
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_subnet" "private" {
  for_each = toset(var.availability_zones)

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.cidr_block, 4, index(var.availability_zones, each.key))

  tags = merge(var.tags, {
    Name = "${var.name}-private-${each.key}"
    Tier = "private"
  })
}
```

#### `outputs.tf`
```hcl
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = [for s in aws_subnet.private : s.id]
}
```

#### `versions.tf`
```hcl
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }
}
```

---

## 🎯 Module Design Principles

### 1. **Single Responsibility**
- A module should do one thing (VPC, RDS, EKS — separate)
- "Mega module" — 5+ different resource groups → split it

### 2. **Sensible Defaults**
```hcl
variable "instance_class" {
  default = "db.t3.medium"   # sensible default
}

variable "allocated_storage" {
  default = 50
}
```

→ Let the user run it with a minimal config.

### 3. **Versioned Provider**
```hcl
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 5.50"   # ~> 5.50.* (5.50.x accepted, not 5.51)
  }
}
```

### 4. **Validation**
```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### 5. **Output Documentation**
```hcl
output "rds_endpoint" {
  description = "RDS endpoint (host:port)"
  value       = aws_db_instance.main.endpoint
  sensitive   = false
}

output "rds_password" {
  value     = aws_db_instance.main.password
  sensitive = true   # encrypted in state
}
```

### 6. **README + Examples**
Every module's README:
```markdown
# RDS Module

## Usage

```hcl
module "payments_db" {
  source = "git::...//modules/rds?ref=v1.4.0"

  identifier        = "payments"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t3.medium"
  allocated_storage = 100
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids

  tags = local.tags
}
```

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| identifier | RDS instance name | string | - | yes |

## Outputs
| Name | Description |
|------|-------------|
| endpoint | RDS endpoint |
```

> 🔑 **terraform-docs** generates this automatically:
> ```bash
> terraform-docs markdown table . > README.md
> ```

---

## 🔄 Composition (Module + Module)

### Environment-level composition
```hcl
# environments/prod/main.tf

module "vpc" {
  source = "git::...//modules/vpc?ref=v1.4.0"

  name              = "prod"
  cidr_block        = "10.0.0.0/16"
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  tags = local.tags
}

module "eks" {
  source = "git::...//modules/eks?ref=v2.1.0"

  cluster_name    = "prod"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  cluster_version = "1.30"

  tags = local.tags
}

module "rds_payments" {
  source = "git::...//modules/rds?ref=v1.4.0"

  identifier     = "payments-prod"
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  instance_class = "db.r5.large"

  tags = local.tags
}
```

### Locals + tags
```hcl
locals {
  environment = "prod"
  tags = {
    Environment  = local.environment
    ManagedBy    = "terraform"
    CostCenter   = "platform"
    Owner        = "platform-team"
  }
}
```

---

## 🛠️ Backend + State

### S3 backend (recommended)
```hcl
terraform {
  backend "s3" {
    bucket         = "<TFSTATE_BUCKET>"
    key            = "prod/terraform.tfstate"
    region         = "<REGION>"
    encrypt        = true
    dynamodb_table = "terraform-locks"
    kms_key_id     = "<KMS_KEY>"
  }
}
```

### Backend bucket setup
```bash
aws s3api create-bucket --bucket <TFSTATE_BUCKET>
aws s3api put-bucket-versioning --bucket <TFSTATE_BUCKET> \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket <TFSTATE_BUCKET> \
  --server-side-encryption-configuration '{...}'

aws dynamodb create-table --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

---

## 🧪 Module Testing

### terratest
```go
package test

import (
  "testing"
  "github.com/gruntwork-io/terratest/modules/terraform"
  "github.com/stretchr/testify/assert"
)

func TestVPC(t *testing.T) {
  opts := &terraform.Options{
    TerraformDir: "../examples/basic",
    Vars: map[string]interface{}{
      "cidr_block": "10.99.0.0/16",
      "name":       "test-vpc",
    },
  }

  defer terraform.Destroy(t, opts)
  terraform.InitAndApply(t, opts)

  vpcID := terraform.Output(t, opts, "vpc_id")
  assert.NotEmpty(t, vpcID)
}
```

### Static analysis
```bash
# tflint: best practices
tflint --recursive

# tfsec: security
tfsec .

# checkov: compliance
checkov -d .

# OPA / Conftest: custom policy
conftest test --policy=policies/ main.tf
```

> ℹ️ **tfsec → Trivy:** tfsec was consolidated into Trivy in 2023 (no new checks are coming); for new setups use `trivy config .`.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| A single 5000-line `main.tf` | Maintenance hell | Module split |
| No module versioning | Breaking change surprise | Semver tag |
| No provider version pin | Drift | `~> 5.50` |
| No remote state backend | Local state, no sharing | S3 + DynamoDB lock |
| State unencrypted | Secret leak (on compromise) | KMS encrypt |
| All secrets plain in variable.tf | Compromise | Vault / AWS Secrets Manager + data source |
| No module README + example | Usage unclear | terraform-docs |
| `terraform apply` directly on prod | No review | PR + plan output review |
| Mixing up `count` vs `for_each` | Resource recreation | for_each (key-stable) |
| Output sensitive=false | Plain in state | sensitive=true |
| tfvars in Git (contains secrets) | Compromise | tfvars in `.gitignore`, fetch from Vault |
| Module nesting 5+ deep | Hard to debug | Max 2-3 deep |

---

## 📋 Module + Layout Checklist

```
[ ] Repo layout chosen (mono / per-module / Terraform Cloud)
[ ] Standard module structure (main/variables/outputs/versions)
[ ] Variable validation
[ ] Sensible defaults
[ ] Provider version pin (`~> X.Y`)
[ ] Module versioning (semver tag)
[ ] README + example per module
[ ] Auto-generated with terraform-docs
[ ] State backend: S3 + DynamoDB lock + KMS
[ ] State versioning
[ ] tfvars not in Git, in `.gitignore`
[ ] CI: tflint + tfsec + checkov
[ ] terratest unit + integration
[ ] PR review mandatory (CODEOWNERS)
[ ] Plan output visible in PR (Atlantis / Spacelift)
[ ] Drift detection cron (weekly plan diff)
```

---

## 📚 References

- **Terraform Module Best Practices** — terraform.io/docs/modules
- **terraform-docs** — terraform-docs.io
- **terratest** — terratest.gruntwork.io
- **tflint** — github.com/terraform-linters/tflint
- **tfsec** — aquasecurity.github.io/tfsec
- **checkov** — checkov.io
- **Atlantis** — runatlantis.io
- [`Terraform-Best-Practices.md`](Terraform-Best-Practices.md)
- [`OpenTofu-Migration.md`](OpenTofu-Migration.md)
- [`Drift-Detection.md`](Drift-Detection.md)
- [`Crossplane-Intro.md`](Crossplane-Intro.md)

---

> *"Module layout isn't 'personal taste' — it's **the team's maintenance
> comfort**. With the right structure, 50 services feel like a single
> YAML edit; with the wrong structure, 5 services turn into a 'did I
> copy it or edit it' mess."*

---

> 🎓 **Learning Path:** This document is used as the "Read first" resource in the [`C3`](../22-Learning-Path/block-c-reproducibility/C3-terraform.md) module.
