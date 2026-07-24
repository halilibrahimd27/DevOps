---
description: "A distributed tracing guide: setting up Grafana Tempo with the OpenTelemetry SDK, trace anatomy, sampling strategies, and production trace-analysis best practices."
tags:
  - Observability
  - Monitoring
  - Performance
  - SRE
---
# Distributed Tracing — Tempo + OpenTelemetry

> *"Microservice X's p99 is 8s. Which service is slow? Logs alone
> won't tell you. **Trace** = seeing every hop of the request — the
> answer to 'the call it said took 47ms to reach service X actually
> spent 7 seconds in the DB' in **5 minutes**."*

This guide covers distributed tracing — OpenTelemetry SDK + Grafana
Tempo — production setup practices, sampling strategies, and trace
analysis best practices.

---

## 🎯 Tracing Anatomy

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

> 🔑 Trace = **end-to-end request graph**. Each hop = a span. Spans carry timing + metadata.

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

# Create a span
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

→ Minimal code change, automatic HTTP/DB/queue spans.

---

## 🚀 OTel Collector

> OpenTelemetry Collector = a trace/metric/log collection + processing + export proxy.

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
      # 1% sample others
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
- **S3 backend** (long-term, cheap)
- Trace ID-based lookup (no full-text)
- Tempo works Loki-style: it doesn't index, **only label + trace ID**

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

→ **Drill-down** between Tempo ↔ Loki ↔ Prometheus, in Grafana.

---

## 🎯 Sampling Strategies

### 1. Head Sampling (simple)
```python
# Decide at the start of each trace: sample or skip
trace_provider = TracerProvider(
    sampler=ParentBased(TraceIdRatioBased(0.01))  # 1%
)
```

→ Keep 1% of traces, drop the rest. **But errors get lost too!**

### 2. Tail Sampling (recommended)
- First collect the entire trace
- Decision: made once the trace finishes
- Logic: error / slow / random 1%

> 🔑 **Tail sampling** = error + slow always, 1% of the rest.

### 3. Adaptive Sampling
- High-traffic service: 0.1%
- Low-traffic: 100%
- Adjust automatically

---

## 🔍 Trace Analysis — Practical Scenarios

### "Slow request"
```
1. Grafana → SLO dashboard → p99 latency spike
2. "Explore" → Tempo → recent slow traces
3. Select a trace → waterfall view
4. Longest span: payments-svc → db_query (7s)
5. Drill down to Loki (same trace_id)
6. DB log: "lock wait timeout"
7. Root cause: DB blocking transaction
```

### "Random 503"
```
1. Tempo → status_code=ERROR last 1h
2. Top 10 error traces
3. Pattern: always the same external API (Stripe)
4. Stripe status page check → outage
```

### N+1 Query Detection
```
1. 100 spans to the same service in the trace
2. Pattern: SELECT * FROM users WHERE id = ? × 100
3. Fix: batch query or JOIN
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
# Automatic (otelhttp middleware)
# Manual
from opentelemetry.propagate import inject

headers = {}
inject(headers)  # adds traceparent
requests.get("http://other-service", headers=headers)
```

> 🔑 **Service mesh (Istio/Linkerd/Cilium) propagates automatically**. No app-side instrumentation needed.

---

## 📊 Trace + Metric + Log Correlation

```promql
# Slow request → drill via trace ID
http_request_duration_seconds{trace_id!=""} > 5
```

```logql
# trace ID search in Loki
{namespace="payments"} | json | trace_id="abc123"
```

→ The **"View logs"** button in the Tempo trace UI takes you to Loki (same trace_id).

> 🔑 **Pillars of Observability**: Metric → "how slow?", Trace → "where is it slow?", Log → "why is it slow?".

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| No tracing | Microservice is slow, cause unknown | Instrument with OpenTelemetry |
| Manual instrumentation everywhere | Maintenance burden | Auto-instrumentation |
| 100% sampling | Disk + cost explode | Tail sampling |
| Head-based sampling only | Errors get lost | Tail sampling |
| Manual trace context propagation | Missing spans | Mesh or otelhttp middleware |
| No trace + log + metric correlation | "Three separate tools" | Grafana + Tempo + Loki + Prometheus |
| PII in trace attributes | Compliance violation | Hash / mask |
| Unlimited Tempo retention | Cost | Lifecycle 30/90 days |
| Full-text trace lookup | Tempo doesn't support it | Trace ID or label |
| Service mesh + app tracing mixed | Duplicate spans | A single instrumentation layer |

---

## 📋 Tracing Adoption Checklist

```
[ ] OpenTelemetry SDK on every service (auto-instrumentation)
[ ] Deploy the OTel Collector
[ ] Tail sampling (error + slow + 1% random)
[ ] Tempo backend: S3 (cost-effective)
[ ] Trace context propagation (W3C standard)
[ ] Grafana datasource: Tempo + Loki + Prometheus correlation
[ ] PII filter (on trace attributes)
[ ] Retention policy (30/90 days)
[ ] Per-service sampling rate (adaptive)
[ ] Service mesh integration (if any)
[ ] Documentation: trace lookup runbook
[ ] Quarterly: trace volume + cost review
[ ] Critical path instrumented on every service
```

---

## 📚 References

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

> *"Trace is the **eyes** of a microservice architecture. Prod with
> 100 services and no tracing = a **black box**. OpenTelemetry + Tempo
> gives you **root cause** in minutes."*
