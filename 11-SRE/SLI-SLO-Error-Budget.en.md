---
description: "A practical guide explaining SLI, SLO, SLA and error budget concepts in an actionable way, walking you through writing your own service's first SLO."
tags:
  - SRE
  - Observability
  - Monitoring
  - DORA
---
# SLI / SLO / Error Budget — Practical Guide

> *"100% uptime is not a target; it is mathematically impossible. **99.9% is the target, and the remaining 0.1% is your engineering decision budget.**"*

This guide is distilled from the Google SRE Book but is direct and
immediately actionable. Our goal is that by the end you can write your own service's first SLO.

---

## 📐 Definitions (short and clear)

| Term | Meaning |
|---|---|
| **SLI** (Service Level **Indicator**) | The thing being measured. `% successful requests`, `p99 latency`. **A ratio or a histogram.** |
| **SLO** (Service Level **Objective**) | The target. `SLI ≥ 99.9% over the last 30 days`. **Your internal promise.** |
| **SLA** (Service Level **Agreement**) | The legal promise to the customer. Must be **looser** than the SLO. |
| **Error Budget** | `1 - SLO`. The amount of failure tolerated. **Spent to take risks.** |
| **Burn Rate** | How many times faster than normal we are burning the budget. `2x burn` → a 30-day budget runs out in 15 days. |

> 🔑 **Key principle:** An SLO is written **from the customer's perspective**. Nobody
> cares about CPU%; they care about "did the payment go through or not."

---

## 🎯 SLI Selection Rules

### Rule 1: Must reflect customer experience
- ✅ HTTP 2xx rate, request latency
- ✅ Job completion time, queue lag
- ❌ CPU%, memory%, disk I/O (these are saturation signals, not SLIs)

### Rule 2: Measurable and controllable
- ✅ "Our response time < 500ms"
- ❌ "The customer's own internet connection"

### Rule 3: Classify by category
| Type | Example | SLI |
|---|---|---|
| **Request/response** | HTTP API | Availability (success rate), Latency (percentile) |
| **Data processing** | ETL, ML inference | Throughput, Freshness, Correctness |
| **Storage** | DB, S3 | Durability, Retrieval latency, Throughput |

### Rule 4: User journey > endpoint
- ❌ "GET /api/users 99.9% successful"
- ✅ "Checkout flow (chain of 4 endpoints) 99.5% successful"

The user is really asking "did my payment complete"; a single endpoint may be green
but the flow may be broken.

---

## 🧮 Setting the SLO Target

### Step 1: Measure current performance
First measure the **unconscious** SLO (i.e. actual behavior). Last 30 days:

```promql
# Current availability
sum(rate(http_requests_total{code!~"5..",app="<APP>"}[30d]))
/
sum(rate(http_requests_total{app="<APP>"}[30d]))
```

Output: `0.9985` → currently 99.85%.

### Step 2: Set a realistic target

Common mistake: "make it 99.99%". Look at the table below — do you really need it?

| SLO | Monthly downtime | Yearly downtime | Cost (roughly) |
|---|---|---|---|
| 99% | 7 hours 18 min | 3.65 days | Low (single-AZ + retries) |
| 99.5% | 3 hours 39 min | 1.83 days | Medium |
| 99.9% | 43 minutes | 8.76 hours | Multi-AZ + auto-failover (**sweet spot for most prod**) |
| 99.95% | 21 minutes | 4.38 hours | Active-active HA |
| 99.99% | 4.3 minutes | 52 minutes | Multi-region + complex DR |
| 99.999% | 26 seconds | 5.26 minutes | "Five nines" — only telco/finance |

### Step 3: The SLO < SLA rule
If you give the customer `99.5%` in the SLA, make your **internal SLO `99.7%`**. The buffer
is for you.

### Step 4: Window (time window)
Standard: **30-day rolling**.
- Shorter (7 days): noisy, annoying
- Longer (90 days): you notice bad behavior far too late

---

## 💰 Error Budget Math

```
SLO          = %99.9
Window       = 30 days
Total minutes = 30 * 24 * 60 = 43,200 min
Allowed bad  = 43,200 * (1 - 0.999) = 43.2 min
```

So in 30 days you can tolerate **43 minutes** of "bad" time.

### Practical budget management table

| Budget state | Policy |
|---|---|
| > 50% (fresh) | Take risks, deploy aggressively, new features |
| 20-50% | Normal pace |
| 0-20% | Feature freeze; reliability work only |
| < 0% (overspent) | STOP deploying to production; focus on root causes |

> This **must be enforced automatically**. Enforced in code with Argo Rollouts + alertmanager + GitOps
> gating. No manual "we'll keep an eye on it" policy.

---

## 🚨 Multi-Burn-Rate Alerting

The single-window SLO alert problem: either it sees too late (low-burn) or is too sensitive (false positive).

**Solution:** Alert if you see a high burn-rate over two different windows at the same time.

```
FAST burn  = 14.4x   → 5min + 1hour window
                       burns the budget in 2 hours → SEV-1 page
SLOW burn  = 6x      → 1hour + 6hour
                       burns the budget in 5 days → SEV-2 ticket
```

PromQL example:

```yaml
- alert: HighErrorBudgetBurnRate
  expr: |
    (
      (1 - sli:availability:5m) > (14.4 * (1 - 0.999))
      and
      (1 - sli:availability:1h) > (14.4 * (1 - 0.999))
    )
  for: 2m
```

(Full template: [`17-Templates/prometheus-rules/slo-recording-rules.yaml`](../17-Templates/prometheus-rules/slo-recording-rules.yaml))

---

## 📊 What Should Be on the Dashboard?

**At a glance** the following should be visible:

```
┌──────────────────────────────────────────────────────────────┐
│  Service: payments-api          SLO: %99.9 / 30d              │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  Current SLO:    99.94%   ✅                                  │
│  Error Budget:   78%       (33 min / 43 min)                  │
│                                                                │
│  Burn Rate:                                                    │
│    1h     0.4x   (within budget)                              │
│    6h     0.7x                                                 │
│    24h    0.9x                                                 │
│                                                                │
│  ┌────── Burn over 30 days ──────────────────────────────┐    │
│  │ ▁▁▁▂▂▁▁▃▃▃▁▁▁▁▁▂▂▂▁▁▁▁▁▁▁▁▁▁▁                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                │
│  Recent deploys (annotation):  v3.4.0  v3.4.1  v3.4.2          │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

---

## 🎓 Common Mistakes and Their Fixes

### Mistake 1: not "average < 500ms" but "p99 < 500ms"
The average lies. At p99 you catch many more of the bad requests.

```promql
# WRONG
avg(rate(request_duration_seconds_sum[5m])) / avg(rate(request_duration_seconds_count[5m]))

# RIGHT
histogram_quantile(0.99,
  sum by (le) (rate(request_duration_seconds_bucket[5m]))
)
```

### Mistake 2: SLO is only error rate
Latency, freshness, correctness should be SLOs too. If your service is fast but
returns wrong answers, the SLO is green but the customer is unhappy.

### Mistake 3: Cause-based alert
- ❌ `CPU > %80` (CPU may be high but the user is not affected)
- ✅ `error_budget_burn_rate > 14.4x` (real customer impact)

### Mistake 4: Aggregate metric vs per-tenant
In a multi-tenant API your aggregate SLO may be 99.9% but one large tenant
may be 50% unavailable → if you look at the aggregate you won't notice.

```promql
# Per-tenant breakdown
sum by (tenant) (rate(http_requests_total{code!~"5.."}[5m]))
/
sum by (tenant) (rate(http_requests_total[5m]))
```

### Mistake 5: Retro-fitting the SLO
"My current behavior is 99.7%, my target is 99.7%." That's not an SLO, it's a measurement.
The target should always be **close to current but a bit better** (if there's work to be done).

### Mistake 6: Measure close to the customer, not the producer
- ❌ 5xx rate on the app side (timeouts at the load balancer aren't measured at all)
- ✅ On the CDN / API gateway side (what the user sees)

---

## 🚀 Step by Step: Write Your First SLO Today

### 1. Pick your service (start with the critical one)
- Customer-facing
- Failure hurts
- Metrics are already being collected

### 2. List your SLIs
```
- availability  : (1 - error_rate)
- latency        : p99 < 500ms for main request types
- (optional) freshness : data lag < 60s
```

### 3. Measure current performance
The last 30 days via a Prometheus query.

### 4. Set the target
Current + a bit of engineering effort = SLO.

### 5. Write recording + alerting rules
Template: [`17-Templates/prometheus-rules/slo-recording-rules.yaml`](../17-Templates/prometheus-rules/slo-recording-rules.yaml)

### 6. Build the dashboard
Burn-rate, current SLO, budget remaining.

### 7. Publish the error budget policy
Announce the "if budget < 20%, feature freeze" rule to the team **in writing**.
Who will enforce this rule (tooling enforcement + manager approval)?

### 8. Monthly review
- How much of the budget was burned?
- Did the alerts fire correctly?
- Does the SLO target need updating?

---

## 🚫 Anti-Pattern

The table below distills the most common mistakes in SLO practice. Don't do what's on the
left, do what's on the right.

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Target SLO = 100% | Mathematically impossible; error budget = 0, so you can never deploy. | Set it realistically (99.9% for most prod). Spend the budget to take risks. |
| Set SLO equal to current behavior (retro-fit) | "I'm at 99.7%, my target is 99.7%" is a measurement, not a target; the pressure to improve disappears. | Current + a bit of engineering effort = SLO. Keep the target close to current but a bit better. |
| Pick CPU/memory/disk as the SLI | Saturation signal; the user may be unaffected even when CPU is high. | An SLI reflecting customer experience: success rate, latency, freshness. |
| Measure latency with average | The average lies; it hides the bad requests in the tail. | Use p99/p95 percentiles with `histogram_quantile`. |
| Make only error rate the SLO | A fast but wrong/stale answer shows the SLO green while the customer is unhappy. | Fold latency + freshness + correctness into the SLO too. |
| Cause-based alert (CPU > 80%) | Produces false positives; pages without real customer impact. | Symptom-based: alert on error budget burn-rate. |
| Single-window SLO alert | Sees either too late (low-burn) or too sensitively (false positive). | Multi-burn-rate: two windows (fast 14.4x + slow 6x) together. |
| Look at the total/aggregate metric | If one large tenant is 50% down you won't notice in the aggregate. | Measure with per-tenant / per-journey breakdown. |
| SLO per endpoint | A single endpoint may be green but the user journey is broken. | Write the SLO per user journey (the flow chain). |
| Measure on the producer side (app 5xx) | A request that times out at the LB/gateway never reaches the app, isn't measured. | Measure close to the customer: CDN / API gateway side. |
| SLA = SLO (same value) | No buffer; missing the internal target directly violates the customer promise. | Keep the internal SLO tighter than the SLA (SLA 99.5% → SLO 99.7%). |
| Make the error budget policy a manual "we'll keep an eye on it" | Discipline is the first thing to collapse under pressure; gating isn't enforced. | Enforce the policy with tooling (GitOps gating + alertmanager). |
| Pick a window that's too short (7 days) | Noisy; constant false alarms, annoying. | 30-day rolling is standard. Too long (90 days) also makes you notice trouble late. |

---

## 📋 Checklist

All of these must be checked before a service's SLO counts as production-ready.

**SLI definition**
- [ ] SLIs chosen from the customer perspective (not CPU/memory, but success rate / latency)
- [ ] Latency SLI measured with a percentile (p99/p95), not with the average
- [ ] SLIs appropriate to the service category (request/response → availability + latency; data → freshness + correctness)
- [ ] Measurement done at the point closest to the customer (CDN / API gateway), not inside the app
- [ ] At least one SLI defined per user journey (the critical flow's endpoint chain)

**SLO target**
- [ ] Current performance measured over the last 30 days (a real baseline)
- [ ] Target set realistically (cost/need validated against the downtime table)
- [ ] The internal SLO is tighter than the SLA given to the customer (there's a buffer)
- [ ] Window fixed at 30-day rolling
- [ ] If multi-tenant, a per-tenant breakdown query exists

**Error budget & alerting**
- [ ] Error budget math calculated (allowed bad minutes known)
- [ ] Multi-burn-rate alert set up (fast 14.4x → page, slow 6x → ticket)
- [ ] Alerts are symptom-based (burn-rate), not cause-based (CPU)
- [ ] Recording + alerting rules under version control (`<PLACEHOLDER>/slo-recording-rules.yaml`)
- [ ] Deploy gating tied to budget thresholds enforced with tooling (not manual)

**Observability & process**
- [ ] Dashboard shows at a glance: current SLO, budget remaining, burn-rate, deploy annotation
- [ ] Error budget policy written down and announced to the team (budget < 20% → feature freeze)
- [ ] Clear who/what enforces the policy (tooling enforcement + manager approval)
- [ ] Monthly SLO review on the calendar (budget burn, alert accuracy, target update)

---

## 📚 Further Reading

- *Site Reliability Engineering* (Google SRE Book) — chapter 4
- *The Site Reliability Workbook* — chapter 2
- [SRE Book online](https://sre.google/sre-book/service-level-objectives/) — free
- [Awesome SLO](https://github.com/awesome-slo/awesome-slo) — practical examples
- [`17-Templates/prometheus-rules/slo-recording-rules.yaml`](../17-Templates/prometheus-rules/slo-recording-rules.yaml) — ready-made rules in this repo

---

## 📚 References

- [SLO Engineering](../07-Observability/SLO-Engineering.md) — putting the SLO on a measurement foundation, recording rule practice
- [Alerting Done Right](../07-Observability/Alerting-Done-Right.md) — symptom-based alerting, setting up burn-rate alarms without noise
- [Prometheus Best Practices](../07-Observability/Prometheus-Best-Practices.md) — metric design and histogram use for SLI queries
- [Incident Response](Incident-Response.md) — incident management that kicks in when the error budget is exhausted
- [Postmortem Practice](Postmortem-Practice.md) — drawing blameless lessons from budget-burning incidents
- [Prometheus documentation](https://prometheus.io/docs/) — the official PromQL and alerting reference

---

> *"An SLI that doesn't measure what the customer feels is noise; an error budget that doesn't stop deploys when consumed is just dashboard decoration."*

---

> 🎓 **Learning Path:** This document is used as a "Read first" resource in the [`E1`](../22-Learning-Path/block-e-ownership/E1-sli-slo-error-budget.md) module.
