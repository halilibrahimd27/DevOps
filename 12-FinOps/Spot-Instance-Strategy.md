---
description: "AWS Spot, GCP Preemptible ve Azure Spot ile %70 tasarruf: uygun workload secimi, graceful interruption handling ve Karpenter ile mixed fleet stratejisi."
tags:
  - FinOps
  - Cost Optimization
  - AWS
  - Kubernetes
  - Cost
---
# Spot Instance Strategy — %70 Tasarruf

> *"Spot %70 daha ucuz — 'ama interrupt edilebilir' diye kullanmayan
> ekip, **aylık $5K-50K** boş para harcıyor. Doğru workload + doğru
> tooling = spot %30+ adoption."*

Bu rehber AWS Spot, GCP Preemptible, Azure Spot için workload uygunluk,
graceful interruption handling, ve Karpenter ile mixed fleet stratejisini anlatır.

---

## 🎯 Spot Nedir?

> **Spot/Preemptible**: Cloud sağlayıcının **idle kapasite**si.
> %70-90 daha ucuz; ama **2 dakika öncesinden** interruption notice
> ile kapatılabilir.

| Cloud | Spot | İndirim |
|---|---|---|
| AWS | Spot Instance | %70-90 |
| GCP | Preemptible / Spot VM | %60-91 |
| Azure | Spot VM | %50-90 |

---

## ✅ Uygun Workload'lar

| Workload | Spot uygunluk |
|---|---|
| **Stateless API** (HTTP) | ✅ replica > 1 + LB |
| **CI runner** | ✅ ephemeral |
| **ML training (batch)** | ✅✅ checkpointing varsa |
| **Data ETL** | ✅ idempotent |
| **Background queue worker** | ✅✅ retry varsa |
| **Render farm** | ✅ |
| **Dev / staging** | ✅✅ |
| **Cache (Redis primary)** | ❌ state |
| **Database primary** | ❌ data loss |
| **Stateful kafka** | ⚠️ replica varsa OK |
| **Real-time critical** | ❌ interrupt etki |

> 🔑 **Genel kural**: Stateless + replica > 1 + retry varsa **spot OK**.

---

## 🚀 AWS Spot Best Practices

### EC2 Spot
```bash
# Mixed instance type (interruption riski azaltır)
aws ec2 run-instances \
  --instance-market-options 'MarketType=spot,SpotOptions={SpotInstanceType=one-time}' \
  --image-id ami-xxx \
  --instance-type m5.large
```

### EKS Spot Node Group
```bash
eksctl create nodegroup --config-file=- <<EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: prod
managedNodeGroups:
  - name: spot
    instanceTypes: [m5.large, m5a.large, m5n.large, m4.large]   # diversify
    spot: true
    minSize: 2
    maxSize: 20
    labels: {capacity-type: spot}
    taints:
      - key: capacity-type
        value: spot
        effect: NoSchedule
EOF
```

### Karpenter (önerilen)
```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: spot-pool
spec:
  template:
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: [spot]
        - key: karpenter.k8s.aws/instance-family
          operator: In
          values: [m5, m5a, m5n, m6i, m7i]   # diversify
        - key: kubernetes.io/arch
          operator: In
          values: [amd64, arm64]
  limits:
    cpu: "1000"
  disruption:
    consolidationPolicy: WhenEmpty
    expireAfter: 720h   # 30 gün max lifetime
```

> 🔑 Karpenter spot interruption signal'lerini handle eder, otomatik node replace.

---

## 🛡️ Graceful Interruption Handling

### Interruption notice
- AWS: **2 dakika** öncesi signal (instance metadata)
- GCP: 30 saniye
- Azure: 30 saniye

### Pod tarafında
```yaml
# PodDisruptionBudget
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: payments
spec:
  minAvailable: 2
  selector:
    matchLabels: {app: payments}
```

### Termination handler
```bash
# AWS Node Termination Handler
helm install aws-node-termination-handler aws-cdk/aws-node-termination-handler \
  -n kube-system \
  --set enableSpotInterruptionDraining=true \
  --set enableScheduledEventDraining=true
```

→ Interruption signal → cordon + drain → pod'lar sağlıklı node'a evict.

---

## 🎯 Mixed Fleet Strategy

```
[Workload Type]               [Capacity Type]
─────────────────────────────────────────────
Critical / DB                  → on-demand (100%)
Stateless API replica > 3       → on-demand (1) + spot (rest)
Background queue                → spot (100%)
CI runner                       → spot (100%)
Dev/staging                     → spot (100%)
ML training                     → spot (checkpointing)
```

### K8s tolerations + node affinity
```yaml
spec:
  tolerations:
    - key: capacity-type
      operator: Equal
      value: spot
      effect: NoSchedule
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          preference:
            matchExpressions:
              - key: capacity-type
                operator: In
                values: [spot]
```

---

## 📊 Cost Saving Hesabı

```
m5.large baseline:
  On-demand: $0.096/saat × 720 saat = $69/ay
  Spot:      $0.025/saat × 720 saat = $18/ay
  Tasarruf: $51/ay (%74)

10 node cluster:
  All on-demand: $690/ay
  All spot:      $180/ay
  Mixed (3 OD + 7 spot): $333/ay   ← %52 tasarruf, kabul edilebilir risk
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Spot kullanmama | %70 maliyet kaybı | Mixed fleet |
| Tek instance type spot | Interruption riski yüksek | Diversify (5+ instance type) |
| DB primary spot | Data loss | On-demand |
| PDB yok | Interruption sırasında pod kaybı | minAvailable set |
| Termination handler yok | Hard kill, requests fail | Drain handler |
| Spot %100 prod-critical | Interruption felaket | %30-50 spot |
| ML training checkpoint yok | Interruption = baştan başla | Checkpoint per epoch |
| Spot fiyat dalgalanması ignore | Bid stratejisi yok | Karpenter auto |
| Workload spot uygunluğu unutuldu | Real-time spot'ta | Workload classify |

---

## 📋 Spot Adoption Checklist

```
[ ] Workload classification: spot uygun listesi
[ ] Karpenter / equivalent ile mixed fleet
[ ] Diversify: 5+ instance type
[ ] PDB tüm workload'larda
[ ] Termination handler (aws-node-termination-handler)
[ ] Stateless replica > 1 + LB
[ ] Tolerations + node affinity
[ ] ML workload: checkpoint per epoch
[ ] Cost dashboard: spot adoption %
[ ] Quarterly: spot interruption rate review
[ ] DR: spot tüm down durumda fallback
[ ] Yıllık tasarruf hedef: %30+
```

---

## 📚 Referanslar

- **AWS Spot** — aws.amazon.com/ec2/spot
- **AWS Node Termination Handler** — github.com/aws/aws-node-termination-handler
- **GCP Spot VMs** — cloud.google.com/spot-vms
- **Azure Spot** — azure.microsoft.com/en-us/products/virtual-machines/spot
- **Karpenter** — karpenter.sh
- [`Cloud-Cost-Allocation.md`](Cloud-Cost-Allocation.md)
- [`Right-Sizing.md`](Right-Sizing.md)
- [`Reserved-and-Savings-Plans.md`](Reserved-and-Savings-Plans.md)
- [`14-Sustainability/Efficiency-Practices.md`](../14-Sustainability/Efficiency-Practices.md)

---

> *"Spot %70 daha ucuz, **'kullanılmıyor' bahanesi yok**. Workload
> classify + Karpenter + termination handler = $5K-50K aylık
> tasarruf, **2 hafta implementation**."*

---

> 🎓 **Öğrenme Patikası:** Bu doküman [`F1`](../22-Learning-Path/block-f-judgment/F1-maliyet-finops.md) modülünde "Önce oku" kaynağı olarak kullanılıyor.
