---
description: "Right-sized, role-targeted dokümantasyon kültürü: 4 katmanlı hiyerarşi (README, RFC, ADR, runbook) ve doc rotting'e karşı pratik stratejiler."
tags:
  - Culture
  - Soft Skills
  - Platform Engineering
---

# Documentation Culture

> *"Dokümante etmediğin sistem, sadece sen anlıyor; bus factor 1; sen
> ayrılırsan, gizli bilgi gider."*
>
> *"Aşırı dokümante ettiğin sistem, kimse okumuyor; doc rotting; gerçek
> davranış ile yazı arasında drift büyür."*

İkisinin arası — **right-sized, role-targeted documentation** — gerçek
sanat.

---

## 📐 4-Tier Hierarchy

### Tier 1: README (her repo'nun)

> "Bu repo ne yapar? Nasıl başlarım?" 5 dakikada cevap.

Olması gerekenler:
- 1 cümlelik özet
- Ne işe yarar (use case)
- Quick start (3-5 komut)
- Architecture diagram (high-level)
- "Where to go next" linkleri

**Olmaması gerekenler:**
- Yüzlerce satır API docs (ayrı yere)
- Internal team-only details

### Tier 2: ADR (Architecture Decision Record)

> Önemli kararları **niye** aldığımız.

```markdown
# ADR-0042: Postgres yerine Aurora kullanmak

## Status: Accepted (2026-04-15)

## Context
- Production load 5K → 50K RPS bekleniyor
- Cross-region read replica gerek
- Mevcut self-managed Postgres operasyon yükü yüksek

## Decision
Aurora PostgreSQL Global Database'e geçiyoruz.

## Consequences
+ Auto-failover, multi-region read replica yönetimi yok
+ %99.99 SLA built-in
- Cost +%30
- Aurora-specific features (vendor lock)
- Major version upgrade kontrolümüzde değil

## Alternatives Considered
- Self-managed PostgreSQL with Patroni: ops yükü reddedildi
- CockroachDB: ekip aşinalık yok, migration risk yüksek
- Cloud SQL (GCP): mevcut altyapı AWS, multi-cloud zorlaştırır
```

**ADR'lar:**
- Numaralı (0001, 0002, ...)
- Immutable — yeni karar gerekirse yeni ADR (önceki "Superseded")
- Repo'da `docs/adr/` altında
- 1 sayfayı geçmesin

> 📚 [adr-tools](https://github.com/npryce/adr-tools), [Markdown Architectural Decision Records](https://adr.github.io/madr/)

### Tier 3: RFC (Request for Comments)

> Önemli yeni öneri'ler için **review öncesi** belge.

- ADR'dan **daha geniş**, kararsız, draft hali
- 5-15 sayfa
- Stakeholder feedback için 2 hafta açık
- Sonunda → ADR'a dönüşür ya da reddedilir

```markdown
# RFC-0017: API rate limiting v2

## Author: @author
## Reviewers: @reviewer1, @reviewer2
## Status: Draft / Review / Accepted / Rejected
## Deadline: 2026-05-15

## Summary
2 cümle.

## Motivation
Sorun ne, niye çözüyoruz.

## Detailed Design
Mimari, API, UI mockups, code samples.

## Trade-offs
Hangi alternatifleri düşündük, niye bu.

## Open Questions
Yanıt bekleyen sorular.

## Migration Plan
Mevcut sistemden geçiş.
```

### Tier 4: Runbook + Postmortem

> "İncident anında ne yap" / "İncident sonrası ne öğrendik".

> Template'ler: [`17-Templates/runbooks/`](../17-Templates/runbooks/)

---

## 🎯 Audience-First yaklaşım

Aynı bilginin farklı versiyonu:

| Doc tipi | Audience | Ne içerir |
|---|---|---|
| README | Yeni gelen mühendis | "Nasıl çalıştırırım" |
| Architecture | Senior + new starter | "Sistemin parçaları nasıl konuşur" |
| Runbook | On-call | "Bu alert geldiğinde ne yap" |
| ADR | Senior, future you | "Niye böyle karar aldık" |
| API docs | API tüketicisi | "Bu endpoint ne dönüyor" |
| Tutorial | Learner | "Adım adım nasıl yapılır" |
| Reference | Power user | "Tüm parametreler" |

> Diátaxis framework — 4 doc türü ayrı tutulmalı: tutorial, how-to, reference, explanation. Karıştırma.

---

## 🛡️ "Doc rotting"e karşı stratejiler

### 1. Code-as-doc (en çok)
```python
def calculate_tax(amount: Decimal, region: str) -> Decimal:
    """
    Mevcut bölge için KDV hesaplar.

    Trade-off: TR için %20 sabit, AB için region-spesifik tablo.
    AB tablosu 2026-Q1'den itibaren mongo'da; rate'ler statik değil.

    Args:
        amount: Brüt tutar
        region: ISO country code (örn: "TR", "DE")
    """
```

> İyi yazılmış kod = en çok güncel doc'tur.

### 2. Test-as-doc
```python
def test_checkout_handles_concurrent_clicks():
    """
    Kullanıcı checkout'a tıklarken double-click yaparsa,
    sadece 1 sipariş oluşmalı (idempotency key).
    """
    # ...
```

### 3. CI'da link checker
```yaml
- uses: lycheeverse/lychee-action@v1
  with:
    args: --verbose --no-progress './**/*.md'
```

### 4. "Last updated" zorunlu
Her doc'un başında:
```yaml
---
last-reviewed: 2026-04-30
owner: @platform-team
review-frequency: quarterly
---
```

CI'da "6 aydır review olmamış" warning.

### 5. Sahiplik (CODEOWNERS)
```
# .github/CODEOWNERS
docs/architecture/    @platform-team
docs/runbooks/        @sre-team
docs/api/             @api-team
```

### 6. "Decommission ya da düzelt" reviewly
Yılda bir audit. Her doc:
- Hâlâ relevant mi? → güncel hale getir
- Değil mi? → sil

> Stale doc, no doc'tan **kötüdür**. Yanıltır.

---

## 📚 Tooling

### Statik
- **Markdown** in repo — search'lenebilir, version-controlled
- **MkDocs / Docusaurus / Hugo** — markdown'dan static site
- **Backstage TechDocs** — service-attached docs
- **Read the Docs** — auto-deploy

### Dinamik
- **Confluence / Notion** — meeting notes, brainstorm
- **Slack** — anlık iletişim (asla doc kaynağı olarak kullanma)

### Diagrama
- **Mermaid** — markdown native, GitHub render'lı
- **PlantUML** — kod-as-diagram, version control
- **Excalidraw** — quick sketch
- **Lucidchart / Miro** — collaborative

> Karar: docs **Git'te**, meeting notes Notion/Confluence'da. Ayrı tut.

---

## ✨ İyi doc yazma kuralları

1. **Bir-cümlelik özet ile başla** — okur ihtiyacı var mı 5 sn'de anlasın
2. **Active voice** ("API token oluşturursun" vs "API token oluşturulmalıdır")
3. **Code blocks tested** — komut çalışıyor mu?
4. **Placeholder'lar `<UPPER_CASE>`** — gerçek değer kullanma
5. **Diagram > 300 satır metin** — uygunsa
6. **Linkler relative** — repo taşınınca kırılmasın
7. **Recently-updated date** belirgin yerde
8. **Examples > abstract definitions**

---

## 🚫 Anti-pattern'ler

| Anti-pattern | Neden kötü |
|---|---|
| "TODO: ileride doldurulacak" | Asla doldurulmaz |
| Auto-generated reference (sadece signature) | Audience yok, faydasız |
| Wiki'de saklı doc | Search'lenmez, lost knowledge |
| Word doc / PDF | Versiyonlanmaz, diff yok |
| 50-sayfa "comprehensive" guide | Kimse okumaz, parçala |
| Doc PR review etmemek | Doc kalitesi kontrol dışı |
| Slack thread olarak yapışmış "doc" | Aranabilir değil, kaybolur |
| Personal yazı tarzı (ego) | Maintainability düşürür |

---

## 🎓 Doc-as-code principles

- ✅ Doc, repo'da kod ile birlikte yaşar
- ✅ Doc PR review'dan geçer (yazım, anlam)
- ✅ Doc CI'da test edilir (link, syntax, formatting)
- ✅ Doc, code change ile aynı PR'da güncellenir (yoksa PR rejected)
- ✅ Doc'un bir owner'ı vardır (`CODEOWNERS`)
- ✅ Stale doc CI uyarısı verir

---

## 📋 Checklist

Bir doc'u "production-ready" saymadan önce:

- [ ] Her repo'da Tier-1 README var — özet + quick start + architecture link 5 dakikada anlaşılıyor
- [ ] Önemli mimari kararlar numaralı ADR'da (`docs/adr/`), 1 sayfayı geçmiyor, immutable
- [ ] Doc başında `last-reviewed` + `owner` + `review-frequency` frontmatter'ı dolu
- [ ] `CODEOWNERS`'ta doc dizinlerinin sahibi tanımlı (orphan doc yok)
- [ ] CI'da link checker (lychee vb.) çalışıyor — kırık link PR'ı bloke ediyor
- [ ] CI'da "6 aydır review olmamış" / stale doc uyarısı aktif
- [ ] Code change ile doc aynı PR'da güncelleniyor (drift'e karşı PR kuralı)
- [ ] Tüm code block'lar test edildi — komutlar gerçekten çalışıyor
- [ ] Placeholder'lar `<UPPER_CASE>` formatında, gerçek IP/domain/credential yok
- [ ] Linkler relative — repo taşınınca kırılmıyor
- [ ] Diátaxis ayrımı korunmuş — tutorial / how-to / reference / explanation karışmamış
- [ ] On-call için runbook + incident sonrası postmortem template'i mevcut
- [ ] Doc Git'te (markdown), meeting notes Notion/Confluence'da — kaynak doc Slack thread değil
- [ ] Audit'te "decommission ya da düzelt" geçti — stale doc silindi

---

## 📚 Devamı

- [Diátaxis framework](https://diataxis.fr) — 4 doc türü
- [Architecture Decision Records (ADR) on GitHub](https://adr.github.io/)
- [Google Technical Writing courses](https://developers.google.com/tech-writing) — ücretsiz
- [Write the Docs community](https://www.writethedocs.org)
- [`17-Templates/runbooks/`](../17-Templates/runbooks/) — runbook + postmortem template
