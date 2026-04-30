# SLI / SLO / Error Budget — Pratik Rehber

> *"%100 uptime hedef değildir; matematiksel imkansızdır. **%99.9 hedeftir, geri kalan %0.1 mühendislik karar bütçenizdir.**"*

Bu rehber Google SRE Book'tan damıtılmış ama Türkçe ve doğrudan
uygulanabilir. Sonunda kendi servisinin ilk SLO'sunu yazabilmen amacımız.

---

## 📐 Tanımlar (kısa ve net)

| Terim | Anlam |
|---|---|
| **SLI** (Service Level **Indicator**) | Ölçülen şey. `% successful requests`, `p99 latency`. **Bir oran veya bir histogram.** |
| **SLO** (Service Level **Objective**) | Hedef. `SLI ≥ %99.9 son 30 günde`. **Kendi içsel sözünüz.** |
| **SLA** (Service Level **Agreement**) | Müşteriyle yasal söz. SLO'dan **gevşek** olmalı. |
| **Error Budget** | `1 - SLO`. Tolere edilen arıza miktarı. **Risk almak için harcanır.** |
| **Burn Rate** | Bütçeyi normal hızdan kaç kat hızlı yakıyoruz. `2x burn` → 30 gün budget'ı 15 günde biter. |

> 🔑 **Anahtar prensip:** SLO **müşteri perspektifinden** yazılır. CPU%
> kimsenin umurunda değil; "ödeme oluştu mu, oluşmadı mı" umurundadır.

---

## 🎯 SLI Seçim Kuralları

### Kural 1: Müşteri-deneyimi yansıtmalı
- ✅ HTTP 2xx oranı, request latency
- ✅ Job tamamlanma süresi, queue lag
- ❌ CPU%, memory%, disk I/O (bunlar saturation göstergesi, SLI değil)

### Kural 2: Ölçülebilir ve kontrol edilebilir
- ✅ "Bizim cevap süremiz < 500ms"
- ❌ "Müşterinin kendi internet bağlantısı"

### Kural 3: Kategorilere göre sınıflandır
| Tür | Örnek | SLI |
|---|---|---|
| **Request/response** | HTTP API | Availability (success rate), Latency (percentile) |
| **Data processing** | ETL, ML inference | Throughput, Freshness, Correctness |
| **Storage** | DB, S3 | Durability, Retrieval latency, Throughput |

### Kural 4: User journey > endpoint
- ❌ "GET /api/users %99.9 başarılı"
- ✅ "Checkout flow (4 endpoint zinciri) %99.5 başarılı"

User aslında "ödeme tamamladı mı" soruyor; tek endpoint yeşil olabilir
ama akış kırık olabilir.

---

## 🧮 SLO Hedef Belirleme

### Adım 1: Mevcut performansı ölç
Önce **bilinçsiz** olan SLO'yu (yani gerçek davranışı) ölç. Son 30 gün:

```promql
# Şu anki availability
sum(rate(http_requests_total{code!~"5..",app="<APP>"}[30d]))
/
sum(rate(http_requests_total{app="<APP>"}[30d]))
```

Çıktı: `0.9985` → şu an %99.85.

### Adım 2: Hedefi gerçekçi koy

Yaygın hata: "%99.99 olsun". Aşağıdaki tabloya bak — gerçekten gerek var mı?

| SLO | Aylık downtime | Yıllık downtime | Maliyet (kabaca) |
|---|---|---|---|
| %99 | 7 saat 18 dk | 3.65 gün | Düşük (tek-AZ + retries) |
| %99.5 | 3 saat 39 dk | 1.83 gün | Orta |
| %99.9 | 43 dakika | 8.76 saat | Multi-AZ + auto-failover (**çoğu prod için sweet spot**) |
| %99.95 | 21 dakika | 4.38 saat | Aktif-aktif HA |
| %99.99 | 4.3 dakika | 52 dakika | Multi-region + complex DR |
| %99.999 | 26 saniye | 5.26 dakika | "Five nines" — sadece telco/finance |

### Adım 3: SLO < SLA kuralı
SLA müşteriye `%99.5` veriyorsanız, **iç SLO'nuz `%99.7`** olsun. Buffer
sizin için.

### Adım 4: Window (zaman penceresi)
Standart: **30 gün rolling**.
- Daha kısa (7 gün): noisy, sinir bozucu
- Daha uzun (90 gün): kötü davranışı çok geç fark edersin

---

## 💰 Error Budget Matematiği

```
SLO          = %99.9
Window       = 30 gün
Total minutes = 30 * 24 * 60 = 43,200 dk
Allowed bad  = 43,200 * (1 - 0.999) = 43.2 dk
```

Yani 30 günde **43 dakika** "kötü" zaman tolerebilir.

### Bütçe yönetimi pratik tablosu

| Bütçe durumu | Politika |
|---|---|
| > %50 (taze) | Risk al, agresif deploy, yeni feature |
| %20-50 | Normal hız |
| %0-20 | Feature freeze; sadece reliability işleri |
| < %0 (overspent) | Üretime deploy DUR; root cause'lara odaklan |

> Bu **otomatik enforce edilmeli**. Argo Rollouts + alertmanager + GitOps
> gating ile kodla zorlanır. Manuel "biz tutarız" politika yok.

---

## 🚨 Multi-Burn-Rate Alerting

Tek-window SLO alert sorunu: ya çok geç görür (low-burn) ya da çok hassas (false positive).

**Çözüm:** Aynı anda 2 farklı pencerede yüksek burn-rate görürsen alert.

```
FAST burn  = 14.4x   → 5dk + 1saat penceresi
                       2 saatte bütçeyi yakar → SEV-1 page
SLOW burn  = 6x      → 1saat + 6saat
                       5 günde bütçeyi yakar → SEV-2 ticket
```

PromQL örneği:

```yaml
- alert: HighErrorBudgetBurnRate
  expr: |
    (
      (1 - sli:availability:5m) > (14.4 * (1 - 0.999))
      and
      (1 - sli:availability:1h) > (14.4 * (1 - 0.999))
    )
  for: 2m
```

(Tam template: [`17-Templates/prometheus-rules/slo-recording-rules.yaml`](../17-Templates/prometheus-rules/slo-recording-rules.yaml))

---

## 📊 Dashboard'da Ne Olmalı?

**Tek bakışta** şunlar görülmeli:

```
┌──────────────────────────────────────────────────────────────┐
│  Service: payments-api          SLO: %99.9 / 30d              │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  Current SLO:    99.94%   ✅                                  │
│  Error Budget:   78%       (33 dk / 43 dk)                    │
│                                                                │
│  Burn Rate:                                                    │
│    1h     0.4x   (within budget)                              │
│    6h     0.7x                                                 │
│    24h    0.9x                                                 │
│                                                                │
│  ┌────── Burn over 30 days ──────────────────────────────┐    │
│  │ ▁▁▁▂▂▁▁▃▃▃▁▁▁▁▁▂▂▂▁▁▁▁▁▁▁▁▁▁▁                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                │
│  Recent deploys (annotation):  v3.4.0  v3.4.1  v3.4.2          │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

---

## 🎓 Yaygın Hatalar ve Çözümleri

### Hata 1: "p99 < 500ms" değil "average < 500ms"
Ortalama yalan söyler. p99 hızında çok daha az pek çok kötü request görür.

```promql
# YANLIŞ
avg(rate(request_duration_seconds_sum[5m])) / avg(rate(request_duration_seconds_count[5m]))

# DOĞRU
histogram_quantile(0.99,
  sum by (le) (rate(request_duration_seconds_bucket[5m]))
)
```

### Hata 2: SLO sadece error rate
Latency, freshness, correctness de SLO olmalı. Servisiniz hızlı ama
yanlış yanıt veriyorsa SLO yeşil ama müşteri kötü.

### Hata 3: Cause-based alert
- ❌ `CPU > %80` (CPU yüksek olabilir, kullanıcı etkilenmemiş)
- ✅ `error_budget_burn_rate > 14.4x` (gerçek müşteri etkisi)

### Hata 4: Toplam metric vs per-tenant
Çoklu tenant'lı API'de toplam SLO'nuz %99.9 ama bir büyük tenant
%50 kullanılamaz olabilir → toplama bakarsanız fark etmezsiniz.

```promql
# Per-tenant breakdown
sum by (tenant) (rate(http_requests_total{code!~"5.."}[5m]))
/
sum by (tenant) (rate(http_requests_total[5m]))
```

### Hata 5: SLO'yu retro-fit etmek
"Şu anki davranışım %99.7, hedefim %99.7". Bu SLO değil, ölçüm.
Hedef her zaman **şu ankine yakın ama biraz iyi** olmalı (yapılması gereken iş varsa).

### Hata 6: Üreticiye değil müşteriye yakın ölç
- ❌ App tarafında 5xx oranı (load balancer'da timeout olan zaten ölçülmemiş)
- ✅ CDN / API gateway tarafında (kullanıcının gördüğü)

---

## 🚀 Adım Adım: İlk SLO'nu Bugün Yaz

### 1. Servisini seç (kritikten başla)
- Customer-facing
- Failure'ı acı veriyor
- Metrics zaten toplanıyor

### 2. SLI'larını listele
```
- availability  : (1 - error_rate)
- latency        : p99 < 500ms ana request türleri için
- (opsiyonel) freshness : data lag < 60s
```

### 3. Mevcut performansı ölç
Geçen 30 günü Prometheus query ile.

### 4. Hedef koy
Mevcut + biraz mühendislik gücü = SLO.

### 5. Recording + alerting rules yaz
Template: [`17-Templates/prometheus-rules/slo-recording-rules.yaml`](../17-Templates/prometheus-rules/slo-recording-rules.yaml)

### 6. Dashboard kur
Burn-rate, current SLO, budget remaining.

### 7. Error budget policy yayınla
"Budget < %20 ise feature freeze" kuralını **yazılı** olarak takıma
duyur. Kim bu kuralı uygulayacak (tooling enforce'u + manager onayı)?

### 8. Aylık review
- Bütçe ne kadar yandı?
- Alert'ler doğru mu tetikledi?
- SLO hedefini güncellemek gerek mi?

---

## 📚 Devamı

- *Site Reliability Engineering* (Google SRE Book) — bölüm 4
- *The Site Reliability Workbook* — bölüm 2
- [SRE Book online](https://sre.google/sre-book/service-level-objectives/) — ücretsiz
- [Awesome SLO](https://github.com/awesome-slo/awesome-slo) — pratik örnekler
- [`17-Templates/prometheus-rules/`](../17-Templates/prometheus-rules/) — bu repo'da hazır rule'lar
