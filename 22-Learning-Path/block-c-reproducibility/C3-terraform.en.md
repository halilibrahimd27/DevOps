---
description: "Terraform: defining the infrastructure you built by hand in A6 as code — an abstraction that only means something to someone who's lived the pain."
level: C
module: C3
estimated_hours: 16
prerequisites: [A6, C1]
tags: [Learning Path, IaC]
---
# C3 — Terraform: Automate A6

> *"Terraform is an abstraction; teaching it to someone who hasn't lived the pain it abstracts away is pointless. Remember A6."*

**Block:** C — Reproducibility · **Duration:** ~16h · **Prerequisite:** [`A6`](../block-a-intuition/A6-elle-deploy.md), [`C1`](C1-container.md)

## 🎯 When you finish this module
- You define the infrastructure you set up by hand in A6 as code with Terraform.
- You explain the `plan`/`apply`/`destroy` cycle and what state is.
- You can rebuild the same environment from scratch, without touching anything by hand.

## 🧠 Why this, why now
In A6 you did everything by hand, and every repeat was error-prone. C3 turns that
manual work into code; this is exactly the **C → D transition signal**: "can you
rebuild your system from scratch, without touching anything by hand?"

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`03-IaC/Terraform-Best-Practices.md`](../../03-IaC/Terraform-Best-Practices.md) | state, structure, practices | ~30 min |
| [`03-IaC/Terraform-Module-Layout.md`](../../03-IaC/Terraform-Module-Layout.md) | module layout | ~20 min |

## 🔨 Lab
👉 [`labs/build/L11-terraform/`](../labs/build/L11-terraform/) — local: **LocalStack** (an emulator that mimics AWS services locally — no cloud/money needed; [`Glossary.md`](../../Glossary.md)).

## 💥 Broken lab
👉 [`labs/broken/K03-terraform-state/`](../labs/broken/K03-terraform-state/) — Symptom: "apply gives an
unexpected result / is locked." (Realistic cause hidden: state lock / drift.) This is
Block C's mandatory broken lab.

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] The A6 environment gets built from scratch with `terraform apply` (locally, on LocalStack)
- [ ] After `terraform destroy`, running `apply` again produces the same result — proof of reproducibility
- [ ] `bash labs/broken/K03-terraform-state/verify.sh` passes with zero errors after the fix
- [ ] You can explain in writing what state is and why it needs to live in a shared/lockable location

## 🧪 Test yourself
1. What is Terraform state? Why is it not "a photograph of the real world" but "a record of what Terraform did"?
2. What happens if two people run `apply` at the same time, and what prevents it?
3. Someone changed a resource by hand from the console. What does the next `plan` show, what is this called, and how do you fix it?

<details><summary>Answers</summary>

1. State is a mapping of the resources Terraform manages: it tracks which resource it associates with which real object. The real world can change independently of this (manual intervention); Terraform only knows its own record, and surfaces the difference in `plan`. Details in [`03-IaC/Terraform-Best-Practices.md`](../../03-IaC/Terraform-Best-Practices.md).
2. Two concurrent `apply` runs can corrupt state. **State lock** prevents this: the first run takes the lock, the second waits. This is why state needs to live in a remote, lockable backend (not a local file).
3. `plan` shows an unexpected difference — this is called **drift**. Either revert the manual change and align it back to code with `apply`, or, if the change should be permanent, reflect it in the code. `ignore_changes` is only a last resort.
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| `apply` says "state locked" | A previous run left the lock behind / concurrent run | If no run is active, `force-unlock` (carefully); share state with the team on a remote backend |
| `plan` shows a change every time | Drift, or a field the provider doesn't normalize | Revert the manual change or reflect it in code; `ignore_changes` is a last resort |
| `destroy` leaves some resources behind | Dependency / `prevent_destroy` protection | Resolve the dependency order; review the protection flag |
| Locally it's hitting the real cloud | Provider endpoint isn't pointed at LocalStack | Redirect the endpoint to the local emulator; there's no real cloud until C4 |

## 💼 Portfolio output
The code form of the A6 infrastructure (a Terraform module) — buildable from scratch, demoable.

## ⏭️ Up next
[`C4 — Cloud Foundations + Budget Alarm`](C4-bulut-butce-alarmi.md)

---

> *"Infrastructure set up by hand is a memory; infrastructure that is code is a fact — the reproducible kind."*
