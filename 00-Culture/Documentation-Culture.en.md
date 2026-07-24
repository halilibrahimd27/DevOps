---
description: "Right-sized, role-targeted documentation culture: the 4-tier hierarchy (README, RFC, ADR, runbook) and practical strategies against doc rotting."
tags:
  - Culture
  - Soft Skills
  - Platform Engineering
---

# Documentation Culture

> *"A system you don't document is understood only by you; bus factor of 1;
> if you leave, the hidden knowledge leaves with you."*
>
> *"A system you over-document, nobody reads; doc rotting sets in; the
> drift between actual behavior and the writing keeps growing."*

The middle ground between the two — **right-sized, role-targeted
documentation** — is the real art.

---

## 📐 4-Tier Hierarchy

### Tier 1: README (for every repo)

> "What does this repo do? How do I get started?" Answered in 5 minutes.

What it should have:
- A one-sentence summary
- What it's for (use case)
- Quick start (3-5 commands)
- Architecture diagram (high-level)
- "Where to go next" links

**What it shouldn't have:**
- Hundreds of lines of API docs (put them elsewhere)
- Internal team-only details

### Tier 2: ADR (Architecture Decision Record)

> **Why** we made important decisions.

```markdown
# ADR-0042: Using Aurora instead of Postgres

## Status: Accepted (2026-04-15)

## Context
- Production load expected to go from 5K → 50K RPS
- Cross-region read replica needed
- Current self-managed Postgres has high operational overhead

## Decision
We're moving to Aurora PostgreSQL Global Database.

## Consequences
+ No auto-failover / multi-region read replica management burden
+ 99.99% SLA built-in
- Cost +30%
- Aurora-specific features (vendor lock-in)
- Major version upgrades aren't in our control

## Alternatives Considered
- Self-managed PostgreSQL with Patroni: rejected due to ops overhead
- CockroachDB: team has no familiarity, migration risk is high
- Cloud SQL (GCP): current infra is AWS, multi-cloud complicates things
```

**ADRs:**
- Numbered (0001, 0002, ...)
- Immutable — if a new decision is needed, write a new ADR (mark the old one "Superseded")
- Live under `docs/adr/` in the repo
- Shouldn't exceed 1 page

> 📚 [adr-tools](https://github.com/npryce/adr-tools), [Markdown Architectural Decision Records](https://adr.github.io/madr/)

### Tier 3: RFC (Request for Comments)

> A **pre-review** document for important new proposals.

- **Broader** than an ADR, undecided, in draft form
- 5-15 pages
- Open for 2 weeks for stakeholder feedback
- Eventually → turns into an ADR or gets rejected

```markdown
# RFC-0017: API rate limiting v2

## Author: @author
## Reviewers: @reviewer1, @reviewer2
## Status: Draft / Review / Accepted / Rejected
## Deadline: 2026-05-15

## Summary
2 sentences.

## Motivation
What's the problem, why are we solving it.

## Detailed Design
Architecture, API, UI mockups, code samples.

## Trade-offs
Which alternatives we considered, why this one.

## Open Questions
Questions still awaiting an answer.

## Migration Plan
Migration path from the current system.
```

### Tier 4: Runbook + Postmortem

> "What to do during an incident" / "What we learned after the incident."

> Templates: [`17-Templates/runbooks/`](../17-Templates/runbooks/)

---

## 🎯 Audience-First approach

Different versions of the same information:

| Doc type | Audience | What it covers |
|---|---|---|
| README | New engineer joining | "How do I run this" |
| Architecture | Senior + new starter | "How the system's pieces talk to each other" |
| Runbook | On-call | "What to do when this alert fires" |
| ADR | Senior, future you | "Why we decided this" |
| API docs | API consumer | "What this endpoint returns" |
| Tutorial | Learner | "How to do it step by step" |
| Reference | Power user | "All the parameters" |

> Diátaxis framework — the 4 doc types should be kept separate: tutorial, how-to, reference, explanation. Don't mix them.

---

## 🛡️ Strategies against "doc rotting"

### 1. Code-as-doc (the most important)
```python
def calculate_tax(amount: Decimal, region: str) -> Decimal:
    """
    Calculates VAT for the given region.

    Trade-off: 20% flat rate for TR, region-specific table for EU.
    The EU table has lived in mongo since 2026-Q1; rates aren't static.

    Args:
        amount: Gross amount
        region: ISO country code (e.g., "TR", "DE")
    """
```

> Well-written code is the most up-to-date doc there is.

### 2. Test-as-doc
```python
def test_checkout_handles_concurrent_clicks():
    """
    If a user double-clicks checkout,
    only 1 order should be created (idempotency key).
    """
    # ...
```

### 3. Link checker in CI
```yaml
- uses: lycheeverse/lychee-action@v1
  with:
    args: --verbose --no-progress './**/*.md'
```

### 4. "Last updated" is mandatory
At the top of every doc:
```yaml
---
last-reviewed: 2026-04-30
owner: @platform-team
review-frequency: quarterly
---
```

CI throws a "hasn't been reviewed in 6 months" warning.

### 5. Ownership (CODEOWNERS)
```
# .github/CODEOWNERS
docs/architecture/    @platform-team
docs/runbooks/        @sre-team
docs/api/             @api-team
```

### 6. "Decommission or fix" review

An audit once a year. For every doc:
- Still relevant? → bring it up to date
- Not anymore? → delete it

> A stale doc is **worse** than no doc. It misleads.

---

## 📚 Tooling

### Static
- **Markdown** in repo — searchable, version-controlled
- **MkDocs / Docusaurus / Hugo** — static site generated from markdown
- **Backstage TechDocs** — service-attached docs
- **Read the Docs** — auto-deploy

### Dynamic
- **Confluence / Notion** — meeting notes, brainstorming
- **Slack** — real-time communication (never use as a doc source)

### Diagrams
- **Mermaid** — markdown-native, renders on GitHub
- **PlantUML** — code-as-diagram, version control
- **Excalidraw** — quick sketch
- **Lucidchart / Miro** — collaborative

> Decision: docs live in **Git**, meeting notes live in Notion/Confluence. Keep them separate.

---

## ✨ Rules for writing good docs

1. **Start with a one-sentence summary** — let the reader know in 5 seconds whether they need this
2. **Active voice** ("You create an API token" vs. "An API token should be created")
3. **Code blocks are tested** — does the command actually work?
4. **Placeholders in `<UPPER_CASE>`** — never use real values
5. **A diagram beats 300 lines of text** — when it fits
6. **Links are relative** — so they don't break when the repo moves
7. **A recently-updated date** in a visible spot
8. **Examples > abstract definitions**

---

## 🚫 Anti-patterns

| Anti-pattern | Why it's bad |
|---|---|
| "TODO: fill in later" | Never gets filled in |
| Auto-generated reference (signature only) | No audience, useless |
| Doc hidden away in a wiki | Not searchable, knowledge gets lost |
| Word doc / PDF | Not versioned, no diff |
| 50-page "comprehensive" guide | Nobody reads it — split it up |
| Not reviewing doc PRs | Doc quality goes unchecked |
| A "doc" pasted together from a Slack thread | Not searchable, gets lost |
| Personal writing style (ego) | Hurts maintainability |

---

## 🎓 Doc-as-code principles

- ✅ Docs live in the repo alongside the code
- ✅ Docs go through PR review (wording, meaning)
- ✅ Docs are tested in CI (links, syntax, formatting)
- ✅ Docs are updated in the same PR as the code change (otherwise the PR is rejected)
- ✅ Every doc has an owner (`CODEOWNERS`)
- ✅ Stale docs trigger a CI warning

---

## 📋 Checklist

Before calling a doc "production-ready":

- [ ] Every repo has a Tier-1 README — summary + quick start + architecture link, understandable in 5 minutes
- [ ] Important architectural decisions live in a numbered ADR (`docs/adr/`), don't exceed 1 page, immutable
- [ ] `last-reviewed` + `owner` + `review-frequency` frontmatter is filled in at the top of the doc
- [ ] Doc directories have a defined owner in `CODEOWNERS` (no orphan docs)
- [ ] A link checker (lychee, etc.) runs in CI — a broken link blocks the PR
- [ ] A "hasn't been reviewed in 6 months" / stale doc warning is active in CI
- [ ] Docs are updated in the same PR as the code change (a PR rule against drift)
- [ ] All code blocks are tested — the commands actually work
- [ ] Placeholders are in `<UPPER_CASE>` format, no real IP/domain/credential
- [ ] Links are relative — they don't break when the repo moves
- [ ] The Diátaxis separation is preserved — tutorial / how-to / reference / explanation aren't mixed
- [ ] A runbook for on-call and a post-incident postmortem template both exist
- [ ] Docs live in Git (markdown), meeting notes live in Notion/Confluence — the source doc isn't a Slack thread
- [ ] The "decommission or fix" step passed in the audit — stale docs were deleted

---

## 📚 Further reading

- [Diátaxis framework](https://diataxis.fr) — the 4 doc types
- [Architecture Decision Records (ADR) on GitHub](https://adr.github.io/)
- [Google Technical Writing courses](https://developers.google.com/tech-writing) — free
- [Write the Docs community](https://www.writethedocs.org)
- [`17-Templates/runbooks/`](../17-Templates/runbooks/) — runbook + postmortem template

---

## 📚 References

- [`On-Call-Playbook.md`](On-Call-Playbook.md) — where the runbook fits into the on-call flow
- [`Blameless-Postmortem-Template.md`](Blameless-Postmortem-Template.md) — the Tier-4 postmortem template
- [`11-SRE/Runbook-Template.md`](../11-SRE/Runbook-Template.md) — the in-incident runbook skeleton
- [`11-SRE/Postmortem-Practice.md`](../11-SRE/Postmortem-Practice.md) — postmortem culture, learning against drift
- [`17-Templates/runbooks/`](../17-Templates/runbooks/) — the runbook + postmortem template directory
- [Diátaxis framework](https://diataxis.fr) — the tutorial / how-to / reference / explanation split

---

> *"Documentation is a matter of ownership, not quantity: a doc that lives apart from the code, has no owner, and is past its review date is lying to you — update it or delete it."*

---

> 🎓 **Learning Path:** This document is used as the "read first" resource in the [`F4`](../22-Learning-Path/block-f-judgment/F4-yazma-adr-rfc.md) module.
