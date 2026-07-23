---
description: "Cost and trade-off (FinOps): looking at the same systems through the lens of money — the first step of the third look."
level: F
module: F1
estimated_hours: 10
prerequisites: [C4, D2]
tags: [Learning Path, FinOps]
---
# F1 — Cost and Trade-off (FinOps)

> *"You looked at the same cluster in D for how it works; in F you're looking at what it costs."*

**Block:** F — Judgment · **Duration:** ~10h · **Prerequisite:** [`C4`](../block-c-reproducibility/C4-bulut-butce-alarmi.md), [`D2`](../block-d-orchestration/D2-k8s-production.md)

## 🎯 When you finish this module
- You break down a workload's cost into its components (compute, storage, network/egress) and calculate them.
- You justify a trade-off like right-sizing / spot / reserved with numbers.
- You defend a cost decision in both engineering and business language.

## 🧠 Why this, why now
This block isn't a continuation of A–E, it's the **third look.** The same systems
are now viewed through the lens of money. In C4 you set up the budget alert; F1
turns that awareness into a decision discipline.

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`12-FinOps/README.md`](../../12-FinOps/README.md) | cost axes: compute / storage / egress, unit cost | ~30 min |
| [`12-FinOps/Right-Sizing.md`](../../12-FinOps/Right-Sizing.md) | tying D2's request/limit to the bill, over-provisioning | ~25 min |
| [`12-FinOps/Spot-Instance-Strategy.md`](../../12-FinOps/Spot-Instance-Strategy.md) | spot / reserved / on-demand trade-off | ~20 min |

## 🔨 Deliverable exercise
This module isn't pure reading; its output is a written analysis. Pick a workload — the
application you ran in D2, or your [`Capstone 1`](../capstones/CAP1-blok-c-sonu.md)/[`Capstone 2`](../capstones/CAP2-blok-d-sonu.md) system. Write `finops-analiz.md`:
1. Break the cost into three axes (compute, storage, network/egress) — with scenario values, not a real bill.
2. Calculate a unit cost (per 1000 requests or GB-month) — write down your assumptions.
3. Propose one optimization (right-sizing / spot / storage class) and show the savings as an **absolute difference** (before → after).
4. Defend the same decision to the business side in one paragraph (technical + business language).

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] `finops-analiz.md` has a table that breaks cost into three axes (compute / storage / egress)
- [ ] A unit cost was calculated with a number, and the assumptions behind it are written down
- [ ] An optimization proposal is justified with before → after absolute difference (not percentage, an absolute number)
- [ ] The same decision is defended in business language in a separate "Business side" paragraph inside `finops-analiz.md` (monthly cost + downtime/risk outcome — not just technical terms)

## 🧪 Test yourself
1. Why does the egress bill surprise you while compute cost stays constant, and how do you narrow it down?
2. A service uses one-eighth of its CPU but has 2 vCPU reserved. What are your first three checks?
3. For a night-running, interruption-tolerant batch job, which would you pick among spot / on-demand / reserved, and why?

<details><summary>Answers</summary>

1. Egress is priced separately in most clouds, and intra-cluster/cross-AZ/internet-egress traffic is billed differently; if a service sends too much data out, the bill balloons even if compute stays constant. Narrowing it down: data localization, caching, compression — [`12-FinOps/Egress-Cost-Reduction.md`](../../12-FinOps/Egress-Cost-Reduction.md).
2. Measure actual usage (D2's metrics / `kubectl top`), bring the request closer to actual usage, then review the node type/count. Right-sizing requires measurement first — [`12-FinOps/Right-Sizing.md`](../../12-FinOps/Right-Sizing.md).
3. Spot: the cheapest option for interruption-tolerant, restartable work, where the job's design absorbs the interruption risk. On-demand wants flexibility, reserved is for predictable continuous load. Batch + tolerant → spot makes sense — [`12-FinOps/Spot-Instance-Strategy.md`](../../12-FinOps/Spot-Instance-Strategy.md).
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| You can't break the cost into axes | You're looking at a single total number | Split the bill into compute / storage / network; write each on a separate line |
| "Savings" is stated without a number | Before/after wasn't measured | Write the cost before and after the change separately, show the difference as an absolute number |
| Right-sizing is done by guesswork | Actual usage wasn't measured | Go back to the metrics (B2/D2); set the request based on p95 usage, not a guess |
| The business side isn't convinced | Only technical language was used | Translate the decision into a business outcome like "X units per month, risk Y downtime" |

## 💼 Portfolio output
A cost analysis + optimization proposal — proof of L2 decision-making.

## ⏭️ Up next
[`F2 — Threat Modeling + Compliance`](F2-tehdit-uyum.md)

---

> *"It's not the cheapest architecture that wins, it's the architecture chosen with a knowingly right trade-off."*
