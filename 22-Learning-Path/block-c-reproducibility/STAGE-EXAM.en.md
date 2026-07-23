---
description: "Block C exam: Python automation, containers, CI, Terraform, budget alerts — the C→D transition gate. Can you rebuild the system from scratch without touching anything by hand?"
level: C
tags: [Learning Path, Stage Exam]
---
# 📝 Block C Exam — Reproducibility

> *"C → D transition signal: can you rebuild your system from scratch, without touching anything by hand?"*

**Gate:** End of Block C (after C4, before D1) · **Prerequisite:** [`C0`](C0-ops-python.md)–[`C4`](C4-bulut-butce-alarmi.md) acceptance criteria passed

> ℹ️ Run all `bash labs/...` commands **from the `22-Learning-Path/` root**.

Block C makes one claim: **being able to build the same system a second time with the same input.**
This exam measures that. Every question traces back to a module's acceptance criterion.

> 🏁 **Exam ≠ capstone.** This exam is a knowledge/skill gate. The block's big deliverable
> project is [`Capstone 1`](../capstones/CAP1-blok-c-sonu.md) — there you make the A6
> app reproducible end to end. Pass the exam, then sit down with
> the capstone.

---

## 1️⃣ Concept questions (written)

| # | Question | Traceability (module → acceptance criterion) |
|---|---|---|
| 1 | Why would you write a task in Python instead of Bash (or vice versa)? Give a decision rule. | C0 → "why Python/Bash" criterion |
| 2 | Why is swallowing errors with `except: pass` dangerous? Give a failure scenario. | C0 → `except: pass` criterion |
| 3 | Why does a Docker layer get cached / invalidated? Why does `COPY` order matter? | C1 → layer cache criterion |
| 4 | Why is the `:latest` tag forbidden? What's used instead (SHA/semver), and why? | C2 → versioned tag criterion |
| 5 | What exactly does "pipeline green" prove, and what does it **not** prove? | C2 → "what green verified" criterion |
| 6 | What is Terraform state? Why must it live in a shared + locked location? | C3 → state criterion |
| 7 | Which cloud services are free tier, and which are billed per hour/GB? Give two examples. | C4 → free tier criterion |

**Passing:** **At least 6 of the 7** questions correct + reasoned. Question 4 (the `:latest` ban)
is **mandatory correct** — mutable tags are a supply-chain risk and a prerequisite for D4.

---

## 2️⃣ Applied task — "from scratch, without touching anything by hand"

**Task A — Two broken labs (core):**

- [ ] [`K02 — container error`](../labs/broken/K02-container-hatasi/): `bash labs/broken/K02-container-hatasi/verify.sh` passes with zero errors after the fix
- [ ] [`K03 — terraform state`](../labs/broken/K03-terraform-state/): `bash labs/broken/K03-terraform-state/verify.sh` passes with zero errors after the fix
- [ ] For both, you wrote the root cause + diagnostic flow (K03 = stale state lock → `force-unlock`)

**Task B — Proof of reproducibility:**
Use the [`C3`](C3-terraform.md)/[`L11`](../labs/build/L11-terraform/) (LocalStack) setup.

- [ ] The environment is built from scratch with `terraform apply` → `terraform destroy` → `apply` again produces the **same** result
- [ ] A commit → CI → registry flow is green ([`L10`](../labs/build/L10-ci/)); the image is published with a versioned tag (no `:latest`)

**Task C — The budget alert really works:**
[`C4`](C4-bulut-butce-alarmi.md)/[`L12`](../labs/build/L12-bulut-butce-alarmi/).

- [ ] The budget/billing alert is set up, connected to a notification channel, and tested by **actually triggering** it
- [ ] A small resource was created and closed with `destroy` — verified that **no resource is left running**

---

## 🚫 Don't lose this exam to yourself

| Anti-pattern | Why it's bad | Right |
|---|---|---|
| "It works" with `:latest` | Which version is running is unclear; rollback is impossible | Pin with SHA/semver |
| Manually fixing a setting after `apply` | It's no longer "reproducible from scratch" | Put the fix into code, `apply` again |
| Leaving things without `destroy`ing | Exactly the cost trap C4 warns about | `destroy` + verify at the end of every lab |
| Setting up a budget alert and not testing it | An untested alert isn't an alert | Lower the threshold and **trigger** it, see the notification |
| "Silencing" the script with `except: pass` | The failure is swallowed silently | Catch the error, log it, exit non-zero |

---

## ✅ Did you pass?

- [ ] Concept: at least 6 of 7 + question 4 mandatory correct
- [ ] Application: K02 + K03 green; `apply→destroy→apply` idempotent; CI green & versioned image
- [ ] Budget: alert tested by triggering it; no resource left running after `destroy`

If you didn't pass: go back to C1 for containers, C2 for CI, C3 for state, C4 for budget.

## ⏭️ Up next
If you passed: first [`Capstone 1`](../capstones/CAP1-blok-c-sonu.md), then
[`D1 — K8s Fundamentals`](../block-d-orchestration/D1-k8s-temel.md).

---

> *"Reproducibility isn't a feature, it's proof. Before adding one more layer of abstraction with K8s (Block D), prove you can build the system you have the same way twice."*
