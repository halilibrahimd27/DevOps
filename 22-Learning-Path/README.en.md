---
description: "A from-scratch DevSecOps learning path — read, build, verify, pass. Not a reading list — a curriculum."
tags: [Learning Path]
---
# 🎓 Learning Path — DevSecOps From Scratch

> *"This is not a reading list — it's a curriculum. A reading list says 'read this'; a curriculum says: read → build → verify → didn't pass? go back → passed? move on."*

This path is a curriculum someone who knows nothing about DevSecOps can start
from zero and work through step by step. Every step spells out what to read,
what to build, how to verify it, and where to go next. The goal: **never once
asking "what do I do now?"**

This repo (`The DevSecOps Handbook`) holds 125+ deep-dives across 21 topic
folders. The path is their **backbone and sequencer** — not a copy. If a topic
is already covered in a deep-dive, the module **links to it.**

---

## 🎯 Who this path is for

- **New grad / career changer** — assumes zero prior knowledge, starts at A0 (environment + terminal).
- **Backend / software developer** — knows code, fills the gaps in ops/networking/deploy.
- **System administrator / IT** — knows Linux/networking, moves into automation and orchestration.

[`PLACEMENT.md`](PLACEMENT.md) decides where you start — not because you said
"I know this," but via the **check test.**

---

## 🧭 How to use this

1. [`PLACEMENT.md`](PLACEMENT.md) → pick your entry ramp, pass the check test.
2. [`STUDY-METHOD.md`](STUDY-METHOD.md) → read/build ratio, external-resource contract.
3. [`PROGRESS-TEMPLATE.md`](PROGRESS-TEMPLATE.md) → copy it for yourself, track your progress.
4. [`CURRICULUM.md`](CURRICULUM.md) → see the block order and dependency graph.
5. Open your first module, and **don't move to the next one until you pass its acceptance criteria.**
6. At the end of each block, solve that block's `STAGE-EXAM.md` (in the block
   folder) — the signal isn't "I get it," it's command output + written
   justification. At the end of Block C/D/E there's also a
   [`capstone`](capstones/) deliverable project.

You're not alone when you get stuck: every module has a `🆘 If you're stuck`
table; common errors are in [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) (Phase 9).
Before you spend any money, read [`COST-GUARDRAILS.md`](COST-GUARDRAILS.md) —
**every lab runs locally first.**

---

## 🧱 Six blocks — ordered by dependency, not by technology

The order isn't built around tool count — it's built around **radius of
responsibility.** Each step's justification: *this is required to understand
the next one.*

| Block | Name | What you gain |
|---|---|---|
| **A** | Intuition | You bring an app up **by hand** — no containers. |
| **B** | Visibility | You **prove** a failure with logs and metrics — you don't guess. |
| **C** | Reproducibility | Containers, CI, Terraform — you rebuild the system from scratch. |
| **D** | Orchestration | K8s — **security baked in from day one** (RBAC, NetworkPolicy). |
| **E** | Ownership | SLOs, on-call, incidents, restore — you bring back what broke. |
| **F** | Judgment | Cost, compliance, platform, writing — being able to say "no." |

Details + mermaid dependency graph: [`CURRICULUM.md`](CURRICULUM.md).

---

## ⏱️ How long it takes

Understating the time is the fastest way to lose trust. For someone putting
in **10–12 hours** a week, the rough range is: **~40–48 weeks** (~483 hours
total, capstones included). This isn't a race — actually passing the
acceptance criteria matters more than the calendar.

> ⛔ This path does not promise you a **title** (you won't find phrasing like
> "you'll reach title X in Y months" here). A title is determined by
> experience, employer, and the market. The path gives you **competency**:
> when you finish a block, you're *able to do* something specific.

---

## 🧗 Honest ceiling — not a footnote, the main text

> The last two doors can't be opened on your own. They require a failure you
> didn't choose, a system you own, and real users. What's needed at this point
> isn't more reading: it's getting a job, joining the on-call rotation,
> volunteering for an incident. This path gets you there; **what comes after
> is taught by production.**

Topics that get introduced too early (service mesh, multi-cluster, IDP…) are
deliberately deferred — see [`NOT-YET.md`](NOT-YET.md). The real damage a
roadmap does isn't what it leaves out — it's **what it puts in too soon.**

---

## 🗺️ What's in this folder

| File | What it's for |
|---|---|
| [`CURRICULUM.md`](CURRICULUM.md) | Block table, dependency graph, pass signals |
| [`PLACEMENT.md`](PLACEMENT.md) | Three entry ramps + check test |
| [`STUDY-METHOD.md`](STUDY-METHOD.md) | How to study, external-resource contract |
| [`PROGRESS-TEMPLATE.md`](PROGRESS-TEMPLATE.md) | Progress file you copy for yourself |
| [`COST-GUARDRAILS.md`](COST-GUARDRAILS.md) | Local alternatives + cloud budget alerts |
| [`NOT-YET.md`](NOT-YET.md) | "Not yet" list and the reasoning behind it |
| [`PORTFOLIO.md`](PORTFOLIO.md) | Which module/capstone maps to which résumé line |
| `block-a … block-f/` | Module files (A0…F5) |
| `capstones/` | End-of-block C/D/E deliverable projects |
| `labs/` | Build labs + broken labs |

---

> *"Only someone who's felt the pain that came before an abstraction knows what it actually solves. This path preserves that order."*
