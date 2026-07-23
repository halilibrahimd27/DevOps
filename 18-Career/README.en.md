---
description: "DevOps/SRE career guide index: interview questions, SRE prep, system design cheatsheet, and CV tips; Junior-to-Principal level map and compensation discussion notes."
tags:
  - Career
  - SRE
  - Roadmap
---
# 18 · Career

> *"What does a DevOps engineer do?" depends on **the interviewer**;
> how much money you should ask for depends on **you**.*

## Contents

| File | Topic |
|---|---|
| [`DevOps-Interview-Questions.md`](DevOps-Interview-Questions.md) | 50+ questions from Junior to Staff level, categorized, with answer hints |
| [`SRE-Interview-Prep.md`](SRE-Interview-Prep.md) | SRE-specific: SLO design, incident response simulation, capacity |
| [`System-Design-Cheatsheet.md`](System-Design-Cheatsheet.md) | System design questions specific to DevOps/SRE (design a cluster, multi-region, etc.) |
| [`CV-Tips.md`](CV-Tips.md) | How to write a DevOps CV; the difference between a "tool list" and "impact" |

## Level map (rough)

| Level | Years | What's expected |
|---|---|---|
| **Junior** | 0-2 | Fluent with a single tool chain; follows runbooks; on-call shadow |
| **Mid** | 2-5 | Stack widens; independent incident handling; does PR reviews |
| **Senior** | 5-8 | Cross-cutting designs; cluster/pipeline owner; mentors juniors |
| **Staff** | 8-12 | Org-wide standards; multi-team impact; trade-off architecture |
| **Principal** | 12+ | Company strategy; tech radar; long-term platform vision |

> Level is measured by **impact**, not years. But the hiring matrix starts
> with years — express your experience through impact (not just "5 years
> of Kubernetes" but "managed 3 cluster migrations in 5 years, downtime
> under 1 minute").

## Compensation discussion notes

- Check the market with Levels.fyi, Glassdoor, Build From Outside (TR)
- Total comp = base + bonus + equity + benefits — ask about all of them
- Give a **number**, not an "expected range" — whoever states a figure wins
- Don't accept a counter-offer without talking to your team first

## Must-know topics (2026 baseline)

```
Linux                 → process, file, network, permissions — root-level comfort
Networking            → TCP/IP, DNS, TLS, HTTP, load balancing
Containers            → Docker, OCI, container runtime
Kubernetes            → at least 6 months hands-on running a cluster
IaC                   → Terraform OR Pulumi (shipped at least one to prod)
CI/CD                 → GitHub Actions / GitLab / Jenkins
Observability         → Prometheus + Grafana, log/trace logic
Cloud                 → AWS / GCP / Azure (Solutions Architect-Associate equivalent in at least one)
Scripting             → Bash + Python (daily-use level)
Database basics       → SQL, transactions, basic backup/restore
```

> Must-know ≠ must be an expert in. For mid level, be comfortable with
> **at least 7** of these; for senior, **all of them** plus 2-3 areas
> of deep expertise.
