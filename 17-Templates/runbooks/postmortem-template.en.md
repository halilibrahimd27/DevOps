---
description: "Blameless postmortem template: TL;DR, impact metrics, UTC timeline, root cause, defense layers, owner-assigned action items, and lessons learned."
tags:
  - Template
  - Incident Response
  - SRE
  - DORA
---
# Postmortem: <INCIDENT TITLE>

> **Status:** Draft / Under Review / Final
> **Date:** YYYY-MM-DD
> **Author:** @author-handle
> **Reviewers:** @reviewer1, @reviewer2

---

## TL;DR (3 sentences)

*(What happened, how long it lasted, what the impact was.)*

Example: **Between 2026-04-30 14:02–14:16 UTC payment-service became
unavailable. The root cause was an accidental N+1 query on a new endpoint. Over
14 minutes roughly 3,200 payments failed, with an estimated ~22k EUR of potential
revenue impact.**

## 🎯 Impact

| Metric | Value |
|---|---|
| Total downtime | XX minutes |
| Affected users | ~XXX |
| Failed transactions | ~XXX |
| Revenue impact (estimate) | ~XX,XXX EUR |
| SLO impact | Ate X% of error budget |
| Customer complaints | X (zendesk ticket) |

## ⏱️ Timeline (UTC)

> This part must have **precise detail**. Not "around 14:00" but
> "14:02:34". Take it from PagerDuty/Slack timestamps.

| Time | Event |
|---|---|
| 14:00 | Deploy v3.4.1 started (PR #4521 — `<COMMIT_SHA>`) |
| 14:02 | Deploy completed, 100% prod traffic on v3.4.1 |
| 14:05 | In Datadog p99 latency jumped 200ms → 8s; SLO burn-rate alert firing |
| 14:07 | On-call (@alice) got paged from PagerDuty, in the `#incident-payments` channel |
| 14:10 | Incident commander (@alice), comms lead (@bob) assigned |
| 14:11 | Rollback command run (`kubectl rollout undo`) |
| 14:13 | Traffic 50% v3.4.0 / 50% v3.4.1, latency stabilization began |
| 14:16 | Rollback completed, latency back to normal |
| 14:30 | All-clear, incident closed |
| 15:00 | Postmortem ticket opened |

## 🔍 Root Cause

> *Explain the system, not the person.*

The newly added `/payments/:id/full-receipt` endpoint was firing 50 extra SQL
queries per payment because of the ORM's lazy-loading feature (the N+1 problem).
In production, against prod-tier RPS load:
- DB connection pool was exhausted
- App connection acquisition timeout (10s)
- Liveness probe fail → pod restart loop

In staging, which lacks production-like data volume, this pattern didn't
manifest (staging fixture is 10 rows vs prod 50 rows).

## 🛡️ Why wasn't it caught?

Not a single failure — every one of the **defense layers** had a hole:

1. **Code review** — the N+1 pattern wasn't spotted in the PR (reviewer @charlie didn't know the ORM lazy-load behavior)
2. **Lint/CI** — no N+1 detector in the pipeline
3. **Load test** — only tested at 100 RPS; N+1 blows up at 5000 RPS
4. **Staging** — fixture data volume is 0.0001% of prod's
5. **Canary deploy** — went straight to 100% prod, there was no 5% ramp

## ✅ What went well?

- ⚡ Automatic rollback triggered within **4 minutes** of getting paged from PagerDuty
- 📞 Incident channel auto-creation worked, the right people arrived in one go
- 🔁 The ArgoCD rollback command is a one-liner in the engineer's hands
- 📊 The SLO burn-rate alert fired from the cause, not the symptom (early signal)

## ⚠️ What didn't go well?

- Status page wasn't updated (customer comms missing)
- Manual rollback was required (there was no automatic one)
- During the incident 4 separate threads ran in parallel in the `#incident-payments` channel (confusing)

## 🎬 Action Items

> Every item must have an **owner**, a **due date**, and be **measurable**.
> Promises like "let's be more careful" are not accepted.

| # | Action | Owner | Due | Status |
|---|---|---|---|---|
| 1 | Raise the load test to 1000 RPS + sustained 30 min | @alice | 2026-05-15 | Open |
| 2 | Add an ORM N+1 detector (n-plus-one query analyzer) to the PR pipeline | @bob | 2026-05-22 | Open |
| 3 | Scale staging fixture data volume to 1% of prod's | @platform-team | 2026-06-01 | Open |
| 4 | Canary deploy strategy: 5% → 25% → 100% mandatory (Argo Rollouts) | @platform-team | 2026-06-01 | Open |
| 5 | Add a "who updates the status page?" line to the incident response playbook | @comms-lead | 2026-05-08 | Open |
| 6 | Document the thread rule in `#incident-*` channels (single thread, lock by IC) | @docs | 2026-05-08 | Open |

## 📊 Links to metric evidence

- [Datadog dashboard - payment-service](https://example.com/datadog/...)
- [PagerDuty incident #INC-12345](https://example.com/pd/...)
- [Slack timeline export](https://example.com/slack/...)
- [PR that caused it: #4521](https://github.com/.../pull/4521)
- [Rollback PR: #4534](https://github.com/.../pull/4534)

## 💡 Lessons Learned

> *A general lesson. Don't write "person X was careless". Write "X wasn't visible in our system".*

1. **Staging's proportion to prod matters** — not just the schema, the **data volume too** must be prod-like.
2. **N+1 slips past code review** — automatic detection is a checkpoint.
3. **Canary deploy isn't a guard, it's a requirement** — especially for DB-backed endpoints.
4. **Automatic rollback is gold** — manual intervention turns 4 minutes into 14 minutes.

## 👥 Postmortem participants

- @alice (incident commander)
- @bob (comms lead)
- @charlie (code author)
- @platform-team
- @engineering-manager

---

> 📝 This postmortem was written on **blameless** principles. The intent: the
> whole team learning from the system, not blaming a person. The issue is not @charlie
> writing "wrong" code; it's the absence of an N+1 detector in our review.
