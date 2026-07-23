---
description: "Block E exam: SLO/error budget, alerting, incident+postmortem, tested restore, chaos — E→F transition gate. Proof of ownership."
level: E
tags: [Learning Path, Stage Exam]
---
# 📝 Block E Exam — Ownership

> *"The D → E transition signal: did something you built yourself break because of your own mistake — and did you bring it back?"*

**Gate:** End of Block E (after E5, before F1) · **Prerequisite:** [`E1`](E1-sli-slo-error-budget.md)–[`E5`](E5-chaos.md) acceptance criteria passed

> ℹ️ Run every `verify.sh` from the `22-Learning-Path/` root (`bash labs/broken/…/verify.sh`). K08 is meaningful locally too, via doc/access checks; K07 audits incident docs, K09 audits a live cluster — without that environment, `verify.sh` won't come back green.

Block E is the transition from "operator" to "owner." This exam can measure the
**mechanics** of ownership: is the SLO defined, does the alarm actually fire, was
the restore genuinely tested. Every question traces back to a module's acceptance
criterion.

> 🧗 **Honest ceiling (in the main text, not a footnote):** This exam proves the
> *mechanics* of ownership; not ownership *itself*. That requires an outage you
> didn't choose, a system you actually own, and real users. What comes after this
> gate isn't more reading: it's taking a job, going on-call, volunteering for an
> incident. See [`README.md`](../README.md) → Honest ceiling.

---

## 1️⃣ Concept questions (written)

| # | Question | Traceability (module → acceptance criterion) |
|---|---|---|
| 1 | How do you choose an SLI? How do you calculate an error budget (min/month) from an SLO? | E1 → SLI/SLO/error budget criterion |
| 2 | What changes once the error budget is exhausted? (Does release stop, what becomes the priority?) | E1 → budget exhaustion criterion |
| 3 | What's the "should this wake someone at 3am?" test for an alarm? The page / ticket / log distinction? | E2 → alarm classification criterion |
| 4 | Give an example of a "noisy alarm"; why is it silenced/removed? When does escalation kick in? | E2 → noise + escalation criterion |
| 5 | What does "blameless postmortem" mean? Which three things are **mandatory** in one? | E3 → postmortem criterion |
| 6 | Why is "an untested backup isn't a backup"? What's the difference between RTO and RPO? | E4 → restore + RTO/RPO criterion |
| 7 | What security checks are asked of a backup? (Who can access it, is it encrypted at rest?) | E4 → backup access/at-rest criterion |
| 8 | Why is a game day with a limited blast radius run as hypothesis → experiment → result? | E5 → game day criterion |

**Passing:** **At least 7 of 8** questions correct. Questions 6 and 7 (restore +
backup security) **must be correct** — that's the security thread's link in
Block E.

---

## 2️⃣ Applied task — the mechanics of ownership

**Task A — Three broken labs (core):**

- [ ] [`K07 — incident simulation`](../labs/broken/K07-incident-sim/): `verify.sh` green; managed with a UTC minute-precision timeline
- [ ] [`K08 — restore failed`](../labs/broken/K08-restore-basarisiz/): `verify.sh` green; the restore actually worked
- [ ] [`K09 — chaos game day`](../labs/broken/K09-chaos-gameday/): `verify.sh` green; limited blast radius maintained

**Task B — Alarm tied to an SLO (E1+E2):**
[`L18`](../labs/build/L18-sli-slo/) + [`L19`](../labs/build/L19-alerting/).

- [ ] An SLI for a service is measured in Prometheus; an SLO + error budget (min/month) has been calculated in writing
- [ ] An alarm rule tied to the SLO **fired at least once** and was resolved — Alertmanager/panel proof
- [ ] Every alarm is classified as page/ticket/log; escalation is defined in writing

**Task C — Restore genuinely tested (mandatory, security thread):**
[`E4`](E4-veritabani-restore.md)/[`L20`](../labs/build/L20-veritabani-restore/).

- [ ] A backup was restored to a **clean environment**; data integrity was verified with a query (row count/checksum)
- [ ] RTO and RPO were measured and written down
- [ ] The backup's access + at-rest encryption controls were written down

**Task D — Postmortem + action item:** Write a blameless postmortem from K07:
numeric impact + root cause + "why wasn't it caught sooner" + at least one
traceable action item (owner + due date).

---

## 🚫 Don't lose this exam to yourself

| Anti-pattern | Why it's bad | Right |
|---|---|---|
| Trusting an untested backup | The restore won't work in a real disaster — E4's core lesson | Restore to a clean environment, **query** the integrity |
| Blaming a person in the postmortem | People stop sharing information; the root cause gets hidden | Write it system/process-focused, blameless |
| A postmortem with no action item | The same incident happens again | Produce a traceable item with an owner + due date |
| Alerting that pages for everything | Alert fatigue → real pages get missed | Classify page/ticket/log; silence the noise |
| "Chaos" with no blast radius | You actually break your own production | Limited scope + hypothesis → experiment → result |
| Passing the mechanics and calling yourself "an owner" | Honest ceiling: real ownership happens in production | Prove the mechanics; the job/on-call teaches the rest |

---

## ✅ Did you pass?

- [ ] Concept: at least 7 of 8, plus questions 6 & 7 mandatory correct
- [ ] Application: K07 + K08 + K09 green; the SLO-tied alarm fired; the restore was verified in a clean environment
- [ ] Writing: blameless postmortem + traceable action item (owner + due date)

If you didn't pass: go back to E1 for the SLO, E2 for alerting, E3 for
incident/postmortem, E4 for restore, E5 for chaos.

## ⏭️ Up next
If you passed, go to [`Capstone 3`](../capstones/CAP3-blok-e-sonu.md) first, then
[`F1 — Cost and Trade-off (FinOps)`](../block-f-judgment/F1-maliyet-finops.md) —
but read the honest ceiling first: from here on, it's **production's** job.

---

> *"Ownership isn't building a system; it's being the one who gets called when it breaks and brings it back. This exam shows those muscles work; what actually exhausts them is your first real incident."*
