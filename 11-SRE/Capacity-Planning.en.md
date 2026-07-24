---
description: "A capacity planning guide covering demand forecasting, headroom calculation, a load test framework, and a methodical answer to the question 'when do we scale up?'."
tags:
  - SRE
  - Performance
  - Cost Optimization
  - Monitoring
---
# Capacity Planning — The Engineering Answer to "How Much Is Enough?"

> *"Enough capacity is not 'intuition' — it is proven with **data**.
> A team that says 'it's been enough so far' cannot answer **will it be
> enough this year too?** on Black Friday. Capacity = awareness + plan."*

This guide gives the methodical answer to demand forecasting, headroom
calculation, a load test framework, and the question "when do we scale up?".

---

## 🎯 Capacity Planning — 3 Questions

```
1. How much capacity do we have right now?  (current)
2. How fast is demand growing?              (forecast)
3. Which resource runs out and when?        (saturation point)
```

---

## 📊 Measuring Current Capacity

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
# Will the disk fill up? Forecast for 30 days
predict_linear(node_filesystem_avail_bytes[6h], 30*24*3600) < 0
```

### Seasonality (Holt-Winters)
- Daily pattern: low at night, high during the day
- Weekly: low on weekends (B2B SaaS) or high (B2C)
- Yearly: Black Friday, Ramadan, Christmas

```python
import statsmodels.tsa.holtwinters as hw

# Monthly request count → 6-month forecast
model = hw.ExponentialSmoothing(
    monthly_requests,
    trend='add',
    seasonal='add',
    seasonal_periods=12
).fit()

forecast = model.forecast(6)
```

### Business growth
- Marketing campaign → +30% traffic
- New feature launch → unknown spike
- Customer segment growth: per-customer scenario

> 🔑 **Forecast = statistics + business**. Weigh both.

---

## 🎯 Headroom Target

| Resource | Target Headroom | Why |
|---|---|---|
| CPU | 30%+ free | Spike + GC + retry overhead |
| Memory | 20%+ free | OOM buffer |
| Disk | 30%+ free | WAL + backup + log growth |
| DB connection | 50%+ free | Connection storm buffer |
| Network bandwidth | 40%+ free | Burst traffic |

> 🔑 **80%+ utilization = red zone**. No buffer for a surprise spike.

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
          value: 100   # 2x scale up, max in 1 min
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300   # wait 5 min
      policies:
        - type: Percent
          value: 25    # max 25% scale down each time
          periodSeconds: 60
```

### KEDA (event-driven)
```yaml
# Scale workers by queue depth
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
- HPA multiplies pods
- Karpenter adds nodes (when needed)
- Cost-aware: spot instance + right-size

---

## 🎯 Predictive Scaling

> Reactive scaling ≠ enough. You need to scale up **before the spike**.

### Cron-based (predictable)
```yaml
# KEDA cron trigger
triggers:
  - type: cron
    metadata:
      timezone: Europe/Istanbul
      start: 0 9 * * *      # every morning 09:00
      end: 0 18 * * *       # 18:00
      desiredReplicas: '20' # more during business hours
```

### Event-based (Black Friday)
- Start 1 week ahead
- Manually scale up the baseline
- Validate with a load test
- Post-event scale down

### ML-based (experimental)
- Train an LSTM on the past 6 months of data
- Predict traffic 30 min ahead
- HPA buffer

---

## 🧪 Load Testing — Validating the Hypothesis

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
    http_req_failed: ['rate<0.01'],       // <1% fail
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

### Test Environment Strategy
- **Staging cluster** = 30% of prod (scale)
- **Shadow traffic** in prod: real user → mirror → test cluster
- **Production load test**: low blast radius, off-peak (not recommended, but in some cases)

---

## 📋 Capacity Review Cycle

### Quarterly review
```
1. Current utilization dashboard (CPU/Mem/Disk/DB conn)
2. Last 90-day trend
3. New feature / customer growth forecast
4. Headroom assessment
5. Black Friday / big event check
6. Action items: scale up, optimize, archive
```

### Annual review
- Hardware refresh plan
- Cloud commitment (Reserved Instance, Savings Plans)
- Multi-region capacity
- DR capacity (a full half on standby)

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| "Is it enough" by intuition | Surprise outage | Data-driven forecast |
| Accepting 95%+ utilization | Crash on a spike | 30%+ headroom |
| No auto-scaling | Manual ramp-up, late at night | HPA + KEDA |
| No load test | Learned on real traffic | Quarterly load test |
| Linear-only forecast | Seasonality missed | Holt-Winters / ML |
| Black Friday prep in the last week | Not realistic | 4-6 weeks ahead |
| HPA on CPU only | Memory / queue ignored | Multi-metric |
| Aggressive scale down | No pods when traffic spikes back | Stabilization window |
| No predictive scaling | Reactive lag | Cron + event-based |
| Capacity → SRE's job alone | Devs don't know the scale | Per-service capacity ownership |
| Half DR capacity | Region down → crash | DR site = 50%+ of prod |

---

## 📋 Capacity Planning Checklist

```
[ ] Key metrics on the dashboard (CPU/Mem/Disk/Conn/RPS)
[ ] Headroom alarm (80%+ utilization)
[ ] HPA min/max/target defined for every prod service
[ ] KEDA for queue / event-driven workloads
[ ] Cluster Autoscaler / Karpenter
[ ] Quarterly load test (k6 / Locust)
[ ] Forecast: linear + seasonality
[ ] Black Friday / big event playbook (4-6 weeks ahead)
[ ] Predictive scaling: cron or ML
[ ] Cost-aware: spot + savings plan
[ ] DR capacity (100% after region failover)
[ ] Quarterly capacity review meeting
[ ] Annual: hardware refresh plan
[ ] Per-service ownership (devs know it)
[ ] Documentation: scale up runbook
```

---

## 📚 References

- **Google SRE Workbook** — Chapter 11: Capacity Planning
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

> *"Capacity isn't 'lots of resources' — it's **the right resource at the right time**.
> Scaling without a forecast **wastes money**; growth without a load test
> **wastes customers**."*

---

> 🎓 **Learning Path:** This document is used as a "Read first" resource in the [`E5`](../22-Learning-Path/block-e-ownership/E5-chaos.md) module.
