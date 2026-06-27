---
description: "Blameless postmortem kültürünün rutine dönüştürülmesini, yazma süreci, fasilitasyon, action item yönetimi ve kültürel sürdürülebilirliği anlatır."
---
# Postmortem Practice — Blameless'i Rutin Haline Getirmek

> *"Postmortem yazılmamış incident, **bir daha olmaya hazırlanan**
> incident'tır. Yazılmış ama action item'sız postmortem ise,
> **postmortem değil, yas töreni**."*

Bu rehber blameless postmortem kültürünün nasıl rutine dönüştürüleceğini,
yazma süreci, fasilitasyon, action item yönetimi ve **kültürel
sürdürülebilirliği** anlatır.

---

## 🎯 Postmortem Niye?

| Amaç | Açıklama |
|---|---|
| **Öğrenme** | Aynı incident bir daha olmasın |
| **Sistem iyileştirme** | Action item → kalıcı düzeltme |
| **Bilgi paylaşımı** | Ekip dışı insanlar da öğrensin |
| **Trust building** | Stakeholder'lara "ciddiye aldık" mesajı |
| **Pattern keşfi** | 5 postmortem'in ortak teması = systemic issue |

---

## 🚫 Blame ≠ Accountability

### Blame (yapma)
- "Kim yaptı bunu?"
- "Niye dikkat etmedi?"
- "Bu hata bir daha olmamalı." (kişisel)

### Accountability (yap)
- "Hangi mekanizma bunu fark ettirmedi?"
- "Hangi süreç eksikti?"
- "Bu pattern bir daha olmasın diye sistem nasıl değişmeli?"

> 🔑 **Etki**: Blame culture → "kimse hata söylemez" → büyük incident'lar
> sessizce büyür. Blameless → ekip korkmadan rapor eder → hızlı tespit.

> Detay: [`00-Culture/Blameless-Postmortem-Template.md`](../00-Culture/Blameless-Postmortem-Template.md)

---

## 📋 Postmortem Şablonu

```markdown
# Postmortem: <KISA_BAŞLIK>
**Date of incident:** YYYY-MM-DD HH:MM (UTC)  
**Severity:** SEV-1 / SEV-2  
**Duration:** X dakika  
**Authors:** @<KULLANICI>  
**Status:** Draft / Review / Published  

## Executive Summary (3 cümle)
<Ne oldu, ne kadar etkiledi, çözüldü mü.>

## Impact
- **Customers affected:** ~%X (Y kişi)
- **Revenue impact:** ~$Z
- **Data loss:** none / X records
- **SLO breach:** error budget %X consumed
- **Public communication:** status page + email

## Timeline (UTC)
| Time | Event |
|---|---|
| 15:30 | Deploy v1.4.2 başladı |
| 15:32 | Payment endpoint p99 50ms → 8s |
| 15:35 | Alert (PagerDuty SEV2) |
| 15:38 | On-call IC açtı |
| 15:42 | Root cause hypothesis: connection pool config |
| 15:45 | Mitigation: rollback başladı |
| 15:48 | Rollback tamamlandı, metrics normal |
| 15:50 | Status page: Resolved |

## Root Cause
<Teknik detay: ne neden oldu.>

> 5-Whys uygulanmış mı?
> 1. Niye outage? — Pool tükendi.
> 2. Niye tükendi? — Pool size 100 → 50 yapılmış.
> 3. Niye 50 yapıldı? — Test'te 50 yetiyordu.
> 4. Niye prod'a 50 deploy edildi? — Config tek dosya, env split yok.
> 5. Niye env split yoktu? — Kustomize migration eksik kaldı.

## What went well
- IC role hızlı atandı
- Rollback 6 dakikada tamamlandı
- Status page güncellendi
- Müşteri destek hazırdı

## What went wrong
- Test environment prod load'unu temsil etmedi
- Config validation eksikti (CI gate yok)
- Alert 7 dakika sonra düştü (early-warning gap)

## Where we got lucky
- Rollback otomatik
- Pool tükenme deploy sonrası 5 dk içinde, yoğun olmayan saat

## Action Items
| # | Action | Owner | Due | Priority |
|---|---|---|---|---|
| 1 | Kustomize ile env split bitir | @platform | 2026-05-15 | P1 |
| 2 | CI gate: prod values diff review | @platform | 2026-05-08 | P0 |
| 3 | Load test prod-like data ile | @qa | 2026-06-01 | P2 |
| 4 | Pool size early-warning alarm | @sre | 2026-05-12 | P1 |
| 5 | Config doc: pool sizing | @docs | 2026-05-20 | P3 |

## References
- Slack: #inc-2026-05-04-payment-degraded
- Bridge recording: <URL>
- Dashboard at incident: <URL>
- Related postmortems: INC-2026-02-08
```

---

## 🗓️ Postmortem Takvimi

```
T+0       Incident resolved
T+30 dk   Hot wash (bridge'de hızlı retro, 30 dk)
T+1 gün   Author atanır (genelde IC)
T+3 gün   Draft hazır → review için paylaş
T+5 gün   Review meeting (60 dk)
T+5 gün   Published — wiki / Backstage / repo
T+30 gün  Action item check (kim ne ne kadar tamamladı)
T+90 gün  Pattern review (son 3 ay postmortem'lerin trendi)
```

> 🔑 **5 iş günü** kuralı. Aksi halde hafıza bulanır, action item kaybolur.

---

## 🎤 Review Meeting Fasilitasyonu

### Katılımcılar
- IC (incident commander)
- SME'ler (debug yapanlar)
- Manager (ekip lideri)
- Stakeholder (PM, customer success — opsiyonel)
- Skip-level senior (pattern bakar)

### Akış (60 dakika)
```
0-5 dk:    Tone setting (blameless reminder)
5-15 dk:   Timeline review
15-25 dk:  Root cause tartışma + 5-whys
25-35 dk:  "What went well" — ekibe takdir
35-45 dk:  "What went wrong" + "lucky"
45-55 dk:  Action items finalize (owner + due)
55-60 dk:  Yayın onayı + iletişim plan
```

### Fasilitatör'ün rolü
- "Blame" sezdiğinde nazikçe redirect ("Sistem perspektifi nedir?")
- Sessiz olanı söze davet et
- Action item'ı **net** hale getir (vague şey kabul etmeyen)
- "Bu konu burada değil" diyebilmek (scope creep)

---

## 📊 Action Item Yönetimi — En Zayıf Halka

> Postmortem yazıldı, kimse action item'ı yapmadı → 6 ay sonra **aynı incident**.

### Kurallar
1. **Sahibi** kişi (ekip değil)
2. **Due date** spesifik (sprint'in son günü değil, "Q3" değil)
3. **Priority** P0-P3 (P0 = derhal)
4. **Tracking** — JIRA/Linear/GitHub Issue
5. **Status check** 30 gün sonra zorunlu
6. **Escalation** — gecikenlerin manager'ına eskalasyon

### Dashboard
```
Postmortem Action Items
├── Open: 23
│   ├── Overdue (>30 gün): 5 ⚠️
│   ├── In progress: 12
│   └── New: 6
├── Closed (last 90 days): 47
└── Pattern: connection pool issues = 4 postmortem
```

> 🔑 Quarterly review: Pattern keşfeder. Aynı sebep 3+ postmortem'de
> → systemic project (örnek: "platform connection pooling overhaul").

---

## 📈 Postmortem Metrikleri

| Metrik | Hedef |
|---|---|
| **Incident → postmortem published** süresi | < 7 gün |
| **Action item completion** (within due date) | > %80 |
| **Postmortem'lerin %X'i** action item'larıyla incident önler | Trend up |
| **Public postmortem** sayısı (transparency) | Belirli SEV-1 için |
| **Pattern detection** (aynı kök neden tekrar) | Trend down |

---

## 🌐 Public Postmortem (B2B Müşteri)

Bazı incident'lar **public** yazılır:
- Müşteriye etki yüksek (>%5 outage)
- Müşteri trust gerektirir (SaaS)
- B2B SLA breach

### İyi public postmortem örnekleri
- Cloudflare incident reports
- GitHub status & postmortems
- AWS Service Health Dashboard postmortems

### Public yazımı
- Internal postmortem'i sadeleştir
- PII/secret yok
- Net timeline + impact + sebep
- "Sorry" demekten çekinme (ama abartma)
- Action item özet (detay internal)

---

## 🎯 Postmortem Kalitesi: Rubric

Yazılan postmortem'i puanla (PR review'da):

| Kriter | 0 | 1 | 2 |
|---|---|---|---|
| Timeline net mi? | Yok | Genel | Saniye-dakika bazında |
| Root cause | "Bug" | Teknik açıklama | 5-whys uygulanmış |
| Impact ölçülmüş | Hayır | Yaklaşık | Müşteri sayı + revenue |
| What went well | Atlanmış | 1-2 madde | Ekibe takdir + ne işe yaradı |
| Action item: owner+due | Hiçbiri | Sadece owner | Owner + due + priority |
| Blameless dil | "X yaptı" | Karmaşık | Sistem-perspektifli |
| Pattern bağlantısı | Tek incident | Bahsi geçer | Önceki postmortem'lerle ilişkilenmiş |

> Toplam 12 üzerinden < 8 → **revize**.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Postmortem 3 hafta sonra | Hafıza bulanır | 5 iş günü kuralı |
| "X bunu yaptı, dikkatli olsun" | Blame, korku kültürü | Sistem-perspektifli dil |
| Action item: "Daha dikkatli olalım" | Ölçülemez | Spesifik task + owner + due |
| Action item sayısız ama hiçbiri kapanmıyor | Görünür değil | Tracking + 30 gün check |
| 1 sayfa kısa postmortem (SEV-1 için) | Detay eksik, öğrenme yok | Detaylı + timeline |
| 30 sayfa postmortem | Kimse okumaz | Detay var ama executive summary 3 cümle |
| Postmortem secret | Ekip dışı öğrenmiyor | Internal-public; SEV-1 için public |
| Aynı root cause 3 postmortem'de | Pattern kaçırıldı | Pattern review project |
| "Lucky" bölümü atlanır | Risk değerlendirmesi eksik | Where we got lucky her zaman |
| Postmortem yapanlar **hep aynı kişiler** | Burnout | Rotation: IC değil, ekipten |
| Public postmortem PR/marketing onay'ı bekler | 2 hafta gecikir | Pre-templated + DPO/Hukuk hızlı review |

---

## 🎓 Postmortem Yazma Eğitimi

### Yeni mühendise on-boarding
1. Önceki 3 postmortem'i oku
2. Bir postmortem'in fasilitasyonunda **shadow** ol
3. İkinci postmortem'i **yardımcı author** olarak yaz
4. Üçüncüden itibaren solo

### Quarterly tatbikat
- Geçmiş incident'ı simüle et
- Yeni mühendise postmortem yazdır
- Senior review + feedback
- "Postmortem game day" — eğlenceli & öğretici

---

## 📋 Postmortem Disiplin Checklist

```
[ ] SEV-1 + SEV-2 her zaman postmortem
[ ] Author 24 saat içinde atanır (genelde IC)
[ ] Draft 3 iş günü içinde
[ ] Review meeting 5 iş günü içinde
[ ] Published 7 iş günü
[ ] Şablon kullanılıyor (timeline, root cause, AI)
[ ] 5-Whys yapılmış
[ ] Action item: owner + due + priority
[ ] Action item tracking (JIRA/Linear)
[ ] 30 gün action check
[ ] Quarterly pattern review
[ ] Public postmortem (B2B / yüksek SEV-1)
[ ] Postmortem rubric ile review
[ ] Blameless dili enforce
[ ] Yeni mühendis postmortem'lerden onboarding
[ ] Postmortem yazımı rotation (sadece senior değil)
```

---

## 📚 Referanslar

- **Google SRE Book** — Bölüm 15: Postmortem Culture
- **Etsy Debriefing Facilitation Guide** — fasilitasyon altın standardı
- **PagerDuty Postmortem Documentation**
- **VOID Project** — public postmortems database
- [`Incident-Response.md`](Incident-Response.md)
- [`Runbook-Template.md`](Runbook-Template.md)
- [`00-Culture/Blameless-Postmortem-Template.md`](../00-Culture/Blameless-Postmortem-Template.md)
- [`17-Templates/runbooks/postmortem-template.md`](../17-Templates/runbooks/postmortem-template.md)
- [`20-Soft-Skills/Oncall-Sustainability.md`](../20-Soft-Skills/Oncall-Sustainability.md)

---

> *"Postmortem 'tarih raporu' değil, **gelecek incident'ı önlemek**
> için yazılan kullanıcı manualidir. Yazıldığında ekip öğrenir;
> action item kapandığında **sistem öğrenir**."*
