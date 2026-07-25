---
description: "SLI / SLO / error budget: defining a system's 'good enough' with a number — ownership starts here."
level: E
module: E1
estimated_hours: 12
prerequisites: [B2, D2]
tags: [Learning Path, SRE]
---
# E1 — SLI / SLO / Error Budget

> *"The engineering answer to 'is the system healthy?' comes from a number, not a feeling."*

**Block:** E — Ownership · **Duration:** ~12h · **Prerequisite:** [`B2`](../block-b-visibility/B2-metrik-prometheus.md), [`D2`](../block-d-orchestration/D2-k8s-production.md)

## 🎯 When you finish this module
- Choose a meaningful SLI (indicator) for a service and defend why you chose it.
- Set an SLO (target) and calculate the error budget.
- Explain what changes when the error budget runs out (does the release freeze).

## 🧠 Why this, why now
You set up metrics in B2 and production settings in D2. E1 turns these metrics into
an **ownership contract**: you define what "good enough" means.
The budget isn't fixed: how fast it burns is called **burn rate** —
how many times the normal rate you're spending it at. The alerting in E2 is built
on top of these SLOs and burn rate.

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`11-SRE/SLI-SLO-Error-Budget.md`](../../11-SRE/SLI-SLO-Error-Budget.md) | concept + math | ~35 min |
| [`07-Observability/SLO-Engineering.md`](../../07-Observability/SLO-Engineering.md) | putting it into practice | ~25 min |

## 🔨 Lab
👉 [`labs/build/L18-sli-slo/`](../labs/build/L18-sli-slo/README.md)

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] An SLI was chosen for a service (e.g. request success rate) and is measured in Prometheus — evidence via query/panel output
- [ ] An SLO for this SLI (e.g. 30-day 99.9%) and the corresponding error budget (min/month) were calculated in writing
- [ ] What changes when the error budget runs out (does the release freeze, what gets prioritized) was defended in writing in one sentence

## 🧪 Test yourself
1. Roughly how many minutes is the error budget for a monthly 99.9% SLO, and what does that budget "buy"?
2. Why do you measure "did the user's request succeed" instead of "is the server up" for an availability SLI?
3. 80% of the error budget was burned by day 10 of the month. Should the team ship faster or slower — why?

<details><summary>Answers</summary>

1. 99.9% → 0.1% a month → ~43 min for 30 days. This budget is a share you consciously spend on planned risk (releases, experiments); instead of aiming for zero, you deliberately spend down what's left. The math is in [`11-SRE/SLI-SLO-Error-Budget.md`](../../11-SRE/SLI-SLO-Error-Budget.md).
2. Because the user cares whether their request worked, not whether the server is up. If the server is `Running` but returning 500s, the "server is up" SLI says healthy while the user is unhappy — the SLI must be tied to user experience. Covered in [`07-Observability/SLO-Engineering.md`](../../07-Observability/SLO-Engineering.md).
3. Slow down. When the budget is close to running out, risk appetite drops: releases freeze, priority shifts to reliability. When the budget is plentiful, you can speed up instead — an SLO is a speed↔reliability negotiation, not a feeling.
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| SLI always shows 100% | You're measuring the wrong thing (health-check) | Measure the outcome of real user requests; a synthetic probe alone isn't enough |
| Error budget calculation doesn't add up | Window/ratio mismatch (weekly↔monthly) | Pick a fixed window (e.g. 30-day rolling), convert the ratio to match |
| Team doesn't buy into the SLO | Target is arbitrary, no tie to users | Measure current performance, set the target at that +a bit; write down user impact |

## 💼 Portfolio output
A written SLI/SLO definition + error budget calculation for a service.

## ⏭️ Up next
[`E2 — Alerting + On-Call`](E2-alerting-oncall.md)

---

> *"100% uptime isn't a goal, it's an illusion; the error budget turns that illusion into a budget."*
