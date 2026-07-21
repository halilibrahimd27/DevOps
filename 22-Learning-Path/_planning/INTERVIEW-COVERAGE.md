# INTERVIEW-COVERAGE — Mid-seviye soru × A–E modül eşlemesi

> **Faz 4 çıktı kapısı (BUILD-PROMPT §10).** `18-Career/DevOps-Interview-Questions.md`
> içindeki her **mid-level (🟡, 2-5 yıl)** sorusu en az bir A–E modülüyle eşleşmeli.
> Eşleşmeyen → ya modül eklenir ya soru F'ye taşınır. Bu dosya o denetimi kaydeder.

**Kapsam:** Sorular 11–25 (mid-level bloğu). Junior (1–10) A/B/C temelleriyle,
Senior (26–40) ve Staff+ çoğunlukla **F bloğu**yla (karar/tasarım) eşleşir — kapı yalnız
mid-level'ı zorunlu tutar, o yüzden tablo 11–25'e odaklanır.

---

## Mid-level eşleme tablosu

| # | Soru (özet) | Birincil modül | Destek modül |
|---|---|---|---|
| 11 | Pod `Pending` → debug | D1 (k8s temel) | D2, B3 (sistematik teşhis) |
| 12 | Prod'da `kubectl edit` yapılır mı | D5 (GitOps/drift) | D1 |
| 13 | Bir servisin SLO'sunu tasarla | **E1** | B2 (metrik) |
| 14 | Zero-downtime deploy | D2 (rolling/probe) | E4 (expand/contract migration) |
| 15 | Terraform state yönetimi | C3 (Terraform) | — |
| 16 | Container imajını küçült | C1 (container) | — |
| 17 | CI pipeline'ı hızlandır | C2 (CI) | — |
| 18 | Prod DB schema migration | E4 (zero-downtime migration) | D2 |
| 19 | p99 latency fırladı — ilk 5 dk | E2 (alerting) + E3 (incident) | B2 (metrik), E1 |
| 20 | Helm vs Kustomize trade-off | D5 (Helm-vs-Kustomize kaynağı) | D1 |
| 21 | PostgreSQL prod yedek | **E4 (restore)** | — |
| 22 | NetworkPolicy tasarımı | D1 (RBAC+NetworkPolicy ilk günden) | D3 |
| 23 | Secret yönetimi (Vault yok) | D3 (secret) | D4 |
| 24 | İmaj imzalama niye/nasıl | D4 (supply chain) | C2 |
| 25 | Linux process %200 CPU — kim | A1 (Linux process) | B3 (arıza bulma) |

**Sonuç:** 15/15 mid-level soru en az bir A–E modülüne izleniyor. **Eşleşmeyen yok →
F'ye taşınan soru yok, eklenmesi gereken modül yok.** Kapı geçildi.

---

## Notlar

- **Soru 19** iki modüle böler: ilk tepki/triyaj E2–E3'te, "neyi ölçerim" B2'de. Her ikisi
  de A–E içinde → kapı sağlanıyor.
- **Soru 14 ve 18** DB tarafını E4'e (zero-downtime migration + restore), uygulama tarafını
  D2'ye bağlar. Güvenlik ipliği: E4 backup erişim/şifreleme kabul kriterinde içeride.
- **Soru 25** Linux process teşhisi A1'de temellenir; `pidstat`/`perf` derinliği repo içi
  `16-Cheatsheets/linux-troubleshooting.md`'de (B blokunun okuma kaynağı). Mülakat cevabı
  için A1 + B görünürlük yeterli.
- **Senior/Staff+ (26–40)** çoğunlukla Blok F kapsamındadır (multi-region, platform,
  FinOps, strateji). Bunlar Faz 7'de F modülleriyle eşlenecek — bu kapının konusu değil.

---

> *"Bir müfredat, mezununun karşılaşacağı soruları karşılamıyorsa müfredat değil, dilek listesidir."*
