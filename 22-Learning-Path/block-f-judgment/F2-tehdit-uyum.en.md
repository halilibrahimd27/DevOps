---
description: "Threat modeling + compliance (KVKK / GDPR / SOC 2): translating risk and regulation into engineering controls."
level: F
module: F2
estimated_hours: 12
prerequisites: [D1, D4]
tags: [Learning Path, Security, Compliance]
---
# F2 — Threat Modeling + Compliance (KVKK / GDPR / SOC 2)

> *"Compliance isn't a document — it's engineering controls translated into a language."*

**Block:** F — Judgment · **Duration:** ~12h · **Prerequisite:** [`D1`](../block-d-orchestration/D1-k8s-temel.md), [`D4`](../block-d-orchestration/D4-supply-chain.md)

## 🎯 When you finish this module
- You can produce a simple threat model for a system and prioritize the risks.
- You can tie a regulatory requirement (KVKK / GDPR / SOC 2) to a concrete engineering control.
- You can defend an "acceptable risk" decision in writing, with reasoning.

## 🧠 Why this, why now
In D1 you set up RBAC/NetworkPolicy, in D4 supply chain security — those are
individual controls. F2 places those controls into a **risk and compliance
framework**: what are you protecting, against whom, under what obligation?

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`08-Security/Threat-Modeling.md`](../../08-Security/Threat-Modeling.md) | STRIDE framework + template | ~35 min |
| [`19-Compliance/KVKK-Practical.md`](../../19-Compliance/KVKK-Practical.md) | example of translating a regulation into an engineering control | ~30 min |
| [`19-Compliance/SOC2-Type2-Prep.md`](../../19-Compliance/SOC2-Type2-Prep.md) | control ↔ evidence mapping | ~25 min |

## 🔨 Deliverable exercise
The output is a written threat model + control map. Pick the system you built in
D1–D5 (or Capstone 2). Write `tehdit-modeli.md`:
1. Map out the assets and trust boundaries (what's valuable, where data flows from and to).
2. List at least 5 threats in a STRIDE-like table, and map each one to a control
   (D1 RBAC/NetworkPolicy, D3 secrets, D4 image scanning/signing — which one closes which threat).
3. Tie one KVKK/GDPR/SOC 2 requirement to a **concrete** control (clause → control → how it's evidenced).
4. Write down **explicitly** a risk you did not close: which risk you accepted, why, and under what condition it gets revisited.

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] `tehdit-modeli.md` has a table with asset + trust boundary + at least 5 threat → control rows
- [ ] At least one regulatory clause is tied to a concrete control and that control's evidence (clause → control → evidence)
- [ ] An accepted risk is documented in writing with reasoning: why it was accepted, under what condition it's reassessed
- [ ] Every threat's mapped control is traceable to one of the D1–D4 modules (source module name is written down)

## 🧪 Test yourself
1. Which engineering control closes the "R" (Repudiation) threat in STRIDE, and why is an audit log a compliance requirement?
2. How do you prove the statement "we're compliant" to an auditor — with a claim, or with evidence, and which one?
3. If closing a risk is disproportionately expensive (control cost > value protected), what do you do?

<details><summary>Answers</summary>

1. Repudiation is closed by an **audit log** that records who did what in a tamper-evident way; compliance frameworks require this because it's the answer to "who, what, when" — [`08-Security/Threat-Modeling.md`](../../08-Security/Threat-Modeling.md).
2. With evidence. An auditor doesn't look at a claim — they look at an artifact that shows the control is actually working (log, config, pipeline output). Automating that evidence is the real work — [`19-Compliance/Audit-Evidence-Automation.md`](../../19-Compliance/Audit-Evidence-Automation.md).
3. You consciously accept the risk: you record the decision, its reasoning, and the condition under which it will be revisited, in writing. An accepted risk is never silent — it's documented — [`08-Security/Threat-Modeling.md`](../../08-Security/Threat-Modeling.md).
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| The threat list never ends | Trust boundary wasn't drawn | First map where data flows from and to; look for threats at the boundary crossings |
| The regulation stays abstract | Clause wasn't tied to a control | Reduce every clause to "which control, which evidence"; a clause you can't tie down is a gap |
| Every risk gets "must be closed" | No concept of acceptable risk exists | Compare control cost against the value protected; write down what you're not closing, with reasoning |
| Control exists but no evidence | Audit trail wasn't designed for it | Produce the log/config that proves the control works, now — it can't be reconstructed after the fact |

## 💼 Portfolio output
A threat model + control map — proof of security decision-making.

## ⏭️ Up next
[`F3 — Platform, IDP, Team Topologies`](F3-platform-idp.md)

---

> *"Saying 'we're compliant' is easy; showing which control satisfies which clause is engineering."*
