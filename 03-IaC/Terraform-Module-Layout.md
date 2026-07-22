---
description: "Terraform/OpenTofu repo yapısı ve module tasarımı rehberi: mono/multi repo modelleri, vpc/eks/rds modül iskeleti, versioning ve composition pattern örnekleri."
tags:
  - IaC
  - Terraform
  - Template
  - Networking
---
# Terraform Module Layout — Repo Yapısı + Module Tasarımı

> *"50 service için tek `main.tf` 5000 satır oldu. **Module yok**,
> kopya-yapıştır cehennemi. Doğru module layout = **maintenance
> 10x kolay**."*

Bu rehber Terraform/OpenTofu için repo yapısı, module tasarımı,
versioning, ve composition pattern'ini somut örneklerle anlatır.

---

## 📐 3 Repo Yapı Modeli

### Model A: Tek Repo (mono)
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

> ✅ Küçük-orta team, tek cloud, tek bölge.

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

→ Her module bağımsız semver. `module "vpc" { source = "git::...//modules/vpc?ref=v1.4.0" }`.

> ✅ Büyük org, multi-team, multi-cloud.

### Model C: Terraform Cloud / Spacelift Workspaces
- Her environment = ayrı workspace
- State backend Terraform Cloud / Spacelift
- Module registry kullanılır

> ✅ Enterprise, governance ihtiyacı yüksek.

---

## 🧱 Module Anatomi

### Standart yapı
```
modules/rds/
├── main.tf              # ana resource'lar
├── variables.tf         # input
├── outputs.tf           # output
├── versions.tf          # Terraform + provider version
├── README.md            # nasıl kullanılır
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

### Örnek: VPC module

#### `variables.tf`
```hcl
variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Geçerli CIDR olmalı."
  }
}

variable "name" {
  description = "VPC name"
  type        = string
}

variable "availability_zones" {
  description = "AZ listesi"
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

## 🎯 Module Tasarım Prensipleri

### 1. **Single Responsibility**
- Module bir şey yapsın (VPC, RDS, EKS — ayrı)
- "Mega module" — 5+ farklı resource grupları → böl

### 2. **Sensible Defaults**
```hcl
variable "instance_class" {
  default = "db.t3.medium"   # makul default
}

variable "allocated_storage" {
  default = 50
}
```

→ User minimum config ile çalıştırabilsin.

### 3. **Versionlu Provider**
```hcl
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 5.50"   # ~> 5.50.* (5.50.x kabul, 5.51 değil)
  }
}
```

### 4. **Validation**
```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment dev, staging, veya prod olmalı."
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
  sensitive = true   # state'te encrypted
}
```

### 6. **README + Examples**
Her module'ün README:
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

> 🔑 **terraform-docs** otomatik oluşturur:
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

### S3 backend (önerilen)
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

> ℹ️ **tfsec → Trivy:** tfsec 2023'te Trivy'ye konsolide edildi (yeni check gelmiyor); yeni kurulumda `trivy config .` kullan.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tek `main.tf` 5000 satır | Maintenance hell | Module split |
| Module versioning yok | Breaking change sürpriz | Semver tag |
| Provider version pin yok | Drift | `~> 5.50` |
| State remote backend yok | Local state, paylaşım yok | S3 + DynamoDB lock |
| State şifrelenmemiş | Secret leak (compromise) | KMS encrypt |
| Tüm secret variable.tf'te plain | Compromise | Vault / AWS Secrets Manager + data source |
| Module README + example yok | Kullanım belirsiz | terraform-docs |
| `terraform apply` doğrudan prod'da | Review yok | PR + plan output review |
| `count` vs `for_each` karıştırma | Resource yeniden yarat | for_each (key-stable) |
| Output sensitive=false | State'te plain | sensitive=true |
| tfvars Git'te (secret içerir) | Compromise | tfvars `.gitignore`'da, Vault'tan al |
| Module nested 5+ derin | Debug zor | Max 2-3 derin |

---

## 📋 Module + Layout Checklist

```
[ ] Repo yapısı seçildi (mono / per-module / Terraform Cloud)
[ ] Standard module structure (main/variables/outputs/versions)
[ ] Variable validation
[ ] Sensible defaults
[ ] Provider version pin (`~> X.Y`)
[ ] Module versioning (semver tag)
[ ] README + example per module
[ ] terraform-docs ile auto-generate
[ ] State backend: S3 + DynamoDB lock + KMS
[ ] State versioning
[ ] tfvars Git'te değil, `.gitignore`'da
[ ] CI: tflint + tfsec + checkov
[ ] terratest unit + integration
[ ] PR review zorunlu (CODEOWNERS)
[ ] Plan output PR'da görünür (Atlantis / Spacelift)
[ ] Drift detection cron (haftalık plan diff)
```

---

## 📚 Referanslar

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

> *"Module layout 'kişisel zevk' değil — **ekibin maintenance
> rahatlığı**. Doğru struct ile 50 service tek YAML editi gibi
> olur; yanlış struct'la 5 service 'mı kopyaladım, mı edit ettim'
> karmaşası."*

---

> 🎓 **Öğrenme Patikası:** Bu doküman [`C3`](../22-Learning-Path/block-c-reproducibility/C3-terraform.md) modülünde "Önce oku" kaynağı olarak kullanılıyor.
