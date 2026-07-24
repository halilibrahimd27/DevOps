---
description: "Two frameworks for engineering performance: the DORA 4 delivery metrics (deploy frequency, lead time, MTTR, change failure) and the holistic SPACE model."
tags:
  - Culture
  - DORA
  - SRE
  - Performance
---

# DORA & SPACE — Engineering Performance Metrics

> *"You can't improve what you don't measure; but measuring the wrong thing will drown your team."*

Two frameworks: one focused on **delivery performance** (DORA), the other **holistic** (SPACE).
Used together.

---

## 📊 DORA — The 4 Key Metrics

From Google's "Accelerate State of DevOps Report." It measures **delivery
performance** — i.e., how a team ships code.

### 1. Deployment Frequency

> How often do you deploy to production?

| Level | Frequency |
|---|---|
| Elite | N times per day (on-demand) |
| High | Daily-weekly |
| Medium | Weekly-monthly |
| Low | Monthly-yearly |

**How is it measured:**
```
deploys / day  =  count(merge_to_main) / days_in_period
                  (successful deploys only)
```

### 2. Lead Time for Changes

> How long from first commit to production?

| Level | Duration |
|---|---|
| Elite | < 1 hour |
| High | 1 day – 1 week |
| Medium | 1 week – 1 month |
| Low | 1 – 6 months |

**How is it measured:**
```
lead_time = deploy_timestamp - first_commit_in_PR_timestamp
```

Track p50, p95 (averages lie).

### 3. Change Failure Rate (CFR)

> What fraction of deploys required a **rollback** or a **hotfix**?

| Level | Rate |
|---|---|
| Elite | 0-15% |
| High | 16-30% |
| Medium | 16-30% |
| Low | 46-60% |

**How is it measured:**
```
CFR = failed_deploys / total_deploys
```

"Failed deploy" definition:
- Required a rollback
- A hotfix PR was merged within hours
- Caused a customer-facing incident

### 4. Mean Time to Restore (MTTR)

> How long after an incident starts does it take to resolve?

| Level | Duration |
|---|---|
| Elite | < 1 hour |
| High | < 1 day |
| Medium | 1 day – 1 week |
| Low | 1 week – 1 month |

**How is it measured:**
```
MTTR = avg(incident_resolved - incident_started)
```

p50 + p95.

---

## 🎯 Moving between DORA levels — in practice

### Low → Medium

**Main bottlenecks:**
- Manual deploy, manual testing
- Branches live for months
- "Deploy day" is extra stress

**Fixes:**
- Automated CI/CD (basic)
- Move to trunk-based development
- Automated unit + integration tests
- Staging environment

### Medium → High

**Main bottlenecks:**
- Manual approval bottlenecks
- Slow test suite
- Rollback is manual and slow

**Fixes:**
- Feature flags (deploy ≠ release)
- Automatic deploy (dev → staging)
- Fast CI (parallel + cache)
- Automatic rollback

### High → Elite

**Main bottlenecks:**
- Production deploy is still an "event"
- E2E tests take 30+ min
- Incident response is manual

**Fixes:**
- Continuous Deployment to prod (every commit)
- Progressive delivery (canary, feature flags)
- Automated incident response (runbook automation)
- SLO-driven deploy (freeze once the error budget runs out)

---

## 🌟 The SPACE Framework — Holistic Productivity

DORA is focused on "delivery"; **SPACE is holistic**:

| Letter | Stands for | Example metric |
|---|---|---|
| **S** | atisfaction & well-being | Survey: "How satisfied are you with your job?", burnout index |
| **P** | erformance | Defect rate, customer satisfaction (NPS), eval score |
| **A** | ctivity | Number of commits, PRs, deploys |
| **C** | ommunication & collaboration | Code review time, doc PRs, mentoring hours |
| **E** | fficiency & flow | Uninterrupted work time, context switches, focus time |

### Why SPACE?

DORA alone is incomplete:
- High activity **isn't** productivity ("more commits" → small, meaningless commits)
- Short lead time can be a burnout signal
- Low CFR means the team isn't taking risks (no innovation)

SPACE's 5 dimensions give you a **balanced** picture.

### Important principle: don't judge by a single metric

> 🚫 **Don't:** "This team only made 5 commits this week, that's bad performance"
>
> ✅ **Do:** "Activity dropped; the 'blocked by docs' percentage rose in the
> survey, let's measure review times — it might be a flow problem"

A single metric can be gamed; multiple metrics show the **real pattern**.

---

## 📈 How do I track this at the team level?

### Tooling
- **Automated DORA metrics:** `dora-team/four-keys` on GitHub (Google), Sleuth, LinearB, Faros
- **SPACE survey:** quarterly 5-min survey; Culture Amp, Lattice, custom Google Form

### Dashboard
```
┌────────────── Engineering Performance ──────────────┐
│                                                       │
│  Q1 2026                  prev Q  current Q  trend    │
│                                                       │
│  Deployment frequency     8/day   12/day     ↑        │
│  Lead time (p50)          4h      2h         ↑        │
│  CFR                      14%     11%        ↑        │
│  MTTR (p50)               45min   38min      ↑        │
│                                                       │
│  ─── SPACE survey (n=42) ───                         │
│  Satisfaction             7.8/10  7.2/10     ↓ ⚠️    │
│  Communication score      8.1/10  8.0/10     ─        │
│  Focus time/day           4.2h    3.5h       ↓ ⚠️    │
│                                                       │
└──────────────────────────────────────────────────────┘
```

> ⚠️ **Anti-pattern:** looking only at DORA and saying "everything's fine."
> Here satisfaction and focus are trending down — DORA's improvement
> may not be sustainable.

---

## 🚫 DORA/SPACE anti-patterns

### "Vanity metrics"
- ✅ "Deploy frequency 12/day" — meaningful
- ❌ "Total commits 5,234 this quarter" — meaningless

### "Gaming the metrics"
- Artificially inflating deploy frequency by adding trivial unit-test commits
- Not counting hotfixes as "incidents" → artificially low CFR

### "Comparison across teams"
- ❌ "Payments team deploys 8x/day, growth team 2x/day — payments is better"
- ✅ Different contexts (regulatory, scale) — each team judged by its own trend

### "Manager-only dashboard"
- If the team can't see it, they don't own the data
- If only upper management sees it: creates a "we're under surveillance" feeling

### "Quarterly review only"
- A dashboard glanced at once a month and forgotten produces no value
- Weekly trend → small corrections

---

## 🎓 Set up your first DORA dashboard (1 week)

```
Day 1-2: Collect deploy events from GitHub Actions / GitLab CI
         (a webhook on every successful deploy → BigQuery / DataDog)

Day 3:   For lead time: PR's first commit timestamp + deploy timestamp

Day 4:   Identify the incident source (PagerDuty webhook → DB)
         For CFR: deploy → incident correlation

Day 5:   Grafana dashboard with 4 panels
         - Deploy frequency (per day)
         - Lead time p50/p95 (rolling 7d)
         - CFR (rolling 30d)
         - MTTR p50/p95

Day 6:   Review with the team — is it meaningful? Anything missing?

Day 7:   Set up a weekly automated post of the dashboard to the team channel
```

---

## 📋 Checklist — production-ready measurement system

Don't consider the dashboard "done" — until the items below are complete, the data isn't trustworthy.

**Data collection**
- [ ] All 4 DORA metrics are collected automatically (NO manual Excel — manual data goes stale and is unreliable)
- [ ] Deploy events come from a single source of truth (CI pipeline), no manual marking
- [ ] The "failed deploy" definition is written down and team-approved (rollback + hotfix + incident-correlation)
- [ ] The incident source (PagerDuty/Opsgenie/issue) is automatically correlated with deploys
- [ ] Lead time measurement starts from the first commit timestamp (not from PR open)

**Statistical quality**
- [ ] p50 + p95 are reported for lead time and MTTR, not the average (averages hide outliers)
- [ ] Metrics are shown with a rolling window (7d / 30d), not a single snapshot
- [ ] Sample size is stated for low-volume teams (n<10 deploys → don't interpret the trend)

**SPACE balance**
- [ ] At least one SPACE dimension (satisfaction/focus) is measured regularly alongside DORA
- [ ] Burnout/satisfaction trends are tracked alongside speed metrics (speed ↑ + satisfaction ↓ = red flag)
- [ ] No decision rests on a single metric; at least two signals are cross-checked

**Access and cadence**
- [ ] The dashboard is open to the whole team (not just managers — that creates a feeling of surveillance)
- [ ] A weekly automated summary is posted to the team channel (not quarterly)
- [ ] Metrics are used for each team's own trend, NOT for cross-team comparison
- [ ] No secrets/credentials in dashboard URLs (`<GRAFANA_URL>`, `<WEBHOOK_SECRET>` kept in env)

**Action loop**
- [ ] An owner + action is defined for every negative trend (just showing a red arrow isn't enough)
- [ ] Metric review is part of the retro — data turns into conversation

---

## 📚 Further reading

- [DORA — State of DevOps Report](https://dora.dev) (annual)
- [SPACE Framework paper](https://queue.acm.org/detail.cfm?id=3454124) — Microsoft Research
- *Accelerate* — Forsgren, Humble, Kim (the scientific basis for DORA)
- [Four Keys project (Google)](https://github.com/dora-team/fourkeys) — open-source DORA dashboard

---

## 📚 References

- [SLI / SLO / Error Budget](../11-SRE/SLI-SLO-Error-Budget.md) — connects MTTR and CFR to error budgets; deploy-freeze logic comes from here
- [SLO Engineering](../07-Observability/SLO-Engineering.md) — the practice of moving DORA metrics into an SLO dashboard
- [Incident Response](../11-SRE/Incident-Response.md) — the response flow and runbook automation for lowering MTTR
- [Blameless Postmortem Template](Blameless-Postmortem-Template.md) — for turning CFR/MTTR data into learning instead of blame
- [DORA — State of DevOps](https://dora.dev) — the source of the metrics and the annual benchmarks

---

> *"DORA's four metrics measure speed and stability; SPACE balances those numbers against gaming and burning out the team — whoever watches only one metric breaks not what they measure, but their team."*
