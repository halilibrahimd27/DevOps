---
description: "Storage cost optimization for S3, EBS, snapshots, and backups: concrete savings through lifecycle policies, tier transitions, and idle volume / zombie snapshot cleanup."
tags:
  - FinOps
  - Cost Optimization
  - AWS
  - Backup
  - Cost
---
# Storage Cost Optimization — S3, EBS, Snapshot, Backup

> *"S3 bill $20K/mo, 80% of it is 6-month-old logs + zombie snapshots.
> Lifecycle policy + tier transition = same data **70% cheaper**.
> 4 hours of work, a permanent $14K/mo savings."*

This guide covers cost optimization techniques for S3 / EBS / snapshots / backups,
with concrete commands and lifecycle policies.

---

## 🎯 Storage Cost Drivers

| Cost source | % common |
|---|---|
| **EBS volumes** (idle) | 20-40% |
| **EBS snapshots** (old, unused) | 15-30% |
| **S3 Standard** (old logs/files) | 20-40% |
| **NAT Gateway egress** | 10-25% |
| **Backup retention** (uncontrolled) | 15-30% |

---

## 🪣 1️⃣ S3 Lifecycle Policy

### Staged tier
```yaml
LifecycleRules:
  - Filter: {Prefix: logs/}
    Transitions:
      - Days: 30
        StorageClass: STANDARD_IA      # 40% cheaper
      - Days: 90
        StorageClass: GLACIER          # 80% cheaper
      - Days: 365
        StorageClass: DEEP_ARCHIVE     # 95% cheaper
    Expiration: {Days: 2555}            # 7 years
```

### Cost comparison (per TB per month)
```
STANDARD:        $23
STANDARD_IA:     $12.5
GLACIER:         $4
GLACIER_IR:      $5      (instant retrieval)
DEEP_ARCHIVE:    $1
```

### Use case mapping
| Data type | Recommended class |
|---|---|
| Active data | STANDARD |
| Old logs (30+ days, occasional access) | STANDARD_IA |
| Compliance audit (1+ year) | GLACIER or DEEP_ARCHIVE |
| Backup (1+ year) | GLACIER + Object Lock |

### Intelligent-Tiering
```yaml
StorageClass: INTELLIGENT_TIERING
```

→ AWS shifts tiers automatically (tier transition fee $0.0025/1K objects).

---

## 💾 2️⃣ EBS Optimization

### Idle volume detection
```bash
# Detached volumes
aws ec2 describe-volumes \
  --filters "Name=status,Values=available" \
  --query 'Volumes[*].[VolumeId, Size, CreateTime]' \
  --output table

# Idle but attached (CloudWatch read/write 0)
aws cloudwatch get-metric-statistics \
  --namespace AWS/EBS \
  --metric-name VolumeReadOps \
  --dimensions Name=VolumeId,Value=vol-xxx \
  --start-time $(date -d '14 days ago' +%FT%T) \
  --end-time $(date +%FT%T) \
  --period 86400 \
  --statistics Sum
```

### gp3 migration (from gp2)
```bash
# gp2 → gp3: 20% cheaper + better IOPS
aws ec2 modify-volume \
  --volume-id vol-xxx \
  --volume-type gp3 \
  --iops 3000 --throughput 125
```

> 🔑 **gp3 default is cheaper than gp2**. Migration is easy, instant.

### Right-sizing
- 100 GB volume, 30% usage → shrink to 50 GB (tooling: shrink lvm/xfs/ext4)
- > 80% usage → grow (gp3 instant)

---

## 📸 3️⃣ Snapshot Cleanup

### Old snapshots
```bash
# 90+ days old
aws ec2 describe-snapshots --owner-ids self \
  --query 'Snapshots[?StartTime<=`2026-02-04`].[SnapshotId, StartTime, Description]' \
  --output table

# Automatic delete (Cloud Custodian policy)
```

```yaml
# custodian-snapshot-cleanup.yml
policies:
  - name: ebs-snapshot-old
    resource: ebs-snapshot
    filters:
      - type: age
        days: 90
        op: gt
      - "tag:DoNotDelete": absent
    actions:
      - delete
```

```bash
custodian run -s out custodian-snapshot-cleanup.yml
```

### Lifecycle Manager (DLM)
```yaml
# AWS DLM: scheduled snapshot
ResourceTypes: [VOLUME]
Schedules:
  - Name: daily
    CreateRule: {Interval: 24, IntervalUnit: HOURS}
    RetainRule: {Count: 7}    # keep for 7 days
```

---

## 🌐 4️⃣ Egress Cost (NAT Gateway / Inter-AZ)

### Egress cost
```
S3 GET (within AWS region):    $0
S3 GET (cross region):         $0.02/GB
EC2 → Internet:                $0.09/GB
NAT Gateway:                   $0.045/GB
Inter-AZ:                      $0.01/GB
```

### Optimization
1. **VPC Endpoints** (NAT bypass for S3, DynamoDB)
   ```bash
   aws ec2 create-vpc-endpoint \
     --vpc-id vpc-xxx \
     --service-name com.amazonaws.<REGION>.s3 \
     --route-table-ids rtb-xxx
   ```
   → S3 traffic bypasses the NAT, **$0**.

2. **Minimize cross-AZ traffic**: pod anti-affinity, single-AZ for non-HA

3. **CDN**: edge cache → origin traffic drops 50%+

---

## 📦 5️⃣ Backup Retention Discipline

### Rule
- **Production daily backup**: 30 days
- **Weekly**: 12 weeks
- **Monthly**: 12 months
- **Yearly (compliance)**: 7 years

### Automatic cleanup
```yaml
# AWS Backup
BackupPlanRule:
  RuleName: daily
  TargetBackupVaultName: prod-vault
  ScheduleExpression: cron(0 2 * * ? *)
  Lifecycle:
    DeleteAfterDays: 30
    MoveToColdStorageAfterDays: 7   # cheap tier

  RuleName: monthly
  ScheduleExpression: cron(0 2 1 * ? *)
  Lifecycle:
    DeleteAfterDays: 365
    MoveToColdStorageAfterDays: 30
```

---

## 🔍 Storage Cost Audit

### Quarterly review
```bash
# Top 10 cost-heavy bucket
aws s3 ls --summarize --human-readable

# Is there a lifecycle policy?
aws s3api get-bucket-lifecycle-configuration --bucket <BUCKET>

# Versioning storage cost
aws s3api list-object-versions --bucket <BUCKET>
```

### Cost Explorer
```bash
aws ce get-cost-and-usage \
  --time-period Start=2026-04-01,End=2026-05-01 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=USAGE_TYPE \
  --filter '{"Dimensions": {"Key": "SERVICE", "Values": ["Amazon S3"]}}'
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Do this instead |
|---|---|---|
| No lifecycle policy | 70% overpayment | 30/90/365-day tier |
| Snapshot retention unbounded | Piles up | DLM + retention |
| gp2 still in use | 20% overpayment | Migrate to gp3 |
| Egress heavy through NAT | $$ | VPC Endpoints |
| Cross-AZ pod placement random | Inter-AZ traffic | Anti-affinity strategy |
| No backup retention / unbounded | Storage cost + KVKK (Turkey's Personal Data Protection Law, No. 6698) violation | Disciplined retention |
| No S3 versioning + lifecycle | Versions pile up | Lifecycle for versioned objects |
| No Custodian / cleanup automation | Manual neglect | Cron + script |
| Detached volume for months | Idle cost | Cleanup policy |
| Intelligent Tiering treated as mandatory | Tier fee isn't always minimal | Classic lifecycle is cheaper in some cases |

---

## 📋 Storage Cost Optimization Checklist

```
[ ] S3 lifecycle: 30/90/365-day tier
[ ] S3 Intelligent Tiering (large buckets)
[ ] S3 versioning lifecycle (old version cleanup)
[ ] EBS gp3 migration (from gp2)
[ ] EBS detached volume cleanup (Custodian)
[ ] EBS snapshot retention (DLM, 7-30 days)
[ ] Snapshot cleanup (90+ days old)
[ ] VPC Endpoints (S3, DynamoDB)
[ ] NAT Gateway minimize
[ ] CDN: static assets to the edge
[ ] Backup retention disciplined (3-2-1 + lifecycle)
[ ] Quarterly storage cost review
[ ] Per-bucket cost dashboard
[ ] Tag policy: cost-center per bucket
```

---

## 📚 References

- **AWS S3 Storage Classes** — aws.amazon.com/s3/storage-classes
- **AWS DLM** — aws.amazon.com/ebs/dlm
- **Cloud Custodian** — cloudcustodian.io
- **AWS Cost Explorer** — aws.amazon.com/aws-cost-management
- **VPC Endpoints** — docs.aws.amazon.com/vpc/latest/privatelink/
- [`Cloud-Cost-Allocation.md`](Cloud-Cost-Allocation.md)
- [`Right-Sizing.md`](Right-Sizing.md)
- [`Kubecost-Setup.md`](Kubecost-Setup.md)
- [`14-Sustainability/Efficiency-Practices.md`](../14-Sustainability/Efficiency-Practices.md)

---

> *"Storage cost is assumed to be 'small' — 6 months later it's **30% of the bill**.
> Lifecycle policy + cleanup automation = **free savings**,
> one week of implementation."*
