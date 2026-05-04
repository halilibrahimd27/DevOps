# 07 · Observability

> *"Loglar olmadan çalışmıyor, traces olmadan yavaş, metrics olmadan SLO
> tutmuyor — ve hangisi olduğunu bilmiyorsun."*

Modern observability "3 pillar + 1": **metrics, logs, traces, profiles**.
Hepsinin önünde **OpenTelemetry**.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`OpenTelemetry-Adoption.md`](OpenTelemetry-Adoption.md) | OTel SDK + Collector + vendor-neutral pipeline kurulumu |
| _`Prometheus-Best-Practices.md`_ *(yakında)* | Cardinality, recording rules, Mimir/VictoriaMetrics scaling |
| _`SLO-Engineering.md`_ *(yakında)* | SLI seçimi, multi-window/multi-burn-rate alert, SLO dashboard |
| _`Alerting-Done-Right.md`_ *(yakında)* | Symptom-based alert, page/ticket/log ayrımı, alert fatigue çözümü |
| _`Logs-Loki-vs-ELK.md`_ *(yakında)* | Log stack seçimi, structured logging, query patterns |
| _`Tracing-with-Tempo.md`_ *(yakında)* | Distributed tracing kurulumu, trace ID exemplar'ları |
| _`Profiling-with-Pyroscope.md`_ *(yakında)* | Continuous profiling, eBPF, hot path tespiti |

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
