---
description: "Index for the Site Reliability Engineering module: SLI/SLO/error budget, incident response, runbook, chaos engineering, capacity, toil, and postmortem."
tags:
  - SRE
  - Observability
  - Incident Response
  - Roadmap
---
# 11 · Site Reliability Engineering

> *"If we don't engineer reliability as a feature, we can't guarantee
> it — we can only hope for it."* — Google SRE Book

Built on SLI / SLO / Error Budget, with a *toil minimization* approach.

## Contents

| File | Topic |
|---|---|
| [`SLI-SLO-Error-Budget.md`](SLI-SLO-Error-Budget.md) | SLI selection, SLO math, error budget policy |
| [`Incident-Response.md`](Incident-Response.md) | IC role, severity matrix, communication tree, comms runbook |
| [`Runbook-Template.md`](Runbook-Template.md) | Template for "what to do when this alert fires" |
| [`Chaos-Engineering.md`](Chaos-Engineering.md) | GameDay → continuous chaos, using Litmus/Chaos Mesh |
| [`Capacity-Planning.md`](Capacity-Planning.md) | Demand forecasting, headroom, load test framework |
| [`Toil-Reduction.md`](Toil-Reduction.md) | Toil definition, measurement, the 50% rule |
| [`Postmortem-Practice.md`](Postmortem-Practice.md) | How to turn blameless postmortems into routine |

## SRE's "sacred book"

```
SLI:   Service Level Indicator      → what we measure
SLO:   Service Level Objective      → which target
SLA:   Service Level Agreement      → promise to the customer
EB:    Error Budget = 1 - SLO       → how much failure we tolerate
Toil:  manual + repetitive + non-value work, targeted at < 50%
```

## Error Budget Policy (example)

| Budget status | Policy |
|---|---|
| Budget > 50% | Take risks, deploy aggressively, push new features |
| Budget 20-50% | Normal pace, standard guardrails |
| Budget 0-20% | Feature freeze; reliability improvements only |
| Budget < 0 (overspent) | All prod deploys stop; focus on the failure's root cause |

> This policy **must be enforced automatically** — no manual "we'll hold
> the line" promises. It's enforced in code via Argo Rollouts +
> alertmanager + GitOps gating.

## Incident severity matrix (example)

| Sev | Definition | Target MTTR | Who gets paged? |
|---|---|---|---|
| **SEV-1** | Customer-impacting outage, revenue down | < 1 hour | On-call IC + manager + leadership |
| **SEV-2** | Major feature broken, affects a subset of users | < 4 hours | On-call IC |
| **SEV-3** | Minor feature broken, workaround exists | Next business day | Ticket, not on-call |
| **SEV-4** | Cosmetic, internal tool | Backlog | None |

## Anti-patterns

- ❌ "100% uptime" SLO (mathematically impossible, 99.99% is enough)
- ❌ Avg latency SLI (use median/p99 instead)
- ❌ No postmortems — the same incident repeats 3 months later
- ❌ A "hero" engineer who's always the one handling incidents (bus factor 1)
- ❌ Runbooks left in a wiki, no link from the alert
- ❌ Chaos engineering as "we'll do it later" — it's the only way to build confidence in production
