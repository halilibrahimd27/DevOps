---
description: "A guide to turning SLOs into an engineering discipline: SLI/SLO/error budget summary, multi-window burn rate alerts, error budget policy, and operational tooling."
tags:
  - Observability
  - SRE
  - Monitoring
  - Incident Response
---
# SLO Engineering — Multi-Window, Burn Rate, Error Budget

> *"You defined an SLI. You set an SLO. **Without an error budget
> alert**, that's not an SLO — it's **good intentions**. A burn rate
> alert is the **real enforcer** of an SLO."*

This guide covers multi-window burn rate alerts, error budget policy,
and operational tooling for turning SLOs into an engineering
discipline.

> Foundation: [`11-SRE/SLI-SLO-Error-Budget.md`](../11-SRE/SLI-SLO-Error-Budget.md)

---

## 🎯 SLI / SLO / Error Budget Summary

```
SLI: the thing measured   → http_requests_total (success rate)
SLO: the target           → 99.9% over the last 30 days
Error Budget              → 0.1% × 30 days = 43 minutes
Burn Rate                 → how many times faster than normal are we burning the budget?
```

---

## 🔥 What Is Burn Rate?

> **Burn rate**: how many times faster than normal we're consuming the error budget.

```
Normal: 30 days → 100% budget
Rate 1: 30 days × 1 = budget runs out in 30 days ✓
Rate 2: 30 days / 2 = 15 days
Rate 14: 30 days / 14 = 2.14 days ⚠️ critical
```

### PromQL
```promql
# 5-minute error rate
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))

# Burn rate (target 99.9% → 0.001 error rate is normal)
(error_rate_5m / 0.001)   # 1 = normal rate, 14 = 14x burn
```

---

## 📊 Multi-Window, Multi-Burn-Rate Alerts

> **Slow burn**: slow but sustained; **Fast burn**: sudden spike.

### Google SRE Workbook formula
| Window | Burn Rate | Budget Share | Urgency |
|---|---|---|---|
| **1 hour** | 14.4x | 2% (43 min × 14.4 / 30 days × 24 h) | Critical (page) |
| **6 hours** | 6x | 5% | High (page) |
| **3 days** | 1x | 10% | Medium (ticket) |

### Alert manifest
```yaml
groups:
  - name: payments-slo
    rules:
      # Fast burn (1 hour)
      - alert: PaymentsErrorBudgetFastBurn
        expr: |
          (
            sum(rate(http_requests_total{service="payments",status=~"5.."}[1h]))
            /
            sum(rate(http_requests_total{service="payments"}[1h]))
          ) > (0.001 * 14.4)
          and
          (
            sum(rate(http_requests_total{service="payments",status=~"5.."}[5m]))
            /
            sum(rate(http_requests_total{service="payments"}[5m]))
          ) > (0.001 * 14.4)
        for: 2m
        labels:
          severity: page
        annotations:
          summary: "Payments error budget fast burn (14.4x)"
          runbook_url: "<RUNBOOK>"

      # Slow burn (6 hours)
      - alert: PaymentsErrorBudgetSlowBurn
        expr: |
          (
            sum(rate(http_requests_total{service="payments",status=~"5.."}[6h]))
            /
            sum(rate(http_requests_total{service="payments"}[6h]))
          ) > (0.001 * 6)
        for: 15m
        labels:
          severity: page

      # Long burn (3 days)
      - alert: PaymentsErrorBudgetLongBurn
        expr: |
          (
            sum(rate(http_requests_total{service="payments",status=~"5.."}[3d]))
            /
            sum(rate(http_requests_total{service="payments"}[3d]))
          ) > 0.001
        for: 1h
        labels:
          severity: ticket
```

> 🔑 **Multi-window** = fewer false positives + earlier detection.

---

## 📈 Error Budget Policy

### Policy example (written)
```
Service: payments-api
SLO: 99.9% availability (30-day rolling)
Error budget: 43 minutes / 30 days

Budget status → action:
  > 50% (21+ min remaining) → Take risks, aggressive feature deploys OK
  20% - 50%                 → Normal velocity
  5% - 20%                  → Slow down: bug fixes + perf improvements only
  0% - 5%                   → Feature freeze
  < 0 (overspent)           → All hands on reliability
```

### Automatic enforcement
```yaml
# ArgoCD sync gate
- alert: ErrorBudgetCritical
  expr: error_budget_remaining < 0.05
  annotations:
    action: "Auto-block prod deploys for {{ $labels.service }}"
```

→ Prod deploy auto-block via Slack bot / GitOps gate.

---

## 🛠️ Sloth — SLO YAML → Prometheus Rules

[Sloth](https://sloth.dev) lets you define SLOs in YAML and auto-generates Prometheus rules.

```yaml
# slo.yaml
version: prometheus/v1
service: payments-api
labels:
  team: payments
slos:
  - name: availability
    objective: 99.9
    description: "99.9% successful HTTP requests over 30d"
    sli:
      events:
        error_query: |
          sum(rate(http_requests_total{service="payments",status=~"5.."}[{{.window}}]))
        total_query: |
          sum(rate(http_requests_total{service="payments"}[{{.window}}]))
    alerting:
      name: PaymentsAvailability
      page_alert:
        labels: {severity: page}
      ticket_alert:
        labels: {severity: ticket}

  - name: latency
    objective: 99.0   # 99% requests < 500ms
    description: "99% of requests served under 500ms"
    sli:
      events:
        # bad events = requests SLOWER than 500ms = total − (le=0.5 bucket)
        # Order matters: count − bucket; reversing it produces a negative value and breaks the burn rate.
        error_query: |
          sum(rate(http_request_duration_seconds_count{service="payments"}[{{.window}}]))
          -
          sum(rate(http_request_duration_seconds_bucket{service="payments",le="0.5"}[{{.window}}]))
        total_query: |
          sum(rate(http_request_duration_seconds_count{service="payments"}[{{.window}}]))
```

```bash
sloth generate -i slo.yaml -o prometheus-rules.yaml
```

→ Multi-window burn alerts + recording rules are auto-generated.

---

## 🎯 SLI Types

### 1. **Availability** (most common)
```promql
sum(rate(http_requests_total{status!~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))
```

### 2. **Latency**
```promql
# 99% of requests < 500ms
histogram_quantile(0.99,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
)
```

### 3. **Throughput**
```promql
# Min RPS
sum(rate(http_requests_total[1m])) > 100
```

### 4. **Quality** (data correctness)
- Customer reports → "wrong order delivered"
- Application-level metric

### 5. **Freshness** (data pipeline)
```promql
# How stale is the latest data
time() - max(data_pipeline_last_processed_timestamp)
```

---

## 📋 Writing an SLO — Practical Steps

### 1. Identify the user journey
"What's the critical flow for the user?"
- Login → Browse → Checkout → Payment

### 2. Define an SLI for each step
- Login: 99% < 1s
- Browse: 99% < 500ms
- Checkout: 99.9% success
- Payment: 99.95% success

### 3. SLO cycle
- 30-day rolling window
- Error budget = 1 - SLO

### 4. Alerts + dashboard
- Auto-generate with Sloth
- Grafana SLO dashboard

### 5. Quarterly review
- Is the budget holding up?
- Too strict (wasted overhead)?
- Too loose (doesn't affect customers)?

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| 100% uptime SLO | Mathematically impossible | 99.9% (sweet spot) |
| Average latency SLI | p99 outliers get hidden | Histogram p95/p99 |
| Single-window alert | False-positive bombardment | Multi-window burn |
| Invisible budget | Team ignores it | Grafana dashboard |
| Ignoring an overspent budget | Missing reliability investment | Feature freeze policy |
| SLO never discussed with the product team | "What does this mean?" | Joint review (Eng + PM) |
| No alert severity | Spam | severity: page / warn / ticket |
| No recording rules | Slow dashboard | Pre-computed |
| Guessed burn rate thresholds | False positives | Google formula |
| SLO same as SLA | Customer SLA breach | SLO < SLA buffer |

---

## 📋 SLO Engineering Checklist

```
[ ] Critical user journeys defined
[ ] Per-service SLO (availability + latency)
[ ] SLO < SLA (10-20% buffer)
[ ] Multi-window burn rate alert (1h fast, 6h, 3d)
[ ] Error budget dashboard (Grafana)
[ ] Burn rate alert severity (page / warn / ticket)
[ ] YAML → rule auto-generate with Sloth
[ ] Error budget policy documented (deploy freeze rules)
[ ] Quarterly: SLO review (with the product team)
[ ] Postmortem: budget impact reported
[ ] Recording rules (precomputed)
[ ] SLO violation → action item tracking
[ ] Customer-facing status page SLO section (optional)
```

---

## 📚 References

- **Google SRE Workbook** — Chapter 5: Alerting on SLOs
- **Sloth** — sloth.dev
- **Pyrra** — pyrra.dev (alternative SLO tool)
- **OpenSLO** — openslo.com (vendor-neutral spec)
- [`11-SRE/SLI-SLO-Error-Budget.md`](../11-SRE/SLI-SLO-Error-Budget.md)
- [`Prometheus-Best-Practices.md`](Prometheus-Best-Practices.md)
- [`Alerting-Done-Right.md`](Alerting-Done-Right.md)
- [`OpenTelemetry-Adoption.md`](OpenTelemetry-Adoption.md)
- [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md)

---

> *"An SLO isn't 'define a metric, set a target' — it's **multi-window
> burn rate + error budget policy**. An undisciplined SLO is just the
> team's 'good intentions' — it never gets enforced."*

---

> 🎓 **Learning Path:** This document is used as the "read first" resource in the [`E1`](../22-Learning-Path/block-e-ownership/E1-sli-slo-error-budget.md) module.
