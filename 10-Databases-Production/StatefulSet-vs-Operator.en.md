---
description: "Managing stateful workloads on Kubernetes: where a plain StatefulSet is enough, when the operator pattern becomes mandatory, and the decision tree."
tags:
  - Databases
  - Kubernetes
  - PostgreSQL
  - Platform Engineering
---
# StatefulSet vs Operator — Stateful Workloads on K8s

> *"How do you put Postgres on K8s? Manually manage a StatefulSet, or
> use the operator pattern. **In 2026 the operator is standard**, manual
> StatefulSet is only for basic stateful workloads."*

This guide covers where a StatefulSet is enough, when the operator
becomes mandatory, and the decision tree.

---

## ⚖️ In One Sentence

| Approach | Philosophy |
|---|---|
| **Plain StatefulSet** | "Manage manually, K8s is just pod orchestration" |
| **Operator** (CRD-based) | "Domain-specific automation: failover, backup, upgrade" |

---

## 📐 StatefulSet — Where It's Enough

### Use case
- **Stateless-ish state**: Redis cache (data loss is acceptable)
- **Manual-managed DB**: single-instance dev Postgres
- **Custom workload**: a stateful app you wrote yourself

### Manifest
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis
spec:
  serviceName: redis
  replicas: 3
  selector:
    matchLabels: {app: redis}
  template:
    spec:
      containers:
        - name: redis
          image: redis:7
          volumeMounts:
            - name: data
              mountPath: /data
  volumeClaimTemplates:
    - metadata: {name: data}
      spec:
        accessModes: [ReadWriteOnce]
        resources: {requests: {storage: 10Gi}}
```

### ✅ Pro
- K8s native, simple
- Compatible with all K8s tooling
- Low operational overhead

### ❌ Con
- No HA failover (manual)
- No backup (manual)
- No upgrade orchestration
- No cluster-wide health management

> 🔑 **StatefulSet is enough for**: Redis cache, NATS, custom worker.

---

## 🤖 Operator — Mandatory for Production DBs

### Why?
Stateful workloads need a **complex lifecycle**:
- Primary failover
- Automated backup + restore
- Version upgrade (rolling, validation)
- Quorum management
- Encryption rotation
- Cross-region replication

**Operator** = embeds this logic as a K8s controller.

### Anatomy
```
[CRD: Cluster]                  ← user manifest (declarative)
   │
   ▼
[Operator (controller pod)]     ← reconcile loop
   │
   ├── Creates StatefulSet
   ├── Manages PVC
   ├── Automatic failover
   ├── Triggers backup
   └── Orchestrates upgrade
```

### Use case
- **Postgres**: CloudNativePG, Crunchy, Zalando
- **MySQL**: Vitess, Percona, MySQL Operator
- **Redis**: Redis Operator, Redis Enterprise Operator
- **Kafka**: Strimzi
- **MongoDB**: MongoDB Community Operator
- **Elasticsearch**: ECK (Elastic Cloud on K8s)
- **etcd**: etcd Operator

> Detail: [`Operator-Patterns.md`](Operator-Patterns.md) (Postgres-focused).

---

## 🌳 Decision Tree

```
START
  │
  ├── Production DB (Postgres / MySQL / Mongo)?
  │     │
  │     └── Operator mandatory (CloudNativePG / Crunchy / etc.)
  │
  ├── Stateful queue (Kafka / NATS)?
  │     │
  │     ├── Kafka → Strimzi
  │     └── NATS → StatefulSet OK (simple setup)
  │
  ├── Cache (Redis / Memcached)?
  │     │
  │     ├── Stateless cache (data loss OK) → StatefulSet
  │     └── Persistent / sentinel HA → Redis Operator
  │
  ├── Search (Elasticsearch / OpenSearch)?
  │     │
  │     └── ECK / OpenSearch Operator
  │
  ├── Custom stateful workload (one you wrote yourself)?
  │     │
  │     └── StatefulSet (write a custom controller if needed)
  │
  └── Dev / lab DB?
        │
        └── Simple StatefulSet (operator is unneeded overhead)
```

---

## 📊 Comparison Table

| Dimension | StatefulSet | Operator |
|---|---|---|
| **Setup** | YAML | Operator install + CRD |
| **Failover** | Manual | Automatic |
| **Backup** | Manual script | Native (CRD-based) |
| **Upgrade** | Manual rolling | Orchestrated |
| **Configuration drift** | Manual detect | Continuous reconcile |
| **Multi-cluster** | Manual | Native (operator-dependent) |
| **Operational overhead** | High | Low (depends on operator) |
| **Learning curve** | Low | Medium (CRD spec) |
| **Vendor lock-in** | None | Operator-specific |
| **2026 prod recommendation** | Niche | **Standard** |

---

## 🛠️ StatefulSet Best Practices (If You're Using It)

### 1. PodDisruptionBudget mandatory
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: redis
spec:
  minAvailable: 2
  selector:
    matchLabels: {app: redis}
```

### 2. Pod anti-affinity (different node)
```yaml
spec:
  template:
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels: {app: redis}
              topologyKey: kubernetes.io/hostname
```

### 3. Fast SSD storage class
```yaml
spec:
  volumeClaimTemplates:
    - spec:
        storageClassName: <FAST_SSD>
```

### 4. Headless service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: redis
spec:
  clusterIP: None
  selector: {app: redis}
```

→ Pod-level DNS: `redis-0.redis.<NS>.svc.cluster.local`.

### 5. PreStop hook + graceful shutdown
```yaml
lifecycle:
  preStop:
    exec:
      command: ["redis-cli", "SHUTDOWN", "NOSAVE"]
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Postgres prod StatefulSet (no operator) | Manual failover, no backup | CloudNativePG / Crunchy |
| Operator + manual `kubectl edit` | Drift | GitOps + ArgoCD |
| StatefulSet + single replica in prod | SPOF | 3+ replicas |
| PVC ReadWriteMany for cache | Performance | RWO + per-pod PVC |
| No PDB | Pod loss during drain | Set minAvailable |
| Slow HDD storage class | DB latency | NVMe / SSD |
| StatefulSet upgrade `OnDelete` strategy | Manual pod delete | RollingUpdate |
| Single guess for volume size | Disk full | Generous + alarm + expand |
| Operator + StatefulSet mixed management | Unclear who's in charge | Operator manages, StatefulSet read-only |

---

## 📋 Decision Checklist

```
[ ] Workload type: DB / queue / cache / search / custom?
[ ] Production or dev/lab?
[ ] HA requirement (automatic failover)?
[ ] Backup need?
[ ] Is there an operator (community / commercial)?
[ ] Operator maturity (CNCF / production-grade)?
[ ] Is vendor lock-in acceptable?
[ ] Is there operational overhead capacity?

Decision: StatefulSet vs Operator
```

---

## 📚 References

- **K8s StatefulSet** — kubernetes.io/docs/concepts/workloads/controllers/statefulset/
- **Operator Pattern** — kubernetes.io/docs/concepts/extend-kubernetes/operator/
- **OperatorHub.io** — operatorhub.io
- **Awesome Operators** — github.com/operator-framework/awesome-operators
- [`Operator-Patterns.md`](Operator-Patterns.md) — Postgres operators
- [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md)
- [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md)
- [`Backup-Restore-Patterns.md`](Backup-Restore-Patterns.md)
- [`Connection-Pooling.md`](Connection-Pooling.md)

---

> *"StatefulSet is K8s's **basic tool**; the operator is the **specialist
> tool**. Production DB → operator mandatory; cache/queue → StatefulSet
> is enough. Wrong choice = you find out **6 months later**, during a failover."*
