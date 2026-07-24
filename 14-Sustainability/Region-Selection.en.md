---
description: "A guide comparing AWS, GCP, and Azure regions by carbon intensity; building a low-carbon region decision matrix with latency, cost, and data-residency trade-offs."
tags:
  - Sustainability
  - AWS
  - Cost Optimization
  - Compliance
  - KVKK
---
# Region Selection — Cloud Region Carbon Decision Matrix

> *"Running the same workload in Stockholm instead of Frankfurt cuts
> emissions by %60 — **for free**. Latency increases 10ms, the customer
> won't notice, but the company's Scope 2 report **drops dramatically**."*

This guide compares AWS, GCP, and Azure regions by **carbon
intensity**, explains how to evaluate the latency/cost/data-residency
trade-off, and shows how to build a decision matrix.

---

## 🎯 How "Green" Is a Cloud Region?

```
[Region]
   │
   ├── Electric grid (coal/gas/wind/solar/nuclear/hydro mix)
   ├── Cloud provider's PPA (Power Purchase Agreement) — renewable contracts
   ├── PUE (Power Usage Effectiveness) — datacenter efficiency
   └── Cooling source (water / air / free cooling)
```

> 🔑 **Carbon intensity varies 5-10x by region.** Annual average
> ranges from 20-800 g CO₂/kWh.

---

## 📊 2026 Low-Carbon Regions

### AWS
| Region | City | Approximate intensity (g/kWh) | Notes |
|---|---|---|---|
| `eu-north-1` | Stockholm | 20-40 | Hydro + nuclear |
| `eu-west-3` | Paris | 50-90 | Nuclear-heavy |
| `us-west-2` | Oregon | 100-200 | Hydro + some gas |
| `ca-central-1` | Montreal | 30-60 | Hydro |
| `eu-west-1` | Ireland | 200-350 | Wind, but gas too |
| `eu-central-1` | Frankfurt | 350-500 | Mixed, gas/coal present |
| `ap-southeast-3` | Jakarta | 700-900 | Coal-heavy ❌ |
| `cn-north-1` | Beijing | 600-800 | Coal ❌ |

### GCP
| Region | City | Approximate intensity |
|---|---|---|
| `europe-north1` | Hamina, FI | 30-60 |
| `europe-west1` | Belgium | 100-200 |
| `europe-west4` | Netherlands | 200-300 |
| `us-west1` | Oregon | 100-200 |
| `us-central1` | Iowa | 400-500 |

### Azure
| Region | City | Approximate intensity |
|---|---|---|
| `swedencentral` | Sandviken | 20-40 |
| `northeurope` | Dublin | 200-350 |
| `francecentral` | Paris | 50-100 |
| `westus2` | Washington | 100-200 |

> ⚠️ These figures are **periodic averages**. For real-time data, use the ElectricityMaps API.

---

## ⚖️ Decision Matrix — 4 Dimensions

| Dimension | Question |
|---|---|
| **Latency** | Close to customers? |
| **Cost** | Price difference per region? |
| **Data Residency** | Legal requirement (KVKK/GDPR)? |
| **Carbon** | Carbon intensity? |

### Decision matrix table (example: TR customer)
| Region | Latency (ms) | Cost ($/CPU-h) | Residency | Carbon (g/kWh) |
|---|---|---|---|---|
| eu-central-1 (Frankfurt) | 50 | 0.045 | EU ✅ | 400 |
| eu-west-1 (Ireland) | 70 | 0.040 | EU ✅ | 280 |
| eu-north-1 (Stockholm) | 90 | 0.039 | EU ✅ | **30** |
| eu-west-3 (Paris) | 70 | 0.043 | EU ✅ | 80 |

> 🎯 **Decision**: From Turkey, eu-north-1 (Stockholm) — latency 90ms, the
> customer tolerates it, **carbon is 13x lower**. Cost is also 15% cheaper.

---

## 🌳 Decision Flow

```
1. Which customer segment? Latency sensitivity?
   - < 100ms required → nearby region
   - 100-300ms tolerable → distant region OK

2. Is there a legal data residency requirement?
   - KVKK/GDPR → EU
   - Health data → additional restrictions (in-country)

3. Carbon-aware option?
   - Lowest carbon within the same residency

4. Compare cost
   - Green regions are usually cheaper (subsidized renewable)

5. Multi-region need?
   - Pick a green second region for DR too
```

---

## 🛠️ Migrating an Existing Workload

### Phased plan
```
1. Week — Audit
   - Which workloads are in the current region?
   - Latency-sensitive vs tolerant?
   - Is data residency mandatory?

2-4. Week — Plan
   - Pick target region (using the decision matrix)
   - Migration plan: state, secrets, data
   - Cost modeling

5-12. Week — Migrate
   - Stateless workloads first (easy)
   - DB last (replica → switchover)
   - DNS / CDN routing
   - Phased: 10% → 50% → 100%

13. Week — Sunset
   - Shut down the old region
   - Cost saving + carbon saving report
```

### Feasible migration candidates
| Workload | Migration difficulty |
|---|---|
| CI runner | Low (stateless) |
| Backup storage | Low (object store) |
| ML training | Low (batch) |
| Stateless API | Medium (DNS, app config) |
| Database | High (state, downtime) |
| User-facing primary | High (latency impact) |

> 🔑 **First target**: ML training + batch + backup. **Last**: user-facing DB.

---

## 📊 Real-Time Region Selection (Carbon-Aware)

### Multi-region replica + dynamic routing
```python
# Pseudocode: ML training scheduler
import requests

def select_best_region(zones=['DE', 'SE', 'FR', 'IE']):
    intensities = {}
    for zone in zones:
        r = requests.get(
            f'https://api.electricitymap.org/v3/carbon-intensity/latest?zone={zone}',
            headers={'auth-token': TOKEN}
        ).json()
        intensities[zone] = r['carbonIntensity']
    
    return min(intensities, key=intensities.get)

# Job submit
zone = select_best_region()
region = ZONE_TO_REGION[zone]   # SE → eu-north-1
submit_training_job(region=region)
```

### KEDA + carbon scaler (see the Carbon-Aware-Computing guide above)
- Per-region replica
- Scale up the low-carbon one
- Scale the high-carbon one to zero

---

## 🌍 Turkey-Specific — The "Local Cloud" Debate

### Cloud regions in Turkey (2026)
- **AWS Turkey**: none (there's lobbying, may come soon)
- **Azure Turkey**: coming soon (announced)
- **GCP Turkey**: none
- **Local cloud providers**: Turkcell, Türk Telekom, Vodafone

### KVKK + data residency
- Public sector: data may be required to stay within Turkey
- Private B2B: generally OK in the EU under KVKK (assessed as adequate protection)

### Local provider vs. hyperscale
| Dimension | Local | Hyperscale (AWS/GCP/Azure) |
|---|---|---|
| Latency | Low | Medium-high (Frankfurt 50ms) |
| Cost | Usually lower | Spot pricing available |
| Service variety | Limited | Broad |
| Carbon transparency | Low | High |
| Renewable PPA | Unclear | Disclosed |
| KVKK compliance | ✅ In-country | ⚠️ Adequate protection + SCC |

> 🔑 In practice: most workloads are fine in EU regions. For public
> sector or sensitive TR-only data, use local cloud + EU DR.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Region choice based only on latency | Carbon neglected | 4-dimension decision matrix |
| Automatic "default region" | eu-central on day one, forever after | Deliberate choice |
| No carbon transparency from the vendor | You can't measure it | Ask for vendor certifications |
| US region + EU customer | Schrems II / GDPR violation | EU residency |
| TR-only data in an EU region | KVKK interpretation risk | Legal review + SCC + technical safeguard |
| Big-bang migration | Breaks production | Phased + canary |
| No multi-region failover set up | DR gap | 2 regions per cloud, per residency |
| Carbon-aware limited to batch only | Also possible for stateless APIs | Multi-region routing |
| Choosing local cloud just because it's "national" | No carbon transparency | Hold it to the same discipline |
| Cost counted as compute only | Network egress ignored | TCO: compute + network + storage |

---

## 📋 Region Selection Checklist

```
[ ] 4-dimension decision matrix (latency + cost + residency + carbon)
[ ] Real-time carbon intensity (ElectricityMaps token)
[ ] Cloud Carbon Footprint dashboard
[ ] Vendor PPA / renewable transparency documentation
[ ] Data residency: KVKK + GDPR compliance check
[ ] Multi-region: at least 2 green regions (DR + carbon-aware)
[ ] Migration plan: phased (stateless → stateful)
[ ] Latency baseline: for customer segments
[ ] Cost comparison: same workload in different regions
[ ] Annual: region review (any new green regions?)
[ ] Quarterly: carbon report (emissions per region)
[ ] CI/CD: region-change policy gate (prevent accidentally picking a coal region)
```

---

## 📚 References

- **AWS Sustainability** — sustainability.aboutamazon.com
- **GCP Carbon-Free Energy %** — cloud.google.com/sustainability
- **Azure Sustainability** — azure.microsoft.com/en-us/global-infrastructure/sustainability
- **ElectricityMaps** — electricitymaps.com
- **The Green Web Foundation — Carbon.txt** — thegreenwebfoundation.org
- [`Green-Software-Principles.md`](Green-Software-Principles.md)
- [`Carbon-Aware-Computing.md`](Carbon-Aware-Computing.md)
- [`Measuring-Software-Carbon.md`](Measuring-Software-Carbon.md)
- [`19-Compliance/KVKK-Practical.md`](../19-Compliance/KVKK-Practical.md) — data residency
- [`12-FinOps/Cloud-Cost-Allocation.md`](../12-FinOps/Cloud-Cost-Allocation.md) — TCO

---

> *"Region selection isn't an 'infrastructure preference' — it's a
> **carbon strategy decision**. Choosing a green region is a
> one-click, **20-50% emission gain**: a green practice that requires
> no code change and applies **instantly**."*
