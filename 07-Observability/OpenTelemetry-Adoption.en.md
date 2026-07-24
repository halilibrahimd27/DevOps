---
description: "Vendor-neutral observability with OpenTelemetry (OTel): a single SDK and the OTLP protocol, Collector architecture, and removing vendor lock-in through auto-correlation and semantic conventions."
tags:
  - Observability
  - Monitoring
  - Platform Engineering
  - SRE
---
# OpenTelemetry Adoption — Vendor-Neutral Observability

> *"The Datadog SDK + Prometheus client + Loki driver keep writing
> the same information over and over. If I wanted to drop Datadog,
> I'd have to change code everywhere."*

OpenTelemetry (OTel)'s answer: **a single SDK, a single protocol (OTLP), vendor-neutral**.

---

## 🎯 Why OTel?

| Old model | With OTel |
|---|---|
| Datadog SDK + Prometheus + Loki client | A single SDK |
| Switching vendors = code changes | Collector config changes, code stays the same |
| No trace ID in metrics/logs | Auto-correlation built in |
| No standard, everyone tags differently | Semantic conventions standard |
| Polyglot stack (Go/Python/Node) with separate tools | Same SDK in every language |

---

## 🏛️ Architecture

```
┌─────────────────────────────────────────┐
│  Application                             │
│  ┌──────────────────┐                    │
│  │ OTel SDK         │  metrics/logs/     │
│  │ (auto-instrument)│  traces            │
│  └────────┬─────────┘                    │
└───────────┼──────────────────────────────┘
            │ OTLP (gRPC or HTTP)
            ▼
┌─────────────────────────────────────────┐
│  OpenTelemetry Collector                 │
│                                          │
│  Receivers → Processors → Exporters     │
│                                          │
│  - OTLP receiver (from apps)             │
│  - Prometheus receiver (scrape)          │
│  - Filelog receiver (file logs)          │
│                                          │
│  Processors:                             │
│  - Batch (efficient send)                │
│  - Memory limiter                        │
│  - Tail sampling (smart trace selection) │
│  - Resource detection (cloud metadata)   │
│  - Attributes (PII redact, transform)    │
│                                          │
│  Exporters:                              │
│  - Prometheus / Mimir / VictoriaMetrics  │
│  - Loki / Datadog / Splunk               │
│  - Tempo / Jaeger / Honeycomb            │
└─────────────────────────────────────────┘
```

---

## 🚀 1. SDK setup (examples)

### Python (FastAPI)

```python
# pip install opentelemetry-distro opentelemetry-exporter-otlp \
#             opentelemetry-instrumentation-fastapi
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.instrumentation.psycopg2 import Psycopg2Instrumentor

from fastapi import FastAPI
app = FastAPI()

FastAPIInstrumentor.instrument_app(app)
RequestsInstrumentor().instrument()
Psycopg2Instrumentor().instrument()
```

Zero-code auto-instrumentation with `opentelemetry-instrument`:
```bash
opentelemetry-instrument \
  --traces_exporter otlp \
  --metrics_exporter otlp \
  --logs_exporter otlp \
  --service_name my-api \
  --exporter_otlp_endpoint http://otel-collector:4317 \
  uvicorn main:app
```

### Node.js

```javascript
// npm i @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');

const sdk = new NodeSDK({
  serviceName: 'my-app',
  traceExporter: new OTLPTraceExporter({ url: 'http://otel-collector:4317' }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();
```

### Go

Auto-instrument support in Go is weak — do it manually:
```go
import (
  "go.opentelemetry.io/otel"
  "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
  "go.opentelemetry.io/otel/sdk/trace"
)

exporter, _ := otlptracegrpc.New(ctx)
tp := trace.NewTracerProvider(
  trace.WithBatcher(exporter),
  trace.WithResource(resource.NewWithAttributes(
    semconv.ServiceName("my-api"),
  )),
)
otel.SetTracerProvider(tp)

// HTTP middleware:
import "go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
handler := otelhttp.NewHandler(myHandler, "operation")
```

### Adding a manual span

```python
from opentelemetry import trace
tracer = trace.get_tracer(__name__)

@tracer.start_as_current_span("compute_tax")
def compute_tax(amount, region):
    span = trace.get_current_span()
    span.set_attribute("amount", float(amount))
    span.set_attribute("region", region)
    # ...
```

---

## ⚙️ 2. Collector setup (Kubernetes)

### Helm install

```bash
helm install otel-collector \
  open-telemetry/opentelemetry-collector \
  -n observability --create-namespace \
  -f values.yaml
```

### values.yaml

```yaml
mode: deployment            # or: daemonset, statefulset

config:
  receivers:
    otlp:
      protocols:
        grpc: { endpoint: 0.0.0.0:4317 }
        http: { endpoint: 0.0.0.0:4318 }

    prometheus:
      config:
        scrape_configs:
          - job_name: 'kubernetes-pods'
            kubernetes_sd_configs:
              - role: pod

  processors:
    batch:
      timeout: 10s
      send_batch_size: 1024

    memory_limiter:
      check_interval: 1s
      limit_mib: 1500
      spike_limit_mib: 512

    resource:
      attributes:
        - key: deployment.environment
          value: "<ENV>"
          action: upsert

    # Tail sampling: take 100% of errors or slow spans, 5% of the rest
    tail_sampling:
      decision_wait: 10s
      policies:
        - name: errors
          type: status_code
          status_code: { status_codes: [ERROR] }
        - name: slow
          type: latency
          latency: { threshold_ms: 1000 }
        - name: random
          type: probabilistic
          probabilistic: { sampling_percentage: 5 }

    # PII redaction
    attributes:
      actions:
        - key: http.user_agent
          action: hash
        - key: user.email
          action: delete

  exporters:
    otlphttp/mimir:
      endpoint: http://mimir:9009/otlp

    loki:
      endpoint: http://loki:3100/loki/api/v1/push

    otlp/tempo:
      endpoint: tempo:4317
      tls: { insecure: true }

  service:
    pipelines:
      metrics:
        receivers: [otlp, prometheus]
        processors: [memory_limiter, batch, resource]
        exporters: [otlphttp/mimir]
      logs:
        receivers: [otlp]
        processors: [memory_limiter, batch, resource, attributes]
        exporters: [loki]
      traces:
        receivers: [otlp]
        processors: [memory_limiter, batch, resource, tail_sampling, attributes]
        exporters: [otlp/tempo]
```

---

## 🏷️ 3. Semantic Conventions

The foundation of OTel's vendor-neutrality: **standard attribute names**.

| Correct | Wrong |
|---|---|
| `http.method` | `httpMethod`, `method` |
| `http.status_code` | `statusCode` |
| `http.route` | `endpoint` |
| `http.target` | `path` |
| `db.system` | `database` |
| `db.statement` | `sql` |
| `service.name` | `app` |
| `service.version` | `version` |
| `deployment.environment` | `env` |

> Full list: https://opentelemetry.io/docs/specs/semconv/

---

## 🎯 4. Trace ID propagation

Two services talk to each other → the trace ID is forwarded automatically:

```
Service A (handler) ─── traceparent: 00-abc-... ─── Service B (handler)
                                                      │
Service B's span is linked to Service A's trace      ▼
                                          a DB query span gets added
```

W3C `traceparent` header standard. Most HTTP client SDKs auto-inject it.

### Logger correlation

```python
# add trace_id to every log the logger emits
import logging
from opentelemetry.trace import get_current_span

class TraceIDFilter(logging.Filter):
    def filter(self, record):
        span = get_current_span()
        ctx = span.get_span_context() if span else None
        record.trace_id = format(ctx.trace_id, "032x") if ctx and ctx.is_valid else None
        return True

# JSON log: { "trace_id": "abc123...", "msg": "DB error" }
# In Loki: {service="api"} | json | trace_id="abc123..." → all related logs
```

In Grafana, you jump from trace to log and log to trace with a single click.

---

## 📊 5. Metrics

The OTel SDK supports the Prometheus format, but **write new metrics with the OTel API:**

```python
from opentelemetry import metrics

meter = metrics.get_meter(__name__)

# Counter
order_counter = meter.create_counter(
    "orders.total",
    unit="1",
    description="Number of orders created",
)
order_counter.add(1, {"status": "success", "tier": user.tier})

# Histogram (for latency)
processing_time = meter.create_histogram(
    "order.processing_time",
    unit="ms",
    description="Order processing latency",
)
processing_time.record(elapsed_ms, {"endpoint": "create"})

# Gauge / observable
def cb(observer):
    observer.observe(get_queue_depth(), {"queue": "orders"})
queue_gauge = meter.create_observable_gauge("queue.depth", callbacks=[cb])
```

---

## 🔄 6. "Migration": Moving from your existing stack to OTel

### Phase 1: Traces (least invasive)
- OTel SDK + auto-instrument PR
- Deploy the Collector
- Tempo backend (or send OTLP to your existing Datadog)
- No changes to the existing metric/log stack

### Phase 2: Metrics
- OTel SDK metrics API
- Prometheus → OTLP exporter
- Gradually convert the old Prometheus client code to the OTel API

### Phase 3: Logs
- OTel logging bridge
- Old log forwarder (fluent-bit) → OTel Collector
- Keep Loki/ELK as-is, with the Collector in the middle

### Phase 4: Vendor-neutral
- If you decide to move off a paid SaaS like Datadog/NewRelic, just
  change the Collector exporter. The code stays the same.

---

## ⚠️ Common pitfalls

### Cardinality explosion
- Add a `user_id` attribute to every span → millions of unique trace dimensions
- Fix: don't put high-cardinality attributes on metrics; they're already in the trace

### Sampling strategy
- Head-based: 5% of everything (simple, but misses errors)
- Tail-based: 100% of errors + slow spans, 5% of the rest (smarter, done in the collector)
- Recommended: **tail-based** for production

### Auto-instrument noise
- Auto-instrument sometimes creates spans you don't want (every HTTP redirect, DB ping)
- Silence them with a span filter / sampler

### Performance overhead
- SDK + collector overhead < 1% (typical), but the **batch processor** must be tuned correctly
- Memory limiter is mandatory (prevents OOM)

---

## 🚫 Anti-Pattern

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| Using a vendor SDK (Datadog/NewRelic) in new code | Defeats the whole point of OTel; the code changes again when the vendor changes | Write with the OTel API/SDK, ship to the vendor via the Collector exporter |
| Putting a high-cardinality attribute like `user_id`/`order_id` on a metric | Time series explode, Prometheus/Mimir cost skyrockets | Leave high-cardinality fields in the trace; use low-cardinality labels on metrics |
| Skipping the memory limiter processor | Collector OOMs, all telemetry is lost + restart loop | Make `memory_limiter` the first processor in every pipeline |
| OTLP export without a batch processor | Every span is a separate RPC; network/CPU overhead explodes | Group sends with the `batch` processor |
| Head-based 100% sampling in prod | Data and cost grow uncontrolled | Tail-based sampling: 100% of errors + slow, low percentage for the rest |
| Setting tail sampling's `decision_wait` too short | Late-arriving spans get dropped from the trace, leaving it incomplete | Set `decision_wait` to cover the slowest span (e.g., 10s) |
| Custom attribute names (`httpMethod`, `env`) | Breaks semantic conventions, vendor dashboards/queries stop working | Use the standard names `http.method`, `deployment.environment` |
| Not adding the trace ID to logs | Trace ↔ log correlation breaks, no bridge while debugging | Inject `trace_id`/`span_id` into the logger, write it to the JSON log |
| Not forwarding the `traceparent` header manually | The trace chain between services breaks | Set up the W3C propagator; let the HTTP client auto-inject it |
| Sending PII (email, token) into spans/logs as-is | KVKK/GDPR violation, leak risk | Apply delete/hash with the `attributes` processor |
| Turning on auto-instrument blindly and leaving it | Unnecessary spans (redirect, health-check, DB ping) = noise + cost | Silence unwanted spans with a sampler/filter |
| Using the OTLP endpoint without TLS on a public network | Telemetry traffic flows unencrypted and can be sniffed | `insecure` is fine on the internal network; require mTLS/TLS on external hops |
| Migrating everything at once (trace+metric+log) | High risk, hard to roll back, overwhelms the team | Go phase by phase: traces first, then metrics, then logs |

---

## 📋 Checklist

For production-ready OTel adoption:

- [ ] OTel SDK (auto + manual spans) installed on every service, vendor SDK removed
- [ ] `service.name`, `service.version`, `deployment.environment` set on every service
- [ ] Attribute names follow semantic conventions (`http.*`, `db.*`, `service.*`)
- [ ] Collector deployed (`mode` matches the workload: deployment/daemonset)
- [ ] `memory_limiter` is first in every pipeline, `batch` processor included
- [ ] Tail-based sampling active: 100% of errors + slow, low percentage random
- [ ] `decision_wait` set to cover the slowest operation
- [ ] PII redaction: delete/hash processor included for email/token/user-agent
- [ ] W3C `traceparent` propagation works across HTTP/gRPC between all services
- [ ] `trace_id`/`span_id` injected into logs, trace ↔ log jump tested in Grafana
- [ ] High-cardinality attributes go to traces, not metrics (cardinality checked)
- [ ] New metrics are written with the OTel metrics API (not the old Prometheus client)
- [ ] OTLP endpoint protected with TLS/mTLS on external hops
- [ ] Collector exports its own telemetry (self-monitoring: drop/queue metrics)
- [ ] Collector resource limits/requests set, OOM and restart loops monitored
- [ ] Migration phases planned and executed in order (trace → metric → log → vendor-neutral)
- [ ] Exporter failover/queue (sending_queue + retry) configured for backend-down scenarios

---

## 📚 Further Reading

- [opentelemetry.io](https://opentelemetry.io)
- [OTel Demo App](https://opentelemetry.io/docs/demo/) — a complete example microservice stack
- [OTel Collector Receivers/Processors/Exporters list](https://github.com/open-telemetry/opentelemetry-collector-contrib)
- _`07-Observability/Prometheus-Best-Practices.md`_ *(coming soon)*

---

## 📚 References

- [OpenTelemetry official documentation](https://opentelemetry.io/docs/) — SDK, Collector, semantic conventions
- [OTel Collector Contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib) — receiver/processor/exporter list
- [Tracing with Tempo](Tracing-with-Tempo.md) — trace backend, trace ↔ log correlation
- [Prometheus Best Practices](Prometheus-Best-Practices.md) — metrics side, cardinality control
- [Logs: Loki vs ELK](Logs-Loki-vs-ELK.md) — log backend selection, OTel log pipeline
- [SLO Engineering](SLO-Engineering.md) — producing SLIs/SLOs from telemetry

---

> *"OTel's real payoff isn't the dashboard — it's decoupling instrumentation from the backend: code gets written once, and you switch vendors by changing one exporter line in the Collector."*
