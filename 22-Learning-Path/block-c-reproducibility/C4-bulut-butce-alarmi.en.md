---
description: "Cloud fundamentals + mandatory budget alarm: VPC/IAM/compute concepts, and seeing spend the moment you first touch the cloud."
level: C
module: C4
estimated_hours: 12
prerequisites: [C3]
tags: [Learning Path, Cloud]
---
# C4 — Cloud Fundamentals + Budget Alarm

> *"Your first job in the cloud isn't opening a resource — it's setting up the alarm that will see the spend."*

**Block:** C — Reproducibility · **Duration:** ~12h · **Prerequisite:** [`C3`](C3-terraform.md)

## 🎯 When you finish this module
- You can explain what the VPC, IAM, and compute concepts mean in a cloud.
- **Before doing anything else**, you set up and test a budget/billing alarm.
- You practice the habit of tearing down (`destroy`) every lab resource once the work is done.

## 🧠 Why this, why now
This is the path's **first module that uses the cloud.** You carry the Terraform you
learned in C3 into the cloud — but first you put up the cost guardrail. The
local-first principle ends here, and careful cloud use begins.

## 🧩 Three cloud fundamentals (a short bridge)
Cloud providers offer hundreds of services, but almost everything sits on top of these
three — and all three are the cloud abstraction of something you've already **seen by
hand**:

| Concept | What it means | Where you saw it before |
|---|---|---|
| **Compute** | The CPU/memory that runs your work — a virtual machine (e.g. AWS EC2), a container service, or a function | The cloud form of the VM you set up by hand in A6 |
| **VPC** (Virtual Private Cloud) | The **isolated private network** your resources live in: subnet, routing, firewall (security group) | The cloud-managed form of the IP/subnet/port concepts from A2 |
| **IAM** (Identity and Access Management) | **Who can do what** — users/roles + permission policies | The cloud counterpart of the users/groups/permissions and "least privilege" from A1 |

Depth isn't this module's point; the goal is to know these well enough to understand
the bill and access. For short definitions of the terms, see [`Glossary.md`](../../Glossary.md)
(VPC/IAM/Compute · free tier · egress · NAT).

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`16-Cheatsheets/aws-cli.md`](../../16-Cheatsheets/aws-cli.md) | basic CLI commands | ~20 min |
| [`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md) | local alternative + budget alarm | ~15 min |

## 🔨 Lab
👉 [`labs/build/L12-bulut-butce-alarmi/`](../labs/build/L12-bulut-butce-alarmi/README.md) — **First step: the budget alarm.**

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] A billing/budget alarm is set up, wired to a notification channel, and **tested by either exceeding the forecast threshold or manually triggering it with a low threshold** — or, if not, how to test it on a real account is written down (real billing data lags by hours/days; L12 verifies this locally with `plan`/config)
- [ ] A small resource was opened with Terraform and torn down with `destroy` — verified that no open resource remains
- [ ] You wrote down which services fall under the **free tier** and which are billed per hour/GB
- [ ] You **wrote** the VPC, IAM, and compute concepts in your own words (L12 `report.txt` — `verify.sh` looks for all three definitions)

## 🧪 Test yourself
1. On your first touch of the cloud, why is setting up a budget alarm **before opening any resource** not a preference, but a rule?
2. What does "least privilege" mean in IAM; why is doing daily work with a root/admin key dangerous?
3. A lab is done. Which single habit protects you from driving cost to zero, and why?

<details><summary>Answers</summary>

1. Because in the cloud, cost accumulates **without you noticing**: a forgotten disk, load balancer, or IP is billed by the hour. The alarm lets you see the bill in the first hour, not at the end of the month. Local alternatives + alarm setup are in [`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md).
2. Least privilege: give an identity only enough permission to do its job, no more. If a root/admin key leaks, the attacker can do anything; even if a narrow role leaks, the damage stays limited. Use a separate, restricted identity for daily work.
3. The `destroy` (or lab-teardown) habit. Tear down every resource you open in the cloud once the work is done — "I'll tear it down later" is the most expensive sentence.
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| Unexpected end-of-month bill | Forgotten resource (load balancer, disk, IP) | Set the alarm to a low threshold; the `destroy` habit; check the cost explorer |
| Alarm never fires | Notification channel not verified | Test the alarm manually with a low threshold; confirm the email/webhook subscription |
| `apply` gives "access denied" | Missing IAM permission | Add the needed permission narrowly; don't use an admin key |
| A service you thought was free tier turns out billed | Egress (outbound data transfer) / NAT / data transfer hidden cost | Read the pricing beforehand; watch out for egress and managed services |

## 💼 Portfolio output
A disciplined cloud setup note with a budget alarm + `destroy`.

## ⏭️ Up next
Block C is done → **gate project**: [`Capstone 1`](../capstones/CAP1-blok-c-sonu.md).
Then [`D1 — K8s Fundamentals`](../block-d-orchestration/D1-k8s-temel.md).

---

> *"A forgotten resource in the cloud is a meter running while you sleep."*
