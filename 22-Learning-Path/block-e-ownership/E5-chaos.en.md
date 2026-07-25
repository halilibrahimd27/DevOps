---
description: "Advanced broken lab / chaos: break the system in a controlled way and prove its resilience — game day."
level: E
module: E5
estimated_hours: 12
prerequisites: [E3, D2]
tags: [Learning Path, SRE, Chaos]
---
# E5 — Advanced Broken Lab / Chaos

> *"If you don't know how your system breaks, you don't know it's reliable — you only know it hasn't broken yet."*

**Block:** E — Ownership · **Duration:** ~12h · **Prerequisite:** [`E3`](E3-incident-postmortem.md), [`D2`](../block-d-orchestration/D2-k8s-production.md)

## 🎯 When you finish this module
- You'll inject a failure in a controlled way (blast radius limited).
- You'll run a game day, applying the hypothesis → experiment → observation loop.
- You'll turn the weakness you found into an action item and (if applicable) a new alert.

## 🧠 Why this, why now
In E1–E4 you measured the system, alerted on it, managed an incident, and restored it.
E5 does this proactively: instead of waiting for a failure, you induce one yourself, in a
controlled way. This is the last ownership exam before the E → F transition.

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`11-SRE/Chaos-Engineering.md`](../../11-SRE/Chaos-Engineering.md) | chaos principles + game day | ~30 min |
| [`11-SRE/Capacity-Planning.md`](../../11-SRE/Capacity-Planning.md) | load/capacity link | ~20 min |

## 💥 Broken lab
👉 [`labs/broken/K09-chaos-gameday/`](../labs/broken/K09-chaos-gameday/README.md) — A multi-failure,
hypothesis-driven game day; blast radius limited, observation and learning at the center.

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] A failure with limited blast radius (e.g., dropping a Pod/dependency) was injected and its impact observed — metric/log evidence
- [ ] The game day was written up as a hypothesis → experiment → result report
- [ ] The experiment's outcome was tied to an action: a weakness that was found got turned into an action item/alert **or** (if no weakness surfaced) it's documented which evidence now tracks/protects the confirmed resilience
- [ ] `bash labs/broken/K09-chaos-gameday/verify.sh` passes with zero errors after the fix

## 🧪 Test yourself
1. What's the one thing that must be written before starting a chaos experiment?
2. What does "limiting the blast radius" mean in practice?
3. Is a game day that passes without anything breaking a failure?

<details><summary>Answers</summary>

1. A hypothesis: "If X fails, the system stays up without breaking in way Y." An experiment without a hypothesis is just poking around — without a measurable expectation you can't interpret the result. Principles are in [`11-SRE/Chaos-Engineering.md`](../../11-SRE/Chaos-Engineering.md).
2. Confining the experiment to the smallest safe scope: a single replica, a single namespace, a low-traffic window, and a ready rollback. The goal is to learn, not to hit real users.
3. No — if you confirmed your hypothesis (the system held up as expected), that's valuable evidence. But if no weakness ever surfaces, the experiment may be too small; grow the scope in a controlled way. Capacity link is in [`11-SRE/Capacity-Planning.md`](../../11-SRE/Capacity-Planning.md).
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| The experiment hit real users | Blast radius wasn't limited | Shrink the scope (single replica/namespace), run it at low traffic with a rollback ready |
| The result can't be interpreted | There was no hypothesis | Write "my expectation is X" first, then inject; measure the deviation |
| The finding got lost | No report/action item | Write the game day up in hypothesis→result format; tie the weakness to an action/alert |
| The same failure was a surprise again | The learning never became an alert | Add an E2-style alert for the weakness you found |

## 💼 Portfolio output
A game day report (hypothesis, experiment, finding, action) — mature evidence of ownership.

## ⏭️ Up next
Block E is done → **gate project**: [`Capstone 3`](../capstones/CAP3-blok-e-sonu.md).
Then [`F1 — Cost (FinOps)`](../block-f-judgment/F1-maliyet-finops.md).

---

> *"Chaos isn't about breaking the system; it's about learning where it's fragile, on a safe day."*
