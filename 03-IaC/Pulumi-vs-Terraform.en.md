---
description: "A comparison of Pulumi with Terraform/OpenTofu: HCL versus general-purpose languages like Python/Go/TS, when to prefer which, and a migration strategy."
tags:
  - IaC
  - Terraform
  - Platform Engineering
---
# Pulumi vs Terraform — General-Purpose Lang vs HCL

> *"Terraform: HCL, declarative, optimized for IaC. Pulumi: Python/Go/TS,
> an existing programming language, you can use **for-loops + libraries**.
> Which one? It comes down to **your team's habits**."*

This guide covers a comparison of Pulumi with Terraform/OpenTofu,
when to prefer which one, and a migration
strategy.

---

## ⚖️ In One Sentence

| Tool | Philosophy |
|---|---|
| **Terraform/OpenTofu** | "HCL, declarative, IaC-purpose" |
| **Pulumi** | "Write infrastructure with an existing language (Python/Go/TS/.NET)" |

---

## 📊 Detailed Comparison

| Dimension | **Terraform/OpenTofu** | **Pulumi** |
|---|---|---|
| **Language** | HCL (DSL) | Python, TypeScript, Go, .NET, Java |
| **Paradigm** | Declarative | Imperative + declarative (mix) |
| **Loop / conditional** | `for_each`, `count`, `dynamic` | Native `for`, `if`, function |
| **Library** | Module | Pip / npm / Go modules |
| **Type safety** | Moderate HCL type checking | TypeScript / Go strong typing |
| **Test** | terratest, checkov | Native unit test (pytest, jest) |
| **State** | tfstate | Pulumi state (cloud / self-host) |
| **State encryption** | Backend-dependent (S3 SSE) | Built-in (passphrase / KMS) |
| **Secret in state** | Plain (protected by S3 SSE) | Encrypted (built-in) |
| **Plan + apply** | ✅ | ✅ |
| **Drift detection** | terraform plan | pulumi refresh |
| **Multi-cloud** | ✅ | ✅ |
| **Provider count** | ~3000+ | ~150+ (growing) |
| **Community** | Very large | Growing |
| **Maturity** | 10+ years | 7+ years |
| **Free tier** | OpenTofu free, Terraform BSL | Pulumi Cloud free, 200 resources |
| **Commercial** | HashiCorp / Spacelift | Pulumi Inc |

---

## 🌳 Decision Tree

```
START
  │
  ├── Does the team know Python / TypeScript / Go (but not HCL)?
  │     │
  │     └── YES → Pulumi (saves learning time)
  │
  ├── Need a broad ecosystem of providers?
  │     │
  │     └── YES → Terraform/OpenTofu (3000+ providers)
  │
  ├── Is type safety + advanced testing critical?
  │     │
  │     └── YES → Pulumi (strong-typed)
  │
  ├── Lots of complex loops / conditionals / abstraction?
  │     │
  │     └── YES → Pulumi (native lang power)
  │
  ├── Multi-cloud + standard pattern?
  │     │
  │     └── Terraform/OpenTofu (established)
  │
  └── Default → Terraform/OpenTofu (established, large community)
```

> 🎯 **2026 practical take**: **Terraform/OpenTofu** for most teams. **Pulumi** if you want custom abstractions that lean on your team's programming strength.

---

## 💻 Code Comparison

### S3 bucket + IAM policy

#### Terraform/OpenTofu
```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "${var.app_name}-logs"
  tags   = var.tags
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureConnections"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = ["${aws_s3_bucket.logs.arn}/*"]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}
```

#### Pulumi (TypeScript)
```typescript
import * as aws from "@pulumi/aws";
import * as pulumi from "@pulumi/pulumi";

const config = new pulumi.Config();
const appName = config.require("appName");

const logsBucket = new aws.s3.Bucket("logs", {
  bucket: `${appName}-logs`,
  tags: { Environment: "prod" },
});

const policy = new aws.s3.BucketPolicy("logs-policy", {
  bucket: logsBucket.id,
  policy: logsBucket.arn.apply(arn => JSON.stringify({
    Version: "2012-10-17",
    Statement: [{
      Sid: "DenyInsecureConnections",
      Effect: "Deny",
      Principal: "*",
      Action: "s3:*",
      Resource: [`${arn}/*`],
      Condition: {
        Bool: { "aws:SecureTransport": "false" }
      }
    }]
  })),
});
```

### Loop across multiple regions

#### Terraform
```hcl
locals {
  regions = ["eu-west-1", "us-east-1", "ap-southeast-1"]
}

resource "aws_s3_bucket" "regional" {
  for_each = toset(local.regions)
  provider = aws[each.key]
  bucket   = "${var.app}-${each.key}"
}
```

#### Pulumi (TypeScript)
```typescript
const regions = ["eu-west-1", "us-east-1", "ap-southeast-1"];

const buckets = regions.map(region => {
  const provider = new aws.Provider(region, { region });
  return new aws.s3.Bucket(`${appName}-${region}`, {
    bucket: `${appName}-${region}`,
  }, { provider });
});
```

> 🔑 **Pulumi**: standard programming. **Terraform**: learn HCL syntax.

---

## 🧪 Testing Comparison

### Terraform — terratest
```go
// test/main_test.go
package test

import (
  "testing"
  "github.com/gruntwork-io/terratest/modules/terraform"
)

func TestS3Bucket(t *testing.T) {
  opts := &terraform.Options{
    TerraformDir: "../",
    Vars: map[string]interface{}{
      "app_name": "test-app",
    },
  }
  defer terraform.Destroy(t, opts)
  terraform.InitAndApply(t, opts)
  // assert: bucket exists
}
```

### Pulumi — native test (Mocha)
```typescript
import * as pulumi from "@pulumi/pulumi";
import { describe, it } from "mocha";

pulumi.runtime.setMocks({
  newResource: (args) => ({
    id: `${args.name}-id`,
    state: args.inputs,
  }),
  call: (args) => args.inputs,
});

describe("Infrastructure", () => {
  let infra: typeof import("./index");

  before(async () => {
    infra = await import("./index");
  });

  it("S3 bucket name is correct", (done) => {
    pulumi.all([infra.logsBucket.bucket]).apply(([name]) => {
      if (name !== "test-app-logs") {
        done(new Error(`Expected test-app-logs, got ${name}`));
      } else {
        done();
      }
    });
  });
});
```

→ Pulumi has **mock-based unit testing** natively; Terraform needs an extra tool like terratest.

---

## 🔄 Migration: Terraform → Pulumi (or vice versa)

### Pulumi `tf2pulumi` tool
```bash
pip install pulumi-tf2pulumi
tf2pulumi --target-language typescript -o pulumi-project/
```

→ Existing HCL is automatically converted to Pulumi TS. Manual review + testing required.

### Staged: parallel migration
1. New resources in Pulumi
2. Existing ones stay in Terraform
3. Gradual import (per resource)
4. Full migration over 6-12 months

> ⚠️ **State migration is complex**. Practical approach: Pulumi for new greenfield work, stay on Terraform for existing infrastructure.

---

## 🚧 Trade-offs

### Pulumi Pro
- ✅ Existing programming language
- ✅ Strong typing
- ✅ Native testing
- ✅ Library ecosystem (pip, npm)
- ✅ Native loop / conditional

### Pulumi Con
- ❌ Fewer providers (~150 vs 3000)
- ❌ Newer community
- ❌ "Programmer's IaC" → hard for non-dev DevOps folks
- ❌ State management via Pulumi Cloud (or self-host setup)
- ❌ Imperative mix → risk of unintended side effects

### Terraform Pro
- ✅ Established, massive ecosystem
- ✅ Declarative (simple mental model)
- ✅ Provider diversity
- ✅ HashiCorp ecosystem (Vault, Consul, Nomad)

### Terraform Con
- ❌ HCL DSL (a new language to learn)
- ❌ Ugly loop / conditional syntax (`for_each`, `dynamic`)
- ❌ Missing test framework (terratest is external)
- ❌ BSL license (Terraform 1.6+) → OpenTofu fork

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Being hypnotized into using Pulumi "for everything" | Pulumi state is complex | Evaluate use case + team skill |
| Rejecting Terraform as "not modern" | Established + mature | Evaluate trade-offs |
| Mixed Terraform + Pulumi on the same resource | State conflicts | Clear boundary |
| Pulumi imperative side effects | No reproducibility | Pure functions, isolate side effects |
| Overusing HCL `dynamic` | Unreadable | Module + specific resource |
| Pulumi Cloud free tier in prod | 200 resource limit | Self-host backend (S3) |
| No tests | "I think it works" | Native unit test (Pulumi) or terratest (TF) |
| No provider version pin | Drift, surprises | Pin version |
| Pulumi secret stored plain in state | Compromise = total | KMS encryption (Pulumi config) |

---

## 📋 IaC Tool Adoption Checklist

```
[ ] Tool choice decision documented (RFC)
[ ] Team skill (HCL vs Python/TS) evaluated
[ ] State backend: S3 + versioning + encryption
[ ] Secret management: Pulumi config / Vault / SOPS
[ ] Provider version pin
[ ] Module / library structure (Pulumi npm package vs TF module)
[ ] Test strategy (Pulumi mocha / terratest)
[ ] CI/CD: plan + apply pipeline
[ ] Drift detection (periodic refresh / plan)
[ ] Rollback procedure (state copies)
[ ] Migration plan (if needed)
[ ] Documentation: how a new engineer gets started
```

---

## 📚 References

- **Terraform** — terraform.io
- **OpenTofu** — opentofu.org
- **Pulumi** — pulumi.com
- **Pulumi Examples** — github.com/pulumi/examples
- **tf2pulumi** — github.com/pulumi/pulumi-converter-terraform
- **Terratest** — terratest.gruntwork.io
- [`Terraform-Best-Practices.md`](Terraform-Best-Practices.md)
- [`OpenTofu-Migration.md`](OpenTofu-Migration.md)
- [`Crossplane-Intro.md`](Crossplane-Intro.md)
- [`Terraform-Module-Layout.md`](Terraform-Module-Layout.md)

---

> *"Pulumi vs Terraform isn't about the 'right answer' — it's about the
> **right tool for the right team**. Learn HCL in 2 days; if you already
> know Python, Pulumi saves you time. If you're locked into the HashiCorp
> ecosystem, stay with Terraform/OpenTofu."*
