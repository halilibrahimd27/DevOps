---
description: "Index of soft-skill guides for the human side of DevOps/SRE/Platform work: on-call, stakeholders, security, vendors, saying no, postmortems, mentoring."
tags:
  - Soft Skills
  - Culture
  - Career
  - SRE
---
# 20 · Soft Skills — More Important Than Engineering (Sometimes)

> *"The engineer who makes the best architecture decision can't get it
> implemented if they explain it to the **wrong person**. Soft skills aren't
> 'soft' — they're **leverage**."*

DevOps/SRE/Platform work is about **people** — your team, developers,
managers, vendors. This section isn't about "how to write the code," it's
a collection of practices for **how the work actually runs**.

## Contents

| File | Topic |
|---|---|
| [`Oncall-Sustainability.md`](Oncall-Sustainability.md) | Preventing on-call burnout, shift design, post-incident rest |
| [`Stakeholder-Management.md`](Stakeholder-Management.md) | Senior management, product, security, legal — what language to speak with whom |
| [`Working-with-Security-Team.md`](Working-with-Security-Team.md) | Treating the security team as a partner, not an adversary |
| [`Vendor-Management.md`](Vendor-Management.md) | RFPs, vendor lock-in, negotiation, escape strategy |
| [`Saying-No.md`](Saying-No.md) | The art of saying "no": scope creep, premature commitment |
| [`Postmortem-Conversation.md`](Postmortem-Conversation.md) | Carrying blameless culture into the conversation itself |
| [`Mentoring-Junior-Engineers.md`](Mentoring-Junior-Engineers.md) | Practices for teaching infra/SRE to junior engineers |
| [`Documentation-as-Communication.md`](Documentation-as-Communication.md) | RFC, ADR, design doc — writing and reading them |

## Philosophy

> Engineering solves the 0 → 1 problem. Soft skills solve the 1 → N
> **scaling** problem. A single engineer working alone falls far behind
> one who coordinates 5.

## Notes on a Specific Work Culture

Dynamics commonly seen in hierarchical, high power-distance work cultures:
- **Hierarchical decision-making**: "What would the manager say?" — DevOps teams often wait for a change to be "cleared by management" before acting. Reversing this pattern takes deliberate empowerment.
- **Preference for face-to-face**: Meeting pressure crowds out async communication (PR review, RFC). Shifting from a meeting culture to an RFC culture.
- **Avoiding saying "no"**: Not delivering on work you already agreed to becomes a bigger problem later. This is the culture the Saying-No guide addresses.
- **Juniors hesitant to "ask questions"**: In seniority-driven cultures such as Pakistan, Turkey, and India, juniors are afraid to ask questions. The mentoring flow is designed to be sensitive to this.

## Anti-patterns

- ❌ "Soft skills don't matter, focus on the code" → 5 years later, the same junior is still a junior, now senior in title only
- ❌ All communication happens in meetings → no async culture, documents go stale
- ❌ Security team treated as the enemy → bypasses start, shadow IT emerges
- ❌ Explaining things to senior management in technical language → decisions get delayed, budget doesn't get approved
- ❌ Full trust placed in the vendor → lock-in, escalation becomes impossible
- ❌ Ignoring burnout signals → the senior resigns, the organization loses institutional knowledge
