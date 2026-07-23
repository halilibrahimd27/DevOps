---
description: "70% savings with AWS Spot, GCP Preemptible, and Azure Spot: choosing suitable workloads, graceful interruption handling, and a mixed fleet strategy with Karpenter."
tags:
  - FinOps
  - Cost Optimization
  - AWS
  - Kubernetes
  - Cost
---
# Spot Instance Strategy — 70% Savings

> *"Spot is 70% cheaper — the team that won't use it because 'it can be
> interrupted' is burning **$5K-50K a month** for nothing. The right
> workload + the right tooling = 30%+ spot adoption."*

This guide covers workload suitability for AWS Spot, GCP Preemptible, and Azure Spot,
graceful interruption handling, and a mixed fleet strategy with Karpenter.

---

## 🎯 What Is Spot?

> **Spot/Preemptible**: The cloud provider's **idle capacity**.
> 70-90% cheaper; but it can be shut down with an interruption notice
> **2 minutes ahead**.

| Cloud | Spot | Discount |
|---|---|---|
| AWS | Spot Instance | 70-90% |
| GCP | Preemptible / Spot VM | 60-91% |
| Azure | Spot VM | 50-90% |

---

## ✅ Suitable Workloads

| Workload | Spot suitability |
|---|---|
| **Stateless API** (HTTP) | ✅ replica > 1 + LB |
| **CI runner** | ✅ ephemeral |
| **ML training (batch)** | ✅✅ if checkpointing |
| **Data ETL** | ✅ idempotent |
| **Background queue worker** | ✅✅ if retry |
| **Render farm** | ✅ |
| **Dev / staging** | ✅✅ |
| **Cache (Redis primary)** | ❌ state |
| **Database primary** | ❌ data loss |
| **Stateful kafka** | ⚠️ OK if replica |
| **Real-time critical** | ❌ interrupt impact |

> 🔑 **Rule of thumb**: If stateless + replica > 1 + retry, **spot OK**.

---

## 🚀 AWS Spot Best Practices

### EC2 Spot
```bash
# Mixed instance type (reduces interruption risk)
aws ec2 run-instances \
  --instance-market-options 'MarketType=spot,SpotOptions={SpotInstanceType=one-time}' \
  --image-id ami-xxx \
  --instance-type m5.large
```

### EKS Spot Node Group
```bash
eksctl create nodegroup --config-file=- <<EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: prod
managedNodeGroups:
  - name: spot
    instanceTypes: [m5.large, m5a.large, m5n.large, m4.large]   # diversify
    spot: true
    minSize: 2
    maxSize: 20
    labels: {capacity-type: spot}
    taints:
      - key: capacity-type
        value: spot
        effect: NoSchedule
EOF
```

### Karpenter (recommended)
```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: spot-pool
spec:
  template:
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: [spot]
        - key: karpenter.k8s.aws/instance-family
          operator: In
          values: [m5, m5a, m5n, m6i, m7i]   # diversify
        - key: kubernetes.io/arch
          operator: In
          values: [amd64, arm64]
  limits:
    cpu: "1000"
  disruption:
    consolidationPolicy: WhenEmpty
    expireAfter: 720h   # 30-day max lifetime
```

> 🔑 Karpenter handles spot interruption signals, automatic node replacement.

---

## 🛡️ Graceful Interruption Handling

### Interruption notice
- AWS: signal **2 minutes** ahead (instance metadata)
- GCP: 30 seconds
- Azure: 30 seconds

### On the Pod side
```yaml
# PodDisruptionBudget
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: payments
spec:
  minAvailable: 2
  selector:
    matchLabels: {app: payments}
```

### Termination handler
```bash
# AWS Node Termination Handler
helm install aws-node-termination-handler aws-cdk/aws-node-termination-handler \
  -n kube-system \
  --set enableSpotInterruptionDraining=true \
  --set enableScheduledEventDraining=true
```

→ Interruption signal → cordon + drain → pods evicted to a healthy node.

---

## 🎯 Mixed Fleet Strategy

```
[Workload Type]               [Capacity Type]
─────────────────────────────────────────────
Critical / DB                  → on-demand (100%)
Stateless API replica > 3       → on-demand (1) + spot (rest)
Background queue                → spot (100%)
CI runner                       → spot (100%)
Dev/staging                     → spot (100%)
ML training                     → spot (checkpointing)
```

### K8s tolerations + node affinity
```yaml
spec:
  tolerations:
    - key: capacity-type
      operator: Equal
      value: spot
      effect: NoSchedule
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          preference:
            matchExpressions:
              - key: capacity-type
                operator: In
                values: [spot]
```

---

## 📊 Cost Saving Calculation

```
m5.large baseline:
  On-demand: $0.096/hour × 720 hours = $69/month
  Spot:      $0.025/hour × 720 hours = $18/month
  Savings: $51/month (74%)

10 node cluster:
  All on-demand: $690/month
  All spot:      $180/month
  Mixed (3 OD + 7 spot): $333/month   ← 52% savings, acceptable risk
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Do this instead |
|---|---|---|
| Not using spot | 70% cost loss | Mixed fleet |
| Single instance type for spot | High interruption risk | Diversify (5+ instance types) |
| DB primary on spot | Data loss | On-demand |
| No PDB | Pod loss during interruption | Set minAvailable |
| No termination handler | Hard kill, requests fail | Drain handler |
| 100% spot for prod-critical | Interruption is a disaster | 30-50% spot |
| No ML training checkpoint | Interruption = start over | Checkpoint per epoch |
| Ignoring spot price fluctuation | No bid strategy | Karpenter auto |
| Forgetting workload spot suitability | Real-time on spot | Classify workloads |

---

## 📋 Spot Adoption Checklist

```
[ ] Workload classification: spot-suitable list
[ ] Mixed fleet with Karpenter / equivalent
[ ] Diversify: 5+ instance types
[ ] PDB on all workloads
[ ] Termination handler (aws-node-termination-handler)
[ ] Stateless replica > 1 + LB
[ ] Tolerations + node affinity
[ ] ML workload: checkpoint per epoch
[ ] Cost dashboard: spot adoption %
[ ] Quarterly: spot interruption rate review
[ ] DR: fallback when all spot is down
[ ] Annual savings target: 30%+
```

---

## 📚 References

- **AWS Spot** — aws.amazon.com/ec2/spot
- **AWS Node Termination Handler** — github.com/aws/aws-node-termination-handler
- **GCP Spot VMs** — cloud.google.com/spot-vms
- **Azure Spot** — azure.microsoft.com/en-us/products/virtual-machines/spot
- **Karpenter** — karpenter.sh
- [`Cloud-Cost-Allocation.md`](Cloud-Cost-Allocation.md)
- [`Right-Sizing.md`](Right-Sizing.md)
- [`Reserved-and-Savings-Plans.md`](Reserved-and-Savings-Plans.md)
- [`14-Sustainability/Efficiency-Practices.md`](../14-Sustainability/Efficiency-Practices.md)

---

> *"Spot is 70% cheaper, **no 'we don't use it' excuse**. Classify
> workloads + Karpenter + termination handler = $5K-50K monthly
> savings, **2-week implementation**."*

---

> 🎓 **Learning Path:** This document is used as a "read first" resource in the [`F1`](../22-Learning-Path/block-f-judgment/F1-maliyet-finops.md) module.
