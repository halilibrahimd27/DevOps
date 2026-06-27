# DORA & SPACE — Mühendislik Performansı Metrikleri

> *"Ölçmediğin şeyi iyileştiremezsin; ama yanlış ölçtüğün şey ekibini boğar."*

İki çerçeve, biri **delivery performance** odaklı (DORA), diğeri **bütünsel** (SPACE).
Birlikte kullanılır.

---

## 📊 DORA — 4 Anahtar Metrik

Google'ın "Accelerate State of DevOps Report"undan. **Delivery
performance** ölçer — yani ekip nasıl kod gönderiyor.

### 1. Deployment Frequency

> Production'a ne sıklıkta deploy?

| Seviye | Frekans |
|---|---|
| Elite | Gün içinde N kez (on-demand) |
| High | Günde-haftada |
| Medium | Haftada-ayda |
| Low | Ayda-yılda |

**Nasıl ölçülür:**
```
deploys / day  =  count(merge_to_main) / days_in_period
                  (sadece success'lü deploy'lar)
```

### 2. Lead Time for Changes

> İlk commit → production'a kaç süre?

| Seviye | Süre |
|---|---|
| Elite | < 1 saat |
| High | 1 gün – 1 hafta |
| Medium | 1 hafta – 1 ay |
| Low | 1 – 6 ay |

**Nasıl ölçülür:**
```
lead_time = deploy_timestamp - first_commit_in_PR_timestamp
```

p50, p95 takibi (averajlar yalan söyler).

### 3. Change Failure Rate (CFR)

> Deploy'ların kaçı **rollback** veya **hotfix** gerektirdi?

| Seviye | Oran |
|---|---|
| Elite | %0-15 |
| High | %16-30 |
| Medium | %16-30 |
| Low | %46-60 |

**Nasıl ölçülür:**
```
CFR = failed_deploys / total_deploys
```

"Failed deploy" tanımı:
- Rollback gerektiren
- Hotfix PR mergelenenan saatler içinde
- Customer-facing incident sebep olan

### 4. Mean Time to Restore (MTTR)

> Incident başladıktan sonra ne kadar sürede çözülüyor?

| Seviye | Süre |
|---|---|
| Elite | < 1 saat |
| High | < 1 gün |
| Medium | 1 gün – 1 hafta |
| Low | 1 hafta – 1 ay |

**Nasıl ölçülür:**
```
MTTR = avg(incident_resolved - incident_started)
```

p50 + p95.

---

## 🎯 DORA seviyeleri arası geçiş — pratik

### Low → Medium

**Ana darboğazlar:**
- Manuel deploy, manuel test
- Branch'ler aylarca yaşıyor
- "Deploy günü" ekstra sıkıntı

**Çözümler:**
- Otomatize CI/CD (basic)
- Trunk-based development geçişi
- Otomatize unit + integration test
- Staging environment

### Medium → High

**Ana darboğazlar:**
- Manuel approval bottleneck'leri
- Test suite yavaş
- Rollback manuel ve uzun

**Çözümler:**
- Feature flag (deploy ≠ release)
- Otomatik deploy (dev → staging)
- Hızlı CI (paralel + cache)
- Otomatik rollback

### High → Elite

**Ana darboğazlar:**
- Production deploy hâlâ "event"
- E2E test 30+ dk
- Incident response manuel

**Çözümler:**
- Continuous Deployment to prod (her commit)
- Progressive delivery (canary, feature flag)
- Otomatik incident response (runbook automation)
- SLO-driven deploy (error budget bitince freeze)

---

## 🌟 SPACE Çerçevesi — Bütünsel Productivity

DORA "delivery" odaklı; **SPACE bütünsel**:

| Harf | Açılım | Örnek metrik |
|---|---|---|
| **S** | atisfaction & well-being | Survey: "İşinden ne kadar memnunsun?", burnout index |
| **P** | erformance | Defect rate, customer satisfaction (NPS), eval skor |
| **A** | ctivity | Commit, PR, deploy sayısı |
| **C** | ommunication & collaboration | Code review süresi, doc PR, mentoring saat |
| **E** | fficiency & flow | Kesintisiz iş süresi, context switch, focus zaman |

### Niye SPACE?

DORA tek başına eksik:
- Activity yüksek = produktivite **değil** ("daha çok commit" → küçük anlamsız commit'ler)
- Lead time kısa = burnout sinyali olabilir
- CFR düşük = ekip risk almıyor (no innovation)

SPACE'in 5 boyutuyla **dengeli** bir resim alırsın.

### Önemli prensip: tek metrikle değerlendirme

> 🚫 **Yapma:** "Bu ekip haftada sadece 5 commit attı, kötü performans"
>
> ✅ **Yap:** "Activity düştü; survey'de 'doc engelli' yüzdesi arttı,
> review sürelerini ölçelim — flow problemi olabilir"

Tek metrik → manipüle edilebilir; çoklu metrikler **gerçek pattern**'i gösterir.

---

## 📈 Ekip seviyesinde nasıl track ederim?

### Tooling
- **DORA metric otomatik:** GitHub'da `dora-team/four-keys` (Google), Sleuth, LinearB, Faros
- **SPACE survey:** quarterly 5-min anket; Culture Amp, Lattice, custom Google Form

### Dashboard
```
┌────────────── Engineering Performance ──────────────┐
│                                                       │
│  Q1 2026                  prev Q  current Q  trend    │
│                                                       │
│  Deployment frequency     8/day   12/day     ↑        │
│  Lead time (p50)          4h      2h         ↑        │
│  CFR                      14%     11%        ↑        │
│  MTTR (p50)               45min   38min      ↑        │
│                                                       │
│  ─── SPACE survey (n=42) ───                         │
│  Satisfaction             7.8/10  7.2/10     ↓ ⚠️    │
│  Communication score      8.1/10  8.0/10     ─        │
│  Focus time/day           4.2h    3.5h       ↓ ⚠️    │
│                                                       │
└──────────────────────────────────────────────────────┘
```

> ⚠️ **Anti-pattern:** sadece DORA'ya bakıp "her şey iyi" demek. Burada
> satisfaction ve focus düşüş trendinde — DORA'nın iyileşmesi
> sürdürülebilir değil olabilir.

---

## 🚫 DORA/SPACE anti-pattern'leri

### "Vanity metrics"
- ✅ "Deploy frequency 12/day" — anlamlı
- ❌ "Total commits 5,234 this quarter" — anlamsız

### "Gaming the metrics"
- Birim test ekleyerek deploy frequency yapay artırma
- Hot-fix'leri "incident" saymama → CFR yapay düşük

### "Comparison across teams"
- ❌ "Payments team günde 8 deploy, growth team 2 deploy — payments daha iyi"
- ✅ Farklı bağlamlar (regulatory, scale) — her ekip kendi trend'iyle

### "Manager-only dashboard"
- Ekip görmüyorsa veriye sahip değildir
- Sadece üst yönetim görüyorsa: "üzerimizde gözetim" hissi

### "Quarterly review only"
- Ay başında bakılıp ay sonu unutulan dashboard değer üretmiyor
- Haftalık trend → küçük düzeltmeler

---

## 🎓 İlk DORA dashboard'unu kur (1 hafta)

```
Gün 1-2: GitHub Actions / GitLab CI'dan deploy event'lerini collect et
         (her successful deploy'da bir webhook → BigQuery / DataDog)

Gün 3:   Lead time için: PR'ın ilk commit timestamp'ı + deploy timestamp

Gün 4:   Incident kaynağı belirle (PagerDuty webhook → DB)
         CFR için: deploy → incident correlation

Gün 5:   Grafana dashboard 4 panel
         - Deploy frequency (per day)
         - Lead time p50/p95 (rolling 7d)
         - CFR (rolling 30d)
         - MTTR p50/p95

Gün 6:   Ekip ile review — anlamlı mı? Eksik var mı?

Gün 7:   Dashboard'u team channel'da haftalık otomatik post yap
```

---

## 📋 Checklist — production-ready ölçüm sistemi

Dashboard'u "kuruldu" sayma; aşağıdakiler bitmeden veri güvenilmez.

**Veri toplama**
- [ ] 4 DORA metriği de otomatik toplanıyor (manuel Excel YOK — manuel veri bayatlar ve güvenilmez)
- [ ] Deploy event'i tek doğruluk kaynağından geliyor (CI pipeline), elle işaretleme yok
- [ ] "Failed deploy" tanımı yazılı ve ekipçe onaylı (rollback + hotfix + incident-correlation)
- [ ] Incident kaynağı (PagerDuty/Opsgenie/issue) deploy'larla otomatik ilişkilendiriliyor
- [ ] Lead time ölçümü ilk commit timestamp'ından başlıyor (PR açılış'tan değil)

**İstatistik kalitesi**
- [ ] Lead time ve MTTR için ortalama değil p50 + p95 raporlanıyor (averaj outlier'ı saklar)
- [ ] Metrikler rolling pencere ile (7d / 30d) gösteriliyor, tek snapshot değil
- [ ] Düşük hacimli ekipler için sample size belirtiliyor (n<10 deploy → trend yorumlanmaz)

**SPACE dengesi**
- [ ] DORA yanında en az bir SPACE boyutu (satisfaction/focus) düzenli ölçülüyor
- [ ] Hız metriklerinin yanında burnout/satisfaction trend'i izleniyor (hız ↑ + memnuniyet ↓ = kırmızı bayrak)
- [ ] Hiçbir karar tek metriğe dayanmıyor; en az iki sinyal çapraz kontrol ediliyor

**Erişim ve ritim**
- [ ] Dashboard tüm ekibe açık (sadece yönetici görmüyor — gözetim hissi yaratır)
- [ ] Haftalık otomatik özet team channel'a post ediliyor (quarterly değil)
- [ ] Metrikler ekipler arası kıyas için DEĞİL, her ekibin kendi trend'i için kullanılıyor
- [ ] Gizli veri/credential dashboard URL'lerinde yok (`<GRAFANA_URL>`, `<WEBHOOK_SECRET>` env'de tutuluyor)

**Eylem döngüsü**
- [ ] Negatif trend için sahip + aksiyon tanımlanıyor (sadece kırmızı ok göstermek yetmez)
- [ ] Metrik review'ı retrospektifin parçası — veri konuşmaya dönüşüyor

---

## 📚 Devamı

- [DORA — State of DevOps Report](https://dora.dev) (yıllık)
- [SPACE Framework paper](https://queue.acm.org/detail.cfm?id=3454124) — Microsoft Research
- *Accelerate* — Forsgren, Humble, Kim (DORA'nın bilimsel temeli)
- [Four Keys project (Google)](https://github.com/dora-team/fourkeys) — açık kaynak DORA dashboard
