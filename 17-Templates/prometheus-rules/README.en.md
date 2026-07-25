---
description: "Prometheus SLO recording + alerting rule template: multi-window multi-burn-rate alerting (fast/slow burn) and p99 latency alarm; 99.9% availability example."
tags:
  - Template
  - Observability
  - SRE
  - Prometheus
---
# Prometheus SLO Rules

> Precompute the SLI with a recording rule, alert on SLO violations with
> multi-window multi-burn-rate. Turns the 99.9% target on paper into a working alarm.
> Placeholders use `<UPPER_CASE>`. This page is the embedded form of the neighboring file;
> the source file is in the same folder.

## File

| File | Kind | What it provides |
|---|---|---|
| [`slo-recording-rules.yaml`](slo-recording-rules.yaml) | PrometheusRule | 5m–3d availability SLI + fast/slow burn + latency alarm |

Concept + math: [`11-SRE/SLI-SLO-Error-Budget.md`](../../11-SRE/SLI-SLO-Error-Budget.md).

## Why multi-window multi-burn-rate

A single threshold is either too noisy (every micro-error alarms) or too late (won't warn before the budget is gone).
Two windows are checked at once:

- **Fast burn** (5m + 1h, 14.4x): fast degradation burning the budget in ~2 hours → `critical`, page immediately.
- **Slow burn** (1h + 6h, 6x): a slow leak → `warning`, look during business hours.

The short window answers "is it bad now", the long window "is it really a trend"; when both fire together, alarm noise drops.

### `slo-recording-rules.yaml`

```yaml
# Prometheus recording + alerting rules
# SLO: 99.9% successful requests / 30-day rolling window
# Multi-window multi-burn-rate alerting (Google SRE workbook)

apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: <APP_NAME>-slo
  namespace: monitoring
  labels:
    role: alert-rules
    prometheus: kube-prometheus
spec:
  groups:
    # ───── Recording rules: SLI calculation ─────
    - name: <APP_NAME>.sli.rules
      interval: 30s
      rules:
        # 5-minute availability ratio
        - record: sli:<APP_NAME>:availability:5m
          expr: |
            sum(rate(http_requests_total{app="<APP_NAME>",code!~"5.."}[5m]))
            /
            sum(rate(http_requests_total{app="<APP_NAME>"}[5m]))

        # 1 hour
        - record: sli:<APP_NAME>:availability:1h
          expr: |
            sum(rate(http_requests_total{app="<APP_NAME>",code!~"5.."}[1h]))
            /
            sum(rate(http_requests_total{app="<APP_NAME>"}[1h]))

        # 6 hours
        - record: sli:<APP_NAME>:availability:6h
          expr: |
            sum(rate(http_requests_total{app="<APP_NAME>",code!~"5.."}[6h]))
            /
            sum(rate(http_requests_total{app="<APP_NAME>"}[6h]))

        # 1 day
        - record: sli:<APP_NAME>:availability:1d
          expr: |
            sum(rate(http_requests_total{app="<APP_NAME>",code!~"5.."}[1d]))
            /
            sum(rate(http_requests_total{app="<APP_NAME>"}[1d]))

        # 3 days
        - record: sli:<APP_NAME>:availability:3d
          expr: |
            sum(rate(http_requests_total{app="<APP_NAME>",code!~"5.."}[3d]))
            /
            sum(rate(http_requests_total{app="<APP_NAME>"}[3d]))

        # SLO target (constant, for the dashboard)
        - record: slo:<APP_NAME>:target
          expr: vector(0.999)

    # ───── Alerting rules: multi-window multi-burn-rate ─────
    - name: <APP_NAME>.slo.alerts
      rules:
        # FAST burn — 5m + 1h window, 14.4x burn rate
        # → burns the 30-day budget in 2 hours
        - alert: <APP_NAME>HighErrorBudgetBurnRate
          expr: |
            (
              (1 - sli:<APP_NAME>:availability:5m) > (14.4 * (1 - 0.999))
              and
              (1 - sli:<APP_NAME>:availability:1h) > (14.4 * (1 - 0.999))
            )
          for: 2m
          labels:
            severity: critical
            slo: <APP_NAME>-availability
          annotations:
            summary: "<APP_NAME> error budget burning fast (fast burn)"
            description: |
              Over the last 5 minutes and 1 hour the error rate is burning the
              30-day SLO budget at 14.4x. The entire budget is gone within 2 hours.
              Urgent intervention required.
            runbook_url: https://github.com/<ORG>/runbooks/<APP_NAME>/error-budget-burn.md
            dashboard_url: https://grafana.example.com/d/<DASH_ID>

        # SLOW burn — 1h + 6h window, 6x burn rate
        # → burns the 30-day budget in 5 days
        - alert: <APP_NAME>SustainedErrorBudgetBurn
          expr: |
            (
              (1 - sli:<APP_NAME>:availability:1h) > (6 * (1 - 0.999))
              and
              (1 - sli:<APP_NAME>:availability:6h) > (6 * (1 - 0.999))
            )
          for: 15m
          labels:
            severity: warning
            slo: <APP_NAME>-availability
          annotations:
            summary: "<APP_NAME> sustained error budget burn"
            description: |
              Over the last 1 hour and 6 hours the error rate is burning the
              30-day SLO budget at 6x. The budget is gone within 5 days.
            runbook_url: https://github.com/<ORG>/runbooks/<APP_NAME>/error-budget-burn.md

        # Latency SLO (p99 < 500ms for the main request type)
        - alert: <APP_NAME>HighLatency
          expr: |
            histogram_quantile(0.99,
              sum by (le) (rate(http_request_duration_seconds_bucket{app="<APP_NAME>"}[5m]))
            ) > 0.5
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "<APP_NAME> p99 latency > 500ms"
            description: "p99: {{ $value }}s"
```

---

## 🚫 Anti-Pattern

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Single-threshold alarm (`error_rate > 0`) | Either noise or lateness | Multi-window multi-burn-rate |
| Computing the SLI at alarm time | Heavy query, slow evaluation | Precompute with a recording rule |
| Alarm without `runbook_url` | Whoever gets paged doesn't know what to do | Runbook + dashboard link on every alarm |
| Measuring the SLO with an average | An average hides tail latency | p99/p99.9 histogram_quantile |

> *"An SLO is the math of 'when do you wake up'; burn rate turns it into the 'now or in the morning' decision."*
