---
description: "Carbon-aware workload scheduling guide: choosing when and where a job runs based on the grid's real-time carbon intensity, with real-time APIs and K8s/CI examples."
tags:
  - Sustainability
  - Kubernetes
  - CI/CD
  - FinOps
---
# Carbon-Aware Computing — Run in the Low-Carbon Hour

> *"Running the same job on a windy night versus a fossil-fuel-heavy
> afternoon — **a 5x difference in CO₂**. The engineer who can choose
> the time + place of a workload holds the **controls of emission
> reduction**."*

This guide covers **carbon-aware** workload scheduling patterns,
real-time carbon-intensity APIs, and how to apply them in K8s/CI with
concrete examples.

---

## 🎯 What Is Carbon-Aware Computing?

> **Carbon-Aware**: choosing **when** and **where** a job runs based on
> the electric grid's **real-time carbon intensity**.

```
[Workload]
    │
    ├── Time-shift: "carbon is heavy now, run in 3 hours"
    │   (batch jobs, night wind, daytime sun)
    │
    └── Location-shift: "run in Stockholm instead of Frankfurt"
        (different carbon intensity per region)
```

---

## 📊 What Is Carbon Intensity?

> **Carbon Intensity**: **how many grams of CO₂** are emitted to
> generate 1 kWh of electricity? (g CO₂eq/kWh)

| Source | Approximate intensity |
|---|---|
| Hydroelectric | 5-50 |
| Nuclear | 5-20 |
| Wind | 10-15 |
| Solar | 50-90 |
| Natural gas | 400-500 |
| Coal | 800-1000+ |

### Region changes in real time
- **Germany**: 200-600 g/kWh depending on the hour of day
- **Stockholm**: 20-50 g/kWh (hydro + nuclear heavy)
- **Poland**: 600-800 g/kWh (coal heavy)
- **Texas**: 300-500 g/kWh (wind/gas mixed)

---

## 🛠️ Carbon Intensity APIs

| API | Coverage | Cost |
|---|---|---|
| **ElectricityMaps** | Global | Free tier + commercial |
| **WattTime** | US heavy | Free + paid |
| **Carbon Aware SDK** (Microsoft/GSF) | Multi-source aggregator | Free, OSS |
| **AWS Customer Carbon Footprint Tool** | AWS | Free, AWS only |
| **GCP Carbon Footprint** | GCP | Free, GCP only |

### ElectricityMaps API
```bash
curl "https://api.electricitymap.org/v3/carbon-intensity/latest?zone=DE" \
  -H "auth-token: <TOKEN>"
```

```json
{
  "zone": "DE",
  "carbonIntensity": 425,
  "datetime": "2026-05-04T14:00:00.000Z",
  "updatedAt": "2026-05-04T14:05:00.000Z",
  "emissionFactorType": "lifecycle",
  "isEstimated": false,
  "estimationMethod": null
}
```

```bash
# Forecast (next 24 hours)
curl "https://api.electricitymap.org/v3/carbon-intensity/forecast?zone=DE" \
  -H "auth-token: <TOKEN>"
```

---

## 🕐 Pattern 1: Time-Shifting (Batch Job)

> "The ideal cron is 02:00, but the electricity is cleaner at that hour."

### With GitHub Actions
```yaml
name: Carbon-Aware ML Training

on:
  schedule:
    - cron: '0 1 * * *'   # first attempt at 01:00
  workflow_dispatch:

jobs:
  check-carbon:
    runs-on: ubuntu-latest
    outputs:
      should_run: ${{ steps.check.outputs.should_run }}
    steps:
      - id: check
        run: |
          INTENSITY=$(curl -s "https://api.electricitymap.org/v3/carbon-intensity/latest?zone=DE" \
            -H "auth-token: ${{ secrets.EMAPS_TOKEN }}" \
            | jq '.carbonIntensity')

          if [ "$INTENSITY" -lt 200 ]; then
            echo "should_run=true" >> $GITHUB_OUTPUT
          else
            echo "should_run=false" >> $GITHUB_OUTPUT
            echo "Carbon intensity $INTENSITY > 200, deferred"
          fi

  ml-training:
    needs: check-carbon
    if: needs.check-carbon.outputs.should_run == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>
      - run: ./train.sh
```

### Carbon Aware SDK
```yaml
# GitHub Actions
- uses: green-software-foundation/carbon-aware-sdk-action@<VERSION>
  with:
    location: 'eu-north-1'
    duration: '60'   # a 60-minute job
    window: '6h'     # find a suitable time within 6 hours
  id: carbon

- name: Wait until best time
  run: sleep ${{ steps.carbon.outputs.wait_seconds }}

- name: Run job
  run: ./expensive-task.sh
```

---

## 🌍 Pattern 2: Location-Shifting

### Multi-region replicas
The workload is ready in **more than one region** → route it to the lowest carbon intensity.

```yaml
# Example: ML training across EKS clusters
# eu-north-1 (Stockholm) ↔ eu-central-1 (Frankfurt) ↔ us-west-2 (Oregon)

# Fetch each region's carbon intensity
INTENSITIES=$(for region in eu-north-1 eu-central-1 us-west-2; do
  ZONE=$(map_region_to_zone "$region")
  INTENSITY=$(curl -s ".../carbon-intensity/latest?zone=$ZONE" -H "auth-token: $TOKEN" | jq '.carbonIntensity')
  echo "$region $INTENSITY"
done)

# Pick the lowest
BEST=$(echo "$INTENSITIES" | sort -k2 -n | head -1 | awk '{print $1}')

# Send the job there
kubectl --context $BEST apply -f training-job.yaml
```

> 🔑 **If it's not latency-critical**, location-shift is a big win — especially for batch.

---

## ⚡ Pattern 3: Demand Shaping

> Can the traffic be deferred **with consent**?

### "Eco mode" feature
```python
# Two options for the user
@app.route('/api/render-video', methods=['POST'])
def render_video():
    if request.json.get('eco_mode'):
        # Put it on the low-priority queue, run at night
        eco_queue.enqueue(render_task, request.json)
        return jsonify({"status": "queued", "estimated": "tomorrow morning"})
    else:
        # Do it now (may be high carbon)
        return render_task(request.json)
```

### Adaptive video quality (Netflix-style)
- Wind heavy → 4K
- Carbon heavy → 1080p (transcode + bandwidth savings)
- The user can control it ("eco-stream" toggle)

---

## 🔧 Pattern 4: KEDA Carbon Scaler

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: carbon-aware-batch-worker
  namespace: ml
spec:
  scaleTargetRef:
    name: ml-batch-worker
  minReplicaCount: 0
  maxReplicaCount: 10
  triggers:
    - type: external
      metadata:
        scalerAddress: carbon-aware-scaler:8080
        location: 'eu-north-1'
        intensityThreshold: '150'   # scale up if < 150 g/kWh
        # Scale down trigger: > 400 g/kWh
        intensityThresholdHigh: '400'
```

→ Run when carbon is low, wait when it's high.

> There is a **KEDA carbon scaler** community project in the Cilium ecosystem.

---

## 📊 Workload Classification

Not every workload can be carbon-aware. Decision matrix:

| Workload type | Latency sensitivity | Carbon-aware fit |
|---|---|---|
| User-facing API | High | ❌ No (location-shift possible) |
| Background queue (hourly) | Low | ✅ Yes (time-shift ideal) |
| ML training | Very low | ✅✅ Very suitable |
| Batch ETL | Low | ✅ Yes |
| Cron job (nightly) | Medium | ✅ Yes |
| Build CI | Medium | ⚠️ Limited (don't keep devs waiting) |
| Backup | Low | ✅ Yes |
| Real-time streaming | High | ❌ No |
| Data analytics dashboard refresh | Low | ✅ Yes |

> 🔑 **Goal**: Make latency-tolerant workloads carbon-aware. Don't touch the critical path.

---

## 📉 Measurement — How Much Do You Save?

### Baseline + carbon-aware comparison
```python
# The same workload: 1 week non-aware, 1 week aware
non_aware_emissions = sum([
    energy_kwh[hour] * intensity_at_hour[hour]
    for hour in non_aware_run_hours
])

aware_emissions = sum([
    energy_kwh[hour] * intensity_at_hour[hour]
    for hour in aware_run_hours  # low-carbon hours
])

reduction_pct = (non_aware_emissions - aware_emissions) / non_aware_emissions * 100
# Typical: 20-50% reduction
```

### Grafana panel
```promql
# Carbon-aware savings (cumulative)
sum(increase(workload_co2_grams_saved_total[7d]))
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Right |
|---|---|---|
| Assuming every workload is carbon-aware | Latency-critical user-facing degrades | Classify the workload |
| Time-shift fixed to "night" only | Weather changes, no flexibility | Real-time API + window |
| Location-shift without considering data export | KVKK/GDPR violation | Data residency check |
| Manual cron, "hopefully it's low at that hour" | No forecast | API-driven scheduling |
| Carbon API rate limit forgotten | Call limit exceeded | Cache + minutely poll |
| Savings not measured | "We're going green" claim | Baseline + reporting |
| No transparency for the user | Deciding even when "eco mode" is off | Opt-in, visible |
| Trust the forecast, no real poll | Surprise change | Hourly re-check |
| Single carbon API source (ElectricityMaps) | API down → no fallback | Multi-source aggregator |

---

## 📋 Carbon-Aware Adoption Checklist

```
[ ] Workload classification: latency-tolerant ones identified
[ ] First 3 carbon-aware-suitable workloads picked (priority)
[ ] ElectricityMaps / WattTime / Carbon Aware SDK token
[ ] Time-shift: GitHub Actions / Cron + intensity check
[ ] Location-shift: multi-region failover or batch routing
[ ] KEDA carbon scaler (for K8s batch)
[ ] User-facing "eco mode" opt-in (if suitable)
[ ] Demand shaping: video quality, batch defer
[ ] Measurement: baseline + carbon-aware savings reporting
[ ] Data residency: location-shift KVKK compliant
[ ] Multi-source carbon API (fallback)
[ ] Quarterly: savings report to management
[ ] Documentation: developers are carbon-aware conscious
```

---

## 📚 References

- **Green Software Foundation — Carbon Aware** — greensoftware.foundation/articles/carbon-aware
- **ElectricityMaps API** — electricitymaps.com
- **WattTime API** — watttime.org
- **Carbon Aware SDK (Microsoft)** — github.com/Green-Software-Foundation/carbon-aware-sdk
- **CNCF Sustainability TAG** — github.com/cncf/tag-environmental-sustainability
- [`Green-Software-Principles.md`](Green-Software-Principles.md)
- [`Measuring-Software-Carbon.md`](Measuring-Software-Carbon.md)
- [`Region-Selection.md`](Region-Selection.md)
- [`12-FinOps/Cloud-Cost-Allocation.md`](../12-FinOps/Cloud-Cost-Allocation.md) — cost ↔ carbon dual

---

> *"Carbon-aware computing isn't 'run everything late' — it's **smart
> deferral**. Shifting latency-tolerant workloads to the wind hours
> **cuts emissions by 20-50%** — a win the user never notices."*
