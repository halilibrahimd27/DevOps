---
description: "OpenTelemetry (OTel) ile vendor-neutral observability: tek SDK ve OTLP protokolu, Collector mimarisi, auto-correlation ve semantic conventions ile vendor bagimliligini kaldirma."
tags:
  - Observability
  - Monitoring
  - Platform Engineering
  - SRE
---
# OpenTelemetry Adoption — Vendor-Neutral Observability

> *"Datadog SDK + Prometheus client + Loki driver hep aynı bilgiyi
> tekrar yazıyor. Datadog'u bırakmak istesem, kodun her yerinde
> değişiklik."*

OpenTelemetry (OTel) çözümü: **tek SDK, tek protokol (OTLP), vendor-neutral**.

---

## 🎯 Niye OTel?

| Eski model | OTel ile |
|---|---|
| Datadog SDK + Prometheus + Loki client | Tek SDK |
| Vendor değiştirmek = kod değişikliği | Collector config değişir, kod aynı |
| Trace ID metric/log'da yok | Auto-correlation built-in |
| Standart yok, herkes farklı tag | Semantic conventions standardı |
| Polyglot stack (Go/Python/Node) ayrı tools | Aynı SDK her dilde |

---

## 🏛️ Mimari

```
┌─────────────────────────────────────────┐
│  Application                             │
│  ┌──────────────────┐                    │
│  │ OTel SDK         │  metrics/logs/     │
│  │ (auto-instrument)│  traces            │
│  └────────┬─────────┘                    │
└───────────┼──────────────────────────────┘
            │ OTLP (gRPC veya HTTP)
            ▼
┌─────────────────────────────────────────┐
│  OpenTelemetry Collector                 │
│                                          │
│  Receivers → Processors → Exporters     │
│                                          │
│  - OTLP receiver (apps'ten)              │
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

## 🚀 1. SDK kurulum (örnekler)

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

`opentelemetry-instrument` ile sıfır-kod auto-instrumentation:
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

Go'da auto-instrument zayıf, manuel:
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

### Manuel span eklemek

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

## ⚙️ 2. Collector kurulum (Kubernetes)

### Helm install

```bash
helm install otel-collector \
  open-telemetry/opentelemetry-collector \
  -n observability --create-namespace \
  -f values.yaml
```

### values.yaml

```yaml
mode: deployment            # veya: daemonset, statefulset

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

    # Tail sampling: errors veya slow span'ları %100 al, geri kalan %5
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

OTel'in vendor-neutral'lığının temeli: **standart attribute isimleri**.

| Doğru | Yanlış |
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

> Tam liste: https://opentelemetry.io/docs/specs/semconv/

---

## 🎯 4. Trace ID propagation

İki servis konuşuyor → trace ID otomatik forward:

```
Service A (handler) ─── traceparent: 00-abc-... ─── Service B (handler)
                                                      │
Service B'nin span'ı Service A'nın trace'ine bağlı   ▼
                                          DB query span'ı eklenir
```

W3C `traceparent` header standardı. Çoğu HTTP client SDK auto-inject eder.

### Logger correlation

```python
# logger her log'a trace_id ekle
import logging
from opentelemetry.trace import get_current_span

class TraceIDFilter(logging.Filter):
    def filter(self, record):
        span = get_current_span()
        ctx = span.get_span_context() if span else None
        record.trace_id = format(ctx.trace_id, "032x") if ctx and ctx.is_valid else None
        return True

# JSON log: { "trace_id": "abc123...", "msg": "DB error" }
# Loki'de: {service="api"} | json | trace_id="abc123..." → ilgili tüm log'lar
```

Grafana'da trace'ten log'a, log'dan trace'e tek tıklamayla geçilir.

---

## 📊 5. Metrics

OTel SDK Prometheus formatı destekler ama **yeni metric'leri OTel API ile yaz:**

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

# Histogram (latency için)
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

## 🔄 6. "Migration": Mevcut stack'ten OTel'e geçiş

### Faz 1: Trace (en az invaziv)
- OTel SDK + auto-instrument PR
- Collector deploy
- Tempo backend (veya mevcut Datadog'a OTLP gönder)
- Mevcut metric/log stack'inde değişiklik yok

### Faz 2: Metric
- OTel SDK metric API
- Prometheus → OTLP exporter
- Eski Prometheus client kodunu yavaş yavaş OTel API'ye çevir

### Faz 3: Log
- OTel logging bridge
- Eski log forwarder (fluent-bit) → OTel Collector
- Loki/ELK aynı kalsın, ortada Collector

### Faz 4: Vendor-neutral
- Datadog/NewRelic gibi paid SaaS'ten çıkış kararı verirsen, sadece
  Collector exporter'ı değiştir. Kod aynı.

---

## ⚠️ Yaygın tuzaklar

### Cardinality patlaması
- `user_id` attribute'u her span'a eklersen → milyonlarca unique trace dimension
- Çözüm: high-cardinality attribute'ları metrics'e ekleme; trace'te zaten var

### Sampling stratejisi
- Head-based: %5 her şey (basit ama error miss eder)
- Tail-based: error + slow %100, geri kalan %5 (daha akıllı, collector'da)
- Önerilen: **tail-based** prod için

### Auto-instrument noise
- Auto-instrument bazen istemediğin span'ları yaratır (her HTTP redirect, DB ping)
- Span filter / sampler ile sustur

### Performance overhead
- SDK + collector overhead < %1 (tipik), ama **batch processor** doğru ayarlanmalı
- Memory limiter zorunlu (OOM önle)

---

## 🚫 Anti-Pattern

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Vendor SDK'sını (Datadog/NewRelic) yeni kodda kullanmak | OTel'in tüm amacını öldürür; vendor değişince yine kod değişir | OTel API/SDK ile yaz, Collector exporter'ından vendor'a gönder |
| `user_id`/`order_id` gibi high-cardinality attribute'u metric'e koymak | Time-series patlar, Prometheus/Mimir maliyeti uçar | High-cardinality alanları trace'e bırak; metric'te düşük-kardinalite label kullan |
| Memory limiter processor'ı atlamak | Collector OOM olur, tüm telemetry kaybı + restart loop | Her pipeline'da `memory_limiter`'ı ilk processor yap |
| Batch processor'sız OTLP export | Her span ayrı RPC; network/CPU overhead patlar | `batch` processor ile gönderimi grupla |
| Prod'da head-based %100 sampling | Veri ve maliyet kontrolsüz büyür | Tail-based sampling: error + slow %100, geri kalan düşük yüzde |
| Tail sampling'i `decision_wait` çok kısa ayarlamak | Geç gelen span'lar trace'ten düşer, eksik trace | `decision_wait`'i en yavaş span'ı kapsayacak şekilde ver (örn. 10s) |
| Custom attribute isimleri (`httpMethod`, `env`) | Semantic convention bozulur, vendor dashboard/query çalışmaz | `http.method`, `deployment.environment` standart isimlerini kullan |
| Trace ID'yi log'a eklememek | Trace ↔ log korelasyonu kopar, debug'da köprü yok | Logger'a `trace_id`/`span_id` enjekte et, JSON log'a yaz |
| `traceparent` header'ı manuel forward etmemek | Servisler arası trace zinciri kırılır | W3C propagator'ı kur; HTTP client auto-inject etsin |
| PII'yı (email, token) span/log'a olduğu gibi göndermek | KVKK/GDPR ihlali, sızıntı riski | `attributes` processor ile delete/hash uygula |
| Auto-instrument'i kör açıp bırakmak | Gereksiz span (redirect, health-check, DB ping) noise + maliyet | İstenmeyen span'ları sampler/filter ile sustur |
| OTLP endpoint'ini TLS'siz public ağda kullanmak | Telemetry trafiği şifresiz akar, dinlenebilir | İç ağda `insecure` tamam; dış hop'ta mTLS/TLS zorunlu kıl |
| Hepsini tek seferde (trace+metric+log) migrate etmek | Risk büyük, geri dönüş zor, ekip boğulur | Faz faz git: önce trace, sonra metric, sonra log |

---

## 📋 Checklist

Production-ready OTel adoption için:

- [ ] OTel SDK (auto + manuel span) tüm servislerde kurulu, vendor SDK kaldırıldı
- [ ] `service.name`, `service.version`, `deployment.environment` her serviste set ediliyor
- [ ] Attribute isimleri semantic conventions'a uygun (`http.*`, `db.*`, `service.*`)
- [ ] Collector deploy edildi (`mode` workload'a uygun: deployment/daemonset)
- [ ] Her pipeline'da `memory_limiter` ilk, `batch` processor ekli
- [ ] Tail-based sampling aktif: error + slow %100, random düşük yüzde
- [ ] `decision_wait` en yavaş işlemi kapsayacak şekilde ayarlı
- [ ] PII redaction: email/token/user-agent için delete/hash processor'ı ekli
- [ ] W3C `traceparent` propagation tüm servisler arası HTTP/gRPC'de çalışıyor
- [ ] Log'lara `trace_id`/`span_id` enjekte ediliyor, Grafana'da trace ↔ log geçişi test edildi
- [ ] High-cardinality attribute'lar metric'e değil trace'e gidiyor (cardinality kontrol edildi)
- [ ] Yeni metric'ler OTel metrics API ile yazılıyor (eski Prometheus client değil)
- [ ] OTLP endpoint dış hop'larda TLS/mTLS ile korunuyor
- [ ] Collector kendi telemetry'sini export ediyor (self-monitoring: drop/queue metrikleri)
- [ ] Collector resource limit/request set edildi, OOM ve restart loop izleniyor
- [ ] Migration fazları planlandı ve sıralı yürütülüyor (trace → metric → log → vendor-neutral)
- [ ] Exporter failover/queue (sending_queue + retry) backend down senaryosu için ayarlı

---

## 📚 Devamı

- [opentelemetry.io](https://opentelemetry.io)
- [OTel Demo App](https://opentelemetry.io/docs/demo/) — eksiksiz örnek mikroservis stack
- [OTel Collector Receivers/Processors/Exporters list](https://github.com/open-telemetry/opentelemetry-collector-contrib)
- _`07-Observability/Prometheus-Best-Practices.md`_ *(yakında)*
