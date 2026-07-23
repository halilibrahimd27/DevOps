---
description: "How to study: read/do ratio, active recall, and the external-source contract (the four-field link rule)."
tags: [Learning Path]
---
# 📚 Study Method

> *"Reading isn't understanding. Understanding is being able to break it and put it back together."*

This path is not a reading list — it's a curriculum. The method below exists to
turn what you read into **competence**. Read little, do much, prove it.

---

## ⚖️ Read/do ratio

Rough target: **1 unit reading → 2 units doing.** Don't stop once you finish a
module's "Read first" table — the real learning happens in the lab and in the
broken lab. Reading a concept makes you think you understand it; applying it
to a system and breaking it is when you actually learn it.

| Stage | What you do | Goal |
|---|---|---|
| Read | Go through the sources in the "Read first" table | Concept + the "why" |
| Build | Finish the `labs/build/` task | Being able to do it by hand |
| Break & fix | Solve the `labs/broken/` broken lab | Diagnostic intuition |
| Prove | Pass the acceptance criteria with a command | Objective verification |
| Explain | Write a concept in your own words | Retention (active recall) |

---

## 🔁 Active recall and spaced repetition

- At the end of each module, answer the `🧪 Test yourself` questions **closed-book**.
- After taking a week's break, re-run one of the previous block's acceptance criteria.
- If you can't explain the concept to someone else (or to a blank page), you haven't learned it.

---

## 🌐 External-source contract — the four-field link rule

This repo is a **curator**, not a copy of the entire world. The goal isn't
"no need for any other source" — it's **"no moment left without direction."**
That's why every external link in this path fills these four fields:

| Source | Why you're going | Exactly what you'll do there | Duration | How it's verified when you return |
|---|---|---|---|---|
| (example) official Terraform tutorial | See the state concept from the official source | `terraform apply` → inspect the state file | ~30 min | Compare `terraform state list` output against the module's lab |

An external link without all four fields is a **link dump, and it's forbidden
in this path.** If you see a link in a module that just says "check this
address," that's a bug — it gets fixed in the Phase 9 audit.

> **Two exceptions — these are not link dumps:**
> 1. **Just-in-time single-fact reference.** A source you check to grab a
>    single piece of information **instantly** — a `man` page, a tool's wiki,
>    or the current version number on a GitHub release — rather than "going to
>    learn something," doesn't need all four fields. It's a dictionary lookup,
>    not directed reading.
> 2. **In-repo "Read first" links.** The deep-dive links in a module's
>    `📖 Read first` table are not external sources; source + purpose +
>    duration (three fields) is enough. The module's **acceptance criteria**
>    already handle the "verify on return" job.

---

## 🧱 When you get stuck

1. Check the module's `🆘 If you're stuck` table (symptom → likely cause → what to do).
2. General errors: [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).
3. In the broken lab, the `hints/` folder is staged: `hint-1` (direction) →
   `hint-2` (narrow down) → `hint-3` (near-answer). Open them in order; don't
   open `solution.md` on your first move.

> Getting stuck isn't a malfunction — it's the process itself. Narrowing down
> an error without help is the actual skill this path teaches.

---

## 🚫 Anti-patterns

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| Reading an entire block without doing any labs | Reading isn't competence; you'll collapse on the first real task | Finish at least one lab per module |
| Passing an acceptance criterion by saying "I get it" | Subjective; unprovable | Prove it with a command / file existence / written output |
| Opening `solution.md` at the first difficulty | You never exercise your diagnostic muscle | Start with `hint-1`, form your own hypothesis first |
| Skipping a block ("I already know this") | The gap shows up later as a wall | Pass the check test, then skip |
| Diving into an external link and never coming back | You end up directionless, hours lost | Follow the four-field contract: duration + return verification |

---

## 📋 Checklist — before counting a module as "done"

```
[ ] Went through the "Read first" sources
[ ] Finished the lab, verify.sh passed with zero errors
[ ] (If present) solved the broken lab without help (at most with hint-1/2)
[ ] Proved every acceptance criterion with a command/output
[ ] Answered the test-yourself questions closed-book
[ ] Saved the portfolio artifact (if any)
```

---

> *"Speed isn't the goal. Actually passing one block is worth more than half-knowing two."*
