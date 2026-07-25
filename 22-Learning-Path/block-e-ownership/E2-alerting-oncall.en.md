---
description: "Alerting + on-call discipline: what counts as an alert, what counts as noise, and a sustainable on-call rotation."
level: E
module: E2
estimated_hours: 12
prerequisites: [E1, B1]
tags: [Learning Path, SRE]
---
# E2 — Alerting + On-Call Discipline

> *"Putting an alert on everything is putting an alert on nothing — either way, you get woken up tonight or you don't."*

**Block:** E — Ownership · **Duration:** ~12h · **Prerequisite:** [`E1`](E1-sli-slo-error-budget.md), [`B1`](../block-b-visibility/B1-log-okuma.md)

## 🎯 When you finish this module
- You set up an alert tied to an SLO that's actionable.
- You distinguish noisy alerts from real ones, cutting down alert fatigue.
- You explain what a sustainable on-call rotation looks like.

## 🧠 Why this, why now
In E1 you defined "good enough"; E2 sets up **who** gets notified **when**
that threshold is crossed. This module's alert rules are written on top of the
Prometheus/PromQL you set up in B2 (E1 already lists B2 as a prerequisite —
you can't alert on a metric you can't measure). The incident response in E3
is triggered by these alerts.

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`07-Observability/Alerting-Done-Right.md`](../../07-Observability/Alerting-Done-Right.md) | actionable alerting | ~30 min |
| [`00-Culture/On-Call-Playbook.md`](../../00-Culture/On-Call-Playbook.md) | on-call discipline | ~25 min |

## 🔨 Lab
👉 [`labs/build/L19-alerting/`](../labs/build/L19-alerting/README.md)

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] An alert rule tied to an SLO was written, fired, and resolved at least once — proven via Alertmanager (Prometheus's component that groups/routes/silences alerts; you set it up in L19) or dashboard output (don't write the PromQL from thin air: L19's README **Task 1** walks step by step through which rule to write — error rate crossing the threshold within 1 minute)
- [ ] At least one "noisy alert" example was documented, along with why it was silenced/removed
- [ ] Every alert was classified against the "should this wake someone at 3am?" test (page / ticket / log) — written as a table
- [ ] It's documented in writing who an unresolved alert escalates to, and when

## 🧪 Test yourself
1. "CPU at 80%" vs. "error rate burning the error budget within 1 hour" — which one should page, and why?
2. What does alert fatigue break, and how do you measure it?
3. An alert fires but there's no runbook. Is the first fix to silence the alert?

<details><summary>Answers</summary>

1. The second one. CPU at 80% can be a symptom, but on its own it doesn't demand action (cause-based, frequently noisy); "the budget is burning at this rate" is tied to user impact and is actionable (symptom-based). The distinction is covered in [`07-Observability/Alerting-Done-Right.md`](../../07-Observability/Alerting-Done-Right.md).
2. It causes real alerts to get lost in the noise — the on-call responder stops paying attention. Measure it via the action-conversion rate per alert; if a lot get "acked (acknowledged) and closed" but few turn into actual action, the alert is noise. (Ack = the acknowledgment that you've seen the alert and are taking it on.)
3. No. Silencing it just hides the symptom. First check whether it's actionable: if it isn't, fix or remove the rule; if it is, write a runbook. Silencing is only valid when it's deliberate, time-boxed, and leaves an audit trail. On-call discipline is covered in [`00-Culture/On-Call-Playbook.md`](../../00-Culture/On-Call-Playbook.md).
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| On-call gets woken up every night | Too many page-level alerts | Page only what's user-impacting/actionable, drop the rest to tickets |
| Alert fires, nobody knows what to do | No runbook/action defined | Attach a single "first step" runbook to every page alert |
| A real outage was missed | Drowned out in noise | Run an alert audit; remove non-actionable rules, tie thresholds to the SLO |
| An alert was forgotten before it was resolved | No escalation chain | Define ack + time-boxed escalation; tie silencing to an audit trail |

## 💼 Portfolio output
A set of SLO-tied alert rules + your on-call notes.

## ⏭️ Up next
[`E3 — Incident + Postmortem`](E3-incident-postmortem.md)

---

> *"A good alert doesn't ask a question, it states an action."*
