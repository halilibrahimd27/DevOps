---
description: "Blameless postmortem template: TL;DR, etki metrikleri, UTC zaman çizelgesi, kök neden, savunma katmanları, owner'lı aksiyon maddeleri ve öğrenilen dersler."
tags:
  - Template
  - Incident Response
  - SRE
  - DORA
---
# Postmortem: <INCIDENT TITLE>

> **Status:** Draft / Under Review / Final
> **Date:** YYYY-MM-DD
> **Author:** @author-handle
> **Reviewers:** @reviewer1, @reviewer2

---

## TL;DR (3 cümle)

*(Ne oldu, ne kadar sürdü, etki nasıldı.)*

Örnek: **2026-04-30 14:02–14:16 UTC arasında payment-service kullanılamaz
hale geldi. Kök neden, yeni bir endpoint'te accidental N+1 query'di. 14
dakika boyunca yaklaşık 3.200 ödeme başarısız oldu, ~22k EUR potansiyel
revenue impact tahmin ediliyor.**

## 🎯 Etki

| Metrik | Değer |
|---|---|
| Total downtime | XX dakika |
| Affected users | ~XXX |
| Failed transactions | ~XXX |
| Revenue impact (estimate) | ~XX,XXX EUR |
| SLO impact | Error budget %X yendi |
| Customer complaints | X (zendesk ticket) |

## ⏱️ Zaman çizelgesi (UTC)

> Bu kısım **hassas detaya** sahip olmalı. "Yaklaşık 14:00'te" değil
> "14:02:34" yazın. PagerDuty/Slack timestamp'lerinden alın.

| Zaman | Olay |
|---|---|
| 14:00 | Deploy v3.4.1 başlatıldı (PR #4521 — `<COMMIT_SHA>`) |
| 14:02 | Deploy tamamlandı, %100 prod traffic v3.4.1'de |
| 14:05 | Datadog'da p99 latency 200ms → 8s sıçradı; SLO burn-rate alert firing |
| 14:07 | On-call (@alice) PagerDuty'den page aldı, `#incident-payments` kanalında |
| 14:10 | Incident commander (@alice), comms lead (@bob) atandı |
| 14:11 | Rollback komutu çalıştırıldı (`kubectl rollout undo`) |
| 14:13 | Trafik %50 v3.4.0 / %50 v3.4.1, latency stabilizasyon başladı |
| 14:16 | Rollback tamamlandı, latency normalleşti |
| 14:30 | All-clear, incident kapatıldı |
| 15:00 | Postmortem ticket açıldı |

## 🔍 Kök Neden (Root Cause)

> *Kişi değil, sistemi açıklayın.*

Yeni eklenen `/payments/:id/full-receipt` endpoint'i, ORM'in lazy-loading
özelliğinden ötürü her ödeme için 50 ek SQL query atıyordu (N+1 problemi).
Production'da prod-tier RPS yüküne karşı:
- DB connection pool tükendi
- App connection acquisition timeout (10s)
- Liveness probe fail → pod restart döngüsü

Production'a benzer veri hacmi olmayan staging'de bu pattern manifest
olmadı (staging fixture'ı 10 satır vs prod 50 satır).

## 🛡️ Niye yakalanmadı?

Tek bir failure değil, **savunma katmanlarının** hepsi delik:

1. **Code review** — N+1 pattern PR'da tespit edilmedi (reviewer @charlie ORM lazy-load davranışını bilmiyordu)
2. **Lint/CI** — N+1 detector pipeline'da yok
3. **Load test** — sadece 100 RPS test yapılıyor; N+1 5000 RPS'de patlıyor
4. **Staging** — fixture data hacmi prod'un %0.0001'i
5. **Canary deploy** — direkt %100 prod'a gitti, %5'lik ramp yoktu

## ✅ Ne iyi gitti?

- ⚡ Otomatik rollback PagerDuty'den page aldıktan **4 dakika** içinde tetiklendi
- 📞 Incident channel auto-creation çalıştı, doğru insanlar tek seferde geldi
- 🔁 ArgoCD rollback komutu mühendisin elinde tek satır
- 📊 SLO burn-rate alert symptom'tan değil cause'tan tetiklendi (early signal)

## ⚠️ Ne iyi gitmedi?

- Status page güncellenmedi (customer comms eksik)
- Manuel rollback gerekti (otomatik yoktu)
- Incident sırasında `#incident-payments` kanalında 4 farklı thread paralel ilerledi (kafa karıştırıcı)

## 🎬 Aksiyon Maddeleri

> Her madde **owner**'lı, **due date**'li, **measurable** olmalı.
> "Daha dikkatli olalım" gibi sözler kabul edilmez.

| # | Aksiyon | Owner | Due | Status |
|---|---|---|---|---|
| 1 | Load test'i 1000 RPS + sustained 30dk'a çıkar | @alice | 2026-05-15 | Open |
| 2 | ORM N+1 detector (n-plus-one query analyzer) PR pipeline'a ekle | @bob | 2026-05-22 | Open |
| 3 | Staging fixture data hacmini prod'un %1'ine ölçekle | @platform-team | 2026-06-01 | Open |
| 4 | Canary deploy stratejisi: %5 → %25 → %100 zorunlu (Argo Rollouts) | @platform-team | 2026-06-01 | Open |
| 5 | Incident response playbook'a "status page update kim?" satırı ekle | @comms-lead | 2026-05-08 | Open |
| 6 | `#incident-*` kanalında thread kuralı dokümante et (single thread, lock by IC) | @docs | 2026-05-08 | Open |

## 📊 Metrik delillerine link

- [Datadog dashboard - payment-service](https://example.com/datadog/...)
- [PagerDuty incident #INC-12345](https://example.com/pd/...)
- [Slack timeline export](https://example.com/slack/...)
- [PR that caused it: #4521](https://github.com/.../pull/4521)
- [Rollback PR: #4534](https://github.com/.../pull/4534)

## 💡 Öğrenilenler

> *Genel ders. "Kişi X dikkatsizdi" yazma. "Sistemimizde X gözükmüyordu" yaz.*

1. **Staging'in prod ile orantısı önemli** — sadece schema değil, **data hacmi de** prod-like olmalı.
2. **N+1, code review'da gözden kaçar** — otomatik detection bir kontrol noktası.
3. **Canary deploy guard değil, gereklilik** — özellikle DB-backed endpoint'lerde.
4. **Otomatik rollback altın değer** — manuel müdahale 4 dakikayı 14 dakikaya çıkarıyor.

## 👥 Postmortem'e katılanlar

- @alice (incident commander)
- @bob (comms lead)
- @charlie (code author)
- @platform-team
- @engineering-manager

---

> 📝 Bu postmortem **blameless** prensiplerine göre yazıldı. Niyet: tüm
> ekibin sistemden öğrenmesi, kişiyi suçlamak değil. Konu @charlie'nin
> "yanlış" kod yazması değil; review'umuzda N+1 detector'ın olmaması.
