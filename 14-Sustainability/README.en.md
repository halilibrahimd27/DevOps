---
description: "Sustainable engineering and Green IT section index: guides on the GSF's 8 principles, carbon-aware computing, SCI measurement, low-carbon region selection, and efficiency practices."
tags:
  - Sustainability
  - FinOps
  - Kubernetes
  - Roadmap
---
# 14 · Sustainable Engineering / Green IT

> *"Software is **never** carbon-neutral; it's just CO₂ that you decided
> not to measure."* — Green Software Foundation

By 2026 it's a legal requirement: the EU CSRD and the US SEC climate rule mandate emissions reporting.
Cloud usage = Scope 2/3 emissions.

## Contents

| File | Topic |
|---|---|
| [`Green-Software-Principles.md`](Green-Software-Principles.md) | The GSF's 8 principles, how they translate into engineering decisions |
| [`Carbon-Aware-Computing.md`](Carbon-Aware-Computing.md) | The "run batch jobs during low-carbon hours" pattern |
| [`Measuring-Software-Carbon.md`](Measuring-Software-Carbon.md) | SCI formula, Cloud Carbon Footprint, Kepler |
| [`Region-Selection.md`](Region-Selection.md) | Regions with high renewable-energy density (cloud-specific) |
| [`Efficiency-Practices.md`](Efficiency-Practices.md) | ARM/Graviton, idle cleanup, caching, compression |

## Green Software Foundation's 8 principles

1. **Carbon Efficiency** — do the same work with less emission
2. **Energy Efficiency** — use fewer watts
3. **Carbon Awareness** — run at low-carbon times/places
4. **Hardware Efficiency** — use old hardware more efficiently
5. **Measurement** — you can't improve what you don't measure
6. **Climate Commitments** — back ambitious corporate climate commitments
7. **Networking** — data movement = energy; minimize it
8. **Demand Shaping** — design the application to flex against load

## SCI (Software Carbon Intensity) formula

```
SCI = ((E × I) + M) / R

E = Energy (kWh)              electricity consumed by the application
I = Carbon Intensity (gCO₂/kWh) carbon intensity of the electricity (region+hour)
M = Embodied carbon (gCO₂)    carbon embedded in hardware manufacturing
R = functional unit           1000 requests, 1 user, 1 transaction...

→ Unit: gCO₂eq / functional unit
→ Goal: minimize SCI (you can only reduce it, never increase it)
```

## Practical application

### Region selection (example — by emission intensity)

| Cloud | Low-carbon regions (~2026) |
|---|---|
| AWS | `eu-north-1` (Stockholm), `eu-west-3` (Paris), `us-west-2` (Oregon) |
| Azure | `Sweden Central`, `North Europe`, `France Central` |
| GCP | `europe-north1` (Finland), `europe-west1` (Belgium), `us-west1` (Oregon) |

> ⚠️ Emission intensity changes **in real time** (wind/solar generation). Validate
> regions against your cloud provider's "Customer Carbon Footprint Tool" output.

### Carbon-aware scheduling example

```yaml
# Idle batch job in CI — carbon-aware, run during low-emission hours
jobs:
  carbon-aware-rebuild:
    runs-on: ubuntu-latest
    if: ${{ steps.carbon.outputs.intensity == 'low' }}
    steps:
      - id: carbon
        uses: green-software-foundation/carbon-aware-action@v1
        with:
          location: 'eu-north-1'
          window: '6h'
      - run: ./expensive-rebuild.sh
```

### Quick wins

- ✅ Move to **ARM/Graviton instances** — 2-4x more efficient per watt
- ✅ **Spot instances** — use idle capacity, no new hardware manufactured
- ✅ Idle resource cleanup — an unused watt is a watt turned off
- ✅ **Compression** — fewer network bytes = less energy
- ✅ **CDN** — moving traffic away from origin = distance savings
- ✅ **Shut down** dev clusters **at night** (cron scaler)

## Anti-patterns

- ❌ "We buy carbon offsets" → no measurement, just marketing
- ❌ Constantly allocating `vCPU=4` but running at 5% utilization
- ❌ "Always-on" dev environments left running over the weekend
- ❌ Region selection based only on latency (carbon ignored)
- ❌ Logging everything and keeping it "just in case we need it"
