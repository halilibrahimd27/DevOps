---
description: "A guide to the stack that turns software emissions into real metrics: the SCI formula, Cloud Carbon Footprint, Kepler eBPF, and AWS/GCP/Azure native carbon dashboards, step by step."
tags:
  - Sustainability
  - Observability
  - Prometheus
  - Compliance
  - FinOps
---
# Measuring Software Carbon — SCI, Cloud Carbon Footprint, Kepler

> *"If you're not measuring software carbon, **any reduction claim is empty**.
> When asked whether writing 'green' in Excel is enough, CSRD says 'submit a
> 10-page emissions report'; the auditor says 'show me the metric'; if you
> haven't measured, you're left holding **a claim and the shame**."*

This guide walks through the stack that turns software emissions into a
**real metric** — the SCI formula, Cloud Carbon Footprint, Kepler eBPF,
AWS/GCP/Azure native dashboards — with concrete steps.

---

## 🎯 SCI — Software Carbon Intensity

```
SCI = ((E × I) + M) / R

E = Energy (kWh)              electricity consumed by the application
I = Carbon Intensity           gCO₂eq/kWh (region+hour)
M = Embodied carbon            hardware lifecycle CO₂ (amortized)
R = Functional unit            request, user, transaction…

Unit: gCO₂eq / functional unit
```

> 🔑 **Goal**: **reduce** SCI — it's not about the absolute number. A
> year-over-year 20% reduction is solid progress.

### Example calculation (simple)
```
E = 100 kWh (1 week)
I = 250 gCO₂/kWh (eu-west-1 average)
M = 1500 g (server lifecycle, 1 week amortized)
R = 10,000,000 requests

SCI = (100 × 250 + 1500) / 10,000,000
    = 25,001,500 / 10,000,000
    = 2.5 gCO₂ / request
```

---

## 🛠️ E (Energy) Measurement

### Cloud — Bill-Based Estimation
| Tool | Method | Cloud |
|---|---|---|
| **Cloud Carbon Footprint** | Billing + utilization → kWh estimate | AWS, GCP, Azure |
| **AWS Customer Carbon Footprint Tool** | Native dashboard | AWS |
| **GCP Carbon Footprint** | Native | GCP |
| **Azure Emissions Impact Dashboard** | Native | Azure |

### On-prem / K8s — Kepler (eBPF)
**Kepler** measures pod-level energy in the kernel via eBPF (RAPL: Running Average Power Limit + GPU sensors).

```bash
helm install kepler kepler/kepler \
  -n kepler --create-namespace \
  --set serviceMonitor.enabled=true
```

### Prometheus metrics
```promql
# Joules per pod (cumulative)
kepler_container_joules_total{pod_name="<POD>", container_name="<C>"}

# Watt-hours per namespace (over a 1-hour window)
sum by (namespace) (
  rate(kepler_container_joules_total[1h])
) / 3600

# CPU vs DRAM vs GPU breakdown
kepler_container_package_joules_total   # CPU socket
kepler_container_dram_joules_total       # DRAM
kepler_container_gpu_joules_total        # GPU
```

> 🔑 **Kepler limitation**: some AMD CPUs have no RAPL access →
> falls back to "estimation mode" (model-based). Intel gives real measurement.

---

## 🛠️ I (Carbon Intensity) Data Sources

| Source | Coverage | Granularity |
|---|---|---|
| **ElectricityMaps API** | Global | Hourly real-time + forecast |
| **WattTime** | US-focused | 5-minute |
| **Cloud-native** (AWS/GCP/Azure) | Vendor zone | Monthly average |
| **National grid data** | UK, US, etc. | Hourly |

### Cloud Carbon Footprint built-in
```bash
# Docker compose
docker-compose -f cloud-carbon-footprint/docker-compose.yml up

# UI: localhost:4000
```

Dashboard:
- Emissions per AWS account
- Per service (EC2 vs RDS vs S3)
- Per region
- Daily trend
- Kubecost integration (per-namespace)

---

## 🛠️ M (Embodied Carbon)

> Carbon that comes from **manufacturing** hardware — producing servers, switches, disks.

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

### Practical calculation
- Server manufacturing: ~1500 kg CO₂eq
- Lifecycle: 4 years = 35,040 hours
- Per hour: ~43 g CO₂

→ Embodied carbon per server per hour: 43 g.

---

## 🛠️ R (Functional Unit)

> Counting "1 unit of work." Depends on the domain:

| Workload | R |
|---|---|
| REST API | 1000 requests |
| Data processing | 1 GB processed |
| ML inference | 1000 predictions |
| Storage | 1 TB-month |
| Streaming | 1000 hours watched |
| Build pipeline | 1 build |

### Measurement
```promql
# Monthly request count
sum(increase(http_requests_total[30d]))

# Per-build (CI metric)
ci_pipeline_runs_total{status="success"}
```

---

## 📊 The Full Stack: Putting It Together

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
         CSRD / SOC2 / ISO 14001 report
```

### Example Python calculation
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

    # M: Boavizta (cluster-level, split per service)
    embodied_per_hour = 43   # g CO₂
    cluster_servers = 30
    service_share = 0.1      # 10% cluster usage
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
1. **Cluster total emissions** (gCO₂/hour trend)
2. **Per-namespace** breakdown
3. **Top 10 carbon-heavy services**
4. **Service SCI trend** (with target line)
5. **Energy mix** (CPU vs GPU vs DRAM)
6. **Region comparison**
7. **Carbon-aware savings** (time-shift gain)

### Example queries
```promql
# Cluster CO₂/hour
sum(rate(kepler_container_joules_total[1h])) / 3600000 * 250
# (250 = average gCO₂/kWh)

# Per-namespace, top 10
topk(10, sum by (namespace) (rate(kepler_container_joules_total[1h])))

# SCI per service (custom metric)
service_sci_grams_per_1k_requests
```

---

## 📦 CSRD / Compliance Reporting

### EU CSRD (Corporate Sustainability Reporting Directive)
- **Scope 1**: direct emissions (usually none in software)
- **Scope 2**: purchased electricity (cloud workload **falls here**)
- **Scope 3**: supply chain (vendor SaaS, hardware lifecycle)

### Reporting format
```yaml
# Example: CSRD-compliant annual report
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

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Buying only "carbon offsets," no measurement | Not real reduction, just marketing | Measure → reduce → offset the remainder |
| Trusting only cloud-native tool numbers | Covers only that one cloud | Multi-source aggregator (CCF) |
| Using average (annual) intensity | Misses real-time variation | Hourly ElectricityMaps |
| Neglecting M (embodied) | Loses 20-30% of the total | Include it via the Boavizta API |
| R (functional unit) undefined | SCI can't be calculated | Define "1 unit of work" per workload |
| Measurement exists, no target | Improvement is invisible | Year-over-year target |
| ESG team acting alone | Engineers not involved | Joint dashboard, shared target |
| No estimation in K8s without Kepler | No pod-level visibility | Kepler or equivalent |
| No trend tracking | A one-off report goes stale | Continuous Grafana |
| Annual report done manually | Errors + wasted time | Automated aggregator |
| Neglecting AI/ML | LLM training is massive | Separate category, report GPU energy separately |

---

## 📋 Software Carbon Measurement Checklist

```
[ ] Cloud Carbon Footprint installed (multi-cloud aggregator)
[ ] Kepler (K8s pod-level energy) — on Intel clusters
[ ] ElectricityMaps API token (real-time intensity)
[ ] Boavizta API embodied carbon
[ ] Per-service SCI calculated
[ ] R (functional unit) defined for every workload
[ ] Grafana sustainability dashboard
[ ] Year-over-year reduction target (e.g., -20%)
[ ] AI/ML workloads in a separate category (GPU energy)
[ ] CSRD-ready report template
[ ] Quarterly review: trend shared with management
[ ] Engineer onboarding: SCI awareness
[ ] Vendor SaaS Scope 3 inventory
[ ] Hardware lifecycle policy (4-5 years + refurbish)
[ ] Network carbon addressed via CDN / cache strategy
[ ] Region selection matrix (carbon included)
```

---

## 📚 References

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

> *"You can't reduce what you don't measure. **SCI** is the one tool
> that reduces software carbon to a **pass/fail metric in CI**. It turns
> CSRD reporting into **dashboard output** instead of 'pages of text.'"*
