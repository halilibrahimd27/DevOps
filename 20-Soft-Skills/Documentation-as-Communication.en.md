---
description: "A guide to written communication formats like RFCs, ADRs, and Design Docs — what they are, when and how to write them, and the async, meeting-free decision culture behind them."
tags:
  - Soft Skills
  - Culture
  - Template
  - Career
---
# Documentation as Communication — RFC, ADR, Design Doc

> *"Holding a meeting costs 5 people 1 hour each. A **5-page RFC**
> makes the same decision async, with an audit trail, leaving it
> behind for the future. A writing culture is **the cure for
> meeting culture**."*

This guide covers **what, when, and how** to write RFCs, ADRs, and
Design Docs — written communication formats — the async decision
culture behind them, and the discipline a **meeting-free team**
needs.

---

## 🎯 The Value of an Async Writing Culture

### Meeting culture
- 5 people × 1 hour = 5 hours of human resources
- Notes are loose, the decision is unclear
- "I wasn't in that meeting" becomes an excuse generator
- 6 months later there's no answer to "why is it like this?"

### Writing culture
- 1 hour of writing + 5 people × 30 min reading + 30 min discussion = 4 hours
- The decision is **documented** + auditable
- A new engineer **finds** the answer to "why?"
- A legacy for the future

> 🔑 **Writing = leverage.** Write once, get read infinitely.

---

## 📋 Three Formats

| Format | Niche | Lifespan |
|---|---|---|
| **RFC** (Request for Comments) | New feature / architecture proposal | Open until a decision is made |
| **ADR** (Architecture Decision Record) | Record of an architecture decision already made | Forever (history) |
| **Design Doc** | Implementation plan | For the duration of implementation |

### Typical flow
```
[Idea]
   │
   ▼
[RFC]  ─── discussion + iteration ─── [Decision]
                                       │
                                       ▼
                                    [ADR]   ← record it
                                       │
                                       ▼
                                  [Design Doc] ← detailed implementation
                                       │
                                       ▼
                                    [Build]
```

---

## 📝 RFC — New Proposal

### When to write an RFC?
- Requires 1+ month of work
- Affects 3+ teams
- Hard to reverse (architecture decision)
- Budget investment (>$X)
- Previously discussed, now being reopened
- Cross-team API contract change

### RFC template
```markdown
# RFC: <TITLE>
**Status:** Draft / Review / Accepted / Rejected / Superseded by RFC-X  
**Author:** @<USER>  
**Reviewers:** @<USER>, ...  
**Date:** YYYY-MM-DD  
**Decision deadline:** YYYY-MM-DD

## TL;DR (3 sentences)
<Decision, motivation, impact.>

## 1. Problem
<Why are we talking about this? Back it with data.>

## 2. Goals & Non-Goals
**Goals:**
- ...
**Non-goals:**
- ... (out of scope; prevents scope-creep debates)

## 3. Proposal
<Proposed approach. Diagram + flow.>

## 4. Alternatives Considered
- A: ... (pro/con, why not)
- B: ... (pro/con, why not)
- Selected: ... (rationale)

## 5. Detailed Design
<Architecture, sequence diagram, API spec, data model.>

## 6. Trade-offs
- Pro: ...
- Con: ...

## 7. Risks & Mitigations
| Risk | Likelihood | Impact | Mitigation |

## 8. Cost Estimate
<Investment: person/hours, $, maintenance>

## 9. Success Criteria
<How will we know this RFC succeeded?>
- Metric 1: ...
- Metric 2: ...

## 10. Timeline
<Phases + estimated dates>

## 11. Open Questions
<Questions you don't have answers to — to be resolved during review>

## 12. References
<Related RFCs, blog posts, papers>
```

### RFC review flow
1. **Draft** — written privately by the author
2. **Review** — stakeholders comment (1 week)
3. **Decide** — meeting + decision (30 minutes max)
4. **Accepted / Rejected / Modified** — written outcome
5. Archived as an **ADR**

> 🔑 **An RFC can exist without a meeting**, but **not without a decision**.

---

## 🏛️ ADR — Architecture Decision Record

> When an RFC is accepted it becomes an **ADR** — a permanent record.

### ADR template (lightweight)
```markdown
# ADR-007: Service mesh adoption — Linkerd

**Date:** 2026-04-15  
**Status:** Accepted  
**Deciders:** @platform-team  
**Supersedes:** -  
**Superseded by:** -

## Context
In production we need mTLS, observability, and retries between
microservices. Solving this with a library in every service means
redoing the work each time.

## Decision
We will use Linkerd (sidecar mode, K8s 1.27+).

## Consequences
**Positive:**
- mTLS automatic
- Observability for free (Linkerd Viz)
- Low learning curve

**Negative:**
- ~10 MB sidecar overhead per pod
- Requires Linkerd-specific debugging knowledge
- Cilium service mesh was evaluated as an alternative → Cilium not yet GA

## Alternatives Considered
- Istio: too complex, 50 MB sidecar overhead
- Cilium SM: still incubating as of 2026
- App-side library: maintenance burden

## Related
- RFC-014: Service mesh evaluation
- ADR-005: Kubernetes 1.27 upgrade
```

### ADR repo structure
```
adr/
├── 0001-record-architecture-decisions.md
├── 0002-use-postgresql-for-primary-storage.md
├── 0003-adopt-trunk-based-development.md
├── 0004-use-argo-cd-for-gitops.md
├── 0005-kubernetes-1.27-upgrade.md
├── 0006-shift-from-helm-to-kustomize.md
└── 0007-service-mesh-adoption-linkerd.md
```

### ADR lifecycle
- **Accepted**: actively in use
- **Deprecated**: a new decision has superseded it
- **Superseded by ADR-X**: replaced

> 🔑 **You don't delete an ADR, you supersede it.** History is preserved.

---

## 📐 Design Doc — Implementation Plan

> RFC answers "what should we do?" — Design Doc answers "how will we do it?"

### Template
```markdown
# Design Doc: <FEATURE_NAME>
**RFC:** RFC-014  
**Author:** @<USER>  
**Status:** Draft / Review / In Progress / Done  
**Last updated:** YYYY-MM-DD

## Overview
<One paragraph: what we're going to do.>

## Architecture
<Diagram: components, data flow, dependencies.>

## API Spec
```yaml
openapi: 3.0
paths:
  /v2/users:
    post:
      ...
```

## Data Model
```sql
CREATE TABLE users_v2 (
  ...
);
```

## Migration Plan
<How we'll get the existing system to the new one, expand/contract>

## Testing Strategy
- Unit
- Integration
- E2E
- Load test

## Rollout Plan
- Stage 1: dev → smoke
- Stage 2: staging → load test
- Stage 3: prod canary 5% → 50% → 100%

## Rollback Plan
<How we roll back if something goes wrong.>

## Observability
- Metrics: ...
- Logs: ...
- Traces: ...
- Alerts: ...

## Security Considerations
<Threat model summary, AuthN/AuthZ, sensitive data.>

## Open Questions
<To be resolved during implementation.>

## Timeline & Milestones
- M1: ...
- M2: ...
- M3: GA
```

---

## 🎨 Good Writing Practices

### 1. **Lead with a TL;DR**
The first 3 sentences = the main idea. Everything else is detail.

### 2. **Write the "why"**
Explaining "what" you'll do is easy. If you didn't write down **why**, a future engineer may say "it's working fine right now, let's roll it back."

### 3. **A diagram is mandatory**
Mermaid is enough:
```
flowchart LR
  User --> LB[Load Balancer] --> API
  API --> DB[(PostgreSQL)]
  API --> Cache[(Redis)]
```

### 4. **Evaluate alternatives**
Don't write "the one right answer" — show **several options** + why the chosen one won.

### 5. **Cost + risk**
"If we don't touch this, X happens in 6 months. If we do it, it's 4 weeks + $X."

### 6. **Open Questions**
Don't hide what you don't know — **write it as a question**. It gets answered during review.

### 7. **The power of visuals**
Tables > paragraphs. Code example > abstract explanation.

---

## 🚦 Moving to a Writing Discipline

### Old (meeting culture) → New (writing culture)
| Change | Practice |
|---|---|
| "Let's discuss this" → | "I'm writing an RFC and sharing it" |
| Decision made at standup | RFC + 1 week review |
| Whiteboard photo | Mermaid diagram |
| Discussion in a Slack thread | RFC comment |
| Decision made in a 1:1 → | "1:1 notes + ADR" |

### Encouraging it as a manager
- The habit of asking "is this topic worth an RFC?"
- Recognition for whoever writes the RFC
- New engineer onboarding: "write one RFC in your first month"
- Templated tooling (e.g., a GitHub issue template for RFCs)

---

## 🛠️ Tooling

### In the repo
```
docs/
├── rfcs/                  # numbered: RFC-001, RFC-002
│   ├── 0001-template.md
│   ├── 0002-trunk-based.md
│   └── 0003-service-mesh.md
├── adrs/
│   ├── 0001-template.md
│   └── ...
└── design-docs/
    └── ...
```

### GitHub
- An **issue template** for RFCs (`.github/ISSUE_TEMPLATE/rfc.md`)
- Review via PR (line-by-line comments)
- Discussions (for RFC comments)

### Notion / Confluence
- Fine if it's already set up, but **it's not in sync with the code** → it goes stale
- Preferred: **markdown + Git** (rendered in Backstage via TechDocs)

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Do this instead |
|---|---|---|
| No RFC, "let's discuss it on Slack" | No audit trail for the decision | Write an RFC for the specific topic |
| RFC too long (50+ pages) | Nobody reads it | TL;DR + max 5-10 pages |
| RFC written but no decision meeting held | Questions go unanswered | 1 week review + 30 min decide meeting |
| Zero ADRs | Architecture decisions get forgotten | ADR for every major decision |
| Deleting an ADR instead of superseding it | History is lost | Link it with "Superseded by" |
| No design doc before implementation starts | "We'll figure it out as we go" | Write first, then build |
| No diagram, just paragraphs | Hard to follow | Mermaid + table |
| No Open Questions ("I know it all") | Review loses its value | Deliberately ask questions |
| RFC author decides alone | Others feel excluded | Reviewer sign-off required |
| RFC from 6 months ago never updated | Architecture changed, RFC is stale | Update with "Superseded by" |
| Manager doesn't have the writing habit | Culture doesn't change | Manager writes their own RFC, sets the example |

---

## 📋 Written Communication Discipline Checklist

```
[ ] RFC template in the repo
[ ] ADR template in the repo
[ ] Design doc template in the repo
[ ] RFC numbering system (e.g., RFC-001, RFC-002)
[ ] GitHub issue template (for opening an RFC)
[ ] CODEOWNERS auto-review for docs/rfcs/
[ ] RFC review flow: draft → review (1 week) → decide → ADR
[ ] Mermaid / draw.io diagram standard
[ ] New engineer onboarding: read previous RFCs
[ ] Habit of asking "did you write the RFC?" in the manager 1:1
[ ] Major decision = ADR mandatory
[ ] Quarterly: RFC retrospective (what were the effects of the decisions?)
[ ] Public-facing API: RFC mandatory
[ ] Cross-team impact: RFC mandatory
```

---

## 📚 References

- **Architectural Decision Records** — adr.github.io
- **Google Design Doc Template** — google.com/site/sitezilla/design-doc-template (community-shared)
- **Stripe Engineering Blog — RFCs at Stripe**
- **Squarespace Engineering — How we write design docs**
- **Will Larson — How to write a design doc** (chapter in Staff Engineer)
- [`Stakeholder-Management.md`](Stakeholder-Management.md)
- [`Postmortem-Conversation.md`](Postmortem-Conversation.md)
- [`Saying-No.md`](Saying-No.md) — rejecting an RFC
- [`01-Git-Workflow/Code-Review-Checklist.md`](../01-Git-Workflow/Code-Review-Checklist.md) — review culture

---

> *"A writing culture demands **discipline** — async communication
> is **not effortless**. But once it's established, the number of
> meetings drops by half, decision quality doubles, and **the new
> engineer who joins 6 months later** can understand it on their
> own."*

---

> 🎓 **Learning Path:** This document is used as the "read first" resource in module [`F4`](../22-Learning-Path/block-f-judgment/F4-yazma-adr-rfc.md).
