---
description: "Yazilim emisyonunu gercek metrige donusturen stack rehberi: SCI formulu, Cloud Carbon Footprint, Kepler eBPF ve AWS/GCP/Azure native karbon dashboard'lari adim adim."
---
# Measuring Software Carbon — SCI, Cloud Carbon Footprint, Kepler

> *"Yazılım karbonunu ölçmüyorsan, **azaltma iddiası boştur**.
> Excel'e 'green' yazmak yeter mi sorulduğunda CSRD '10 sayfalık
> emisyon raporu' der; auditor 'metric göster' der; sen ölçmemişsen
> **iddia + utanç**'la baş başa kalırsın."*

Bu rehber yazılım emisyonunu **gerçek metric**'e dönüştüren stack'i
— SCI formülü, Cloud Carbon Footprint, Kepler eBPF, AWS/GCP/Azure
native dashboard'lar — somut adımlarla anlatır.

---

## 🎯 SCI — Software Carbon Intensity

```
SCI = ((E × I) + M) / R

E = Energy (kWh)              uygulamanın tükettiği elektrik
I = Carbon Intensity           gCO₂eq/kWh (region+saat)
M = Embodied carbon            hardware lifecycle CO₂ (amorti)
R = Functional unit            request, user, transaction…

Birim: gCO₂eq / functional unit
```

> 🔑 **Hedef**: SCI'ı **azalt**, mutlak rakam değil. Year-over-year
> %20 azalma sağlam ilerleme.

### Örnek hesap (basit)
```
E = 100 kWh (1 hafta)
I = 250 gCO₂/kWh (eu-west-1 ortalama)
M = 1500 g (server lifecycle, 1 hafta amorti)
R = 10,000,000 request

SCI = (100 × 250 + 1500) / 10,000,000
    = 25,001,500 / 10,000,000
    = 2.5 gCO₂ / request
```

---

## 🛠️ E (Energy) Ölçümü

### Cloud — Bill-Based Estimation
| Tool | Yöntem | Cloud |
|---|---|---|
| **Cloud Carbon Footprint** | Billing + utilization → kWh tahmin | AWS, GCP, Azure |
| **AWS Customer Carbon Footprint Tool** | Native dashboard | AWS |
| **GCP Carbon Footprint** | Native | GCP |
| **Azure Emissions Impact Dashboard** | Native | Azure |

### On-prem / K8s — Kepler (eBPF)
**Kepler** kernel'da eBPF ile pod-level energy ölçer (RAPL: Running Average Power Limit + GPU sensor).

```bash
helm install kepler kepler/kepler \
  -n kepler --create-namespace \
  --set serviceMonitor.enabled=true
```

### Prometheus metrikler
```promql
# Pod başına joule (cumulative)
kepler_container_joules_total{pod_name="<POD>", container_name="<C>"}

# Namespace başına watt-saat (1 saat penceresinde)
sum by (namespace) (
  rate(kepler_container_joules_total[1h])
) / 3600

# CPU vs DRAM vs GPU dağılımı
kepler_container_package_joules_total   # CPU socket
kepler_container_dram_joules_total       # DRAM
kepler_container_gpu_joules_total        # GPU
```

> 🔑 **Kepler limit**: AMD CPU bazılarında RAPL erişimi yok →
> "estimation mode" (model-based). Intel'de gerçek ölçüm.

---

## 🛠️ I (Carbon Intensity) Veri Kaynağı

| Source | Coverage | Granularity |
|---|---|---|
| **ElectricityMaps API** | Global | Saatlik real-time + forecast |
| **WattTime** | US odaklı | 5-dakikalık |
| **Cloud-native** (AWS/GCP/Azure) | Vendor zone | Aylık ortalama |
| **National grid data** | UK, US, vb. | Saatlik |

### Cloud Carbon Footprint built-in
```bash
# Docker compose
docker-compose -f cloud-carbon-footprint/docker-compose.yml up

# UI: localhost:4000
```

Dashboard:
- AWS account başına emisyon
- Service başına (EC2 vs RDS vs S3)
- Region başına
- Daily trend
- Kubecost entegrasyonu (per-namespace)

---

## 🛠️ M (Embodied Carbon)

> Hardware'in **üretimden** gelen karbonu — server, switch, disk üretimi.

### Boavizta API
```bash
curl -X POST 'https://api.boavizta.org/v1/server/' \
  -H 'Content-Type: application/json' \
  -d '{
    "model": {"type": "rack"},
    "configuration": {
      "cpu": {"units": 2, "core_units": 32, "tdp": 200},
      "ram": [{"capacity": 256, "units": 12}],
      "disk": [{"type": "ssd", "capacity": 2000, "units": 4}]
    },
    "usage": {"hours_life_time": 35040, "usage_location": "DEU"}
  }'
```

```json
{
  "impacts": {
    "gwp": {"manufacture": 1500, "use": 7600, "unit": "kgCO2eq"}
  }
}
```

### Pratik hesaplama
- Server üretim: ~1500 kg CO₂eq
- Lifecycle: 4 yıl = 35,040 saat
- Per-saat: ~43 g CO₂

→ 1 saatte 1 server'a düşen embodied: 43 g.

---

## 🛠️ R (Functional Unit)

> "1 birim iş" sayımı. Domain'e bağlı:

| Workload | R |
|---|---|
| REST API | 1000 request |
| Veri işleme | 1 GB processed |
| ML inference | 1000 prediction |
| Storage | 1 TB-month |
| Streaming | 1000 saat watch |
| Build pipeline | 1 build |

### Ölçüm
```promql
# Aylık request sayısı
sum(increase(http_requests_total[30d]))

# Per-build (CI metric)
ci_pipeline_runs_total{status="success"}
```

---

## 📊 Tüm Stack: Birleştirelim

```
┌────────────────────────────────────────────────────────┐
│                    SCI Calculator                       │
│                                                         │
│   E (energy)      ← Kepler / CCF / cloud-native        │
│   I (intensity)   ← ElectricityMaps API                │
│   M (embodied)    ← Boavizta API                       │
│   R (units)       ← Prometheus app metrics             │
└────────────────────────────────────────────────────────┘
                          │
                          ▼
                  Per-service SCI
                          │
                          ▼
                Grafana Dashboard
                          │
                          ▼
         CSRD / SOC2 / ISO 14001 raporu
```

### Örnek Python hesaplama
```python
import requests

def calculate_sci(service: str, period_hours: int = 168):
    # E: Kepler
    energy_kwh = prometheus.query(
        f'sum(increase(kepler_container_joules_total{{namespace="{service}"}}[{period_hours}h])) / 3600000'
    )

    # I: ElectricityMaps
    intensity = requests.get(
        f'https://api.electricitymap.org/v3/carbon-intensity/latest?zone=DE',
        headers={'auth-token': EMAPS_TOKEN}
    ).json()['carbonIntensity']

    # M: Boavizta (cluster-level, per service'a böl)
    embodied_per_hour = 43   # g CO₂
    cluster_servers = 30
    service_share = 0.1      # %10 cluster usage
    embodied_g = embodied_per_hour * period_hours * cluster_servers * service_share

    # R: app metric
    requests_total = prometheus.query(
        f'sum(increase(http_requests_total{{service="{service}"}}[{period_hours}h]))'
    )

    sci = ((energy_kwh * intensity) + embodied_g) / (requests_total / 1000)
    return sci   # gCO₂ per 1000 requests
```

---

## 🎯 Grafana Dashboard

### Panels
1. **Cluster total emissions** (gCO₂/saat trend)
2. **Per-namespace** breakdown
3. **Top 10 carbon-heavy services**
4. **Service SCI trend** (target line ile)
5. **Energy mix** (CPU vs GPU vs DRAM)
6. **Region comparison**
7. **Carbon-aware savings** (time-shift gain)

### Örnek query'ler
```promql
# Cluster CO₂/saat
sum(rate(kepler_container_joules_total[1h])) / 3600000 * 250
# (250 = ortalama gCO₂/kWh)

# Per-namespace, top 10
topk(10, sum by (namespace) (rate(kepler_container_joules_total[1h])))

# SCI per service (custom metric)
service_sci_grams_per_1k_requests
```

---

## 📦 CSRD / Compliance Raporlama

### EU CSRD (Corporate Sustainability Reporting Directive)
- **Scope 1**: doğrudan emisyon (genelde yazılımda yok)
- **Scope 2**: alınan elektrik (cloud workload **buraya girer**)
- **Scope 3**: tedarik zinciri (vendor SaaS, hardware lifecycle)

### Raporlama formatı
```yaml
# Örnek: CSRD-uyumlu yıllık rapor
year: 2026
scope_2_emissions_kg:
  cloud_compute: 24000
  cloud_storage: 3500
  cloud_network: 2100
  total: 29600

scope_3_emissions_kg:
  hardware_embodied: 8000
  vendor_saas:
    github: 500
    datadog: 1200
    others: 800
  total: 10500

methodology: "GHG Protocol + GSF SCI"
data_sources:
  - "AWS Customer Carbon Footprint Tool"
  - "Kepler (K8s)"
  - "Boavizta (embodied)"

reduction_targets:
  baseline_year: 2024
  2030_target: -50%
  current_progress: -18%
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Sadece "carbon offset" alma, ölçüm yok | Real reduction değil, pazarlama | Ölç → azalt → kalanı offset |
| Cloud-native tool sayılarına güven sadece | Sadece o cloud'u kapsar | Multi-source aggregator (CCF) |
| Average intensity (yıllık) kullanma | Real-time eksik | Saatlik ElectricityMaps |
| M (embodied) ihmal | Toplam %20-30 kayıp | Boavizta API ile dahil et |
| R (functional unit) tanımlanmamış | SCI hesaplanamaz | Per-workload "1 birim iş" tanımı |
| Ölçüm var, target yok | İyileşme görünmez | Year-over-year hedef |
| ESG ekibi tek başına | Mühendis dahil değil | Joint dashboard, ortak hedef |
| Kepler'siz K8s'de tahmin yok | Pod-level yok | Kepler veya equivalent |
| Trend takibi yok | Bir kerelik rapor → eskimiş | Grafana sürekli |
| Yıllık rapor manuel | Hata + zaman israfı | Otomatik aggregator |
| AI/ML ihmal | LLM training devasa | Ayrı kategori, GPU energy ayrı raporla |

---

## 📋 Software Carbon Measurement Checklist

```
[ ] Cloud Carbon Footprint kurulu (multi-cloud aggregator)
[ ] Kepler (K8s pod-level energy) — Intel cluster'larda
[ ] ElectricityMaps API token (real-time intensity)
[ ] Boavizta API embodied carbon
[ ] Per-service SCI hesaplanıyor
[ ] R (functional unit) her workload için tanımlı
[ ] Grafana sustainability dashboard
[ ] Year-over-year reduction target (örn: -20%)
[ ] AI/ML workload'lar ayrı kategori (GPU energy)
[ ] CSRD-ready rapor şablonu
[ ] Quarterly review: yöneticilere trend
[ ] Mühendis on-boarding: SCI farkındalığı
[ ] Vendor SaaS Scope 3 envanter
[ ] Hardware lifecycle politikası (4-5 yıl + refurbish)
[ ] CDN / cache strategy ile network carbon
[ ] Region selection matrix (carbon dahil)
```

---

## 📚 Referanslar

- **GSF SCI Specification** — sci.greensoftware.foundation
- **Cloud Carbon Footprint** — cloudcarbonfootprint.org
- **Kepler** — sustainable-computing.io
- **Boavizta** — boavizta.org
- **ElectricityMaps** — electricitymaps.com
- **AWS Customer Carbon Footprint Tool**
- **GCP Carbon Footprint**
- **Azure Emissions Impact Dashboard**
- **GHG Protocol** — ghgprotocol.org
- **CSRD (EU)** — finance.ec.europa.eu/csrd
- [`Green-Software-Principles.md`](Green-Software-Principles.md)
- [`Carbon-Aware-Computing.md`](Carbon-Aware-Computing.md)
- [`Region-Selection.md`](Region-Selection.md)

---

> *"Ölçmediğin şeyi azaltamazsın. **SCI** yazılım karbonunu **CI'da
> pass/fail metric'e** indirgeyebilen tek araç. CSRD raporlamasını
> 'sayfalar dolusu metin' yerine **dashboard çıktısı** yapan disiplin."*
