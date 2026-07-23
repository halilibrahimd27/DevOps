---
description: "Index of the DevOps culture reference folder: blameless postmortem, on-call playbook, DORA/SPACE metrics, Team Topologies, and documentation culture."
tags:
  - Culture
  - SRE
  - Roadmap
---

# 00 · DevOps Culture

> *"The hardest problem isn't the code's; it's the people's."*

Changing tooling takes a week; changing culture takes 2 years. This folder
collects practical, directly applicable references for the culture side.

## Contents

| File | Topic |
|---|---|
| [`Blameless-Postmortem-Template.md`](Blameless-Postmortem-Template.md) | Blameless postmortem template, filled-in example + checklist |
| [`On-Call-Playbook.md`](On-Call-Playbook.md) | Setting up a healthy on-call rotation, handover, alert hygiene |
| [`DORA-SPACE-Metrics.md`](DORA-SPACE-Metrics.md) | The 4 DORA metrics + SPACE framework: what we measure, how we measure it, how we interpret it |
| [`Team-Topologies.md`](Team-Topologies.md) | 4 team types (stream-aligned/enabling/complicated-subsystem/platform) and interaction modes |
| [`Documentation-Culture.md`](Documentation-Culture.md) | RFC, ADR, runbook hierarchy; strategies against "documentation rotting" |

## Where to start?

- **Setting up a new team:** Team Topologies → DORA → On-Call Playbook
- **Improving an existing team:** Blameless Postmortem → SPACE → Documentation
- **Learning individually:** Modern-DevOps-2026 → Postmortem → DORA

## Markers of culture

### 🟢 Healthy signs
- Postmortems ask "why was this possible," not "who did it"
- The on-call pager is silent 24/7, rarely wakes anyone
- A new engineer merges their first PR within a day
- The phrase "I'm shipping to production" isn't tense

### 🔴 Toxic signs
- "Hero culture": deploys can't happen without certain people
- Postmortems turn into HR matters
- The Slack `#alerts` channel floods 50+ alerts an hour
- There's a separate silo called the "DevOps team"
