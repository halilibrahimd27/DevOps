---
description: "FinOps Foundation framework (Inform-Optimize-Operate) guides: cost allocation, right-sizing, spot, reserved plans, storage, egress, Kubecost and PR cost diff."
tags:
  - FinOps
  - Cost Optimization
  - Roadmap
  - Cost
---
# 12 · FinOps

> *"The AWS bill landed at the start of the month: $42,318. Last month
> it was $19,200. Who, what, where? Nobody knows."* — every startup without a cost team

FinOps Foundation framework: the **Inform → Optimize → Operate** loop.
Treats cost as an engineering problem, not a finance one.

## Table of Contents

| File | Topic |
|---|---|
| [`Cloud-Cost-Allocation.md`](Cloud-Cost-Allocation.md) | Tagging policy, showback/chargeback, OpenCost/Kubecost setup |
| [`Right-Sizing.md`](Right-Sizing.md) | Compute Optimizer, VPA recommendations, detecting "fat pods" |
| [`Spot-Instance-Strategy.md`](Spot-Instance-Strategy.md) | Spot interruption handling, mixed pool with Karpenter |
| [`Reserved-and-Savings-Plans.md`](Reserved-and-Savings-Plans.md) | RI vs SP, commitment strategies, expiration planning |
| [`Storage-Cost-Optimization.md`](Storage-Cost-Optimization.md) | S3 Intelligent-Tiering, EBS gp2→gp3, snapshot lifecycle |
| [`Egress-Cost-Reduction.md`](Egress-Cost-Reduction.md) | The "hidden killer" — VPC endpoint, Cloudflare R2, region locality |
| [`Kubecost-Setup.md`](Kubecost-Setup.md) | Kubernetes cost attribution: namespace/workload/team |
| [`PR-Cost-Diff.md`](PR-Cost-Diff.md) | Pre-merge cost review with Infracost |

## FinOps Foundation loop

```
   ┌─── INFORM ───┐         ┌── OPTIMIZE ──┐         ┌── OPERATE ──┐
   │ Tagging      │         │ Right-size   │         │ Anomaly det │
   │ Cost dash    │ ─────▶ │ Spot/RI/SP   │ ─────▶ │ FinOps champ│
   │ Allocation   │         │ Idle cleanup │         │ KPI track   │
   │ Showback     │         │ Lifecycle    │         │ Forecast    │
   └──────────────┘         └──────────────┘         └─────────────┘
           ▲                                                   │
           │                                                   │
           └─────────────────── continuous ────────────────────┘
```

## Tagging policy (mandatory, enforced)

| Tag | Example value | Why mandatory |
|---|---|---|
| `Environment` | `prod`, `staging`, `dev` | Cost separation |
| `Team` | `payments`, `growth`, `platform` | Showback |
| `Service` | `api`, `worker`, `db` | Workload-level breakdown |
| `CostCenter` | `eng-1234` | Finance integration |
| `ManagedBy` | `terraform`, `manual` | IaC drift tracking |
| `Owner` | `team-handle` | Accountability |

> If tagging is missing:
> - ✅ Make it **undeployable** via AWS Config / Service Control Policy
> - ✅ Terraform validation: the `required_tags` module
> - ✅ Kyverno (K8s) annotation enforcement

## "Quick wins" — doable this week

1. **Idle resource cleanup** — `aws ec2 describe-instances --filters Name=instance-state-name,Values=stopped` (older than 30 days → terminate)
2. **EBS gp2 → gp3** — same performance, 20% cheaper, online migration
3. **Old snapshot purge** — older than 90 days + never restored
4. **Idle Load Balancer** — `RequestCount=0` for 7 days straight → delete
5. **Unattached EIP** — Elastic IPs are billed even while idle
6. **Empty namespace deployments** — replica=0 but a secret/configmap is still running
7. **Old AMIs** — deregister the unused ones
8. **Public S3 + Internet egress** — put it behind a CDN

> ⏱️ Typical savings: 15-30% in the first month, with no extra engineering effort.

## Anti-patterns

- ❌ "Cost is finance's job" — every team should see its own cost
- ❌ Getting surprised after the monthly bill arrives — set up daily anomaly alerts instead
- ❌ Making tagging optional — retrofitting it later is impossible
- ❌ "Buy reserved and forget" — no expiry plan, you hit the cliff
- ❌ Ignoring Kubernetes overcommit — "let's request a bit extra" → the cluster keeps growing
- ❌ Ignoring egress — the hidden biggest expense line

---

> 🎓 **Learning Path:** This document is used as the "Read first" resource in the [`F1`](../22-Learning-Path/block-f-judgment/F1-maliyet-finops.md) module.
