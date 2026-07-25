---
description: "A guide distilled from Skelton & Pais's Team Topologies book: the 4 team types (stream-aligned, enabling, complicated-subsystem, platform) and their interaction modes."
tags:
  - Culture
  - Platform Engineering
  - Soft Skills
---

# Team Topologies — Engineering as Team Structure

> *Conway's Law: "Systems mirror the communication structure of the
> organizations that design them."* — in other words, **your team structure = your architecture's destiny.**

Distilled from Skelton & Pais's *Team Topologies* (2019); the **structural**
reference for modern DevOps & Platform Engineering teams.

---

## 🎯 The 4 Team Types

### 1. Stream-Aligned Team

> Aligned to a product/business stream. Produces **customer value**.

- Owns one end-to-end flow (e.g., "checkout flow")
- 5-9 people (Spotify "squad" size)
- Full stack: frontend + backend + DB + observability
- "You build it, you run it" — builds its own product, deploys it, carries the on-call

**Example:**
- Payments squad
- Search relevance team
- Mobile checkout team

### 2. Enabling Team

> A specialist team that gives stream-aligned teams **short-term help**.
> Not a consultant — works alongside them, then lets go.

- Usually 3-5 people
- Deep expertise in one area (e.g., "performance", "security", "test automation")
- Comes in for 2-4 weeks to remove a blocker in front of a stream-aligned team
- Then leaves — the team continues on its own

**Example:**
- SRE Enabling team — helps a team set up its SLOs
- Security Champions team — spreads the threat-modeling practice

### 3. Complicated Subsystem Team

> A highly technical subcomponent — one that requires specialized expertise.
> Not "ideal," but sometimes unavoidable.

- 3-5 people
- Compiler, ML model, real-time codec, cryptography
- Exposes a usage API to stream-aligned teams

**Example:**
- Video transcoding team
- ML training infrastructure team
- Crypto/HSM team

### 4. Platform Team

> Provides **self-service** tooling to stream-aligned teams.
> The evolved form of the "DevOps team."

- 5-15 people
- Owns the Internal Developer Platform
- Backstage, golden path, reusable CI/CD workflows, monitoring stack
- **Customer = developer** — runs it like a product (measures NPS, has a roadmap)

> 📚 [`13-Platform-Engineering/`](../13-Platform-Engineering/README.md)

---

## 🤝 The 3 Interaction Modes

How do two teams talk to each other?

### Mode 1: Collaboration

> Two teams work side by side toward a **shared goal**, for a short time.

- Usually 1-3 months
- Design together, build together
- High communication overhead
- At the end: either they split apart (moving to X-as-a-Service) or a new team forms

**Example:**
- A stream-aligned team + platform team while standing up a new microservice

### Mode 2: X-as-a-Service

> A service one team provides that other teams consume self-service.
> Low communication overhead.

- Clear API / SLA / documentation
- Consumer: "I need this" → "here, use it"
- Provider: manages its own backlog, prioritizes it

**Example:**
- Platform team → stream-aligned (CI/CD as a service)
- Identity team → applications (auth as a service)

### Mode 3: Facilitating

> The enabling team's characteristic mode. **Teaches, coaches, leaves.**

- 2-6 weeks
- Works alongside the team to say "make this practice part of your life"
- Once it's done, keeping it up is the receiving team's responsibility

**Example:**
- Performance team → teaches the checkout team load-testing practice, then leaves

---

## 📊 Cognitive Load — The Key Concept

> A team's capacity to **hold complexity in its head** is limited.
> Once it's exceeded: slowdowns, mistakes, burnout.

3 types:

| Type | Description | Fix |
|---|---|---|
| **Intrinsic** | Comes from the problem itself (algorithm, domain) | Can't reduce it; only training makes it easier |
| **Extraneous** | Tooling/process mess | **The platform team's job:** reduce it |
| **Germane** | Learning/improvement effort | Good investment — protect it |

### How do you measure cognitive load?

> "How many different teams/systems do I have to talk to, to answer these three questions?"

- Spin up a new service → 14 tickets?
- Deploy to production → 3 systems?
- Resolve an incident → 5 dashboards?

> If the number is high: cognitive load is **too much**. A signal that the
> platform team either doesn't exist or isn't effective.

---

## ⚙️ Practical organization maps

### Antipattern: the "DevOps Team"

```
[ Dev teams ] → [ DevOps team ] → [ Production ]
   N of them     single silo,      (gatekeeper)
                 bottleneck
```

**Problem:**
- DevOps team is the bottleneck
- Dev teams don't know operations
- "Throw it over the wall" culture
- DevOps gets paged at 2am — the product team sleeps

### Healthy: Stream-aligned + Platform

```
[ Stream-aligned x N ] ──── [ Platform team ]
   each one full-stack          self-service IDP
   owns + runs on-call          reusable workflow

           ↑
   [ Enabling teams (rare visits) ]
```

**Benefits:**
- Stream-aligned teams are fast, autonomous
- Platform standardizes from a single point
- Cognitive load stays manageable
- "You build it, you run it" — ownership

---

## 📐 Which team owns which area?

### Decision matrix

| Question | Answer | Team type |
|---|---|---|
| Does it produce value for the customer? | Yes | Stream-aligned |
| Does it provide infrastructure/tools to other teams? | Yes | Platform |
| Very specialized technical expertise? | Yes | Complicated subsystem |
| Do we want to spread a practice? | Yes | Enabling |

### Bad examples

- ❌ "Frontend team" + "Backend team" — Conway's law: monolithic backend / SPA
- ❌ "QA team" — quality is the stream-aligned team's job
- ❌ "Database team" — DBs are owned by stream-aligned teams, not a complicated subsystem

---

## 🏗️ Evolution by org size

### 5 engineers
- **1 stream-aligned team** = everyone
- No platform (tools + scripts are shared)

### 20 engineers
- **3-4 stream-aligned**
- No platform yet, but an "inner circle" volunteers to look after shared infrastructure

### 50 engineers
- **6-8 stream-aligned**
- **1 platform team (3-5 people)**
- Maybe 1 enabling team (for a specific need)

### 200+ engineers
- **20+ stream-aligned**
- **Multiple platform teams** (network, observability, dev tools)
- **Enabling teams** (security, performance)
- **Complicated subsystem teams** (if needed)

---

## 🔄 When to reorg?

### Signals (reorganize)

- 🚩 A new feature takes 6 months — coordination fatigue
- 🚩 "Go talk to that team" spread across 5 different tickets
- 🚩 Managers spend their time in coordination meetings
- 🚩 The architecture diagram doesn't look like the org chart

### Signals (leave it alone)

- 🟢 Teams are autonomous, manage their own backlogs
- 🟢 The platform team's NPS is high
- 🟢 A new engineer ships a prod commit within 1 week

---

## ⚠️ Common mistakes

| Mistake | Correct |
|---|---|
| Let's set up a "DevOps team" | Build a platform team, run it like a product |
| Make the manager the "bottleneck of decision" | Stream-aligned teams make autonomous decisions |
| The enabling team becomes permanent | It disbands or moves to another practice once the job is done |
| Platform team is ticket-driven | Backlog is self-managed, NPS is measured |
| "QA team" | Quality is the stream-aligned team's responsibility |
| A stream-aligned team grows past 9 people | Split it in two |

---

## 📋 Checklist

Before you call an org structure "Team Topologies compliant," verify the following:

- [ ] Every team maps cleanly to one type (stream-aligned / enabling / complicated subsystem / platform) — no "hybrid" teams
- [ ] Stream-aligned teams own an end-to-end flow: build + deploy + on-call sit in the same team ("you build it, you run it")
- [ ] No stream-aligned team exceeds 9 people (split it if it does)
- [ ] The platform team is run like a product: it has a roadmap, NPS is measured, it isn't ticket-driven
- [ ] Platform is self-service: spinning up a new service / deploying to prod takes one team and few steps
- [ ] There are no silo bottlenecks like a "DevOps team" / "QA team" / "Database team"
- [ ] Exit criteria are defined for enabling teams — they don't become permanent, they disband once the work is done
- [ ] Every team pair has an explicit interaction mode (collaboration / X-as-a-Service / facilitating), and time-boxed ones have an end date
- [ ] Cognitive load is measured: the count of "how many teams do I need to talk to for a new service / deploy / incident" is tracked
- [ ] Extraneous cognitive load (tooling/process mess) sits as a reduction goal on the platform team's backlog
- [ ] The architecture diagram reflects the org chart (Conway's Law) — mismatches are tracked as a reorg signal
- [ ] Reorg triggers are defined: feature lead time, coordination-meeting load, cross-team ticket count

---

## 📚 Further reading

- *Team Topologies* — Skelton & Pais (book, **must read**)
- [TeamTopologies.com](https://teamtopologies.com) — examples and workshops
- *Topologies of Team* — InfoQ talk (free on YouTube)
- [`13-Platform-Engineering/`](../13-Platform-Engineering/README.md) — platform team details

---

## 📚 References

- *Team Topologies* — Matthew Skelton & Manuel Pais (book, **must read**)
- [TeamTopologies.com](https://teamtopologies.com) — official site, examples and workshops
- [`13-Platform-Engineering/Platform-as-Product.md`](../13-Platform-Engineering/Platform-as-Product.md) — running the platform team like a product
- [`13-Platform-Engineering/Internal-Developer-Platform.md`](../13-Platform-Engineering/Internal-Developer-Platform.md) — self-service IDP details
- [`11-SRE/SLI-SLO-Error-Budget.md`](../11-SRE/SLI-SLO-Error-Budget.md) — the stream-aligned team's "you run it" responsibility
- [`20-Soft-Skills/Stakeholder-Management.md`](../20-Soft-Skills/Stakeholder-Management.md) — the human side of cross-team interaction modes

---

> *"You don't build your org chart around your architecture — you build your architecture around your org chart; so draw team boundaries by cognitive load and put an end date on every interaction mode, or Conway's Law will decide for you."*

---

> 🎓 **Learning Path:** This document is used as the "read first" resource in the [`F3`](../22-Learning-Path/block-f-judgment/F3-platform-idp.md) module.
