---
description: "Making sense of the cloud bill: answering who spent what on; cost allocation via tagging strategy, showback, chargeback, and anomaly detection."
tags:
  - FinOps
  - Cost Optimization
  - AWS
  - Cost
---
# Cloud Cost Allocation — Making Sense of the Bill

> *"This month's AWS bill is $42,318. For what? I don't know. Which
> team burned it through? I don't know. Where could we optimize? I don't know."*
> Teams that can answer these questions within hours cut their costs
> by **30-50% within 2 years.**

---

## 📐 Goal

For every dollar (or TRY/EUR): **who spent it, and on what?**

3 points:
1. **Showback** — each team sees its own cost (peer pressure)
2. **Chargeback** — finance issues teams an internal invoice (real accounting)
3. **Anomaly detection** — catch surprises before month-end

---

## 🏷️ 1. Tagging Strategy (Foundation)

If tagging is missing, no allocation works. **Invest in this first.**

### Required tag set

| Tag | Example | Why |
|---|---|---|
| `Environment` | `prod`, `staging`, `dev` | Cost separation |
| `Team` | `payments`, `growth`, `platform` | Ownership |
| `Service` | `api`, `worker`, `db` | Workload-level |
| `CostCenter` | `eng-1234` | Finance integration |
| `ManagedBy` | `terraform`, `helm`, `manual` | Drift detection |
| `Owner` | `<TEAM_HANDLE>` | Accountability |
| `Project` (optional) | `mobile-revamp` | Initiative tracking |

### Enforcement

**1️⃣ AWS Service Control Policy (org-level)**

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Deny",
    "Action": ["ec2:RunInstances"],
    "Resource": "arn:aws:ec2:*:*:instance/*",
    "Condition": {
      "Null": { "aws:RequestTag/Environment": "true" }
    }
  }]
}
```

**2️⃣ Terraform validation**

```hcl
# modules/required-tags/main.tf
variable "tags" {
  type = map(string)
  validation {
    condition = alltrue([
      contains(keys(var.tags), "Environment"),
      contains(keys(var.tags), "Team"),
      contains(keys(var.tags), "CostCenter"),
    ])
    error_message = "Tags Environment, Team, CostCenter are required."
  }
}
```

**3️⃣ Kyverno (Kubernetes)**

```yaml
# inside 17-Templates/kyverno-policies/require-labels.yaml
```

**4️⃣ AWS Config Rules** — `required-tags` rule, automatically reports non-compliant resources.

### Retroactively tagging existing resources

```bash
# Bulk-tag with the AWS Resource Groups Tagging API
aws resourcegroupstaggingapi tag-resources \
  --resource-arn-list arn:aws:s3:::bucket1 arn:aws:s3:::bucket2 \
  --tags Environment=prod,Team=platform,CostCenter=eng-1001
```

> 💡 **Tip:** Weekly untagged-resource report. Resources that stay
> untagged for 4 weeks running **get automatically stopped** (Lambda + scheduled).

---

## 📊 2. Allocation Reports

### A. AWS Cost Explorer (built-in)

```bash
# This month, by service
aws ce get-cost-and-usage \
  --time-period Start=$(date -d 'first day of month' +%F),End=$(date +%F) \
  --granularity DAILY \
  --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# By tag (Team = payments)
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '30 days ago' +%F),End=$(date +%F) \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --filter '{"Tags":{"Key":"Team","Values":["payments"]}}'

# Group-by with tag breakdown
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '30 days ago' +%F),End=$(date +%F) \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=TAG,Key=Team
```

### B. Cost & Usage Report (CUR) → Athena

CUR is detailed (every resource, every hour) but huge. Query it with Athena:

```sql
-- Top 20 service by cost (last 7 days)
SELECT
  product_servicecode AS service,
  SUM(line_item_unblended_cost) AS cost
FROM cost_and_usage_report
WHERE line_item_usage_start_date >= date_add('day', -7, current_date)
GROUP BY product_servicecode
ORDER BY cost DESC
LIMIT 20;

-- Per-team breakdown
SELECT
  resource_tags_user_team AS team,
  SUM(line_item_unblended_cost) AS cost
FROM cost_and_usage_report
WHERE line_item_usage_start_date >= date_add('day', -30, current_date)
  AND resource_tags_user_team IS NOT NULL
GROUP BY resource_tags_user_team
ORDER BY cost DESC;

-- Untagged resources (money you're losing track of)
SELECT
  product_servicecode,
  SUM(line_item_unblended_cost) AS cost,
  COUNT(DISTINCT line_item_resource_id) AS resource_count
FROM cost_and_usage_report
WHERE line_item_usage_start_date >= date_add('day', -7, current_date)
  AND resource_tags_user_team IS NULL
GROUP BY product_servicecode
ORDER BY cost DESC;
```

### C. Kubernetes — OpenCost / Kubecost

For Kubernetes cost attribution (the cloud bill isn't K8s-native):

```bash
# OpenCost (CNCF, OSS)
helm install opencost opencost/opencost -n opencost --create-namespace

# Kubecost (superset of OpenCost, includes UI)
helm install kubecost \
  --repo https://kubecost.github.io/cost-analyzer \
  cost-analyzer \
  -n kubecost \
  --create-namespace
```

These tools give you:
- Per-pod compute/memory cost
- Namespace breakdown
- Workload (deployment) breakdown
- PVC cost
- Idle resources (requested but never used) — **hidden waste**

```bash
# Via CLI (Kubecost API)
curl http://kubecost.kubecost:9090/model/allocation \
  --data-urlencode 'window=7d' \
  --data-urlencode 'aggregate=namespace' \
  --data-urlencode 'accumulate=true' | jq
```

---

## 💸 3. Showback / Chargeback Model

### Showback (recommended starting point)

Each team **sees** its own cost; no finance transaction happens.

**Monthly dashboard / e-mail:**

```
┌────────────────────────────────────────────────┐
│  Team: payments                                 │
│  Period: March 2026                             │
├────────────────────────────────────────────────┤
│  Total: $4,820                                  │
│                                                  │
│  Compute (EKS)             $2,340  (49%)         │
│  RDS (Postgres)            $1,200  (25%)         │
│  S3 (snapshots)              $480  (10%)         │
│  Data transfer (egress)      $400   (8%)         │
│  CloudWatch logs             $180   (4%)         │
│  Other                       $220   (4%)         │
│                                                  │
│  vs last month: +$340 (+8%)                      │
│  vs budget:     ($5,000 budget, 96% of budget)   │
│                                                  │
│  ⚠️  Anomaly: S3 +$200 (snapshots 30→90 day)     │
│                                                  │
│  🔝 Top 5 cost drivers:                          │
│  1. eks-prod-cluster       $1,800                │
│  2. rds-payments-primary     $720                │
│  3. eks-staging-cluster      $540                │
│  4. rds-payments-replica     $480                │
│  5. s3-payment-receipts      $480                │
└────────────────────────────────────────────────┘
```

### Chargeback (large orgs)

Finance issues each team an internal invoice. The engineering budget becomes real = team cost.

**Advantage:** maximum cost awareness
**Disadvantage:** bureaucratic, overkill for small orgs

---

## 🚨 4. Anomaly Detection

Prevents month-end surprise spikes.

### AWS Cost Anomaly Detection (built-in)

```bash
# Create a monitor (daily anomaly tracking per service)
aws ce create-anomaly-monitor --anomaly-monitor '{
  "MonitorName": "Daily-Service-Anomaly",
  "MonitorType": "DIMENSIONAL",
  "MonitorDimension": "SERVICE"
}'

# Subscription (Slack/email)
aws ce create-anomaly-subscription --anomaly-subscription '{
  "SubscriptionName": "FinOps-Slack",
  "Threshold": 100,
  "Frequency": "DAILY",
  "MonitorArnList": ["arn:aws:ce::<ACCOUNT_ID>:anomalymonitor/<ID>"],
  "Subscribers": [{"Type":"SNS","Address":"arn:aws:sns:<REGION>:<ACCOUNT_ID>:cost-alerts"}]
}'
```

### Custom (more sensitive) — Athena + cron

```sql
-- Yesterday vs 7-day average, deviation > 30%
WITH daily AS (
  SELECT
    DATE(line_item_usage_start_date) AS day,
    resource_tags_user_team AS team,
    product_servicecode AS service,
    SUM(line_item_unblended_cost) AS cost
  FROM cost_and_usage_report
  WHERE line_item_usage_start_date >= date_add('day', -8, current_date)
  GROUP BY 1, 2, 3
)
SELECT
  team, service,
  yesterday_cost,
  weekly_avg,
  ROUND(((yesterday_cost - weekly_avg) / weekly_avg) * 100, 1) AS pct_change
FROM (
  SELECT
    team, service,
    SUM(CASE WHEN day = current_date - 1 THEN cost END) AS yesterday_cost,
    AVG(CASE WHEN day BETWEEN current_date - 8 AND current_date - 2 THEN cost END) AS weekly_avg
  FROM daily
  GROUP BY 1, 2
)
WHERE yesterday_cost > 50  -- noise filter
  AND yesterday_cost > weekly_avg * 1.30
ORDER BY pct_change DESC;
```

Post the result to Slack:
```
🚨 Cost anomaly detected:
- payments / RDS: $250 yesterday (avg $80, +212%)
- growth / DataTransfer: $890 yesterday (avg $300, +197%)
```

---

## 🎯 5. Quick Wins (15-30% savings in the first 30 days)

```bash
# 1. Idle EC2 (stopped > 30 days)
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=stopped" \
  --query 'Reservations[].Instances[?StateTransitionReason!=null && StateTransitionReason<`'$(date -d '30 days ago' +%F)'`]'

# 2. Idle Elastic IP (~$3.6/month each)
aws ec2 describe-addresses \
  --query 'Addresses[?AssociationId==null].[PublicIp,AllocationId]'

# 3. Unused EBS volume
aws ec2 describe-volumes --filters Name=status,Values=available

# 4. EBS gp2 → gp3 (same performance, 20% cheaper)
aws ec2 describe-volumes \
  --filters Name=volume-type,Values=gp2 \
  --query 'Volumes[].VolumeId' --output text \
  | xargs -n 1 aws ec2 modify-volume --volume-type gp3 --volume-id

# 5. Old snapshots
aws ec2 describe-snapshots --owner-ids self \
  --query "Snapshots[?StartTime<='$(date -d '90 days ago' +%F)'].SnapshotId" \
  --output text | xargs -n1 aws ec2 delete-snapshot --snapshot-id

# 6. RDS public access (misconfiguration + cost)
aws rds describe-db-instances \
  --query 'DBInstances[?PubliclyAccessible==`true`].[DBInstanceIdentifier]'

# 7. Idle Load Balancer
aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerArn' \
  --output text | while read arn; do
  count=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB --metric-name RequestCount \
    --dimensions Name=LoadBalancer,Value=${arn##*/} \
    --start-time $(date -u -d '7 days ago' +%FT%TZ) \
    --end-time $(date -u +%FT%TZ) --period 86400 --statistics Sum \
    --query 'sum(Datapoints[].Sum)' --output text)
  [ "$count" = "None" -o "$count" = "0.0" ] && echo "Idle: $arn"
done
```

### Egress (the biggest hidden cost)

> AWS data transfer OUT costs $0.09/GB. 1 TB/month = $90. 50 TB/month = $4,500.
> Unless you keep watch, it **grows unchecked.**

- ✅ S3 → EC2 within the same region: free
- ✅ VPC Endpoint (S3/DynamoDB): eliminates NAT GW egress
- ✅ CloudFront / CDN: cache close to the user
- ✅ Cloudflare R2 — no egress fee
- ❌ Cross-AZ within the same region (easy to overlook, but adds $0.01/GB)
- ❌ Cross-region (the most expensive)

---

## 📈 6. Reserved Instances / Savings Plans

Buy your regularly-used baseline capacity with a commitment:

| Strategy | Discount | Risk |
|---|---|---|
| **3-year all-upfront RI** | up to 72% | High (no flexibility) |
| **1-year SP (Compute)** | 30-50% | Medium (instance type can be changed) |
| **3-year SP (Compute)** | 50-65% | High |
| **Spot** | 50-90% | High (interruption) |

### Strategy recommendation

```
Baseline (24/7 continuous)        → SP 1-year compute
Stable, type won't change         → RI 1-year
Burst / batch / fault-tolerant    → Spot
Dev/test                          → Spot (auto-pause overnight)
```

> ⚠️ **Commit cliff**: Set an alarm 60 days before your 1-year SP's
> expiration date. Have a renewal plan ready. Hitting the cliff and watching costs explode is a common mistake.

---

## 🛠️ 7. PR-time Cost Diff (Infracost)

Cost diff before merge, on Terraform change PRs:

```yaml
# .github/workflows/infracost.yml
name: Infracost
on: [pull_request]

jobs:
  diff:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: infracost/actions/setup@v3
        with:
          api-key: ${{ secrets.INFRACOST_API_KEY }}
      - name: Generate baseline
        run: |
          git checkout ${{ github.event.pull_request.base.ref }}
          infracost breakdown --path terraform --format json --out-file baseline.json
      - name: Generate diff
        run: |
          git checkout ${{ github.event.pull_request.head.ref }}
          infracost diff --path terraform --compare-to baseline.json --format json --out-file diff.json
      - name: PR comment
        run: infracost comment github --path diff.json --behavior update \
                --repo $GITHUB_REPOSITORY --pull-request ${{ github.event.pull_request.number }} \
                --github-token ${{ secrets.GITHUB_TOKEN }}
```

Automatic comment on the PR:
```
### 💰 Infracost estimate

Project       baseline  PR        diff
my-infra      $4,820    $5,140    +$320 (+6.6%)

Top changes:
+ aws_db_instance.replica          +$240/mo
+ aws_eks_node_group.gpu-pool       +$180/mo
- aws_instance.legacy-bastion      -$100/mo

Monthly cost change: +$320
```

---

## 🚫 Anti-Pattern

The most common mistakes in cost allocation — the ones that leave the bill unreadable:

| Anti-pattern | Why it's bad | Do this instead |
|---|---|---|
| Starting allocation without tag enforcement | Untagged resources = unattributable money; the report comes out full of holes | Enforce tags with SCP/Config/Kyverno first, then report |
| Only looking at the total bill | You can't see which team/service burned it; optimization is blind | Pull a breakdown by Team + Service tag |
| Waiting until month-end to check the bill | Surprise spike; the deviation grows for 30 days straight | Daily anomaly detection (Cost Anomaly or an Athena cron) |
| Doing resource-level analysis with Cost Explorer | CE is aggregate; you can't track a single resource | Use CUR → Athena for resource-level work |
| Reading Kubernetes cost off the cloud bill | The bill is node-based; no pod/namespace attribution | Pod-level allocation with OpenCost/Kubecost |
| Ignoring egress cost | Grows unchecked ($0.09/GB); the biggest hidden expense | Track VPC Endpoint + CDN + cross-region traffic |
| Jumping straight to a 3-year all-upfront RI | Zero flexibility; money's wasted the moment the instance type changes | Start with a 1-year SP, commit longer once usage settles |
| Not tracking SP/RI expiration | Hitting the commit cliff and dropping to on-demand pricing | Alarm 60 days before expiration + a renewal plan |
| Leaving idle resources (unused EIP/EBS/LB) running | Racks up charges while unused; piles up month after month | Weekly idle scan + automatic cleanup |
| Dumping all cost on one central team (no showback) | Nobody sees their own consumption, no accountability | Showback dashboard; each team sees its own cost |
| Noticing the cost diff after merge | Expensive resources leak into prod, hard to walk back | See it before merge with a PR-time Infracost diff |

---

## 📋 Checklist

Concrete items for production-ready cost allocation:

**Tagging foundation**
- [ ] Required tag set defined (`Environment`, `Team`, `Service`, `CostCenter`, `ManagedBy`, `Owner`)
- [ ] SCP blocks creating untagged resources (org-level)
- [ ] Terraform `required-tags` module is used across all modules
- [ ] Kyverno/AWS Config tag-compliance auditing is active for K8s + AWS
- [ ] Existing (legacy) resources have been retro-tagged
- [ ] Weekly untagged report is automatic; resources untagged for 4 straight weeks get stopped

**Reporting**
- [ ] CUR is active and connected to Athena (resource-level queries possible)
- [ ] Team-based breakdown report works
- [ ] Untagged-cost report is monitored (lost money is visible)
- [ ] OpenCost/Kubecost installed for Kubernetes (pod/namespace allocation)

**Showback / Chargeback**
- [ ] Every team gets a monthly showback dashboard/e-mail
- [ ] Budget vs. actual comparison is in the report
- [ ] (Large org) Chargeback internal-invoice flow integrated with finance

**Anomaly & alarm**
- [ ] AWS Cost Anomaly Detection monitor + subscription active
- [ ] Daily deviation query (>30%) lands in Slack/e-mail
- [ ] Alarm subscriber ARN/endpoint parametrized with `<PLACEHOLDER>`, no hardcoded credentials

**Optimization**
- [ ] Idle EC2/EBS/EIP/LB scanned weekly
- [ ] gp2→gp3 migration and old-snapshot cleanup planned
- [ ] Egress (data transfer) monitored; VPC Endpoint/CDN in place
- [ ] RI/SP strategy set based on baseline; alarm 60 days before expiration
- [ ] PR-time Infracost diff runs in CI

---

## 📚 Further Reading

- [FinOps Foundation](https://www.finops.org)
- [FOCUS specification](https://focus.finops.org) — vendor-neutral cost spec
- [AWS Well-Architected — Cost Optimization Pillar](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/)
- [OpenCost docs](https://www.opencost.io)
- _Right Sizing → 12-FinOps/Right-Sizing.md_ *(coming soon)*

---

## 📚 References

- [Kubecost / OpenCost setup](Kubecost-Setup.md) — pod/namespace-level K8s allocation
- [Right-Sizing](Right-Sizing.md) — tuning requests/limits, closing off idle waste
- [Reserved & Savings Plans](Reserved-and-Savings-Plans.md) — commitment strategy and cliff management
- [Egress cost reduction](Egress-Cost-Reduction.md) — the hidden bill behind data transfer
- [PR-time Cost Diff (Infracost)](PR-Cost-Diff.md) — cost visibility before merge
- [AWS Well-Architected — Cost Optimization Pillar](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/)

---

> *"Untagged cost is unowned cost; without tying the bill to allocation, you're not optimizing — you're just guessing."*
