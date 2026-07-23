---
description: "Template you copy for yourself to check off progress: a box for every module, lab, and block transition signal."
tags: [Learning Path]
---
# ✅ Progress Template

> *"A checked box isn't a declaration — it's proof. Don't check the box before you pass the acceptance criteria."*

**Copy this file for yourself** (e.g. `PROGRESS.md`) and check things off as you go.
Only mark a module `[x]` once you've passed all its acceptance criteria with a
command/output. If you can't pass the block transition signal, you haven't left
that block yet.

**Start date:** `____` · **My ramp:** `A1 / A6 / B1` ([`PLACEMENT.md`](PLACEMENT.md))

---

## Block A — Intuition
```
[ ] A1  Linux basics
[ ] A2  Networking I — TCP/IP, ports, routing
[ ] A3  Networking II — DNS → HTTP → TLS
[ ] A4  Git basics
[ ] A5  Bash
[ ] A6  Stand up an app by hand (+ broken lab)
```
**Transition signal (A → B):** I can narrow down why a service won't come up,
using three commands, without looking at documentation. `[ ]`

## Block B — Visibility
```
[ ] B1  Reading logs
[ ] B2  Metrics — Prometheus basics
[ ] B3  First broken lab
```
**Transition signal (B → C):** I **proved** an incident with logs and metrics —
I didn't guess. `[ ]`
> 🔒 Don't move on to Block C until this box is checked — the strictest rule on the path.

## Block C — Reproducibility
```
[ ] C0  Python for ops
[ ] C1  Containers (+ broken lab)
[ ] C2  CI
[ ] C3  Terraform (+ broken lab)
[ ] C4  Cloud basics + budget alert
[ ] Capstone 1 (end of Block C)
```
**Transition signal (C → D):** I can rebuild my system from scratch without
touching anything by hand. `[ ]`

## Block D — Orchestration (security woven throughout)
```
[ ] D1  K8s basics — RBAC + NetworkPolicy from day one (+ broken lab)
[ ] D2  K8s in production (+ broken lab)
[ ] D3  Secret management
[ ] D4  Supply chain — continuation of the C2 pipeline
[ ] D5  GitOps / ArgoCD (+ broken lab)
[ ] Capstone 2 (end of Block D)
```
**Transition signal (D → E):** Something I built broke because of my own
mistake, and I brought it back. `[ ]`

## Block E — Ownership (L1 gate)
```
[ ] E1  SLI / SLO / error budget
[ ] E2  Alerting + on-call
[ ] E3  Incident + blameless postmortem (+ broken lab)
[ ] E4  Database in production — restore (+ broken lab)
[ ] E5  Advanced broken lab / chaos
[ ] Capstone 3 (end of Block E)
```
**Transition signal (E → F):** I said "no" to something and defended my
reasoning in writing. `[ ]`

## Block F — Judgment (L1 → L2)
```
[ ] F1  Cost and trade-offs (FinOps)
[ ] F2  Threat modeling + compliance
[ ] F3  Platform, IDP, Team Topologies
[ ] F4  Writing — ADR, RFC, postmortem
[ ] F5  Stakeholders, saying "no", vendors
```

---

## 🧗 Honest ceiling reminder

The E and F gates can't be passed on your own: they require an incident you
didn't choose, a system you own, and real users. If you've gotten here, the
next step isn't more reading — it's getting into a production environment.
See [`README.md`](README.md) → Honest ceiling.

---

> *"Progress isn't measured by the calendar — it's measured by the gates you've passed."*
