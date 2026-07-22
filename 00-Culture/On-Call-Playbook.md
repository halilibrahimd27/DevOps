---
description: "Sağlıklı on-call rotation kurma rehberi: primary/secondary roller, alert hijyeni, devir-teslim, eskalasyon ve sürdürülebilir nöbet pratikleri."
tags:
  - Culture
  - Incident Response
  - SRE
  - Monitoring
---

# On-Call Playbook

> *"Sağlıklı on-call: 7 gün boyunca rotation'da olduğunda **2 kez bile
> uyanmadıysan**, ve uyandığın zaman runbook 5 dk'da çözüm verdiyse —
> sistemi mühendislik etmişsin demektir."*

---

## 🎯 On-Call'un amacı (gerçekten)

- Customer-impacting sorunları **hızlı** kapat
- "Hero culture" değil — sürdürülebilir rotation
- Sürekli iyileştirme: her uyandığın alert post-mortem'e ya da runbook'a
- Kıdem/seniority test alanı değil — herkes katılır

---

## 👥 Roller

### Primary On-Call (1 kişi)
- Tüm alert'leri ilk yanıtlar
- 7 gün rotation, weekend dahil
- Telefon + Slack erişilebilir
- 15 dk içinde acknowledge

### Secondary On-Call (1 kişi)
- Primary cevaplamazsa devreye girer
- Primary süreklenirse paylaş
- Eskalasyon sahibinin yedeği

### Incident Commander (gerektiğinde)
- SEV-1 / SEV-2'de Primary IC olur
- Komut zincirini kontrol eder
- Comms lead'i atar
- Decision-maker (rollback / failover / wait)

### Comms Lead (gerektiğinde)
- Status page güncelleme
- Customer-facing channel
- Internal stakeholder update

---

## 📅 Rotation tasarımı

### Boyut
- 4-8 kişi ideal (6 önerilen)
- < 4: burnout riski
- > 8: rotation çok seyrek, beceri körelir

### Süre
- 7 gün rotation (Pazartesi-Pazartesi)
- Bazı ekipler 3-4 gün böler — hafta sonu ayrı
- Daily rotation çok yorucu (context yok)

### Adil dağıtım
- PagerDuty / Opsgenie ile auto-rotation
- Tatil/izin override
- Senior + junior pair (ilk ay)

### Compensation
- Standby pay (bazı ülkelerde yasal)
- Page-time pay (uyandırılınca extra)
- Comp-day (uykusuz geçen gece için ertesi gün izin)
- 🚫 "Kahramanlığın ödülü" değil — herkesin hakkı

---

## 🔔 Alert hijyeni

### Sağlıklı alert tabi
- **Actionable** — "şu komutla düzelt"
- **Customer-impacting** — gerçek bir kullanıcı sorun yaşıyor
- **Urgent** — ertesi sabaha kadar bekleyemez

### "Ticket" yapmalı, "page" yapmamalı
- "Disk %75 dolu" — page değil, ticket
- "1 pod restart oldu" — log, ne page ne ticket
- "Cron job yarın çalışmadı" — ticket

### Severity tier

| Sev | Tanım | Bildirim |
|---|---|---|
| **SEV-1** | Customer impact, revenue down | PagerDuty (call + push) |
| **SEV-2** | Major feature broken, subset etkilenir | PagerDuty (push) |
| **SEV-3** | Minor, workaround var | Slack #alerts |
| **SEV-4** | Cosmetic | Ticket queue |

### Alert audit (haftalık)
Her hafta on-call shift sonunda:
- Hangi alert'ler tetiklendi?
- Kaçı **gerçek incident**'tı? Kaçı false positive?
- Her false positive → eşik ayarlanmalı veya alert silinmeli
- Yeni alert eklendi mi? Niye?

> 🎯 Hedef: rotation'da **< 5 page** ortalama. Üzeri → reliability yatırımı.

---

## 📞 Pager response protokolü

### 0-2 dakika: Acknowledge
```
1. PagerDuty acknowledge
2. Slack #incident-X kanalına gir
3. "On it" yaz
```

### 2-5 dakika: Triage
```
4. Alert ne diyor? Runbook link'i tıkla
5. Dashboard kontrol — gerçek mi?
6. Severity doğrula
```

### 5-15 dakika: Mitigate
```
7. Önce mitigate (rollback / failover / circuit-break)
8. Sonra investigate
9. SEV-1 ise: incident commander rolü, comms lead ata
10. Sec/yapı genişliyorsa: senior'ı paged et
```

### 15+ dakika: Communicate
```
11. Status page güncelle
12. Internal update her 30 dk
13. Customer impact varsa marketing/CS'i bilgilendir
```

### Resolution
```
14. Mitigation doğrulandı (metrics yeşil)
15. Customer-facing all-clear
16. Incident channel kapatma
17. Postmortem ticket aç (24 saat içinde draft)
```

---

## 📚 Runbook standardı

> Tam template: [`17-Templates/runbooks/runbook-template.md`](../17-Templates/runbooks/runbook-template.md)

Her alert'in **mutlaka** runbook'u olmalı:
- Alert tetiklendiğinde **ilk 60 saniyede** ne kontrol edilir
- Olası sebepler + her birinin çözüm komutu
- Eskalasyon: ne zaman kim'e

> Runbook olmadan gelen alert = sebepsiz uyandırma.

---

## 🔄 Devir-teslim (handoff)

Shift sonu / başı önemli ritüel.

### Outgoing on-call yazar:
```
## Geçen hafta özet — payment-api on-call

- 3 page (1 SEV-2, 2 SEV-3)
- 1 incident (INC-1234) — postmortem yarın
- Açık issue'lar:
  - DB replica lag yüksek (ticket #5678) — gözlemde
  - Memory leak şüphesi (ticket #5689) — staging'de repro çalışılıyor
- Bu hafta deploy planlanan: v3.5.0 (Çar)

## Incoming için notlar
- v3.5.0 deploy'u canary için 30 dk gözleyin (PR'da issue var)
- payment-db-replica-2 hâlâ kararsız, fail olursa bunu kullanın: <runbook>
```

### 30 dk overlap (ideal)
- Incoming + outgoing 30 dk birlikte
- Açık konular sözle anlatılır
- Slack özet kanaldan paylaşılır

---

## 🧠 Burnout işaretleri (ekibinde gör)

- ❗ Aynı kişi sürekli "extra" shift alıyor
- ❗ Page geliyor ama acknowledge yavaş ya da skip
- ❗ Postmortem yazma istemiyorlar
- ❗ "Bu alert'i mute edelim" dediler ama kapatmadılar
- ❗ Senior ekipten ayrılma talebi

> Bunlardan herhangi biri = **acil platform yatırımı** veya **rotation
> büyütme** sinyali.

---

## ⚙️ Tooling

- **PagerDuty** — endüstri standart, en zengin
- **Opsgenie** — Atlassian, ucuz alternatif
- **Grafana OnCall** — open source, K8s-native
- **incident.io / FireHydrant / Rootly** — incident management (Slack-bot integration)
- **Statuspage.io / Cachet** — public status page

---

## 🎓 Onboarding (yeni mühendisler için)

Bir mühendisin "production-ready on-call" olması için:

| Hafta | Aktivite |
|---|---|
| 1 | Architecture overview, runbook'ları oku |
| 2 | Senior'la shadow shift (yanında dur, sorumluluk yok) |
| 3 | Reverse shadow (kendisi tutar, senior izler) |
| 4 | Solo primary (secondary tecrübeli) |

> Mock incident drill (game day) yapmak da değerli — gerçek olmayan
> ama gerçekçi senaryolarla pratik.

---

## ✅ Sağlıklı on-call kültür sinyalleri

- 🟢 Junior yeni mühendis 4 hafta sonra rahat solo gidiyor
- 🟢 Page sayısı stabil veya **azalıyor** (her postmortem fix'i ile)
- 🟢 Postmortem aksiyon item'larının > %70'i kapatılıyor
- 🟢 "Bu alert'i kapatalım, gerçek değil" dediğinde kabul edilir
- 🟢 On-call shift sonunda **comp-day** veriliyor

---

## 📋 Checklist

On-call rotation'ı **production-ready** saymadan önce hepsini işaretle:

- [ ] Rotation 4-8 kişi — < 4 ise burnout riski, hemen büyüt.
- [ ] PagerDuty/Opsgenie ile auto-rotation kurulu, tatil/izin override çalışıyor.
- [ ] Her aktif alert'in runbook'u var — runbook'suz alert canlıya alınmaz.
- [ ] Alert'ler actionable + customer-impacting + urgent; gerisi ticket'a düşürüldü.
- [ ] Severity tier (SEV-1..SEV-4) tanımlı, her tier'ın bildirim kanalı net.
- [ ] Acknowledge SLA'i (15 dk) ölçülüyor, kaçırılınca secondary'ye eskale oluyor.
- [ ] Incident Commander + Comms Lead rolleri SEV-1/SEV-2 için belirli.
- [ ] Status page (<STATUS_PAGE_URL>) bağlı, Comms Lead güncelliyor.
- [ ] Handoff ritüeli var — outgoing özet yazıyor, 30 dk overlap uygulanıyor.
- [ ] Postmortem 24 saat içinde draft'a giriyor, blameless yürütülüyor.
- [ ] Postmortem aksiyon item'larının > %70'i kapatılıyor (takip ediliyor).
- [ ] Haftalık alert audit yapılıyor; false positive eşik ayarı veya silme ile kapatılıyor.
- [ ] Compensation politikası net: standby/page-time pay veya comp-day veriliyor.
- [ ] Yeni mühendis 4 haftalık onboarding (shadow → reverse shadow → solo) tamamladı.
- [ ] Rotation ortalaması < 5 page; üzeri reliability yatırımı tetikliyor.

---

## 📚 Devamı

- [Google SRE Book — Chapter 11: Being On-Call](https://sre.google/sre-book/being-on-call/)
- *Seeking SRE* — David N. Blank-Edelman (kitap)
- [PagerDuty Incident Response docs](https://response.pagerduty.com)
- [`17-Templates/runbooks/`](../17-Templates/runbooks/) — runbook + postmortem template

---

## 📚 Referanslar

- [Blameless Postmortem Template](Blameless-Postmortem-Template.md) — her page sonrası blameless postmortem iskeleti.
- [Incident Response](../11-SRE/Incident-Response.md) — SEV-1/SEV-2 komut zinciri, IC ve Comms Lead detayı.
- [Runbook Template](../11-SRE/Runbook-Template.md) — runbook'suz alert canlıya alınmaz; standart şablon.
- [Alerting Done Right](../07-Observability/Alerting-Done-Right.md) — actionable alert tasarımı, false-positive avı.
- [SLI/SLO & Error Budget](../11-SRE/SLI-SLO-Error-Budget.md) — page bütçesini error budget'a bağla.
- [Google SRE Book](https://sre.google/sre-book/table-of-contents/) — on-call ve incident response referansı.

---

> *"On-call'i sürdürülebilir kılan kahramanlık değil; runbook'lu alert, blameless postmortem ve gece uyandıran her page'i kapatacak reliability yatırımıdır."*

---

> 🎓 **Öğrenme Patikası:** Bu doküman [`E2`](../22-Learning-Path/block-e-ownership/E2-alerting-oncall.md) modülünde "Önce oku" kaynağı olarak kullanılıyor.
