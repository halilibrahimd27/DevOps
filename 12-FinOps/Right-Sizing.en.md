---
description: "Right-sizing guide for AWS, GCP, and Kubernetes: downsizing instances based on the usage profile, CPU/memory targets, tooling, and deciding when to downsize."
tags:
  - FinOps
  - Cost Optimization
  - Kubernetes
  - AWS
  - Performance
---
# Right-Sizing — Resources at the Right Size

> *"A team that allocates `4 vCPU` to an instance averaging 15% CPU is
> **burning money** on 75% of it every month. Right-sizing = downsize the
> instance based on the usage profile."*

This guide covers right-sizing practices, tooling, and the "when to downsize"
decision for AWS / GCP / K8s.

---

## 🎯 Right-Sizing Targets

| Resource | Ideal utilization |
|---|---|
| CPU | 50-70% average |
| Memory | 60-80% |
| Disk | 40-70% (growth buffer) |
| Network | 30-60% |

> 🔑 **80%+ utilization = capacity risk**. **Below 20% = waste**.

---

## 📊 Profile-Based Sizing

### Step 1: Collect current usage
```promql
# CPU p95 (1 week)
quantile_over_time(0.95,
  rate(container_cpu_usage_seconds_total[5m])[7d:1h]
)

# Memory peak
max_over_time(
  container_memory_working_set_bytes[7d]
)
```

### Step 2: Compute the right size
```
New size = max(p95 × 1.2, p99 × 1.0)

Example: CPU p95 = 600m, p99 = 900m
New = max(720m, 900m) = 900m → 1000m (round up)
```

### Step 3: Validate (1 week of observation)
- Any throttling during HPA scaling spikes?
- OOMKilled?
- Latency impact?

---

## 🛠️ Cloud-Side Right-Sizing

### AWS Compute Optimizer
```bash
aws compute-optimizer get-ec2-instance-recommendations \
  --account-ids <ACCT>
```

→ A specific recommendation like "recommend i3.2xlarge → i3.large".

### GCP Recommender
```bash
gcloud recommender recommendations list \
  --project=<PROJECT> \
  --recommender=google.compute.instance.MachineTypeRecommender
```

### Azure Advisor
```bash
az advisor recommendation list --category Cost
```

---

## 🐳 K8s Right-Sizing

### VPA (Vertical Pod Autoscaler)
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: payments-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: payments
  updatePolicy:
    updateMode: "Off"   # recommendation only
```

```bash
kubectl describe vpa payments-vpa
# Recommendation:
#   cpu: 234m
#   memory: 512Mi
```

→ A human reviews it and applies it manually to the deployment.

### Kubecost
```bash
helm install kubecost kubecost/cost-analyzer \
  -n kubecost --create-namespace \
  --set kubecostToken=<TOKEN>
```

UI: per-namespace + per-pod right-sizing recommendation. Kubecost cluster-wide cost dashboard.

### Goldilocks (open-source)
```bash
helm install goldilocks fairwinds-stable/goldilocks
```

→ Auto-generates a VPA recommendation per namespace + dashboard.

---

## 📦 Database Right-Sizing

### Postgres / MySQL
```sql
-- Connection count
SELECT count(*) FROM pg_stat_activity;

-- Cache hit ratio
SELECT
  sum(blks_hit) / nullif(sum(blks_hit + blks_read), 0)::float
FROM pg_stat_database;
-- > 0.99 = optimal
-- < 0.95 = increase shared_buffers
```

### Sizing rule
- **Burstable** workload → t-class (AWS) / e2 (GCP) / B-series (Azure)
- **Sustained** → r-class (memory) or m-class (general)
- **CPU-heavy** → c-class

> 🔑 Burstable instances choke under 24/7 high CPU. Choose based on the profile.

---

## 🚧 Right-Sizing Risks

### 1. Over-downsizing → crash under spike
- Leave 20-30% headroom
- Validate with a load test

### 2. Memory under-provision → OOMKilled
- Base the memory peak on **max**, not p99

### 3. Insufficient storage IOPS
- Watch the IOPS limit when switching gp3 → gp2

### 4. Reduced network throughput
- Smaller instance = less bandwidth

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Do this instead |
|---|---|---|
| Guess "make it big, we'll downsize later" | $X wasted monthly | Profile-based |
| Right-size once and forget | Workload changes | Quarterly review |
| VPA Auto + HPA Auto on the same resource | Race | VPA Off mode |
| Downsize memory → OOM | Restart cycle | Peak buffer |
| Downsize disk | Migration is hard | Generous + alarm at 80% |
| Reserved + right-size afterwards | Wasted commitment | Right-size **first**, reserved after |
| Same size for production and dev | Dev waste | Per-env sizing |

---

## 📋 Right-Sizing Checklist

```
[ ] Quarterly right-sizing review
[ ] Cloud Compute Optimizer / Advisor / Recommender
[ ] K8s: VPA Off mode + Goldilocks dashboard
[ ] Kubecost (per-namespace cost)
[ ] CI gate: Kubecost diff on the PR (PR-Cost-Diff.md)
[ ] Per-env sizing (dev small, prod profile-based)
[ ] Correct class for burstable vs sustained workload
[ ] Memory: p99 + buffer (OOM prevention)
[ ] Storage: 20%+ headroom + alarm
[ ] DB connection pool (PgBouncer)
[ ] Quarterly cost report to management
```

---

## 📚 References

- **AWS Compute Optimizer** — aws.amazon.com/compute-optimizer
- **GCP Recommender** — cloud.google.com/recommender
- **Kubecost** — kubecost.com
- **Goldilocks** — github.com/FairwindsOps/goldilocks
- **VPA** — github.com/kubernetes/autoscaler
- [`Cloud-Cost-Allocation.md`](Cloud-Cost-Allocation.md)
- [`Spot-Instance-Strategy.md`](Spot-Instance-Strategy.md)
- [`Reserved-and-Savings-Plans.md`](Reserved-and-Savings-Plans.md)
- [`Kubecost-Setup.md`](Kubecost-Setup.md)
- [`14-Sustainability/Efficiency-Practices.md`](../14-Sustainability/Efficiency-Practices.md)

---

> *"Right-sizing isn't a 'one-time cleanup' — it's a **quarterly discipline**.
> Profiles change, traffic grows and shrinks. An undisciplined team's
> AWS bill balloons 20% every 6 months."*

---

> 🎓 **Learning Path:** This document is used as a "Read first" resource in the [`F1`](../22-Learning-Path/block-f-judgment/F1-maliyet-finops.md) module.
