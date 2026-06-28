---
description: "Cloud faturasini anlamlandirma: kim ne icin harcadi sorusuna cevap; tagging stratejisi, showback, chargeback ve anomaly detection ile maliyet allocation."
tags:
  - FinOps
  - Cost Optimization
  - AWS
  - Cost
---
# Cloud Cost Allocation — Faturayı Anlamak

> *"Bu ay AWS faturası $42,318. Ne için? Bilmiyorum. Hangi takım yaktı?
> Bilmiyorum. Optimize edebileceğimiz yer? Bilmiyorum."*
> Bu sorulara saatler içinde cevap verebilen ekiplerin maliyeti **2 yıl
> içinde %30-50 düşüyor.**

---

## 📐 Hedef

Her dolar (TL/EUR) için: **kim, ne için harcadı?**

3 nokta:
1. **Showback** — her ekip kendi maliyetini görür (peer pressure)
2. **Chargeback** — finans ekibe dahili fatura keser (gerçek hesap)
3. **Anomaly detection** — ay sonunu beklemeden sürpriz yakala

---

## 🏷️ 1. Tagging Strategy (Foundation)

Tagging eksikse hiçbir allocation çalışmaz. **Önce buna yatır.**

### Zorunlu tag set

| Tag | Örnek | Niye |
|---|---|---|
| `Environment` | `prod`, `staging`, `dev` | Maliyet ayrımı |
| `Team` | `payments`, `growth`, `platform` | Ownership |
| `Service` | `api`, `worker`, `db` | Workload-level |
| `CostCenter` | `eng-1234` | Finans entegrasyonu |
| `ManagedBy` | `terraform`, `helm`, `manual` | Drift detection |
| `Owner` | `<TEAM_HANDLE>` | Sorumluluk |
| `Project` (opsiyonel) | `mobile-revamp` | Initiative tracking |

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
    error_message = "Tags Environment, Team, CostCenter zorunludur."
  }
}
```

**3️⃣ Kyverno (Kubernetes)**

```yaml
# 17-Templates/kyverno-policies/require-labels.yaml içinde
```

**4️⃣ AWS Config Rules** — `required-tags` rule, non-compliant resource'ları otomatik raporla.

### Mevcut resource'ların retro-tag'lenmesi

```bash
# AWS Resource Groups Tagging API ile bulk tag
aws resourcegroupstaggingapi tag-resources \
  --resource-arn-list arn:aws:s3:::bucket1 arn:aws:s3:::bucket2 \
  --tags Environment=prod,Team=platform,CostCenter=eng-1001
```

> 💡 **İpucu:** Untagged resource raporu haftalık. 4 hafta üst üste
> untagged kalanlar **otomatik durdurulur** (Lambda + scheduled).

---

## 📊 2. Allocation Reports

### A. AWS Cost Explorer (built-in)

```bash
# Bu ay servis bazında
aws ce get-cost-and-usage \
  --time-period Start=$(date -d 'first day of month' +%F),End=$(date +%F) \
  --granularity DAILY \
  --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Tag bazında (Team = payments)
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '30 days ago' +%F),End=$(date +%F) \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --filter '{"Tags":{"Key":"Team","Values":["payments"]}}'

# Tag breakdown ile group-by
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '30 days ago' +%F),End=$(date +%F) \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=TAG,Key=Team
```

### B. Cost & Usage Report (CUR) → Athena

CUR detaylı (her resource her saat) ama büyük. Athena ile sorgula:

```sql
-- Top 20 service by cost (son 7 gün)
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

-- Untagged resource'lar (kayıp para)
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

Kubernetes maliyet attribution için (cloud bill K8s-native değil):

```bash
# OpenCost (CNCF, OSS)
helm install opencost opencost/opencost -n opencost --create-namespace

# Kubecost (OpenCost'un üst seti, UI dahil)
helm install kubecost \
  --repo https://kubecost.github.io/cost-analyzer \
  cost-analyzer \
  -n kubecost \
  --create-namespace
```

Bu tool'lar:
- Pod başına compute/memory cost
- Namespace breakdown
- Workload (deployment) breakdown
- PVC cost
- Idle resource (request edildi ama kullanılmadı) — **gizli israf**

```bash
# CLI ile (Kubecost API)
curl http://kubecost.kubecost:9090/model/allocation \
  --data-urlencode 'window=7d' \
  --data-urlencode 'aggregate=namespace' \
  --data-urlencode 'accumulate=true' | jq
```

---

## 💸 3. Showback / Chargeback Modeli

### Showback (önerilen başlangıç)

Her ekip kendi maliyetini **görür**, finans hareketi yok.

**Aylık dashboard / e-mail:**

```
┌────────────────────────────────────────────────┐
│  Team: payments                                 │
│  Period: Mart 2026                              │
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
│  vs budget:     ($5,000 budget, %96 of budget)   │
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

### Chargeback (büyük org'lar)

Finans her ekibe iç fatura keser. Engineering bütçesi gerçek = team cost.

**Avantajı:** maliyet bilinci max
**Dezavantajı:** bürokratik, küçük org'larda overkill

---

## 🚨 4. Anomaly Detection

Ay sonu sürpriz patlamayı önler.

### AWS Cost Anomaly Detection (built-in)

```bash
# Monitor oluştur (her servis için günlük anomaly takibi)
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

### Custom (daha hassas) — Athena + cron

```sql
-- Yesterday vs 7-day average, sapma > %30
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

Sonucu Slack'e at:
```
🚨 Cost anomaly detected:
- payments / RDS: $250 yesterday (avg $80, +212%)
- growth / DataTransfer: $890 yesterday (avg $300, +197%)
```

---

## 🎯 5. Quick Wins (ilk 30 günde %15-30 tasarruf)

```bash
# 1. Idle EC2 (stopped > 30 gün)
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=stopped" \
  --query 'Reservations[].Instances[?StateTransitionReason!=null && StateTransitionReason<`'$(date -d '30 days ago' +%F)'`]'

# 2. Boşta Elastic IP (her biri ~$3.6/ay)
aws ec2 describe-addresses \
  --query 'Addresses[?AssociationId==null].[PublicIp,AllocationId]'

# 3. Kullanılmayan EBS volume
aws ec2 describe-volumes --filters Name=status,Values=available

# 4. EBS gp2 → gp3 (aynı performans, %20 ucuz)
aws ec2 describe-volumes \
  --filters Name=volume-type,Values=gp2 \
  --query 'Volumes[].VolumeId' --output text \
  | xargs -n 1 aws ec2 modify-volume --volume-type gp3 --volume-id

# 5. Eski snapshot'lar
aws ec2 describe-snapshots --owner-ids self \
  --query "Snapshots[?StartTime<='$(date -d '90 days ago' +%F)'].SnapshotId" \
  --output text | xargs -n1 aws ec2 delete-snapshot --snapshot-id

# 6. RDS public access (yanlış config + maliyet)
aws rds describe-db-instances \
  --query 'DBInstances[?PubliclyAccessible==`true`].[DBInstanceIdentifier]'

# 7. Boşta Load Balancer
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

### Egress (gizli en büyük gider)

> AWS data transfer OUT $0.09/GB. 1 TB/ay = $90. 50 TB/ay = $4,500.
> Kontrol etmediğin sürece **kontrolsüz büyür.**

- ✅ Aynı region içinde S3 → EC2: ücretsiz
- ✅ VPC Endpoint (S3/DynamoDB): NAT GW egress'i ortadan kaldırır
- ✅ CloudFront / CDN: kullanıcıya yakın cache
- ✅ Cloudflare R2 — egress ücreti yok
- ❌ Cross-AZ aynı region (bilemem ama olur, $0.01/GB ekler)
- ❌ Cross-region (en pahalı)

---

## 📈 6. Reserved Instances / Savings Plans

Düzenli kullanılan baseline kapasiteyi commit ile satın al:

| Strateji | Discount | Risk |
|---|---|---|
| **3-year all-upfront RI** | %72'ye kadar | Yüksek (esneklik yok) |
| **1-year SP (Compute)** | %30-50 | Orta (instance type değiştirilebilir) |
| **3-year SP (Compute)** | %50-65 | Yüksek |
| **Spot** | %50-90 | Yüksek (interruption) |

### Strateji önerisi

```
Baseline (24/7 sürekli)         → SP 1-year compute
Stable, tip değişmeyecek         → RI 1-year
Burst / batch / fault-tolerant   → Spot
Dev/test                         → Spot (auto-pause overnight)
```

> ⚠️ **Commit cliff**: 1-year SP'in expiration tarihi yaklaşırken 60 gün
> önce alarm. Yeniden alma planı yap. Cliff'e çarpıp $$$ patlamak yaygın hata.

---

## 🛠️ 7. PR-time Cost Diff (Infracost)

Terraform değişiklik PR'larında, merge öncesi maliyet diff:

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

PR'da otomatik comment:
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

Maliyet allocation'da en sık görülen ve faturayı kör eden hatalar:

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tag enforcement olmadan allocation başlatmak | Untagged resource = atfedilemeyen para; rapor delik dolu çıkar | Önce SCP/Config/Kyverno ile zorunlu tag, sonra rapor |
| Sadece toplam faturaya bakmak | Hangi ekip/servis yaktı görünmez, optimizasyon kör | Team + Service tag bazında breakdown çek |
| Ay sonunu bekleyip faturaya bakmak | Sürpriz patlama; sapma 30 gün boyunca büyür | Günlük anomaly detection (Cost Anomaly veya Athena cron) |
| Cost Explorer ile resource-seviye analiz | CE aggregate; tek resource'u izleyemezsin | Resource-seviye için CUR → Athena kullan |
| Kubernetes maliyetini cloud bill'den okumak | Bill node bazlı; pod/namespace attribution yok | OpenCost/Kubecost ile pod-seviye allocation |
| Egress maliyetini görmezden gelmek | Kontrolsüz büyür ($0.09/GB); en büyük gizli gider | VPC Endpoint + CDN + cross-region trafiği izle |
| Hemen 3-yıl all-upfront RI almak | Esneklik sıfır; instance tipi değişince para çöp | Önce 1-year SP, kullanım oturunca uzun commit |
| SP/RI expiration'ı takip etmemek | Commit cliff'e çarpıp on-demand fiyata düşmek | Bitişten 60 gün önce alarm + yenileme planı |
| Idle resource'u (boş EIP/EBS/LB) bırakmak | Kullanılmadan fatura yazar; ay ay birikir | Haftalık idle taraması + otomatik temizlik |
| Maliyeti merkezi tek ekibe yıkmak (showback yok) | Kimse kendi tüketimini görmez, sorumluluk yok | Showback dashboard; her ekip kendi maliyetini görür |
| Maliyet diff'ini merge sonrası fark etmek | Pahalı kaynak prod'a sızar, geri almak zor | PR-time Infracost diff ile merge öncesi gör |

---

## 📋 Checklist

Production-ready cost allocation için somut maddeler:

**Tagging foundation**
- [ ] Zorunlu tag set tanımlı (`Environment`, `Team`, `Service`, `CostCenter`, `ManagedBy`, `Owner`)
- [ ] SCP ile tag'siz resource oluşturma engelleniyor (org-level)
- [ ] Terraform `required-tags` modülü tüm modüllerde kullanımda
- [ ] Kyverno/AWS Config ile K8s + AWS tag compliance denetimi aktif
- [ ] Mevcut (legacy) resource'lar retro-tag'lendi
- [ ] Haftalık untagged raporu otomatik; 4 hafta üst üste untagged kalan durduruluyor

**Reporting**
- [ ] CUR aktif ve Athena'ya bağlı (resource-seviye sorgu mümkün)
- [ ] Team bazlı breakdown raporu çalışıyor
- [ ] Untagged-cost raporu izleniyor (kayıp para görünür)
- [ ] Kubernetes için OpenCost/Kubecost kurulu (pod/namespace allocation)

**Showback / Chargeback**
- [ ] Her ekibe aylık showback dashboard/e-mail gidiyor
- [ ] Bütçe vs gerçek karşılaştırması raporda var
- [ ] (Büyük org) Chargeback iç fatura akışı finansla entegre

**Anomaly & alarm**
- [ ] AWS Cost Anomaly Detection monitor + subscription aktif
- [ ] Günlük sapma sorgusu (>%30) Slack/e-mail'e düşüyor
- [ ] Alarm subscriber ARN/endpoint `<PLACEHOLDER>` ile parametrize, hardcode kredensiyal yok

**Optimizasyon**
- [ ] Idle EC2/EBS/EIP/LB haftalık taranıyor
- [ ] gp2→gp3 ve eski snapshot temizliği planlı
- [ ] Egress (data transfer) izleniyor; VPC Endpoint/CDN devrede
- [ ] RI/SP stratejisi baseline'a göre belirli; expiration'a 60 gün alarm
- [ ] PR-time Infracost diff CI'da çalışıyor

---

## 📚 Devamı

- [FinOps Foundation](https://www.finops.org)
- [FOCUS specification](https://focus.finops.org) — vendor-neutral cost spec
- [AWS Well-Architected — Cost Optimization Pillar](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/)
- [OpenCost docs](https://www.opencost.io)
- _Right Sizing → 12-FinOps/Right-Sizing.md_ *(yakında)*
