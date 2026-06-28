---
description: "RFC, ADR ve Design Doc gibi yazılı iletişim biçimlerinin ne, ne zaman, nasıl yazıldığını ve async toplantısız karar kültürünü anlatan rehber."
tags:
  - Soft Skills
  - Culture
  - Template
  - Career
---
# Documentation as Communication — RFC, ADR, Design Doc

> *"Toplantı yapmak 5 kişinin 1 saatini götürür. **5 sayfalık RFC**
> aynı kararı async, audit'li, geleceğe miras bırakarak yapar.
> Yazma kültürü, **toplantı kültürünün ilacıdır**."*

Bu rehber RFC, ADR ve Design Doc gibi yazılı iletişim biçimlerinin
**ne, ne zaman, nasıl** yazıldığını, async karar kültürünü, ve
**toplantısız ekibin** disiplin gereksinimini anlatır.

---

## 🎯 Async Yazı Kültürünün Değeri

### Toplantı kültürü
- 5 kişi × 1 saat = 5 saat insan kaynağı
- Notlar gevşek, karar belirsiz
- "Ben bu toplantıda yoktum" ekleştirici
- 6 ay sonra "niye böyle?" cevabı yok

### Yazı kültürü
- 1 saatlik yazı + 5 kişi × 30 dk okuma + 30 dk tartışma = 4 saat
- Karar **dokumante** + audit
- Yeni mühendis "niye?" cevabını **bulur**
- Geleceğe miras

> 🔑 **Yazı = leverage.** Bir kez yaz, sonsuz kez okun.

---

## 📋 Üç Format

| Format | Niche | Yaşam |
|---|---|---|
| **RFC** (Request for Comments) | Yeni özellik / mimari öneri | Karar verilene kadar açık |
| **ADR** (Architecture Decision Record) | Yapılmış mimari kararı kayıt | Sonsuz (history) |
| **Design Doc** | İmplementasyon planı | Implementation süresince |

### Tipik akış
```
[Fikir]
   │
   ▼
[RFC]  ─── tartışma + iterasyon ─── [Decision]
                                       │
                                       ▼
                                    [ADR]   ← kayda al
                                       │
                                       ▼
                                  [Design Doc] ← detaylı implementasyon
                                       │
                                       ▼
                                    [Build]
```

---

## 📝 RFC — Yeni Öneri

### Ne zaman RFC?
- 1 ay+ iş gerektirir
- 3+ ekip etkilenir
- Geri dönüşü zor (mimari karar)
- Bütçe yatırımı (>$X)
- Geçmişte tartışılmış, yeniden açılıyor
- Cross-team API kontrat değişikliği

### RFC şablonu
```markdown
# RFC: <BAŞLIK>
**Status:** Draft / Review / Accepted / Rejected / Superseded by RFC-X  
**Author:** @<KULLANICI>  
**Reviewers:** @<KULLANICI>, ...  
**Date:** YYYY-MM-DD  
**Decision deadline:** YYYY-MM-DD

## TL;DR (3 cümle)
<Karar, motivasyon, etki.>

## 1. Problem
<Niye burada konuşuyoruz? Veri ile destekle.>

## 2. Goals & Non-Goals
**Goals:**
- ...
**Non-goals:**
- ... (scope dışı; tartışma engelle)

## 3. Proposal
<Önerilen yaklaşım. Diagram + akış.>

## 4. Alternatives Considered
- A: ... (pro/con, niye değil)
- B: ... (pro/con, niye değil)
- Selected: ... (gerekçe)

## 5. Detailed Design
<Mimari, sequence diagram, API spec, data model.>

## 6. Trade-offs
- Pro: ...
- Con: ...

## 7. Risks & Mitigations
| Risk | Likelihood | Impact | Mitigation |

## 8. Cost Estimate
<Yatırım: kişi/saat, $, maintenance>

## 9. Success Criteria
<Bu RFC başarılı mı nasıl bilirsek?>
- Metric 1: ...
- Metric 2: ...

## 10. Timeline
<Aşamalar + tahmini tarih>

## 11. Open Questions
<Cevabını bilmediğin sorular — review'da çözülecek>

## 12. References
<İlgili RFC'ler, blog post'lar, paper'lar>
```

### RFC review akışı
1. **Draft** — author, kapalı yazılır
2. **Review** — paydaşlar yorum (1 hafta)
3. **Decide** — toplantı + karar (30 dakika max)
4. **Accepted / Rejected / Modified** — yazılı sonuç
5. **ADR** olarak arşivlenir

> 🔑 **Toplantı'sız RFC olur**, **kararsız RFC olmaz**.

---

## 🏛️ ADR — Mimari Karar Kaydı

> RFC kabul edilince **ADR** olur — kalıcı kayıt.

### ADR şablonu (lightweight)
```markdown
# ADR-007: Service mesh adoption — Linkerd

**Date:** 2026-04-15  
**Status:** Accepted  
**Deciders:** @platform-team  
**Supersedes:** -  
**Superseded by:** -

## Context
Production'da microservice'ler arası mTLS, observability, retry
gerekiyor. Her servis library ile çözmek tekrar.

## Decision
Linkerd kullanacağız (sidecar mode, K8s 1.27+).

## Consequences
**Pozitif:**
- mTLS otomatik
- Observability bedava (Linkerd Viz)
- Düşük öğrenme eğrisi

**Negatif:**
- Pod başına ~10 MB sidecar overhead
- Linkerd-specific debug bilgisi gerekli
- Cilium service mesh alternative'i değerlendirildi → Cilium henüz GA değil

## Alternatives Considered
- Istio: çok karmaşık, sidecar overhead 50 MB
- Cilium SM: 2026'da henüz incubating
- App-side library: maintenance burden

## Related
- RFC-014: Service mesh evaluation
- ADR-005: Kubernetes 1.27 upgrade
```

### ADR repo yapısı
```
adr/
├── 0001-record-architecture-decisions.md
├── 0002-use-postgresql-for-primary-storage.md
├── 0003-adopt-trunk-based-development.md
├── 0004-use-argo-cd-for-gitops.md
├── 0005-kubernetes-1.27-upgrade.md
├── 0006-shift-from-helm-to-kustomize.md
└── 0007-service-mesh-adoption-linkerd.md
```

### ADR yaşam
- **Accepted**: aktif uygulanıyor
- **Deprecated**: yeni karar superseded etti
- **Superseded by ADR-X**: replaced

> 🔑 **ADR silmez, superseded eder.** History korunur.

---

## 📐 Design Doc — Implementation Plan

> RFC "ne yapmalıyız?" — Design Doc "nasıl yapacağız?"

### Şablon
```markdown
# Design Doc: <FEATURE_NAME>
**RFC:** RFC-014  
**Author:** @<KULLANICI>  
**Status:** Draft / Review / In Progress / Done  
**Last updated:** YYYY-MM-DD

## Overview
<Bir paragraf: ne yapacağız.>

## Architecture
<Diagram: components, data flow, dependencies.>

## API Spec
```yaml
openapi: 3.0
paths:
  /v2/users:
    post:
      ...
```

## Data Model
```sql
CREATE TABLE users_v2 (
  ...
);
```

## Migration Plan
<Mevcut sistemi nasıl yeni'ye getireceğiz, expand/contract>

## Testing Strategy
- Unit
- Integration
- E2E
- Load test

## Rollout Plan
- Stage 1: dev → smoke
- Stage 2: staging → load test
- Stage 3: prod canary %5 → %50 → %100

## Rollback Plan
<Hata olursa nasıl geri alırız.>

## Observability
- Metrics: ...
- Logs: ...
- Traces: ...
- Alerts: ...

## Security Considerations
<Threat model summary, AuthN/AuthZ, sensitive data.>

## Open Questions
<Implementation sırasında çözülecek.>

## Timeline & Milestones
- M1: ...
- M2: ...
- M3: GA
```

---

## 🎨 İyi Yazı Pratikleri

### 1. **TL;DR sun**
İlk 3 cümle = ana fikir. Geri kalan detay.

### 2. **"Niye?" yaz**
"Ne" yapacağını anlatmak kolay. **Niye** yapacağını yazmadıysan, gelecek mühendis "şu an iyi gidiyor, geri çekelim" diyebilir.

### 3. **Diagram zorunlu**
Mermaid yeter:
```
flowchart LR
  User --> LB[Load Balancer] --> API
  API --> DB[(PostgreSQL)]
  API --> Cache[(Redis)]
```

### 4. **Alternatif değerlendir**
"Tek doğru cevap" yazma — **birkaç seçenek** + niye seçileni göster.

### 5. **Maliyet + risk**
"Dokunmazsak 6 ay sonra şu olur. Yaparsak 4 hafta + $X."

### 6. **Open Questions**
Bilmediğini gizleme — **soru olarak yaz**. Review'da cevaplanır.

### 7. **Görsel gücü**
Tablolar > paragraflar. Kod örneği > soyut açıklama.

---

## 🚦 Yazma Disiplinine Geçiş

### Eski (toplantı kültürü) → Yeni (yazı kültürü)
| Değişim | Pratik |
|---|---|
| "Bunu konuşalım" → | "RFC yazıp paylaşıyorum" |
| Standup'ta karar | RFC + 1 hafta review |
| Whiteboard fotoğrafı | Mermaid diagram |
| Slack thread'inde tartışma | RFC comment |
| 1-1'de karar verildi → | "1-1 notes + ADR" |

### Manager olarak teşvik
- "Bu konu RFC değer mi?" diye sorma alışkanlığı
- RFC yazana takdir
- Yeni mühendis on-boarding: "İlk ayda bir RFC yaz"
- Templated tooling (örn: GitHub issue template'i RFC için)

---

## 🛠️ Tooling

### Repo'da
```
docs/
├── rfcs/                  # numaralandırılmış: RFC-001, RFC-002
│   ├── 0001-template.md
│   ├── 0002-trunk-based.md
│   └── 0003-service-mesh.md
├── adrs/
│   ├── 0001-template.md
│   └── ...
└── design-docs/
    └── ...
```

### GitHub
- RFC için **issue template** (`.github/ISSUE_TEMPLATE/rfc.md`)
- PR ile review (line-by-line comment)
- Discussion'lar (RFC yorumları için)

### Notion / Confluence
- Kuruluyorsa OK ama **kod ile senkron değil** → eskir
- Tercih: **markdown + Git** (TechDocs ile Backstage'de render)

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| RFC yok, "Slack'te tartışalım" | Karar audit yok | Spesifik konu için RFC |
| RFC çok uzun (50+ sayfa) | Kimse okumaz | TL;DR + max 5-10 sayfa |
| RFC yazıp toplantı yapmama | Soru cevapsız | 1 hafta review + 30 dk decide meeting |
| ADR sıfır | Mimari kararlar unutulur | Her major karar ADR |
| ADR superseded yerine sil | History kayıp | Superseded by ile bağla |
| Design doc impl başlamadan yok | "İlerledikçe planlarız" | Önce yaz, sonra build |
| Diagram yok, paragraf | Anlaşılmaz | Mermaid + tablo |
| Open Questions yok ("hepsini biliyorum") | Review faydası kayıp | Bilinçli soru sor |
| RFC author tek başına decide | Diğerleri katılmadığını hisseder | Reviewer onayı gerekli |
| 6 ay önceki RFC update değil | Mimari değişti, RFC eski | "Superseded by" güncelleme |
| Yazma alışkanlığı manager'da yok | Kültür değişmez | Manager kendi RFC'sini yaz, örnek ol |

---

## 📋 Yazılı İletişim Disiplin Checklist

```
[ ] RFC şablonu repo'da
[ ] ADR şablonu repo'da
[ ] Design doc şablonu repo'da
[ ] RFC numaralandırma sistemi (örn: RFC-001, RFC-002)
[ ] GitHub issue template (RFC açma)
[ ] CODEOWNERS docs/rfcs/ için review otomatik
[ ] RFC review akışı: draft → review (1 hafta) → decide → ADR
[ ] Mermaid / draw.io diagram standardı
[ ] Yeni mühendis on-boarding: önceki RFC'leri oku
[ ] Manager 1:1'de "RFC yazdın mı?" alışkanlığı
[ ] Major karar = ADR zorunlu
[ ] Quarterly: RFC retrospective (kararların etkileri ne oldu?)
[ ] Public-facing API: RFC zorunlu
[ ] Cross-team etki: RFC zorunlu
```

---

## 📚 Referanslar

- **Architectural Decision Records** — adr.github.io
- **Google Design Doc Template** — google.com/site/sitezilla/design-doc-template (community-shared)
- **Stripe Engineering Blog — RFCs at Stripe**
- **Squarespace Engineering — How we write design docs**
- **Will Larson — How to write a design doc** (Staff Engineer'da bölüm)
- [`Stakeholder-Management.md`](Stakeholder-Management.md)
- [`Postmortem-Conversation.md`](Postmortem-Conversation.md)
- [`Saying-No.md`](Saying-No.md) — RFC reddi
- [`01-Git-Workflow/Code-Review-Checklist.md`](../01-Git-Workflow/Code-Review-Checklist.md) — review kültürü

---

> *"Yazılı kültür **disiplin** ister — async iletişim **kolaysız**.
> Ama bir kez kurulduğunda toplantı sayısı yarıya düşer, karar
> kalitesi iki katına çıkar, **6 ay sonra gelen yeni mühendis**
> kendi başına anlayabilir hale gelir."*
