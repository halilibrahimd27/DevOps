---
description: "Terraform/OpenTofu 2026 production rehberi: remote state, versiyonlu module, PR'da plan, manuel apply, for_each, sensitive marking ve sürekli drift izleme."
tags:
  - IaC
  - Terraform
  - CI/CD
  - Security
---
# Terraform Best Practices

> *"Terraform `apply -auto-approve` insanlığın en pahalı klavye
> kombinasyonlarından biridir."*

Terraform / OpenTofu için 2026 production rehberi. Hem yeni başlayanlar
hem de "hata yaptık, ders aldık" diyen ekipler için.

---

## 🎯 Genel prensipler

1. **State remote, Git'te asla** — local state = veri kaybı timer'ı
2. **Module versiyonlu** — `path = "../modules/x"` yerine Git tag'i
3. **Plan PR'da görünür** — atlantis veya GitHub Actions
4. **Apply otomatik değil** — manuel onaylı, audit log'lu
5. **`for_each` > `count`** — her zaman
6. **Sensitive marking** — variable + output
7. **Drift sürekli izlenir** — daily/weekly plan
8. **Module < 200 satır** — büyürken parçala

---

## 📁 Repo Layout

### Tek-cloud, küçük-orta org

```
infra/
├── modules/                    # reusable, versiyonlu (genelde ayrı repo)
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
│   │   ├── main.tf            # module çağrıları
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

### Multi-cloud, büyük org

Her cloud için ayrı repo + cross-cloud için "core" repo:

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

State bucket sertifikalı:
- ✅ Versioning **enabled** (rollback için)
- ✅ Encryption (KMS preferred over SSE-S3)
- ✅ Public access block: **all**
- ✅ Access log → ayrı bucket
- ✅ Lifecycle: noncurrent → glacier 30g, sil 365g
- ✅ MFA delete

### Backend bootstrap problemi

State backend kendisini Terraform ile yaratıyorsanız: **chicken-and-egg**.
Çözüm:
- İlk seferinde `local` backend ile bucket+table yarat
- Sonra `terraform init -migrate-state` ile remote'a geç
- Veya: ayrı, küçük "bootstrap" repo'su (state'ini Git'te tut, sadece bu)

---

## 📦 Module Tasarımı

### Standard layout

```hcl
# main.tf — kaynaklar
resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  tags = merge(var.tags, { Name = var.name })
}

# variables.tf — input contract
variable "name" {
  type        = string
  description = "VPC adı"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block (örn: 10.0.0.0/16)"
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Geçerli CIDR olmalı."
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

# versions.tf — provider bağımlılıkları
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

### Module versiyonlama

```hcl
module "vpc" {
  source  = "git::https://github.com/<ORG>/terraform-modules.git//vpc?ref=v1.2.3"
  # ya da Terraform Registry:
  # source  = "<ORG>/vpc/aws"
  # version = "~> 1.2.0"

  name       = "prod"
  cidr_block = "10.0.0.0/16"
}
```

### Module yazarken kuralları

- **Single responsibility** — bir module bir şey yapsın
- **DRY ama over-abstract değil** — aynı blok 3 yerde tekrar ediyorsa modül yap
- **Immutable inputs** — input değişikliği = `terraform apply`
- **README.md** — `terraform-docs` ile auto-generate
- **Examples/** — `examples/basic/`, `examples/with-flow-logs/`

---

## 🔁 `for_each` vs `count`

### `count` (eski)

```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = "<AMI>"
  instance_type = "t3.micro"
  tags          = { Name = "web-${count.index}" }
}
```

**Sorun:** `count = 2` yapınca `web[2]` silinir. Ama eğer `web[1]` silmek
istiyorsan tüm sıralamaları kaydırırsın → `web[2]`'i `web[1]`'e taşıma.
Plan büyük diff verir, replace eder.

### `for_each` (modern, **tercih**)

```hcl
resource "aws_instance" "web" {
  for_each      = toset(["api", "worker", "scheduler"])
  ami           = "<AMI>"
  instance_type = "t3.micro"
  tags          = { Name = each.key }
}
```

**Avantaj:** isimle erişim — `aws_instance.web["api"]`. Ekleyip silerken
diğerleri etkilenmiyor.

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
  description = "Ortam adı"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment dev/staging/prod olmalı."
  }
}

variable "tags" {
  type        = map(string)
  description = "Resource'lara eklenecek tag'ler"
  default     = {}
  validation {
    condition = alltrue([
      contains(keys(var.tags), "Team"),
      contains(keys(var.tags), "CostCenter"),
    ])
    error_message = "tags Team ve CostCenter içermeli."
  }
}

variable "db_password" {
  type        = string
  sensitive   = true              # plan/apply çıktısında masklenir
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
    prevent_destroy       = true                    # destroy engelle (DB için)
    ignore_changes        = [tags["LastModifiedBy"]] # bu tag'i drift sayma
    replace_triggered_by  = [aws_security_group.web.id]
  }
}
```

### `prevent_destroy` ne zaman?
- Production database (RDS, Aurora)
- KMS key
- Account-level resource (Organization, IAM root)
- S3 bucket (data ile dolu)

### `ignore_changes` ne zaman?
- AWS auto-update'lediği fields (örn: `last_modified`)
- AutoScaling tarafından değişen `desired_capacity`

---

## 🛡️ Sensitive Data

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}

output "db_endpoint" {
  value     = aws_db_instance.main.endpoint
  sensitive = true       # `terraform output` ile görünmez
}

# Ephemeral (Terraform 1.10+) — state'e bile yazılmaz
ephemeral "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/password"
}
```

> ⚠️ Sensitive ama state'te yazılır (encrypted). Real secret için
> ephemeral resource veya runtime fetch (Vault provider) kullan.

---

## 🔍 Drift Detection

Manuel değişiklikleri yakalamak için CI'da scheduled plan:

```yaml
# .github/workflows/drift-detection.yml
on:
  schedule:
    - cron: '0 8 * * 1-5'      # her iş günü 08:00 UTC

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

> ℹ️ **tfsec → Trivy:** tfsec 2023'te Trivy'ye konsolide edildi (yeni check gelmiyor); yeni kurulumda `trivy config .` kullan.

### Compliance

```bash
# OPA / Conftest (policy as code)
conftest test plan.json --policy policies/

# Sentinel (Terraform Cloud)
```

### Integration tests

```hcl
# Terratest (Go) — module gerçekten resource yaratıyor mu?
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
            terraform plan (PR'da comment)
                  │
                  ▼
            Reviewer onayı + merge
                  │
                  ▼
            terraform apply (manuel approval gate)
                  │
                  ▼
            State backup
                  │
                  ▼
            Notification (Slack)
```

> 📚 [`17-Templates/github-actions/terraform-plan.yml`](../17-Templates/github-actions/terraform-plan.yml) — hazır workflow

---

## ⚠️ Anti-pattern'ler

| ❌ Anti-pattern | ✅ Doğru |
|---|---|
| Local state | Remote (S3/GCS/Azure) + locking |
| `terraform apply -auto-approve` interactive | Plan + manual review + apply tfplan |
| State Git'te | `*.tfstate` `.gitignore`'da |
| `terraform import` sonrası "bekle, ben bakarım" | İmmediately PR ile karşılığı yaz |
| Module path-based reference | Git tag'li versiyonlu |
| `count` her yerde | `for_each` (named) |
| Provider version unpinned | `~> 5.0` ya da `>= 5.0, < 6.0` |
| Single monolithic state | Service/env per state |
| `ignore_changes = ["*"]` | Spesifik field'lar |
| Sensitive variable plain | `sensitive = true` + Vault/SM |
| "Production'a önce dev'e geçmeden" | Promote: dev → staging → prod |

---

## 🎯 OpenTofu mu Terraform mu?

| Konu | Terraform | OpenTofu |
|---|---|---|
| Lisans | BSL (commercial restrictive) | Apache 2.0 |
| Maintainer | HashiCorp / IBM | Linux Foundation |
| Community | Geniş, mature | Yeni ama hızla büyüyor |
| Enterprise features | Cloud, Sentinel | Cloud (ek yok), Conftest/OPA |
| Backwards compat | Latest version | Up to ~1.9, sonra divergence |

> 2026 itibarıyla yeni proje açıyorsanız: **OpenTofu**. Mevcut projeyi
> migrate etmek genelde sorunsuz (binary swap).

---

## 📋 Checklist

Production'a çıkmadan önce her madde işaretlenmeli. İşaretlenmeyen madde =
açık risk.

### State & Backend
- [ ] State remote backend'de (S3/GCS/Azure Blob) — local state YOK
- [ ] State locking aktif (DynamoDB / GCS native / Azure lease)
- [ ] State bucket'ta versioning enabled (rollback için)
- [ ] State encryption KMS ile (SSE-S3 değil)
- [ ] Bucket public access block: all + access logging ayrı bucket'a
- [ ] `*.tfstate` ve `*.tfstate.backup` `.gitignore`'da
- [ ] Her env/service için ayrı state key (monolitik state YOK)

### Kod & Module
- [ ] `required_version` ve tüm provider'lar pinned (`~> 5.0` / `>= 5.0, < 6.0`)
- [ ] `.terraform.lock.hcl` commit'lenmiş (multi-platform hash'lerle)
- [ ] Module'ler Git tag / Registry version ile referanslı — path-based YOK
- [ ] `for_each` kullanılıyor (mümkün olan her yerde `count` yerine)
- [ ] Tüm `variable`'larda `type` + `description`, kritiklerinde `validation`
- [ ] `terraform fmt -recursive -check` temiz
- [ ] `terraform validate` ve `tflint --recursive` hatasız

### Güvenlik
- [ ] Sensitive değişken/output'lar `sensitive = true`
- [ ] Gerçek secret'lar Vault/Secrets Manager veya ephemeral resource'tan
- [ ] tfsec/Checkov taraması CI'da, kritik bulgu YOK
- [ ] OPA/Conftest policy gate plan üzerinde çalışıyor
- [ ] Provider credential'ları OIDC/role-assume ile (uzun ömürlü key YOK)

### Lifecycle & Güvenli Apply
- [ ] Kritik kaynaklarda (RDS, KMS, prod bucket) `prevent_destroy = true`
- [ ] Replace gerektiren değişiklikler `create_before_destroy` ile
- [ ] `ignore_changes` spesifik field'larda (`["*"]` YOK)
- [ ] Plan PR'da görünür (Atlantis / GHA comment)
- [ ] Apply manuel onay gate'inin arkasında, audit log'lu — `-auto-approve` YOK
- [ ] Apply öncesi state backup adımı pipeline'da

### Operasyon
- [ ] Drift detection scheduled (daily/weekly) + alarm (Slack/PagerDuty)
- [ ] Promote sırası uygulanıyor: dev → staging → prod
- [ ] Module'lerde `README.md` (terraform-docs) ve `examples/` var
- [ ] Kritik module'ler için Terratest/`tofu test` entegrasyon testi
- [ ] Backend bootstrap chicken-and-egg çözümü dokümante (`-migrate-state`)

---

## 📚 Devamı

- [Terraform official docs](https://www.terraform.io/docs)
- [OpenTofu docs](https://opentofu.org)
- [Awesome Terraform](https://github.com/shuaibiyy/awesome-terraform)
- [`17-Templates/github-actions/terraform-plan.yml`](../17-Templates/github-actions/terraform-plan.yml)
- [`16-Cheatsheets/terraform.md`](../16-Cheatsheets/terraform.md)

---

## 📚 Referanslar

- [Module Layout](Terraform-Module-Layout.md) — module iskeleti ve versiyonlama detayı
- [Drift Detection](Drift-Detection.md) — scheduled plan ve alarm kurulumu
- [OpenTofu Migration](OpenTofu-Migration.md) — binary swap ile geçiş adımları
- [Pulumi vs Terraform](Pulumi-vs-Terraform.md) — IaC araç karşılaştırması
- [Policy as Code (OPA/Kyverno)](../08-Security/Policy-as-Code-OPA-Kyverno.md) — plan üzerinde policy gate
- [Secrets Management](../08-Security/Secrets-Management.md) — Vault/SM ile gerçek secret yönetimi

---

> *"Terraform'u güvenli yapan kod değil; kilitli remote state, PR'da görünen plan, onay gate'inin arkasındaki manuel apply ve sürekli drift izlemedir — bunlar yoksa elindeki sadece pahalı bir silahtır."*

---

> 🎓 **Öğrenme Patikası:** Bu doküman [`C3`](../22-Learning-Path/block-c-reproducibility/C3-terraform.md) modülünde "Önce oku" kaynağı olarak kullanılıyor.
