---
description: "SLO'yu muhendislik disiplinine cevirme rehberi: SLI/SLO/error budget ozeti, multi-window burn rate alarmlari, error budget policy ve operasyonel tooling."
tags:
  - Observability
  - SRE
  - Monitoring
  - Incident Response
---
# SLO Engineering — Multi-Window, Burn Rate, Error Budget

> *"SLI tanımladın. SLO koydun. **Error budget alarmı yoksa**, SLO
> değil **iyi niyet**'tir. Burn rate alarm = SLO'nun **gerçek
> uygulayıcısı**."*

Bu rehber SLO'yu mühendislik disiplinine çevirmek için multi-window
burn rate alarm'ı, error budget policy'i, ve operational tooling'i
anlatır.

> Temel: [`11-SRE/SLI-SLO-Error-Budget.md`](../11-SRE/SLI-SLO-Error-Budget.md)

---

## 🎯 SLI / SLO / Error Budget Özet

```
SLI: ölçülen şey      → http_requests_total (success rate)
SLO: hedef           → 99.9% son 30 günde
Error Budget         → 0.1% × 30 gün = 43 dakika
Burn Rate            → bütçeyi normal hızdan kaç kat hızlı yakıyoruz?
```

---

## 🔥 Burn Rate Nedir?

> **Burn rate**: Error budget'ı normal hızdan kaç kat hızlı tüketiyoruz.

```
Normal: 30 gün → 100% bütçe
Hız 1: 30 gün × 1 = 30 gün'de bütçe biter ✓
Hız 2: 30 gün / 2 = 15 gün
Hız 14: 30 gün / 14 = 2.14 gün ⚠️ kritik
```

### PromQL
```promql
# 5 dakikalık error rate
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))

# Burn rate (hedef 99.9% → 0.001 error rate normal)
(error_rate_5m / 0.001)   # 1 = normal hız, 14 = 14x burn
```

---

## 📊 Multi-Window, Multi-Burn-Rate Alerts

> **Slow burn**: yavaş ama sürekli; **Fast burn**: ani spike.

### Google SRE Workbook formula
| Window | Burn Rate | Bütçe oranı | Aciliyet |
|---|---|---|---|
| **1 saat** | 14.4x | %2 (43dk × 14.4 / 30gün × 24saat) | Kritik (page) |
| **6 saat** | 6x | %5 | Yüksek (page) |
| **3 gün** | 1x | %10 | Orta (ticket) |

### Alert manifest
```yaml
groups:
  - name: payments-slo
    rules:
      # Fast burn (1 saat)
      - alert: PaymentsErrorBudgetFastBurn
        expr: |
          (
            sum(rate(http_requests_total{service="payments",status=~"5.."}[1h]))
            /
            sum(rate(http_requests_total{service="payments"}[1h]))
          ) > (0.001 * 14.4)
          and
          (
            sum(rate(http_requests_total{service="payments",status=~"5.."}[5m]))
            /
            sum(rate(http_requests_total{service="payments"}[5m]))
          ) > (0.001 * 14.4)
        for: 2m
        labels:
          severity: page
        annotations:
          summary: "Payments error budget fast burn (14.4x)"
          runbook_url: "<RUNBOOK>"

      # Slow burn (6 saat)
      - alert: PaymentsErrorBudgetSlowBurn
        expr: |
          (
            sum(rate(http_requests_total{service="payments",status=~"5.."}[6h]))
            /
            sum(rate(http_requests_total{service="payments"}[6h]))
          ) > (0.001 * 6)
        for: 15m
        labels:
          severity: page

      # Long burn (3 gün)
      - alert: PaymentsErrorBudgetLongBurn
        expr: |
          (
            sum(rate(http_requests_total{service="payments",status=~"5.."}[3d]))
            /
            sum(rate(http_requests_total{service="payments"}[3d]))
          ) > 0.001
        for: 1h
        labels:
          severity: ticket
```

> 🔑 **Multi-window** = false positive azalır + erken tespit.

---

## 📈 Error Budget Policy

### Policy örneği (yazılı)
```
Service: payments-api
SLO: 99.9% availability (30 gün rolling)
Error budget: 43 dakika / 30 gün

Bütçe durumu → eylem:
  > %50 (21+ dk kalan)  → Risk al, agresif feature deploy OK
  %20 - %50             → Normal velocity
  %5 - %20              → Slow down: sadece bug fix + perf iyileştirme
  %0 - %5               → Feature freeze
  < 0 (overspent)       → All hands on reliability
```

### Otomatik enforcement
```yaml
# ArgoCD sync gate
- alert: ErrorBudgetCritical
  expr: error_budget_remaining < 0.05
  annotations:
    action: "Auto-block prod deploys for {{ $labels.service }}"
```

→ Slack bot / GitOps gate ile prod deploy auto-block.

---

## 🛠️ Sloth — SLO YAML → Prometheus Rules

[Sloth](https://sloth.dev) SLO'yu YAML'da tanımla, Prometheus rules otomatik üretir.

```yaml
# slo.yaml
version: prometheus/v1
service: payments-api
labels:
  team: payments
slos:
  - name: availability
    objective: 99.9
    description: "99.9% successful HTTP requests over 30d"
    sli:
      events:
        error_query: |
          sum(rate(http_requests_total{service="payments",status=~"5.."}[{{.window}}]))
        total_query: |
          sum(rate(http_requests_total{service="payments"}[{{.window}}]))
    alerting:
      name: PaymentsAvailability
      page_alert:
        labels: {severity: page}
      ticket_alert:
        labels: {severity: ticket}

  - name: latency
    objective: 99.0   # 99% requests < 500ms
    description: "99% of requests served under 500ms"
    sli:
      events:
        # bad events = 500ms'den YAVAŞ istekler = toplam − (le=0.5 bucket'ı)
        # Sıra önemli: count − bucket; ters yazılırsa negatif çıkar ve burn-rate bozulur.
        error_query: |
          sum(rate(http_request_duration_seconds_count{service="payments"}[{{.window}}]))
          -
          sum(rate(http_request_duration_seconds_bucket{service="payments",le="0.5"}[{{.window}}]))
        total_query: |
          sum(rate(http_request_duration_seconds_count{service="payments"}[{{.window}}]))
```

```bash
sloth generate -i slo.yaml -o prometheus-rules.yaml
```

→ Multi-window burn alarm + recording rule otomatik üretilir.

---

## 🎯 SLI Çeşitleri

### 1. **Availability** (en yaygın)
```promql
sum(rate(http_requests_total{status!~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))
```

### 2. **Latency**
```promql
# %99 request < 500ms
histogram_quantile(0.99,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
)
```

### 3. **Throughput**
```promql
# Min RPS
sum(rate(http_requests_total[1m])) > 100
```

### 4. **Quality** (data correctness)
- Customer reports → "wrong order delivered"
- Application-level metric

### 5. **Freshness** (data pipeline)
```promql
# Son data ne kadar eski
time() - max(data_pipeline_last_processed_timestamp)
```

---

## 📋 SLO Yazımı — Pratik Adımlar

### 1. User journey'i belirle
"Kullanıcı için kritik akış nedir?"
- Login → Browse → Checkout → Payment

### 2. Her adım için SLI tanımla
- Login: 99% < 1s
- Browse: 99% < 500ms
- Checkout: 99.9% success
- Payment: 99.95% success

### 3. SLO döngüsü
- 30 gün rolling window
- Error budget = 1 - SLO

### 4. Alarm + dashboard
- Sloth ile auto-generate
- Grafana SLO dashboard

### 5. Quarterly review
- Bütçe yetiyor mu?
- Çok mu sıkı (boş overhead)?
- Çok mu gevşek (müşteri etkilemez)?

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| 100% uptime SLO | Matematiksel imkansız | %99.9 (sweet spot) |
| Average latency SLI | p99 outlier kaçar | Histogram p95/p99 |
| Single-window alert | False positive bombardımanı | Multi-window burn |
| Bütçe görünmez | Ekip dikkate almaz | Grafana dashboard |
| Bütçe overspent ignore | Reliability yatırım eksik | Feature freeze policy |
| SLO ürün-team ile konuşulmadı | "Bu ne demek?" | Joint review (Eng + PM) |
| Alert page severity yok | Spam | severity: page / warn / ticket |
| Recording rule yok | Slow dashboard | Pre-computed |
| Burn rate threshold tahmin | False positive | Google formula |
| SLO + SLA aynı | Müşteri SLA breach | SLO < SLA buffer |

---

## 📋 SLO Engineering Checklist

```
[ ] Critical user journey'leri tanımlı
[ ] Per-service SLO (availability + latency)
[ ] SLO < SLA (10-20% buffer)
[ ] Multi-window burn rate alarm (1h fast, 6h, 3d)
[ ] Error budget dashboard (Grafana)
[ ] Burn rate alarm severity (page / warn / ticket)
[ ] Sloth ile YAML → rule auto-generate
[ ] Error budget policy yazılı (deploy freeze rules)
[ ] Quarterly: SLO review (ürün ekibi ile)
[ ] Postmortem: bütçe etkisi raporlandı
[ ] Recording rules (precomputed)
[ ] SLO violation → action item tracking
[ ] Customer-facing status page SLO sayfası (opsiyonel)
```

---

## 📚 Referanslar

- **Google SRE Workbook** — Bölüm 5: Alerting on SLO
- **Sloth** — sloth.dev
- **Pyrra** — pyrra.dev (alternative SLO tool)
- **OpenSLO** — openslo.com (vendor-neutral spec)
- [`11-SRE/SLI-SLO-Error-Budget.md`](../11-SRE/SLI-SLO-Error-Budget.md)
- [`Prometheus-Best-Practices.md`](Prometheus-Best-Practices.md)
- [`Alerting-Done-Right.md`](Alerting-Done-Right.md)
- [`OpenTelemetry-Adoption.md`](OpenTelemetry-Adoption.md)
- [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md)

---

> *"SLO 'metric tanımla, hedef koy' değil — **multi-window burn
> rate + error budget policy**. Disipline edilmemiş SLO, ekibin
> 'iyi niyetidir', uygulanmaz."*

---

> 🎓 **Öğrenme Patikası:** Bu doküman [`E1`](../22-Learning-Path/block-e-ownership/E1-sli-slo-error-budget.md) modülünde "Önce oku" kaynağı olarak kullanılıyor.
