---
description: "Long-term commitment strategy for AWS Reserved Instances, Savings Plans, GCP CUDs, and Azure Reservations; forecasting, commitment ladder, avoiding over-commit."
tags:
  - FinOps
  - Cost Optimization
  - AWS
  - Cost
---
# Reserved Instances & Savings Plans — Long-Term Commitment

> *"A team running prod on on-demand could have bought **3-year Reserved**
> for 50-70% less. The 'lock-in' excuse costs $X. Correct forecast
> + **commitment ladder** = guaranteed savings."*

This guide covers practical strategy for AWS Reserved Instances (RI),
Savings Plans (SP), GCP CUDs, and Azure Reservations, and how to avoid
over-committing.

---

## 📊 Cloud Commitment Types

| Type | AWS | GCP | Azure |
|---|---|---|---|
| **Compute discount** | EC2 RI / Compute SP | CUDs | Reservations |
| **DB discount** | RDS RI | CUDs | SQL Reservations |
| **Storage** | S3 reserved | - | - |

### AWS-specific
| Type | Discount | Flexibility |
|---|---|---|
| **EC2 Standard RI** | 40-50% | Low (instance type fixed) |
| **EC2 Convertible RI** | 30-40% | Medium (type can change) |
| **Compute Savings Plan** | 40-66% | High (any region/family) |
| **EC2 Instance Savings Plan** | 50-72% | Low (specific region) |

> 🔑 **2026 recommendation**: Compute Savings Plan (flexibility) > Standard RI.

---

## 🎯 Commitment Strategy

### Step 1: Determine the baseline workload
- "What's the minimum capacity that will **definitely** run over 12 months?"
- Production services, critical workloads
- **Excluding** workloads that can run on spot/preemptible

### Step 2: Forecast (12-36 months)
- Current growth rate
- New feature roadmap
- Customer-base change

### Step 3: Commitment ladder
```
Year 1: 50% baseline → 1-year SP (medium upfront)
Year 1+1: 70% baseline → 1-year SP renewal + additional
Year 1+2: 80% baseline → 3-year SP (highest discount)
```

> 🔑 **Phased commitment** → reduces over-commit risk.

### Step 4: Spot + RI hybrid
```
Workload composition:
  Stateful DB → On-demand or RI (1-year)
  Stateless prod replica → SP (60% baseline) + on-demand (peak)
  Background batch → Spot
  Dev/staging → Spot
```

---

## 💰 Commitment vs Pay-As-You-Go

```
m5.large baseline (1 instance, 24/7):
  On-demand:       $0.096 × 720 = $69/mo
  1-yr no upfront: $0.060 × 720 = $43/mo  (38% savings)
  3-yr no upfront: $0.040 × 720 = $29/mo  (58% savings)
  3-yr all upfront: $24/mo equivalent     (65% savings)
```

### Upfront options
| Type | Cash flow | Discount |
|---|---|---|
| **No upfront** | Equal monthly | Low |
| **Partial upfront** | 40% upfront + monthly | Medium |
| **All upfront** | 100% upfront | Highest |

> 💸 **All upfront**: best when cash flow allows, 3-5% extra discount.

---

## 🛡️ Over-Commit Risk

### Scenario
```
Year 0: 3-yr SP $1M commitment, 100 instances
Year 1: Workload migration → 50 instances suffice
Year 2: $500K idle commitment (unused)
```

### Mitigation
1. **Phased commitment ladder** (above)
2. **Convertible RI** (sell on AWS Marketplace)
3. **Partial commitment**: 50-70% baseline (on-demand for peak)
4. **Quarterly review**: actual usage vs commit

---

## 📊 AWS Cost Explorer — Recommendation

```bash
# Compute Savings Plan recommendation
aws ce get-savings-plans-purchase-recommendation \
  --savings-plans-type COMPUTE_SP \
  --term-in-years ONE_YEAR \
  --payment-option NO_UPFRONT \
  --lookback-period-in-days SIXTY_DAYS
```

→ AWS recommends: "$Y savings with a $X yearly commitment".

### Continuous monitoring
- **AWS Cost Explorer** → coverage % (commitment utilization rate)
- < 85% coverage → over-committed (idle money)
- < 70% → buy more SP

---

## 🌍 GCP CUDs (Committed Use Discounts)

```bash
gcloud compute commitments create my-commitment \
  --project=<PROJECT> \
  --region=<REGION> \
  --plan=THIRTY_SIX_MONTH \
  --resources=vcpu=10,memory=40
```

| Term | Discount |
|---|---|
| 1 year | 25-37% |
| 3 years | 52-70% |

> GCP CUDs are **resource-based** (vCPU + memory), a bit different from AWS RI/SP.

---

## ☁️ Azure Reservations

| Type | Discount |
|---|---|
| 1-year Reservation | 35-40% |
| 3-year Reservation | 55-65% |

```bash
az reservations reservation-order list
```

---

## 📈 Coverage Dashboard

```promql
# Custom: AWS Cost Explorer API → Prometheus
aws_cost_explorer_savings_plans_coverage_percentage
```

### Targets
- **Coverage %**: 70-85% (not over, not under)
- **Utilization %**: > 95% (the used portion of the commitment)
- **On-demand %**: < 30% (for peak buffer)

### Quarterly review
1. Coverage: below 70% → buy more SP
2. Coverage: 95%+ → over-committed, you may be losing peak
3. New SP need: 30+ days of steady on-demand pattern

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Do this instead |
|---|---|---|
| All prod on-demand | Pay 50-70% too much | SP + spot mix |
| 100% commit (no peak buffer) | Capacity falls short on a spike | 70-80% commit |
| Standard RI instead of Convertible | Lock-in | Compute SP / Convertible |
| 3-yr commit on greenfield | Workload keeps changing | 1-yr ladder |
| No coverage tracking | Over/under-commit | Quarterly review |
| All-upfront without the cash flow | Liquidity problem | No-upfront or partial |
| No commitment, "we already have spot" | Spot interruption and commit are separate niches | Use them together |
| Committing per account | Global pool lost | Organization-wide SP (consolidated) |
| Not knowing about RI marketplace selling | Over-commit loss | Convertible + sell |

---

## 📋 Commitment Strategy Checklist

```
[ ] Baseline workload analysis (12 months)
[ ] Forecast: growth + feature roadmap
[ ] Commitment ladder plan (1-yr → 3-yr phased)
[ ] 70-80% baseline commit (peak buffer)
[ ] Compute SP > Standard RI (flexibility)
[ ] Coverage dashboard
[ ] Quarterly review (under/over-commit)
[ ] Convertible RI (for flexibility)
[ ] Marketplace sell strategy (over-commit fallback)
[ ] Hybrid: SP (steady) + spot (batch) + on-demand (peak)
[ ] Multi-account: org-wide SP pool
[ ] Budget alarm (commit + actual)
[ ] Annual: commitment review to leadership
```

---

## 📚 References

- **AWS Savings Plans** — aws.amazon.com/savingsplans
- **AWS Cost Explorer** — aws.amazon.com/aws-cost-management/
- **GCP CUDs** — cloud.google.com/compute/docs/instances/signing-up-committed-use-discounts
- **Azure Reservations** — azure.microsoft.com/en-us/pricing/reserved-vm-instances
- **FinOps Foundation** — finops.org
- [`Cloud-Cost-Allocation.md`](Cloud-Cost-Allocation.md)
- [`Right-Sizing.md`](Right-Sizing.md)
- [`Spot-Instance-Strategy.md`](Spot-Instance-Strategy.md)
- [`Kubecost-Setup.md`](Kubecost-Setup.md)

---

> *"A Reserved/Savings Plan isn't **'lock-in'** — it's a **forecasted commitment**.
> The right-size + spot + commit trio can cut the cloud bill by **40-60%**.
> A team that does none of them is overpaying at **on-demand price**."*
