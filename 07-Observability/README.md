---
description: "Observability bolumu indeksi: metrics, logs, traces ve profiles dort ayagi ile OpenTelemetry, Prometheus, SLO, alerting, Loki, Tempo ve Pyroscope rehberlerine giris."
---
# 07 · Observability

> *"Loglar olmadan çalışmıyor, traces olmadan yavaş, metrics olmadan SLO
> tutmuyor — ve hangisi olduğunu bilmiyorsun."*

Modern observability "3 pillar + 1": **metrics, logs, traces, profiles**.
Hepsinin önünde **OpenTelemetry**.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`OpenTelemetry-Adoption.md`](OpenTelemetry-Adoption.md) | OTel SDK + Collector + vendor-neutral pipeline kurulumu |
| [`Prometheus-Best-Practices.md`](Prometheus-Best-Practices.md) | Cardinality, recording rules, Mimir/VictoriaMetrics scaling |
| [`SLO-Engineering.md`](SLO-Engineering.md) | SLI seçimi, multi-window/multi-burn-rate alert, SLO dashboard |
| [`Alerting-Done-Right.md`](Alerting-Done-Right.md) | Symptom-based alert, page/ticket/log ayrımı, alert fatigue çözümü |
| [`Logs-Loki-vs-ELK.md`](Logs-Loki-vs-ELK.md) | Log stack seçimi, structured logging, query patterns |
| [`Tracing-with-Tempo.md`](Tracing-with-Tempo.md) | Distributed tracing kurulumu, trace ID exemplar'ları |
| [`Profiling-with-Pyroscope.md`](Profiling-with-Pyroscope.md) | Continuous profiling, eBPF, hot path tespiti |

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

## "Niye OTel?"

| Eski model | OTel ile |
|---|---|
| Datadog SDK + Prometheus client + Loki client | Tek SDK, tek protocol (OTLP) |
| Vendor değiştirmek = kodu değiştirmek | Collector'ı değiştir, kod aynı |
| Trace ID metric/log'da yok | Auto-correlation (trace_id propagation) |
| Standardız, herkes farklı tag isimlendirir | Semantic conventions standardı |

## Altın 4 sinyal (Google SRE)

Bir servis için **mutlaka** ölçülmesi gereken:

1. **Latency** — başarılı/başarısız ayrı (p50, p99)
2. **Traffic** — RPS, kullanıcı sayısı
3. **Errors** — 5xx oranı, panic, timeout
4. **Saturation** — CPU, RAM, disk I/O, queue depth

## Anti-pattern'ler

- ❌ Her şeyi log'la (cardinality patlaması, $$$)
- ❌ "Avg latency < 200ms" SLO (medyanlar yalan söyler, p99 kullan)
- ❌ Cause-based alert ("CPU > %80") yerine symptom-based ("error rate > %1") kullan
- ❌ Dashboards açık ama kimse bakmıyor
- ❌ On-call'a 50 alert düşüyor — eşikleri ayarlamak yerine "ignore" filter ekleniyor
