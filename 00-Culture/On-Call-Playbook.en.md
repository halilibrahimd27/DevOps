---
description: "Guide to building a healthy on-call rotation: primary/secondary roles, alert hygiene, handoff, escalation, and sustainable on-call practices."
tags:
  - Culture
  - Incident Response
  - SRE
  - Monitoring
---

# On-Call Playbook

> *"A healthy on-call: if you were on rotation for 7 days and **didn't
> even wake up twice**, and when you did wake up the runbook handed you
> a fix in 5 minutes — you've engineered the system properly."*

---

## 🎯 The purpose of on-call (really)

- Close customer-impacting problems **fast**
- Not a "hero culture" — a sustainable rotation
- Continuous improvement: every alert that wakes you up feeds a postmortem or a runbook
- Not a seniority test ground — everyone takes part

---

## 👥 Roles

### Primary On-Call (1 person)
- Responds to all alerts first
- 7-day rotation, weekends included
- Reachable by phone + Slack
- Acknowledges within 15 min

### Secondary On-Call (1 person)
- Steps in if Primary doesn't respond
- Shares the load if it drags on for Primary
- Backup for the escalation owner

### Incident Commander (when needed)
- On SEV-1 / SEV-2, Primary becomes IC
- Controls the chain of command
- Assigns the comms lead
- Decision-maker (rollback / failover / wait)

### Comms Lead (when needed)
- Status page updates
- Customer-facing channel
- Internal stakeholder updates

---

## 📅 Rotation design

### Size
- 4-8 people is ideal (6 recommended)
- < 4: burnout risk
- > 8: rotation is too infrequent, skills atrophy

### Duration
- 7-day rotation (Monday-Monday)
- Some teams split it into 3-4 days — weekend separate
- Daily rotation is too exhausting (no context)

### Fair distribution
- Auto-rotation via PagerDuty / Opsgenie
- Holiday/leave override
- Senior + junior pair (first month)

### Compensation
- Standby pay (legally required in some countries)
- Page-time pay (extra when woken up)
- Comp-day (day off the next day after a sleepless night)
- 🚫 Not a "reward for heroism" — it's everyone's right

---

## 🔔 Alert hygiene

### Healthy alert criteria
- **Actionable** — "fix it with this command"
- **Customer-impacting** — a real user is experiencing a problem
- **Urgent** — can't wait until the next morning

### Should be a "ticket," not a "page"
- "Disk is 75% full" — not a page, a ticket
- "1 pod restarted" — a log, neither page nor ticket
- "Cron job didn't run yesterday" — a ticket

### Severity tier

| Sev | Definition | Notification |
|---|---|---|
| **SEV-1** | Customer impact, revenue down | PagerDuty (call + push) |
| **SEV-2** | Major feature broken, a subset affected | PagerDuty (push) |
| **SEV-3** | Minor, workaround available | Slack #alerts |
| **SEV-4** | Cosmetic | Ticket queue |

### Alert audit (weekly)
At the end of every on-call shift each week:
- Which alerts fired?
- How many were **real incidents**? How many were false positives?
- Every false positive → tune the threshold or delete the alert
- Was a new alert added? Why?

> 🎯 Target: an average of **< 5 pages** per rotation. Above that → invest in reliability.

---

## 📞 Pager response protocol

### 0-2 minutes: Acknowledge
```
1. PagerDuty acknowledge
2. Join the Slack #incident-X channel
3. Post "On it"
```

### 2-5 minutes: Triage
```
4. What does the alert say? Click the runbook link
5. Check the dashboard — is it real?
6. Confirm severity
```

### 5-15 minutes: Mitigate
```
7. Mitigate first (rollback / failover / circuit-break)
8. Investigate after
9. If SEV-1: take the incident commander role, assign a comms lead
10. If scope is widening: page a senior
```

### 15+ minutes: Communicate
```
11. Update the status page
12. Internal update every 30 min
13. If there's customer impact, notify marketing/CS
```

### Resolution
```
14. Mitigation confirmed (metrics green)
15. Customer-facing all-clear
16. Close the incident channel
17. Open a postmortem ticket (draft within 24 hours)
```

---

## 📚 Runbook standard

> Full template: [`17-Templates/runbooks/runbook-template.md`](../17-Templates/runbooks/runbook-template.md)

Every alert **must** have a runbook:
- What to check in the **first 60 seconds** when the alert fires
- Possible causes + the fix command for each
- Escalation: when, to whom

> An alert without a runbook = waking someone up for no reason.

---

## 🔄 Handoff

An important ritual at the end/start of a shift.

### The outgoing on-call writes:
```
## Last week summary — payment-api on-call

- 3 pages (1 SEV-2, 2 SEV-3)
- 1 incident (INC-1234) — postmortem due tomorrow
- Open issues:
  - DB replica lag is high (ticket #5678) — being watched
  - Suspected memory leak (ticket #5689) — repro in progress on staging
- Deploy planned this week: v3.5.0 (Wed)

## Notes for incoming
- Watch the v3.5.0 canary for 30 min (there's an open issue in the PR)
- payment-db-replica-2 is still unstable, use this if it fails: <runbook>
```

### 30 min overlap (ideal)
- Incoming + outgoing together for 30 min
- Open topics are talked through verbally
- The summary is shared in the Slack channel

---

## 🧠 Burnout signals (watch for these on your team)

- ❗ The same person keeps taking "extra" shifts
- ❗ Pages come in but acknowledgment is slow or skipped
- ❗ They don't want to write postmortems
- ❗ They said "let's mute this alert" but never closed it out
- ❗ A senior requests to leave the team

> Any one of these = a signal for **urgent platform investment** or
> **growing the rotation**.

---

## ⚙️ Tooling

- **PagerDuty** — industry standard, richest feature set
- **Opsgenie** — Atlassian, cheaper alternative
- **Grafana OnCall** — open source, K8s-native
- **incident.io / FireHydrant / Rootly** — incident management (Slack-bot integration)
- **Statuspage.io / Cachet** — public status page

---

## 🎓 Onboarding (for new engineers)

For an engineer to become "production-ready on-call":

| Week | Activity |
|---|---|
| 1 | Architecture overview, read the runbooks |
| 2 | Shadow shift with a senior (stand by, no responsibility) |
| 3 | Reverse shadow (they run it, senior observes) |
| 4 | Solo primary (with an experienced secondary) |

> Running mock incident drills (game days) is also valuable — practice
> with scenarios that aren't real but are realistic.

---

## ✅ Healthy on-call culture signals

- 🟢 A new junior engineer goes solo comfortably after 4 weeks
- 🟢 Page count is stable or **decreasing** (with every postmortem fix)
- 🟢 **>70%** of postmortem action items get closed
- 🟢 When someone says "let's close this alert, it's not real," it's accepted
- 🟢 A **comp-day** is given at the end of an on-call shift

---

## 📋 Checklist

Check off everything below before calling an on-call rotation **production-ready**:

- [ ] Rotation is 4-8 people — if < 4, that's a burnout risk, grow it immediately.
- [ ] Auto-rotation is set up via PagerDuty/Opsgenie, holiday/leave override works.
- [ ] Every active alert has a runbook — no alert goes to production without one.
- [ ] Alerts are actionable + customer-impacting + urgent; everything else is downgraded to a ticket.
- [ ] Severity tiers (SEV-1..SEV-4) are defined, each tier's notification channel is clear.
- [ ] The acknowledge SLA (15 min) is measured, it escalates to secondary when missed.
- [ ] Incident Commander + Comms Lead roles are defined for SEV-1/SEV-2.
- [ ] The status page (<STATUS_PAGE_URL>) is wired up, Comms Lead keeps it updated.
- [ ] A handoff ritual exists — outgoing writes a summary, a 30 min overlap is practiced.
- [ ] The postmortem enters draft within 24 hours, run blamelessly.
- [ ] **>70%** of postmortem action items get closed (tracked).
- [ ] A weekly alert audit is done; false positives are closed out via threshold tuning or deletion.
- [ ] Compensation policy is clear: standby/page-time pay or comp-day is given.
- [ ] New engineers complete the 4-week onboarding (shadow → reverse shadow → solo).
- [ ] Rotation average is < 5 pages; anything above triggers a reliability investment.

---

## 📚 Further reading

- [Google SRE Book — Chapter 11: Being On-Call](https://sre.google/sre-book/being-on-call/)
- *Seeking SRE* — David N. Blank-Edelman (book)
- [PagerDuty Incident Response docs](https://response.pagerduty.com)
- [`17-Templates/runbooks/`](../17-Templates/runbooks/runbook-template.md) — runbook + postmortem template

---

## 📚 References

- [Blameless Postmortem Template](Blameless-Postmortem-Template.md) — blameless postmortem skeleton for after every page.
- [Incident Response](../11-SRE/Incident-Response.md) — SEV-1/SEV-2 chain of command, IC and Comms Lead detail.
- [Runbook Template](../11-SRE/Runbook-Template.md) — no alert goes to production without a runbook; the standard template.
- [Alerting Done Right](../07-Observability/Alerting-Done-Right.md) — actionable alert design, hunting down false positives.
- [SLI/SLO & Error Budget](../11-SRE/SLI-SLO-Error-Budget.md) — tie the page budget to the error budget.
- [Google SRE Book](https://sre.google/sre-book/table-of-contents/) — on-call and incident response reference.

---

> *"What makes on-call sustainable isn't heroism; it's alerts with runbooks, blameless postmortems, and the reliability investment that closes out every page that wakes you up at night."*

---

> 🎓 **Learning Path:** This document is used as the "read first" resource in the [`E2`](../22-Learning-Path/block-e-ownership/E2-alerting-oncall.md) module.
