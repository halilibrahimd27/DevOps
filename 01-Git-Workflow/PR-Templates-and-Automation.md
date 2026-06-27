---
description: "GitHub'da PR hijyeni: PR template, otomatik label, semantic-pr-action, commit doğrulama, CODEOWNERS ve Renovate/Dependabot ile PR trafiğini otomasyona bağlama."
---
# PR Templates & Automation — PR'ları Standart, Hızlı, İzlenebilir Yap

> *"Her PR description boş, label yok, link yok, checklist yok →
> reviewer 30 dakika 'bu PR niye var?' anlamaya çalışır. **PR
> hijyeni** ekibin **ortalama lead time'ını** belirler."*

Bu rehber GitHub'da PR template, otomatik label, semantic-pr-action,
commit message validation, dependent bot ve CODEOWNERS ile **PR
trafiğini** otomasyonla disiplin haline getirmenin somut yollarını
sunar.

---

## 🎯 PR Hijyeninin Amacı

| Hedef | Mekanizma |
|---|---|
| **Açıklayıcı** description | PR template |
| **Konsistens** title | semantic-pr-action |
| **Doğru reviewer** | CODEOWNERS |
| **Test/build doğrulanmış** | Required CI checks |
| **Güvenli merge** | Branch protection + status checks |
| **Audit trail** | linked issue, conventional commit |
| **Hızlı maintenance** | Renovate / Dependabot |

---

## 📝 PR Template

`.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## Niye? (Why)
<problem ne, niye çözüyoruz, hangi metric/feedback/incident'ten geldi>

## Ne? (What)
<özet: ne yapıldı, hangi yaklaşım seçildi>

## Alternatif yaklaşımlar (düşünüldüyse)
- A: <kısa>
- B: <kısa>
- Seçilen: <gerekçe>

## Test
- [ ] Unit test eklendi/güncellendi
- [ ] Integration test
- [ ] Manuel test:
  - Adım 1:
  - Adım 2:
- [ ] Screenshot / örnek output (UI/CLI ise)

## Risk & Rollback
<deploy edildiğinde ne kırabilir, rollback nasıl>

## Linked
Closes: #123
Refs: PROJ-1234
Postmortem: INC-2026-04-12

## Checklist
- [ ] PR title Conventional Commits formatında
- [ ] Self-review yapıldı
- [ ] Documentation güncellendi (varsa)
- [ ] Breaking change ise CHANGELOG'a eklendi
- [ ] Sensitive data log'a düşmüyor
- [ ] CODEOWNERS doğru atandı
```

### Multiple templates (template seçimi)
`.github/PULL_REQUEST_TEMPLATE/` altında birden çok şablon:

```
.github/PULL_REQUEST_TEMPLATE/
├── feature.md
├── bugfix.md
└── refactor.md
```

URL ile seçim:
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
            PR title küçük harfle başlamalı.
            Örnek: "fix(api): handle nil pointer"
          wip: false
          validateSingleCommit: false
```

> 🔑 Squash merge'de **PR title commit message olur**. Yani PR title'ı
> Conventional Commits'a uyarsa otomatik changelog çalışır.

---

## 🤖 Otomatik Label

### Path-based label (`pull_request_target`)
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

### Size label (kaç satır)
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

→ **size: XL** label görünce reviewer "bu PR çok büyük" feedback verebilir.

---

## 👥 CODEOWNERS

`.github/CODEOWNERS`:
```
# Default
*                       @platform-team

# Spesifik path'ler
/api/                   @backend-team
/api/auth/              @backend-team @security-team
/api/payments/          @backend-team @payments-team @security-team
/web/                   @frontend-team
/infra/                 @platform-team
/k8s/                   @platform-team
/.github/               @platform-team

# Spesifik dosyalar
*.tf                    @platform-team
Dockerfile              @platform-team @security-team
.github/workflows/      @platform-team
package.json            @frontend-team @platform-team
go.mod                  @backend-team @security-team
```

> Branch protection'da **`Require code owner reviews`** açık olunca, bu
> path'lere dokunan PR'a otomatik **doğru reviewer** atanır.

---

## 🔒 Branch Protection Rules

GitHub UI veya Probot/Settings repo:

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

> 🔑 **`required_conversation_resolution: true`** — yorumların çözülmesi
> gerekir merge öncesi. Açık conversation = merge yok.

---

## 🔄 Renovate / Dependabot

### Renovate (önerilen, daha esnek)
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

### Dependabot (basit, GitHub-native)
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

> 🔑 **GitHub Actions için pin digest** zorunlu — Renovate `pinDigests: true`.

---

## 🧹 Stale Bot — Eski PR'ları Otomatik Temizle

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
            Bu PR 30 gündür update almadı.
            Hâlâ aktifsen yorum yap; yoksa 7 gün sonra kapatılacak.
          close-pr-message: 'PR uzun süredir inaktif; kapatıldı.'
          stale-pr-label: 'stale'
          days-before-pr-stale: 30
          days-before-pr-close: 7
          exempt-pr-labels: 'security,blocked-on-other-pr'
```

---

## 🧪 PR Quality Gates

### PR description boş mu?
```yaml
# .github/workflows/pr-quality.yml
- name: Check PR description not empty
  run: |
    if [ -z "${{ github.event.pull_request.body }}" ]; then
      echo "::error::PR description boş — template doldurun"
      exit 1
    fi

- name: Check linked issue
  run: |
    if ! echo "${{ github.event.pull_request.body }}" | grep -E "(Closes|Refs|Fixes) #[0-9]+"; then
      echo "::warning::Linked issue yok"
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

## 📊 PR Metrik Dashboard

Track:
- **Median PR size** (hedef: < 400 satır)
- **PR open → first review** (hedef: < 4 saat)
- **PR open → merge** (hedef: P50 < 1 gün)
- **Review iteration count** (hedef: < 3)
- **Approval per PR** (anomali tespit)

GitHub API + Grafana / Pulse / Code Climate Velocity ile.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| PR template yok | Reviewer "niye" sorar | Standardize template |
| PR title'lar serbest | Conventional Commits kayıp | semantic-pr-action |
| CODEOWNERS yok | Yanlış reviewer atanır | Path-based ownership |
| Branch protection yok | Direct push, force push | Required checks + reviews |
| Renovate / Dependabot yok | CVE birikir | Auto-PR + auto-merge minor |
| Renovate `automerge: false` her şey | Manuel iş | Patch/minor auto, major manual |
| Dependabot `latest` GitHub Action | Mutable tag, supply chain risk | `pinDigests: true` |
| Stale PR'lar 6 ay açık | Maintenance overhead | stale bot |
| PR boyut hiç ölçülmez | Mega PR'lar | size labeler + büyükse warn |
| `Require conversation resolution` kapalı | Yorumla merge | enable |
| `dismiss_stale_reviews` kapalı | Onay eski state'e | enable |
| Auto-assign yok | "Kim baksın?" sorusu | Round-robin auto-assign |
| Commit message hijyensiz, squash sonrası temizlenmiyor | Bisect zor | semantic-pr-action |
| Linked issue yok | Trace eksik | template'de zorunlu alan |

---

## 📋 PR Automation Checklist

```
[ ] PR template `.github/PULL_REQUEST_TEMPLATE.md`
[ ] Multiple template (feature/bugfix/refactor)
[ ] semantic-pr-action: PR title Conventional Commits
[ ] CODEOWNERS spesifik path'lerle
[ ] Branch protection: required checks + reviews + linear history
[ ] Required conversation resolution
[ ] Auto-assign reviewer (round-robin)
[ ] Path-based labeler
[ ] Size labeler (XS-XL)
[ ] Renovate veya Dependabot
[ ] Renovate: minor/patch auto-merge
[ ] Renovate: pin digests (security)
[ ] Stale bot: 30 gün warn, 7 gün close
[ ] Pre-commit hook: gitleaks + lint
[ ] CI: SAST, SCA, lint, test, build
[ ] PR metrik dashboard (median size, lead time)
[ ] Quarterly: PR hijyeni review
```

---

## 📚 Referanslar

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

> *"PR otomasyonu **kontrol** değil, **sürtünme azaltıcıdır**.
> Reviewer'ın 'niye?' soramayacağı kadar net PR, **hızlı merge'ün**
> ön koşuludur."*
