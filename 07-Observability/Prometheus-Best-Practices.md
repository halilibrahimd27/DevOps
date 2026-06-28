---
description: "Production-grade Prometheus best practices: metric naming, cardinality kontrolu, retention politikasi, federation, HA ve recording rules ile OOM'dan kacinma kurallari."
tags:
  - Observability
  - Prometheus
  - Monitoring
  - SRE
---
# Prometheus Best Practices — Production-Grade

> *"Prometheus 'install et çalışıyor' değil — **disiplin gerektiren
> bir veri sistemi**. Cardinality patlamadan, federation kurmadan,
> retention politikası olmadan **6 ay** sonra OOM ile tanışırsın."*

Bu rehber Prometheus production deployment'ının pratik kurallarını —
metric naming, cardinality, retention, federation, HA, recording rules — anlatır.

---

## 🏗️ Prometheus Anatomi

```
[Scrape targets]   ← /metrics endpoint
       ↓
[Prometheus server]
   ├── TSDB (local disk)
   ├── Recording rules (precomputed metrics)
   ├── Alerting rules
   └── HTTP API (PromQL)
       ↓
[Alertmanager]    ← alarmlar ship
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

### Kurallar
- **Suffix**: `_total` (counter), `_seconds` (duration), `_bytes` (size)
- **Snake_case**, lowercase
- Globally unique
- Descriptive isim

### ❌ Yanlış
```
HTTPRequests           # CamelCase
http-requests          # dash yok
http_request_count     # _total kullan
api_latency_ms         # _seconds standardı
```

### ✅ Doğru
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

## 🎯 2️⃣ Cardinality — En Sık Tuzak

> **Cardinality**: Bir metric'in unique label combination sayısı.

### Yüksek cardinality = OOM
```
http_requests_total{
  method="GET",
  path="/api/users/12345",   ← USER ID label (kötü!)
  status="200"
}
```

→ Her user_id ayrı time series. 1M user = **1M series**. Memory: 1M × 3KB = 3 GB.

### ✅ Düşük cardinality
```
http_requests_total{
  method="GET",
  route="/api/users/{id}",   ← path template (iyi!)
  status="200"
}
```

→ Sadece tanımlı route sayısı kadar series.

### Cardinality alarm
```promql
# Top metric'ler
topk(10, count by (__name__)({__name__=~".+"}))
```

### Yasak label'lar
- User ID, request ID, trace ID
- IP address (binlerce unique)
- Email, phone
- Timestamp
- UUID, GUID

→ Bunları **trace** veya **log**'a koy, **metric'e değil**.

> 🔑 **Hedef**: Toplam active series < 1M (single Prometheus). Daha fazlası → Thanos/Mimir/VictoriaMetrics.

---

## 🎯 3️⃣ Histogram vs Summary

### Histogram (önerilen)
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

### Summary (önerme)
```python
http_request_summary = Summary(
    'http_request_duration_summary_seconds',
    'HTTP request duration'
)
```

→ Quantile **client-side** hesaplanır, **aggregation imkansız**.

> 🔑 **Histogram tercih et**. Aggregation + flexibility için.

### Native Histograms (Prometheus 2.40+)
```yaml
# Daha verimli, otomatik bucket
prometheus.yml:
  global:
    enable-feature: native-histograms
```

→ %30-50 disk tasarrufu + p99.9 hassas.

---

## 🎯 4️⃣ Recording Rules (Pre-computed)

> Sık kullanılan PromQL'i önceden hesapla, dashboard'larda hızlandır.

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

> 🔑 Dashboard'lar recording rule kullanır → **10x hızlı**.

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
        - --storage.tsdb.retention.time=2h   # local sadece 2 saat
    - name: thanos-sidecar
      args:
        - --tsdb.path=/prometheus
        - --objstore.config-file=/etc/thanos/objstore.yml
        # → S3'e long-term blok upload
```

→ Local 2 saat (HA + recent), S3'te yıllarca.

---

## 🎯 6️⃣ HA — Prometheus Pair

> Tek Prometheus = SPOF. Production'da pair.

```yaml
# 2 paralel Prometheus, aynı targets, aynı rules
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

→ Aynı alarm 2 Prometheus'tan gelir, Alertmanager dedup eder.

---

## 🎯 7️⃣ Federation

> Multiple Prometheus'tan tek Prometheus'a metric topla.

```yaml
# Global Prometheus federates from regional
scrape_configs:
  - job_name: 'federate'
    scrape_interval: 60s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{__name__=~"job:.*"}'   # sadece aggregated metrics
        - '{job=~".+"}'
    static_configs:
      - targets:
          - 'prometheus-eu.<DOMAIN>:9090'
          - 'prometheus-us.<DOMAIN>:9090'
```

> 🔑 **Federation only aggregated metrics**. Raw metric'leri çekme — cardinality patlar.

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

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Path label'da `/users/{id}` yerine `/users/123` | Cardinality patlar | Route template |
| Summary kullan | Aggregation yok | Histogram |
| Tek Prometheus prod | SPOF | HA pair |
| Retention yok / sonsuz | Disk full | 15d local + Thanos S3 |
| Recording rule yok | Slow dashboard | Pre-computed |
| Tüm metric'leri scrape | Cardinality + storage | Selective `metric_relabel_configs` |
| Federation raw metric | Source overload | Aggregated only |
| Local storage SSD'de | Yavaş query | NVMe önerilir |
| Alertmanager HA değil | Alarm kaybı | Cluster mode 3 replica |
| ServiceMonitor labels generic | Çakışma | Spesifik selector |

---

## 📋 Prometheus Production Checklist

```
[ ] Prometheus Operator (kube-prometheus-stack)
[ ] HA: 2 Prometheus pair
[ ] Alertmanager: 3 replica cluster mode
[ ] Retention: 15d local + Thanos/Mimir S3 long-term
[ ] Storage: NVMe SSD, 100GB+
[ ] Resource: 4-8Gi memory, 2 CPU
[ ] Recording rules: anahtar aggregation
[ ] Cardinality monitoring (top 10 metric)
[ ] Histogram > Summary
[ ] Native histograms (Prometheus 2.40+)
[ ] ServiceMonitor / PodMonitor declarative
[ ] PrometheusRule for alerts
[ ] Federation (multi-region/cluster)
[ ] Backup: Thanos S3 zaten yapıyor
[ ] Quarterly: cardinality review + cleanup
```

---

## 📚 Referanslar

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

> *"Prometheus 'install kolay' diye 'prod-ready' değil. Cardinality
> + retention + HA + federation **disiplin gerektiriyor**. Yoksa
> 6 ay sonra **kendin için kötü olan veri**'yi yönetiyorsun."*
