---
description: "Conventional Commits 1.0 spec: the feat/fix/chore commit format, why it matters, and how to enforce it in CI; the foundation for automated changelog and semver bump."
tags:
  - Git
  - CI/CD
  - Policy as Code
  - Cheatsheet
---
# Conventional Commits — Disciplined Commit Messages

> *"A commit with the message `fix typo lol` — 6 months later nobody
> knows which bug it fixed. **The message matters as much as the
> code** — it's what saves you in bisect, changelog, postmortem."*

This guide covers the Conventional Commits 1.0 spec, why it's useful,
and how to enforce it in CI. **This is the gateway to automated
changelog + semver bump.**

---

## 🎯 Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Examples
```
feat(payments): add stripe webhook signature verification

fix(api): handle nil pointer in user lookup

docs(readme): update kubernetes installation steps

chore(deps): bump go from 1.22 to 1.23

refactor(db): extract connection pool config to env

perf(search): use trigram index for partial match (3x faster)

test(checkout): add edge case for empty cart

ci(github): add OIDC for AWS deploy

build(docker): switch to distroless base

style: format with prettier

revert: feat(payments): add stripe webhook (#123)
```

---

## 🏷️ Type Catalog

| Type | Meaning | Semver impact |
|---|---|---|
| **feat** | New feature | MINOR |
| **fix** | Bug fix | PATCH |
| **docs** | Documentation only | none |
| **style** | Format/whitespace, no behavior change | none |
| **refactor** | Same behavior, code rewritten | none |
| **perf** | Performance improvement | PATCH |
| **test** | Add/update tests | none |
| **build** | Build system (docker, deps) | none |
| **ci** | CI config | none |
| **chore** | Other (housekeeping, license, etc.) | none |
| **revert** | Revert a commit | varies |

### `BREAKING CHANGE`
For a major bump, use `BREAKING CHANGE:` in the body or `!` in the title:
```
feat(api)!: rename /users/me to /users/current

BREAKING CHANGE: clients using /users/me must migrate to /users/current
by 2026-09-01.
```

---

## 🎯 Scope (Optional)

The affected module/area — single word, lowercase:
```
feat(payments): ...
fix(auth): ...
docs(api): ...
chore(deps): ...
```

> 🔑 **Standardize** scope: `payments`, `api`, `db`, `auth`. Don't
> pick a random name on every PR. Keep it aligned with CODEOWNERS.

---

## ✏️ Description Rules

### ✅ Good
- **Imperative**: "add", "fix", "update" (not past tense)
- **Start lowercase**
- **No period** at the end
- **~50 characters** (max 72)
- **WHAT, not WHY**: "use trigram index" (what, not why)

### ❌ Bad
- "Added new feature" (past tense, capitalized)
- "Fixed bug." (has a period, not clear)
- "wip" (meaningless)
- "asdf fix" (nonsense)
- 100+ character title

---

## 📝 Body — Write the Why

If the title is `WHAT`, the body should be `WHY` + `HOW`:

```
fix(checkout): retry payment webhook on 5xx

Stripe webhook retries 3 times (default) when it gets a 5xx.
Our handler wasn't idempotent → risk of duplicate charge.

Fix:
- Idempotency key as unique constraint in DB
- Webhook handler check: existing → skip
- Explicit retry policy: max 3, exponential backoff

Refs: INC-2026-04-12 postmortem
```

---

## 🔗 Footer — Issue + Breaking Change

```
fix(api): correct rate limit calculation

Body...

Closes: #234, #235
Refs: PROJ-1234
BREAKING CHANGE: Rate limit response header renamed
  X-RateLimit-Remaining → RateLimit-Remaining (RFC standard)
```

### Co-Authored-By
Pair / mob programming:
```
feat(search): full-text search on products

Co-Authored-By: Alice Doe <alice@example.com>
Co-Authored-By: Bob Smith <bob@example.com>
```

---

## 🤖 Automation

### release-please (Google)
```yaml
# .github/workflows/release-please.yml
on:
  push:
    branches: [main]

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@<VERSION>
        with:
          release-type: simple   # or node, go, python
```

Conventional Commits → automatically produces:
- Semver bump (`feat` → MINOR, `fix` → PATCH, `BREAKING` → MAJOR)
- `CHANGELOG.md` update (categorized)
- Release PR (merge with a single click)
- Tag creation

### changesets (npm ecosystem)
```bash
npx changeset
# interactive: which package, what type, description
git add .changeset/<HASH>.md
git commit -m "chore: changeset"
```

### semantic-release
```yaml
# .releaserc
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    "@semantic-release/github"
  ]
}
```

---

## 🚦 PR Title Enforcement

The PR title must also follow Conventional Commits (with squash merge, the PR title becomes the commit):

```yaml
# .github/workflows/pr-title.yml
name: Validate PR Title

on:
  pull_request:
    types: [opened, edited, synchronize]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: amannn/action-semantic-pull-request@<VERSION>
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          types: |
            feat
            fix
            docs
            style
            refactor
            perf
            test
            build
            ci
            chore
            revert
          requireScope: false
          subjectPattern: ^(?![A-Z]).+$   # must start lowercase
```

---

## 🔧 Local Enforcement: commitlint

```json
// package.json
{
  "devDependencies": {
    "@commitlint/cli": "<VERSION>",
    "@commitlint/config-conventional": "<VERSION>",
    "husky": "<VERSION>"
  }
}
```

```js
// commitlint.config.js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'subject-case': [2, 'always', 'lower-case'],
    'header-max-length': [2, 'always', 72],
    'scope-enum': [2, 'always', [
      'api', 'auth', 'db', 'payments', 'search', 'ui', 'deps', 'ci'
    ]]
  }
};
```

```bash
# husky setup
npx husky add .husky/commit-msg 'npx commitlint --edit $1'
```

> 🔑 **Pre-commit hook = local guard.** Wrong format → commit rejected.
> Combined with the PR title check running in CI → nothing slips through.

---

## 📊 Automated Changelog Example

`release-please` output:

```markdown
# CHANGELOG.md

## [1.4.0] (2026-05-04)

### Features
- **payments**: add Stripe webhook signature verification (#234)
- **search**: full-text search on products (#241)

### Bug Fixes
- **api**: handle nil pointer in user lookup (#239)
- **checkout**: retry payment webhook on 5xx (#240)

### Performance Improvements
- **search**: use trigram index for partial match (3x faster) (#242)

### BREAKING CHANGES
- **api**: `/users/me` renamed to `/users/current`. Migrate by 2026-09-01.
```

> This changelog gets generated automatically every 6 months. A team that
> spends time hand-writing CHANGELOG is **wasting its own energy**.

---

## 🎯 Combining with Squash Merge

If you use GitHub squash merge:
- PR commits can be messy (`wip`, `fix typo`, etc.)
- After squash, one commit, message = PR title
- ⇒ **PR title must follow the convention**

Branch protection:
```yaml
required_pull_request_reviews:
  require_code_owner_reviews: true
allow_squash_merge: true
allow_merge_commits: false
allow_rebase_merge: false
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| `fix typo lol` | Which typo, in bisect? | `fix(docs): correct deployment.yaml indent` |
| `WIP` across 50 commits | History unreadable | Squash + clean message |
| No type: "added feature" | Automated tooling chokes | `feat(scope): ...` |
| No `!` for `BREAKING CHANGE` | Major bump gets missed | `feat!: ...` or in the body |
| Random scope (`payments`, `payment`, `pay`) | Filter breaks | Standardized scope list |
| No body, complex change | Unclear a year later, why | Explain the "why" in the body |
| Turkish + English mixed | Inconsistent | Pick one language (usually EN) |
| No issue link | Context lost | `Closes: #123` footer |
| `chore: update` (update what?) | Meaningless | `chore(deps): bump react 18.2 → 18.3` |
| `style: refactor logic` | Wrong type (style = format) | `refactor: extract helper` |
| Multi-purpose commit | Hard to bisect | Atomic, single topic |
| 200-character title | Truncated in diff view | Title 50, detail in body |

---

## 📋 Conventional Commits Adoption Checklist

```
[ ] Type list in the team's docs
[ ] Scope list standardized
[ ] commitlint pre-commit hook (local)
[ ] PR title CI check (semantic-pull-request action)
[ ] Squash merge enforced (linear history)
[ ] release-please or changesets set up
[ ] CHANGELOG.md generated automatically
[ ] BREAKING CHANGEs clearly marked
[ ] Onboarding doc: "format on your first PR"
[ ] Quarterly: type/scope usage analysis
```

---

## 📚 References

- **Conventional Commits 1.0** — conventionalcommits.org
- **Semantic Versioning 2.0** — semver.org
- **release-please** — github.com/googleapis/release-please
- **changesets** — github.com/changesets/changesets
- **commitlint** — commitlint.js.org
- [`Trunk-Based-Development.md`](Trunk-Based-Development.md)
- [`Code-Review-Checklist.md`](Code-Review-Checklist.md)

---

> *"Conventional Commits isn't 'prescriptive bureaucracy' — it's **a
> precondition for automation**. The CHANGELOG that answers how much
> value got shipped by the end of the day is the output of these rules."*
