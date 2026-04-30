# Terraform / OpenTofu Cheatsheet

> Komutlar `terraform` ve `tofu` için aynıdır. OpenTofu fork sonrası
> Apache 2.0 lisanslıdır; production için tercih edilebilir.

## 🚀 Workflow Temel

```bash
# Init (provider'ları indir, backend'i hazırla)
terraform init
terraform init -upgrade              # provider'ları yükselt
terraform init -reconfigure          # backend ayarlarını yenile
terraform init -migrate-state        # backend değiştiriyorsan

# Format
terraform fmt
terraform fmt -recursive
terraform fmt -check                 # CI'da: değişiklik varsa fail

# Validate
terraform validate
terraform validate -json | jq

# Plan
terraform plan
terraform plan -out=tfplan           # plan'i kaydet
terraform plan -var="region=us-east-1"
terraform plan -var-file=prod.tfvars
terraform plan -target=aws_instance.web    # belirli kaynağa
terraform plan -refresh=false        # state'i yenileme (hızlı)

# Apply
terraform apply
terraform apply tfplan               # kayıtlı plan'i uygula
terraform apply -auto-approve        # dikkatli kullan; CI dışında YAPMA
terraform apply -var-file=prod.tfvars

# Destroy
terraform destroy
terraform destroy -target=aws_instance.tmp
```

## 🗂️ State Operations

```bash
# State içeriğini gör
terraform state list
terraform state show aws_instance.web

# Bir kaynağı state'ten çıkar (silmeden)
terraform state rm aws_instance.web

# Mevcut bir kaynağı state'e import et
terraform import aws_instance.web i-1234567890abcdef0

# Kaynağı yeniden adlandır
terraform state mv aws_instance.old aws_instance.new

# State backup
terraform state pull > state.backup.json

# State push (backup'tan geri yükleme)
terraform state push state.backup.json

# Refresh (sadece state'i provider'la senkronla, plan oluşturma)
terraform apply -refresh-only
```

## 📦 Module Layout

```
terraform/
├── modules/
│   └── my-module/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── README.md (terraform-docs ile auto-generate)
└── environments/
    ├── prod/
    │   ├── main.tf
    │   ├── backend.tf
    │   └── terraform.tfvars
    └── dev/
        └── ...
```

### Module çağırma

```hcl
module "vpc" {
  source  = "git::https://github.com/<ORG>/<REPO>.git//modules/vpc?ref=v1.2.3"
  # ya da:
  source  = "../../modules/vpc"

  cidr_block       = "10.0.0.0/16"
  azs              = ["us-east-1a", "us-east-1b"]
  enable_flow_logs = true
}

# Output kullan
output "vpc_id" {
  value = module.vpc.vpc_id
}
```

## 🔐 Backend (Remote State)

```hcl
# S3 + DynamoDB locking
terraform {
  backend "s3" {
    bucket         = "<COMPANY>-terraform-state"
    key            = "envs/prod/network.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

# GCS
terraform {
  backend "gcs" {
    bucket = "<COMPANY>-terraform-state"
    prefix = "envs/prod"
  }
}

# Azure
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "<COMPANY>tfstate"
    container_name       = "tfstate"
    key                  = "prod.tfstate"
  }
}
```

## 🎛️ Variables

```hcl
# variables.tf
variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
  validation {
    condition     = can(regex("^us-|^eu-", var.region))
    error_message = "Region us- veya eu- ile başlamalı."
  }
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

variable "subnets" {
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))
}
```

```bash
# CLI'dan ver
terraform plan -var="region=eu-west-1"

# tfvars dosyası
terraform plan -var-file=prod.tfvars
# Otomatik yüklenir: terraform.tfvars, *.auto.tfvars

# Env vars (TF_VAR_<isim>)
export TF_VAR_region=eu-west-1
terraform plan
```

## 🔄 for_each ve count

```hcl
# count (eski, sıralı listeler için)
resource "aws_instance" "web" {
  count         = 3
  ami           = "<AMI_ID>"
  instance_type = "t3.micro"
  tags = { Name = "web-${count.index}" }
}

# for_each (modern, isimli kaynaklar için — TERCIH EDİLEN)
resource "aws_instance" "web" {
  for_each      = toset(["api", "worker", "scheduler"])
  ami           = "<AMI_ID>"
  instance_type = "t3.micro"
  tags = { Name = each.key }
}

resource "aws_subnet" "this" {
  for_each   = { for s in var.subnets : s.name => s }
  vpc_id     = aws_vpc.main.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
}
```

## 🧮 Functions

```hcl
# String
upper("hello")              # "HELLO"
format("%d-%s", 42, "x")    # "42-x"
replace("foo-bar", "-", "_")
join(",", ["a", "b", "c"]) # "a,b,c"
split(",", "a,b,c")        # ["a","b","c"]

# List/Map
length([1,2,3])             # 3
contains([1,2,3], 2)        # true
keys({a=1, b=2})            # ["a","b"]
values({a=1, b=2})
merge({a=1}, {b=2})         # {a=1, b=2}
concat([1,2], [3,4])

# Numeric
max(1, 2, 3)
min(1, 2, 3)
ceil(4.2)
floor(4.8)

# Type
tostring(123)
tonumber("42")
tolist(toset([1,2,3]))

# File
file("scripts/init.sh")
templatefile("user-data.tpl", { region = var.region })
filebase64sha256("app.zip")

# Encoding
jsonencode({a=1})
yamlencode({a=1})
base64encode("hello")

# Conditional
var.env == "prod" ? "m5.large" : "t3.micro"

# Try (graceful fallback)
try(local.maybe_undefined, "default")
```

## 🔍 Console (REPL)

```bash
terraform console
> aws_instance.web.public_ip
> [for s in var.subnets : s.cidr]
> length(module.vpc.subnet_ids)
> can(regex("^prod", "production"))
```

## 🚦 Workspaces (multi-env, basit kullanım için)

```bash
terraform workspace list
terraform workspace new prod
terraform workspace select dev
terraform workspace show
terraform workspace delete dev

# State'te kullanım:
# terraform.workspace == "prod"
```

> ⚠️ Workspaces küçük projelerde iyi; büyük org'larda **environment-per-directory**
> daha temiz (her env'in kendi backend.tf, variables, vs olur).

## 🔒 Sensitive

```hcl
variable "db_password" {
  type      = string
  sensitive = true               # plan/apply çıktısında gizler
}

output "db_endpoint" {
  value     = aws_db_instance.main.endpoint
  sensitive = true
}
```

## 📐 Lifecycle

```hcl
resource "aws_instance" "web" {
  # ...
  lifecycle {
    create_before_destroy = true   # zero-downtime replacement
    prevent_destroy       = true   # `terraform destroy` engelle
    ignore_changes        = [tags["LastModifiedBy"]]
    replace_triggered_by  = [aws_security_group.web.id]
  }
}
```

## 🩺 Diagnostic

```bash
# Provider tracing log
TF_LOG=DEBUG terraform plan
TF_LOG=TRACE TF_LOG_PATH=tf.log terraform apply

# Provider versiyonlarını gör
terraform version
terraform providers
terraform providers schema -json | jq

# Dependency graph
terraform graph | dot -Tpng > graph.png      # graphviz gerekir
```

## 📝 Önerilen .tflint.hcl

```hcl
plugin "aws" {
    enabled = true
    version = "0.30.0"
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "terraform" {
    enabled = true
    preset  = "recommended"
}
```

## 📋 İyi pratikler özet

- ✅ `terraform.lock.hcl` **commit'le** (versiyon reproducibility)
- ✅ State **remote** (S3+DynamoDB / GCS / Azure)
- ✅ State **encrypt** + bucket versioning + access log
- ✅ `for_each` > `count`
- ✅ Module versiyonlu (Git tag, registry)
- ✅ `terraform plan` PR'da otomatik (atlantis / GH Actions)
- ✅ `terraform fmt -check` + `tflint` + `tfsec` CI'da
- ✅ Sensitive variable'lar `sensitive = true`
- ✅ Production'a `apply` sadece pipeline'dan
- ❌ State Git'te asla
- ❌ `*.auto.tfvars`'a secret koyma (vault'tan ç ek)
- ❌ `terraform apply -auto-approve` interaktif kullanma
