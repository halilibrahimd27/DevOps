---
description: "Trunk-based development instead of Git Flow: a guide to fast, safe development on main using short-lived feature branches, feature flags, and safe prod deploys."
tags:
  - Git
  - CI/CD
  - DORA
  - Platform Engineering
---
# Trunk-Based Development — Where Speed and Safety Meet

> *"If your branch lives 3 days, that's bad; 3 weeks, that's a disaster;
> 3 months, it's **no longer part of your codebase** — it's a parallel universe."*

This guide explains why you should forget Git Flow, why you should
adopt trunk-based development, and how to do it with **feature flags +
safe prod deploys**.

---

## 🎯 What Is Trunk-Based Development?

```
main (trunk)  ─●───●───●───●───●───●───●───●───●─→
                  ↑       ↑       ↑       ↑
              feat-a   fix-b   feat-c   feat-d
              (1 day)  (4 hours)(2 days) (5 hours)
```

**One rule:** all development stays very close to `main`. Feature
branches are **short-lived** (1-2 days max).

---

## 🆚 Git Flow vs Trunk-Based

| Dimension | **Git Flow** (2010) | **Trunk-Based** (2026) |
|---|---|---|
| Branch count | `main`, `develop`, `feature/*`, `release/*`, `hotfix/*` | `main` + short `feature/*` |
| Feature branch lifespan | Weeks / months | 1-2 days max |
| Merge frequency | End of sprint | Several times an hour |
| Release | Manual, develop → release → main | Every merge is prod-ready |
| Conflict management | "Big bang" surprise merges | Continuous, small conflicts |
| CI/CD | Slow (large PRs) | Fast (small PRs) |
| Productivity (DORA) | Low (long lead time) | High (deploy frequency) |
| Rollback | Complex (cherry-pick) | Single revert commit |

> 🔑 **The data:** DORA State of DevOps reports have said the same thing
> for 10 years running: high-performing teams work with **short-lived
> branches + several deploys a day**. Git Flow blocks that model.

---

## 🚧 Why Is Git Flow Broken?

### 1. The `develop`/`main` split is artificial
- `main` = "what's in production", `develop` = "the next release"
- In practice `develop` is always ahead → "so what even is `main`?" confusion
- Hotfix flow: `main` → `hotfix/*` → `main` + cherry-pick to `develop` → the same code lives in 3 places

### 2. Release branches = "a time tunnel for deploys"
- `release/v1.4` stays open for 3 weeks → bug fixes get merged into it → cherry-picked to main
- 3 weeks of drift from develop → merge conflict hell

### 3. Long feature branches = integration shock
- 3 weeks of solo development → merge day brings 200 files of conflicts
- Reviewer says "I have no idea what happened here" → rubber-stamp review
- The test pyramid breaks because integration is a surprise

### 4. Incompatible with CI/CD
- "Continuous integration" means integrating every day. Git Flow means once every two weeks.

---

## ✅ The Trunk-Based Stack

### Tools you need
1. **Branch protection** — no direct push to `main`
2. **Required CI** — no merge until test/lint/scan are green
3. **Required reviews** — 1 reviewer (not 2 — that's a bottleneck)
4. **Squash merge** — clean history
5. **Feature flags** — keep half-built features off in prod
6. **Automated deploy** — main → staging → prod (gated)

### A day in the flow
```
09:00  git checkout main && git pull
09:05  git checkout -b feat/add-pagination
09:10  ... write code, write tests ...
11:00  git push -u origin feat/add-pagination
11:05  open PR (template auto-fills)
11:10  CI green (3 min)
11:15  reviewer looks it over
11:30  approve + comment
11:35  squash merge → main
11:40  CI build + deploy to staging
12:00  smoke test passes → automatic canary to prod
12:15  canary metrics green → full prod rollout
```

> This flow ships a feature between **9 and 12**. In Git Flow that's 2 weeks of work.

---

## 🚦 Feature Flags: Trunk-Based's Non-Negotiable

> "We don't hide a feature behind a branch — we hide it behind a **flag**."

### Why?
- Merge half-built features into `main` while keeping them **behind a flag**
- Turn a feature on/off **live** in production (off during an incident)
- A/B testing, canary releases
- "Dark launch" — ship to prod without users seeing it, collect telemetry

### Flag types
| Type | Lifespan | Example |
|---|---|---|
| **Release flag** | Weeks-months (deleted afterward) | "New checkout flow" |
| **Experiment flag** | Weeks (deleted once the A/B result is in) | "Discount 10% vs 15%" |
| **Permission flag** | Permanent | "Premium user feature" |
| **Ops flag** | Permanent | "Retry 3x off (during an incident)" |

### Stack recommendations (2026)

| Tool | Type | Niche |
|---|---|---|
| **LaunchDarkly** | SaaS | Enterprise, rich UI |
| **Flagsmith** | Self-host + SaaS | OSS, lower cost |
| **GrowthBook** | Self-host + SaaS | A/B-test focused, OSS |
| **Unleash** | Self-host + SaaS | Norway-based, OSS, GitOps-friendly |
| **OpenFeature** | Standard (vendor-neutral) | Abstraction: SDK + provider |
| **ConfigCat** | SaaS | Small teams, cheap |

### Code example (Go + OpenFeature)
```go
import (
    "github.com/open-feature/go-sdk/openfeature"
)

client := openfeature.NewClient("checkout")

enabled, err := client.BooleanValue(
    ctx,
    "new-checkout-flow",
    false, // default
    openfeature.NewEvaluationContext(
        userID,
        map[string]interface{}{"plan": user.Plan},
    ),
)

if enabled {
    return newCheckoutFlow(ctx)
}
return oldCheckoutFlow(ctx)
```

### Flag hygiene
- Every flag has an **owner** + an **expiry date**
- Quarterly: auto-report flags that should be deleted
- A flag considered "permanent" is no longer a feature flag — it's configuration → move it to a permanent home

---

## 🔀 Branching Cookbook

### Feature: 1-2 days
```bash
git checkout main && git pull
git checkout -b feat/<short-desc>
# code, commit, push
gh pr create --fill
```

### Hotfix: there's a bug in prod
```bash
git checkout main && git pull
git checkout -b fix/<short-desc>
# minimal fix
gh pr create --label hotfix
# CI green → merge → automatic prod
```

> ⚠️ **Trunk-based has no separate hotfix branch.** A fast PR + auto-deploy already is one.

### Long-running refactor (if you're forced into one)
- ❌ A 3-week `feature/big-rewrite` branch
- ✅ Feature flag + small daily PRs into `main`
- ✅ The "strangler fig pattern" — old and new run in parallel, cut over with a flag

---

## 🛡️ Branch Protection Settings (GitHub)

```yaml
# .github/branch-protection.yaml (if you use Probot)
# or UI: Settings → Branches → main

main:
  required_status_checks:
    strict: true   # PR must be up to date with base
    contexts:
      - "ci/lint"
      - "ci/unit-tests"
      - "ci/integration-tests"
      - "security/sast"
      - "security/sca"

  enforce_admins: true   # admins can't bypass

  required_pull_request_reviews:
    required_approving_review_count: 1
    require_code_owner_reviews: true
    dismiss_stale_reviews: true   # new commit → review dismissed

  required_linear_history: true   # squash or rebase merge

  restrictions: null   # anyone can open a PR

  allow_force_pushes: false
  allow_deletions: false
```

> 🔑 **`required_approving_review_count: 1`** — more than that is a bottleneck.
> For critical code that needs two people, spot-enforce it with CODEOWNERS.

---

## ⚙️ CI Speed: the 90-Second Rule

Trunk-based's precondition is **fast CI**. A 30-min CI makes trunk-based impossible.

### Targets
| Pipeline | Duration |
|---|---|
| Lint + format | < 30s |
| Unit test | < 60s |
| SAST + SCA | < 90s |
| Integration test (on PR) | < 5 min |
| E2E (main only) | < 15 min |

### Speed boosters
- **Parallel matrix** (test sharding)
- **Cache** (npm, pip, go modules, Docker layers)
- **Selective testing** (only affected paths → not the whole suite)
- **Test pyramid** (lots of unit, little E2E)

See [`02-CI-CD/Pipeline-Patterns.md`](../02-CI-CD/Pipeline-Patterns.md).

---

## 📈 Migration: From Git Flow to Trunk-Based

### Week 1: Branch protection + speed up CI
- No direct push to `main`
- CI < 5 minutes (selective testing if needed)

### Week 2: Retire the `develop` branch
- `develop` → `main` merge (final sync)
- `develop` is now archived
- All PR bases = `main`

### Week 3: Feature flag stack
- Set up LaunchDarkly / Flagsmith / OpenFeature
- Start with a flag for the first big feature

### Week 4: Mandatory squash merge
- Repository setting: squash merge only
- "Allow merge commits" turned off

### Week 5: Remove release branches
- Automated changelog (release-please / changesets)
- A tag is just a point on main, no more release branches

### Week 6: Auto-deploy
- main → staging automatic
- staging smoke test passes → canary to prod
- Via Argo Rollouts or Flagger

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| `develop` + `main` split | Artificial complexity | A single `main` |
| A 3-week feature branch | Big-bang merge, conflicts | Feature flag + daily commits |
| `release/v1.4` open for 2 weeks | Cherry-pick hell | Trunk is always release-ready |
| Merge commit spam | Unreadable history | Squash merge |
| `WIP fix` commits | Bisect is impossible | Conventional Commits + squash |
| 4 required reviewers | Bottleneck, nobody actually reviews | 1 + CODEOWNERS spot-checks |
| CI takes 25 minutes | Trunk-based is impossible | < 5 min PR pipeline |
| No feature flags | Half-built features can't merge → long branches | Flag stack is mandatory |
| Flags never deleted | Code paths multiply, dead code | Quarterly cleanup, expiry |
| Force-push to `main` | History corrupted | Force-push protection |

---

## 📋 Trunk-Based Checklist

```
[ ] main branch protected (no force-push, no deletion)
[ ] Direct push forbidden; PR only
[ ] Required status checks: lint, unit, SAST, SCA
[ ] Required review: 1 (CODEOWNERS for specific paths)
[ ] Linear history (squash or rebase merge)
[ ] CI < 5 minutes (PR pipeline)
[ ] Conventional Commits enforced (semantic-pr-action)
[ ] Automated changelog (release-please)
[ ] Feature flag stack set up (LD/Flagsmith/OpenFeature)
[ ] Flag ownership + expiry (quarterly cleanup)
[ ] Auto-deploy: main → staging → prod (with canary)
[ ] Rollback: a single `git revert` + auto-deploy
[ ] No develop branch, no release branch
[ ] Branch lifespan: P50 < 1 day, P95 < 3 days
[ ] Deploy frequency: more than once a day
```

---

## 📚 References

- **Trunk Based Development site** — trunkbaseddevelopment.com (Paul Hammant)
- **Accelerate** (Forsgren, Humble, Kim) — the book behind the DORA metrics
- **State of DevOps Report** — the annual DORA report
- **Feature Toggles** — Pete Hodgson (Martin Fowler blog)
- [`Conventional-Commits.md`](Conventional-Commits.md)
- [`02-CI-CD/Pipeline-Patterns.md`](../02-CI-CD/Pipeline-Patterns.md)
- _`02-CI-CD/Pipeline-Performance.md`_ *(coming soon)*

---

> *"Git Flow was designed for the 2010 release model: 'monthly release,
> big-bang integration'. In 2026, if your team can deploy daily, **your
> branches' days are numbered**."*
