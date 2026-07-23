---
description: "A practical guide that gives clear answers to what to do, who says what, and who decides when an incident hits production; focused on the IC role, severity, and communication."
tags:
  - SRE
  - Incident Response
  - Monitoring
  - Soft Skills
---
# Incident Response — The Anatomy of Firefighting

> *"The difference between a team that closes an incident in 30 minutes and one that takes 4 hours is not the team's skill — it's the **procedure**."*

This guide gives clear answers to "what to do, who says what, who
decides" when a fire breaks out in production. Not a slogan — you pull it
up and apply it while on-call.

---

## 📐 Core Definitions

| Term | Meaning |
|---|---|
| **Incident** | An unexpected service degradation that impacts users or risks impacting them. *Bug ≠ incident.* |
| **Severity (SEV)** | Magnitude of impact. SEV1 → catastrophe, SEV4 → cosmetic. |
| **Incident Commander (IC)** | The **single person** who runs communication and decisions. Not an engineer, a coordinator. |
| **Subject Matter Expert (SME)** | The person(s) doing the technical debugging. |
| **Communications Lead (CL)** | The person who posts announcements to stakeholders and the status page. |
| **Scribe** | The person keeping the timeline down to the second (critical for the postmortem). |
| **MTTD** | Mean Time To Detect. *The time to learn it happened.* |
| **MTTR** | Mean Time To Recover. *The time to get back to green.* |
| **Blast radius** | The percentage of affected tenants/users. |

> 🔑 **The one rule:** **Who** opens the incident must be decided up front. "Whoever gets the PagerDuty alert is the IC" — this saves the first 5 minutes.

---

## 🚨 Severity Matrix

Every company has its own definition; the one below can be used as a **reference**.

| SEV | Definition | Example | Response time | Communication |
|---|---|---|---|---|
| **SEV1** | All users affected, revenue may be leaking | Login down 100%, payments down, data breach | IC + 2+ SME **within 5 min** | Status page + customer email + executive |
| **SEV2** | A major feature broken or one tenant fully down | Search not working, EU region down, p99 latency 10x | IC + 1 SME within **15 min** | Status page + #incidents channel |
| **SEV3** | Performance degraded or partial impact | p95 50ms→200ms, one endpoint 2% errors | SME within **30 min**, IC optional | Internal channel |
| **SEV4** | Not reached users, risky condition | Replica dropped but HA held, disk 85% | Within business hours | Ticket |

### Who decides the severity?
- The person who opens it first makes a **maximum estimate** (SEV1 instead of SEV2; downgrading later is fine).
- The IC confirms/changes it in the first 10 minutes.
- It's not "you can upgrade but not downgrade" — quite the opposite: **unnecessary panic is cheaper**. Starting as SEV1 and dropping to SEV3 after 20 minutes does far less damage than starting SEV3 and realizing "it was actually SEV1" an hour later.

---

## 🎭 Roles (who does what)

```
                        ┌─────────────────────┐
                        │  INCIDENT COMMANDER │
                        │   (IC) - 1 person   │
                        │                     │
                        │  Decides,           │
                        │  coordinates comms, │
                        │  directs the SMEs.  │
                        │  DOES NO TECH WORK. │
                        └──────────┬──────────┘
                                   │
                ┌──────────────────┼──────────────────┐
                ▼                  ▼                  ▼
      ┌─────────────────┐  ┌──────────────┐  ┌──────────────┐
      │  SME(s)         │  │  COMMS LEAD  │  │  SCRIBE      │
      │  Debugs,        │  │  Status page │  │  Timeline    │
      │  proposes fix.  │  │  customer DM │  │  second-ms   │
      └─────────────────┘  └──────────────┘  └──────────────┘
```

### The IC's golden rules
1. **Don't touch the keyboard.** You're the IC, not an engineer. The SME runs commands.
2. **Ask for an update every 15 minutes.** Break the SMEs' "let me look a bit more" loop.
3. **Decide, don't take a vote.** "We're rolling back, 5 minutes." — end the debate.
4. **You call the end.** The incident isn't over until you say "Resolved"; an SME may *feel* like it's fixed.

### To be an IC
- ✅ Know the system's overall architecture (not every service)
- ✅ Be able to stay calm
- ✅ Be able to say "I don't know, ask the SME"
- ❌ Be the most senior engineer (usually the opposite — they should be the most senior SME)

---

## ⏱️ Incident Flow (10 steps)

### 1️⃣ Detect — Learn about the event
**Source priority order:**
1. Automated alert (Prometheus/Datadog/Sentry → PagerDuty)
2. Customer report (support → #incidents)
3. Upper management ("the CEO's friend complained")

> ⚠️ If **the customer tells you** first, your monitoring is **broken**.
> It goes down in the postmortem as an "alerting gap".

### 2️⃣ Acknowledge — "I've got it"
Ack in PagerDuty/Opsgenie **within 5 minutes**. Otherwise escalation kicks in.

### 3️⃣ Open the bridge — Open the rally point
- Slack: `#inc-2026-05-04-payment-down` (permanent, for the postmortem)
- Zoom/Meet: video bridge (screen sharing is critical)
- Status page: first draft, `Investigating` status

```
[15:42] @oncall: SEV2 opened. Payment endpoint p99 8s, 5xx 12%.
[15:42] IC: me (Halil). SME: @backend-oncall. Comms: @support-lead.
[15:43] Bridge: meet.google.com/<MEETING_ID>
[15:43] Slack: #inc-2026-05-04-payment-degraded
```

### 4️⃣ Assess — Must be answered in the first 10 minutes
| Question | Answer |
|---|---|
| What's broken? | Payment endpoint latency + 5xx |
| How many users affected? | 35% (EU traffic) |
| Since when? | 15:30, near the last deploy |
| Recent change? | 15:25 deploy: `payment-svc v2.4.7` |
| Reproducible? | Yes, `curl` returns in 8s |

> 🔑 The **recent change** question is **always** the first question. 70% of incidents come from a change made in the last 24 hours.

### 5️⃣ Mitigate — NOT root cause, stop the bleeding
Mitigation options (priority order):
1. **Rollback** — is the last deploy suspect? Roll it back without a 1% doubt.
2. **Feature flag off** — turn off the new feature.
3. **Traffic shift** — redirect to another region.
4. **Scale up** — if you suspect saturation.
5. **Restart** — last resort; you lose the cause (was a memory dump taken?).

> ⚠️ **Mitigate ≠ Fix.** Right now your goal is to stop the bleeding. Root cause goes in the POST.

### 6️⃣ Communicate — Keep the status page current
**Update interval:**
- SEV1: every **15 minutes**
- SEV2: every **30 minutes**
- "No info" is an update too: *"Investigation ongoing, next update at 16:30."*

**Status page draft:**
```
[15:50] Investigating — Some of our users may be experiencing
delays on the payment page. The engineering team is looking into it.

[16:05] Identified — We've traced the problem to the last deploy, rolling it back.

[16:18] Monitoring — Rollback complete, we're watching the metrics.

[16:35] Resolved — Back to normal for all users.
A detailed postmortem will be published within 5 business days.
```

> 🇹🇷 **KVKK note:** If there is a personal data breach, notifying the KVKK
> is mandatory **within 72 hours**. The status page text must clear the legal team.
> See: [`19-Compliance/KVKK-Practical.md`](../19-Compliance/KVKK-Practical.md).

### 7️⃣ Resolve — Green
- Metrics at normal values for 15 minutes
- Customer reports have stopped
- IC says `Resolved` → status page is updated → `[RESOLVED]` tag on the channel

### 8️⃣ Hotwash — Within 30 minutes
A short retro before the bridge closes:
- What worked?
- What couldn't we do?
- Which tool was missing?
- Did the IC coordinate well?

Notes are prepared for the postmortem.

### 9️⃣ Postmortem — Within 5 business days
Use the [`Blameless-Postmortem-Template.md`](../00-Culture/Blameless-Postmortem-Template.md)
and [`17-Templates/runbooks/postmortem-template.md`](../17-Templates/runbooks/postmortem-template.md)
templates.

### 🔟 Action items — owner + due date
- Every action item needs a **person** and a **date**
- A "team" cannot be the owner
- An action item without a due date never closes

---

## 🛠️ Practical Tooling

| Need | Recommended | Alternative |
|---|---|---|
| Alerting + on-call rotation | PagerDuty | Opsgenie, Grafana OnCall (open-source) |
| Status page | Statuspage.io, Better Stack | cstate (self-hosted), Instatus |
| Incident channel creation | [Incident.io](https://incident.io), Rootly | Slack workflow + custom bot |
| Timeline / scribing | Incident.io automatic | FireHydrant, manual Slack thread |
| Postmortem writing | Jeli.io, Incident.io | Notion + template |
| Chatops bot | Slack `/incident` workflow | Custom (Python+slack-sdk) |

### Slack workflow example (for the `/incident` command)
```yaml
# Slack workflow: /incident-open
inputs:
  - severity: SEV1, SEV2, SEV3, SEV4
  - title: free text
  - affected_service: dropdown

actions:
  1. Create channel #inc-<DATE>-<SLUG>
  2. Invite @oncall-<TEAM>, @ic-rotation
  3. Post pinned message:
     - Severity, title, IC, SME, CL, scribe slots
     - Bridge link
     - Status page update template
  4. Notify #incidents-firehose
  5. PagerDuty incident open (if SEV1/SEV2)
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | The right way |
|---|---|---|
| **"Let's not roll back before we find the root cause"** | The user is bleeding while you do analysis | Mitigate first, root cause in the postmortem |
| **IC touches the keyboard** | Whoever touches the keyboard can't coordinate | The IC only coordinates |
| **CEO joins the bridge asking "what's going on?"** | Breaks the IC's flow | CL → executive briefing in a **separate** channel |
| **"Let me fix it quietly, no one notices"** | Then no postmortem, no learning, it recurs | Every SEV1/SEV2 is reported in writing |
| **No updates, "it'll be over soon"** | Stakeholder trust collapses | "No info" is an update too |
| **Same IC for 8 hours | A tired IC makes bad decisions | Rotate every 4 hours |
| **"That person broke it again"** | Blame culture → everyone hides information | Blameless: system fault, not the person |
| **PagerDuty escalation at 30 minutes** | The first responder acks forever without sleeping | Escalate at 5 minutes |
| **Postmortem writes **what**, not **why** | Doesn't prevent recurrence | Was 5-Whys applied? |

---

## 📋 IC Cheatsheet (open it while the fire's on)

```
1. Set the severity, open the channel, share the bridge link.
2. Assign roles: SME, CL, Scribe.
3. First 10 min → Assess: what, who, how much, last change?
4. Pick a mitigation: rollback / flag / scale / traffic shift.
5. Status page: Investigating → Identified → Monitoring → Resolved.
6. Update every 15-30 min.
7. Resolved: 15 min green + no customer reports.
8. Hotwash + assign postmortem.

Watch out:
- Don't touch the keyboard.
- Decide, don't take a vote.
- Saying "I don't know" is strength for an IC, not weakness.
- If you're tired, hand off the IC role.
```

---

## 🎯 Preparation (not for the incident moment — *beforehand*)

### Game Day / Chaos Engineering
- 1 simulated incident per month (a drill).
- Scenario: "Region-A down", "DB failover", "DNS hijack".
- Learning goal: are the runbooks working, are the ICs ready.

### Runbook Library
Every service has its own `runbook/` folder:
- Common alarm → what to do
- Rollback procedure
- Who's the owner, who to escalate to

Template: [`17-Templates/runbooks/runbook-template.md`](../17-Templates/runbooks/runbook-template.md)

### IC Training
- A new IC first **shadows** on 3 incidents.
- Then acts as **deputy IC** on 3 incidents (alongside the actual IC).
- Then solo IC.
- A drill every 6 months.

### On-call sustainability
- Max **48 hours** primary per week
- A shift covering the night → next day off
- Overtime → reduced in the next sprint
- Burnout signals: see [`20-Soft-Skills/Oncall-Sustainability.md`](../20-Soft-Skills/Oncall-Sustainability.md)

---

## 📚 References

- **Google SRE Workbook** — Chapter 9: Incident Response
- **PagerDuty Incident Response Documentation** — open-source, accessible
- **Etsy Debriefing Facilitation Guide** — the gold standard for postmortem facilitation
- [`00-Culture/Blameless-Postmortem-Template.md`](../00-Culture/Blameless-Postmortem-Template.md)
- [`00-Culture/On-Call-Playbook.md`](../00-Culture/On-Call-Playbook.md)
- [`11-SRE/SLI-SLO-Error-Budget.md`](SLI-SLO-Error-Budget.md) — should the error budget trigger an incident?

---

## 📋 Checklist

For production-ready incident response — it must be written down, drilled, and wired into automation.

```
[ ] Severity matrix (SEV1-SEV4) defined, everyone knows it; "who opens" decided up front
[ ] IC role is separate (doesn't touch the keyboard); SME / Comms Lead / Scribe roles written down
[ ] Alerting is automated (Prometheus/Datadog → PagerDuty); the customer doesn't learn before you
[ ] PagerDuty/Opsgenie ack window is 5 min, escalation triggers within 5 min
[ ] `/incident` Slack workflow opens channel + bridge + status page draft with a single command
[ ] Assess in the first 10 min: what / how many users / since when / recent change all answered
[ ] Mitigation priority order is clear (rollback → flag → traffic shift → scale → restart)
[ ] Status page update interval enforced (SEV1: 15 min, SEV2: 30 min); "no info" is an update too
[ ] KVKK: 72-hour notification flow + legal sign-off ready for a personal data breach 🇹🇷
[ ] Blameless postmortem after every SEV1/SEV2 (5 business days); action item = owner + due date
[ ] Game Day once a month, runbook library current, IC training (shadow → deputy → solo) running
[ ] On-call sustainable: max 48 hours primary, night shift → next day off, IC rotates every 4 hours
```

---

> *"The best incident response is the incident not happening." — True.
> But when it does, it's the team's **procedure**, not its practice, that wins.*

---

> 🎓 **Learning Path:** This document is used as a "Read first" resource in the [`E3`](../22-Learning-Path/block-e-ownership/E3-incident-postmortem.md) module.
