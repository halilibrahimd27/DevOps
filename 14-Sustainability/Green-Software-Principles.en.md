---
description: "Guide that translates the Green Software Foundation's 8 principles into concrete engineering decisions; covers measuring with the SCI metric and turning green software into a CI pass/fail metric, with CSRD/SEC context."
tags:
  - Sustainability
  - Observability
  - Prometheus
  - CI/CD
  - Compliance
---
# Green Software Principles — Turning Carbon into an Engineering Discipline

> *"Software is **never** carbon-neutral; it's just CO₂ that you decided
> not to measure."* — Green Software Foundation

This guide translates the Green Software Foundation's 8 principles into
concrete engineering decisions, covers measuring with the SCI metric, and
explains how to turn "green software" from a buzzword into a **CI pass/fail metric**.

---

## 🎯 Why It Matters in 2026

### Legal requirements
- **EU CSRD** (Corporate Sustainability Reporting Directive) — large companies
  are **required** to report emissions (took effect in 2024, phased scope)
- **US SEC Climate Rule** — public companies must report Scope 1/2/3
- **EU Cyber Resilience Act + Sustainability** — the carbon impact of software
- **ISO 14001** and similar standards now feed into software observability

### Business impact
- **Customer demand** — the "carbon disclosure" question is now standard in RFPs
- **Investor pressure** — ESG metrics factor into funding decisions
- **Cost** — green usually means efficient, which means cheap (cost ↔ carbon dual optimization)
- **Talent attraction** — 70% of Gen-Z engineers factor sustainability into their job choice

> 🔑 **Saying "we don't care about green" in 2026** is becoming as
> untenable as saying "we don't comply with GDPR."

---

## 🌳 Green Software Foundation — 8 Principles

### 1. Carbon Efficiency
> Do the same work with less carbon emission.

**Practice:** Optimize at the code level — less CPU, less IO.

```
Bad:   500 lines of pandas → the whole CSV loaded into RAM
Good:  stream processing chunks → less memory + CPU
```

### 2. Energy Efficiency
> Do the same work with fewer watts.

**Practice:**
- ARM/Graviton CPUs (2-4x more efficient per watt)
- Compiled languages (Go, Rust) are more efficient than interpreted ones
- Lazy evaluation, vectorization

### 3. Carbon Awareness
> Run at low-carbon times/places.

**Practice:**
- Run batch jobs at night (more wind, less demand)
- Run training jobs in a carbon-low region

### 4. Hardware Efficiency
> Use old hardware more efficiently; avoid unnecessary refreshes.

**Practice:**
- "Embodied carbon" comes from hardware manufacturing = long-lived servers
- Refurbished hardware on-prem
- Increase utilization in the cloud → fewer physical servers

### 5. Measurement
> You can't improve what you don't measure.

**Practice:**
- SCI metric (below)
- Cloud Carbon Footprint
- Kepler (eBPF-based pod-level energy)

### 6. Climate Commitments
> Understand and back your company's commitments.

**Practice:** ISO 14064, GHG Protocol, SBTi (Science Based Targets initiative).

### 7. Networking
> Data movement = energy. Minimize it.

**Practice:**
- CDN (move traffic away from origin)
- Compression
- Smaller payload (Protobuf vs JSON, gRPC)
- Cache aggressively

### 8. Demand Shaping
> Design the application to flex against load.

**Practice:**
- "Eco mode": low-priority requests run in the background
- Adaptive video quality
- Batch at night instead of real-time

---

## 📊 SCI — Software Carbon Intensity

```
SCI = ((E × I) + M) / R

E = Energy (kWh)              electricity consumed by the application
I = Carbon Intensity (gCO₂eq/kWh)  carbon intensity of electricity by region+hour
M = Embodied carbon (gCO₂eq)  carbon embedded in hardware manufacturing (amortized)
R = functional unit           1000 requests, 1 user, 1 transaction…

Unit: gCO₂eq / functional unit

Goal: **Reduce** SCI. NEVER "compensate" / offset — only reduction counts.
```

### Example calculation
| Stage | Value |
|---|---|
| E (kWh) | 100 |
| I (gCO₂/kWh, eu-west-1 average) | 250 |
| M (kg CO₂, server lifecycle) | 1500 |
| R (requests) | 10,000,000 |
| **SCI** | (100 × 250 + 1500) / 10,000,000 = **2.65 gCO₂/req** |

> 🔑 **The goal is to reduce the trend**, not hit an absolute number. A 20% year-over-year reduction is "good."

---

## 🔧 Wiring SCI into Engineering

### Who measures it?
| Tool | What it measures | License |
|---|---|---|
| **Cloud Carbon Footprint** | Cloud (AWS, GCP, Azure) — bill-based | Apache 2 |
| **Kepler** | K8s pod energy (eBPF) | Apache 2 |
| **Scaphandre** | VM/server energy (RAPL) | Apache 2 |
| **AWS Customer Carbon Footprint Tool** | AWS native | Free, AWS only |
| **GCP Carbon Footprint** | GCP native | Free, GCP only |
| **Azure Emissions Impact Dashboard** | Azure native | Free, Azure only |
| **Boavizta API** | Hardware embodied carbon | OSS |

### Installing Kepler
```bash
helm install kepler kepler/kepler \
  -n kepler --create-namespace \
  --set serviceMonitor.enabled=true
```

Prometheus metrics:
```promql
# Joules per pod
kepler_container_joules_total{pod_name="<POD>"}

# Watt-hours per namespace (1-hour window)
sum by (namespace) (
  rate(kepler_container_joules_total[1h])
) / 3600
```

### Grafana Sustainability Dashboard
- Cluster total carbon (gCO₂/hour)
- Per-namespace breakdown
- Top 10 carbon-heavy pod
- Trend (weekly)

---

## 🌍 Region Selection — Carbon Intensity

Cloud regions can differ by **5-10x** in **real-time** carbon intensity.

### Recommended low-carbon regions for 2026

| Cloud | Region | Notes |
|---|---|---|
| AWS | `eu-north-1` (Stockholm) | Hydroelectric + nuclear |
| AWS | `us-west-2` (Oregon) | Hydroelectric |
| AWS | `eu-west-3` (Paris) | Nuclear-heavy |
| GCP | `europe-north1` (Finland) | Wind + nuclear |
| GCP | `europe-west1` (Belgium) | Mix, 85%+ renewable |
| Azure | `Sweden Central` | Hydroelectric |
| Azure | `North Europe` (Ireland) | Wind |

### Anti-example (high carbon)
- AWS `ap-southeast-3` (Jakarta) — coal-heavy
- AWS `cn-north-1` (Beijing) — coal-heavy

> ⚠️ **Latency vs carbon tradeoff:** If your customer is in Turkey,
> `eu-central-1` (Frankfurt) is good for latency but higher-carbon than
> `eu-north-1`. Add it to the decision matrix.

### Using Cloud Carbon Footprint
```bash
# Cloud Carbon Footprint scans AWS billing
docker run --rm \
  -e AWS_ACCESS_KEY_ID=... -e AWS_SECRET_ACCESS_KEY=... \
  cloudcarbonfootprint/cloud-carbon-footprint:latest

# Web UI: localhost:4000
```

---

## ⚡ Carbon-Aware Computing

### Pattern: "run batch jobs during low-carbon hours"

```yaml
# CronJob: run during high-wind hours (at night)
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly-rebuild
spec:
  schedule: "0 2 * * *"  # 02:00 — low demand, more wind
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: rebuild
              image: <APP>
```

### Smarter: a dynamic scheduler
**Carbon Aware SDK** (Microsoft, GSF) — reads real-time carbon intensity via the ElectricityMaps API:

```yaml
# GitHub Actions
jobs:
  carbon-aware-rebuild:
    runs-on: ubuntu-latest
    if: ${{ steps.carbon.outputs.intensity == 'low' }}
    steps:
      - id: carbon
        uses: green-software-foundation/carbon-aware-action@<VERSION>
        with:
          location: 'eu-north-1'
          window: '6h'
      - run: ./expensive-rebuild.sh
```

### KEDA carbon scaler
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: carbon-aware-batch
spec:
  scaleTargetRef:
    name: batch-worker
  triggers:
    - type: external
      metadata:
        scalerAddress: carbon-aware-scaler:8080
        location: "eu-west-1"
        intensity-threshold: "200"   # scale up if below 200 gCO₂/kWh
```

---

## 🔧 Quick Wins (Fast Impact)

| Action | Savings (rough) | Time |
|---|---|---|
| **Idle resource cleanup** (unused EC2, EBS, RDS) | 10-30% | 1 week |
| **Migrate to ARM/Graviton** (suitable workloads) | 20-40% watt | 2-4 weeks |
| **Spot instances** (idle capacity) | 70% cost, no extra hardware manufactured | 1-2 weeks |
| **Right-sizing** (shrink over-provisioned) | 20% | 2 weeks |
| **Cron scaler dev/staging** (off at night) | 60% dev cost | 3 days |
| **Compression** (HTTP gzip/brotli) | 5-15% network | 1 day |
| **Image tag immutable + cache** | Fewer build re-runs | 1 day |
| **CDN** (static assets to edge) | 20-40% origin traffic | 1-2 weeks |
| **Cold tier** (old logs → S3 Glacier) | 80% storage cost | 1 week |
| **Database autovacuum + bloat cleanup** | 15% disk + IO | 1 day |

> 🔑 **The quick-win list is the cost ↔ carbon dual.** FinOps + Sustainability
> recommend the same actions most of the time.

---

## 🧪 A Carbon Gate in CI

```yaml
# .github/workflows/sustainability-check.yml
name: Sustainability Check

on: [pull_request]

jobs:
  bundle-size:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>
      - run: npm ci && npm run build
      - uses: andresz1/size-limit-action@<VERSION>
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}

  image-size:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>
      - run: docker build -t <APP>:test .
      - id: size
        run: |
          SIZE=$(docker image inspect <APP>:test --format '{{.Size}}')
          echo "size=$SIZE" >> $GITHUB_OUTPUT
          if [ $SIZE -gt 100000000 ]; then
            echo "::error::Image > 100 MB, sustainability budget exceeded"
            exit 1
          fi
```

> 🔑 Bundle size, image size, dependency count — proxy metrics. If you
> can't measure SCI fully, these are a **good starting point**.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| "We buy carbon offsets" | Marketing, no real reduction | **Reduce** first, then offset the residual (why offset-over-reduction isn't accepted) |
| Allocating 4 vCPUs, 5% utilization | Wasted embodied carbon + idle | Right-sizing, HPA, VPA |
| Always-on dev env | Wasted watts over the weekend | Cron scaler |
| Region selection based only on latency | Carbon gets ignored | Add carbon to the decision matrix |
| Logging everything "just in case" | Storage = energy | Severity filter, retention policy |
| `:latest` tag → CI cache miss | The same build runs N times | Digest pin + cache |
| 4 GB Docker image | Bandwidth + storage on every pull | Distroless, multi-stage |
| Testing everything on every PR | Wasted CPU | Selective testing, change-based |
| Synchronous I/O on the hot path | CPU sits waiting | Async / batched |
| Uncached database query | The same result computed N times | Redis cache, materialized view |
| On-prem HDD, 10% utilization | High embodied carbon, high watts | Consolidate → fewer servers, more utilization |

---

## 📋 Sustainability Engineering Checklist

```
[ ] Cloud Carbon Footprint installed, dashboard visible
[ ] Kepler or equivalent K8s pod-level energy
[ ] SCI metric defined, baseline measured
[ ] Quarterly: SCI trend report (to management)
[ ] Region selection matrix: latency + carbon + cost
[ ] ARM/Graviton (Java, Go, Python suitable) migration completed
[ ] Spot instances: 30%+ of workload
[ ] Idle resource cleaner cron (weekly)
[ ] Right-sizing: VPA + manual review
[ ] Dev cluster shuts down at night (cron scaler)
[ ] CDN: static assets to edge
[ ] Cold tier: 90+ day-old logs to S3 Glacier
[ ] Bundle size budget gated in CI
[ ] Image size budget gated in CI
[ ] Carbon-aware batch (during wind hours)
[ ] Hardware lifecycle policy (4-5 years, then refurbish)
[ ] Carbon report for customers (B2B customer demand)
[ ] CSRD reporting readiness (if a large company)
[ ] Quarterly: green software training (engineer onboarding)
```

---

## 📚 References

- **Green Software Foundation** — greensoftware.foundation
- **Principles** — principles.green
- **SCI Spec** — sci.greensoftware.foundation
- **Cloud Carbon Footprint** — cloudcarbonfootprint.org
- **Kepler** — sustainable-computing.io
- **Climate Action Tech** — climateaction.tech
- **Boavizta** — boavizta.org
- **ElectricityMaps API** — electricitymaps.com
- **AWS Customer Carbon Footprint Tool**
- **GCP Carbon Footprint**
- **Azure Emissions Impact Dashboard**
- [`Carbon-Aware-Computing.md`](Carbon-Aware-Computing.md)
- [`Measuring-Software-Carbon.md`](Measuring-Software-Carbon.md)
- [`Region-Selection.md`](Region-Selection.md)
- [`12-FinOps/Cloud-Cost-Allocation.md`](../12-FinOps/Cloud-Cost-Allocation.md) — cost ↔ carbon dual

---

> *"Green software isn't an 'optional nicety' — it's an **engineering
> discipline**. Just as you question a decision's 'cost', 'latency', and
> 'security' dimensions, don't let 'carbon' become the one you never ask."*
