---
description: "Stacked diffs pattern: büyük feature'ı küçük ve gerçekten review edilebilir PR'lara bölme; Graphite, Sapling veya manuel branch chain ile araç ve workflow."
---
# Stacked Diffs — Büyük Feature'ı Küçük PR'lara Bölme

> *"3000 satırlık PR'ı 'review et' demek, mühendisin **gözünü
> kapatıp 'LGTM'** yazmasını istemektir. Stacked diffs aynı feature'ı
> 6 küçük PR'a böler — **gerçek review** olur."*

Bu rehber **stacked diffs** pattern'ini — Graphite, Sapling, ya da
manuel branch chain — somut araçlar ve workflow ile anlatır.

---

## 🎯 Sorun: Büyük PR

```
Geleneksel:
  feature/big-rewrite (3 hafta yaşar)
    ├── 47 commit
    ├── 3000 satır diff
    └── 1 PR
        → reviewer: "anlamadım, LGTM"
```

Sonuç:
- Review yüzeysel
- Bug'lar geç tespit
- Merge conflict cehennem
- Trunk-based ile uyumsuz

---

## ✅ Çözüm: Stacked Diffs

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

Her PR **küçük** (100-300 satır), bağımsız review edilebilir, **ardışık merge**.

---

## 🛠️ Manuel Stacked Diffs (Tool'suz)

### Akış
```bash
# 1. Base branch'ten ilk PR
git checkout main && git pull
git checkout -b feat/refactor-1-extract-helper
# kod yaz
git commit -m "feat: extract helper function"
git push -u origin feat/refactor-1-extract-helper
gh pr create --base main

# 2. İlk PR'ın üzerine ikinci PR
git checkout -b feat/refactor-2-add-validation
# kod yaz
git commit -m "feat: add validation layer"
git push -u origin feat/refactor-2-add-validation
gh pr create --base feat/refactor-1-extract-helper

# 3. Üçüncü PR
git checkout -b feat/refactor-3-new-flow
# ...
gh pr create --base feat/refactor-2-add-validation
```

### Sorun: PR #1 review feedback geldi
```bash
git checkout feat/refactor-1-extract-helper
# fix yap
git commit --amend
git push --force-with-lease

# Şimdi #2 ve #3 base'den behind
git checkout feat/refactor-2-add-validation
git rebase feat/refactor-1-extract-helper
git push --force-with-lease

git checkout feat/refactor-3-new-flow
git rebase feat/refactor-2-add-validation
git push --force-with-lease
```

> ⚠️ **Manuel = ağrı**. 3+ PR stack'te rebase chain çok hata yapar. Tool kullan.

---

## 🛠️ Graphite — Modern Stacked Tool

[Graphite](https://graphite.dev) GitHub üstüne stacked PR workflow ekler.

### Setup
```bash
brew install withgraphite/tap/graphite
gt auth
```

### Akış
```bash
# 1. Yeni stack başlat
gt branch create feat/refactor-1
# kod yaz
gt commit create -m "feat: extract helper"

# 2. Üstüne yeni branch
gt branch create feat/refactor-2
# kod yaz
gt commit create -m "feat: add validation"

# 3. Devam
gt branch create feat/refactor-3

# 4. Hepsini submit (PR'lara)
gt stack submit
```

### Restack (PR #1 değişti, üst PR'lar otomatik update)
```bash
gt branch checkout feat/refactor-1
# fix yap
gt commit amend

# Tüm üst stack otomatik rebase
gt stack restack
gt stack submit
```

### Merge sırası
- PR #1 merge → main
- Graphite otomatik: PR #2 base'i main'e değişir
- PR #2 merge → main
- Devam

---

## 🛠️ Sapling (Meta) — Native Stacked

[Sapling](https://sapling-scm.com) Meta'nın açık kaynak Git replacement'ı:

```bash
# Stack oluştur
sl commit -m "feat: extract helper"
sl commit -m "feat: add validation"
sl commit -m "feat: new flow"

# GitHub PR'lara çevir
sl pr submit
```

> Sapling Git ile uyumlu — repo aynı, sadece CLI farklı.

---

## 🌳 Diğer Tool'lar

| Tool | Notlar |
|---|---|
| **Graphite** | SaaS + CLI, GitHub native |
| **Sapling** | Meta OSS, Git uyumlu |
| **`spr`** (CLI) | Lightweight, opensource |
| **`git stack`** | bash-based plugin |
| **Phabricator** | Eski, Meta'da hâlâ kullanılıyor |
| **Gerrit** | Google ekosistemi |

> 🔑 **2026 önerisi**: GitHub kullanıyorsan **Graphite**. OSS isterseniz **Sapling**.

---

## 🎯 Ne Zaman Stacked Diffs?

### ✅ İyi senaryolar
- Büyük refactor (eski sistem → yeni)
- Multi-step feature (her adım değer üretiyor)
- Migration (database, framework)
- Geniş impact (5+ dosya değişikliği)
- Reviewer'ın anlayabileceği **logical chunk**'lar var

### ❌ Kötü senaryolar
- Tek küçük bug fix (PR yeter)
- Bağımsız feature'lar (paralel branch yeter)
- Çok kişili coğrafi dağılım (rebase çakışması)
- Hızlı prototyping (overhead)

---

## 📐 Stack'i Bölme — Pratik Sanat

### Tek bir feature'ı 4 PR'a bölme örneği:
**Feature**: "User profile sayfasına 2FA ekle"

```
PR #1: schema migration (column ekle)
  - DB: users.totp_secret column eklendi (nullable)
  - Migration script
  - Test: schema validation
  → Bağımsız, geri alınabilir

PR #2: backend totp helper
  - lib/totp.go: generate, verify
  - Unit test
  → Bağımsız, kullanılmıyor henüz

PR #3: API endpoint /v1/users/2fa/setup
  - Endpoint impl (önceki helper kullanır)
  - Auth middleware update
  - Integration test
  → API var ama UI yok, prod'a çıkabilir (feature flag)

PR #4: UI component
  - React component
  - Settings page integration
  - E2E test
  → Tam feature, flag açık
```

> 🔑 Her PR **bağımsız mantıklı** + **prod'a çıkabilir** + **review edilebilir**.

---

## 📋 Stacked Diff Hijyeni

### Her PR boyutu
- **Hedef**: 100-300 satır
- **Max**: 500 satır
- **Ne kadar küçük o kadar iyi review**

### Her PR description
```markdown
## Stack
- #101 [extract helper]   ← bu PR
- #102 add validation
- #103 new flow

## Niye?
<problem>

## Bu PR ne yapar?
<bu specific PR'ın işi>

## Test
- [x] Unit test
- [x] Integration test
```

### Reviewer'a sinyal
```
[Stack 1/4] feat: extract helper function
[Stack 2/4] feat: add validation layer
[Stack 3/4] feat: new auth flow
[Stack 4/4] feat: UI integration
```

→ Reviewer sırayı görür, doğru sırada review eder.

---

## 🚦 Merge Stratejisi

### Bottom-up merge
```
PR #1 merge → main
   ↓
PR #2 base auto-update to main
   ↓ review (zaten yapıldıysa) → merge
   ↓
PR #3 ...
```

### Squash mu rebase mu?
| Strategy | Pro | Con |
|---|---|---|
| **Squash merge** | Clean history (PR = 1 commit) | Stack'in iç yapısı kayıp |
| **Rebase merge** | History detaylı | Bisect zor |
| **Merge commit** | Stack visible | History kirli |

> 🔑 **Çoğu ekip**: squash merge. Stack'in iç yapısı PR description'da kalır.

---

## 🧪 CI ile Etkileşim

### Stack'te her PR için CI çalışmalı
```yaml
# CI sadece base ile merge'i test eder, ama stacked PR'ı doğrulamak için:
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches: [main, 'feat/**']    # stacked PR base'i de feat/* olabilir
```

### Selective testing (büyük stack'te)
- Sadece etkilenen path için test
- Bkz [`02-CI-CD/Pipeline-Performance.md`](../02-CI-CD/Pipeline-Performance.md)

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| 1500 satır PR | Review yüzeysel | Stack'e böl |
| Manuel rebase chain | Hata kaynağı | Graphite / Sapling |
| Bağımsız olmayan PR'lar | Bottom merge edilemez | Her PR self-contained |
| Stack çok derin (10+ PR) | Yönetilmez | Max 5-6 PR |
| Stack'te conflict ihmal | Sonraki PR'lar bozulur | `gt stack restack` düzenli |
| PR description boş, "stack 1/4" yok | Reviewer kafası karışır | Açık etiketleme |
| Stack ortasında force push history rewrite | Reviewer eski yorumu kayıp | `--force-with-lease` |
| Squash + stack uyumsuz | History karmaşık | Squash + iç PR'da detay |
| Tek geliştirici stack çalışıyor | Bus factor 1 | Pair veya 2 reviewer |
| Test'siz PR | Bağımsız bile değil | Her PR'ın testi var |

---

## 📋 Stacked Diff Adoption Checklist

```
[ ] Tool seçimi: Graphite (önerilen) / Sapling / manuel
[ ] CI base branch: feat/* support
[ ] PR template'de "Stack X/Y" alanı
[ ] Squash merge enforce (linear history)
[ ] Branch protection: required CI per PR
[ ] Quarterly: stack metric (avg PR size, lead time)
[ ] Onboarding: yeni mühendis stack akışı
[ ] Documentation: ne zaman stack, ne zaman tek PR
[ ] Stack max derinlik kuralı (örn: max 6)
[ ] Stack üzerinde pair / 2-reviewer
```

---

## 📚 Referanslar

- **Graphite** — graphite.dev
- **Sapling** — sapling-scm.com
- **Phabricator (Stacked Diffs origin)** — phacility.com (deprecated, reference)
- **Will Larson — Stacked Diffs vs PRs**
- [`Trunk-Based-Development.md`](Trunk-Based-Development.md)
- [`Code-Review-Checklist.md`](Code-Review-Checklist.md)
- [`Conventional-Commits.md`](Conventional-Commits.md)

---

> *"Stack'lemek 'bürokrasi' değil — **review kalitesini** korumanın
> tek yolu. Büyük feature'ı tek PR'a sıkıştırmak, **review yapmamak**
> demektir."*
