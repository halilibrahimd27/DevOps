---
description: "Block A exam: Linux, networking, DNS/HTTP/TLS, Git, Bash, and manual deploy — the A→B transition gate. Every question ties to a module's acceptance criterion."
level: A
tags: [Learning Path, Stage Exam]
---
# 📝 Block A Exam — Intuition

> *"A → B transition signal: can you narrow down why a service won't come up, in three commands, without opening the docs?"*

**Gate:** End of Block A (after A6, before B1) · **Prerequisite:** [`A1`](A1-linux-temeli.md)–[`A6`](A6-elle-deploy.md) acceptance criteria passed

> ℹ️ Run all `bash labs/...` commands **from the `22-Learning-Path/` root** (same path as the acceptance criteria in the modules).

This exam doesn't teach a new topic; it's **proof** of what you've learned. It has two parts:
written concept questions and a hands-on applied task. The criterion isn't "I know it"
— it's whether the command runs, the output is correct, and you can write your reasoning. Every question
traces back to a module's acceptance criterion (right-hand column); this exam doesn't invent a new
criterion, it gathers the existing acceptance criteria into a single session.

> 📌 **How to take it:** **Close** the module documents. Write/run the answers first,
> then compare against your own module. A copied answer won't get you into B —
> in B1 you'll be alone in front of a real broken system.

---

## 1️⃣ Concept questions (written)

Write each one **in your own words.** The "correct" answer is in the module; write yours first.

| # | Question | Traceability (module → acceptance criterion) |
|---|---|---|
| 1 | Explain the `640` permission in octal and `rwx` form; what can each of the three classes (owner/group/others) do? Tie this to the "least privilege" principle. | A1 → permission + user/group criterion |
| 2 | What are the two different meanings of "disk full" (`df -h` vs `df -i`)? Which one is inode exhaustion? | A1 → `df -h`/`df -i` criterion |
| 3 | What's the difference between "connection refused" and "connection timed out"? What does each point to, and at which layer? | A2 → refused/timeout criterion |
| 4 | Why is a service listening on `127.0.0.1:80` "unreachable from outside"? What's the difference with `0.0.0.0`? | A2 → `127.0.0.1`/`0.0.0.0` criterion |
| 5 | What do the HTTP status code classes (`2xx/3xx/4xx/5xx`) tell you? Whose responsibility is `4xx` versus `5xx`? | A3 → status code criterion |
| 6 | For a TLS certificate, what does each of expired / name-mismatch / chain errors mean? | A3 → certificate criterion |
| 7 | Why does the "never rebase shared history" golden rule exist? How does history differ between merge and rebase? | A4 → merge/rebase criterion |
| 8 | What does each of the three flags in `set -euo pipefail` prevent, individually? Give one example for each. | A5 → `set -euo pipefail` criterion |

**Passing:** Write **at least 7 of the 8** questions, without looking at the module, technically
correct and in your own words. Not a memorized definition — an answer with a *why*.

---

## 2️⃣ Applied task — "the service that won't come up"

This task combines A1–A6 into a single scenario and is the A→B signal itself.

**Task A — Diagnose the broken service (core):**
Solve the [`K00 — systemd won't come up`](../labs/broken/K00-systemd-ayaga-kalkmiyor/README.md) broken
lab. `README.md` only gives the symptom; you'll find the cause.

- [ ] `bash labs/broken/K00-systemd-ayaga-kalkmiyor/verify.sh` passes with zero errors
- [ ] You wrote the root cause and the **diagnostic flow** (symptom → narrowing → root cause → fix → verification)
- [ ] You used at most `hint-1`/`hint-2`; if you opened `hint-3`/`solution.md`, this doesn't count as a pass this time

**Task B — Prove the manual deploy is up:**
Use the [`A6`](A6-elle-deploy.md)/[`L06`](../labs/build/L06-elle-deploy/README.md) setup.

- [ ] `systemctl is-enabled app` → `enabled` **and** `systemctl is-active app` → `active`
- [ ] `curl -s http://127.0.0.1/health` returns `200` + the expected body via nginx
- [ ] You showed that in `ss -tlnp` output, app listens only on `127.0.0.1`, nginx on `0.0.0.0:80`

**Task C — Layer narrowing (timed):** Write the **first three commands** you used while
finding the fault in Task A, and why each one came in that order. Soft target (not
mandatory): time yourself and get to the right layer in a few minutes without opening docs —
not speed, **the right order** matters.

---

## 🚫 Don't lose this exam to yourself

| Anti-pattern | Why it's bad | Right |
|---|---|---|
| Opening `solution.md` to "solve" K00 | You never exercised your diagnostic muscle | Start from the symptom, open hints **gradually** |
| Saying "I got it" and moving on | Subjective; it won't hold up in B1 | Show command output + written reasoning |
| Silencing a permission problem with `chmod 777` | Hides the problem, breaks least privilege | Grant only the **single** missing bit |
| Guessing "it's DNS" | No evidence; the exact opposite of Block B | Show **which layer** it is with `dig`/`ss`/`curl` |
| Skipping Task C | Narrowing discipline is the actual thing being measured | Write the three commands and the reasoning for their order |

---

## ✅ Did you pass?

If all three are true, you're ready for Block B:
- [ ] Concept: at least 7 of 8 correct + reasoned
- [ ] Application: K00 `verify.sh` green (hints ≤2) **and** A6 reboot-safe proof
- [ ] Narrowing: you narrowed a fault down to the right layer with three commands, without opening docs

If you didn't pass, there's nothing to be ashamed of — **go back to whichever module the
question/task you got stuck on belongs to.** E.g., if you couldn't find the layer in Task A,
go to A2; if you got stuck on TLS, go to A3. The exam isn't here to send you back, it's here
to **tell you where to go back to.**

## ⏭️ Up next
If you passed: [`B1 — Reading Logs`](../block-b-visibility/B1-log-okuma.md).
If you didn't pass: go back to the module you got stuck on, pass the acceptance criteria again.

---

> *"If you can't narrow down why a service isn't working in three commands, making it observable (Block B) is premature."*
