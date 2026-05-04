# Reserved Instances & Savings Plans — Long-Term Commitment

> *"On-demand prod kullanan ekip, **3 yıl Reserved** alabilirdi
> %50-70 daha ucuza. 'Lock-in' bahanesi $X kayıp. Doğru forecast
> + **commitment ladder** = guaranteed tasarruf."*

Bu rehber AWS Reserved Instances (RI), Savings Plans (SP), GCP CUDs,
Azure Reservations için pratik strateji ve nasıl over-commit'ten
kaçınılır anlatır.

---

## 📊 Cloud Commitment Tipleri

| Tip | AWS | GCP | Azure |
|---|---|---|---|
| **Compute discount** | EC2 RI / Compute SP | CUDs | Reservations |
| **DB discount** | RDS RI | CUDs | SQL Reservations |
| **Storage** | S3 reserved | - | - |

### AWS spesifik
| Type | İndirim | Esneklik |
|---|---|---|
| **EC2 Standard RI** | %40-50 | Düşük (instance type fixed) |
| **EC2 Convertible RI** | %30-40 | Orta (type değişebilir) |
| **Compute Savings Plan** | %40-66 | Yüksek (any region/family) |
| **EC2 Instance Savings Plan** | %50-72 | Düşük (specific region) |

> 🔑 **2026 önerisi**: Compute Savings Plan (esneklik) > Standard RI.

---

## 🎯 Commitment Stratejisi

### Adım 1: Baseline workload'u belirle
- "12 ayda **kesin** çalışacak min capacity ne?"
- Production servisler, kritik workload
- Spot/preemptible olabilen workload **hariç**

### Adım 2: Forecast (12-36 ay)
- Mevcut growth rate
- Yeni feature roadmap
- Müşteri base değişimi

### Adım 3: Commitment ladder
```
Year 1: %50 baseline → 1-yıl SP (medium upfront)
Year 1+1: %70 baseline → 1-yıl SP renewal + ek
Year 1+2: %80 baseline → 3-yıl SP (highest discount)
```

> 🔑 **Aşamalı commitment** → over-commit riski azaltır.

### Adım 4: Spot + RI hibrit
```
Workload composition:
  Stateful DB → On-demand veya RI (1-yıl)
  Stateless prod replica → SP (60% baseline) + on-demand (peak)
  Background batch → Spot
  Dev/staging → Spot
```

---

## 💰 Commitment vs Pay-As-You-Go

```
m5.large baseline (1 instance, 24/7):
  On-demand:       $0.096 × 720 = $69/ay
  1-yr no upfront: $0.060 × 720 = $43/ay  (%38 tasarruf)
  3-yr no upfront: $0.040 × 720 = $29/ay  (%58 tasarruf)
  3-yr all upfront: $24/ay equivalent     (%65 tasarruf)
```

### Upfront seçenekleri
| Type | Cash flow | İndirim |
|---|---|---|
| **No upfront** | Aylık eşit | Düşük |
| **Partial upfront** | %40 başta + aylık | Orta |
| **All upfront** | %100 başta | En yüksek |

> 💸 **All upfront**: cash flow uygunsa en iyi, %3-5 ekstra indirim.

---

## 🛡️ Over-Commit Riski

### Senaryo
```
Year 0: 3-yr SP $1M commitment, 100 instances
Year 1: Workload migration → 50 instance yeterli
Year 2: $500K boş commitment (kullanılmıyor)
```

### Mitigasyon
1. **Aşamalı commitment ladder** (yukarıda)
2. **Convertible RI** (sell on AWS Marketplace)
3. **Partial commitment**: %50-70 baseline (peak için on-demand)
4. **Quarterly review**: gerçek kullanım vs commit

---

## 📊 AWS Cost Explorer — Recommendation

```bash
# Compute Savings Plan recommendation
aws ce get-savings-plans-purchase-recommendation \
  --savings-plans-type COMPUTE_SP \
  --term-in-years ONE_YEAR \
  --payment-option NO_UPFRONT \
  --lookback-period-in-days SIXTY_DAYS
```

→ AWS önerir: "$X yıllık commitment ile $Y tasarruf".

### Continuous monitoring
- **AWS Cost Explorer** → coverage % (commitment kullanım oranı)
- < %85 coverage → over-committed (boş para)
- < %70 → satın al daha fazla SP

---

## 🌍 GCP CUDs (Committed Use Discounts)

```bash
gcloud compute commitments create my-commitment \
  --project=<PROJECT> \
  --region=<REGION> \
  --plan=THIRTY_SIX_MONTH \
  --resources=vcpu=10,memory=40
```

| Term | İndirim |
|---|---|
| 1 yıl | %25-37 |
| 3 yıl | %52-70 |

> GCP CUDs **resource-based** (vCPU + memory), AWS RI/SP'den biraz farklı.

---

## ☁️ Azure Reservations

| Tip | İndirim |
|---|---|
| 1-yıl Reservation | %35-40 |
| 3-yıl Reservation | %55-65 |

```bash
az reservations reservation-order list
```

---

## 📈 Coverage Dashboard

```promql
# Custom: AWS Cost Explorer API → Prometheus
aws_cost_explorer_savings_plans_coverage_percentage
```

### Hedefler
- **Coverage %**: 70-85% (over değil, under değil)
- **Utilization %**: > 95% (commitment'ın kullanılan kısmı)
- **On-demand %**: < 30% (peak buffer için)

### Quarterly review
1. Coverage: %70'in altı → daha fazla SP al
2. Coverage: %95+ → over-committed, peak'i kaybediyor olabilir
3. Yeni SP ihtiyacı: 30+ gün steady on-demand pattern

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tüm prod on-demand | %50-70 fazla ödenir | SP + spot mix |
| %100 commit (no peak buffer) | Spike'da capacity yetmez | %70-80 commit |
| Standard RI Convertible yerine | Lock-in | Compute SP / Convertible |
| 3-yr commit greenfield | Workload değişiyor | 1-yr ladder |
| Coverage tracking yok | Over/under-commit | Quarterly review |
| All-upfront cash flow olmadan | Liquidity sorun | No-upfront veya partial |
| Commitment yok, "spot var zaten" | Spot interruption + commit ayrı niche | Birlikte kullan |
| Account başına commit | Global pool kayıp | Organization-wide SP (consolidated) |
| RI marketplace satışı bilmemek | Over-commit kayıp | Convertible + sell |

---

## 📋 Commitment Strategy Checklist

```
[ ] Baseline workload analizi (12 ay)
[ ] Forecast: growth + feature roadmap
[ ] Commitment ladder plan (1-yr → 3-yr aşamalı)
[ ] %70-80 baseline commit (peak buffer)
[ ] Compute SP > Standard RI (esneklik)
[ ] Coverage dashboard
[ ] Quarterly review (under/over-commit)
[ ] Convertible RI (esneklik için)
[ ] Marketplace sell strateji (over-commit fallback)
[ ] Hibrit: SP (steady) + spot (batch) + on-demand (peak)
[ ] Multi-account: org-wide SP pool
[ ] Budget alarm (commit + actual)
[ ] Annual: commitment review yöneticilere
```

---

## 📚 Referanslar

- **AWS Savings Plans** — aws.amazon.com/savingsplans
- **AWS Cost Explorer** — aws.amazon.com/aws-cost-management/
- **GCP CUDs** — cloud.google.com/compute/docs/instances/signing-up-committed-use-discounts
- **Azure Reservations** — azure.microsoft.com/en-us/pricing/reserved-vm-instances
- **FinOps Foundation** — finops.org
- [`Cloud-Cost-Allocation.md`](Cloud-Cost-Allocation.md)
- [`Right-Sizing.md`](Right-Sizing.md)
- [`Spot-Instance-Strategy.md`](Spot-Instance-Strategy.md)
- [`Kubecost-Setup.md`](Kubecost-Setup.md)

---

> *"Reserved/Savings Plan **'lock-in'** değil — **forecasted commitment**.
> Right-size + spot + commit üçlüsü ile cloud bill'i **%40-60**
> azaltılabilir. Hiçbiri yapmayan ekip, **on-demand fiyatına**
> overpay ediyor."*
