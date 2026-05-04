# HPA, VPA, KEDA — K8s Autoscaling Tam Rehber

> *"3 farklı autoscaler, 3 farklı niche. HPA: pod sayısı CPU'ya göre.
> VPA: pod resource'u kullanıma göre. KEDA: pod sayısı **event'e**
> göre (queue, cron, custom metric). **Hangisini ne zaman**?"*

Bu rehber Kubernetes'in 3 ana autoscaler'ını karşılaştırır, hangi
senaryoda hangisinin tercih edileceğini, ve birlikte çalışma
pattern'lerini anlatır.

---

## ⚖️ 3 Autoscaler

| Tool | Ne | Yöntem |
|---|---|---|
| **HPA** | Horizontal Pod Autoscaler | Pod sayısı ↑↓ (CPU/Memory/custom metric) |
| **VPA** | Vertical Pod Autoscaler | Pod resource (CPU/Memory request) ↑↓ |
| **KEDA** | Kubernetes Event-Driven Autoscaler | Pod sayısı, **dış event'lere** göre |

---

## 🎯 HPA — Horizontal Pod Autoscaler

> Pod sayısını yatay ölçekler (örn: 3 → 10 → 3).

### Basit (CPU)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: payments-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: payments
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70   # CPU %70 hedef
```

### Multi-metric (CPU + Memory + Custom)
```yaml
metrics:
  - type: Resource
    resource:
      name: cpu
      target: {type: Utilization, averageUtilization: 70}
  - type: Resource
    resource:
      name: memory
      target: {type: Utilization, averageUtilization: 80}
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: 100
```

### Behavior tuning (scale up/down hızı)
```yaml
behavior:
  scaleUp:
    stabilizationWindowSeconds: 0   # hızlı scale up
    policies:
      - type: Percent
        value: 100   # max 2x kat
        periodSeconds: 60
      - type: Pods
        value: 4     # max 4 pod ekle
        periodSeconds: 60
    selectPolicy: Max
  scaleDown:
    stabilizationWindowSeconds: 300   # 5 dk bekle
    policies:
      - type: Percent
        value: 25
        periodSeconds: 60
```

> 🔑 **Scale up hızlı, scale down yavaş** → flap engelleme.

### Custom metric (Prometheus)
```yaml
# prometheus-adapter
- seriesQuery: 'http_requests_total{namespace!="",pod!=""}'
  resources:
    overrides:
      namespace: {resource: "namespace"}
      pod: {resource: "pod"}
  name: {matches: "^(.*)_total$", as: "${1}_per_second"}
  metricsQuery: sum(rate(<<.Series>>{<<.LabelMatchers>>}[2m])) by (<<.GroupBy>>)
```

```yaml
# HPA custom metric kullanır
- type: Pods
  pods:
    metric: {name: http_requests_per_second}
    target: {type: AverageValue, averageValue: 100}
```

---

## 📦 VPA — Vertical Pod Autoscaler

> Pod resource (CPU/Memory) request/limit ayarlar.

### Modes
| Mode | Davranış |
|---|---|
| `Off` | Sadece öneri, resource değişmez (recommendation mode) |
| `Initial` | Pod oluşturulurken resource set, sonra değişmez |
| `Auto` | Pod yeniden başlatarak resource günceller |
| `Recreate` | Eski pod kill, yeni resource'la yarat |

### Manifest
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
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
      - containerName: payments
        minAllowed: {cpu: 100m, memory: 128Mi}
        maxAllowed: {cpu: 2000m, memory: 4Gi}
        controlledResources: [cpu, memory]
```

### `Off` mode (recommendation only)
```yaml
spec:
  updatePolicy:
    updateMode: "Off"
```

```bash
# Önerileri gör
kubectl describe vpa payments-vpa
# Recommendation: cpu=234m memory=512Mi
```

→ İnsan review eder, deployment'a manuel uygular.

---

## ⚠️ HPA + VPA Birlikte

```
HPA: pod sayısı (yatay)
VPA: pod resource (dikey)
   ↑
   └── Aynı resource (CPU) için ikisini birlikte kullanma!
       İhtilaf riski.

✅ İYİ: HPA CPU + VPA Memory
✅ İYİ: VPA Off mode + HPA prod'da
❌ KÖTÜ: HPA Auto + VPA Auto aynı resource
```

> 🔑 **Production önerisi**: HPA aktif (pod sayısı), VPA `Off` mode (öneri only) → manuel review + deployment'a uygula.

---

## ⚡ KEDA — Event-Driven Autoscaler

> HPA'yı "event source"larla genişletir. Queue depth, cron, AWS SQS, Kafka, Prometheus, vb.

### Kurulum
```bash
helm install keda kedacore/keda \
  -n keda --create-namespace
```

### ScaledObject — SQS queue
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: queue-worker-scaler
spec:
  scaleTargetRef:
    name: queue-worker
  minReplicaCount: 0
  maxReplicaCount: 50
  pollingInterval: 30   # 30 saniyede bir queue check
  cooldownPeriod: 300   # 5 dk idle sonrası scale down
  triggers:
    - type: aws-sqs-queue
      metadata:
        queueURL: <SQS_URL>
        queueLength: '10'
        awsRegion: <REGION>
        identityOwner: pod
```

### Kafka consumer
```yaml
triggers:
  - type: kafka
    metadata:
      bootstrapServers: <KAFKA_BROKER>:9092
      consumerGroup: payments-group
      topic: orders
      lagThreshold: '50'
```

### Cron (predictable scale)
```yaml
triggers:
  - type: cron
    metadata:
      timezone: Europe/Istanbul
      start: 0 9 * * 1-5     # weekday 09:00 → scale up
      end: 0 18 * * 1-5      # 18:00 → scale down
      desiredReplicas: '20'
```

### Prometheus custom metric
```yaml
triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus.<NS>.svc:9090
      metricName: http_requests_per_second
      threshold: '100'
      query: |
        sum(rate(http_requests_total{service="payments"}[2m]))
```

### Multi-trigger
```yaml
triggers:
  - type: prometheus
    metadata: {...}
  - type: cron
    metadata: {...}
  - type: aws-sqs-queue
    metadata: {...}
# → herhangi biri tetiklendiğinde scale
```

### Scale to zero
```yaml
minReplicaCount: 0   # idle'da hiç pod yok
```

→ Queue boşken **0 pod** (cost tasarruf). Mesaj gelince hızla scale.

---

## 🌳 Karar Ağacı

```
START
  │
  ├── Sürekli HTTP traffic (req/sec ile bağlı)?
  │     │
  │     └── HPA (CPU + custom: http_requests_per_second)
  │
  ├── Background queue worker (SQS, Kafka, RabbitMQ)?
  │     │
  │     └── KEDA + queue trigger
  │
  ├── Predictable load (business hours)?
  │     │
  │     └── KEDA + cron
  │
  ├── Idle period uzun (saatler boşta)?
  │     │
  │     └── KEDA + scale-to-zero
  │
  ├── Pod resource yanlış set, sürekli OOM/idle?
  │     │
  │     └── VPA recommendation mode + manuel uygula
  │
  └── Multi-source event (queue + traffic + schedule)?
         │
         └── KEDA multi-trigger
```

---

## 🛡️ Cluster Autoscaler / Karpenter

HPA pod ekler ama **node yetersizse** ne olur?

### Cluster Autoscaler
```yaml
# AWS EKS örneği
apiVersion: autoscaling/v1
kind: ClusterAutoscaler
spec:
  resourceLimits:
    minNodes: 3
    maxNodes: 50
  scaleDown:
    enabled: true
    delayAfterAdd: 10m
```

### Karpenter (önerilen, AWS)
```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: [amd64, arm64]
        - key: karpenter.sh/capacity-type
          operator: In
          values: [spot, on-demand]
      nodeClassRef:
        name: default
  limits:
    cpu: "1000"
  disruption:
    consolidationPolicy: WhenUnderutilized
```

→ Karpenter otomatik node oluşturur (instance type seçer), idle'da consolidate eder.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| HPA + VPA Auto aynı resource | Race condition | HPA + VPA Off (recommendation) |
| HPA min=1, max=2 | Effective scaling yok | min 3 (HA), max gerçek peak |
| Scale down çok hızlı | Pod thrashing | stabilizationWindowSeconds 300+ |
| KEDA scale-to-zero ama health check yetersiz | İlk request slow (cold start) | warmup veya prewarm |
| Cluster Autoscaler yok HPA + büyük scale up | Pod pending | CA / Karpenter |
| HPA target %95 CPU | Spike'da çökme | %70 hedef (headroom) |
| Custom metric production'da test'siz | False scaling | Prometheus query test |
| KEDA queue trigger threshold yanlış | Yanlış scale | Burst pattern analiz |
| Resource request set değil | HPA % hesaplayamaz | requests zorunlu |
| HPA üzerinde manuel `kubectl scale` | HPA geri alır | HPA disable veya değiştir |

---

## 📋 Autoscaling Production Checklist

```
[ ] Resource requests/limits set (HPA için zorunlu)
[ ] HPA: min 3 replica (HA)
[ ] HPA: target %70 CPU (headroom)
[ ] HPA behavior: scale up fast, scale down slow
[ ] Multi-metric: CPU + Memory veya custom
[ ] Custom metric: Prometheus adapter
[ ] VPA: Off mode (recommendation), manuel uygula
[ ] KEDA: queue / cron / Prometheus trigger
[ ] Scale-to-zero (uygunsa, idle queue)
[ ] Cluster Autoscaler / Karpenter (node scaling)
[ ] PodDisruptionBudget (HPA scale down sırası)
[ ] Quarterly: HPA target review
[ ] Monitoring: HPA events + scaling history
[ ] Load test: HPA gerçek peak'i karşılıyor mu
```

---

## 📚 Referanslar

- **HPA Docs** — kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
- **VPA Docs** — github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler
- **KEDA** — keda.sh
- **Karpenter** — karpenter.sh
- **Cluster Autoscaler** — github.com/kubernetes/autoscaler
- [`Production-Checklist.md`](Production-Checklist.md)
- [`Resource-Limits-Guide.md`](Resource-Limits-Guide.md)
- [`11-SRE/Capacity-Planning.md`](../11-SRE/Capacity-Planning.md)
- [`14-Sustainability/Carbon-Aware-Computing.md`](../14-Sustainability/Carbon-Aware-Computing.md) — KEDA carbon scaler

---

> *"Autoscaling 'pod sayısı oynamak' değil — **doğru tool, doğru
> yer**. HPA + VPA + KEDA + Karpenter dörtlüsü doğru kombinasyon
> ile **maliyet %50 azaltır + reliability ↑**."*
