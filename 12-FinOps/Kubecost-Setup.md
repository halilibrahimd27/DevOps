---
description: "Kubecost ile Kubernetes cost visibility: per-namespace, workload ve label bazli dollar maliyet dashboard, allocation modeli, alert ve OpenCost alternatifi."
tags:
  - FinOps
  - Cost Optimization
  - Kubernetes
  - Observability
  - Cost
---
# Kubecost Setup — K8s Cost Visibility

> *"K8s cluster $80K/ay maliyet, 'kim kullanıyor?' bilen yok.
> Namespace'lere fatura kesemeyen ekip, **maliyet sahipsiz**.
> Kubecost = K8s için **per-namespace cost dashboard**."*

Bu rehber Kubecost'u kurma, allocation modeli, alert setup, Sustainability
entegrasyonu, ve OpenCost (CNCF) alternatif anlatır.

---

## 🎯 Kubecost Nedir?

> **Kubecost**: Kubernetes cluster'ında her resource'un (pod, namespace,
> deployment, label) **dollar maliyetini** real-time gösterir.

```
Cloud bill: $80K/ay
   │
   ▼ Kubecost allocation
   │
   ├── namespace=payments     $32K/ay (40%)
   ├── namespace=catalog      $20K/ay (25%)
   ├── namespace=monitoring   $8K/ay  (10%)
   ├── ...
   └── shared (kube-system)   $4K/ay  (5%)
```

---

## 🚀 Kurulum

### Helm install
```bash
helm install kubecost kubecost/cost-analyzer \
  -n kubecost --create-namespace \
  --set kubecostToken="<TOKEN>" \
  --set prometheus.server.persistentVolume.enabled=true
```

### Cloud integration (gerçek bill)
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

→ Kubecost AWS Cost & Usage Report'tan gerçek bill çeker.

---

## 📊 Allocation Model

### Aggregation
- **Namespace**: per-team
- **Deployment**: per-service
- **Label**: `team`, `cost-center` label'lı pod'lar
- **Annotation**: custom

### Idle costs
- Cluster'ın boş kısmı: kim ödüyor?
- Default: **proportionally** dağıt (her tenant payına düşen)
- Alternatif: shared `_unallocated` namespace

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
    Estimated saving: $400/ay

  Total potential saving: $12,000/ay (15% cluster)
```

### Cluster Comparison
- Multi-cluster: hangi cluster en pahalı, niye?
- Region cost karşılaştırması

---

## 🚨 Alarmlar

```yaml
# values.yaml
notifications:
  alertConfigs:
    enabled: true
    alerts:
      - type: budget
        threshold: 10000   # $10K/ay üstü
        window: 7d
        aggregation: namespace
        filter: payments
        slackWebhookUrl: <WEBHOOK>

      - type: efficiency
        efficiencyThreshold: 0.4   # %40 verim altı
        spendThreshold: 1000
        aggregation: deployment
```

→ Slack alarm: "Payments namespace 7-gün $12K, bütçeyi aştı".

---

## 📈 Per-PR Cost Diff (CI'da)

> PR'da "bu deploy ne kadar ekstra maliyet getirir" gösterimi.

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
  CPU: +200m → +$15/ay
  Memory: +512Mi → +$6/ay
  Total: +$21/ay (+%2.3)
```

> Detay: [`PR-Cost-Diff.md`](PR-Cost-Diff.md).

---

## 🌱 Sustainability — Karbon Tahmini

```yaml
# Carbon estimation
sustainability:
  carbon:
    enabled: true
    region: eu-west-1
```

→ Per-namespace **CO₂ emission** tahmini (Cloud Carbon Footprint integration).

---

## ⚖️ Kubecost vs OpenCost

| Boyut | Kubecost | OpenCost |
|---|---|---|
| **License** | Free + paid tiers | Apache 2 (CNCF) |
| **Topluluk** | Kubecost Inc | CNCF, broader |
| **Features** | Daha çok (UI, alerts, multi-cluster) | Core engine |
| **Cloud integration** | Native | Manuel |
| **Kullanım** | UI-driven | API + custom dashboard |

> 🔑 **Kubecost** = OpenCost engine + UI + premium features. **2026 önerisi**: Kubecost free tier yeterli çoğu için.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Cost transparency yok | "Kim ne harcıyor?" cevapsız | Kubecost / OpenCost |
| Tüm cluster maliyeti shared | Allocation yok | Namespace + label |
| Idle cost merkezi havuzda | Team'lere bedava | Proportional dağıt |
| Cost alert yok | Bütçe sürprizi | Per-team threshold |
| Right-sizing recommendation ignore | İsraf | Quarterly review |
| PR cost diff yok | Dev cost-blind | CI integration |
| Cloud bill + Kubecost senkron değil | Tahmin yanlış | CUR / Billing API integrate |
| Multi-cluster cost yok | Karşılaştırma imkansız | Multi-cluster Kubecost |

---

## 📋 Kubecost Production Checklist

```
[ ] Kubecost / OpenCost deploy
[ ] Cloud billing integration (CUR / Billing Export)
[ ] Allocation: namespace + label (team / cost-center)
[ ] Idle cost: proportional dağıt
[ ] Right-sizing recommendation review (quarterly)
[ ] Slack alarm: per-team budget threshold
[ ] PR cost diff CI'da
[ ] Sustainability/carbon integration
[ ] Multi-cluster (varsa) tek dashboard
[ ] Quarterly cost report yöneticilere
[ ] Per-team cost dashboard self-service
[ ] Annual: cost optimization roadmap
```

---

## 📚 Referanslar

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

> *"Kubecost 'opsiyonel finans tool' değil — **K8s'in maliyet
> görüntüsü**. 'Hangi namespace kaç para?' cevabı 5 dakikada
> verilemiyorsa, **sahipsiz cost** birikiyor."*
