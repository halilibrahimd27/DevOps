---
description: "SRE mülakat hazırlığı: SLO design round, error budget ve kapasite matematiği, incident simulation ve postmortem; SRE rolünde aranan core skill'ler üzerine pratik notlar."
---
# SRE Interview Prep

> SRE rolünün DevOps'tan ayrılan tarafı: **rakam ile düşünme**, *kasten*
> arıza çıkarma, *kapasiteyi* değil *güvenilirliği* mühendislik etme.

## 🎯 SRE rolünde aranan core skill'ler

1. **Numerical reasoning** — error budget, capacity, scale (back-of-envelope)
2. **Systems thinking** — cascade, retry storm, thundering herd
3. **Calm under pressure** — incident simulation
4. **Communication** — postmortem, runbook
5. **Eng. craftsmanship** — toil reduction, automation, observability

---

## 1️⃣ SLO Design Round

> **Soru tipik:** "Sana bir servis verdim — payment-api: ödeme alıyor.
> Aylık 100M request, 5% peak hours, p99 latency hedef ~500ms. SLO tasarla."

**Adım adım nasıl yaklaşırsın:**

1. **Müşteri perspektifi:** Ödeme alındı mı? Latency ne kadar acı veriyor?
2. **SLI seç:**
   - Availability: HTTP 2xx oranı (5xx server hatası kabul edilmez)
   - Latency: ödeme oluşturma p99 < 500ms
   - (Opsiyonel) Correctness: idempotency key respect edilme oranı
3. **SLO koy:**
   - Availability: %99.95 / 30 gün → 21.6 dk down/ay budget
   - Latency: %99.9 of requests p99 < 500ms / 30 gün
4. **SLA müşteriye:** %99.9 (intern SLO buffer'lı)
5. **Multi-burn-rate alert:**
   - Fast: 14.4x burn → 2 saatte budget tükenir → SEV-1 page
   - Slow: 6x burn → 5 günde tükenir → SEV-2 ticket
6. **Error budget policy:** budget < %20 → feature freeze

> 💡 **Ne göstermek istiyorlar:** matematik + müşteri perspektifi +
> automate-able alert.

---

## 2️⃣ Incident Response Simulation

> **Soru tipik:** "Senaryo: 14:02 UTC, p99 latency 200ms → 8s sıçradı.
> 5xx oranı %3'e çıktı. Sen on-call'sın. İlk 5 dakikada ne yaparsın?"

**Söylemen gereken sıra:**

1. **Acknowledge** PagerDuty alert'i (kimse "kimse görmüyor" sanmasın)
2. **Severity belirle** — customer-impacting → SEV-1
3. **Incident channel aç** — `/incident sev-1 payment-api` (otomasyon)
4. **Recent change kontrolü** (en sık sebep):
   - Son deploy ne zaman? `kubectl rollout history`
   - Config değişikliği? Feature flag toggle?
5. **Quick rollback hazır** — "düzeltmeye çalışmadan önce, geri dön":
   - `kubectl rollout undo deployment/payment-api`
6. **Diagnosis (paralel):**
   - Downstream service latency? (DB, external API)
   - Pod restart? OOM? CPU throttle?
   - DB connection pool exhaust?
   - Recent traffic spike?
7. **Communication** — status page güncelle, customer comms tetikle
8. **Mitigate, sonra root cause**

> 🔑 **"Mitigate first, investigate later"** prensibi. 14 dakika down olmaktansa,
> 4 dakika rollback + 2 saat sonra incognito root-cause araştır.

---

## 3️⃣ Capacity Planning

> **Soru tipik:** "Şu an servis 10K RPS. Önümüzdeki Black Friday 50K RPS
> bekleniyor. Hazırlığını nasıl yaparsın?"

**Aşamalar:**

1. **Baseline ölç (current):**
   - Şu an pod sayısı, CPU/RAM kullanımı, p99 latency
   - DB connection sayısı, query latency
   - Downstream API limit'leri

2. **Linear scale assumption (genelde yanlış):**
   - 5x trafik = 5x pod? Hayır. DB, cache, downstream pinch point'ler var

3. **Bottleneck tespiti — önce DB:**
   - Read: replica scale-up + read-heavy query'leri replica'ya yönlendir
   - Write: connection pool, prepared statement cache, write batching
   - Eğer master CPU bound → vertical scale veya sharding

4. **Cache layer:**
   - Redis hit ratio? Capacity?
   - CDN cacheable response için kullan

5. **Load test:**
   - k6 / Gatling / Locust ile 60K RPS sustained
   - p99 latency degrade noktası?
   - HPA hızı yetiyor mu? (60s scale-up window?)

6. **Pre-scale (önemli!):**
   - HPA reactive → ilk dalga acı. Manuel `replicas: 100` event öncesi
   - Database connection pool pre-warm

7. **Headroom:**
   - Hedef peak'ten %30 fazla kapasite
   - Cost: maliyet artar — finance ile koordine

8. **Monitoring tighter:**
   - Burn-rate alert eşikleri sıkılaştır
   - On-call ekibi 2 katı (war room)

9. **Rollback plan:**
   - Eski sürüme geri dönüş (kapasite-eski sürüm uyumlu mu?)
   - Feature flag ile yeni-feature kapatma

---

## 4️⃣ Toil Reduction

> **Soru tipik:** "Ekibinin toil'ünü %50'nin altına indirmen gerekti.
> Nasıl yaklaşırsın?"

**Adımlar:**

1. **Ölç:** 1 hafta time-track (her saat ne yapıldı, kaç saat manuel?)
2. **Top 5 toil'i listele** (en sık + en uzun)
3. **Her biri için ROI hesapla:**
   - Kaç saat tasarruf? (haftada × 52)
   - Otomatize etmek kaç saat alır?
   - Payback period < 3 ay olanlar öncelik
4. **Quick wins:**
   - Slack komutuyla self-service ("`/restart-pod payment-api`")
   - Otomatik ticket triage (etiket, severity)
   - Runbook'ları script'leştir
5. **Yapısal:**
   - Sık kırılan servis için reliability iyileştirmesi (root cause fix)
   - On-call rotation healthier (alert fatigue audit)
6. **Sonuç ölç:** ay sonra time-track tekrarla, çıkan grafik

> Toil **sıfır** olmaz; **kontrol altında** olur. Yeni feature'lar, yeni
> toil yaratır. Sürekli rebalance.

---

## 5️⃣ Chaos Engineering

> **Soru tipik:** "İlk chaos experiment'ini nasıl tasarlarsın?"

**Süreç:**

1. **Steady state tanımla** — normal nasıl görünüyor?
   - p99 latency, error rate, throughput
   - SLO'lar in-budget
2. **Hipotez kur:** "Bir Postgres replica düşerse, cluster ayakta kalır."
3. **Blast radius minimize:**
   - Önce dev/staging'de
   - Sonra prod, ama sadece %1 traffic
   - Off-hours
4. **Tooling:**
   - Chaos Mesh / LitmusChaos / AWS FIS
   - Bir replica pod'u 5dk için sil
5. **Observe:**
   - SLO etki yedi mi?
   - Failover nasıl gerçekleşti?
   - Recovery time?
6. **Result:**
   - Hipotez doğrulandı mı?
   - Bulgular → action item'lar
7. **Iterate:** her ay yeni bir scenario, sonunda continuous chaos

### "Niye prod'da chaos?"

Stage'de bulunan hatalar prod'da **hep tekrar bulunur**. Ama sadece
prod'da bulunan hatalar **prod'da olur**. Karşı taraf bunu duymak istemez,
ama gerçek bu.

---

## 6️⃣ Pratik problemler

### Problem A — Cascading failure

```
Servis A → Servis B → Servis C
(bütün B → C çağrıları yavaşladı, A timeout retry yapıyor, B daha çok yük yiyor)
```

**Çözümler:**
- **Circuit breaker** (Hystrix, Polly, resilience4j)
- **Bulkhead** — connection pool'ları izole et
- **Backoff with jitter** — retry storm'unu engelle
- **Load shedding** — A %50 trafiği reject etsin, healthier kalsın
- **Adaptive concurrency limit** — Netflix's concurrency-limits

### Problem B — Thundering herd

Cache miss → 1000 pod aynı DB query'sini paralel atıyor.

**Çözümler:**
- **request coalescing** — aynı key'i bekleyenler tek query
- **probabilistic early refresh** — TTL bitmeden bazı pod'lar yenilesin
- **stale-while-revalidate** — eski değer döndür, arka planda yenile

### Problem C — Hot spot

Tek bir partition/shard tüm trafiği yiyor.

**Çözümler:**
- Re-sharding (key prefix randomize)
- Read replica per partition
- Cache layer hot key'ler için
- Rate limit per-key

---

## 🎓 Çalışma planı (4 hafta)

| Hafta | Konu |
|---|---|
| 1 | SRE Book bölüm 1-5 (philosophy, SLO, incident) |
| 2 | SRE Workbook (pratik examples) |
| 3 | Production-like lab + chaos experiment |
| 4 | Mock interview (peer ya da Pramp/Interviewing.io) |

---

## 🚫 Mülakatta sık hatalar

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| SLO'yu rakamsız "yüksek availability" diye geçmek | Ölçülemez hedef = error budget yok = mühendislik yok | SLI seç, %99.9x koy, dakikaya/budget'a çevir |
| %100 availability hedeflemek | Imkansız + sonsuz maliyet, hiçbir deploy/risk alınamaz | Error budget kavramını savun: %99.95 yeter, kalanı hız için harca |
| Incident'te önce root-cause araştırmak | Müşteri down'ken dakikalar yanar, "mitigate first" ihlali | Önce rollback/mitigate, root-cause postmortem'e bırak |
| Alert'i acknowledge etmeden dalmak | Ekip "kimse bakıyor mu" panik yapar, çift müdahale | İlk hareket: acknowledge + severity + incident channel |
| Kapasiteyi linear ölçeklemek (5x trafik = 5x pod) | DB/cache/downstream pinch point'leri görmezden gelir | Bottleneck'i (genelde DB) tespit et, pre-scale + headroom |
| HPA'ya güvenip event'e reactive girmek | İlk dalga acı çeker, scale-up window'u geç kalır | Black Friday öncesi manuel pre-scale + pool pre-warm |
| Chaos'u staging'de bırakıp prod'a hiç sokmamak | Sadece prod'da çıkan hatalar yakalanmaz | Blast radius minimize (%1 traffic, off-hours) edip prod'da koştur |
| Toil'i "sıfırlayacağım" demek | Gerçekçi değil; yeni feature yeni toil yaratır | "Kontrol altına alırım" + ROI/payback ile önceliklendir |
| Retry'ı jitter'sız/limitsiz eklemek | Retry storm + thundering herd, cascade'i büyütür | Backoff + jitter + circuit breaker + load shedding |
| Cache miss'i request coalescing'siz bırakmak | 1000 pod aynı query'yi atar, DB çöker | Coalescing + stale-while-revalidate + early refresh |
| Postmortem'i kişi suçlamak için kullanmak | Blameless kültür kırılır, gerçek root-cause saklanır | Blameless: sistem/process eksiğine odaklan, action item çıkar |

---

## 📋 Hazırlık adımları

- [ ] Back-of-envelope matematik akıcı: RPS↔QPS, dakika↔budget, %99.9x→downtime çevirimini ezberle
- [ ] Bir SLO'yu uçtan uca tasarlayabiliyorum (SLI seç → SLO → SLA → multi-burn-rate alert → error budget policy)
- [ ] Incident response sıralamasını refleks haline getir: ack → severity → channel → recent-change → rollback → diagnosis → comms
- [ ] "Mitigate first, investigate later" prensibini bir örnekle anlatabiliyorum
- [ ] Capacity planning'de bottleneck-önce-DB yaklaşımını ve pre-scale gerekçesini sözel verebiliyorum
- [ ] Cascading failure çözümlerini (circuit breaker, bulkhead, backoff+jitter, load shedding) ezbere sayabiliyorum
- [ ] Thundering herd / hot spot kalıplarına en az 2'şer çözüm hazır
- [ ] Bir chaos experiment'i steady-state→hipotez→blast-radius→observe→iterate sırasıyla tasarlayabiliyorum
- [ ] Blameless postmortem yapısını (timeline, impact, root cause, action items) biliyorum
- [ ] En az 1 gerçek incident/proje hikayemi STAR formatında hazırladım (Situation-Task-Action-Result)
- [ ] 4 haftalık çalışma planındaki SRE Book + Workbook bölümlerini tamamladım
- [ ] En az 1 mock interview yaptım (peer ya da Pramp/Interviewing.io)
- [ ] kubectl rollout / HPA / k6 gibi araçların temel komutlarını canlı yazabiliyorum

---

## 📚 Hazırlık kaynakları

- *Site Reliability Engineering* — Google (ücretsiz online)
- *The SRE Workbook* — Google
- *Building Secure & Reliable Systems* — Google
- *Database Reliability Engineering* — Campbell & Majors
- [SREcon talks YouTube](https://www.usenix.org/conferences/byname/925)
- Mock interview: Pramp, Interviewing.io
