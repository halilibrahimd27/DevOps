---
description: "Yesil yazilim icin hizli uygulanabilen verimlilik pratikleri: ARM/Graviton, spot instance, idle cleanup, compression, caching ve right-sizing; cost-carbon dual ROI ornekleriyle."
tags:
  - Sustainability
  - FinOps
  - Cost Optimization
  - Kubernetes
  - Performance
---
# Efficiency Practices — Quick Wins for Carbon + Cost

> *"Yeşil yazılım 'gelecekte düşünelim' işi değil — **bu çeyrek**
> uygulanan pratikler %20-50 emisyon azaltır + cost ↔ carbon
> dual'i çoğu durumda **maliyet de azaltır**. **Kazan-kazan**."*

Bu rehber yeşil yazılım için **hızlı uygulanabilen** pratikleri —
ARM/Graviton, spot instance, idle cleanup, compression, caching,
right-sizing — somut komut + ROI ile anlatır.

---

## 🎯 Cost ↔ Carbon Dual

> "Her FinOps kazancı **çoğu zaman** sustainability kazancıdır."

| Pratik | Cost azaltma | Carbon azaltma |
|---|---|---|
| Idle cleanup | %10-30 | %10-30 |
| Right-sizing | %15-25 | %15-25 |
| Spot instance | %70 | %30 (yeni hardware üretmiyor) |
| ARM/Graviton | %20-40 | %20-40 (per-watt verim) |
| CDN | %20-40 (bandwidth) | %20-40 |
| Compression | %5-15 | %5-15 |
| Cold tier (eski log) | %80 (storage) | %50 |

> 🔑 **Quick wins**: 4-8 hafta uygulanır, Q1'de %20-30 reduction normal.

---

## 1️⃣ Idle Resource Cleanup

### Hedefler
- Kullanılmayan EC2, EBS, RDS, NAT Gateway
- Boş S3 bucket, eski snapshot'lar
- Zombie load balancer'lar
- Test environment'ları (haftasonu kapalı)

### Tooling
- **AWS Trusted Advisor** → idle resource list
- **Kubecost** → K8s pod-level idle
- **Cloud Custodian** → policy-based cleanup
- **awsweeper** → idle taraması + delete

### Custodian örneği
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
# CloudWatch CPUUtilization < %5 son 14 gün
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 --metric-name CPUUtilization \
  --start-time $(date -d '14 days ago' +%FT%T) \
  --end-time $(date +%FT%T) \
  --period 86400 --statistics Average
```

---

## 2️⃣ Right-Sizing

### Pattern
- Memory: %30+ headroom OK, %70+ bos = ölçek küçült
- CPU: peak %50 → 1 size küçült
- Disk: utilization < %20 → küçült veya tier düşür

### Tooling
- **AWS Compute Optimizer** → otomatik öneri
- **Kubecost** → K8s right-sizing (önerilen pod resource)
- **Vertical Pod Autoscaler (VPA)** → otomatik

### VPA örneği
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
    updateMode: "Auto"   # veya "Off" (sadece öneri)
  resourcePolicy:
    containerPolicies:
      - containerName: payments
        minAllowed: {cpu: 100m, memory: 128Mi}
        maxAllowed: {cpu: 2000m, memory: 4Gi}
```

> ⚠️ HPA + VPA ikisi birlikte ihtilafa girebilir. VPA recommendation-mode'da kullanılır + HPA ölçek için.

---

## 3️⃣ ARM / Graviton Migration

### Avantajlar
- **Per-watt 2-4x** verimli (Graviton 3 → 4)
- **Maliyet**: x86 instance'a göre %20 daha ucuz
- **Performance**: many workload'da daha hızlı

### Uygun workload'lar
- ✅ Go (cross-compile kolay)
- ✅ Java (JVM Graviton optimized)
- ✅ Python (CPython arm64 wheel)
- ✅ Node.js (native arm64 v20+)
- ✅ Rust (cross-compile)
- ⚠️ Sayısal (NumPy, TensorFlow): kontrol et — bazı pip wheel arm64 yok

### Migration adımı
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

### Karpenter ile mixed nodepools
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

### Avantajlar
- **%70 daha ucuz** (AWS Spot, GCP Preemptible)
- Existing hardware → ek üretim gerekmez (carbon)

### Uygun workload'lar
- ✅ Stateless (HTTP API)
- ✅ Batch / ML training
- ✅ CI runner
- ⚠️ DB (genelde değil — state)
- ⚠️ Cache (Redis primary değil — replica OK)

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
      # Spot interruption koruması
      disruption:
        consolidationPolicy: WhenEmpty
```

---

## 5️⃣ Dev Cluster Gece Kapatma

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

> 🔑 **%60 dev cost reduction** — 5 gün × 14 saat / 7 gün × 24 saat ≈ %58.

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

→ %20-40 bandwidth tasarrufu.

### Storage compression
```yaml
# S3 lifecycle: gzip eski log
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

> Origin'den uzaklaştırma = path tasarrufu = enerji tasarrufu.

### Cloudflare / CloudFront
- Static asset (JS, CSS, image) → CDN
- API cache (TTL 60s) → POST cache hard
- HTML page (5min TTL acceptable)

### Cache headers
```http
Cache-Control: public, max-age=3600, s-maxage=86400, immutable
```

---

## 8️⃣ Cold Storage — Eski Log

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
    Expiration: {Days: 2555}         # 7 yıl (compliance retention)
```

→ STANDARD_IA: %40 daha ucuz. GLACIER: %80 daha ucuz.

---

## 9️⃣ Database Cache + Read Replica

### Redis önünde Postgres
- Read query'lerin %80'ini Redis cache
- Postgres CPU %30 azalır → daha küçük instance

### Read replica
- Reporting / analytics → replica
- Primary CPU %20-40 azalır

---

## 🔟 ML Training Optimization

### Daha küçük model = az enerji
- Distillation (büyük model → küçük model)
- Quantization (FP32 → INT8)
- LoRA fine-tuning (full retrain yerine)

### GPU efficiency
- Mixed precision (FP16) — 2x throughput
- Multi-instance GPU sharing (MIG)
- Spot GPU (eğer interrupt OK)
- Carbon-aware scheduling (low-intensity saat)

---

## 📊 Quick Wins ROI Hesabı

```
Aksiyon                  | Effort  | Cost Save | CO₂ Save
─────────────────────────|─────────|───────────|──────────
Idle cleanup             | 1 hafta | %10-30    | %10-30
Right-sizing             | 2 hafta | %15-25    | %15-25
ARM migration            | 4 hafta | %20-40    | %20-40
Spot adoption            | 2 hafta | %30-50    | %20
Dev cron scaler          | 3 gün   | %60 (dev) | %60 (dev)
CDN                      | 1 hafta | %20-40    | %20-40
Compression              | 1 gün   | %5-15     | %5-15
Cold tier                | 1 hafta | %50-80    | %30-50
                         |         |           |
İlk 3 ayda toplam:       |         | %30-50    | %30-50
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "Performance her şey, cost / carbon sonra" | Bütçe + iklim ihmal | Quarterly review |
| Idle resource ihmal | Aylık $X kayıp | Custodian + alarm |
| Spot kullanılmıyor | %70 maliyet kaybedildi | Mixed nodepool |
| Tüm workload x86 | %30 fazla watt | ARM uygunları migrate |
| Dev 24/7 açık | Hafta sonu israf | Cron scaler |
| Log retention sonsuz | Storage cost + carbon | Lifecycle policy |
| ML training peak hour | Yüksek karbon | Carbon-aware scheduling |
| Compression kapalı | Bandwidth + enerji | gzip/brotli enable |
| CDN yok / yetersiz | Origin overload | CloudFront / Cloudflare |
| HPA agresif scale up + scale down hızlı | Pod thrashing | Stabilization window |

---

## 📋 Efficiency Quick Wins Checklist

```
[ ] Idle resource scan (haftalık cron)
[ ] Right-sizing (VPA recommendation mode)
[ ] ARM/Graviton migration plan + uygun workload list
[ ] Spot instance: %30+ workload
[ ] Dev cluster cron scaler (gece + hafta sonu)
[ ] HTTP compression (gzip + brotli)
[ ] CDN: static asset + API cache
[ ] S3 lifecycle: 30/90/365 gün tier
[ ] Redis cache (read-heavy DB önünde)
[ ] Read replica (reporting / analytics)
[ ] ML mixed precision (FP16)
[ ] Carbon-aware batch scheduler
[ ] Quarterly: efficiency report (cost + CO₂)
[ ] FinOps + Sustainability shared dashboard
```

---

## 📚 Referanslar

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

> *"Efficiency 'yarın' işi değil — **bu çeyrek**'in kazancı.
> Cost ↔ carbon dual'inde her **dolar tasarrufu** çoğu zaman **kg
> CO₂ tasarrufudur**. Hem bütçe hem yeşil rapor."*
