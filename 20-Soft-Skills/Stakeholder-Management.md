# Stakeholder Management — Kime, Ne Dilde, Ne Kadar

> *"Aynı outage hikâyesini CTO'ya 30 saniyede, müşteri destek
> ekibine 3 cümlede, müşteriye 3 paragrafta anlatabiliyorsan, sen
> mühendis değil **iletişim translator'usun** — ve **çok değerlisin**."*

DevOps/SRE/Platform işleri **çok-paydaşlı**. Yönetim, ürün, müşteri,
hukuk, finans, security — her biri farklı dil bekler. Bu rehber
"kime ne dilde anlatırsın" sorusunun cevabı.

---

## 🎯 Paydaş Haritası

```
                  ┌────────────────┐
                  │  Üst Yönetim   │  → "İş etkisi, maliyet, risk"
                  │  (CEO, CTO)    │
                  └────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Ürün       │  │  Mühendis    │  │ Operasyonel  │
│   (PM)       │  │   ekibi      │  │  (Support,   │
│              │  │              │  │   QA, Sales) │
└──────────────┘  └──────────────┘  └──────────────┘
        │                                  │
        ▼                                  ▼
┌──────────────┐                   ┌──────────────┐
│  Müşteri     │                   │  Vendor      │
│  (B2B/B2C)   │                   │  (cloud, etc)│
└──────────────┘                   └──────────────┘

       ┌───────────────────────────────────┐
       │  Yatay paydaşlar (her durumda)    │
       │  Hukuk · Security · Finans · HR   │
       └───────────────────────────────────┘
```

---

## 🗣️ Hangi Paydaşa Ne Dil

### Üst Yönetim (CEO, CTO, CFO)
| Bekledikleri | Sevmedikleri |
|---|---|
| **İş etkisi** ($, müşteri sayısı) | Teknik jargon |
| Risk (yüksek/orta/düşük) | "Belki, eğer" |
| **Karar** soruluyor mu, **bilgi** mi? | Uzun email |
| Net önerin var mı? | "Sizden ne yapmamı istiyorsunuz?" sorusu |

#### Şablon: bir incident özeti (CEO için)
```
What:    Payment endpoint 18 dakika down (15:30-15:48).
Impact:  ~340 müşteri etkilendi, ~$12K kayıp gelir.
Cause:   Son deploy'da DB connection pool 100 → 50 düşürdü, traffic spike'ında pool tükendi.
Fix:     Rollback yapıldı, pool 200'e çıkarıldı.
Action:  Postmortem 5 iş günü içinde. Bütçe etkisi yok.
```

> 🔑 **5 satır.** CEO 30 saniyede okur, soru sorarsa zaten gelir.

#### Şablon: yatırım talebi
```
PROBLEM: K8s cluster sürümü 1.24 (EOL Mart 2026). Upgrade etmezsek security + support kaybı.

ÇÖZÜM: 1.30'a kademeli upgrade — 6 hafta + 1 mühendis.

MALİYET: ~$15K (overtime, downtime risk minimal — mavi/yeşil deploy).

RİSK ALTERNATİF: Upgrade'i ertelersek Eylül 2026'da CVE expose, audit finding, $100K+ remediation.

ÖNERİ: Sprint 24-26'da yapalım.
```

### Ürün Müdürü (PM)
| Bekledikleri | Sevmedikleri |
|---|---|
| Feature impact (delivery date, capacity) | "Performance" gibi soyut |
| Trade-off (X yaparsak Y geç) | Saplantılı teknik tartışma |
| **Kullanıcı etkisi** | "Ben yapamam" cevabı (alternatif yok) |

#### Şablon: kapasite konuşması
```
PM: "Bu sprint'te 5 feature alabilir miyiz?"

Ben: "5'i sığdırırız ama:
      - Test süresi sıkışır → P95 bug riski %20
      - Deploy çakışmaları → rollback riski
      
      Önerim: 3 feature + 1 platform iyileştirmesi (önümüzdeki çeyrek için
      fundamentals). Hangisini bırakalım?"
```

### Mühendis Ekibi
| Bekledikleri | Sevmedikleri |
|---|---|
| Net teknik konuşma | "Yöneticilik dili" |
| Senin kararının gerekçesi | Otorite argümanı |
| Pair / pair coding daveti | Tepeden talimat |
| RFC + tartışma | Kararı fait accompli sunma |

### Müşteri Destek / Sales
| Bekledikleri | Sevmedikleri |
|---|---|
| "Hangi müşteri etkilendi?" | Teknik detay |
| Müşteriye ne diyebilecekleri | "Düzeltiyoruz" geneli |
| Geri dönüş zamanı | Açık uçlu |

#### Şablon: support ekibine outage update
```
[OUTAGE - Payment - SEV2]

Status:  ACTIVE - Investigating
Started: 15:30
Affected: ~%35 EU traffic, payment endpoint
Müşteri için söyle: "Bazı müşterilerimiz ödeme sayfasında gecikme yaşıyor olabilir, ekip aktif çalışıyor. Etkilenen müşteri için tam refund + ekstra 30 gün service credit hazır."
ETA: ~30 dk
Sonraki update: 16:00
```

### Müşteri (B2B / B2C)
| Bekledikleri | Sevmedikleri |
|---|---|
| Sahiplenme | "Vendor problemi" bahanesi |
| Net adımlar | "Soruşturuyoruz" tek başına |
| Tazminat seçeneği (ciddi outage'da) | Sessizlik |
| Düzenli update | Rastgele communication |

### Hukuk
| Bekledikleri | Sevmedikleri |
|---|---|
| Yasal risk değerlendirme | "Bunu öyle yapmıştık" |
| Veri akışı dokumanı | Söz |
| 72-saat (KVKK) gibi sürelere ciddiyet | "Yarın bakarız" |

### Finans
| Bekledikleri | Sevmedikleri |
|---|---|
| Cost forecast | "Belki büyür" |
| Kullanılmayan kapasite raporu | Sürpriz fatura |
| ROI hesabı yatırım için | "Long-term iyi olur" |

---

## 📊 Iletişim Tipi: Ne Zaman Ne

| Tip | Ne zaman | Örnek |
|---|---|---|
| **Toplantı (sync)** | Karar gerekir + 3+ kişi | RFC review, incident bridge |
| **Slack thread** | Hızlı, async OK | Status update, soru |
| **E-mail** | Eylem listesi + N kişi | Outage özet (post-resolve), monthly metric |
| **RFC / Design Doc** | Büyük karar, gelecekteki insanlar okusun | Service mesh adoption |
| **Status page** | Müşteri-facing | Outage |
| **Dashboard** | Sürekli, otomatik | Cost, SLO |
| **1:1 toplantı** | Hassas, kişisel | Performance, kariyer |

> 🔑 **Toplantı default değildir.** "Bu toplantı e-mail olabilirdi" demeden önce
> "bu e-mail dashboard olabilirdi" diye sor.

---

## 🚦 Eskalasyon Çerçevesi

### 4-Adım Eskalasyon (DevOps için)
```
1. Direct çözüm → kendi ekibinde, async
2. Manager → standuplarda raise
3. Skip-level → yöneticinin yöneticisi (1:1'de)
4. CTO/VP → critical, gerçek bütçe / örgütsel mesele
```

### Eskalasyon dili
**Yapma:**
- "Bu konuyu yöneticime taşıyacağım." (tehdit gibi gelir)

**Yap:**
- "Bunu çözmek için yöneticilerimizin desteği gerekecek. Birlikte bir senaryo üretelim mi yöneticime götürmeden önce?"

> 🔑 Eskalasyon = **sürpriz değil**. Karşılıklı bilgi paylaşımı.

---

## 📝 RFC / Design Doc Yazımı

### RFC ne zaman gerekli?
- 1 ay+ iş gerektirir
- 3+ ekip etkilenir
- Geri dönüşü zor (mimari karar)
- Bütçe yatırımı (>$X)
- Geçmişte tartışılmış, yeniden açılıyor

### RFC anatomisi
```markdown
# RFC: <BAŞLIK>
**Status:** Draft / Review / Accepted / Rejected  
**Author:** @<KULLANICI>  
**Reviewers:** @<KULLANICI>, ...  
**Date:** YYYY-MM-DD  
**Decision deadline:** YYYY-MM-DD

## TL;DR (3 cümle)
<Karar, motivasyon, etki>

## 1. Problem
<Niye burada konuşuyoruz>

## 2. Proposal
<Önerilen yaklaşım>

## 3. Alternatives Considered
- A: ... (niye değil)
- B: ... (niye değil)
- Selected: ...

## 4. Detailed Design
<Mimari, sequence diagram, API>

## 5. Trade-offs
- Pro: ...
- Con: ...

## 6. Risks & Mitigations
| Risk | Mitigation |

## 7. Decision Required
<Bu RFC'den çıkacak karar net olmalı>

## 8. Timeline
<Aşamalar + tarih>

## 9. References
```

### RFC review akışı
1. **Draft** — yazara, kapalı
2. **Review** — paydaşlar yorumlar (1 hafta)
3. **Decide** — toplantı + karar (30 dakika)
4. **Accepted / Rejected** — yazılı sonuç (kim, niye)

> 🔑 **Toplantı'sız RFC** olur, **kararsız** RFC olmaz.

---

## ⚖️ "Hayır" Demek

Bkz [`Saying-No.md`](Saying-No.md) — soft skill'in özü.

### Kısa formula
```
Yes-If: "Yapabilirim ama X bırakırsak."
Not-Now: "Bu çeyrek değil ama Q3'te."
Not-By-Me: "Bu benim alanım değil; X ekibi daha uygun."
Not-Worth-It: "Maliyet/fayda yatmıyor — şu sayılar..."
```

---

## 💬 Çatışma Çözümü

### Mühendis ↔ PM çatışması
- Common ground: müşteri etkisi
- Veri konuş: "Bu feature %2 customer'i etkiliyor; tech debt %30 deploy süresini etkiliyor."
- Trade-off ortaya: "İkisini de yapamayız, hangi metric'i tercih ediyoruz?"

### Mühendis ↔ Security
- Bkz [`Working-with-Security-Team.md`](Working-with-Security-Team.md)

### Mühendis ↔ Mühendis (teknik tartışma)
- "Hangi data ile karar verelim?"
- Disagree-and-commit: kararı al, uygula, sonuçla doğrula

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| CEO'ya 30 dakikalık teknik anlatım | Anlamaz, karar geri | 5 satır TL;DR |
| PM'a "performans iyileştirme" feature | Soyut | "P95 200ms → 50ms; checkout %3 daha çok başarılı" |
| Müşteriye "soruşturuyoruz" 4 saat | Güvensizlik | 30 dk update düzenli |
| Süpriz eskalasyon | Pat hava | Önceden manager-uyarı |
| Toplantı için RFC yazma | Kimse hazırlık yapmaz | RFC önce, toplantıda karar |
| Async iletişim yok | Toplantı yorgunu | Slack + RFC + dashboard |
| Karar "iletişimsiz" verilir | Sahipsiz, geri çekilmez | Decision log + duyuru |
| Hukuka geç haber | KVKK 72-saat ihlali | Day-zero hukuk dahil |
| "Vendor problem" demek | Sahiplenme yok | "Biz vendor'la çalışıyoruz; ETA X" |
| Status page güncel değil | Müşteri Twitter'a yazıyor | 30 dk update SLA |

---

## 📋 İletişim Hijyeni Checklist

```
[ ] Stakeholder map güncel (kim ne ister)
[ ] Şablonlar hazır: outage update, RFC, executive summary
[ ] Slack channel hijyeni: #incidents, #platform-changes, vb.
[ ] Status page: müşteri-facing, otomatik update
[ ] RFC kültürü: 1 ay+ iş için zorunlu
[ ] Decision log (Confluence / Notion / Git'te)
[ ] Quarterly: stakeholder NPS / feedback
[ ] 1:1'ler: manager, peer, skip-level düzenli
[ ] On-boarding: yeni mühendise iletişim normları öğret
[ ] Postmortem'de iletişim açısı: "iletişim eksiği var mı?"
```

---

## 📚 Referanslar

- **The Manager's Path** — Camille Fournier
- **Crucial Conversations** — Patterson et al.
- **Staff Engineer** — Will Larson
- **Writing for Developers** — Piotr Sarna
- [`Working-with-Security-Team.md`](Working-with-Security-Team.md)
- [`Saying-No.md`](Saying-No.md)
- [`Documentation-as-Communication.md`](Documentation-as-Communication.md)

---

> *"Mühendislik bilgini stakeholder anlamadığında, **teknik
> doğruluğun** bir kazanım değildir. İletişim, mühendisliğin
> **tamamlayıcısı** değil, **çarpanıdır**."*
