---
description: "Guide to migrating from Terraform to OpenTofu: the HashiCorp BSL license issue, the MPL 2.0 fork, compatibility differences, and a practical answer to what to move to in 2026."
tags:
  - IaC
  - Terraform
  - Compliance
---
# OpenTofu Migration — Breaking Free from Terraform

> *"In August 2023 HashiCorp changed Terraform's license to BSL.
> The community forked it and launched **OpenTofu**. In 2026 the Terraform vs OpenTofu
> choice has turned into the question 'have you made your call yet?'"*

This guide walks through the Terraform → OpenTofu migration, the BSL license issue, and
gives a practical answer to the question of what to move to in 2026.

---

## 🎯 Summary: Why OpenTofu?

| Dimension | Terraform (BSL) | OpenTofu (MPL) |
|---|---|---|
| **License** | Business Source License | Mozilla Public License 2.0 |
| **Source available** | ✅ but restricted use | ✅ Fully open source |
| **Vendor lock-in** | HashiCorp | CNCF (Linux Foundation) |
| **Free for all** | For most, but "competitive" use forbidden | Open to all uses |
| **Community** | HashiCorp + ecosystem | CNCF + Spacelift, env0, Gruntwork, IBM |
| **Provider compatibility** | Native | Same (registry-compatible) |
| **Module compatibility** | Native | 95%+ compatible |
| **Velocity** | HashiCorp roadmap | Community PRs (faster) |
| **Commercial support** | HashiCorp Enterprise | Spacelift / env0 / Scalr |

> 🔑 **2026 recommendation**: New project → **OpenTofu**. Existing Terraform stack — migrate or stay.

---

## 📚 The Story

### August 2023
- HashiCorp changed Terraform's license to **BSL** (Business Source License)
- "Competitive use" forbidden (e.g., Terraform-as-a-Service vendors)
- Community in shock

### September 2023
- **OpenTF Foundation** established under the Linux Foundation
- Spacelift, env0, Gruntwork, Cloudify as primary sponsors

### January 2024
- **OpenTofu 1.6** → first stable
- Fork of Terraform 1.5, the pre-BSL codebase

### 2024-2025
- OpenTofu CNCF Sandbox → Incubating
- Terraform 1.9, 1.10 released (under BSL)
- OpenTofu 1.7, 1.8 → state encryption, OCI registry, and more

### 2026
- The two projects live in parallel
- **Community dynamism is with OpenTofu**

---

## 🚀 Migration Steps

### Step 1: Backup
```bash
# State backup
terraform state pull > terraform.tfstate.backup-$(date +%F)

# Confirm versioning is enabled on the tfstate S3 / GCS bucket
```

### Step 2: OpenTofu install
```bash
# macOS
brew install opentofu

# Linux
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | sh

# Verify
tofu version
```

### Step 3: Prepare the working directory
```bash
# Terraform still active
terraform plan
terraform apply
# Commit all changes

# Lock file rename
mv .terraform.lock.hcl .opentofu.lock.hcl   # optional; tofu also reads .terraform.lock.hcl
```

### Step 4: Provider compatibility check
```bash
# Provider list
tofu init   # downloads OpenTofu providers

# Providers
tofu providers
```

> 🔑 **Most providers** (AWS, GCP, Azure, K8s) are compatible with both Terraform and OpenTofu in the registry.

### Step 5: Plan + Apply (should be a no-op)
```bash
tofu init -upgrade
tofu plan
# Output: "No changes" — success

tofu apply
```

### Step 6: CI/CD update
```yaml
# Old
- run: terraform plan

# New
- uses: opentofu/setup-opentofu@<VERSION>
- run: tofu plan
```

### Step 7: Module updates
```hcl
# Old (Terraform Cloud only)
terraform {
  cloud {
    organization = "<ORG>"
    workspaces { name = "prod" }
  }
}

# OpenTofu compatible
terraform {
  backend "s3" {
    bucket = "<TFSTATE_BUCKET>"
    key    = "prod/terraform.tfstate"
    region = "<REGION>"
  }
}
```

> ⚠️ **Terraform Cloud / HCP** is not compatible with OpenTofu. Spacelift, env0 are alternatives.

---

## 🎁 OpenTofu-Specific Features

### State Encryption (1.7+)
```hcl
terraform {
  encryption {
    key_provider "aws_kms" "key" {
      kms_key_id = "<KMS_KEY_ID>"
      region     = "<REGION>"
    }

    method "aes_gcm" "state" {
      keys = key_provider.aws_kms.key
    }

    state {
      method = method.aes_gcm.state
    }
  }
}
```

→ The state file is encrypted with AES-GCM (an extra layer on top of S3 SSE).

### OCI Registry (1.8+)
```hcl
module "vpc" {
  source = "oci://<REGISTRY>/modules/vpc:1.0.0"
}
```

→ Manage modules in an OCI registry, just like a Helm chart.

### Module + Provider for_each (1.7+)
```hcl
module "regions" {
  for_each = toset(["eu-west-1", "us-east-1", "ap-southeast-1"])
  source   = "./modules/region"
  region   = each.key
}
```

---

## 🛠️ Hybrid / Running Both Ways

Some teams run both in parallel:

```bash
# Terraform CLI still installed
terraform plan   # old
tofu plan         # new
```

> ⚠️ State sharing: both can use the same state file, but a **version surprise** can crop up. Use a single tool to keep it consistent.

---

## 🚧 Migration Risks

### 1. Provider divergence
- Provider authors may release different versions for HashiCorp / OpenTofu
- Solution: provider version pinning + testing

### 2. Terraform Cloud lock-in
- HCP Terraform doesn't support OpenTofu
- Solution: Spacelift / env0 / Scalr

### 3. Sentinel policies
- HashiCorp proprietary
- Solution: compatible with OpenTofu policy (Rego/OPA, Conftest)

### 4. Module registry
- registry.terraform.io ↔ OpenTofu Registry
- Most modules are published on both

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Accepted BSL, I'll think about it later | License risk accumulates | Evaluate actively |
| Big-bang migration | State corruption | Staged: dev → staging → prod |
| No state backup during migration | Recovery impossible | S3 versioning + manual snapshot |
| No provider version pin | Surprise drift | `version = "~> 5.0"` |
| No test environment | You learn in production | Lab cluster first |
| Heavy use of HashiCorp CDK / Sentinel | Incompatible with OpenTofu | Migration plan + alternative |
| Terraform Cloud lock | Can't move to OpenTofu | Migrate to Spacelift / env0 |
| Mixed Terraform + OpenTofu state | Version surprise | Single tool, consistent |

---

## 📋 Migration Checklist

```
[ ] License risk assessment (BSL vs MPL)
[ ] Current Terraform version (pre-1.5?)
[ ] State backend (S3 + versioning)
[ ] State backup (manual snapshot)
[ ] OpenTofu install + verify
[ ] Provider compatibility check
[ ] Module compatibility (if you have custom modules)
[ ] CI/CD pipeline update (terraform → tofu)
[ ] Test on a lab cluster (plan should be a no-op)
[ ] Staged migration: dev → staging → prod
[ ] Rollback plan (fall back to terraform)
[ ] Documentation update (runbook, README)
[ ] Tooling: tflint, terragrunt OpenTofu-compatible
[ ] Commercial support (if needed): Spacelift / env0
[ ] Quarterly: OpenTofu version upgrade
```

---

## 📚 References

- **OpenTofu** — opentofu.org
- **OpenTofu Migration Guide** — opentofu.org/docs/intro/migration/
- **Linux Foundation Press Release** — Sep 2023
- **HashiCorp BSL Announcement** — hashicorp.com/blog/hashicorp-adopts-business-source-license
- **Spacelift** — spacelift.io
- **env0** — env0.com
- **Scalr** — scalr.com
- [`Terraform-Best-Practices.md`](Terraform-Best-Practices.md)
- [`Pulumi-vs-Terraform.md`](Pulumi-vs-Terraform.md)
- [`Crossplane-Intro.md`](Crossplane-Intro.md)
- [`Terraform-Module-Layout.md`](Terraform-Module-Layout.md)

---

> *"The BSL license was HashiCorp's decision, but the fork is the community's. In 2026,
> 'OpenTofu or Terraform' is as pragmatic a question as 'GitLab or GitHub'.
> New project → OpenTofu, absent a strong argument otherwise."*
