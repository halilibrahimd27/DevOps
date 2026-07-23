---
description: "Kubernetes cost visibility with Kubecost: per-namespace, workload, and label-based dollar-cost dashboards, allocation model, alerts, and the OpenCost alternative."
tags:
  - FinOps
  - Cost Optimization
  - Kubernetes
  - Observability
  - Cost
---
# Kubecost Setup — K8s Cost Visibility

> *"The K8s cluster costs $80K/month, and nobody knows 'who's using it?'
> A team that can't invoice namespaces has **unowned cost**.
> Kubecost = a **per-namespace cost dashboard** for K8s."*

This guide covers installing Kubecost, the allocation model, alert setup, the
Sustainability integration, and the OpenCost (CNCF) alternative.

---

## 🎯 What Is Kubecost?

> **Kubecost**: shows the **dollar cost** of every resource (pod, namespace,
> deployment, label) in a Kubernetes cluster in real time.

```
Cloud bill: $80K/month
   │
   ▼ Kubecost allocation
   │
   ├── namespace=payments     $32K/mo (40%)
   ├── namespace=catalog      $20K/mo (25%)
   ├── namespace=monitoring   $8K/mo  (10%)
   ├── ...
   └── shared (kube-system)   $4K/mo  (5%)
```

---

## 🚀 Installation

### Helm install
```bash
helm install kubecost kubecost/cost-analyzer \
  -n kubecost --create-namespace \
  --set kubecostToken="<TOKEN>" \
  --set prometheus.server.persistentVolume.enabled=true
```

### Cloud integration (the real bill)
```yaml
# values.yaml
kubecostProductConfigs:
  cloudIntegrationSecret: cloud-integration
  awsSpotDataRegion: <REGION>
  awsSpotDataBucket: <SPOT_DATA_BUCKET>
  cloudCostsEnabled: true
```

```bash
# AWS billing data
kubectl create secret generic cloud-integration \
  -n kubecost \
  --from-literal=cloud-integration.json='{
    "aws": [{
      "athenaProjectId": "<ACCT>",
      "athenaBucketName": "<CUR_BUCKET>",
      "athenaRegion": "<REGION>",
      "athenaDatabase": "athenacurcfn",
      "athenaTable": "<CUR_TABLE>",
      "serviceKeyName": "<KEY>",
      "serviceKeySecret": "<SECRET>"
    }]
  }'
```

→ Kubecost pulls the real bill from the AWS Cost & Usage Report.

---

## 📊 Allocation Model

### Aggregation
- **Namespace**: per-team
- **Deployment**: per-service
- **Label**: pods labeled with `team`, `cost-center`
- **Annotation**: custom

### Idle costs
- The cluster's empty capacity: who pays for it?
- Default: distribute **proportionally** (each tenant's share)
- Alternative: a shared `_unallocated` namespace

---

## 🛠️ Kubecost UI

### Cost Allocation
```
[UI: Cost Allocation]
  Filter: namespace=payments, last 30d
  Total: $32,000

  Breakdown:
    CPU: $18K (56%)
    Memory: $9K (28%)
    GPU: $3K (9%)
    PV (storage): $1K (3%)
    Network egress: $1K (3%)
```

### Right-Sizing Recommendations
```
[UI: Savings]
  Pod: payments-api-7d8...
    Current: 4 vCPU, 8 GB
    Recommended: 1 vCPU, 2 GB
    Estimated saving: $400/mo

  Total potential saving: $12,000/mo (15% of cluster)
```

### Cluster Comparison
- Multi-cluster: which cluster is most expensive, and why?
- Region cost comparison

---

## 🚨 Alerts

```yaml
# values.yaml
notifications:
  alertConfigs:
    enabled: true
    alerts:
      - type: budget
        threshold: 10000   # above $10K/month
        window: 7d
        aggregation: namespace
        filter: payments
        slackWebhookUrl: <WEBHOOK>

      - type: efficiency
        efficiencyThreshold: 0.4   # below 40% efficiency
        spendThreshold: 1000
        aggregation: deployment
```

→ Slack alert: "Payments namespace $12K over 7 days, exceeded the budget".

---

## 📈 Per-PR Cost Diff (in CI)

> Show "how much extra cost this deploy adds" on the PR.

```yaml
# .github/workflows/cost-diff.yml
- uses: kubecost/kubecost-cost-action@<VERSION>
  with:
    api-key: ${{ secrets.KUBECOST_API_KEY }}
    repo: <ORG>/<REPO>
    pr-number: ${{ github.event.pull_request.number }}
```

→ PR comment:
```
💰 Cost Impact:
  CPU: +200m → +$15/mo
  Memory: +512Mi → +$6/mo
  Total: +$21/mo (+2.3%)
```

> Details: [`PR-Cost-Diff.md`](PR-Cost-Diff.md).

---

## 🌱 Sustainability — Carbon Estimation

```yaml
# Carbon estimation
sustainability:
  carbon:
    enabled: true
    region: eu-west-1
```

→ Per-namespace **CO₂ emission** estimate (Cloud Carbon Footprint integration).

---

## ⚖️ Kubecost vs OpenCost

| Dimension | Kubecost | OpenCost |
|---|---|---|
| **License** | Free + paid tiers | Apache 2 (CNCF) |
| **Community** | Kubecost Inc | CNCF, broader |
| **Features** | More (UI, alerts, multi-cluster) | Core engine |
| **Cloud integration** | Native | Manual |
| **Usage** | UI-driven | API + custom dashboard |

> 🔑 **Kubecost** = OpenCost engine + UI + premium features. **2026 recommendation**: the Kubecost free tier is enough for most.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Do this instead |
|---|---|---|
| No cost transparency | "Who's spending what?" goes unanswered | Kubecost / OpenCost |
| All cluster cost lumped as shared | No allocation | Namespace + label |
| Idle cost in a central pool | Free for teams | Distribute proportionally |
| No cost alerts | Budget surprises | Per-team threshold |
| Ignoring right-sizing recommendations | Waste | Quarterly review |
| No PR cost diff | Devs are cost-blind | CI integration |
| Cloud bill + Kubecost out of sync | Wrong estimates | Integrate CUR / Billing API |
| No multi-cluster cost view | Comparison impossible | Multi-cluster Kubecost |

---

## 📋 Kubecost Production Checklist

```
[ ] Kubecost / OpenCost deployed
[ ] Cloud billing integration (CUR / Billing Export)
[ ] Allocation: namespace + label (team / cost-center)
[ ] Idle cost: distribute proportionally
[ ] Right-sizing recommendation review (quarterly)
[ ] Slack alert: per-team budget threshold
[ ] PR cost diff in CI
[ ] Sustainability/carbon integration
[ ] Multi-cluster (if any) in a single dashboard
[ ] Quarterly cost report to management
[ ] Per-team cost dashboard self-service
[ ] Annual: cost optimization roadmap
```

---

## 📚 References

- **Kubecost** — kubecost.com
- **OpenCost (CNCF)** — opencost.io
- **AWS Cost & Usage Report** — aws.amazon.com/aws-cost-management/aws-cost-and-usage-reporting
- **GCP Billing Export** — cloud.google.com/billing/docs/how-to/export-data-bigquery
- [`Cloud-Cost-Allocation.md`](Cloud-Cost-Allocation.md)
- [`Right-Sizing.md`](Right-Sizing.md)
- [`PR-Cost-Diff.md`](PR-Cost-Diff.md)
- [`Storage-Cost-Optimization.md`](Storage-Cost-Optimization.md)
- [`14-Sustainability/Measuring-Software-Carbon.md`](../14-Sustainability/Measuring-Software-Carbon.md)

---

> *"Kubecost isn't an 'optional finance tool' — it's **K8s's cost
> view**. If you can't answer 'how much does each namespace cost?' in 5
> minutes, **unowned cost** is piling up."*
