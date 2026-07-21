---
description: "Kubernetes resource yönetimi rehberi: requests vs limits farkı, QoS class'ları, OOMKilled davranışı ve doğru CPU/memory sayılarının nasıl bulunacağı."
tags:
  - Kubernetes
  - Performance
  - Cost Optimization
  - SRE
  - Containers
---
# Resource Limits Guide — Request, Limit, QoS

> *"`requests: 100m, limits: 2000m` setlemenin ne anlamı geldiğini
> bilmeyen ekip, OOMKilled + noisy neighbor + pod eviction sürprizleri
> yaşıyor. **Resource yönetimi** K8s'in sessiz disiplinidir."*

Bu rehber requests vs limits, QoS class'ları, OOM behavior ve "doğru
sayılar nasıl bulunur" sorusunun cevabını verir.

---

## 📐 Requests vs Limits

### Requests
- Pod **scheduling** için kullanılır
- Node'da bu kadar resource **rezerve edilir**
- Pod garanti olarak alır

### Limits
- Pod **maximum** kullanabileceği
- CPU limit aşınırsa **throttle**
- Memory limit aşınırsa **OOMKilled**

```yaml
resources:
  requests:
    cpu: 250m       # 0.25 core garanti
    memory: 512Mi    # 512 MB garanti
  limits:
    cpu: 1000m       # 1 core max (aşınca throttle)
    memory: 1Gi      # 1 GB max (aşınca OOMKilled)
```

---

## 🏷️ QoS Classes

K8s pod'lara 3 QoS class atar:

| Class | Şart | Eviction önceliği |
|---|---|---|
| **Guaranteed** | Tüm container'larda requests = limits (CPU + Memory) | En son evict |
| **Burstable** | requests set ama < limits | Orta |
| **BestEffort** | Hiçbir requests/limits yok | İlk evict |

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

### BestEffort pod (yapma)
```yaml
# Hiç resources yok
spec:
  containers:
    - image: ...
```

> 🔑 **Production'da BestEffort = hata**. Eviction'da ilk gider.

---

## 🎯 Doğru Sayıları Bulma

### Adım 1: Profile et
```bash
# 1 hafta production'da çalış
# Prometheus query
kubectl top pods -n <NS>

# CPU kullanım p95 (1 saat penceresi)
quantile_over_time(0.95,
  rate(container_cpu_usage_seconds_total[5m])
)

# Memory peak
max_over_time(
  container_memory_working_set_bytes[1h]
)
```

### Adım 2: Hesapla
```
Request = p50 (ortalama) + %20 buffer
Limit   = p95 + %50 buffer
```

### Örnek
```
P50 CPU usage: 200m
P95 CPU usage: 600m

Request: 200 × 1.2 = 240m → 250m
Limit:   600 × 1.5 = 900m → 1000m
```

### Adım 3: Test
- HPA scaling spike'larında throttle var mı?
- Memory limit aşınıyor mu (OOMKilled)?
- Eğer OOMKilled → limit artır

---

## 🔥 OOM Davranışı

### Memory limit aşıldı
```
[Pod] memory > limit
   │
   ▼
[OOM Killer (cgroup)] pod'u kill eder
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

### CPU limit aşıldı
```
[Pod] CPU > limit
   │
   ▼
[Throttle] (kernel cgroup CPU throttling)
   │
   ▼
Pod yavaşlar (kill değil, throttle)
```

> 🔑 **CPU = throttle, Memory = kill**.

---

## ⚠️ CPU Limit — Tartışmalı Trade-off

### Argüman 1: CPU limit zorunlu
- Noisy neighbor önler
- Predictable scheduling

### Argüman 2: CPU limit zararlı (controversial)
- Throttling latency'i artırır
- Spike'larda performance düşer
- Modern argümanlar: "request set yeter, limit zararlı"

### Pratik öneri (2026)
| Workload | CPU limit |
|---|---|
| Latency-critical (HTTP API) | **Yok** veya çok yüksek |
| Batch / background | Var (predictable) |
| Multi-tenant | Var (noisy neighbor önle) |
| Trusted single-tenant | Yok |

> 🔑 **Memory limit her zaman zorunlu**. CPU limit duruma göre.

---

## 📦 Memory Best Practices

### `requests = limits` (Guaranteed QoS)
```yaml
# Stateful, kritik servis
resources:
  requests: {memory: 2Gi}
  limits: {memory: 2Gi}
```

### Buffer hesabı
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
    requests.cpu: "20"      # toplam 20 core
    requests.memory: 40Gi
    limits.cpu: "40"
    limits.memory: 80Gi
    pods: "100"
```

> 🔑 Namespace 20 core'dan fazlasını **rezerve edemez**.

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
    - default:           # limit set edilmemiş container'lar için
        cpu: 500m
        memory: 512Mi
      defaultRequest:    # request set edilmemiş için
        cpu: 100m
        memory: 128Mi
      max:               # max izinli
        cpu: 4000m
        memory: 8Gi
      min:               # min zorunlu
        cpu: 50m
        memory: 64Mi
      type: Container
```

→ Geliştirici resources unutursa default uygulanır + max sınır vardır.

---

## 📊 Monitoring + Alerting

### Anahtar metrikler
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

### Alarmlar
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

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Resources tanımlı değil (BestEffort) | Eviction first | Always set requests/limits |
| Request = limit her yer (Guaranteed) | Resource israfı | Burstable çoğu yerde |
| Memory limit yok | OOM unbounded → node down | Memory limit zorunlu |
| CPU limit very low (<500m) latency-critical | Throttle | Yüksek limit veya yok |
| Profile etmeden tahmin | Yanlış sayılar | Prometheus + load test |
| `1` yerine `1000m` kullan? | Aynı şey | Tutarlı stil |
| Java heap = limit | Heap + native overhead | Heap × 1.5-2 limit |
| ResourceQuota yok | Noisy neighbor | Namespace quota |
| LimitRange yok | Default'lar olmadan eksik manifest | LimitRange ile default |
| OOMKilled monitoring yok | Sessiz pod restart | Alarm + dashboard |

---

## 📋 Resource Management Checklist

```
[ ] Tüm pod'larda requests + limits
[ ] Memory limit zorunlu (her container)
[ ] CPU limit politikası belli (latency-critical: yok, batch: var)
[ ] Profile-based sizing (Prometheus + load test)
[ ] Java app: heap × 1.5-2 buffer
[ ] ResourceQuota her namespace
[ ] LimitRange default request/limit
[ ] VPA recommendation mode (per-pod öneri)
[ ] HPA target %70 CPU (headroom)
[ ] PDB tanımlı
[ ] Monitoring: memory/cpu utilization, throttling, OOM
[ ] Alert: PodMemoryHigh, OOMKilled, CPUThrottling
[ ] Quarterly: resource right-sizing review
```

---

## 📚 Referanslar

- **K8s Resource Management** — kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- **Pod QoS** — kubernetes.io/docs/concepts/workloads/pods/pod-qos/
- **VPA** — github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler
- **CPU Limits Considered Harmful** (Tim Hockin) — community discussion
- [`HPA-VPA-KEDA.md`](HPA-VPA-KEDA.md)
- [`Production-Checklist.md`](Production-Checklist.md)
- [`Multi-Tenancy-Patterns.md`](Multi-Tenancy-Patterns.md)
- [`11-SRE/Capacity-Planning.md`](../11-SRE/Capacity-Planning.md)

---

> *"Resource set'i 'tahmin' değil, **veri**. Profile et, hesapla,
> test et. Yanlış set'lenmiş limit, **gece OOMKilled** alarmı.
> Doğru set'lenmiş limit, **predictable** prod."*
