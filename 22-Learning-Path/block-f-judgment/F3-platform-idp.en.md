---
description: "Platform, IDP, and Team Topologies: solving developer pain like a product — before designing the platform."
level: F
module: F3
estimated_hours: 10
prerequisites: [D5, F1]
tags: [Learning Path, Platform-Engineering]
---
# F3 — Platform, IDP, Team Topologies

> *"A platform built without knowing who suffers which pain is a product nobody asked for."*

**Block:** F — Judgment · **Duration:** ~10h · **Prerequisite:** [`D5`](../block-d-orchestration/D5-gitops-argocd.md), [`F1`](F1-maliyet-finops.md)

## 🎯 When you finish this module
- You can tell when a "platform" is a real need and when it's a premature abstraction.
- You can discuss cross-team cognitive load using Team Topologies concepts.
- You can define the concrete pain an internal developer platform (IDP) needs to solve.

## 🧠 Why this, why now
Through D5 you built and operated the systems yourself; in F1 you looked at them
through the lens of cost. F3 changes the question: how do you make this work
repeatable **for others**? But you don't design a platform before feeling
developer pain — see [`NOT-YET.md`](../NOT-YET.md).

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`13-Platform-Engineering/Platform-as-Product.md`](../../13-Platform-Engineering/Platform-as-Product.md) | seeing the platform as a product, user = developer | ~30 min |
| [`13-Platform-Engineering/Golden-Paths.md`](../../13-Platform-Engineering/Golden-Paths.md) | golden path: making the right thing easy | ~25 min |
| [`00-Culture/Team-Topologies.md`](../../00-Culture/Team-Topologies.md) | cross-team cognitive load, platform team type | ~25 min |

## 🔨 Deliverable exercise
The output is a written proposal draft — not code. Pick a concrete friction you
experienced along your own path (from A6 to D5). Write `golden-path-onerisi.md`:
1. **Prove** the pain, don't assume it: which step was repeated how many times, how long did it take, where could it go wrong.
2. Propose a golden path: how do you make "the right thing" the default for the developer suffering this pain.
3. Write when this platform would be **premature** — under what condition you wouldn't build it, and why (see [`NOT-YET.md`](../NOT-YET.md)).
4. In Team Topologies terms: which team type owns this platform, which cognitive load it takes off whom.

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] A concrete developer pain is defined in `golden-path-onerisi.md` with **proof** (repeat count / duration / failure point)
- [ ] A golden path draft is written: clearly how "the right thing" becomes the default
- [ ] The question "when would this platform be premature" is answered with reasoning (the condition for not building it is written down)
- [ ] The team type that would own the platform is named in Team Topologies terms

## 🧪 Test yourself
1. What separates a platform from an internal library — why should a platform be managed like a product?
2. What do you lose if you turn a golden path into a mandate?
3. Why is designing a platform without feeling developer pain one of the most expensive kinds of mistakes?

<details><summary>Answers</summary>

1. A platform has users (developers); it fails if it isn't adopted — that's why it's managed like a product, with user research, feedback, and adoption metrics. A library is a dependency, a platform is a service — [`13-Platform-Engineering/Platform-as-Product.md`](../../13-Platform-Engineering/Platform-as-Product.md).
2. Voluntary adoption. A golden path is "the easiest and right way"; if you force it, the developer finds a way around it and the platform loses trust. Make the right thing easy, don't mandate it — [`13-Platform-Engineering/Golden-Paths.md`](../../13-Platform-Engineering/Golden-Paths.md).
3. Because you build a solution for a pain you never felt: an abstraction nobody asked for, constant maintenance debt, and low adoption. Feeling the pain gets the requirement right — [`NOT-YET.md`](../NOT-YET.md).
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| The pain stays abstract | No proof, just assumption | Count a step: how many times, how many minutes, how many mistakes — no number, no pain |
| The golden path turns into a mandate | Force was chosen over ease | Go back to "make the right thing the default"; don't close off the developer's escape route |
| The platform is being built too early | Developer pain wasn't felt | Solve it manually/with a script first; postpone the platform until the recurring pain is proven |
| Unclear who will own it | Team type wasn't considered | Go back to Team Topologies: is this a platform team's job, or a temporary enabling effort? |

## 💼 Portfolio output
A platform/golden path proposal draft — grounded in pain, against premature abstraction.

## ⏭️ Up next
[`F4 — Writing: ADR, RFC, Postmortem`](F4-yazma-adr-rfc.md)

---

> *"The best platform is invisible: the developer does the right thing without noticing it."*
