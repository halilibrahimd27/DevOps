---
description: "Production-grade Prometheus best practices: metric naming, cardinality control, retention policy, federation, HA, and rules for avoiding OOM with recording rules."
tags:
  - Observability
  - Prometheus
  - Monitoring
  - SRE
---
# Prometheus Best Practices — Production-Grade

> *"Prometheus isn't 'install it and it works' — it's a **data system
> that demands discipline**. Without controlling cardinality, setting up
> federation, and having a retention policy, you'll be shaking hands
> with OOM in **6 months**."*

This guide covers the practical rules of Prometheus production
deployment — metric naming, cardinality, retention, federation, HA, recording rules.

---

## 🏗️ Prometheus Anatomy

```
[Scrape targets]   ← /metrics endpoint
       ↓
[Prometheus server]
   ├── TSDB (local disk)
   ├── Recording rules (precomputed metrics)
   ├── Alerting rules
   └── HTTP API (PromQL)
       ↓
[Alertmanager]    ← ships alerts
[Grafana]         ← dashboard
```

---

## 🎯 1️⃣ Metric Naming Conventions

### Pattern
```
<namespace>_<subsystem>_<name>_<unit>_<type>

http_requests_total
http_request_duration_seconds
db_connections_open
```

### Rules
- **Suffix**: `_total` (counter), `_seconds` (duration), `_bytes` (size)
- **Snake_case**, lowercase
- Globally unique
- Descriptive name

### ❌ Wrong
```
HTTPRequests           # CamelCase
http-requests          # no dashes
http_request_count     # use _total
api_latency_ms         # _seconds is the standard
```

### ✅ Right
```
http_requests_total                                    # counter
http_request_duration_seconds                          # histogram
http_request_duration_seconds_bucket{le="0.5"}         # histogram bucket
http_request_duration_seconds_sum                      # histogram sum
http_request_duration_seconds_count                    # histogram count
process_cpu_seconds_total                              # process CPU
go_goroutines                                          # gauge
```

---

## 🎯 2️⃣ Cardinality — The Most Common Trap

> **Cardinality**: the number of unique label combinations a metric has.

### High cardinality = OOM
```
http_requests_total{
  method="GET",
  path="/api/users/12345",   ← USER ID label (bad!)
  status="200"
}
```

→ Every user_id becomes a separate time series. 1M users = **1M series**. Memory: 1M × 3KB = 3 GB.

### ✅ Low cardinality
```
http_requests_total{
  method="GET",
  route="/api/users/{id}",   ← path template (good!)
  status="200"
}
```

→ Only as many series as there are defined routes.

### Cardinality alarm
```promql
# Top metrics
topk(10, count by (__name__)({__name__=~".+"}))
```

### Forbidden labels
- User ID, request ID, trace ID
- IP address (thousands of unique values)
- Email, phone
- Timestamp
- UUID, GUID

→ Put these in a **trace** or a **log**, **not a metric**.

> 🔑 **Target**: total active series < 1M (single Prometheus). More than that → Thanos/Mimir/VictoriaMetrics.

---

## 🎯 3️⃣ Histogram vs Summary

### Histogram (recommended)
```python
http_request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration',
    buckets=[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
)

http_request_duration.observe(0.234)
```

```promql
# Aggregation server-side
histogram_quantile(0.99,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service)
)
```

### Summary (not recommended)
```python
http_request_summary = Summary(
    'http_request_duration_summary_seconds',
    'HTTP request duration'
)
```

→ Quantile is computed **client-side**, **aggregation is impossible**.

> 🔑 **Prefer Histogram**. For aggregation + flexibility.

### Native Histograms (Prometheus 2.40+)
```yaml
# More efficient, automatic buckets
prometheus.yml:
  global:
    enable-feature: native-histograms
```

→ 30-50% disk savings + precise p99.9.

---

## 🎯 4️⃣ Recording Rules (Pre-computed)

> Precompute frequently used PromQL to speed up dashboards.

### Manifest
```yaml
groups:
  - name: aggregations
    interval: 30s
    rules:
      - record: instance:http_requests:rate5m
        expr: rate(http_requests_total[5m])

      - record: service:http_requests:rate5m
        expr: |
          sum by (service) (
            rate(http_requests_total[5m])
          )

      - record: service:http_request_duration_seconds:p99
        expr: |
          histogram_quantile(0.99,
            sum by (service, le) (
              rate(http_request_duration_seconds_bucket[5m])
            )
          )
```

### Naming convention
```
<level>:<metric>:<aggregation>

instance:http_requests:rate5m   ← per-instance
service:http_requests:rate5m    ← per-service
cluster:http_requests:rate5m    ← cluster total
```

> 🔑 Dashboards that use recording rules are **10x faster**.

---

## 🎯 5️⃣ Retention + Storage

### Default
```yaml
prometheus.yml:
  --storage.tsdb.retention.time=15d
```

### Production sizing
```
Sample size: ~1.5 byte (compressed)
Series: 500K (typical)
Scrape interval: 15s
Daily samples: 500K × (86400/15) = 2.88B samples/day
Daily disk: ~4.3 GB/day
15 day: ~65 GB
```

### Long-term storage (Thanos / Mimir)
```yaml
# Thanos sidecar
spec:
  containers:
    - name: prometheus
      args:
        - --storage.tsdb.retention.time=2h   # local only 2 hours
    - name: thanos-sidecar
      args:
        - --tsdb.path=/prometheus
        - --objstore.config-file=/etc/thanos/objstore.yml
        # → upload long-term blocks to S3
```

→ Local for 2 hours (HA + recent), S3 for years.

---

## 🎯 6️⃣ HA — Prometheus Pair

> A single Prometheus is a SPOF. Run a pair in production.

```yaml
# 2 parallel Prometheus instances, same targets, same rules
prometheus-a:  scrape, alert, fed
prometheus-b:  scrape, alert, fed (mirror)

[Alertmanager cluster] ← deduplication
```

### Alertmanager HA
```yaml
alertmanager:
  replicas: 3
  cluster:
    peers:
      - alertmanager-0:9094
      - alertmanager-1:9094
      - alertmanager-2:9094
```

→ The same alert arrives from 2 Prometheus instances, Alertmanager deduplicates it.

---

## 🎯 7️⃣ Federation

> Collect metrics from multiple Prometheus instances into a single Prometheus.

```yaml
# Global Prometheus federates from regional
scrape_configs:
  - job_name: 'federate'
    scrape_interval: 60s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{__name__=~"job:.*"}'   # aggregated metrics only
        - '{job=~".+"}'
    static_configs:
      - targets:
          - 'prometheus-eu.<DOMAIN>:9090'
          - 'prometheus-us.<DOMAIN>:9090'
```

> 🔑 **Federation only for aggregated metrics**. Don't pull raw metrics — cardinality explodes.

---

## 🎯 8️⃣ Prometheus Operator

```bash
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  --set prometheus.prometheusSpec.retention=15d \
  --set prometheus.prometheusSpec.resources.requests.memory=4Gi \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=100Gi
```

### ServiceMonitor (declarative scrape)
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: payments-metrics
spec:
  selector:
    matchLabels:
      app: payments
  endpoints:
    - port: metrics
      interval: 30s
      path: /metrics
```

### PrometheusRule
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
spec:
  groups:
    - name: payments
      rules:
        - alert: PaymentsHighErrorRate
          expr: |
            sum(rate(http_requests_total{service="payments",status=~"5.."}[5m]))
            /
            sum(rate(http_requests_total{service="payments"}[5m])) > 0.05
          for: 5m
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| `/users/123` in a path label instead of `/users/{id}` | Cardinality explodes | Route template |
| Using Summary | No aggregation | Histogram |
| Single Prometheus in prod | SPOF | HA pair |
| No retention / unbounded | Disk full | 15d local + Thanos S3 |
| No recording rules | Slow dashboard | Pre-computed |
| Scraping all metrics | Cardinality + storage | Selective `metric_relabel_configs` |
| Federation of raw metrics | Source overload | Aggregated only |
| Local storage on SSD | Slow query | NVMe recommended |
| Alertmanager not HA | Alert loss | Cluster mode, 3 replicas |
| ServiceMonitor labels too generic | Collision | Specific selector |

---

## 📋 Prometheus Production Checklist

```
[ ] Prometheus Operator (kube-prometheus-stack)
[ ] HA: 2 Prometheus pair
[ ] Alertmanager: 3 replica cluster mode
[ ] Retention: 15d local + Thanos/Mimir S3 long-term
[ ] Storage: NVMe SSD, 100GB+
[ ] Resources: 4-8Gi memory, 2 CPU
[ ] Recording rules: key aggregations
[ ] Cardinality monitoring (top 10 metrics)
[ ] Histogram > Summary
[ ] Native histograms (Prometheus 2.40+)
[ ] ServiceMonitor / PodMonitor declarative
[ ] PrometheusRule for alerts
[ ] Federation (multi-region/cluster)
[ ] Backup: Thanos S3 already handles it
[ ] Quarterly: cardinality review + cleanup
```

---

## 📚 References

- **Prometheus Docs** — prometheus.io/docs
- **Prometheus Operator** — prometheus-operator.dev
- **Thanos** — thanos.io
- **Mimir** — grafana.com/oss/mimir
- **VictoriaMetrics** — victoriametrics.com
- **Prometheus Naming** — prometheus.io/docs/practices/naming/
- [`OpenTelemetry-Adoption.md`](OpenTelemetry-Adoption.md)
- [`SLO-Engineering.md`](SLO-Engineering.md)
- [`Alerting-Done-Right.md`](Alerting-Done-Right.md)
- [`Prometheus-Grafana-K8s-Setup.md`](Prometheus-Grafana-K8s-Setup.md)
- [`11-SRE/SLI-SLO-Error-Budget.md`](../11-SRE/SLI-SLO-Error-Budget.md)

---

> *"Prometheus being 'easy to install' doesn't make it 'prod-ready'.
> Cardinality + retention + HA + federation **demand discipline**.
> Otherwise, 6 months later you're managing **data that's bad for you**."*
