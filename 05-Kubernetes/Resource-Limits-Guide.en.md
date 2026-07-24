---
description: "Kubernetes resource management guide: the requests vs limits difference, QoS classes, OOMKilled behavior, and how to find the right CPU/memory numbers."
tags:
  - Kubernetes
  - Performance
  - Cost Optimization
  - SRE
  - Containers
---
# Resource Limits Guide — Request, Limit, QoS

> *"A team that doesn't know what setting `requests: 100m, limits: 2000m`
> actually means gets surprised by OOMKilled + noisy neighbor + pod
> eviction. **Resource management** is K8s's quiet discipline."*

This guide answers requests vs limits, QoS classes, OOM behavior, and the
"how do I find the right numbers" question.

---

## 📐 Requests vs Limits

### Requests
- Used for pod **scheduling**
- This much resource is **reserved** on the node
- The pod gets it as a guarantee

### Limits
- The **maximum** the pod can use
- Exceeding the CPU limit → **throttle**
- Exceeding the memory limit → **OOMKilled**

```yaml
resources:
  requests:
    cpu: 250m       # 0.25 core guaranteed
    memory: 512Mi    # 512 MB guaranteed
  limits:
    cpu: 1000m       # 1 core max (throttle when exceeded)
    memory: 1Gi      # 1 GB max (OOMKilled when exceeded)
```

---

## 🏷️ QoS Classes

K8s assigns pods one of 3 QoS classes:

| Class | Condition | Eviction priority |
|---|---|---|
| **Guaranteed** | requests = limits on all containers (CPU + Memory) | Evicted last |
| **Burstable** | requests set but < limits | Middle |
| **BestEffort** | No requests/limits at all | Evicted first |

### Guaranteed pod
```yaml
resources:
  requests:
    cpu: 1000m
    memory: 1Gi
  limits:
    cpu: 1000m       # = requests
    memory: 1Gi      # = requests
```

### Burstable pod
```yaml
resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 1000m       # > requests → burstable
    memory: 1Gi
```

### BestEffort pod (don't)
```yaml
# No resources at all
spec:
  containers:
    - image: ...
```

> 🔑 **In production, BestEffort = mistake**. It's the first to go on eviction.

---

## 🎯 Finding the Right Numbers

### Step 1: Profile it
```bash
# Run 1 week in production
# Prometheus query
kubectl top pods -n <NS>

# CPU usage p95 (1 hour window)
quantile_over_time(0.95,
  rate(container_cpu_usage_seconds_total[5m])
)

# Memory peak
max_over_time(
  container_memory_working_set_bytes[1h]
)
```

### Step 2: Calculate
```
Request = p50 (average) + 20% buffer
Limit   = p95 + 50% buffer
```

### Example
```
P50 CPU usage: 200m
P95 CPU usage: 600m

Request: 200 × 1.2 = 240m → 250m
Limit:   600 × 1.5 = 900m → 1000m
```

### Step 3: Test
- Any throttle during HPA scaling spikes?
- Is the memory limit being exceeded (OOMKilled)?
- If OOMKilled → raise the limit

---

## 🔥 OOM Behavior

### Memory limit exceeded
```
[Pod] memory > limit
   │
   ▼
[OOM Killer (cgroup)] kills the pod
   │
   ▼
[Pod restart] (RestartPolicy: Always default)
```

### `kubectl describe pod`
```yaml
Last State: Terminated
  Reason: OOMKilled
  Exit Code: 137
```

### CPU limit exceeded
```
[Pod] CPU > limit
   │
   ▼
[Throttle] (kernel cgroup CPU throttling)
   │
   ▼
Pod slows down (throttle, not kill)
```

> 🔑 **CPU = throttle, Memory = kill**.

---

## ⚠️ CPU Limit — A Contested Trade-off

### Argument 1: CPU limit is mandatory
- Prevents noisy neighbor
- Predictable scheduling

### Argument 2: CPU limit is harmful (controversial)
- Throttling increases latency
- Performance drops during spikes
- Modern argument: "setting requests is enough, limits are harmful"

### Practical recommendation (2026)
| Workload | CPU limit |
|---|---|
| Latency-critical (HTTP API) | **None** or very high |
| Batch / background | Yes (predictable) |
| Multi-tenant | Yes (prevent noisy neighbor) |
| Trusted single-tenant | None |

> 🔑 **Memory limit is always mandatory**. CPU limit depends on the case.

---

## 📦 Memory Best Practices

### `requests = limits` (Guaranteed QoS)
```yaml
# Stateful, critical service
resources:
  requests: {memory: 2Gi}
  limits: {memory: 2Gi}
```

### Buffer math
- JVM: heap + metaspace + native = ~1.5-2x heap
- Go: garbage collector ~10-20% buffer
- Python: minimal overhead (~5%)
- Node: V8 heap + native = ~50% buffer

```yaml
# Java app, heap 1Gi
JAVA_OPTS: "-Xms1g -Xmx1g"
resources:
  limits: {memory: 2Gi}   # heap × 2 buffer
```

---

## 🛠️ ResourceQuota (Namespace Total Limit)

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a-quota
  namespace: team-a
spec:
  hard:
    requests.cpu: "20"      # 20 cores total
    requests.memory: 40Gi
    limits.cpu: "40"
    limits.memory: 80Gi
    pods: "100"
```

> 🔑 The namespace **can't reserve** more than 20 cores.

---

## 🎁 LimitRange (Default per Container)

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: team-a
spec:
  limits:
    - default:           # for containers with no limit set
        cpu: 500m
        memory: 512Mi
      defaultRequest:    # for those with no request set
        cpu: 100m
        memory: 128Mi
      max:               # max allowed
        cpu: 4000m
        memory: 8Gi
      min:               # min required
        cpu: 50m
        memory: 64Mi
      type: Container
```

→ If a developer forgets resources, the default is applied + there's a max cap.

---

## 📊 Monitoring + Alerting

### Key metrics
```promql
# Memory usage / limit
sum(container_memory_working_set_bytes{container!=""}) by (pod, namespace)
/
sum(kube_pod_container_resource_limits{resource="memory"}) by (pod, namespace)

# CPU throttling
rate(container_cpu_cfs_throttled_seconds_total[5m])
> 0

# OOMKilled events
kube_pod_container_status_terminated_reason{reason="OOMKilled"}
```

### Alarms
```yaml
- alert: PodMemoryHigh
  expr: |
    sum(container_memory_working_set_bytes) by (pod) /
    sum(kube_pod_container_resource_limits{resource="memory"}) by (pod) > 0.9
  for: 5m

- alert: PodCPUThrottling
  expr: rate(container_cpu_cfs_throttled_seconds_total[5m]) > 0.5
  for: 10m

- alert: PodOOMKilled
  expr: increase(kube_pod_container_status_terminated_reason{reason="OOMKilled"}[10m]) > 0
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| No resources defined (BestEffort) | Eviction first | Always set requests/limits |
| Request = limit everywhere (Guaranteed) | Wasted resources | Burstable in most places |
| No memory limit | OOM unbounded → node down | Memory limit mandatory |
| CPU limit very low (<500m) latency-critical | Throttle | High limit or none |
| Guessing without profiling | Wrong numbers | Prometheus + load test |
| Use `1000m` instead of `1`? | Same thing | Consistent style |
| Java heap = limit | Heap + native overhead | Heap × 1.5-2 limit |
| No ResourceQuota | Noisy neighbor | Namespace quota |
| No LimitRange | Incomplete manifest with no defaults | Defaults via LimitRange |
| No OOMKilled monitoring | Silent pod restart | Alarm + dashboard |

---

## 📋 Resource Management Checklist

```
[ ] requests + limits on all pods
[ ] Memory limit mandatory (every container)
[ ] CPU limit policy decided (latency-critical: none, batch: yes)
[ ] Profile-based sizing (Prometheus + load test)
[ ] Java app: heap × 1.5-2 buffer
[ ] ResourceQuota on every namespace
[ ] LimitRange default request/limit
[ ] VPA recommendation mode (per-pod recommendation)
[ ] HPA target 70% CPU (headroom)
[ ] PDB defined
[ ] Monitoring: memory/cpu utilization, throttling, OOM
[ ] Alert: PodMemoryHigh, OOMKilled, CPUThrottling
[ ] Quarterly: resource right-sizing review
```

---

## 📚 References

- **K8s Resource Management** — kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- **Pod QoS** — kubernetes.io/docs/concepts/workloads/pods/pod-qos/
- **VPA** — github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler
- **CPU Limits Considered Harmful** (Tim Hockin) — community discussion
- [`HPA-VPA-KEDA.md`](HPA-VPA-KEDA.md)
- [`Production-Checklist.md`](Production-Checklist.md)
- [`Multi-Tenancy-Patterns.md`](Multi-Tenancy-Patterns.md)
- [`11-SRE/Capacity-Planning.md`](../11-SRE/Capacity-Planning.md)

---

> *"Setting resources isn't 'guessing' — it's **data**. Profile, calculate,
> test. A wrongly set limit is an **OOMKilled at midnight** alarm. A
> correctly set limit is **predictable** prod."*

---

> 🎓 **Learning Path:** This document is used as a "Read first" resource in the [`D2`](../22-Learning-Path/block-d-orchestration/D2-k8s-production.md) module.
