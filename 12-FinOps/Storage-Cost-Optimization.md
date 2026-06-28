---
description: "S3, EBS, snapshot ve backup icin storage maliyet optimizasyonu: lifecycle policy, tier transition, idle volume ve zombie snapshot temizligi ile somut tasarruf."
tags:
  - FinOps
  - Cost Optimization
  - AWS
  - Backup
  - Cost
---
# Storage Cost Optimization — S3, EBS, Snapshot, Backup

> *"S3 bill $20K/ay, %80'i 6 ay önceki log + zombie snapshot.
> Lifecycle policy + tier transition = aynı veri **%70 daha ucuz**.
> 4 saatlik iş, kalıcı $14K/ay tasarruf."*

Bu rehber S3 / EBS / snapshot / backup için cost optimization tekniklerini
somut komut + lifecycle policy ile anlatır.

---

## 🎯 Storage Cost Driver'ları

| Cost source | %  yaygın |
|---|---|
| **EBS volumes** (idle) | %20-40 |
| **EBS snapshots** (eski, kullanılmayan) | %15-30 |
| **S3 Standard** (eski log/file) | %20-40 |
| **NAT Gateway egress** | %10-25 |
| **Backup retention** (uncontrolled) | %15-30 |

---

## 🪣 1️⃣ S3 Lifecycle Policy

### Aşamalı tier
```yaml
LifecycleRules:
  - Filter: {Prefix: logs/}
    Transitions:
      - Days: 30
        StorageClass: STANDARD_IA      # %40 ucuz
      - Days: 90
        StorageClass: GLACIER          # %80 ucuz
      - Days: 365
        StorageClass: DEEP_ARCHIVE     # %95 ucuz
    Expiration: {Days: 2555}            # 7 yıl
```

### Cost karşılaştırma (ay başına 1 TB)
```
STANDARD:        $23
STANDARD_IA:     $12.5
GLACIER:         $4
GLACIER_IR:      $5      (instant retrieval)
DEEP_ARCHIVE:    $1
```

### Use case mapping
| Veri tipi | Recommended class |
|---|---|
| Active data | STANDARD |
| Eski log (30+ gün, ara sıra access) | STANDARD_IA |
| Compliance audit (1+ yıl) | GLACIER veya DEEP_ARCHIVE |
| Backup (1+ yıl) | GLACIER + Object Lock |

### Intelligent-Tiering
```yaml
StorageClass: INTELLIGENT_TIERING
```

→ AWS otomatik tier shift'ler (tier transition fee $0.0025/1K objects).

---

## 💾 2️⃣ EBS Optimization

### Idle volume detection
```bash
# Volume detached olan
aws ec2 describe-volumes \
  --filters "Name=status,Values=available" \
  --query 'Volumes[*].[VolumeId, Size, CreateTime]' \
  --output table

# Idle attached (CloudWatch read/write 0)
aws cloudwatch get-metric-statistics \
  --namespace AWS/EBS \
  --metric-name VolumeReadOps \
  --dimensions Name=VolumeId,Value=vol-xxx \
  --start-time $(date -d '14 days ago' +%FT%T) \
  --end-time $(date +%FT%T) \
  --period 86400 \
  --statistics Sum
```

### gp3 migration (gp2'den)
```bash
# gp2 → gp3: %20 ucuz + better IOPS
aws ec2 modify-volume \
  --volume-id vol-xxx \
  --volume-type gp3 \
  --iops 3000 --throughput 125
```

> 🔑 **gp3 default = gp2'den ucuz**. Migration kolay, instant.

### Right-sizing
- 100 GB volume, %30 kullanım → 50 GB shrink (tooling: shrink lvm/xfs/ext4)
- > %80 → büyüt (gp3 instant)

---

## 📸 3️⃣ Snapshot Cleanup

### Eski snapshot'lar
```bash
# 90+ gün eski
aws ec2 describe-snapshots --owner-ids self \
  --query 'Snapshots[?StartTime<=`2026-02-04`].[SnapshotId, StartTime, Description]' \
  --output table

# Otomatik delete (Cloud Custodian policy)
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
    RetainRule: {Count: 7}    # 7 gün tut
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

### Optimizasyon
1. **VPC Endpoints** (S3, DynamoDB için NAT bypass)
   ```bash
   aws ec2 create-vpc-endpoint \
     --vpc-id vpc-xxx \
     --service-name com.amazonaws.<REGION>.s3 \
     --route-table-ids rtb-xxx
   ```
   → S3 traffic NAT'ı bypass eder, **$0**.

2. **Cross-AZ traffic minimize**: pod anti-affinity, single-AZ for non-HA

3. **CDN**: edge cache → origin trafik %50+ azalır

---

## 📦 5️⃣ Backup Retention Discipline

### Kural
- **Production daily backup**: 30 gün
- **Weekly**: 12 hafta
- **Monthly**: 12 ay
- **Yearly (compliance)**: 7 yıl

### Otomatik cleanup
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

# Lifecycle policy var mı?
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

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Lifecycle policy yok | %70 fazla ödenir | 30/90/365 gün tier |
| Snapshot retention sonsuz | Birikir | DLM + retention |
| gp2 hâlâ kullanılır | %20 fazla | gp3 migrate |
| Egress yoğun NAT üzerinden | $$ | VPC Endpoints |
| Cross-AZ pod yerleştirme rastgele | Inter-AZ traffic | Anti-affinity stratejisi |
| Backup retention yok / sonsuz | Storage + KVKK ihlal | Disciplined retention |
| S3 versioning + lifecycle yok | Versions birikir | Lifecycle versioned objects için |
| Custodian / cleanup automation yok | Manuel ihmal | Cron + script |
| Detached volume aylarca | Idle pay | Cleanup policy |
| Intelligent Tiering şart | Tier fee minimal değil | Klasik lifecycle bazılarda daha ucuz |

---

## 📋 Storage Cost Optimization Checklist

```
[ ] S3 lifecycle: 30/90/365 gün tier
[ ] S3 Intelligent Tiering (büyük buckets)
[ ] S3 versioning lifecycle (eski versions cleanup)
[ ] EBS gp3 migration (gp2'den)
[ ] EBS detached volume cleanup (Custodian)
[ ] EBS snapshot retention (DLM, 7-30 gün)
[ ] Snapshot cleanup (90+ gün eski)
[ ] VPC Endpoints (S3, DynamoDB)
[ ] NAT Gateway minimize
[ ] CDN: static asset edge'e
[ ] Backup retention disciplined (3-2-1 + lifecycle)
[ ] Quarterly storage cost review
[ ] Per-bucket cost dashboard
[ ] Tag policy: cost-center per bucket
```

---

## 📚 Referanslar

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

> *"Storage cost 'küçük' sanılır — 6 ay sonra **bill'in %30'u**.
> Lifecycle policy + cleanup automation = **bedava tasarruf**,
> bir hafta implementation."*
