---
description: "DevOps kültürü referans klasörünün indeksi: blameless postmortem, on-call playbook, DORA/SPACE metrikleri, Team Topologies ve dokümantasyon kültürü."
tags:
  - Culture
  - SRE
  - Roadmap
---

# 00 · DevOps Kültürü

> *"En zor problem, kodun değil; insanların problemidir."*

Tooling'i değiştirmek bir hafta sürer; kültürü değiştirmek 2 yıl. Bu klasör
kültür tarafına dair pratik ve doğrudan uygulanabilir referansları toplar.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`Blameless-Postmortem-Template.md`](Blameless-Postmortem-Template.md) | Suçlama-olmayan postmortem şablonu, dolu örnek + kontrol listesi |
| [`On-Call-Playbook.md`](On-Call-Playbook.md) | Sağlıklı on-call rotation kurma, devir-teslim, alert hijyeni |
| [`DORA-SPACE-Metrics.md`](DORA-SPACE-Metrics.md) | DORA 4 metrik + SPACE çerçevesi: ne ölçeriz, nasıl ölçeriz, nasıl yorumlarız |
| [`Team-Topologies.md`](Team-Topologies.md) | 4 takım türü (stream-aligned/enabling/complicated-subsystem/platform) ve etkileşim modları |
| [`Documentation-Culture.md`](Documentation-Culture.md) | RFC, ADR, runbook hiyerarşisi; "documentation rotting" karşı stratejiler |

## Nereden başlamalı?

- **Yeni ekip kuruyorsan:** Team Topologies → DORA → On-Call Playbook
- **Mevcut ekibi iyileştiriyorsan:** Blameless Postmortem → SPACE → Documentation
- **Bireysel olarak öğreniyorsan:** Modern-DevOps-2026 → Postmortem → DORA

## Kültürün belirteçleri

### 🟢 Sağlıklı işaretler
- Postmortem'larda "neden mümkün oldu" sorulur, "kim yaptı" değil
- On-call sayfası 7/24 sessizdir, nadir uyandırır
- Yeni mühendis 1 günde ilk PR'ını mergeler
- "Production'a çıkarım" cümlesi gergin değildir

### 🔴 Toksik işaretler
- "Hero culture": belli kişiler olmadan deploy yapılamaz
- Postmortem'lar HR meselesine dönüşür
- Slack `#alerts` kanalı saatte 50+ alert akıtır
- "DevOps takımı" diye ayrı silo vardır
