---
description: "Three entry ramps and a placement test: where you start is decided by the test, not by claiming 'I already know this.'"
tags: [Learning Path]
---
# 🚪 Placement — Where to Start

> *"Nobody actually starts from zero. But saying 'I already know this' isn't grounds for skipping — passing the placement test is."*

This page offers three entry ramps. All three connect to the **same body**; the
only difference is where you get in. If you want to skip a block, you have to
pass that block's **placement test**. If you can't pass it, you don't skip —
that's your starting point.

---

## 🎯 Three ramps

| Ramp | Entry point | Condition |
|---|---|---|
| New graduate / career changer | **A0** | Unconditional — start here (environment + terminal). |
| Backend / software developer | A1–A5 quick check → **A6** | You already have an environment → do a 20-minute check pass on A0; if you pass the A1–A5 placement test, go straight to A6. |
| System administrator / IT | A1–A3 can be skipped → **A6, B1** | You already have an environment → skip A0; if you pass the A1–A3 placement test, refresh A4–A5 and move to A6. |

> ⚠️ No ramp **skips A6.** A6 (standing up an application by hand) is the
> anchor of the entire path; every later abstraction refers back to it.

---

## 🧪 Placement tests

Every placement test has two parts: **quick questions** (concept) + a **hands-on
task** (proof). Don't skip the block until you pass both. The criterion isn't
"I know it" — it's that the command runs and the output is correct.

> 📝 The placement tests here are for **skipping** a block. When you finish a
> block and move to the next one, the gate you clear is that block's
> `STAGE-EXAM.md` (e.g. [`Block A exam`](block-a-intuition/STAGE-EXAM.md)). Same
> criterion: the command runs, the output is correct, the reasoning is written
> down. If you get stuck on a placement test, you don't skip — that block is
> your starting point.

### A1–A3 check (System administrator ramp)

A system administrator knows Linux and networking; they can skip A1–A3, but
only **if they prove it.** If you pass, refresh A4–A5 and move to A6; if you
don't, start from the relevant module.

- **Concept (written, no docs open):**
  1. Explain the `640` permission as `rwx` + octal; what does each of owner/group/others do? (→ A1)
  2. What are the two meanings of "disk full" (`df -h` vs `df -i`)? (→ A1)
  3. The difference between "connection refused" and "timed out" — which layer does each point to? (→ A2)
  4. A domain name's resolution chain (`dig` → resolver) + what do `2xx/3xx/4xx/5xx` tell you? (→ A3)
- **Hands-on (command + output):**
  - Find a listening port with `ss -ltnp` (or `lsof -i`) and **match it to a process** (→ A2).
  - Resolve a domain with `dig +short`, read the status code with `curl -I`, and pull the
    certificate's subject/issuer/validity dates with `openssl` (→ A3).
- **Pass:** All four concept questions correct + justified **and** the hands-on steps
  completed without looking at the docs, in three to four commands. If you get stuck on
  even one question, start from that module.

### A1–A5 check (Developer ramp)

A developer knows code and Git; they can skip A1–A5 and move to A6, but only
**if they prove it.**

- **Concept (written, no docs open):**
  1. The four questions from the A1–A3 check above.
  2. Why does the "never rebase shared history" golden rule exist? How does history
     differ between merge and rebase? (→ A4)
  3. What does each of the three flags in `set -euo pipefail` prevent, individually? (→ A5)
- **Hands-on (command + output):**
  - The hands-on steps from the A1–A3 check.
  - Deliberately create a conflict across two branches, resolve it **by hand**, and show
    the result with `git log --oneline --graph` (→ A4).
  - Summarize a log file with a **single-line** pipe chain; write a script that's clean
    under `shellcheck` (→ A5).
- **Pass:** All concept questions correct + justified **and** the conflict + log summary
  completed unassisted. Clean under `bash -n` and `shellcheck`.

> ⚠️ Passing a check only exempts you from that block's **modules** — **not
> from A6.** A6 is the anchor — no ramp skips it.

---

## 🧭 If you're not sure

If you're not sure, **don't try to skip — start from A0.** The modules you
already know go fast; the gaps you think you don't have get closed where they
actually exist. The gap test (the path's core principle): *only someone who has
this module and its prerequisites should be able to complete it.*

---

> *"The cost of entering from the wrong ramp is hitting a wall three weeks later without knowing why."*
