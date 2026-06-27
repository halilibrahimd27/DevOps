---
description: "Conventional Commits 1.0 spec: feat/fix/chore commit formatı, niye işe yaradığı ve CI'da nasıl enforce edileceği; otomatik changelog ve semver bump'ın temeli."
---
# Conventional Commits — Disiplinli Commit Mesajları

> *"`fix typo lol` mesajı olan bir commit, 6 ay sonra hangi bug'ın
> fix'i olduğu anlaşılmaz. **Mesaj kodun kadar önemli** — bisect'te,
> changelog'da, postmortem'de seni o yazı kurtarır."*

Bu rehber Conventional Commits 1.0 spec'ini, niye işine yaradığını,
ve bunu CI'da nasıl enforce edeceğini anlatır. **Otomatik changelog
+ semver bump'ın kapısı** budur.

---

## 🎯 Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Örnekler
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

## 🏷️ Type Kataloğu

| Type | Anlam | Semver impact |
|---|---|---|
| **feat** | Yeni özellik | MINOR |
| **fix** | Bug fix | PATCH |
| **docs** | Sadece doküman | none |
| **style** | Format/whitespace, davranış değişmedi | none |
| **refactor** | Davranış aynı, kod yeniden yazıldı | none |
| **perf** | Performans iyileştirme | PATCH |
| **test** | Test ekleme/güncelleme | none |
| **build** | Build sistemi (docker, deps) | none |
| **ci** | CI config | none |
| **chore** | Diğer (üyelik, license vs) | none |
| **revert** | Bir commit'i geri al | varies |

### `BREAKING CHANGE`
Major bump için body'de `BREAKING CHANGE:` veya başlıkta `!`:
```
feat(api)!: rename /users/me to /users/current

BREAKING CHANGE: clients using /users/me must migrate to /users/current
by 2026-09-01.
```

---

## 🎯 Scope (Opsiyonel)

Etkilenen modül/bölge — tek kelime, küçük harf:
```
feat(payments): ...
fix(auth): ...
docs(api): ...
chore(deps): ...
```

> 🔑 Scope **standardize**: `payments`, `api`, `db`, `auth`. Her PR'da
> rastgele isim koyma. CODEOWNERS ile uyumlu olsun.

---

## ✏️ Description Kuralları

### ✅ İyi
- **İmperatif**: "add", "fix", "update" (geçmiş zaman değil)
- **Küçük harf** başla
- **Nokta yok** sonda
- **50 karakter** civarı (max 72)
- **WHY değil WHAT**: "use trigram index" (niye değil, ne)

### ❌ Kötü
- "Added new feature" (geçmiş zaman, başlık büyük)
- "Fixed bug." (nokta var, açık değil)
- "wip" (anlamsız)
- "asdf fix" (saçma)
- 100+ karakter başlık

---

## 📝 Body — Niye'yi Yaz

Title `WHAT` ise body `WHY` + `HOW` olmalı:

```
fix(checkout): retry payment webhook on 5xx

Stripe webhook'ları 5xx aldığında 3 kez retry yapar (default).
Bizim handler'ımız idempotent değildi → duplicate charge riski.

Çözüm:
- Idempotency key DB'de unique constraint
- Webhook handler check: existing → skip
- Retry policy explicit: max 3, exponential backoff

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

## 🤖 Otomasyon

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
          release-type: simple   # veya node, go, python
```

Conventional Commits → otomatik:
- Semver bump (`feat` → MINOR, `fix` → PATCH, `BREAKING` → MAJOR)
- `CHANGELOG.md` güncellemesi (kategorize edilmiş)
- Release PR (tek bir tıkla merge)
- Tag oluşturma

### changesets (npm ekosistemi)
```bash
npx changeset
# interactive: hangi paket, ne tip, açıklama
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

PR title de Conventional Commits'a uymalı (squash merge'de PR title commit olur):

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
          subjectPattern: ^(?![A-Z]).+$   # küçük harfle başlamalı
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

> 🔑 **Pre-commit hook = local guard.** Yanlış format → commit reject.
> CI'da çalışan PR title check ile birleşir → kayıp yok.

---

## 📊 Otomatik Changelog Örneği

`release-please` çıktısı:

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

> 6 ayda bir bu changelog otomatik üretiliyor. Manuel CHANGELOG yazmaya
> zaman ayıran ekip, **ekip enerjisini boşa harcıyor**.

---

## 🎯 Squash Merge ile Birleşim

GitHub squash merge yapıyorsan:
- PR commits dağınık olabilir (`wip`, `fix typo`, vs)
- Squash sonrası tek commit, mesaj = PR title
- ⇒ **PR title konvansiyona uymak zorunda**

Branch protection:
```yaml
required_pull_request_reviews:
  require_code_owner_reviews: true
allow_squash_merge: true
allow_merge_commits: false
allow_rebase_merge: false
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| `fix typo lol` | Bisect'te hangi typo? | `fix(docs): correct deployment.yaml indent` |
| `WIP` 50 commit'te | History okunmaz | Squash + temiz mesaj |
| Type yok: "added feature" | Otomatik tooling kafayı yer | `feat(scope): ...` |
| `BREAKING CHANGE` exclamation yok | Major bump kaçar | `feat!: ...` veya body'de |
| Scope rastgele (`payments`, `payment`, `pay`) | Filter kırık | Standardize scope listesi |
| Body yok, complex change | 1 yıl sonra niye anlaşılmaz | "Niye?" body'de açıkla |
| Türkçe + İngilizce karışık | Tutarsız | Tek dil seç (genelde EN) |
| Issue link yok | Kontekst kayıp | `Closes: #123` footer |
| `chore: update` (ne update?) | Anlamsız | `chore(deps): bump react 18.2 → 18.3` |
| `style: refactor logic` | Type yanlış (style = format) | `refactor: extract helper` |
| Multi-purpose commit | Bisect zor | Atomic, tek konu |
| 200 karakter title | Diff view'da kırpılır | Title 50, detay body |

---

## 📋 Conventional Commits Adoption Checklist

```
[ ] Type listesi takım dokümanında
[ ] Scope listesi standardize
[ ] commitlint pre-commit hook (lokal)
[ ] PR title CI check (semantic-pull-request action)
[ ] Squash merge enforce (linear history)
[ ] release-please veya changesets kurulu
[ ] CHANGELOG.md otomatik üretiliyor
[ ] BREAKING CHANGE'ler clearly işaretli
[ ] Onboarding dokümanında: "ilk PR'ında format"
[ ] Quarterly: type/scope kullanım analizi
```

---

## 📚 Referanslar

- **Conventional Commits 1.0** — conventionalcommits.org
- **Semantic Versioning 2.0** — semver.org
- **release-please** — github.com/googleapis/release-please
- **changesets** — github.com/changesets/changesets
- **commitlint** — commitlint.js.org
- [`Trunk-Based-Development.md`](Trunk-Based-Development.md)
- [`Code-Review-Checklist.md`](Code-Review-Checklist.md)

---

> *"Conventional Commits 'kuralcı bürokrasi' değil, **otomasyonun
> ön koşulu**. Bir günün sonunda ne kadar değer üretildiğini cevaplayan
> CHANGELOG'un, bu kuralların çıktısıdır."*
