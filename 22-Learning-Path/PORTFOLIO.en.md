# PORTFOLIO — From Module to CV Line

> *"A CV isn't a list of claims — it's an index of evidence. This path produces the evidence; this page turns it into a CV line."*

This page maps the **concrete artifacts you produce** along the path (capstone repos, analysis
write-ups, postmortems) to their corresponding line on a CV. Who it's for: anyone who has
finished a block and is asking "how do I put this on my CV?" By the end, you'll know which
competency each artifact in your hands proves, and how to phrase it in the language of
**impact** rather than tasks.

> ⛔ This page makes no title promises: you won't find a sentence here like "finish this block
> and you move up to this title." Titles are set by experience, the hiring organization, and
> the market. What's here is only **provable competency** and its honest expression on a CV.

---

## 🎯 Core principle: evidence → impact

A CV line's strength comes from two things: being **verifiable** (it points to a repo/artifact)
and narrating **impact** (not what you did, but what changed). This path's outputs deliver
both: capstones produce a working repo, Block F modules produce a written decision artifact.

| ❌ Task-based (weak) | ✅ Impact-based (evidenced) |
|---|---|
| "I used Terraform" | "Made infrastructure `apply`/`destroy` idempotent; cut from-scratch setup time from `<before>` → `<after>`" |
| "I know K8s" | "Stood up a deployment with RBAC + NetworkPolicy from day one; made the privilege surface deny-by-default" |
| "I did monitoring" | "Proved an outage with logs and metrics; wired an SLO breach to an alert" |

> Fill impact bullets with numbers **you measured yourself**. Don't write a number you didn't
> measure — it's the first thing asked in an interview. If there's no number, use a verifiable
> verb like "deployed / proved / made reproducible," not an invented metric.

---

## 🔧 1. Capstone → portfolio project

Capstones are the backbone of the CV: each one is a single git repo — that is,
**demonstrable** evidence. Every capstone produces its own README template; the line here
carries it onto the CV.

| Source | Repo you produce | Corresponding CV line type |
|---|---|---|
| [`Capstone 1`](capstones/CAP1-blok-c-sonu.md) | container + CI + Terraform, rebuilt from scratch via `RECREATE.md` | "Deployed an application reproducibly: multi-stage image, versioned CI, idempotent IaC" |
| [`Capstone 2`](capstones/CAP2-blok-d-sonu.md) | production-grade deploy to K8s (RBAC/NetworkPolicy/probe/HPA/GitOps) | "Deployed a service to K8s with secure defaults; managed it declaratively with GitOps" |
| [`Capstone 3`](capstones/CAP3-blok-e-sonu.md) | SLO + alerting + incident + verified restore | "Owned a system end to end: defined an SLO, managed an incident, verified backups by restoring them" |

> 🔒 Repo READMEs contain no real IP/domain/credential (the capstones' placeholder rule). If
> you're going to share a public GitHub repo, this is a leak check, not a cosmetic detail.

---

## 🔧 2. Block F artifacts → evidence of judgment

Block F isn't pure reading; every module ships a **written artifact**. These are the most
concrete evidence of the L2 (judgment) radius — they demonstrate reasoning, not code.

| Module | Artifact you produce | Corresponding CV line type |
|---|---|---|
| [`F1`](block-f-judgment/F1-maliyet-finops.md) | `finops-analiz.md` — cost breakdown + optimization | "Broke down a workload's cost by component and justified an optimization with numbers" |
| [`F2`](block-f-judgment/F2-tehdit-uyum.md) | `tehdit-modeli.md` — STRIDE table + control/evidence map | "Produced a threat model for a service; mapped a regulatory clause to a concrete control" |
| [`F4`](block-f-judgment/F4-yazma-adr-rfc.md) | an ADR + a rubric-scored postmortem | "Wrote architectural decisions as ADRs; kept postmortems blameless and action-oriented" |
| [`F5`](block-f-judgment/F5-stakeholder-vendor.md) | `karar-yazisi.md` — a justified "no" + vendor evaluation | "Evaluated a vendor decision for lock-in risk; wrote a justified 'no' to a request" |

> F3's output (`golden-path-onerisi.md`) is a platform proposal draft; more than a CV line, it's
> a writing sample that demonstrates **judgment** on platform/IDP topics — something you share
> in an interview.

---

## 🔧 3. Blocks → skills section

Know which block proves what when filling in the CV's "Skills" section. The mapping below
feeds [`CV-Tips.md`](../18-Career/CV-Tips.md) → "Skills — Categorized".

| Block | Area it proves | Honest level statement |
|---|---|---|
| A–B | Linux, networking, git, observability fundamentals | basic — "I can use it, I can narrow down its failures" |
| C | Container, CI, IaC, cloud fundamentals | intermediate — "I can deploy it reproducibly" |
| D | K8s, RBAC/NetworkPolicy, secrets, supply chain, GitOps | intermediate-advanced — "I can operate it with secure defaults" |
| E | SLO, alerting, incident, restore | advanced — "I can own a system" |
| F | FinOps, threat/compliance, platform, writing, decision-making | judgment — "I can weigh in on which system should exist" |

> "Advanced / intermediate / basic" are honest labels; an "expert" claim gets challenged in an
> interview. Only write "intermediate/advanced" for an area once you've passed that block's
> acceptance criteria and its capstone.

---

## 🔧 4. Turning an artifact into a CV bullet — 4 steps

1. **Pick the artifact:** which capstone/write-up? (The evidence will point here.)
2. **Find the impact:** what changed? From-scratch setup time, failure detection, security
   surface, cost.
3. **Measure it:** write your own `<before>` and `<after>` values from your own environment.
   Can't measure it? Use a verifiable verb instead.
4. **Compress into STAR:** situation → task → action → result; strongest bullet on top.
   Detail: [`CV-Tips.md`](../18-Career/CV-Tips.md) → "Experience Section".

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| "K8s, Docker, Terraform, AWS…" tool dump | Doesn't show what you did — anyone can write this | Tie the tool to an impact: "deployed Y with X, Z changed" |
| Writing a metric you never measured | It's the first thing asked in an interview; you fold | Only numbers you measured yourself; otherwise a verifiable verb |
| Not linking to capstone repos | A claim without evidence is an empty claim | Give the GitHub link; make the README understandable to a stranger |
| Real IP/credential in a repo | A leak; makes you look security-unaware | Placeholders + referenced secrets (the capstone rule) |
| Title claims ("senior-level infrastructure") | The market grants the title, not you | Write the competency instead: "owned a system end to end" |
| Writing "advanced" level before finishing the block | Acceptance criteria not passed — it's a bluff | Tie the level to the block's capstone |
| The same CV for every role | The impact context gets lost | Surface artifacts to match the target role |
| Hiding Block F artifacts | The judgment/reasoning behind decisions stays invisible | Share the ADR/postmortem as a writing sample |

---

## 📋 Checklist

```
[ ] Every capstone is a public (or shareable) repo; the README is enough for a stranger
[ ] Repos have NO real IP/domain/credential (placeholders + referenced secrets)
[ ] Every CV bullet points to an artifact (verifiable)
[ ] Numbers are ones you measured yourself; no invented metrics
[ ] Level labels rest on the block's capstone (no bluffing)
[ ] No title claims; competency language throughout
[ ] Block F artifacts (ADR/postmortem/decision write-up) are ready as writing samples
[ ] CV is prioritized to match the target role
```

---

## 📚 References

- [`18-Career/CV-Tips.md`](../18-Career/CV-Tips.md) — CV structure, impact-based bullets, skill categories
- [`capstones/`](capstones/CAP1-blok-c-sonu.md) — CAP1–CAP3 specs + portfolio README templates
- [`README.md`](README.md) → Honest ceiling — why the last two gates can't be passed on your own
- [`block-f-judgment/`](block-f-judgment/F1-maliyet-finops.md) — F1–F5, the written artifacts of judgment

---

> *"The best CV line is the one you can open and walk someone through when they say 'tell me about this' in an interview."*
