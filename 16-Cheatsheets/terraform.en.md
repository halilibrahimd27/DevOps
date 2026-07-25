---
description: "Command notes for Terraform and OpenTofu: init, fmt, validate, plan/apply workflow, state operations, import and console. Commands work the same for both tools."
tags:
  - Cheatsheet
  - Terraform
  - IaC
---
# Terraform / OpenTofu Cheatsheet

> Commands are the same for `terraform` and `tofu`. Since the fork, OpenTofu
> is Apache 2.0 licensed; it can be preferred for production.

## 🚀 Workflow Basics

```bash
# Init (download providers, prepare the backend)
terraform init
terraform init -upgrade              # upgrade providers
terraform init -reconfigure          # refresh backend settings
terraform init -migrate-state        # if you're changing backends

# Format
terraform fmt
terraform fmt -recursive
terraform fmt -check                 # in CI: fail if there are changes

# Validate
terraform validate
terraform validate -json | jq

# Plan
terraform plan
terraform plan -out=tfplan           # save the plan
terraform plan -var="region=us-east-1"
terraform plan -var-file=prod.tfvars
terraform plan -target=aws_instance.web    # for a specific resource
terraform plan -refresh=false        # don't refresh state (fast)

# Apply
terraform apply
terraform apply tfplan               # apply the saved plan
terraform apply -auto-approve        # use carefully; DON'T outside CI
terraform apply -var-file=prod.tfvars

# Destroy
terraform destroy
terraform destroy -target=aws_instance.tmp
```

## 🗂️ State Operations

```bash
# View state contents
terraform state list
terraform state show aws_instance.web

# Remove a resource from state (without deleting it)
terraform state rm aws_instance.web

# Import an existing resource into state
terraform import aws_instance.web i-1234567890abcdef0

# Rename a resource
terraform state mv aws_instance.old aws_instance.new

# State backup
terraform state pull > state.backup.json

# State push (restore from backup)
terraform state push state.backup.json

# Refresh (only sync state with the provider, don't create a plan)
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
│       └── README.md (auto-generated with terraform-docs)
└── environments/
    ├── prod/
    │   ├── main.tf
    │   ├── backend.tf
    │   └── terraform.tfvars
    └── dev/
        └── ...
```

### Calling a module

```hcl
module "vpc" {
  source  = "git::https://github.com/<ORG>/<REPO>.git//modules/vpc?ref=v1.2.3"
  # or:
  source  = "../../modules/vpc"

  cidr_block       = "10.0.0.0/16"
  azs              = ["us-east-1a", "us-east-1b"]
  enable_flow_logs = true
}

# Use output
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
    error_message = "Region must start with us- or eu-."
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
# Pass from CLI
terraform plan -var="region=eu-west-1"

# tfvars file
terraform plan -var-file=prod.tfvars
# Loaded automatically: terraform.tfvars, *.auto.tfvars

# Env vars (TF_VAR_<name>)
export TF_VAR_region=eu-west-1
terraform plan
```

## 🔄 for_each and count

```hcl
# count (old, for ordered lists)
resource "aws_instance" "web" {
  count         = 3
  ami           = "<AMI_ID>"
  instance_type = "t3.micro"
  tags = { Name = "web-${count.index}" }
}

# for_each (modern, for named resources — PREFERRED)
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

## 🚦 Workspaces (multi-env, for simple use)

```bash
terraform workspace list
terraform workspace new prod
terraform workspace select dev
terraform workspace show
terraform workspace delete dev

# Usage in state:
# terraform.workspace == "prod"
```

> ⚠️ Workspaces are fine for small projects; in larger orgs **environment-per-directory**
> is cleaner (each env gets its own backend.tf, variables, etc.).

## 🔒 Sensitive

```hcl
variable "db_password" {
  type      = string
  sensitive = true               # hides it in plan/apply output
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
    prevent_destroy       = true   # block `terraform destroy`
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

# View provider versions
terraform version
terraform providers
terraform providers schema -json | jq

# Dependency graph
terraform graph | dot -Tpng > graph.png      # requires graphviz
```

## 📝 Recommended .tflint.hcl

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

## 📋 Best practices summary

- ✅ **Commit** `terraform.lock.hcl` (version reproducibility)
- ✅ State **remote** (S3+DynamoDB / GCS / Azure)
- ✅ **Encrypt** state + bucket versioning + access log
- ✅ `for_each` > `count`
- ✅ Version modules (Git tag, registry)
- ✅ `terraform plan` automatically on PRs (atlantis / GH Actions)
- ✅ `terraform fmt -check` + `tflint` + `trivy config` in CI (tfsec was consolidated into Trivy in 2023)
- ✅ Sensitive variables get `sensitive = true`
- ✅ `apply` to production only from the pipeline
- ❌ Never state in Git
- ❌ Don't put secrets in `*.auto.tfvars` (pull from vault)
- ❌ Don't use `terraform apply -auto-approve` interactively
