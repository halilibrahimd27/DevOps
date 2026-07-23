---
description: "Observability section index: an introduction to the metrics, logs, traces, and profiles four pillars, along with OpenTelemetry, Prometheus, SLO, alerting, Loki, Tempo, and Pyroscope guides."
tags:
  - Observability
  - Monitoring
  - Prometheus
  - SRE
---
# 07 · Observability

> *"It doesn't work without logs, it's slow without traces, SLOs don't
> hold without metrics — and you don't know which one it is."*

Modern observability is "3 pillars + 1": **metrics, logs, traces, profiles**.
**OpenTelemetry** sits in front of all of them.

## Contents

| File | Topic |
|---|---|
| [`OpenTelemetry-Adoption.md`](OpenTelemetry-Adoption.md) | Setting up an OTel SDK + Collector + vendor-neutral pipeline |
| [`Prometheus-Best-Practices.md`](Prometheus-Best-Practices.md) | Cardinality, recording rules, Mimir/VictoriaMetrics scaling |
| [`SLO-Engineering.md`](SLO-Engineering.md) | Choosing SLIs, multi-window/multi-burn-rate alerts, SLO dashboards |
| [`Alerting-Done-Right.md`](Alerting-Done-Right.md) | Symptom-based alerts, page/ticket/log separation, fixing alert fatigue |
| [`Logs-Loki-vs-ELK.md`](Logs-Loki-vs-ELK.md) | Choosing a log stack, structured logging, query patterns |
| [`Tracing-with-Tempo.md`](Tracing-with-Tempo.md) | Setting up distributed tracing, trace ID exemplars |
| [`Profiling-with-Pyroscope.md`](Profiling-with-Pyroscope.md) | Continuous profiling, eBPF, hot path detection |

## "Three Pillars + 1"

```
                    ┌──────────────────────┐
                    │   Application code   │
                    │  (OTel SDK enabled)  │
                    └──────────┬───────────┘
                               │ OTLP (gRPC/HTTP)
                               ▼
                    ┌──────────────────────┐
                    │ OpenTelemetry        │
                    │ Collector            │  (sampling, enrichment, routing)
                    └──┬─────┬─────┬──┬────┘
                       │     │     │  │
              metrics  │     │ logs│  │ profiles
                       ▼     ▼     ▼  ▼
        ┌──────────────┐ ┌──────┐ ┌──────┐ ┌────────────┐
        │ Prometheus / │ │ Tempo│ │ Loki │ │ Pyroscope  │
        │ Mimir        │ │ Jaeger│ │      │ │            │
        └──────┬───────┘ └──┬───┘ └──┬───┘ └──────┬─────┘
               └────────────┴────────┴─────────────┘
                                │
                                ▼
                          ┌──────────┐
                          │ Grafana  │
                          │   UI     │
                          └──────────┘
```

## "Why OTel?"

| Old model | With OTel |
|---|---|
| Datadog SDK + Prometheus client + Loki client | A single SDK, a single protocol (OTLP) |
| Switching vendors = changing your code | Change the Collector, code stays the same |
| No trace ID in metrics/logs | Auto-correlation (trace_id propagation) |
| No standard, everyone names tags differently | A standard set of semantic conventions |

## The 4 golden signals (Google SRE)

What **must** be measured for a service:

1. **Latency** — successful/failed separately (p50, p99)
2. **Traffic** — RPS, number of users
3. **Errors** — 5xx rate, panics, timeouts
4. **Saturation** — CPU, RAM, disk I/O, queue depth

## Anti-patterns

- ❌ Log everything (cardinality explosion, $$$)
- ❌ "Avg latency < 200ms" as an SLO (averages lie, use p99)
- ❌ Use symptom-based alerts ("error rate > 1%") instead of cause-based ones ("CPU > 80%")
- ❌ Dashboards exist but nobody looks at them
- ❌ On-call gets 50 alerts — instead of tuning thresholds, an "ignore" filter gets added
