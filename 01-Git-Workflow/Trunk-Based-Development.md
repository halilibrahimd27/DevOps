# Trunk-Based Development — Hızın ve Güvenliğin Buluştuğu Yer

> *"Branch'iniz 3 gün yaşıyorsa kötü; 3 hafta yaşıyorsa felaket;
> 3 ay yaşıyorsa **artık kod tabanınız değil**, paralel evren."*

Bu rehber Git Flow'u niye unutmanız, trunk-based development'i niye
benimsemeniz, ve bunu **feature flag + güvenli prod deploy** ile nasıl
yapacağınızı anlatır.

---

## 🎯 Trunk-Based Development Nedir?

```
main (trunk)  ─●───●───●───●───●───●───●───●───●─→
                  ↑       ↑       ↑       ↑
              feat-a   fix-b   feat-c   feat-d
              (1 gün)  (4 saat)(2 gün) (5 saat)
```

**Tek kural:** Tüm geliştirme `main`'in çok yakınında olur. Feature
branch'ler **kısa-ömürlü** (1-2 gün max).

---

## 🆚 Git Flow vs Trunk-Based

| Boyut | **Git Flow** (2010) | **Trunk-Based** (2026) |
|---|---|---|
| Branch sayısı | `main`, `develop`, `feature/*`, `release/*`, `hotfix/*` | `main` + kısa `feature/*` |
| Feature branch ömrü | Haftalar / aylar | 1-2 gün max |
| Merge frekansı | Sprint sonu | Saatte birden fazla |
| Release | Manuel, develop → release → main | Her merge prod-ready |
| Conflict yönetimi | "Big bang" sürpriz merge'leri | Sürekli, küçük conflict |
| CI/CD | Yavaş (büyük PR'lar) | Hızlı (küçük PR'lar) |
| Üretkenlik (DORA) | Düşük (lead time uzun) | Yüksek (deploy frekansı) |
| Rollback | Karmaşık (cherry-pick) | Tek revert commit |

> 🔑 **Veri:** DORA State of DevOps raporları 10 yıl üst üste söylüyor:
> Yüksek-performanslı ekipler **kısa ömürlü branch + günde birkaç deploy**
> yapıyor. Git Flow bu modele engel.

---

## 🚧 Niye Git Flow Bozuk?

### 1. `develop` branch'i + `main` ayrımı yapay
- `main` = "production'da olan", `develop` = "sıradaki release"
- Pratikte `develop` her zaman ileride → "main neyin nesi?" karmaşası
- Hot fix işleyişi: `main` → `hotfix/*` → `main` + cherry-pick `develop` → 3 yerde aynı kod

### 2. Release branch'i = "deploy için zaman tüneli"
- `release/v1.4` 3 hafta açık → bug fix oraya merge → main'e cherry-pick
- 3 hafta içinde develop'tan sürükleme → conflict cehennemi

### 3. Uzun feature branch = entegrasyon şoku
- 3 hafta solo geliştirme → merge günü 200 dosya conflict
- Reviewer "ne yapılmış burada anlamıyorum" → kabuk review
- Test pyramid kırık çünkü integration sürpriz

### 4. CI/CD ile uyumsuz
- "Continuous integration" = her gün integrate. Git Flow = 2 haftada bir.

---

## ✅ Trunk-Based Stack

### Gereken araçlar
1. **Branch protection** — `main` direct push yok
2. **Required CI** — test/lint/scan yeşil olmadan merge yok
3. **Required reviews** — 1 reviewer (2 değil — bottleneck)
4. **Squash merge** — clean history
5. **Feature flags** — yarım feature'ı prod'da kapalı tut
6. **Automated deploy** — main → staging → prod (gated)

### Bir günün akışı
```
09:00  git checkout main && git pull
09:05  git checkout -b feat/add-pagination
09:10  ... kod yaz, test yaz ...
11:00  git push -u origin feat/add-pagination
11:05  PR aç (template otomatik dolar)
11:10  CI yeşil (3 dk)
11:15  Reviewer bakıyor
11:30  Approve + comment
11:35  Squash merge → main
11:40  CI build + deploy to staging
12:00  Smoke test geçti → prod'a otomatik canary
12:15  Canary metrics yeşil → full prod rollout
```

> Bu akış **9-12** arası bir feature shipping. Git Flow'da 2 haftalık iş.

---

## 🚦 Feature Flag: Trunk-Based'in Olmazsa Olmazı

> "Branch ile değil, **flag** ile feature'ı saklarız."

### Niye?
- Yarım feature'ı `main`'e merge etmek için **flag arkasında** kapatabilmek
- Production'da feature'ı **canlı** açıp kapatmak (incident'ta off)
- A/B test, canary release
- "Dark launch" — kullanıcı görmeden prod'a çıkar, telemetry topla

### Flag türleri
| Tip | Yaşam | Örnek |
|---|---|---|
| **Release flag** | Hafta-ay (sonra silinir) | "Yeni checkout flow" |
| **Experiment flag** | Hafta (A/B sonucu silinir) | "Discount %10 vs %15" |
| **Permission flag** | Sürekli | "Premium kullanıcı feature'ı" |
| **Ops flag** | Sürekli | "Retry 3x off (incident anı)" |

### Stack önerileri (2026)

| Tool | Tip | Niche |
|---|---|---|
| **LaunchDarkly** | SaaS | Enterprise, zengin UI |
| **Flagsmith** | Self-host + SaaS | OSS, daha düşük maliyet |
| **GrowthBook** | Self-host + SaaS | A/B test odaklı, OSS |
| **Unleash** | Self-host + SaaS | Norveç tabanlı, OSS, GitOps friendly |
| **OpenFeature** | Standard (vendor-neutral) | Soyutlama: SDK + provider |
| **ConfigCat** | SaaS | Küçük takım, ucuz |

### Kod örneği (Go + OpenFeature)
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

### Flag hijyeni
- Her flag'in **owner** + **expiry tarihi** var
- Quarterly: silinmesi gereken flag'leri otomatik raporla
- "Permanent" sayılabilen flag = artık feature flag değil, configuration → kalıcı yer

---

## 🔀 Branching Cookbook

### Feature: 1-2 günlük
```bash
git checkout main && git pull
git checkout -b feat/<short-desc>
# kodla, commit'le, push'la
gh pr create --fill
```

### Hot fix: prod'da bug var
```bash
git checkout main && git pull
git checkout -b fix/<short-desc>
# minimal fix
gh pr create --label hotfix
# CI yeşil → merge → otomatik prod
```

> ⚠️ **Trunk-based'de hotfix branch'i ayrı yok.** Hızlı PR + auto-deploy zaten o.

### Long-running refactor (mecbur kalırsan)
- ❌ 3 haftalık `feature/big-rewrite` branch
- ✅ Feature flag + her gün küçük PR'lar `main`'e
- ✅ "Strangler fig pattern" — eski + yeni paralel, flag ile geçiş

---

## 🛡️ Branch Protection Ayarları (GitHub)

```yaml
# .github/branch-protection.yaml (Probot kullanıyorsan)
# veya UI: Settings → Branches → main

main:
  required_status_checks:
    strict: true   # PR base ile up-to-date olmalı
    contexts:
      - "ci/lint"
      - "ci/unit-tests"
      - "ci/integration-tests"
      - "security/sast"
      - "security/sca"

  enforce_admins: true   # admin'ler bypass edemez

  required_pull_request_reviews:
    required_approving_review_count: 1
    require_code_owner_reviews: true
    dismiss_stale_reviews: true   # yeni commit → review dismiss

  required_linear_history: true   # squash veya rebase merge

  restrictions: null   # herkes PR açabilir

  allow_force_pushes: false
  allow_deletions: false
```

> 🔑 **`required_approving_review_count: 1`** — daha fazla = bottleneck.
> İki kişiyi gerektiren critical kod için CODEOWNERS ile spot enforce.

---

## ⚙️ CI Hızı: 90 Saniye Kuralı

Trunk-based'in ön koşulu **hızlı CI**. 30 dk CI = trunk-based imkansız.

### Hedef
| Pipeline | Süre |
|---|---|
| Lint + format | < 30s |
| Unit test | < 60s |
| SAST + SCA | < 90s |
| Integration test (PR'da) | < 5 dk |
| E2E (sadece main'de) | < 15 dk |

### Hız kazandırıcılar
- **Parallel matrix** (test sharding)
- **Cache** (npm, pip, go modules, Docker layers)
- **Selective testing** (sadece etkilenen path → tüm test)
- **Test pyramid** (çok unit, az E2E)

Bkz [`02-CI-CD/Pipeline-Patterns.md`](../02-CI-CD/Pipeline-Patterns.md).

---

## 📈 Migration: Git Flow'dan Trunk-Based'e

### 1. Hafta: Branch protection + CI hızlandır
- `main`'e direct push yok
- CI < 5 dakika (gerekirse selective testing)

### 2. Hafta: `develop` branch'i kapat
- `develop` → `main` merge (son senkron)
- `develop` artık archive
- Tüm PR base = `main`

### 3. Hafta: Feature flag stack
- LaunchDarkly / Flagsmith / OpenFeature kur
- İlk büyük feature için flag ile başla

### 4. Hafta: Squash merge zorunlu
- Repository setting: sadece squash merge
- "Allow merge commits" kapalı

### 5. Hafta: Release branch'leri kaldır
- Otomatik changelog (release-please / changesets)
- Tag = main'in bir noktası, artıonk release branch yok

### 6. Hafta: Auto-deploy
- main → staging otomatik
- staging smoke test geçince prod'a canary
- Argo Rollouts veya Flagger ile

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| `develop` + `main` ayrımı | Yapay karmaşıklık | Tek `main` |
| 3 haftalık feature branch | Big-bang merge, conflict | Feature flag + günlük commit |
| `release/v1.4` 2 hafta açık | Cherry-pick cehennemi | Trunk = release-ready |
| Merge commit spam | History anlaşılmaz | Squash merge |
| `WIP fix` commit'leri | Bisect imkansız | Conventional Commits + squash |
| 4 reviewer required | Bottleneck, herkes review yapmıyor | 1 + CODEOWNERS spot |
| CI 25 dakika | Trunk-based imkansız | < 5 dk PR pipeline |
| Feature flag yok | Yarım feature merge edilemez → uzun branch | Flag stack zorunlu |
| Flag asla silinmez | Code paths çoğalır, ölü kod | Quarterly cleanup, expiry |
| `main`'e force-push | History bozulur | Force-push protection |

---

## 📋 Trunk-Based Checklist

```
[ ] main branch protected (force-push, deletion no)
[ ] Direct push yasak; sadece PR
[ ] Required status checks: lint, unit, SAST, SCA
[ ] Required review: 1 (CODEOWNERS spesifik path için)
[ ] Linear history (squash veya rebase merge)
[ ] CI < 5 dakika (PR pipeline)
[ ] Conventional Commits enforce (semantic-pr-action)
[ ] Otomatik changelog (release-please)
[ ] Feature flag stack kurulu (LD/Flagsmith/OpenFeature)
[ ] Flag ownership + expiry (quarterly cleanup)
[ ] Auto-deploy: main → staging → prod (canary'li)
[ ] Rollback: tek `git revert` + auto-deploy
[ ] develop branch yok, release branch yok
[ ] Branch ömrü: P50 < 1 gün, P95 < 3 gün
[ ] Deploy frekansı: günde birden fazla
```

---

## 📚 Referanslar

- **Trunk Based Development site** — trunkbaseddevelopment.com (Paul Hammant)
- **Accelerate** (Forsgren, Humble, Kim) — DORA metrikleri kitap
- **State of DevOps Report** — yıllık DORA
- **Feature Toggles** — Pete Hodgson (Martin Fowler blog)
- _`Conventional-Commits.md`_ *(yakında)*
- [`02-CI-CD/Pipeline-Patterns.md`](../02-CI-CD/Pipeline-Patterns.md)
- _`02-CI-CD/Pipeline-Performance.md`_ *(yakında)*

---

> *"Git Flow, 2010'un release modeli için tasarlandı: 'aylık release, big-bang
> entegrasyon'. 2026'da ekibin günlük deploy edebiliyorsa, **branch'lerin
> günleri sayılı**."*
