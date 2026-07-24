---
description: "Explains how to turn blameless postmortem culture into a routine — the writing process, facilitation, action item management, and cultural sustainability."
tags:
  - SRE
  - Incident Response
  - Culture
  - Soft Skills
---
# Postmortem Practice — Making Blameless a Routine

> *"An incident with no postmortem written is an incident **preparing to
> happen again**. And a postmortem that's written but has no action items
> is **not a postmortem — it's a wake**."*

This guide explains how to turn blameless postmortem culture into a routine —
the writing process, facilitation, action item management, and **cultural
sustainability**.

---

## 🎯 Why Postmortem?

| Purpose | Explanation |
|---|---|
| **Learning** | So the same incident doesn't happen again |
| **System improvement** | Action item → permanent fix |
| **Knowledge sharing** | So people outside the team learn too |
| **Trust building** | The message "we took it seriously" to stakeholders |
| **Pattern discovery** | A common theme across 5 postmortems = systemic issue |

---

## 🚫 Blame ≠ Accountability

### Blame (don't)
- "Who did this?"
- "Why weren't they careful?"
- "This mistake must never happen again." (personal)

### Accountability (do)
- "Which mechanism failed to flag this?"
- "Which process was missing?"
- "How should the system change so this pattern doesn't recur?"

> 🔑 **Effect**: Blame culture → "no one admits a mistake" → big incidents
> grow silently. Blameless → the team reports without fear → fast detection.

> Detail: [`00-Culture/Blameless-Postmortem-Template.md`](../00-Culture/Blameless-Postmortem-Template.md)

---

## 📋 Postmortem Template

```markdown
# Postmortem: <SHORT_TITLE>
**Date of incident:** YYYY-MM-DD HH:MM (UTC)  
**Severity:** SEV-1 / SEV-2  
**Duration:** X minutes  
**Authors:** @<USER>  
**Status:** Draft / Review / Published  

## Executive Summary (3 sentences)
<What happened, how much it impacted, whether it's resolved.>

## Impact
- **Customers affected:** ~X% (Y people)
- **Revenue impact:** ~$Z
- **Data loss:** none / X records
- **SLO breach:** error budget X% consumed
- **Public communication:** status page + email

## Timeline (UTC)
| Time | Event |
|---|---|
| 15:30 | Deploy v1.4.2 started |
| 15:32 | Payment endpoint p99 50ms → 8s |
| 15:35 | Alert (PagerDuty SEV2) |
| 15:38 | On-call IC opened it |
| 15:42 | Root cause hypothesis: connection pool config |
| 15:45 | Mitigation: rollback started |
| 15:48 | Rollback complete, metrics normal |
| 15:50 | Status page: Resolved |

## Root Cause
<Technical detail: what caused what.>

> Was 5-Whys applied?
> 1. Why the outage? — Pool exhausted.
> 2. Why exhausted? — Pool size set from 100 → 50.
> 3. Why set to 50? — 50 was enough in test.
> 4. Why deploy 50 to prod? — Config is a single file, no env split.
> 5. Why no env split? — Kustomize migration was left incomplete.

## What went well
- IC role assigned quickly
- Rollback completed in 6 minutes
- Status page kept updated
- Customer support was ready

## What went wrong
- Test environment didn't represent prod load
- Config validation was missing (no CI gate)
- Alert fired 7 minutes late (early-warning gap)

## Where we got lucky
- Rollback was automatic
- Pool exhaustion within 5 min of deploy, during off-peak hours

## Action Items
| # | Action | Owner | Due | Priority |
|---|---|---|---|---|
| 1 | Finish env split with Kustomize | @platform | 2026-05-15 | P1 |
| 2 | CI gate: prod values diff review | @platform | 2026-05-08 | P0 |
| 3 | Load test with prod-like data | @qa | 2026-06-01 | P2 |
| 4 | Pool size early-warning alarm | @sre | 2026-05-12 | P1 |
| 5 | Config doc: pool sizing | @docs | 2026-05-20 | P3 |

## References
- Slack: #inc-2026-05-04-payment-degraded
- Bridge recording: <URL>
- Dashboard at incident: <URL>
- Related postmortems: INC-2026-02-08
```

---

## 🗓️ Postmortem Calendar

```
T+0       Incident resolved
T+30 min  Hot wash (quick retro on the bridge, 30 min)
T+1 day   Author assigned (usually the IC)
T+3 days  Draft ready → share for review
T+5 days  Review meeting (60 min)
T+5 days  Published — wiki / Backstage / repo
T+30 days Action item check (who completed what, how much)
T+90 days Pattern review (trend across the last 3 months of postmortems)
```

> 🔑 The **5 business days** rule. Otherwise memory blurs and action items get lost.

---

## 🎤 Review Meeting Facilitation

### Participants
- IC (incident commander)
- SMEs (the ones who did the debugging)
- Manager (team lead)
- Stakeholder (PM, customer success — optional)
- Skip-level senior (looks for patterns)

### Flow (60 minutes)
```
0-5 min:    Tone setting (blameless reminder)
5-15 min:   Timeline review
15-25 min:  Root cause discussion + 5-whys
25-35 min:  "What went well" — credit to the team
35-45 min:  "What went wrong" + "lucky"
45-55 min:  Finalize action items (owner + due)
55-60 min:  Publication approval + communication plan
```

### The facilitator's role
- When you sense "blame," gently redirect ("What's the system perspective?")
- Invite the quiet ones to speak
- Make the action item **clear** (don't accept anything vague)
- Being able to say "this topic doesn't belong here" (scope creep)

---

## 📊 Action Item Management — The Weakest Link

> Postmortem written, no one did the action item → 6 months later, **the same incident**.

### Rules
1. **Owner** is a person (not a team)
2. **Due date** specific (not "the last day of the sprint," not "Q3")
3. **Priority** P0-P3 (P0 = immediately)
4. **Tracking** — JIRA/Linear/GitHub Issue
5. **Status check** mandatory after 30 days
6. **Escalation** — escalate overdue ones to the owner's manager

### Dashboard
```
Postmortem Action Items
├── Open: 23
│   ├── Overdue (>30 days): 5 ⚠️
│   ├── In progress: 12
│   └── New: 6
├── Closed (last 90 days): 47
└── Pattern: connection pool issues = 4 postmortems
```

> 🔑 Quarterly review: discovers patterns. Same cause in 3+ postmortems
> → systemic project (e.g., "platform connection pooling overhaul").

---

## 📈 Postmortem Metrics

| Metric | Target |
|---|---|
| **Incident → postmortem published** time | < 7 days |
| **Action item completion** (within due date) | > 80% |
| **X% of postmortems** prevent an incident via their action items | Trend up |
| **Public postmortem** count (transparency) | For specific SEV-1s |
| **Pattern detection** (same root cause recurring) | Trend down |

---

## 🌐 Public Postmortem (B2B Customer)

Some incidents get written **publicly**:
- High customer impact (>5% outage)
- Customer trust required (SaaS)
- B2B SLA breach

### Good public postmortem examples
- Cloudflare incident reports
- GitHub status & postmortems
- AWS Service Health Dashboard postmortems

### Writing it publicly
- Simplify the internal postmortem
- No PII/secrets
- Clear timeline + impact + cause
- Don't be afraid to say "Sorry" (but don't overdo it)
- Action item summary (details internal)

---

## 🎯 Postmortem Quality: Rubric

Score the written postmortem (in PR review):

| Criterion | 0 | 1 | 2 |
|---|---|---|---|
| Is the timeline clear? | None | General | Second-minute basis |
| Root cause | "Bug" | Technical explanation | 5-whys applied |
| Impact measured | No | Approximate | Customer count + revenue |
| What went well | Skipped | 1-2 items | Credit to team + what helped |
| Action item: owner+due | None | Owner only | Owner + due + priority |
| Blameless language | "X did it" | Mixed | System-perspective |
| Pattern linkage | Single incident | Mentioned | Related to previous postmortems |

> Total < 8 out of 12 → **revise**.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | The right way |
|---|---|---|
| Postmortem 3 weeks later | Memory blurs | The 5-business-day rule |
| "X did this, they should be careful" | Blame, fear culture | System-perspective language |
| Action item: "Let's be more careful" | Not measurable | Specific task + owner + due |
| Countless action items but none close | Not visible | Tracking + 30-day check |
| A 1-page short postmortem (for a SEV-1) | Missing detail, no learning | Detailed + timeline |
| A 30-page postmortem | No one reads it | Detail present but executive summary in 3 sentences |
| Secret postmortem | Outside the team no one learns | Internal-public; public for SEV-1 |
| Same root cause in 3 postmortems | Pattern missed | Pattern review project |
| "Lucky" section skipped | Risk assessment missing | Where we got lucky, always |
| The people writing postmortems are **always the same** | Burnout | Rotation: not the IC, someone from the team |
| Public postmortem waits for PR/marketing approval | Delayed by 2 weeks | Pre-templated + fast DPO/Legal review |

---

## 🎓 Postmortem Writing Training

### Onboarding a new engineer
1. Read the last 3 postmortems
2. **Shadow** the facilitation of one postmortem
3. Write the second postmortem as **co-author**
4. Solo from the third onward

### Quarterly drill
- Simulate a past incident
- Have the new engineer write the postmortem
- Senior review + feedback
- "Postmortem game day" — fun & instructive

---

## 📋 Postmortem Discipline Checklist

```
[ ] SEV-1 + SEV-2 always get a postmortem
[ ] Author assigned within 24 hours (usually the IC)
[ ] Draft within 3 business days
[ ] Review meeting within 5 business days
[ ] Published within 7 business days
[ ] Template is used (timeline, root cause, AI)
[ ] 5-Whys done
[ ] Action item: owner + due + priority
[ ] Action item tracking (JIRA/Linear)
[ ] 30-day action check
[ ] Quarterly pattern review
[ ] Public postmortem (B2B / high SEV-1)
[ ] Postmortem reviewed with the rubric
[ ] Blameless language enforced
[ ] New engineer onboarding from postmortems
[ ] Postmortem writing rotation (not just seniors)
```

---

## 📚 References

- **Google SRE Book** — Chapter 15: Postmortem Culture
- **Etsy Debriefing Facilitation Guide** — the gold standard for facilitation
- **PagerDuty Postmortem Documentation**
- **VOID Project** — public postmortems database
- [`Incident-Response.md`](Incident-Response.md)
- [`Runbook-Template.md`](Runbook-Template.md)
- [`00-Culture/Blameless-Postmortem-Template.md`](../00-Culture/Blameless-Postmortem-Template.md)
- [`17-Templates/runbooks/postmortem-template.md`](../17-Templates/runbooks/postmortem-template.md)
- [`20-Soft-Skills/Oncall-Sustainability.md`](../20-Soft-Skills/Oncall-Sustainability.md)

---

> *"A postmortem is not a 'history report' — it's a user manual written to
> **prevent the next incident**. When it's written, the team learns; when the
> action item closes, **the system learns**."*
