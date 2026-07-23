---
description: "Stakeholder management guide for multi-stakeholder DevOps/SRE work — who gets told what, in what language, and how much, covering management, product, customers, legal, and security."
tags:
  - Soft Skills
  - Culture
  - Career
  - SRE
---
# Stakeholder Management — Who, in What Language, How Much

> *"If you can explain the same outage story to the CTO in 30 seconds,
> to customer support in 3 sentences, and to the customer in 3
> paragraphs, you're not an engineer — you're a **communication
> translator**, and that makes you **very valuable**."*

DevOps/SRE/Platform work is **multi-stakeholder**. Management, product,
customers, legal, finance, security — each expects a different
language. This guide answers the question "who do you talk to, and
how."

---

## 🎯 Stakeholder Map

```
                  ┌────────────────┐
                  │   Executive    │  → "Business impact, cost, risk"
                  │  (CEO, CTO)    │
                  └────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Product    │  │ Engineering  │  │  Operations  │
│   (PM)       │  │    team      │  │  (Support,   │
│              │  │              │  │   QA, Sales) │
└──────────────┘  └──────────────┘  └──────────────┘
        │                                  │
        ▼                                  ▼
┌──────────────┐                   ┌──────────────┐
│  Customer    │                   │  Vendor      │
│  (B2B/B2C)   │                   │  (cloud, etc)│
└──────────────┘                   └──────────────┘

       ┌───────────────────────────────────┐
       │  Horizontal stakeholders (always) │
       │  Legal · Security · Finance · HR  │
       └───────────────────────────────────┘
```

---

## 🗣️ Which Language for Which Stakeholder

### Executive Leadership (CEO, CTO, CFO)
| What they expect | What they hate |
|---|---|
| **Business impact** ($, customer count) | Technical jargon |
| Risk (high/medium/low) | "Maybe, if" |
| Are they being asked for a **decision** or just **information**? | Long emails |
| Do you have a clear recommendation? | The question "what do you want me to do?" |

#### Template: an incident summary (for the CEO)
```
What:    Payment endpoint was down for 18 minutes (15:30-15:48).
Impact:  ~340 customers affected, ~$12K in lost revenue.
Cause:   The last deploy dropped the DB connection pool from 100 to 50; the pool was exhausted during a traffic spike.
Fix:     Rolled back, pool raised to 200.
Action:  Postmortem within 5 business days. No budget impact.
```

> 🔑 **5 lines.** The CEO reads it in 30 seconds — if they have questions, they'll ask.

#### Template: an investment request
```
PROBLEM: K8s cluster is on version 1.24 (EOL March 2026). If we don't upgrade, we lose security patches and support.

SOLUTION: Phased upgrade to 1.30 — 6 weeks + 1 engineer.

COST: ~$15K (overtime; downtime risk is minimal — blue/green deploy).

RISK OF NOT ACTING: If we delay the upgrade, we're exposed to a CVE by September 2026, face an audit finding, and $100K+ in remediation costs.

RECOMMENDATION: Let's do it in sprints 24-26.
```

### Product Manager (PM)
| What they expect | What they hate |
|---|---|
| Feature impact (delivery date, capacity) | Vague terms like "performance" |
| Trade-offs (if we do X, Y slips) | Getting stuck in obsessive technical debate |
| **User impact** | An "I can't do it" answer with no alternative |

#### Template: a capacity conversation
```
PM: "Can we fit 5 features into this sprint?"

Me: "We can fit all 5, but:
      - Testing time gets squeezed → 20% higher P95 bug risk
      - Deploy conflicts → rollback risk
      
      My recommendation: 3 features + 1 platform improvement (fundamentals
      for next quarter). Which one should we drop?"
```

### Engineering Team
| What they expect | What they hate |
|---|---|
| Clear technical discussion | "Management-speak" |
| The reasoning behind your decision | Appeals to authority |
| An invite to pair / pair coding | Top-down orders |
| RFC + discussion | Presenting the decision as a fait accompli |

### Customer Support / Sales
| What they expect | What they hate |
|---|---|
| "Which customers were affected?" | Technical detail |
| What they can tell the customer | A vague "we're fixing it" |
| A callback/follow-up time | Open-ended answers |

#### Template: an outage update for the support team
```
[OUTAGE - Payment - SEV2]

Status:  ACTIVE - Investigating
Started: 15:30
Affected: ~35% of EU traffic, payment endpoint
Tell the customer: "Some of our customers may be experiencing delays on the payment page; the team is actively working on it. Affected customers get a full refund plus an extra 30 days of service credit."
ETA: ~30 min
Next update: 16:00
```

### Customer (B2B / B2C)
| What they expect | What they hate |
|---|---|
| Ownership | The "vendor problem" excuse |
| Clear next steps | "We're investigating" and nothing else |
| A compensation option (for serious outages) | Silence |
| Regular updates | Random, ad-hoc communication |

### Legal
| What they expect | What they hate |
|---|---|
| Legal risk assessment | "That's how we've always done it" |
| Data flow documentation | Verbal promises |
| Taking deadlines like the 72-hour KVKK (Turkey's Personal Data Protection Law, No. 6698) notification window seriously | "We'll look at it tomorrow" |

### Finance
| What they expect | What they hate |
|---|---|
| Cost forecast | "It might grow" |
| Unused capacity report | Surprise bills |
| ROI calculation for investments | "It'll pay off long-term" |

---

## 📊 Communication Type: When to Use What

| Type | When | Example |
|---|---|---|
| **Meeting (sync)** | A decision is needed + 3+ people | RFC review, incident bridge |
| **Slack thread** | Fast, async is fine | Status update, question |
| **E-mail** | Action list + N people | Outage summary (post-resolve), monthly metrics |
| **RFC / Design Doc** | Major decision, future readers | Service mesh adoption |
| **Status page** | Customer-facing | Outage |
| **Dashboard** | Continuous, automated | Cost, SLO |
| **1:1 meeting** | Sensitive, personal | Performance, career |

> 🔑 **A meeting isn't the default.** Before saying "this meeting could've been an email,"
> ask "could this email have been a dashboard?"

---

## 🚦 Escalation Framework

### The 4-Step Escalation (for DevOps)
```
1. Direct fix → within your own team, async
2. Manager → raise it in standups
3. Skip-level → your manager's manager (in a 1:1)
4. CTO/VP → critical, real budget / organizational issue
```

### Escalation language
**Don't:**
- "I'm going to take this to my manager." (comes across as a threat)

**Do:**
- "We'll need our managers' support to resolve this. Should we work out a plan together before I take it to my manager?"

> 🔑 Escalation = **not a surprise**. It's mutual information-sharing.

---

## 📝 Writing an RFC / Design Doc

### When is an RFC needed?
- Requires 1+ month of work
- Affects 3+ teams
- Hard to reverse (architectural decision)
- Budget investment (>$X)
- Previously discussed, being reopened

### RFC anatomy
```markdown
# RFC: <TITLE>
**Status:** Draft / Review / Accepted / Rejected  
**Author:** @<USER>  
**Reviewers:** @<USER>, ...  
**Date:** YYYY-MM-DD  
**Decision deadline:** YYYY-MM-DD

## TL;DR (3 sentences)
<Decision, motivation, impact>

## 1. Problem
<Why we're discussing this>

## 2. Proposal
<Proposed approach>

## 3. Alternatives Considered
- A: ... (why not)
- B: ... (why not)
- Selected: ...

## 4. Detailed Design
<Architecture, sequence diagram, API>

## 5. Trade-offs
- Pro: ...
- Con: ...

## 6. Risks & Mitigations
| Risk | Mitigation |

## 7. Decision Required
<The decision this RFC produces must be unambiguous>

## 8. Timeline
<Stages + dates>

## 9. References
```

### RFC review flow
1. **Draft** — author only, closed
2. **Review** — stakeholders comment (1 week)
3. **Decide** — meeting + decision (30 minutes)
4. **Accepted / Rejected** — written outcome (who, why)

> 🔑 An RFC **without a meeting** is fine; an RFC **without a decision** is not.

---

## ⚖️ Saying "No"

See [`Saying-No.md`](Saying-No.md) — the essence of this soft skill.

### The short formula
```
Yes-If: "I can do it, but only if we drop X."
Not-Now: "Not this quarter, but in Q3."
Not-By-Me: "This isn't my domain; team X is a better fit."
Not-Worth-It: "The cost/benefit doesn't work — here are the numbers..."
```

---

## 💬 Conflict Resolution

### Engineer ↔ PM conflict
- Common ground: customer impact
- Talk data: "This feature affects 2% of customers; tech debt affects 30% of deploy time."
- Surface the trade-off: "We can't do both — which metric do we prioritize?"

### Engineer ↔ Security
- See [`Working-with-Security-Team.md`](Working-with-Security-Team.md)

### Engineer ↔ Engineer (technical debate)
- "What data should decide this?"
- Disagree-and-commit: make the call, execute, validate against the outcome

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Do instead |
|---|---|---|
| A 30-minute technical walkthrough for the CEO | They won't follow it, decision stalls | 5-line TL;DR |
| Pitching a "performance improvement" feature to the PM | Too abstract | "P95 200ms → 50ms; checkout success rate up 3%" |
| Telling the customer "we're investigating" for 4 hours | Erodes trust | Regular 30-min updates |
| Surprise escalation | Creates a hostile atmosphere | Give the manager a heads-up first |
| Writing an RFC for a meeting | Nobody comes prepared | RFC first, decide in the meeting |
| No async communication | Meeting fatigue | Slack + RFC + dashboard |
| Decisions made "without communication" | No ownership, can't be walked back | Decision log + announcement |
| Notifying Legal late | Violates the KVKK 72-hour window | Involve Legal from day zero |
| Saying "it's a vendor problem" | No ownership | "We're working with the vendor; ETA X" |
| Status page not kept current | Customers vent on Twitter | 30-min update SLA |

---

## 📋 Communication Hygiene Checklist

```
[ ] Stakeholder map is up to date (who wants what)
[ ] Templates ready: outage update, RFC, executive summary
[ ] Slack channel hygiene: #incidents, #platform-changes, etc.
[ ] Status page: customer-facing, auto-updated
[ ] RFC culture: mandatory for 1+ month of work
[ ] Decision log (in Confluence / Notion / Git)
[ ] Quarterly: stakeholder NPS / feedback
[ ] 1:1s: manager, peer, skip-level, held regularly
[ ] Onboarding: teach new engineers the communication norms
[ ] Communication angle in postmortems: "was there a communication gap?"
```

---

## 📚 References

- **The Manager's Path** — Camille Fournier
- **Crucial Conversations** — Patterson et al.
- **Staff Engineer** — Will Larson
- **Writing for Developers** — Piotr Sarna
- [`Working-with-Security-Team.md`](Working-with-Security-Team.md)
- [`Saying-No.md`](Saying-No.md)
- [`Documentation-as-Communication.md`](Documentation-as-Communication.md)

---

> *"When your stakeholder doesn't understand your engineering,
> **technical correctness** isn't a win. Communication isn't
> engineering's **complement** — it's its **multiplier**."*

---

> 🎓 **Learning Path:** This document is used as a "read first" resource in the [`F5`](../22-Learning-Path/block-f-judgment/F5-stakeholder-vendor.md) module.
