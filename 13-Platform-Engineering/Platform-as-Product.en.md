---
description: "Concrete ways to run Platform Engineering as a product discipline: the philosophy of treating the developer as a customer, NPS measurement, roadmap, OKRs, beta programs, and evangelism."
tags:
  - Platform Engineering
  - Culture
  - Soft Skills
  - Roadmap
---
# Platform-as-Product — Internal Customer Satisfaction

> *"The platform team's product isn't 'a tool' — it's an **internal
> product delivered to other engineers**. Customer = developer. A
> product whose customer satisfaction isn't measured **fills up with
> bypasses within 6 months**."*

This guide covers the concrete ways to run Platform Engineering as a
**product discipline** — NPS measurement, roadmap, OKRs, beta
programs, evangelism.

---

## 🎯 Philosophy Shift

| **DevOps team** (old model) | **Platform-as-Product** (new) |
|---|---|
| "We respond to tickets" | "We build a product" |
| "Our tool is mandatory" | "Our tool is preferred" |
| No backlog, reactive | Roadmap + OKR |
| Quality isn't measured | NPS + adoption + lead time |
| Manager runs the team | Product manager (PM) on the team |
| "The engineer should work for us" | "We work for the engineer" |

> 🔑 **Product mindset**: keep asking, **am I making the customer's
> (the developer's) job easier?**

---

## 📊 Customer (Developer) NPS

> **NPS (Net Promoter Score)**: "Would you recommend this platform to
> a friend?" 0-10 scale. Promoters (9-10) - Detractors (0-6) = NPS.

### Quarterly survey
```
1. Score 0-10 for your experience using the Backstage portal?
2. Did you hit platform friction this past sprint? (yes/no)
3. What was the biggest friction point?
4. Which platform feature do you like the most?
5. One suggestion for next quarter?
```

### Targets
| NPS | Meaning |
|---|---|
| > 50 | Excellent |
| 30-50 | Good |
| 0-30 | Average — needs improvement |
| < 0 | Bad — crisis |

### NPS trend
```
2025-Q1: 12  (just launched, mostly manual)
2025-Q2: 28  (Backstage adoption kicked off)
2025-Q3: 41  (3 golden paths live)
2025-Q4: 55  (cost insights + on-call integration)
2026-Q1: 47  (growth, new teams not yet acclimated)
```

> 🔑 An NPS drop = **red flag**. Review detractor feedback.

---

## 🗺️ Platform Roadmap

### Structure (3 horizons)
```
Horizon 1 (0-3 months): Current adoption + sustain
  - Bug fixes, small improvements
  - Integrate existing paths with the pre-prod path

Horizon 2 (3-9 months): Differentiating capabilities
  - 3 new golden paths
  - Cost insights v2 (deeper Kubecost integration)
  - Multi-cluster catalog

Horizon 3 (9-18 months): New territory
  - Compose pattern: developer picks their own components
  - AI-assisted scaffolding
  - Compliance automation (SOC2 controls made visible)
```

### Roadmap visibility
- "Platform Roadmap" page in Backstage
- Quarterly demo days (new features)
- Slack #platform-announce channel

---

## 🎯 Platform OKRs

### Example (Q3-Q4)
```
Objective: Get new-service onboarding time under 30 minutes.

Key Results:
- KR1: Backstage scaffolder adoption at 85% (currently 60%)
- KR2: Median onboarding time < 30 min (currently 45 min)
- KR3: Onboarding NPS > 40 (currently 32)


Objective: Reduce platform friction.

Key Results:
- KR1: DevOps ticket count down 40%
- KR2: Self-service rate > 80%
- KR3: Quarterly NPS > 45
```

### OKR adoption
- Quarterly review meeting
- Public dashboard (visible to the team + management)
- "Did not hit" KRs get a postmortem (why?)

---

## 👥 Platform Team Structure

### Roles
```
Platform Lead          → Vision, stakeholder management
Platform PM            → Roadmap, customer research
Senior Engineers (2-4) → Build & maintain
DevX Engineer          → Docs, evangelism, onboarding
SRE                    → Reliability of the platform itself
```

### Staffing ratio
- **1 platform engineer : 50 product engineers** (sweet spot)
- < 1:50 — platform team overworked
- > 1:50 — unnecessary headcount

---

## 🎤 Customer Research

### 1. **User Interview** (quarterly)
- 30-45 min conversation with 5-10 engineers
- "What were you trying to get done this past month? Where did you get stuck?"
- Open questions, **listen** rather than propose solutions

### 2. **Office Hours** (weekly)
- Platform team available 2-3 hours
- Engineers can ask, drop by
- Patterns surface → feed the roadmap

### 3. **Slack Listening**
- #platform-help channel
- Questions reveal patterns
- If "are you doing X" gets asked 5 times → it's a doc gap

### 4. **Telemetry**
- Backstage click data
- Scaffolder usage
- Search queries (what's searched for most?)

---

## 📣 Evangelism (Drives Adoption)

### Internal marketing
| Channel | Frequency |
|---|---|
| Demo Day | Monthly |
| Newsletter | Weekly (new features, tips) |
| Lunch & Learn | Monthly (interactive) |
| Onboarding talk | Mandatory for new devs |
| Platform Office Hours | Weekly |
| Slack updates | Ongoing |

### Share "win" stories
> "The Payments team spun up a new service in 12 minutes (used to take 4 weeks)."

→ **Inspires** other teams.

---

## 🚧 Beta Program

### New feature rollout strategy
```
1. Internal proposal (RFC)
2. Beta partner team (1-2)
3. 4-8 week beta
4. Collect NPS + feedback
5. GA decision
6. Roll out to all teams
```

### Choosing beta partners
- Teams open to new technology
- Written agreement with the manager (they must allocate time)
- Feedback is valued, "happy if you file bug reports"

---

## 💸 Cost Transparency

### Make platform cost visible
- "Running Backstage costs the team $X/month"
- Per-team: "Your team's platform usage costs $Y/month"
- ROI: "Savings $X, cost $Y, net $Z"

### The "build vs. use" debate
- Convert the hours the platform team saves → into money
- Convert the velocity the product team gains → into money
- "Our platform team produces 5x its own cost in value"

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Do this instead |
|---|---|---|
| Platform is "mandatory" | Bypasses start | Self-service + escape hatch |
| NPS isn't measured | "Adoption is going fine" claims | Quarterly NPS |
| No roadmap | Reactive ticket factory | OKR + 3-horizon |
| No PM | Purely technical decisions | Product mindset |
| No customer research | Doesn't know what the product needs | User interviews + office hours |
| No Demo Day | Team doesn't know the platform | Monthly demo |
| No cost transparency | No answer to "is it expensive? is it useful?" | Per-team cost dashboard |
| Beta skipped, big-bang launch | Bugs in production | Beta → GA |
| Platform team isolated | "Goes through us" silo | Pair / shadow with product teams |
| No onboarding doc / stale doc | New engineers aren't self-serve | TechDocs + kept current |
| Platform team success measured as "tool count" | Unused tools pile up | Adoption + NPS |
| 1 platform : 200 devs | Burnout | 1:50 ratio |

---

## 📋 Platform-as-Product Checklist

```
[ ] Platform PM assigned (or rotating)
[ ] Roadmap public (3-horizon)
[ ] OKR quarterly + dashboard
[ ] NPS quarterly survey
[ ] User interviews (5+ engineers quarterly)
[ ] Weekly office hours
[ ] Monthly Demo Day
[ ] Newsletter / Slack updates
[ ] Beta program (for new features)
[ ] Adoption dashboard (per path, per plugin)
[ ] Cost transparency (per-team)
[ ] Platform team:dev ratio ~1:50
[ ] Onboarding talk for new devs
[ ] Customer success stories get shared
[ ] Quarterly retro (within the platform team)
[ ] Detractor feedback reviewed one by one
[ ] Platform change notifications (#platform-announce)
[ ] Backwards-compatibility commitment
[ ] Sunset policy: deprecate → 6 months → remove
```

---

## 📚 References

- **Team Topologies** (Skelton, Pais)
- **Platform Engineering** — platformengineering.org
- **The Lean Product Playbook** — Dan Olsen
- **Inspired** — Marty Cagan
- **Internal Developer Platform Maturity Model** — platformengineering.org/maturity-model
- [`Internal-Developer-Platform.md`](Internal-Developer-Platform.md)
- [`Backstage-Setup.md`](Backstage-Setup.md)
- [`Golden-Paths.md`](Golden-Paths.md)
- [`Service-Catalog.md`](Service-Catalog.md)
- [`20-Soft-Skills/Stakeholder-Management.md`](../20-Soft-Skills/Stakeholder-Management.md)

---

> *"Platform-as-Product isn't 'a new buzzword' — it's a **discipline
> shift**. A platform team that treats the engineer as a real
> **customer**, that **measures their NPS**, can **defend its own
> budget with ROI**."*

---

> 🎓 **Learning Path:** This document is used as a "read first"
> resource in the [`F3`](../22-Learning-Path/block-f-judgment/F3-platform-idp.md) module.
