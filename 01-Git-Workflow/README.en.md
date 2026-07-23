---
description: "Modern Git workflow guide index: trunk-based development, conventional commits, code review, stacked diffs and PR automation; the 2026 branching stack."
tags:
  - Git
  - CI/CD
  - Roadmap
  - Platform Engineering
---
# 01 · Git Workflow

> *"A branch's lifespan equals a bug's lifespan."*

Branching strategy, commit discipline, and code review practices for a
modern, fast development flow.

## Contents

| File | Topic |
|---|---|
| [`Trunk-Based-Development.md`](Trunk-Based-Development.md) | Why not Git Flow; trunk-based + feature flag flow |
| [`Conventional-Commits.md`](Conventional-Commits.md) | Canonical use of `feat:`, `fix:`, `chore:` + automated changelog |
| [`Code-Review-Checklist.md`](Code-Review-Checklist.md) | How to do a good review; the "nit/blocker/question" category system |
| [`Stacked-Diffs.md`](Stacked-Diffs.md) | Graphite/sapling flow: small PR stacks |
| [`PR-Templates-and-Automation.md`](PR-Templates-and-Automation.md) | PR template, automatic labels, semantic-pr-action |

## Recommended 2026 stack

```
Branch strategy:    Trunk-based (main + short-lived feature branch)
Merge strategy:     Squash merge (clean history)
PR signal:          Conventional Commits + Semantic PR titles
Release:            release-please / changesets (automated changelog)
Branch protection:  required reviews + status checks + linear history
Stacked diffs:      Graphite (optional for large features)
```

## Anti-patterns

- ❌ Splitting `develop` and `main` — unnecessary complexity
- ❌ Long-lived `feature/big-rewrite` (a branch living for 3 months)
- ❌ History spammed by merge commits
- ❌ Commit messages like `WIP fix typo lol`
- ❌ A "5 people must approve this PR" policy — bottleneck
