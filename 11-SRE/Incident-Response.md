# Incident Response — Yangın Söndürmenin Anatomi'si

> *"Bir incident'ı 30 dakikada kapatabilen ekip ve 4 saatte kapatan ekip arasındaki fark — ekibin yetkinliği değil, **prosedürü**."*

Bu rehber, üretimde yangın çıktığında "ne yapılır, kim ne der, kim
karar verir" sorularına net cevap verir. Slogan değil, oncall'da çekip
uygulanır.

---

## 📐 Temel Tanımlar

| Terim | Anlam |
|---|---|
| **Incident** | Kullanıcıyı etkileyen veya etkileme riski olan, beklenmedik servis bozulması. *Bug ≠ incident.* |
| **Severity (SEV)** | Etki büyüklüğü. SEV1 → felaket, SEV4 → kozmetik. |
| **Incident Commander (IC)** | İletişimi ve kararı yöneten **tek kişi**. Mühendis değil, koordinatör. |
| **Subject Matter Expert (SME)** | Teknik debug yapan kişi(ler). |
| **Communications Lead (CL)** | Stakeholder'lara, status page'e duyuru atan kişi. |
| **Scribe** | Timeline'ı saniye bazında tutan kişi (postmortem için kritik). |
| **MTTD** | Mean Time To Detect. *Olduğunu öğrenme süresi.* |
| **MTTR** | Mean Time To Recover. *Tekrar yeşil olma süresi.* |
| **Blast radius** | Etkilenen tenant/kullanıcı yüzdesi. |

> 🔑 **Tek kural:** Incident'ı **kim** açacağı baştan belli olmalı. "PagerDuty
> alarmı kim alırsa o IC'dir" — bu ilk 5 dakikayı kurtarır.

---

## 🚨 Severity Matrisi

Her şirketin kendi tanımı vardır; aşağıdaki **referans** olarak kullanılabilir.

| SEV | Tanım | Örnek | Yanıt süresi | İletişim |
|---|---|---|---|---|
| **SEV1** | Tüm kullanıcılar etkilenmiş, gelir akıyor olabilir | Login %100 düşmüş, ödeme down, veri sızıntısı | **5 dk içinde** IC + 2+ SME | Status page + müşteri e-mail + executive |
| **SEV2** | Önemli özellik bozuk veya bir tenant tamamen down | Search çalışmıyor, EU region down, p99 latency 10x | **15 dk** IC + 1 SME | Status page + #incidents kanalı |
| **SEV3** | Performans degrade veya kısmi etki | p95 50ms→200ms, bir endpoint %2 hata | **30 dk** SME, IC opsiyonel | Internal kanal |
| **SEV4** | Kullanıcıya ulaşmamış, riskli durum | Replica düştü ama HA tuttu, disk %85 | İş günü içinde | Ticket |

### Severity'i kim kararlaştırır?
- İlk açan kişi **maximum tahmin** yapar (SEV2 yerine SEV1, sonra düşürmek serbest).
- IC ilk 10 dakikada onay/değiştirme yapar.
- "Yükseltebilirsin, düşüremezsin" değil — tam tersi: **gereksiz panik daha ucuz** SEV1 olarak başlatıp 20 dakika sonra SEV3'e indirmek, SEV3 başlatıp 1 saat sonra "aslında SEV1miş" demekten çok daha az hasarlıdır.

---

## 🎭 Roller (kim ne yapar)

```
                        ┌─────────────────────┐
                        │  INCIDENT COMMANDER │
                        │   (IC) - 1 kişi     │
                        │                     │
                        │  Karar verir,       │
                        │  iletişim koordine, │
                        │  SME yönlendirir.   │
                        │  TEKNİK YAPMAZ.     │
                        └──────────┬──────────┘
                                   │
                ┌──────────────────┼──────────────────┐
                ▼                  ▼                  ▼
      ┌─────────────────┐  ┌──────────────┐  ┌──────────────┐
      │  SME(s)         │  │  COMMS LEAD  │  │  SCRIBE      │
      │  Debug eder,    │  │  Status page │  │  Timeline    │
      │  fix önerir.    │  │  müşteri DM  │  │  saniye-ms   │
      └─────────────────┘  └──────────────┘  └──────────────┘
```

### IC'nin altın kuralları
1. **Klavyeye dokunma.** Sen IC'sin, mühendis değilsin. Komut çalıştıran SME.
2. **Her 15 dakikada update iste.** SME'lerin "biraz daha bakıyorum" döngüsünü kır.
3. **Karar ver, oylama yapma.** "Rollback yapıyoruz, 5 dakika." — tartışmayı kapat.
4. **Bitirmeyi sen söylersin.** "Resolved" demeden incident bitmez; SME "düzeltmiş gibi" hissedebilir.

### IC olabilmek için
- ✅ Sistemin genel mimarisini bilmek (her servisin değil)
- ✅ Sakin kalabilmek
- ✅ "Bilmiyorum, sor SME'ye" diyebilmek
- ❌ En kıdemli mühendis olmak (genelde tam tersi — en kıdemli SME olmalı)

---

## ⏱️ Incident Akışı (10 adım)

### 1️⃣ Detect — Olayı öğren
**Kaynak öncelik sırası:**
1. Otomatik alert (Prometheus/Datadog/Sentry → PagerDuty)
2. Müşteri raporu (support → #incidents)
3. Üst yönetim ("CEO arkadaşı şikâyet etti")

> ⚠️ Eğer **müşteri sana** önce söylüyorsa, monitoring sistemin **bozuk**.
> Postmortem'da "alerting gap" diye geçer.

### 2️⃣ Acknowledge — "Ben aldım"
PagerDuty/Opsgenie'de **5 dakika içinde** ack. Aksi halde escalation çalışır.

### 3️⃣ Open the bridge — Toplanma noktasını aç
- Slack: `#inc-2026-05-04-payment-down` (kalıcı, postmortem için)
- Zoom/Meet: video bridge (ekran paylaşımı kritik)
- Status page: ilk taslak, `Investigating` durumu

```
[15:42] @oncall: SEV2 açıldı. Payment endpoint p99 8s, 5xx %12.
[15:42] IC: ben (Halil). SME: @backend-oncall. Comms: @support-lead.
[15:43] Bridge: meet.google.com/<MEETING_ID>
[15:43] Slack: #inc-2026-05-04-payment-degraded
```

### 4️⃣ Assess — İlk 10 dakikada cevaplanmalı
| Soru | Cevap |
|---|---|
| Ne bozuk? | Payment endpoint latency + 5xx |
| Kaç kullanıcı etkileniyor? | %35 (EU traffic) |
| Ne zamandan beri? | 15:30, son deploy'a yakın |
| Recent change? | 15:25 deploy: `payment-svc v2.4.7` |
| Reproducible? | Evet, `curl` 8s döndürüyor |

> 🔑 **Recent change** sorusu **her zaman** ilk soru. Incident'ların %70'i son 24 saatteki bir değişiklikten gelir.

### 5️⃣ Mitigate — Kök neden DEĞİL, kanamayı durdur
Mitigation seçenekleri (öncelik sırası):
1. **Rollback** — son deploy şüpheli mi? %1 düşünmeden geri al.
2. **Feature flag off** — yeni feature'ı kapat.
3. **Traffic shift** — diğer region'a yönlendir.
4. **Scale up** — boğulma şüphesi varsa.
5. **Restart** — son çare; sebebi kaybedersin (memory dump alındı mı?).

> ⚠️ **Mitigate ≠ Fix.** Şu an amacın kanı durdurmak. Kök neden POST'ta.

### 6️⃣ Communicate — Status page güncel
**Update aralığı:**
- SEV1: her **15 dakika**
- SEV2: her **30 dakika**
- "Bilgi yok" bile bir update'tir: *"Soruşturma devam ediyor, sonraki güncelleme 16:30'da."*

**Status page taslağı:**
```
[15:50] Investigating — Bazı kullanıcılarımız ödeme sayfasında
gecikme yaşıyor olabilir. Mühendislik ekibi inceliyor.

[16:05] Identified — Sorunu son deploy'a bağladık, geri alıyoruz.

[16:18] Monitoring — Geri alma tamam, metrikleri izliyoruz.

[16:35] Resolved — Tüm kullanıcılar için normale döndü.
Detaylı postmortem 5 iş günü içinde yayımlanacak.
```

> 🇹🇷 **KVKK notu:** Eğer kişisel veri sızıntısı varsa, **72 saat içinde**
> KVKK'ya bildirim zorunluluğu. Status page metni hukuk ekibinden geçmeli.
> Bkz: [`19-Compliance/KVKK-Practical.md`](../19-Compliance/KVKK-Practical.md).

### 7️⃣ Resolve — Yeşil
- Metrikler 15 dakika boyunca normal değerlerde
- Müşteri raporları kesilmiş
- IC `Resolved` der → status page güncellenir → channel'a `[RESOLVED]` etiketi

### 8️⃣ Hotwash — 30 dakika içinde
Bridge kapanmadan kısa bir retro:
- Ne işe yaradı?
- Ne yapamadık?
- Hangi tool eksikti?
- IC iyi koordine etti mi?

Notlar postmortem için hazırlanır.

### 9️⃣ Postmortem — 5 iş günü içinde
[`Blameless-Postmortem-Template.md`](../00-Culture/Blameless-Postmortem-Template.md)
ve [`17-Templates/runbooks/postmortem-template.md`](../17-Templates/runbooks/postmortem-template.md)
şablonlarını kullan.

### 🔟 Action items — sahibi + due date
- Her action item bir **kişi** ve **tarih** ister
- "Ekip" sahip olamaz
- Due date olmayan action item kapanmaz

---

## 🛠️ Pratik Tooling

| İhtiyaç | Önerilen | Alternatif |
|---|---|---|
| Alerting + on-call rotation | PagerDuty | Opsgenie, Grafana OnCall (open-source) |
| Status page | Statuspage.io, Better Stack | cstate (self-hosted), Instatus |
| Incident channel oluşturma | [Incident.io](https://incident.io), Rootly | Slack workflow + custom bot |
| Timeline / scribing | Incident.io otomatik | FireHydrant, manuel Slack thread |
| Postmortem yazımı | Jeli.io, Incident.io | Notion + template |
| Chatops botu | Slack `/incident` workflow | Custom (Python+slack-sdk) |

### Slack workflow örneği (`/incident` komutu için)
```yaml
# Slack workflow: /incident-open
inputs:
  - severity: SEV1, SEV2, SEV3, SEV4
  - title: free text
  - affected_service: dropdown

actions:
  1. Create channel #inc-<DATE>-<SLUG>
  2. Invite @oncall-<TEAM>, @ic-rotation
  3. Post pinned message:
     - Severity, title, IC, SME, CL, scribe slots
     - Bridge link
     - Status page update template
  4. Notify #incidents-firehose
  5. PagerDuty incident open (if SEV1/SEV2)
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru yapan |
|---|---|---|
| **"Kök nedeni bulmadan rollback yapmayalım"** | Kullanıcı kanıyor, sen analiz yapıyorsun | Önce mitigate, kök neden postmortem'de |
| **IC mühendis | Klavyeye dokunan koordine edemez | IC sadece koordinasyon yapar |
| **CEO bridge'e girip "ne oluyor?" diyor** | IC'nin akışını böler | CL → executive briefing **ayrı** kanalda |
| **"Sessizce çözeyim, kimse fark etmesin"** | Sonra postmortem yok, öğrenme yok, tekrar olur | Tüm SEV1/SEV2 yazılı raporlanır |
| **Update yok, "yakında biter"** | Stakeholder güveni biter | "Bilgi yok" bile update'tir |
| **Aynı IC 8 saat | Yorgun IC kötü karar verir | 4 saatte rotate |
| **"Şu kişi yine bozdu"** | Blame culture → herkes bilgi saklar | Blameless: sistem hatası, kişi değil |
| **PagerDuty escalation 30 dakika** | İlk responder uyumadan sonsuza ack atar | 5 dakikada escalate |
| **Postmortem **what** yazıyor, **why** yazmıyor | Tekrarı önlemez | 5-Whys uygulanmış mı? |

---

## 📋 IC Cheatsheet (yangın anında aç)

```
1. Severity belirle, channel aç, bridge linki paylaş.
2. Roller dağıt: SME, CL, Scribe.
3. İlk 10 dk → Assess: ne, kim, ne kadar, son change?
4. Mitigation seç: rollback / flag / scale / traffic shift.
5. Status page: Investigating → Identified → Monitoring → Resolved.
6. Her 15-30 dk update.
7. Resolved: 15 dk yeşil + müşteri raporu yok.
8. Hotwash + postmortem assign.

Dikkat:
- Klavyeye dokunma.
- Karar ver, oylama yapma.
- "Bilmiyorum" demek IC için güçtür, zayıflık değil.
- Yorgunsan IC'liği devret.
```

---

## 🎯 Hazırlık (incident anı için değil, *önceden*)

### Game Day / Chaos Engineering
- Ayda 1 simulated incident (tatbikat).
- Senaryo: "Region-A down", "DB failover", "DNS hijack".
- Öğrenme hedefi: runbook'lar çalışıyor mu, IC'ler hazır mı.

### Runbook Kütüphanesi
Her servisin kendi `runbook/` klasörü:
- Yaygın alarm → ne yap
- Rollback prosedürü
- Owner kim, escalation kime

Şablon: [`17-Templates/runbooks/runbook-template.md`](../17-Templates/runbooks/runbook-template.md)

### IC Eğitimi
- Yeni IC önce 3 incident'ta **shadow** yapar.
- Sonra 3 incident'ta **deputy IC** (asıl IC'nin yanında).
- Sonra solo IC.
- 6 ayda bir tatbikat.

### On-call sürdürülebilirliği
- Hafta başına max **48 saat** primary
- Geceyi kapsayan vardiya → ertesi gün izinli
- Fazla mesai → next sprint'te azaltılır
- Burnout sinyalleri: bkz [`20-Soft-Skills/Oncall-Sustainability.md`](../20-Soft-Skills/Oncall-Sustainability.md)

---

## 📚 Referanslar

- **Google SRE Workbook** — Bölüm 9: Incident Response
- **PagerDuty Incident Response Documentation** — açık kaynak, Türkçe çevirisi yok ama erişilebilir
- **Etsy Debriefing Facilitation Guide** — postmortem fasilitasyonu için altın standart
- [`00-Culture/Blameless-Postmortem-Template.md`](../00-Culture/Blameless-Postmortem-Template.md)
- [`00-Culture/On-Call-Playbook.md`](../00-Culture/On-Call-Playbook.md)
- [`11-SRE/SLI-SLO-Error-Budget.md`](SLI-SLO-Error-Budget.md) — error budget incident'ı tetiklemeli mi?

---

> *"En iyi incident response — incident'ın olmaması." — Doğru.
> Ama olduğunda, ekibin pratiği değil **prosedürü** kazanır.*
