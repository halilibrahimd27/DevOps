---
description: "Standard Terraform module skeleton: main.tf + variables.tf + outputs.tf; type-safe, validated, version-pinned copy-paste template."
tags:
  - Template
  - Terraform
  - IaC
---
# Terraform Module Skeleton

> A standard Terraform module skeleton: `main.tf` + `variables.tf` + `outputs.tf`.
> Copy it, fill it in for your own resource.

## Files

| File | Purpose |
|---|---|
| [`main.tf`](main.tf) | Resource definitions + `terraform`/`required_providers` block |
| [`variables.tf`](variables.tf) | Type-safe, documented, validated input variables |
| [`outputs.tf`](outputs.tf) | Outputs for resources that consume the module |

## Usage

```bash
# Call the module from your own root config
module "<MODULE_NAME>" {
  source = "git::https://github.com/<ORG>/<REPO>.git//17-Templates/terraform?ref=<VERSION>"

  name        = "<NAME>"
  environment = "<ENV>"
  tags        = { team = "<TEAM>", owner = "<OWNER>" }
}
```

## Why this structure

- **3-file separation** is the standard: resources, inputs, and outputs are read separately.
- **`variables.tf` with validation**: bad input blows up at the `plan` stage, not at `apply`.
- **Version pinning** (`required_providers`): a provider upgrade shouldn't cause surprise drift.

> *"A module is code that's called, not copied — its input/output contract is clear."*
