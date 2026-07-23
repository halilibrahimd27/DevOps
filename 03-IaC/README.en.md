---
description: "Infrastructure as Code section index: Terraform best practices, module layout, OpenTofu migration, Pulumi, Crossplane, drift detection, and the IaC decision tree."
tags:
  - IaC
  - Terraform
  - Roadmap
---
# 03 · Infrastructure as Code

> *"A resource you provisioned by clicking through the console will one
> day get deleted by someone else clicking through it — who, when, why?
> You'll never know."*

IaC keeps everything as code in Git: provisioning, changes, deletion —
all of it goes through PR review.

## Contents

| File | Topic |
|---|---|
| [`Terraform-Best-Practices.md`](Terraform-Best-Practices.md) | Module layout, remote state, workspace, lifecycle hooks, drift handling |
| [`Terraform-Module-Layout.md`](Terraform-Module-Layout.md) | Standard `vpc/eks/rds` module skeleton, `terraform-docs` |
| [`OpenTofu-Migration.md`](OpenTofu-Migration.md) | HashiCorp BSL → OpenTofu Apache transition: what changes/stays the same |
| [`Pulumi-vs-Terraform.md`](Pulumi-vs-Terraform.md) | IaC with TypeScript/Python: when to choose it |
| [`Crossplane-Intro.md`](Crossplane-Intro.md) | Kubernetes-native cloud control plane: why and how |
| [`Drift-Detection.md`](Drift-Detection.md) | Running `terraform plan` automatically in CI; catching manual changes |

## Decision tree: which IaC?

```
Single cloud + Terraform/HCL knowledge?
└─ YES → Terraform / OpenTofu (most common, largest hiring pool)
└─ NO
   ├─ Multi-cloud, Kubernetes-centric?
   │   └─ Crossplane (everything through the K8s API)
   ├─ Want to write it in a programming language?
   │   └─ Pulumi (TS/Python/Go/.NET)
   └─ AWS-only, familiar with JSII?
       └─ AWS CDK / CDK8s
```

## Terraform module hierarchy (recommended)

```
infra/
├── modules/                    ← reusable, versioned
│   ├── vpc/
│   ├── eks/
│   ├── rds/
│   └── observability/
├── environments/               ← composition layer
│   ├── prod/
│   │   ├── main.tf            ← calls the modules
│   │   ├── variables.tf
│   │   └── backend.tf
│   ├── staging/
│   └── dev/
└── stacks/                     ← cross-environment shared
    ├── networking/
    └── identity/
```

## Anti-patterns

- ❌ Committing state to Git (`*.tfstate` should be in `.gitignore`)
- ❌ Using `path = "../modules/x"` instead of versioning modules (guarantees drift)
- ❌ Using `count` (a resource gets deleted, indices shift, plan produces a huge diff) — use `for_each`
- ❌ `terraform apply -auto-approve` without PR review
- ❌ One giant monolithic state (apply takes an hour, blast radius is huge)
- ❌ Changing something in the console, then `terraform import` afterward (skip that step once and you get drift)
