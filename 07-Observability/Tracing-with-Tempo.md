---
description: "Distributed tracing rehberi: OpenTelemetry SDK ile Grafana Tempo kurulumu, trace anatomisi, sampling stratejileri ve production'da trace analizi best practice'leri."
tags:
  - Observability
  - Monitoring
  - Performance
  - SRE
---
# Distributed Tracing — Tempo + OpenTelemetry

> *"Microservice X'in p99 8s. Hangi servis yavaş? Logs alone bunu
> söylemez. **Trace** = isteğin tüm hop'larını görme — 'X servisine
> giden 47 ms dediği call DB'de 7 saniye geçirmiş' cevabı **5
> dakikada**."*

Bu rehber distributed tracing'i — OpenTelemetry SDK + Grafana Tempo —
production'da kurma pratiklerini, sampling stratejilerini, ve trace
analizi best practice'lerini anlatır.

---

## 🎯 Tracing Anatomi

```
[User Request]
   │
   ├─ Trace ID: abc123
   │
   ▼
[API Gateway]                     ← Span 1: 5ms
   │
   ▼
[Auth Service]                    ← Span 2: 50ms
   │
   ▼
[Payments Service]                ← Span 3: 7800ms ⚠️
   │
   ├─ DB query (SELECT...)        ← Span 4: 7500ms (slow!)
   │
   └─ External API (Stripe)       ← Span 5: 200ms
   │
   ▼
[Response]
   Total: 8055ms
```

> 🔑 Trace = **end-to-end request graph**. Her hop = span. Span'larda timing + metadata.

---

## 🛠️ Stack: OpenTelemetry + Tempo

### OpenTelemetry SDK (instrumentation)
```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

provider = TracerProvider()
provider.add_span_processor(
    BatchSpanProcessor(
        OTLPSpanExporter(endpoint="http://otel-collector:4317", insecure=True)
    )
)
trace.set_tracer_provider(provider)

tracer = trace.get_tracer(__name__)

# Span oluştur
with tracer.start_as_current_span("process_payment") as span:
    span.set_attribute("user.id", user_id)
    span.set_attribute("amount", amount)
    result = charge_card(card_token, amount)
    span.set_attribute("payment.status", result.status)
```

### Auto-instrumentation
```bash
# Python
pip install opentelemetry-distro opentelemetry-exporter-otlp
opentelemetry-bootstrap -a install
opentelemetry-instrument python app.py

# Node.js
npm install --save @opentelemetry/auto-instrumentations-node
node --require @opentelemetry/auto-instrumentations-node/register app.js

# Java
java -javaagent:opentelemetry-javaagent.jar app.jar

# Go
import "go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
http.Handle("/", otelhttp.NewHandler(handler, "server"))
```

→ Code change minimum, otomatik HTTP/DB/queue span'leri.

---

## 🚀 OTel Collector

> OpenTelemetry Collector = trace/metric/log toplama + processing + export proxy.

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc: {endpoint: 0.0.0.0:4317}
      http: {endpoint: 0.0.0.0:4318}

processors:
  batch:
    timeout: 10s
    send_batch_size: 1024
  
  tail_sampling:
    decision_wait: 10s
    policies:
      # Always sample errors
      - name: error-policy
        type: status_code
        status_code: {status_codes: [ERROR]}
      # Always sample slow
      - name: slow-policy
        type: latency
        latency: {threshold_ms: 1000}
      # %1 sample others
      - name: probabilistic-policy
        type: probabilistic
        probabilistic: {sampling_percentage: 1}

exporters:
  otlp/tempo:
    endpoint: tempo:4317
    tls: {insecure: true}

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch, tail_sampling]
      exporters: [otlp/tempo]
```

---

## 🚀 Grafana Tempo

```bash
helm install tempo grafana/tempo-distributed \
  -n tempo --create-namespace \
  --set storage.trace.backend=s3 \
  --set storage.trace.s3.bucket=<TEMPO_BUCKET>
```

### Trace storage
- **S3 backend** (long-term, ucuz)
- Trace ID-based lookup (full-text yok)
- Tempo Loki-tarzı: index'lemez, **sadece label + trace ID**

### Grafana datasource
```yaml
apiVersion: 1
datasources:
  - name: Tempo
    type: tempo
    url: http://tempo:3200
    jsonData:
      tracesToLogs:
        datasourceUid: loki
        tags: [job, instance, pod, namespace]
      tracesToMetrics:
        datasourceUid: prometheus
```

→ Tempo ↔ Loki ↔ Prometheus arası **drill-down** Grafana'da.

---

## 🎯 Sampling Stratejileri

### 1. Head Sampling (basit)
```python
# Her trace başında karar: sample veya skip
trace_provider = TracerProvider(
    sampler=ParentBased(TraceIdRatioBased(0.01))  # %1
)
```

→ %1 trace tut, gerisini at. **Ama errors da kaybedilir!**

### 2. Tail Sampling (önerilen)
- Önce tüm trace topla
- Decision: trace bitince
- Logic: error / slow / random %1

> 🔑 **Tail sampling** = error + slow her zaman, normal'in %1'i.

### 3. Adaptive Sampling
- Yüksek-traffic servis: %0.1
- Düşük-traffic: %100
- Otomatik ayarla

---

## 🔍 Trace Analiz — Pratik Senaryolar

### "Yavaş request"
```
1. Grafana → SLO dashboard → p99 latency spike
2. "Explore" → Tempo → recent slow traces
3. Trace seç → waterfall view
4. En uzun span: payments-svc → db_query (7s)
5. Loki'ye drill-down (aynı trace_id)
6. DB log: "lock wait timeout"
7. Root cause: DB blocking transaction
```

### "Random 503"
```
1. Tempo → status_code=ERROR last 1h
2. Top 10 error trace
3. Pattern: hep aynı external API (Stripe)
4. Stripe status page check → outage
```

### N+1 Query Tespit
```
1. Trace'te aynı service'e 100 span
2. Pattern: SELECT * FROM users WHERE id = ? × 100
3. Fix: batch query veya JOIN
```

---

## 🏗️ Trace Context Propagation

### W3C Trace Context (standard)
```
HTTP headers:
  traceparent: 00-{trace_id}-{span_id}-{flags}
  tracestate: vendor1=value1,vendor2=value2
```

```python
# Otomatik (otelhttp middleware)
# Manuel
from opentelemetry.propagate import inject

headers = {}
inject(headers)  # traceparent ekler
requests.get("http://other-service", headers=headers)
```

> 🔑 **Service mesh (Istio/Linkerd/Cilium) otomatik propagate eder**. App-side instrumentation gerek yok.

---

## 📊 Trace + Metric + Log Correlation

```promql
# Slow request → trace ID ile drill
http_request_duration_seconds{trace_id!=""} > 5
```

```logql
# Loki'da trace ID search
{namespace="payments"} | json | trace_id="abc123"
```

→ Tempo trace UI'sında **"View logs"** butonu Loki'ye yönlendirir (aynı trace_id).

> 🔑 **Pillars of Observability**: Metric → "ne kadar yavaş?", Trace → "nerede yavaş?", Log → "niye yavaş?".

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tracing yok | Microservice yavaş, sebep bilinmez | OpenTelemetry instrument |
| Manual instrument her yerde | Maintenance | Auto-instrumentation |
| %100 sample | Disk + cost patlar | Tail sampling |
| Sample sadece head-based | Errors kaybedilir | Tail sampling |
| Trace context propagation manuel | Eksik span | Mesh veya otelhttp middleware |
| Trace + Log + Metric korelasyon yok | "Üç ayrı tool" | Grafana + Tempo + Loki + Prometheus |
| PII trace attribute'da | Compliance ihlal | Hash / mask |
| Tempo retention sonsuz | Cost | Lifecycle 30/90 gün |
| Trace lookup full-text | Tempo desteklemiyor | Trace ID veya label |
| Service mesh + app trace karışık | Duplicate span | Tek instrument layer |

---

## 📋 Tracing Adoption Checklist

```
[ ] OpenTelemetry SDK her servis (auto-instrumentation)
[ ] OTel Collector deploy
[ ] Tail sampling (error + slow + %1 random)
[ ] Tempo backend: S3 (cost-effective)
[ ] Trace context propagation (W3C standard)
[ ] Grafana datasource: Tempo + Loki + Prometheus correlate
[ ] PII filter (trace attribute'larda)
[ ] Retention policy (30/90 gün)
[ ] Per-service sampling rate (adaptive)
[ ] Service mesh entegrasyonu (varsa)
[ ] Documentation: trace lookup runbook
[ ] Quarterly: trace volume + cost review
[ ] Critical path her servis instrumented
```

---

## 📚 Referanslar

- **OpenTelemetry** — opentelemetry.io
- **Grafana Tempo** — grafana.com/oss/tempo
- **Jaeger** (alternative) — jaegertracing.io
- **Zipkin** (legacy) — zipkin.io
- **W3C Trace Context** — w3.org/TR/trace-context
- **OTel Collector** — opentelemetry.io/docs/collector/
- [`OpenTelemetry-Adoption.md`](OpenTelemetry-Adoption.md)
- [`Prometheus-Best-Practices.md`](Prometheus-Best-Practices.md)
- [`Logs-Loki-vs-ELK.md`](Logs-Loki-vs-ELK.md)
- [`Profiling-with-Pyroscope.md`](Profiling-with-Pyroscope.md)
- [`SLO-Engineering.md`](SLO-Engineering.md)

---

> *"Trace, microservice mimarisi'nin **gözleri**. Trace'siz prod 100
> servis = **kara kutu**. OpenTelemetry + Tempo dakikada **root
> cause** verir."*
