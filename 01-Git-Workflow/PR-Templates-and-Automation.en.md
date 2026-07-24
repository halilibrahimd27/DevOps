---
description: "PR hygiene on GitHub: wiring PR templates, automatic labels, semantic-pr-action, commit validation, CODEOWNERS, and Renovate/Dependabot into PR traffic automation."
tags:
  - Git
  - CI/CD
  - Template
  - Policy as Code
---
# PR Templates & Automation — Make PRs Standard, Fast, Traceable

> *"Every PR with an empty description, no label, no link, no checklist →
> the reviewer spends 30 minutes trying to figure out 'why does this PR exist?'. **PR
> hygiene** determines the team's **average lead time**."*

This guide lays out concrete ways to discipline **PR
traffic** through automation on GitHub — PR templates, automatic
labels, semantic-pr-action, commit message validation, dependency
bots, and CODEOWNERS.

---

## 🎯 The Purpose of PR Hygiene

| Goal | Mechanism |
|---|---|
| **Descriptive** description | PR template |
| **Consistent** title | semantic-pr-action |
| **Correct reviewer** | CODEOWNERS |
| **Test/build verified** | Required CI checks |
| **Safe merge** | Branch protection + status checks |
| **Audit trail** | linked issue, conventional commit |
| **Fast maintenance** | Renovate / Dependabot |

---

## 📝 PR Template

`.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## Why?
<what's the problem, why are we solving it, which metric/feedback/incident it came from>

## What?
<summary: what was done, which approach was chosen>

## Alternative approaches (if considered)
- A: <short>
- B: <short>
- Chosen: <rationale>

## Test
- [ ] Unit test added/updated
- [ ] Integration test
- [ ] Manual test:
  - Step 1:
  - Step 2:
- [ ] Screenshot / sample output (if UI/CLI)

## Risk & Rollback
<what this could break on deploy, how to roll back>

## Linked
Closes: #123
Refs: PROJ-1234
Postmortem: INC-2026-04-12

## Checklist
- [ ] PR title in Conventional Commits format
- [ ] Self-review done
- [ ] Documentation updated (if applicable)
- [ ] Added to CHANGELOG if a breaking change
- [ ] No sensitive data in logs
- [ ] CODEOWNERS assigned correctly
```

### Multiple templates (template selection)
Multiple templates under `.github/PULL_REQUEST_TEMPLATE/`:

```
.github/PULL_REQUEST_TEMPLATE/
├── feature.md
├── bugfix.md
└── refactor.md
```

Selection via URL:
```
github.com/<ORG>/<REPO>/compare/main...feat-x?template=feature.md
```

---

## 🏷️ Semantic PR Title (Conventional Commits Enforce)

`.github/workflows/pr-title.yml`:

```yaml
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
          subjectPattern: ^(?![A-Z]).+$
          subjectPatternError: |
            PR title must start with a lowercase letter.
            Example: "fix(api): handle nil pointer"
          wip: false
          validateSingleCommit: false
```

> 🔑 On squash merge, **the PR title becomes the commit message**. So if the PR title
> follows Conventional Commits, the automatic changelog works.

---

## 🤖 Automatic Labels

### Path-based labels (`pull_request_target`)
`.github/labeler.yml`:
```yaml
backend:
  - changed-files:
      - any-glob-to-any-file: 'backend/**'

frontend:
  - changed-files:
      - any-glob-to-any-file: 'frontend/**'

infra:
  - changed-files:
      - any-glob-to-any-file:
          - 'terraform/**'
          - 'k8s/**'

docs:
  - changed-files:
      - any-glob-to-any-file: 'docs/**'

dependencies:
  - changed-files:
      - any-glob-to-any-file:
          - 'package.json'
          - 'package-lock.json'
          - 'go.mod'
          - 'go.sum'
          - 'requirements.txt'

security:
  - changed-files:
      - any-glob-to-any-file:
          - '08-Security/**'
          - '.github/workflows/*scan*'

needs-review:
  - changed-files:
      - any-glob-to-any-file: '**/*.tf'
```

```yaml
# .github/workflows/labeler.yml
name: PR Labeler

on:
  pull_request_target:
    types: [opened, synchronize]

permissions:
  contents: read
  pull-requests: write

jobs:
  label:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/labeler@<VERSION>
```

### Size label (how many lines)
```yaml
- uses: codelytv/pr-size-labeler@<VERSION>
  with:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    xs_label: 'size: XS'
    xs_max_size: '10'
    s_label: 'size: S'
    s_max_size: '100'
    m_label: 'size: M'
    m_max_size: '500'
    l_label: 'size: L'
    l_max_size: '1000'
    xl_label: 'size: XL'
    fail_if_xl: 'false'
```

→ When the **size: XL** label shows up, the reviewer can give the feedback "this PR is too big."

---

## 👥 CODEOWNERS

`.github/CODEOWNERS`:
```
# Default
*                       @platform-team

# Specific paths
/api/                   @backend-team
/api/auth/              @backend-team @security-team
/api/payments/          @backend-team @payments-team @security-team
/web/                   @frontend-team
/infra/                 @platform-team
/k8s/                   @platform-team
/.github/               @platform-team

# Specific files
*.tf                    @platform-team
Dockerfile              @platform-team @security-team
.github/workflows/      @platform-team
package.json            @frontend-team @platform-team
go.mod                  @backend-team @security-team
```

> When **`Require code owner reviews`** is enabled in branch protection, a PR
> touching these paths gets the **correct reviewer** automatically assigned.

---

## 🔒 Branch Protection Rules

GitHub UI or the Probot/Settings repo:

```yaml
main:
  required_status_checks:
    strict: true
    contexts:
      - "ci/lint"
      - "ci/unit-tests"
      - "ci/integration"
      - "security/sast"
      - "security/sca"
      - "PR Title"

  enforce_admins: true

  required_pull_request_reviews:
    required_approving_review_count: 1
    require_code_owner_reviews: true
    dismiss_stale_reviews: true

  required_linear_history: true
  required_conversation_resolution: true

  restrictions: null
  allow_force_pushes: false
  allow_deletions: false
```

> 🔑 **`required_conversation_resolution: true`** — comments must be resolved
> before merge. Open conversation = no merge.

---

## 🔄 Renovate / Dependabot

### Renovate (recommended, more flexible)
`.github/renovate.json`:
```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:recommended",
    ":semanticCommits"
  ],
  "labels": ["dependencies"],
  "schedule": ["after 9am on monday"],
  "timezone": "Europe/Istanbul",
  "packageRules": [
    {
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true,
      "automergeType": "pr",
      "platformAutomerge": true
    },
    {
      "matchUpdateTypes": ["major"],
      "labels": ["dependencies", "major"],
      "reviewers": ["team:platform-team"]
    },
    {
      "matchPackagePatterns": ["@actions/"],
      "groupName": "GitHub Actions",
      "pinDigests": true
    },
    {
      "matchPackagePatterns": ["argoproj"],
      "matchUpdateTypes": ["major"],
      "labels": ["dependencies", "argocd-major"],
      "automerge": false
    }
  ],
  "vulnerabilityAlerts": {
    "labels": ["security"],
    "automerge": true
  },
  "lockFileMaintenance": {
    "enabled": true,
    "schedule": ["before 9am on monday"]
  }
}
```

### Dependabot (simple, GitHub-native)
`.github/dependabot.yml`:
```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    labels: [dependencies]
    open-pull-requests-limit: 10

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels: [dependencies, ci]

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
    labels: [dependencies, security]
```

> 🔑 **Pinning digests for GitHub Actions** is mandatory — Renovate `pinDigests: true`.

---

## 🧹 Stale Bot — Automatically Clean Up Old PRs

`.github/workflows/stale.yml`:
```yaml
name: Mark stale issues and PRs

on:
  schedule:
    - cron: '0 9 * * *'

jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/stale@<VERSION>
        with:
          stale-pr-message: |
            This PR hasn't been updated in 30 days.
            If you're still active on it, leave a comment; otherwise it'll be closed in 7 days.
          close-pr-message: 'This PR has been inactive for a long time; closed.'
          stale-pr-label: 'stale'
          days-before-pr-stale: 30
          days-before-pr-close: 7
          exempt-pr-labels: 'security,blocked-on-other-pr'
```

---

## 🧪 PR Quality Gates

### Is the PR description empty?
```yaml
# .github/workflows/pr-quality.yml
- name: Check PR description not empty
  run: |
    if [ -z "${{ github.event.pull_request.body }}" ]; then
      echo "::error::PR description is empty — fill out the template"
      exit 1
    fi

- name: Check linked issue
  run: |
    if ! echo "${{ github.event.pull_request.body }}" | grep -E "(Closes|Refs|Fixes) #[0-9]+"; then
      echo "::warning::No linked issue"
    fi
```

### Auto-assign reviewer
```yaml
- uses: kentaro-m/auto-assign-action@<VERSION>
  with:
    configuration-path: .github/auto-assign.yml
```

`.github/auto-assign.yml`:
```yaml
addReviewers: true
addAssignees: author
reviewers:
  - alice
  - bob
  - carol
numberOfReviewers: 1
useReviewGroups: true
reviewGroups:
  backend: [alice, bob]
  frontend: [carol, dave]
```

---

## 📊 PR Metrics Dashboard

Track:
- **Median PR size** (target: < 400 lines)
- **PR open → first review** (target: < 4 hours)
- **PR open → merge** (target: P50 < 1 day)
- **Review iteration count** (target: < 3)
- **Approval per PR** (anomaly detection)

Via GitHub API + Grafana / Pulse / Code Climate Velocity.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| No PR template | Reviewer asks "why" | Standardize template |
| PR titles are free-form | Conventional Commits lost | semantic-pr-action |
| No CODEOWNERS | Wrong reviewer assigned | Path-based ownership |
| No branch protection | Direct push, force push | Required checks + reviews |
| No Renovate / Dependabot | CVEs pile up | Auto-PR + auto-merge minor |
| Renovate `automerge: false` for everything | Manual work | Patch/minor auto, major manual |
| Dependabot `latest` GitHub Action | Mutable tag, supply chain risk | `pinDigests: true` |
| Stale PRs open for 6 months | Maintenance overhead | stale bot |
| PR size never measured | Mega PRs | size labeler + warn if too big |
| `Require conversation resolution` disabled | Merge with open comments | enable |
| `dismiss_stale_reviews` disabled | Approval stuck on stale state | enable |
| No auto-assign | "Who should look at this?" question | Round-robin auto-assign |
| Commit messages unhygienic, not cleaned up after squash | Bisect is hard | semantic-pr-action |
| No linked issue | Trace missing | mandatory field in template |

---

## 📋 PR Automation Checklist

```
[ ] PR template `.github/PULL_REQUEST_TEMPLATE.md`
[ ] Multiple templates (feature/bugfix/refactor)
[ ] semantic-pr-action: PR title Conventional Commits
[ ] CODEOWNERS with specific paths
[ ] Branch protection: required checks + reviews + linear history
[ ] Required conversation resolution
[ ] Auto-assign reviewer (round-robin)
[ ] Path-based labeler
[ ] Size labeler (XS-XL)
[ ] Renovate or Dependabot
[ ] Renovate: minor/patch auto-merge
[ ] Renovate: pin digests (security)
[ ] Stale bot: 30-day warn, 7-day close
[ ] Pre-commit hook: gitleaks + lint
[ ] CI: SAST, SCA, lint, test, build
[ ] PR metrics dashboard (median size, lead time)
[ ] Quarterly: PR hygiene review
```

---

## 📚 References

- **GitHub PR Template Docs** — docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests
- **semantic-pull-request** — github.com/amannn/action-semantic-pull-request
- **Renovate** — docs.renovatebot.com
- **Dependabot** — docs.github.com/en/code-security/dependabot
- **CODEOWNERS** — docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- [`Conventional-Commits.md`](Conventional-Commits.md)
- [`Code-Review-Checklist.md`](Code-Review-Checklist.md)
- [`Trunk-Based-Development.md`](Trunk-Based-Development.md)
- [`02-CI-CD/Pipeline-Performance.md`](../02-CI-CD/Pipeline-Performance.md)

---

> *"PR automation isn't **control**, it's **friction reduction**.
> A PR so clear the reviewer can't even ask 'why?' is the
> precondition for a **fast merge**."*
