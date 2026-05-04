# 01 · Git Workflow

> *"Branch'lerin yaşam süresi, bug'ların yaşam süresine eşittir."*

Modern, hızlı geliştirme akışı için branching stratejisi, commit
disiplinleri ve code review pratikleri.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`Trunk-Based-Development.md`](Trunk-Based-Development.md) | Niye Git Flow değil; trunk-based + feature flag akışı |
| [`Conventional-Commits.md`](Conventional-Commits.md) | `feat:`, `fix:`, `chore:` kanonik kullanım + otomatik changelog |
| [`Code-Review-Checklist.md`](Code-Review-Checklist.md) | İyi review nasıl yapılır; "nit/blocker/question" kategori sistemi |
| _`Stacked-Diffs.md`_ *(yakında)* | Graphite/sapling akışı: küçük PR stack'leri |
| [`PR-Templates-and-Automation.md`](PR-Templates-and-Automation.md) | PR template, otomatik label, semantic-pr-action |

## Önerilen 2026 stack

```
Branch strategy:    Trunk-based (main + kısa-ömürlü feature branch)
Merge strategy:     Squash merge (clean history)
PR signal:          Conventional Commits + Semantic PR titles
Release:            release-please / changesets (otomatik changelog)
Branch protection:  required reviews + status checks + linear history
Stacked diffs:      Graphite (büyük feature'lar için opsiyonel)
```

## Anti-pattern'ler

- ❌ `develop` ve `main` ayrılığı — gereksiz karmaşıklık
- ❌ Uzun-ömürlü `feature/big-rewrite` (3 ay yaşayan branch)
- ❌ Merge commit'lerinin spam'lediği history
- ❌ `WIP fix typo lol` gibi commit mesajları
- ❌ "Bu PR'ı 5 kişi onaylasın" politikası — bottleneck
