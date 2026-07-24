---
description: "Stacked diffs pattern: breaking a large feature into small, genuinely reviewable PRs; tooling and workflow with Graphite, Sapling, or a manual branch chain."
tags:
  - Git
  - CI/CD
  - Culture
  - Field Notes
---
# Stacked Diffs — Breaking a Large Feature into Small PRs

> *"Telling an engineer to 'review' a 3000-line PR means asking them
> to **close their eyes** and write 'LGTM'. Stacked diffs split the
> same feature into 6 small PRs — that's **real review**."*

This guide covers the **stacked diffs** pattern — Graphite, Sapling, or
a manual branch chain — with concrete tools and workflow.

---

## 🎯 The Problem: Large PRs

```
Traditional:
  feature/big-rewrite (lives for 3 weeks)
    ├── 47 commits
    ├── 3000-line diff
    └── 1 PR
        → reviewer: "didn't understand it, LGTM"
```

Result:
- Review is superficial
- Bugs caught late
- Merge conflict hell
- Incompatible with trunk-based

---

## ✅ The Solution: Stacked Diffs

```
main
 │
 ├── feat/refactor-1-extract-helper      [PR #1]
 │    │
 │    ├── feat/refactor-2-add-validation  [PR #2, base: #1]
 │    │    │
 │    │    ├── feat/refactor-3-new-flow   [PR #3, base: #2]
 │    │    │    │
 │    │    │    └── feat/refactor-4-tests [PR #4, base: #3]
```

Each PR is **small** (100-300 lines), independently reviewable, **merged sequentially**.

---

## 🛠️ Manual Stacked Diffs (Without Tooling)

### Flow
```bash
# 1. First PR from the base branch
git checkout main && git pull
git checkout -b feat/refactor-1-extract-helper
# write code
git commit -m "feat: extract helper function"
git push -u origin feat/refactor-1-extract-helper
gh pr create --base main

# 2. Second PR on top of the first
git checkout -b feat/refactor-2-add-validation
# write code
git commit -m "feat: add validation layer"
git push -u origin feat/refactor-2-add-validation
gh pr create --base feat/refactor-1-extract-helper

# 3. Third PR
git checkout -b feat/refactor-3-new-flow
# ...
gh pr create --base feat/refactor-2-add-validation
```

### Problem: PR #1 gets review feedback
```bash
git checkout feat/refactor-1-extract-helper
# make the fix
git commit --amend
git push --force-with-lease

# Now #2 and #3 are behind their base
git checkout feat/refactor-2-add-validation
git rebase feat/refactor-1-extract-helper
git push --force-with-lease

git checkout feat/refactor-3-new-flow
git rebase feat/refactor-2-add-validation
git push --force-with-lease
```

> ⚠️ **Manual = pain**. In a stack of 3+ PRs, the rebase chain produces a lot of errors. Use a tool.

---

## 🛠️ Graphite — Modern Stacked Tool

[Graphite](https://graphite.dev) adds a stacked PR workflow on top of GitHub.

### Setup
```bash
brew install withgraphite/tap/graphite
gt auth
```

### Flow
```bash
# 1. Start a new stack
gt branch create feat/refactor-1
# write code
gt commit create -m "feat: extract helper"

# 2. New branch on top
gt branch create feat/refactor-2
# write code
gt commit create -m "feat: add validation"

# 3. Continue
gt branch create feat/refactor-3

# 4. Submit all (as PRs)
gt stack submit
```

### Restack (PR #1 changes, upper PRs update automatically)
```bash
gt branch checkout feat/refactor-1
# make the fix
gt commit amend

# The entire upper stack rebases automatically
gt stack restack
gt stack submit
```

### Merge order
- PR #1 merges → main
- Graphite automatically: PR #2's base changes to main
- PR #2 merges → main
- Continue

---

## 🛠️ Sapling (Meta) — Native Stacked

[Sapling](https://sapling-scm.com) is Meta's open-source Git replacement:

```bash
# Create the stack
sl commit -m "feat: extract helper"
sl commit -m "feat: add validation"
sl commit -m "feat: new flow"

# Turn into GitHub PRs
sl pr submit
```

> Sapling is compatible with Git — the repo is the same, only the CLI differs.

---

## 🌳 Other Tools

| Tool | Notes |
|---|---|
| **Graphite** | SaaS + CLI, GitHub native |
| **Sapling** | Meta OSS, Git-compatible |
| **`spr`** (CLI) | Lightweight, opensource |
| **`git stack`** | bash-based plugin |
| **Phabricator** | Old, still used at Meta |
| **Gerrit** | Google ecosystem |

> 🔑 **2026 recommendation**: If you're on GitHub, **Graphite**. If you want OSS, **Sapling**.

---

## 🎯 When to Use Stacked Diffs?

### ✅ Good scenarios
- Large refactor (old system → new)
- Multi-step feature (each step produces value)
- Migration (database, framework)
- Wide impact (5+ files changed)
- There are **logical chunks** the reviewer can understand

### ❌ Bad scenarios
- A single small bug fix (one PR is enough)
- Independent features (parallel branches are enough)
- Geographically distributed team with many people (rebase conflicts)
- Rapid prototyping (overhead)

---

## 📐 Splitting a Stack — The Practical Art

### Example of splitting a single feature into 4 PRs:
**Feature**: "Add 2FA to the user profile page"

```
PR #1: schema migration (add column)
  - DB: users.totp_secret column added (nullable)
  - Migration script
  - Test: schema validation
  → Independent, revertible

PR #2: backend totp helper
  - lib/totp.go: generate, verify
  - Unit test
  → Independent, not used yet

PR #3: API endpoint /v1/users/2fa/setup
  - Endpoint impl (uses the earlier helper)
  - Auth middleware update
  - Integration test
  → API exists but no UI, can ship to prod (feature flag)

PR #4: UI component
  - React component
  - Settings page integration
  - E2E test
  → Full feature, flag on
```

> 🔑 Every PR is **independently sensible** + **shippable to prod** + **reviewable**.

---

## 📋 Stacked Diff Hygiene

### Size of each PR
- **Target**: 100-300 lines
- **Max**: 500 lines
- **The smaller, the better the review**

### Every PR description
```markdown
## Stack
- #101 [extract helper]   ← this PR
- #102 add validation
- #103 new flow

## Why?
<problem>

## What does this PR do?
<this specific PR's job>

## Test
- [x] Unit test
- [x] Integration test
```

### Signal to the reviewer
```
[Stack 1/4] feat: extract helper function
[Stack 2/4] feat: add validation layer
[Stack 3/4] feat: new auth flow
[Stack 4/4] feat: UI integration
```

→ The reviewer sees the order and reviews in the right sequence.

---

## 🚦 Merge Strategy

### Bottom-up merge
```
PR #1 merges → main
   ↓
PR #2 base auto-updates to main
   ↓ review (if already done) → merge
   ↓
PR #3 ...
```

### Squash or rebase?
| Strategy | Pro | Con |
|---|---|---|
| **Squash merge** | Clean history (PR = 1 commit) | The stack's internal structure is lost |
| **Rebase merge** | Detailed history | Bisect is hard |
| **Merge commit** | Stack visible | Messy history |

> 🔑 **Most teams**: squash merge. The stack's internal structure stays in the PR description.

---

## 🧪 Interaction with CI

### CI must run for every PR in the stack
```yaml
# CI only tests the merge with the base, but to validate a stacked PR:
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches: [main, 'feat/**']    # a stacked PR's base can also be feat/*
```

### Selective testing (in large stacks)
- Only test the affected path
- See [`02-CI-CD/Pipeline-Performance.md`](../02-CI-CD/Pipeline-Performance.md)

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| 1500-line PR | Review is superficial | Split into a stack |
| Manual rebase chain | Source of errors | Graphite / Sapling |
| PRs that aren't independent | Can't merge from the bottom | Every PR self-contained |
| Stack too deep (10+ PRs) | Unmanageable | Max 5-6 PRs |
| Conflicts in the stack ignored | Later PRs break | Run `gt stack restack` regularly |
| PR description empty, no "stack 1/4" | Reviewer gets confused | Clear labeling |
| Force push history rewrite mid-stack | Reviewer's old comments are lost | `--force-with-lease` |
| Squash incompatible with stack | History gets messy | Squash + detail in the inner PR |
| A single developer runs the stack | Bus factor 1 | Pair or 2 reviewers |
| PR without tests | Not even independent | Every PR has tests |

---

## 📋 Stacked Diff Adoption Checklist

```
[ ] Tool choice: Graphite (recommended) / Sapling / manual
[ ] CI base branch: feat/* support
[ ] "Stack X/Y" field in the PR template
[ ] Enforce squash merge (linear history)
[ ] Branch protection: required CI per PR
[ ] Quarterly: stack metrics (avg PR size, lead time)
[ ] Onboarding: stack flow for new engineers
[ ] Documentation: when to stack, when to use a single PR
[ ] Stack max depth rule (e.g. max 6)
[ ] Pair / 2-reviewer on stacks
```

---

## 📚 References

- **Graphite** — graphite.dev
- **Sapling** — sapling-scm.com
- **Phabricator (Stacked Diffs origin)** — phacility.com (deprecated, reference)
- **Will Larson — Stacked Diffs vs PRs**
- [`Trunk-Based-Development.md`](Trunk-Based-Development.md)
- [`Code-Review-Checklist.md`](Code-Review-Checklist.md)
- [`Conventional-Commits.md`](Conventional-Commits.md)

---

> *"Stacking isn't 'bureaucracy' — it's the only way to preserve
> **review quality**. Squeezing a large feature into a single PR
> means **not reviewing** it at all."*
