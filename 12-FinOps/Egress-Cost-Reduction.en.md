---
description: "Reducing egress cost on AWS, GCP, and Azure: turning a hidden bill line item into concrete savings with VPC Endpoints, CDN, peering, single-AZ, and NAT Gateway control."
tags:
  - FinOps
  - Cost Optimization
  - Networking
  - AWS
  - Cost
---
# Egress Cost Reduction — Controlling the Invisible Bill Line Item

> *"**Egress traffic** is 25-40% of the AWS bill. Most teams look at
> 'storage, compute' — and neglect egress. Cross-AZ traffic + NAT
> Gateway + internet egress = a monthly $$ drain."*

This guide covers techniques for reducing egress cost on AWS, GCP,
and Azure — VPC Endpoints, CDN, peering, single-AZ — with concrete
commands and savings.

---

## 💰 Egress Cost Drivers

### AWS example (eu-west-1)
| Traffic type | Price |
|---|---|
| EC2 → Internet | **$0.09/GB** (first 10TB) |
| NAT Gateway | $0.045/GB **+** $0.045/hour |
| Cross-region | $0.02/GB |
| **Cross-AZ** (intra-region) | **$0.01/GB** |
| S3 → EC2 (same region) | **$0** ✅ |
| S3 → Internet | $0.09/GB |
| CloudFront → User | $0.085/GB |
| Inter-region peering | $0.02/GB |

> 🔑 **NAT Gateway**: the sneakiest cost in the cluster. 1TB/month × $0.045 = $45 + $32/month (hourly). If every connection routes through NAT, it skyrockets.

---

## 🛠️ 1️⃣ VPC Endpoints (NAT Bypass)

### The Problem
```
Pod → NAT Gateway → S3
       ↑
       $0.045/GB fee
```

### Solution: Gateway Endpoint (free for S3, DynamoDB)
```bash
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxx \
  --service-name com.amazonaws.<REGION>.s3 \
  --route-table-ids rtb-xxx \
  --vpc-endpoint-type Gateway

aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxx \
  --service-name com.amazonaws.<REGION>.dynamodb \
  --route-table-ids rtb-xxx
```

→ S3 / DynamoDB traffic **bypasses NAT**. **$0/GB**.

### Interface Endpoint (other AWS services)
```bash
# ECR, KMS, Secrets Manager, SNS, SQS...
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxx \
  --service-name com.amazonaws.<REGION>.ecr.dkr \
  --vpc-endpoint-type Interface \
  --subnet-ids subnet-xxx subnet-yyy
```

→ Interface endpoint: $0.01/hour × N AZs + $0.01/GB. Cheaper than NAT.

### Savings Calculation
```
Scenario: 5TB/month S3 download + 2TB ECR image pull

Via NAT: 7000 × $0.045 = $315/month + hourly $32 = $347/month
VPC Endpoint: $0 (gateway) + $50 (interface ECR) = $50/month

Savings: $297/month × 12 = $3,564/year
```

---

## 🌐 2️⃣ CDN — Edge Cache

### Strategy
```
[User] → [CloudFront edge] → [Origin: S3 / ALB]
              │
              ├── Cache hit (80%+) → $0 origin
              └── Cache miss (20%) → origin
```

### CloudFront pricing
- Edge → User: $0.085/GB (S3 direct $0.09 → slightly cheaper)
- Origin → CloudFront: free (with origin shield)
- **Real savings**: 80% cache hit → no origin egress

### Cache headers
```http
Cache-Control: public, max-age=86400, s-maxage=604800, immutable
```

```
public:        CDN cache OK
max-age=86400: client 1 day
s-maxage:      CDN 7 days
immutable:     never-changing (for assets)
```

### Use case
- Static asset (JS, CSS, image) → CDN
- API responses (read-heavy, with TTL)
- Video / HLS streaming
- Image hosting

> 🔑 **B2C app**: without a CDN, **50%+ more** egress.

---

## 🏛️ 3️⃣ Minimize Cross-AZ Traffic

### The Problem
```
Pod A (AZ-1) → Pod B (AZ-2)  → $0.01/GB inter-AZ
                  ↑
                  Lots of pod-pod traffic = $$$
```

### Solution 1: Single-AZ Deploy (when HA isn't needed)
```yaml
spec:
  affinity:
    podAffinity:   # place in the same AZ
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels: {app: payments}
          topologyKey: topology.kubernetes.io/zone
```

> ⚠️ **Trade-off**: Single-AZ → AZ down = full outage. Only for dev/staging or non-critical batch jobs.

### Solution 2: Topology-Aware Hints (K8s 1.23+)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: payments
  annotations:
    service.kubernetes.io/topology-aware-hints: "Auto"
spec:
  selector: {app: payments}
  ports: [...]
```

→ K8s prefers routing service traffic to a **same-AZ pod**.

### Solution 3: Karpenter Zone-Balanced
```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
spec:
  template:
    spec:
      requirements:
        - key: topology.kubernetes.io/zone
          operator: In
          values: [us-west-2a, us-west-2b, us-west-2c]
```

→ Distribute pods evenly across AZs → minimize cross-AZ traffic.

---

## 🔗 4️⃣ Direct Connect / VPC Peering

### Direct Connect (on-prem ↔ AWS)
- Not over the internet — **dedicated** fiber
- Egress: $0.02/GB (cheaper than internet's $0.09)
- Setup: $50-300/hour dedicated link
- ROI: break-even at > 5TB/month traffic

### VPC Peering (AWS ↔ AWS)
- Cross-VPC traffic: $0.01/GB
- Traffic that never touches the internet
- Critical in multi-account architectures

### Transit Gateway
- Hub-and-spoke peering
- $0.05/hour + $0.02/GB
- Managed for 50+ VPC architectures

---

## 🌍 5️⃣ Cross-Region Traffic

### The Most Expensive Pattern
```
US-East  ←→  EU-West (cross-region replication)
$0.02/GB
1TB replication = $20/month (one direction)
```

### Optimization
- **Compress** the data (gzip)
- **Filter** (only what's needed)
- **Async replication** + delta only

---

## 📊 Egress Audit

### AWS Cost Explorer
```bash
aws ce get-cost-and-usage \
  --time-period Start=2026-04-01,End=2026-05-01 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --filter '{"Dimensions": {"Key": "USAGE_TYPE", "Values": ["DataTransfer-Out-Bytes"]}}' \
  --group-by Type=DIMENSION,Key=USAGE_TYPE
```

### VPC Flow Logs Analysis
```sql
-- Athena: top egress destinations
SELECT
  dstaddr,
  SUM(bytes) / 1e9 AS gb_transferred
FROM vpc_flow_logs
WHERE flow_direction = 'egress'
  AND date >= date '2026-04-01'
GROUP BY dstaddr
ORDER BY gb_transferred DESC
LIMIT 20;
```

---

## 🎯 Quick Wins Roadmap

### Week 1: VPC Endpoints
- S3 + DynamoDB Gateway endpoint (free)
- ECR Interface endpoint
- **Savings: $300-500/month** (for 1TB+ S3 traffic)

### Week 2: CloudFront
- Static asset cache
- API response cache (with TTL)
- **Savings: 30-50% origin egress**

### Weeks 3-4: Cross-AZ Audit
- Service topology hints
- Karpenter zone-balanced
- Database replica same-AZ as app
- **Savings: 20-40% cross-AZ traffic**

### Months 2-3: Strategic
- Optimize multi-region traffic
- Direct Connect (on-prem ROI)
- Compress all egress

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Do this instead |
|---|---|---|
| No VPC Endpoint for S3 | NAT $$$$ | Gateway endpoint (free) |
| No CDN for a B2C app | Origin overload | CloudFront/Cloudflare |
| Cross-AZ placement left to chance | Inter-AZ traffic | Topology hints |
| Uncompressed cross-region replication | 5x bandwidth | gzip + delta |
| Public S3 + internet pull | $0.09/GB | Same-region private |
| API gateway → backend cross-AZ on every request | Latency + cost | Same-AZ deployment |
| No egress tracking | Bill surprise | Quarterly audit |
| Container image pulled from Docker Hub every time | Rate limit + egress | ECR mirror |
| External logs (Datadog) shipping all logs | $$$$ egress | Sample + filter |
| SSH/management to a public IP | Internet egress | Bastion VPN |

---

## 📋 Egress Optimization Checklist

```
[ ] VPC Gateway Endpoint: S3, DynamoDB
[ ] VPC Interface Endpoint: ECR, KMS, Secrets Manager
[ ] CloudFront / Cloudflare CDN (B2C)
[ ] Cache-Control headers (immutable, max-age)
[ ] Topology-aware hints (K8s service)
[ ] Karpenter zone-balanced NodePool
[ ] Cross-region: gzip + delta replication
[ ] VPC Flow Logs → Athena analysis
[ ] Quarterly: top egress destination review
[ ] Bastion / VPN (instead of SSH)
[ ] Container registry mirror (Docker Hub rate limit)
[ ] External logging: sample policy
[ ] Direct Connect (on-prem 5TB+ traffic)
[ ] Cost alarm: NAT Gateway > $X/month
```

---

## 📚 References

- **AWS Data Transfer Pricing** — aws.amazon.com/ec2/pricing/on-demand/
- **AWS VPC Endpoints** — docs.aws.amazon.com/vpc/latest/privatelink/
- **CloudFront Pricing** — aws.amazon.com/cloudfront/pricing/
- **K8s Topology Aware Hints** — kubernetes.io/docs/concepts/services-networking/topology-aware-routing/
- [`Cloud-Cost-Allocation.md`](Cloud-Cost-Allocation.md)
- [`Storage-Cost-Optimization.md`](Storage-Cost-Optimization.md)
- [`Right-Sizing.md`](Right-Sizing.md)
- [`09-Networking/DNS-Strategies.md`](../09-Networking/DNS-Strategies.md)
- [`14-Sustainability/Efficiency-Practices.md`](../14-Sustainability/Efficiency-Practices.md)

---

> *"Egress is the **invisible 25-40%** of the AWS bill. VPC Endpoint +
> CDN + topology-aware = **2 weeks of implementation**, **lasting
> $X/month** in savings."*
