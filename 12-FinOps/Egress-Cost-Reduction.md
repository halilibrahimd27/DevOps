# Egress Cost Reduction — Görünmez Bill Kaleminin Kontrolü

> *"AWS bill'inin %25-40'ı **egress traffic**. Çoğu ekip 'storage,
> compute' bakar — egress'i ihmal eder. Cross-AZ traffic + NAT
> Gateway + internet egress = aylık $$ kaynağı."*

Bu rehber AWS, GCP, Azure'da egress maliyetini azaltma tekniklerini —
VPC Endpoints, CDN, peering, single-AZ — somut komut + tasarruf
ile anlatır.

---

## 💰 Egress Cost Driver'ları

### AWS örneği (eu-west-1)
| Trafik tipi | Fiyat |
|---|---|
| EC2 → Internet | **$0.09/GB** (ilk 10TB) |
| NAT Gateway | $0.045/GB **+** $0.045/saat |
| Cross-region | $0.02/GB |
| **Cross-AZ** (intra-region) | **$0.01/GB** |
| S3 → EC2 (same region) | **$0** ✅ |
| S3 → Internet | $0.09/GB |
| CloudFront → User | $0.085/GB |
| Inter-region peering | $0.02/GB |

> 🔑 **NAT Gateway**: cluster'ın en sinsi cost'u. 1TB/ay × $0.045 = $45 + $32/ay (saatlik). Her bağlantı NAT'tan geçerse skyrocket.

---

## 🛠️ 1️⃣ VPC Endpoints (NAT Bypass)

### Sorun
```
Pod → NAT Gateway → S3
       ↑
       $0.045/GB pay
```

### Çözüm: Gateway Endpoint (S3, DynamoDB için ücretsiz)
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

→ S3 / DynamoDB trafiği **NAT'ı bypass** eder. **$0/GB**.

### Interface Endpoint (diğer AWS servisleri)
```bash
# ECR, KMS, Secrets Manager, SNS, SQS...
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxx \
  --service-name com.amazonaws.<REGION>.ecr.dkr \
  --vpc-endpoint-type Interface \
  --subnet-ids subnet-xxx subnet-yyy
```

→ Interface endpoint $0.01/saat × N AZ + $0.01/GB. NAT'tan ucuz.

### Tasarruf hesabı
```
Senaryo: 5TB/ay S3 download + 2TB ECR image pull

NAT yoluyla: 7000 × $0.045 = $315/ay + saatlik $32 = $347/ay
VPC Endpoint: $0 (gateway) + $50 (interface ECR) = $50/ay

Tasarruf: $297/ay × 12 = $3,564/yıl
```

---

## 🌐 2️⃣ CDN — Edge Cache

### Strateji
```
[User] → [CloudFront edge] → [Origin: S3 / ALB]
              │
              ├── Cache hit (%80+) → $0 origin
              └── Cache miss (%20) → origin
```

### CloudFront pricing
- Edge → User: $0.085/GB (S3 direct $0.09 → biraz ucuz)
- Origin → CloudFront: ücretsiz (origin shield ile)
- **Asıl tasarruf**: %80 cache hit → origin egress yok

### Cache headers
```http
Cache-Control: public, max-age=86400, s-maxage=604800, immutable
```

```
public:        CDN cache OK
max-age=86400: client 1 gün
s-maxage:      CDN 7 gün
immutable:     never-changing (asset'lerde)
```

### Use case
- Static asset (JS, CSS, image) → CDN
- API responses (read-heavy, TTL'li)
- Video / HLS streaming
- Image hosting

> 🔑 **B2C app**: CDN olmadan **%50+ fazla** egress.

---

## 🏛️ 3️⃣ Cross-AZ Traffic Minimize

### Sorun
```
Pod A (AZ-1) → Pod B (AZ-2)  → $0.01/GB inter-AZ
                  ↑
                  Çok pod-pod traffic = $$$
```

### Çözüm 1: Single-AZ deploy (HA gerekmiyorsa)
```yaml
spec:
  affinity:
    podAffinity:   # aynı AZ'ye yerleştir
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels: {app: payments}
          topologyKey: topology.kubernetes.io/zone
```

> ⚠️ **Trade-off**: Single-AZ → AZ down = full outage. Sadece dev/staging veya non-critical batch için.

### Çözüm 2: Topology-Aware Hints (K8s 1.23+)
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

→ K8s service traffic'i **same-AZ pod'a** yönlendirmeyi tercih eder.

### Çözüm 3: Karpenter zone-balanced
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

→ Pod'ları AZ'larda dengeli dağıt → cross-AZ minimize.

---

## 🔗 4️⃣ Direct Connect / VPC Peering

### Direct Connect (on-prem ↔ AWS)
- Internet üzerinden değil, **dedicated** fiber
- Egress: $0.02/GB (Internet $0.09'dan ucuz)
- Setup: $50-300/saat dedicated link
- ROI: > 5TB/ay traffic için break-even

### VPC Peering (AWS ↔ AWS)
- Cross-VPC traffic: $0.01/GB
- Internet'e gitmeyen traffic
- Multi-account architecture'larda kritik

### Transit Gateway
- Hub-and-spoke peering
- $0.05/saat + $0.02/GB
- 50+ VPC mimarilerde managed

---

## 🌍 5️⃣ Cross-Region Traffic

### En pahalı pattern
```
US-East  ←→  EU-West (cross-region replication)
$0.02/GB
1TB replication = $20/ay (1 yön)
```

### Optimizasyon
- **Compress** verileri (gzip)
- **Filter** (sadece gereken)
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

### VPC Flow Logs analiz
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

### Hafta 1: VPC Endpoints
- S3 + DynamoDB Gateway endpoint (ücretsiz)
- ECR Interface endpoint
- **Tasarruf: $300-500/ay** (1TB+ S3 traffic'li)

### Hafta 2: CloudFront
- Static asset cache
- API response cache (TTL'li)
- **Tasarruf: %30-50 origin egress**

### Hafta 3-4: Cross-AZ Audit
- Service topology hints
- Karpenter zone-balanced
- Database replica same-AZ as app
- **Tasarruf: %20-40 cross-AZ traffic**

### Ay 2-3: Strategic
- Multi-region traffic optimize
- Direct Connect (on-prem ROI)
- Compression all egress

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| VPC Endpoint yok S3'e | NAT $$$$ | Gateway endpoint (ücretsiz) |
| CDN yok B2C app | Origin overload | CloudFront/Cloudflare |
| Cross-AZ rastgele | Inter-AZ traffic | Topology hints |
| Cross-region replication uncompressed | 5x bandwidth | gzip + delta |
| Public S3 + Internet pull | $0.09/GB | Same-region private |
| API gateway → backend cross-AZ her request | Latency + cost | Same-AZ deployment |
| Egress tracking yok | Bill sürpriz | Quarterly audit |
| Container image her seferinde Docker Hub'dan | Rate limit + egress | ECR mirror |
| External logs (Datadog) tüm log | $$$$ egress | Sample + filter |
| Public IP'ye SSH/management | Internet egress | Bastion VPN |

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
[ ] VPC Flow Logs → Athena analiz
[ ] Quarterly: top egress destination review
[ ] Bastion / VPN (SSH yerine)
[ ] Container registry mirror (Docker Hub rate limit)
[ ] External logging: sample policy
[ ] Direct Connect (on-prem 5TB+ traffic)
[ ] Cost alarm: NAT Gateway > $X/ay
```

---

## 📚 Referanslar

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

> *"Egress, AWS bill'in **görünmez %25-40**'ı. VPC Endpoint + CDN +
> topology-aware = **2 hafta implementation**, **kalıcı $X/ay**
> tasarruf."*
