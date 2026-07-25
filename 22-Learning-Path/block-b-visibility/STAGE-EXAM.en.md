---
description: "Block B exam: reading logs, Prometheus metrics, diagnosing a broken VM — the B→C transition gate. Proof, or a guess?"
level: B
tags: [Learning Path, Stage Exam]
---
# 📝 Block B Exam — Visibility

> *"B → C transition signal: did you **prove** an incident with logs and metrics, or did you guess?"*

**Gate:** End of Block B (after B3, before C0/C1) · **Prerequisite:** [`B1`](B1-log-okuma.md)–[`B3`](B3-ilk-kirik-lab.md) acceptance criteria passed

> ℹ️ Run every `bash labs/...` command **from the `22-Learning-Path/` root**.

This exam has a single yardstick: **is there evidence behind every claim?** "I think
the DB is slow" is not an answer; "this metric crossed this threshold at this minute,
this log line confirms it" is an answer. Every question traces back to a module's
acceptance criterion.

> 🔒 **This is the strictest gate on the path.** You cannot operate a system you
> cannot see. Do not move to Block C (containers, K8s) until you've **proven** you
> solved B3's broken lab.

---

## 1️⃣ Concept questions (written)

| # | Question | Traceability (module → acceptance criterion) |
|---|---|---|
| 1 | How do you filter a service's **most recent errors** with `journalctl`? (`-u`, `--since`, `-p err`) Which field of the output de-duplicates an event? | B1 → `journalctl … -p err` criterion |
| 2 | Why is a structured (JSON) log queryable where a plain-text log isn't? Which fields enter the query? | B1 → structured log criterion |
| 3 | Name two fields that should **never** be written to a log line (one secret + one PII) and explain why. | B1 → "what not to log" criterion |
| 4 | What's the difference between a counter and a gauge? Which one do you read with `rate()`, and why? | B2 → counter/gauge criterion |
| 5 | Give an example of a label that causes high cardinality; why does series explosion lead to OOM? | B2 → cardinality criterion |
| 6 | Write, with an example, the difference between "proving" an incident and "guessing" it. | B3 → A→B/B→C signal criterion |

**Passing:** **At least 5 of the 6** questions correct and justified. Question 3 (what
not to log) is a **mandatory correct** — secret/PII leakage is the first link in the
security thread.

---

## 2️⃣ Applied task — "prove it, don't guess"

**Task A — Diagnose the broken VM (core):**
Solve the [`K01 — broken VM`](../labs/broken/K01-kirik-vm/README.md) lab.

- [ ] `bash labs/broken/K01-kirik-vm/verify.sh` passes with zero errors
- [ ] You wrote a `teshis.md` that shows the root cause with **log/metric evidence**:
      symptom → narrowing → root cause → fix → verification
- [ ] You proved with a separate command that the symptom **is gone** after the fix
      (not just "I fixed it")

**Task B — A health indicator backed by a metric:**
Use the [`B2`](B2-metrik-prometheus.md)/[`L08`](../labs/build/L08-metrik/README.md) setup.

- [ ] The target shows `UP` on the Prometheus **Targets** screen; the `up` query
      returns `1`
- [ ] You wrote a `rate(...[5m])` query for a health indicator and showed its output

**Task C — Three commands, no docs:** Write the **three commands** you used to
narrow down to the root cause in Task A, and why they came in that order. This
re-tests the A→B signal in B: has the narrowing reflex become permanent?

---

## 🚫 Don't lose this exam to yourself

| Anti-pattern | Why it's bad | Right |
|---|---|---|
| Root-causing with "I think/probably …" | A guess; the exact thing Block B rejects | Show it with metric/log **output** |
| Fixing it, passing `verify.sh`, and stopping there | You didn't prove the symptom is gone | Show the symptom is gone with a separate command |
| Writing a secret/PII into a log and calling it "debug" | The most common real incident cause | Mask/strip it; write down why |
| Adding a label to everything | Cardinality explosion → Prometheus OOM | Use labels with a fixed, bounded value set |
| Skipping `teshis.md` and keeping it in your head | Untraceable; the postmortem (E3) muscle never trains | Leave a timestamped, written diagnosis |

---

## ✅ Did you pass?

- [ ] Concepts: at least 5 of 6 correct + question 3 mandatory correct
- [ ] Application: K01 `verify.sh` green + evidenced `teshis.md` + `up=1` & a `rate()` query
- [ ] Narrowing: you reached the root cause with three commands, with proof (not a guess)

If you didn't pass: go back to B1 if you got stuck on logs, B2 if you got stuck on
metrics/PromQL, B3 if you got stuck on the diagnosis flow.

## ⏭️ Up next
If you passed: [`C0 — Ops Python`](../block-c-reproducibility/C0-ops-python.md)
or [`C1 — Containers`](../block-c-reproducibility/C1-container.md).

---

> *"You can guess an incident, but if you can't prove it, you're not ready to make it reproducible (Block C) — you don't know what you'd be reproducing."*
