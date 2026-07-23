---
description: "Writing: ADR, RFC, postmortem — recording a decision, a proposal, and a lesson learned in a form others can read."
level: F
module: F4
estimated_hours: 10
prerequisites: [E3]
tags: [Learning Path, Soft-Skills]
---
# F4 — Writing: ADR, RFC, Postmortem

> *"An undocumented decision is a mystery six months later — nobody remembers why."*

**Block:** F — Judgment · **Duration:** ~10h · **Prerequisite:** [`E3`](../block-e-ownership/E3-incident-postmortem.md)

## 🎯 When you finish this module
- You write an architectural decision as an ADR (Architecture Decision Record).
- You open a proposal for discussion with an RFC, addressing objections before they're raised.
- You write a postmortem that is blameless and action-oriented.

## 🧠 Why this, why now
You wrote a postmortem in E3; F4 extends writing into a **decision-making tool**. Being
effective at the L2 level is often not about writing code, but about writing a decision
in a persuasive and traceable way. This module is not pure reading — it's a **writing exercise.**

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`20-Soft-Skills/Documentation-as-Communication.md`](../../20-Soft-Skills/Documentation-as-Communication.md) | writing is a communication tool, reader-focused | ~30 min |
| [`00-Culture/Documentation-Culture.md`](../../00-Culture/Documentation-Culture.md) | the culture of keeping decisions in writing | ~20 min |
| [`00-Culture/Blameless-Postmortem-Template.md`](../../00-Culture/Blameless-Postmortem-Template.md) | postmortem template (recall from E3) | ~15 min |

## 🔨 Deliverable exercise
This module's output is a **written artifact**, not pure reading. Produce two documents:
1. **An ADR** (Architecture Decision Record): document a real decision you made along the path —
   e.g. "why a multi-stage image in C1", "why I managed secrets this way in D3". Sections:
   context → options considered → decision made → consequences (positive and negative).
2. **Score a postmortem with a rubric**: take the postmortem you wrote in E3 (or K07), score it
   with the rubric below, **fix** the low-scoring axes, and submit the corrected version.

**Rubric (each axis 0–2):** clarity of decision/root cause · alternatives considered · honesty of
consequences (are the negatives written down too) · traceable action items (owner + deadline).

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] An `adr-001-<topic>.md` was written: context, at least 2 options, decision, and **negative** consequences included
- [ ] A postmortem was scored with the rubric above; score for each axis + the fix for low-scoring axes written down
- [ ] "How you address the strongest objection to an RFC in advance" written in one paragraph
- [ ] Every action/consequence item in the ADR is traceable (carries an owner or source module name)

## 🧪 Test yourself
1. In an ADR, why is the "options considered" section more valuable than the "decision made" section?
2. Why does writing the strongest objection yourself before publishing an RFC increase its persuasive power?
3. Why is leaving the "negative consequences" section empty in a postmortem a red flag?

<details><summary>Answers</summary>

1. Because it shows *why* the decision was made and why each alternative was ruled out; six months later, that's where the answer to "why did we do it this way?" lives. A conclusion without context gets re-litigated — [`20-Soft-Skills/Documentation-as-Communication.md`](../../20-Soft-Skills/Documentation-as-Communication.md).
2. If you raise the objection before the reader does, the discussion shifts from "are you right" to "which trade-off" — you come across as credible, not defensive. Address the most common objections in advance — [`00-Culture/Documentation-Culture.md`](../../00-Culture/Documentation-Culture.md).
3. Every decision has a cost; saying there are no negatives means either you're not being honest or you haven't thought it through enough. A document that omits the trade-off loses trust — [`20-Soft-Skills/Documentation-as-Communication.md`](../../20-Soft-Skills/Documentation-as-Communication.md).
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| The ADR turns into a "here's what we did" list | Context and alternatives were skipped | Write the problem and the ruled-out options first; the decision comes last |
| The postmortem blames a person | No blameless framing | Shift the language to the system (E3) — "the system allowed X"; go back to the template |
| The RFC reads as defensive | Objections are being suppressed | Write the strongest objection yourself and answer it; move the discussion to trade-offs |
| Action items can't be tracked | No owner/date | Add an owner + deadline + tracking location to every item |

## 💼 Portfolio output
A written ADR + a postmortem — the most concrete evidence of L2 communication.

## ⏭️ Up next
[`F5 — Stakeholder, Saying "No", Vendor`](F5-stakeholder-vendor.md)

---

> *"The quality of a decision is measured by how many people read it and couldn't argue against it."*
