---
description: "Quick-to-apply efficiency practices for green software: ARM/Graviton, spot instances, idle cleanup, compression, caching, and right-sizing, with cost-carbon dual ROI examples."
tags:
  - Sustainability
  - FinOps
  - Cost Optimization
  - Kubernetes
  - Performance
---
# Efficiency Practices — Quick Wins for Carbon + Cost

> *"Green software isn't a 'we'll get to it later' thing — practices
> applied **this quarter** cut emissions 20-50% + in the cost ↔ carbon
> dual, they **usually cut cost too**. **Win-win**."*

This guide covers **quick-to-apply** practices for green software —
ARM/Graviton, spot instances, idle cleanup, compression, caching,
right-sizing — with concrete commands and ROI.

---

## 🎯 Cost ↔ Carbon Dual

> "Every FinOps win is **usually** a sustainability win too."

| Practice | Cost reduction | Carbon reduction |
|---|---|---|
| Idle cleanup | 10-30% | 10-30% |
| Right-sizing | 15-25% | 15-25% |
| Spot instance | 70% | 30% (no new hardware manufactured) |
| ARM/Graviton | 20-40% | 20-40% (per-watt efficiency) |
| CDN | 20-40% (bandwidth) | 20-40% |
| Compression | 5-15% | 5-15% |
| Cold tier (old logs) | 80% (storage) | 50% |

> 🔑 **Quick wins**: apply over 4-8 weeks; a 20-30% reduction in Q1 is normal.

---

## 1️⃣ Idle Resource Cleanup

### Targets
- Unused EC2, EBS, RDS, NAT Gateway
- Empty S3 buckets, old snapshots
- Zombie load balancers
- Test environments (idle over the weekend)

### Tooling
- **AWS Trusted Advisor** → idle resource list
- **Kubecost** → K8s pod-level idle
- **Cloud Custodian** → policy-based cleanup
- **awsweeper** → idle scan + delete

### Custodian example
```yaml
# cleanup-old-snapshots.yml
policies:
  - name: ebs-snapshot-old
    resource: ebs-snapshot
    filters:
      - type: age
        days: 90
        op: gt
      - "tag:Name": null
    actions:
      - delete
```

### Idle EC2 finder
```bash
# CloudWatch CPUUtilization < 5% over last 14 days
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 --metric-name CPUUtilization \
  --start-time $(date -d '14 days ago' +%FT%T) \
  --end-time $(date +%FT%T) \
  --period 86400 --statistics Average
```

---

## 2️⃣ Right-Sizing

### Pattern
- Memory: 30%+ headroom OK, 70%+ free = scale down
- CPU: peak 50% → shrink one size
- Disk: utilization < 20% → shrink or drop a tier

### Tooling
- **AWS Compute Optimizer** → automatic recommendation
- **Kubecost** → K8s right-sizing (recommended pod resources)
- **Vertical Pod Autoscaler (VPA)** → automatic

### VPA example
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: payments-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: payments
  updatePolicy:
    updateMode: "Auto"   # or "Off" (recommendation only)
  resourcePolicy:
    containerPolicies:
      - containerName: payments
        minAllowed: {cpu: 100m, memory: 128Mi}
        maxAllowed: {cpu: 2000m, memory: 4Gi}
```

> ⚠️ HPA + VPA together can conflict. Use VPA in recommendation mode + HPA for scaling.

---

## 3️⃣ ARM / Graviton Migration

### Advantages
- **2-4x more efficient** per watt (Graviton 3 → 4)
- **Cost**: 20% cheaper than an equivalent x86 instance
- **Performance**: faster on many workloads

### Suitable workloads
- ✅ Go (easy cross-compile)
- ✅ Java (JVM Graviton optimized)
- ✅ Python (CPython arm64 wheel)
- ✅ Node.js (native arm64 v20+)
- ✅ Rust (cross-compile)
- ⚠️ Numeric (NumPy, TensorFlow): check first — some pip wheels don't have an arm64 build

### Migration step
```dockerfile
# Multi-arch Dockerfile
FROM --platform=$BUILDPLATFORM golang:1.23 AS builder
ARG TARGETOS TARGETARCH
WORKDIR /src
COPY . .
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /app .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /app /app
ENTRYPOINT ["/app"]
```

```yaml
# CI: multi-platform build
- uses: docker/build-push-action@<VERSION>
  with:
    platforms: linux/amd64,linux/arm64
    push: true
    tags: <REGISTRY>/<APP>:<TAG>
```

### K8s deployment
```yaml
spec:
  template:
    spec:
      nodeSelector:
        kubernetes.io/arch: arm64
```

### Mixed nodepools with Karpenter
```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: graviton
spec:
  template:
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: [arm64]
        - key: karpenter.k8s.aws/instance-family
          operator: In
          values: [c7g, m7g, r7g]   # Graviton 3
```

---

## 4️⃣ Spot Instance / Preemptible

### Advantages
- **70% cheaper** (AWS Spot, GCP Preemptible)
- Uses existing hardware → no extra manufacturing needed (carbon)

### Suitable workloads
- ✅ Stateless (HTTP API)
- ✅ Batch / ML training
- ✅ CI runner
- ⚠️ DB (usually not — stateful)
- ⚠️ Cache (not Redis primary — replica OK)

### Mixed pod scheduling
```yaml
# Critical: on-demand
spec:
  nodeSelector:
    karpenter.sh/capacity-type: on-demand

# Tolerant: spot
spec:
  tolerations:
    - key: karpenter.sh/capacity-type
      operator: Equal
      value: spot
      effect: NoSchedule
```

### Karpenter spot fleet
```yaml
spec:
  template:
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: [spot, on-demand]
      # Spot interruption protection
      disruption:
        consolidationPolicy: WhenEmpty
```

---

## 5️⃣ Dev Cluster Night Shutdown

```yaml
# CronJob: 19:00 scale to 0
apiVersion: batch/v1
kind: CronJob
metadata:
  name: scale-down-dev
  namespace: kube-system
spec:
  schedule: "0 19 * * 1-5"   # weekday 19:00
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: scaler
          containers:
            - name: scaler
              image: bitnami/kubectl:latest
              command:
                - kubectl
                - scale
                - deployment
                - --all
                - --replicas=0
                - -n
                - dev
```

```yaml
# CronJob: 09:00 scale up
spec:
  schedule: "0 9 * * 1-5"
  # ... --replicas=1
```

> 🔑 **60% dev cost reduction** — 5 days × 14 hours / 7 days × 24 hours ≈ 58%.

---

## 6️⃣ Compression (HTTP + Storage)

### HTTP gzip / brotli
```nginx
# Ingress-NGINX
gzip on;
gzip_types text/plain application/json application/javascript;
gzip_min_length 1000;
brotli on;
brotli_types text/plain application/json application/javascript;
```

→ 20-40% bandwidth savings.

### Storage compression
```yaml
# S3 lifecycle: gzip old logs
- Filter: prefix=logs/
- Transitions:
    - Days: 30
      StorageClass: STANDARD_IA
    - Days: 90
      StorageClass: GLACIER
```

### DB compression
```sql
-- Postgres: column compression (TOAST)
ALTER TABLE events ALTER COLUMN payload SET COMPRESSION lz4;
```

---

## 7️⃣ CDN — Edge Caching

> Moving traffic away from origin = distance savings = energy savings.

### Cloudflare / CloudFront
- Static assets (JS, CSS, images) → CDN
- API cache (TTL 60s) → caching POST requests is hard
- HTML pages (5min TTL acceptable)

### Cache headers
```http
Cache-Control: public, max-age=3600, s-maxage=86400, immutable
```

---

## 8️⃣ Cold Storage — Old Logs

### S3 Lifecycle
```yaml
LifecycleRules:
  - Filter: prefix=logs/
    Transitions:
      - Days: 30
        StorageClass: STANDARD_IA   # Infrequent Access
      - Days: 90
        StorageClass: GLACIER        # Archive
      - Days: 365
        StorageClass: DEEP_ARCHIVE
    Expiration: {Days: 2555}         # 7 years (compliance retention)
```

→ STANDARD_IA: 40% cheaper. GLACIER: 80% cheaper.

---

## 9️⃣ Database Cache + Read Replica

### Redis in Front of Postgres
- Cache 80% of read queries in Redis
- Postgres CPU drops 30% → smaller instance

### Read replica
- Reporting / analytics → replica
- Primary CPU drops 20-40%

---

## 🔟 ML Training Optimization

### Smaller model = less energy
- Distillation (large model → small model)
- Quantization (FP32 → INT8)
- LoRA fine-tuning (instead of full retrain)

### GPU efficiency
- Mixed precision (FP16) — 2x throughput
- Multi-instance GPU sharing (MIG)
- Spot GPU (if interruption is OK)
- Carbon-aware scheduling (low-intensity hours)

---

## 📊 Quick Wins ROI Calculation

```
Action                   | Effort  | Cost Save | CO₂ Save
─────────────────────────|─────────|───────────|──────────
Idle cleanup             | 1 week  | 10-30%    | 10-30%
Right-sizing             | 2 weeks | 15-25%    | 15-25%
ARM migration            | 4 weeks | 20-40%    | 20-40%
Spot adoption            | 2 weeks | 30-50%    | 20%
Dev cron scaler          | 3 days  | 60% (dev) | 60% (dev)
CDN                      | 1 week  | 20-40%    | 20-40%
Compression              | 1 day   | 5-15%     | 5-15%
Cold tier                | 1 week  | 50-80%    | 30-50%
                         |         |           |
First 3 months total:    |         | 30-50%    | 30-50%
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| "Performance is everything, cost / carbon later" | Budget + climate neglected | Quarterly review |
| Idle resources neglected | Monthly $X lost | Custodian + alarm |
| Spot not used | 70% of cost left on the table | Mixed nodepool |
| All workloads on x86 | 30% extra wattage | Migrate ARM-suitable ones |
| Dev running 24/7 | Weekend waste | Cron scaler |
| Unlimited log retention | Storage cost + carbon | Lifecycle policy |
| ML training at peak hour | High carbon | Carbon-aware scheduling |
| Compression disabled | Bandwidth + energy | Enable gzip/brotli |
| No/insufficient CDN | Origin overload | CloudFront / Cloudflare |
| HPA scales up aggressively + down fast | Pod thrashing | Stabilization window |

---

## 📋 Efficiency Quick Wins Checklist

```
[ ] Idle resource scan (weekly cron)
[ ] Right-sizing (VPA recommendation mode)
[ ] ARM/Graviton migration plan + list of suitable workloads
[ ] Spot instances: 30%+ of workload
[ ] Dev cluster cron scaler (nights + weekends)
[ ] HTTP compression (gzip + brotli)
[ ] CDN: static assets + API cache
[ ] S3 lifecycle: 30/90/365-day tiers
[ ] Redis cache (in front of read-heavy DB)
[ ] Read replica (reporting / analytics)
[ ] ML mixed precision (FP16)
[ ] Carbon-aware batch scheduler
[ ] Quarterly: efficiency report (cost + CO₂)
[ ] FinOps + Sustainability shared dashboard
```

---

## 📚 References

- **AWS Cost Optimization Pillar** — aws.amazon.com/architecture/well-architected
- **GCP Cost Optimization** — cloud.google.com/architecture/framework/cost-optimization
- **Cloud Custodian** — cloudcustodian.io
- **Karpenter** — karpenter.sh
- **VPA** — github.com/kubernetes/autoscaler
- **Kubecost** — kubecost.com
- [`Green-Software-Principles.md`](Green-Software-Principles.md)
- [`Carbon-Aware-Computing.md`](Carbon-Aware-Computing.md)
- [`Region-Selection.md`](Region-Selection.md)
- [`Measuring-Software-Carbon.md`](Measuring-Software-Carbon.md)
- [`12-FinOps/Cloud-Cost-Allocation.md`](../12-FinOps/Cloud-Cost-Allocation.md)

---

> *"Efficiency isn't a 'tomorrow' job — it's **this quarter's** win.
> In the cost ↔ carbon dual, every **dollar saved** is usually a
> **kg of CO₂ saved** too. Good for the budget and the green report alike."*
