---
description: "Blameless postmortem philosophy and template: why blameless, blameful vs. blameless tone comparison, a filled-in example, and a checklist."
tags:
  - Culture
  - Incident Response
  - SRE
  - Template
---

# Blameless Postmortem — Philosophy and Template

> *"Blameless" doesn't mean "innocent"; it means **not assigning blame**.
> It means giving up focusing on people in order to understand a system failure.*

---

## 🎯 Why blameless?

In a blameful culture:
- Engineers **don't take risks** for fear of making mistakes → innovation dies
- The real root cause isn't reported, instead "hero X fixed it" is said
- The same incident happens again 6 months later
- The best engineers leave (the environment is toxic)

In a blameless culture:
- System weaknesses are surfaced with **pinpoint accuracy**
- Action items **actually** get closed
- A newcomer spends days reading old incidents and learning from them

---

## 🚫 Anti-examples (what a "blameful" tone looks like)

| Blameful | Blameless |
|---|---|
| "Charlie wrote the wrong code" | "Our code review process had no N+1 detector" |
| "The ops team deployed the wrong thing to prod" | "The manual deploy process was open to human error; automation was missing" |
| "The developer didn't write tests" | "Our test policy was local-only, there was no CI gating" |
| "The manager didn't approve it" | "Our approval flow had no defined escalation path" |
| "Charlie forgot" | "Our system wasn't tolerant of forgetting" |

> 🔑 **Rule:** Where you could say "X didn't do it," write "Our system wasn't resilient to X" instead.

---

## 📐 What is a postmortem? (scope)

- The causes, impact, timeline, and lessons learned **of an incident**
- Not a **static document** — it's reviewed, updated, and its actions are tracked
- Not secret — **open to everyone** within the company (any customer-impacting part is redacted if needed)
- Not an "incident report" — a **learning tool**

---

## ⏱️ When should it be written?

Triggers:
- ✅ Customer-impacting outage (always)
- ✅ SLO breach (error budget exhausted)
- ✅ Significant near-miss (didn't blow up but came close)
- ✅ Surprising behavior (the system behaved differently than expected)
- ✅ Requested manually

**First draft** within 24-48 hours. Finalized within 1 week. Every action must
turn into a ticket and be assigned an owner.

---

## 🧑‍💻 Roles

| Role | Responsibility |
|---|---|
| **Author** | Writes the postmortem (usually the IC = incident commander) |
| **Reviewer (≥2)** | Catches missing perspective, blameful tone, missing actions |
| **Service owner** | Owns the action items |
| **Engineering manager** | Tracks that actions get closed |

---

## 🧩 Postmortem Template (copy-and-fill)

> Ready-to-use template: [`17-Templates/runbooks/postmortem-template.md`](../17-Templates/runbooks/postmortem-template.md)

Sections:

```
1. TL;DR (3 sentences)
2. Impact (metric table: downtime, users, revenue, SLO impact)
3. Timeline (UTC, minute precision)
4. Root Cause (from a systems perspective)
5. Why wasn't it caught? (each defense layer)
6. What went well?
7. What didn't go well?
8. Action Items (owner, due, measurable)
9. Links to metric evidence (dashboard, PR, log)
10. Lessons learned
11. Postmortem participants
```

---

## 🛡️ Reviewer Checklist

The reviewer should check the following on a postmortem PR:

### Tone
- [ ] No sentence makes any person look at fault
- [ ] "Our system wasn't resilient to X" instead of "X didn't do it"
- [ ] No passive voice used (no hidden subject)

### Information
- [ ] Timeline is in UTC and minute-precise
- [ ] Impact is numeric (how many minutes, how many users, how much money)
- [ ] PR/commit/dashboard links are present

### Actions
- [ ] Every action has an owner and a due date
- [ ] Actions are **measurable** ("let's be more careful" is rejected)
- [ ] There is at least one "preventive" + one "detective" action
- [ ] Action items were opened as tickets in JIRA/Linear

### Systemic view
- [ ] There is "5 whys" depth (didn't stop at a surface-level answer)
- [ ] It's analyzed why multiple defense layers weren't enough
- [ ] It says "swiss cheese model," not "a linear chain of causes"

---

## 🧠 "5 Whys" — why 5?

To avoid getting stuck on a surface-level "cause." Example:

```
Q: Why was prod down for 14 minutes?
A: The new deploy's N+1 query choked the DB.

Q: Why wasn't the N+1 caught in review?
A: The reviewer didn't know the ORM's lazy-load behavior.

Q: Why didn't the reviewer know?
A: This pattern isn't taught in onboarding.

Q: Why isn't it in onboarding?
A: Onboarding is 6 months out of date, the ORM has changed since then.

Q: Why wasn't onboarding updated?
A: No owner; everyone expects "the platform team will do it."

→ Action: onboarding should have an owner + a review every 6 months.
```

You can't reach the real systemic cause without going 5 layers down.

---

## 🎬 The postmortem meeting (review)

The first draft, within 1 week — a one-hour meeting.

### Agenda (structure it)

```
[10 min] Author reads the postmortem out loud (everyone at the same baseline)
[20 min] Questions and gaps — "this part isn't clear"
[15 min] Action items — owner assignment, due date
[10 min] Other lessons learned — transfer to other services
[5 min]  Follow-up ownership
```

### The "devil's advocate" role

Deliberately assign someone to ask "did it really go well?" questions.
Prevents the postmortem from being biased.

---

## 📚 Postmortems' value grows over time

- **Institutional memory** — newcomers read them, don't repeat the same mistakes
- **Pattern detection** — if 6 postmortems show the same root cause, that's a **structural problem**
- **Onboarding tool** — a new engineer sees "which areas are dangerous"
- **External publication** — some companies publish sanitized postmortems publicly (e.g., Stripe, Cloudflare, GitHub) — builds community trust

> My recommendation: host postmortems somewhere like a **company wiki** or
> **internal blog**, make them searchable. They get lost in PDFs or
> closed docs.

---

## ✅ Healthy culture signals

- A junior engineer **isn't hesitant** to write a postmortem
- **>70% of action items close within 2 weeks**
- At least **1 postmortem** is produced every month (if not: either incidents are being missed, or they're being hidden under stress)
- Senior engineers **read postmortems on their own and learn from them**
- Postmortems say "team Y's trade-offs" instead of "Manager X decided this"

---

## 📚 Further reading

- [Etsy's Debriefing Facilitation Guide](https://etsyjs.gitbook.io/debriefing-facilitation-guide/)
- [Google SRE Book — Chapter 15](https://sre.google/sre-book/postmortem-culture/)
- *The Field Guide to Understanding Human Error* — Sidney Dekker
- [`17-Templates/runbooks/postmortem-template.md`](../17-Templates/runbooks/postmortem-template.md) — ready to use

---

## 📚 References

- [`11-SRE/Postmortem-Practice.md`](../11-SRE/Postmortem-Practice.md) — postmortem practice, deep examples
- [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md) — incident management, IC role, escalation
- [`00-Culture/On-Call-Playbook.md`](On-Call-Playbook.md) — on-call culture, ties to postmortem triggers
- [`07-Observability/SLO-Engineering.md`](../07-Observability/SLO-Engineering.md) — SLO breach → postmortem trigger chain
- [Google SRE Book — Postmortem Culture](https://sre.google/sre-book/postmortem-culture/) — reference source
- *The Field Guide to Understanding Human Error* — Sidney Dekker (book)

---

> *"The moment you ask who to blame, the postmortem dies; the right question is always 'how did the system make this failure possible?'"*

---

> 🎓 **Learning Path:** This document is used as the "read first" resource in the [`E3`](../22-Learning-Path/block-e-ownership/E3-incident-postmortem.md) and [`F4`](../22-Learning-Path/block-f-judgment/F4-yazma-adr-rfc.md) modules.
