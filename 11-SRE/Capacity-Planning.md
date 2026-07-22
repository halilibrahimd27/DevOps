---
description: "Demand forecasting, headroom hesaplama, load test framework'ü ve 'ne zaman scale up?' sorusunun yöntemsel cevabını veren capacity planning rehberi."
tags:
  - SRE
  - Performance
  - Cost Optimization
  - Monitoring
---
# Capacity Planning — "Ne Kadar Yeterli?" Sorusunun Mühendislik Cevabı

> *"Yeterli kapasite 'sezgi' değil — **veri** ile kanıtlanır.
> 'Şimdiye kadar yetmişti' deyen ekip, Black Friday'de **bu yıl da
> yeter mi?** sorusuna cevap veremez. Capacity = bilinç + plan."*

Bu rehber demand forecasting, headroom hesaplama, load test framework'ü
ve "ne zaman scale up?" sorusunun yöntemsel cevabını verir.

---

## 🎯 Capacity Planning — 3 Soru

```
1. Şu an ne kadar kapasitemiz var?         (mevcut)
2. Talep ne kadar büyüyor?                  (forecast)
3. Hangi kaynak ne zaman bitecek?           (saturation point)
```

---

## 📊 Mevcut Kapasiteyi Ölçme

### CPU saturation
```promql
# CPU utilization (avg)
1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m]))

# Per-pod CPU
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)
/
sum(kube_pod_container_resource_limits{resource="cpu"}) by (pod)
```

### Memory
```promql
# Pod memory usage / limit
sum(container_memory_working_set_bytes) by (pod)
/
sum(kube_pod_container_resource_limits{resource="memory"}) by (pod)
```

### Disk
```promql
# Disk usage trend
node_filesystem_avail_bytes / node_filesystem_size_bytes
```

### Connection / Request rate
```promql
# Request per second
sum(rate(http_requests_total[5m]))

# DB connection
pg_stat_activity_count / pg_settings_max_connections
```

---

## 📈 Demand Forecasting

### Linear projection
```promql
# Disk dolacak mı? 30 gün için tahmin
predict_linear(node_filesystem_avail_bytes[6h], 30*24*3600) < 0
```

### Seasonality (Holt-Winters)
- Günlük pattern: gece düşük, gündüz yüksek
- Haftalık: hafta sonu düşük (B2B SaaS) veya yüksek (B2C)
- Yıllık: Black Friday, Ramadan, Christmas

```python
import statsmodels.tsa.holtwinters as hw

# Aylık request count → 6 ay forecast
model = hw.ExponentialSmoothing(
    monthly_requests,
    trend='add',
    seasonal='add',
    seasonal_periods=12
).fit()

forecast = model.forecast(6)
```

### Business growth
- Marketing campaign → +%30 traffic
- Yeni feature launch → unknown spike
- Müşteri segment growth: per-customer scenario

> 🔑 **Forecast = istatistik + business**. İkisini de değerlendir.

---

## 🎯 Headroom Hedefi

| Resource | Hedef Headroom | Niye |
|---|---|---|
| CPU | %30+ boş | Spike + GC + retry overhead |
| Memory | %20+ boş | OOM tampon |
| Disk | %30+ boş | WAL + backup + log büyüme |
| DB connection | %50+ boş | Connection storm tampon |
| Network bandwidth | %40+ boş | Burst traffic |

> 🔑 **%80+ kullanım = kırmızı bölge**. Sürpriz spike'ı tampon yok.

---

## 🚦 Auto-scaling — Reactive

### HPA (CPU + Memory)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: payments
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: payments
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target: {type: Utilization, averageUtilization: 70}
    - type: Resource
      resource:
        name: memory
        target: {type: Utilization, averageUtilization: 80}
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 100   # 2x scale up max 1 dk'da
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300   # 5 dk bekle
      policies:
        - type: Percent
          value: 25    # her seferinde max %25 scale down
          periodSeconds: 60
```

### KEDA (event-driven)
```yaml
# Queue depth'e göre worker scale
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: queue-worker
spec:
  scaleTargetRef:
    name: worker
  minReplicaCount: 0
  maxReplicaCount: 50
  triggers:
    - type: aws-sqs-queue
      metadata:
        queueURL: <SQS_URL>
        queueLength: '10'   # 10+ message → scale up
```

### Cluster Autoscaler / Karpenter
- HPA pod'ları çoğaltır
- Karpenter node ekler (gerekirse)
- Cost-aware: spot instance + right-size

---

## 🎯 Predictive Scaling

> Reactive scaling ≠ yeterli. **Spike öncesi** scale up gerekir.

### Cron-based (predictable)
```yaml
# KEDA cron trigger
triggers:
  - type: cron
    metadata:
      timezone: Europe/Istanbul
      start: 0 9 * * *      # her sabah 09:00
      end: 0 18 * * *       # 18:00
      desiredReplicas: '20' # business hours daha fazla
```

### Event-based (Black Friday)
- 1 hafta önce başla
- Manuel scale up baseline
- Load test ile doğrula
- Post-event scale down

### ML-based (deneysel)
- Geçmiş 6 ay datasından LSTM eğit
- 30 dk önceden traffic tahmini
- HPA buffer

---

## 🧪 Load Testing — Hipotezi Doğrulamak

### k6 (modern, JavaScript)
```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '5m', target: 100 },   // ramp-up to 100 RPS
    { duration: '10m', target: 100 },  // steady
    { duration: '2m', target: 500 },   // spike
    { duration: '5m', target: 500 },   // sustained
    { duration: '5m', target: 0 },     // ramp-down
  ],
  thresholds: {
    http_req_duration: ['p(99)<2000'],   // p99 < 2s
    http_req_failed: ['rate<0.01'],       // <%1 fail
  },
};

export default function () {
  const res = http.get('https://api.<DOMAIN>/payments/123');
  check(res, { 'status 200': (r) => r.status === 200 });
  sleep(1);
}
```

```bash
k6 run load-test.js
```

### Locust (Python)
```python
from locust import HttpUser, task, between

class APIUser(HttpUser):
    wait_time = between(1, 5)

    @task(3)
    def get_payment(self):
        self.client.get("/payments/123")

    @task(1)
    def post_payment(self):
        self.client.post("/payments", json={"amount": 100})
```

### Test ortamı stratejisi
- **Staging cluster** = prod'un %30'u (ölçek)
- **Shadow traffic** prod'da: gerçek user → mirror → test cluster
- **Production load test**: blast radius düşük, off-peak (önerilmez ama bazı durumlarda)

---

## 📋 Capacity Review Cycle

### Quarterly review
```
1. Mevcut kullanım dashboard'u (CPU/Mem/Disk/DB conn)
2. Son 90 gün trend
3. Yeni feature / customer growth forecast
4. Headroom değerlendirmesi
5. Black Friday / büyük event kontrol
6. Action items: scale up, optimize, archive
```

### Annual review
- Hardware refresh planı
- Cloud commitment (Reserved Instance, Savings Plans)
- Multi-region kapasite
- DR kapasitesi (tam yarısı standby)

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "Yeterli mi" sezgi | Sürpriz outage | Veri-bazlı forecast |
| %95+ kullanım kabul | Spike'da çökme | %30+ headroom |
| Auto-scaling yok | Manuel rampaup, gece geç | HPA + KEDA |
| Load test yok | Real traffic'te öğrenilen | Quarterly load test |
| Forecast linear-only | Seasonality kayıp | Holt-Winters / ML |
| Black Friday hazırlığı son hafta | Gerçekçi değil | 4-6 hafta önce |
| HPA sadece CPU | Memory / queue ihmal | Multi-metric |
| Scale down agresif | Trafik geri spike'ında pod yok | Stabilization window |
| Predictive scaling yok | Reactive lag | Cron + event-based |
| Capacity → SRE'in tek işi | Dev'ler ölçeği bilmez | Per-service capacity ownership |
| DR kapasitesi yarım | Region down → çökme | DR site = prod'un %50+ |

---

## 📋 Capacity Planning Checklist

```
[ ] Anahtar metrikler dashboard'da (CPU/Mem/Disk/Conn/RPS)
[ ] Headroom alarmı (%80+ kullanım)
[ ] HPA min/max/target tanımlı tüm prod servis
[ ] KEDA queue / event-driven workload'lar için
[ ] Cluster Autoscaler / Karpenter
[ ] Quarterly load test (k6 / Locust)
[ ] Forecast: linear + seasonality
[ ] Black Friday / büyük event playbook (4-6 hafta önce)
[ ] Predictive scaling: cron veya ML
[ ] Cost-aware: spot + savings plan
[ ] DR kapasitesi (region failover sonrası %100)
[ ] Quarterly capacity review meeting
[ ] Annual: hardware refresh planı
[ ] Per-service ownership (dev'ler bilir)
[ ] Documentation: scale up runbook
```

---

## 📚 Referanslar

- **Google SRE Workbook** — Bölüm 11: Capacity Planning
- **Capacity Planning for Web Performance** — Daniel A. Menasce
- **k6** — k6.io
- **Locust** — locust.io
- **KEDA** — keda.sh
- **Karpenter** — karpenter.sh
- [`SLI-SLO-Error-Budget.md`](SLI-SLO-Error-Budget.md)
- [`Incident-Response.md`](Incident-Response.md)
- [`Chaos-Engineering.md`](Chaos-Engineering.md)
- [`12-FinOps/Cloud-Cost-Allocation.md`](../12-FinOps/Cloud-Cost-Allocation.md)

---

> *"Capacity 'çok kaynak' değil — **doğru kaynak doğru zamanda**.
> Forecast olmadan scale, **paranın israfı**; load test olmadan
> büyüme, **müşterinin israfı**."*

---

> 🎓 **Öğrenme Patikası:** Bu doküman [`E5`](../22-Learning-Path/block-e-ownership/E5-chaos.md) modülünde "Önce oku" kaynağı olarak kullanılıyor.
