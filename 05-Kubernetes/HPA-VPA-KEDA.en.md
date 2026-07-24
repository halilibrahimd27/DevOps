---
description: "Kubernetes autoscaling guide: HPA (pod count), VPA (pod resource) and KEDA (event-driven) comparison, which one in which scenario, and how they work together."
tags:
  - Kubernetes
  - Performance
  - Cost Optimization
  - SRE
  - Observability
---
# HPA, VPA, KEDA — Complete K8s Autoscaling Guide

> *"3 different autoscalers, 3 different niches. HPA: pod count by CPU.
> VPA: pod resource by usage. KEDA: pod count by **event**
> (queue, cron, custom metric). **Which one, when**?"*

This guide compares Kubernetes' 3 main autoscalers, which one to prefer
in which scenario, and the patterns for running them together.

---

## ⚖️ 3 Autoscalers

| Tool | What | Method |
|---|---|---|
| **HPA** | Horizontal Pod Autoscaler | Pod count ↑↓ (CPU/Memory/custom metric) |
| **VPA** | Vertical Pod Autoscaler | Pod resource (CPU/Memory request) ↑↓ |
| **KEDA** | Kubernetes Event-Driven Autoscaler | Pod count, by **external events** |

---

## 🎯 HPA — Horizontal Pod Autoscaler

> Scales pod count horizontally (e.g. 3 → 10 → 3).

### Simple (CPU)
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
          averageUtilization: 70   # CPU 70% target
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

### Behavior tuning (scale up/down speed)
```yaml
behavior:
  scaleUp:
    stabilizationWindowSeconds: 0   # fast scale up
    policies:
      - type: Percent
        value: 100   # max 2x
        periodSeconds: 60
      - type: Pods
        value: 4     # add max 4 pods
        periodSeconds: 60
    selectPolicy: Max
  scaleDown:
    stabilizationWindowSeconds: 300   # wait 5 min
    policies:
      - type: Percent
        value: 25
        periodSeconds: 60
```

> 🔑 **Scale up fast, scale down slow** → flap prevention.

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
# HPA uses the custom metric
- type: Pods
  pods:
    metric: {name: http_requests_per_second}
    target: {type: AverageValue, averageValue: 100}
```

---

## 📦 VPA — Vertical Pod Autoscaler

> Adjusts pod resource (CPU/Memory) request/limit.

### Modes
| Mode | Behavior |
|---|---|
| `Off` | Recommendation only, resource unchanged (recommendation mode) |
| `Initial` | Resource set at pod creation, unchanged afterward |
| `Auto` | Updates resource by restarting the pod |
| `Recreate` | Kill the old pod, recreate with the new resource |

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
# See the recommendations
kubectl describe vpa payments-vpa
# Recommendation: cpu=234m memory=512Mi
```

→ A human reviews it, applies it manually to the deployment.

---

## ⚠️ HPA + VPA Together

```
HPA: pod count (horizontal)
VPA: pod resource (vertical)
   ↑
   └── Don't use both together for the same resource (CPU)!
       Conflict risk.

✅ GOOD: HPA CPU + VPA Memory
✅ GOOD: VPA Off mode + HPA in prod
❌ BAD: HPA Auto + VPA Auto same resource
```

> 🔑 **Production recommendation**: HPA active (pod count), VPA `Off` mode (recommendation only) → manual review + apply to the deployment.

---

## ⚡ KEDA — Event-Driven Autoscaler

> Extends HPA with "event sources". Queue depth, cron, AWS SQS, Kafka, Prometheus, etc.

### Installation
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
  pollingInterval: 30   # check the queue every 30 seconds
  cooldownPeriod: 300   # scale down after 5 min idle
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
# → scale when any one of them triggers
```

### Scale to zero
```yaml
minReplicaCount: 0   # no pods at all when idle
```

→ **0 pods** while the queue is empty (cost savings). Scales up fast when a message arrives.

---

## 🌳 Decision Tree

```
START
  │
  ├── Continuous HTTP traffic (bound to req/sec)?
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
  ├── Long idle period (hours sitting idle)?
  │     │
  │     └── KEDA + scale-to-zero
  │
  ├── Pod resource set wrong, constant OOM/idle?
  │     │
  │     └── VPA recommendation mode + apply manually
  │
  └── Multi-source event (queue + traffic + schedule)?
         │
         └── KEDA multi-trigger
```

---

## 🛡️ Cluster Autoscaler / Karpenter

HPA adds pods, but what happens **if there aren't enough nodes**?

### Cluster Autoscaler

> Cluster Autoscaler is **not** a CRD — it's a Deployment that reads the node group's (ASG) `min`/`max` values.
> Installed via Helm; it takes its scaling limit from the node group, not from a CRD.

```bash
# 1) Tag the node group ASG (required for autodiscovery):
#    k8s.io/cluster-autoscaler/enabled        = true
#    k8s.io/cluster-autoscaler/<CLUSTER_NAME> = owned

# 2) Install via Helm (with an IRSA role — write permission to the node group)
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=<CLUSTER_NAME> \
  --set awsRegion=<REGION> \
  --set 'rbac.serviceAccount.annotations.eks\.amazonaws\.com/role-arn=<IRSA_ROLE_ARN>'
```

`minNodes`/`maxNodes` are defined on the node group; e.g. EKS managed node group:
`--scaling-config minSize=3,maxSize=50,desiredSize=3`.

### Karpenter (recommended, AWS)
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

→ Karpenter creates nodes automatically (picks the instance type), consolidates when idle.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| HPA + VPA Auto same resource | Race condition | HPA + VPA Off (recommendation) |
| HPA min=1, max=2 | No effective scaling | min 3 (HA), max = real peak |
| Scale down too fast | Pod thrashing | stabilizationWindowSeconds 300+ |
| KEDA scale-to-zero but insufficient health check | First request slow (cold start) | warmup or prewarm |
| No Cluster Autoscaler with HPA + big scale up | Pod pending | CA / Karpenter |
| HPA target 95% CPU | Crash on spike | 70% target (headroom) |
| Custom metric untested in production | False scaling | Prometheus query test |
| KEDA queue trigger threshold wrong | Wrong scaling | Burst pattern analysis |
| Resource request not set | HPA can't compute % | requests required |
| Manual `kubectl scale` over HPA | HPA reverts it | Disable or change HPA |

---

## 📋 Autoscaling Production Checklist

```
[ ] Resource requests/limits set (required for HPA)
[ ] HPA: min 3 replicas (HA)
[ ] HPA: target 70% CPU (headroom)
[ ] HPA behavior: scale up fast, scale down slow
[ ] Multi-metric: CPU + Memory or custom
[ ] Custom metric: Prometheus adapter
[ ] VPA: Off mode (recommendation), apply manually
[ ] KEDA: queue / cron / Prometheus trigger
[ ] Scale-to-zero (if suitable, idle queue)
[ ] Cluster Autoscaler / Karpenter (node scaling)
[ ] PodDisruptionBudget (during HPA scale down)
[ ] Quarterly: HPA target review
[ ] Monitoring: HPA events + scaling history
[ ] Load test: does HPA handle the real peak
```

---

## 📚 References

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

> *"Autoscaling isn't 'fiddling with pod count' — it's **the right tool,
> the right place**. The HPA + VPA + KEDA + Karpenter quartet, in the
> right combination, **cuts cost by 50% + reliability ↑**."*
