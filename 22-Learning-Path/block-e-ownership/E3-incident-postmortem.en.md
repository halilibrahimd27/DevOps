---
description: "Incident response + blameless postmortem: managing an outage and learning from it without blame."
level: E
module: E3
estimated_hours: 14
prerequisites: [E2]
tags: [Learning Path, SRE]
---
# E3 — Incident Response + Blameless Postmortem

> *"An incident's value isn't measured by who you blame, but by how the system changes."*

**Block:** E — Ownership · **Duration:** ~14h · **Prerequisite:** [`E2`](E2-alerting-oncall.md)

## 🎯 When you finish this module
- You manage an incident with roles, communication, and a timeline.
- You write a blameless postmortem, tying the root cause back to the system.
- You make the action items from the postmortem trackable.

## 🧠 Why this, why now
In E2, you knew what to do the moment an alert fired; E3 turns that moment into a process
and then institutionalizes the learning. The writing discipline in F4 (ADR/RFC/postmortem)
builds on the postmortem practice from this module.

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`11-SRE/Incident-Response.md`](../../11-SRE/Incident-Response.md) | incident management | ~30 min |
| [`00-Culture/Blameless-Postmortem-Template.md`](../../00-Culture/Blameless-Postmortem-Template.md) | template | ~20 min |

## 💥 Broken lab
👉 [`labs/broken/K07-incident-sim/`](../labs/broken/K07-incident-sim/) — Symptom: a multi-fault incident
simulation; multiple signals, real time pressure. Diagnosis + communication are measured together.

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] The K07 multi-fault incident simulation was managed with a UTC minute-precision timeline — written timeline
- [ ] A blameless postmortem was written: quantified impact + root cause + "why wasn't this caught earlier"
- [ ] At least one trackable action item (owner + due date) was extracted from the postmortem
- [ ] `bash labs/broken/K07-incident-sim/verify.sh` passes with zero errors after the fix

## 🧪 Test yourself
1. What role should be assigned first in an incident, and why does it come before the technical fix?
2. Why isn't "human error" a root cause?
3. Which section of a postmortem is more valuable: the root cause, or "why wasn't this caught earlier"?

<details><summary>Answers</summary>

1. Incident Commander (coordination + communication). Because people working in parallel trample each other without a single decision point and clear communication; the fix turns into chaos. Role separation is covered in [`11-SRE/Incident-Response.md`](../../11-SRE/Incident-Response.md).
2. Because if you designed the system in a way that let a person get it wrong, the error was inevitable — the root cause is that design (missing guard-rail, fragile process). "Human error" stops the investigation instead of changing the system.
3. The second one. The root cause explains this particular incident; "why wasn't this caught earlier" (missing alert/test/review) is the layer that prevents recurrence — that's where the real learning is. The template is in [`00-Culture/Blameless-Postmortem-Template.md`](../../00-Culture/Blameless-Postmortem-Template.md).
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| Everyone is trying to fix it at the same time | No coordination role | Assign an Incident Commander; clarify roles and the single decision point |
| The timeline can't be reconstructed afterward | No real-time record was kept | Keep timestamped notes as the incident unfolds (a chat channel is enough) |
| The postmortem blames a person | No blameless framework | Shift the language to the system: not "person X made a mistake" but "the system allowed X" |
| Action items aren't tracked | No owner/date | Add an owner + due date + where it will be tracked to every item |

## 💼 Portfolio output
A written blameless postmortem — also used as a writing sample in F4.

## ⏭️ Up next
[`E4 — Database Production (Restore)`](E4-veritabani-restore.md)

---

> *"'Human error' isn't a root cause — it's proof that a system let a person make a mistake."*
