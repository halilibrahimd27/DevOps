---
description: "AWS, GCP ve Kubernetes icin right-sizing rehberi: kullanim profiline gore instance kuculttme, CPU/memory hedefleri, tooling ve ne zaman kuculteleceginin karari."
---
# Right-Sizing — Doğru Boyutta Resource

> *"Ortalama %15 CPU kullanan instance'a `4 vCPU` allocate eden ekip,
> aylık %75'i **boş para harcıyor**. Right-sizing = kullanım profiline
> göre instance küçült."*

Bu rehber AWS / GCP / K8s için right-sizing pratiklerini, tooling'i,
ve "ne zaman küçült" kararını anlatır.

---

## 🎯 Right-Sizing Hedefleri

| Resource | İdeal kullanım |
|---|---|
| CPU | %50-70 ortalama |
| Memory | %60-80 |
| Disk | %40-70 (büyüme buffer) |
| Network | %30-60 |

> 🔑 **%80+ kullanım = capacity riski**. **%20 altı = israf**.

---

## 📊 Profile-Based Sizing

### Adım 1: Mevcut kullanımı topla
```promql
# CPU p95 (1 hafta)
quantile_over_time(0.95,
  rate(container_cpu_usage_seconds_total[5m])[7d:1h]
)

# Memory peak
max_over_time(
  container_memory_working_set_bytes[7d]
)
```

### Adım 2: Doğru size hesapla
```
Yeni size = max(p95 × 1.2, p99 × 1.0)

Örnek: CPU p95 = 600m, p99 = 900m
Yeni = max(720m, 900m) = 900m → 1000m (round up)
```

### Adım 3: Validate (1 hafta gözlem)
- HPA scaling spike'larında throttle var mı?
- OOMKilled?
- Latency etkisi?

---

## 🛠️ Cloud-Side Right-Sizing

### AWS Compute Optimizer
```bash
aws compute-optimizer get-ec2-instance-recommendations \
  --account-ids <ACCT>
```

→ "i3.2xlarge → i3.large öner" gibi spesifik öneri.

### GCP Recommender
```bash
gcloud recommender recommendations list \
  --project=<PROJECT> \
  --recommender=google.compute.instance.MachineTypeRecommender
```

### Azure Advisor
```bash
az advisor recommendation list --category Cost
```

---

## 🐳 K8s Right-Sizing

### VPA (Vertical Pod Autoscaler)
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: payments-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: payments
  updatePolicy:
    updateMode: "Off"   # recommendation only
```

```bash
kubectl describe vpa payments-vpa
# Recommendation:
#   cpu: 234m
#   memory: 512Mi
```

→ İnsan review eder, deployment'a manuel uygular.

### Kubecost
```bash
helm install kubecost kubecost/cost-analyzer \
  -n kubecost --create-namespace \
  --set kubecostToken=<TOKEN>
```

UI: per-namespace + per-pod right-sizing önerisi. Kubecost cluster-wide cost dashboard.

### Goldilocks (open-source)
```bash
helm install goldilocks fairwinds-stable/goldilocks
```

→ Namespace başına VPA recommendation auto-generate + dashboard.

---

## 📦 Database Right-Sizing

### Postgres / MySQL
```sql
-- Connection count
SELECT count(*) FROM pg_stat_activity;

-- Cache hit ratio
SELECT
  sum(blks_hit) / nullif(sum(blks_hit + blks_read), 0)::float
FROM pg_stat_database;
-- > 0.99 = optimal
-- < 0.95 = shared_buffers artır
```

### Sizing kuralı
- **Burstable** workload → t-class (AWS) / e2 (GCP) / B-series (Azure)
- **Sustained** → r-class (memory) veya m-class (general)
- **CPU-heavy** → c-class

> 🔑 Burstable instance'lar 7/24 yüksek CPU'da boğulur. Profile'a göre seç.

---

## 🚧 Right-Sizing Riskleri

### 1. Aşırı küçültme → spike'da çökme
- Headroom %20-30 bırak
- Load test ile validate

### 2. Memory under-provision → OOMKilled
- Memory peak'i p99 değil, **max** baz alarak

### 3. Storage IOPS yetersizliği
- gp3 → gp2 değişimde IOPS limit dikkat

### 4. Network throughput azalması
- Smaller instance = daha az bandwidth

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tahmin et "büyük olsun, sonra küçültürüz" | Aylık $X israf | Profile-based |
| Right-size 1 kez, unutma | Workload değişir | Quarterly review |
| VPA Auto + HPA Auto aynı resource | Race | VPA Off mode |
| Memory küçült → OOM | Restart cycle | Peak buffer |
| Disk küçült | Migration zor | Generous + alarm %80 |
| Reserved + right-size sonra | Wasted commitment | Right-size **önce**, reserved sonra |
| Production ile dev aynı size | Dev israf | Per-env sizing |

---

## 📋 Right-Sizing Checklist

```
[ ] Quarterly right-sizing review
[ ] Cloud Compute Optimizer / Advisor / Recommender
[ ] K8s: VPA Off mode + Goldilocks dashboard
[ ] Kubecost (per-namespace cost)
[ ] CI gate: PR'da Kubecost diff (PR-Cost-Diff.md)
[ ] Per-env sizing (dev küçük, prod profile-based)
[ ] Burstable vs sustained workload doğru class
[ ] Memory: p99 + buffer (OOM önleme)
[ ] Storage: %20+ headroom + alarm
[ ] DB connection pool (PgBouncer)
[ ] Quarterly cost report yöneticilere
```

---

## 📚 Referanslar

- **AWS Compute Optimizer** — aws.amazon.com/compute-optimizer
- **GCP Recommender** — cloud.google.com/recommender
- **Kubecost** — kubecost.com
- **Goldilocks** — github.com/FairwindsOps/goldilocks
- **VPA** — github.com/kubernetes/autoscaler
- [`Cloud-Cost-Allocation.md`](Cloud-Cost-Allocation.md)
- [`Spot-Instance-Strategy.md`](Spot-Instance-Strategy.md)
- [`Reserved-and-Savings-Plans.md`](Reserved-and-Savings-Plans.md)
- [`Kubecost-Setup.md`](Kubecost-Setup.md)
- [`14-Sustainability/Efficiency-Practices.md`](../14-Sustainability/Efficiency-Practices.md)

---

> *"Right-sizing 'bir kerelik temizlik' değil — **quarterly disiplin**.
> Profile değişir, traffic büyür/azalır. Disipline edilmemiş ekibin
> AWS bill'i her 6 ayda %20 şişer."*
