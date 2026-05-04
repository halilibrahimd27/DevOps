# StatefulSet vs Operator — Stateful Workload K8s'de

> *"Postgres'i K8s'e nasıl koyarsın?  StatefulSet manuel yönet, ya
> da operator pattern. **2026'da operator standart**, manual
> StatefulSet sadece basic state'li workload için."*

Bu rehber StatefulSet'in nerede yeterli, operator'ün ne zaman zorunlu
olduğunu, ve karar ağacını anlatır.

---

## ⚖️ Tek Cümlede

| Yaklaşım | Felsefe |
|---|---|
| **Plain StatefulSet** | "Manuel yönet, K8s sadece pod orchestration" |
| **Operator** (CRD-based) | "Domain-specific automation: failover, backup, upgrade" |

---

## 📐 StatefulSet — Yeterli Olduğu Yerler

### Use case
- **Stateless-ish state**: Redis cache (data kaybedilebilir)
- **Manual-managed DB**: tek-instance dev Postgres
- **Custom workload**: senin yazdığın stateful app

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
- K8s native, basit
- Tüm K8s tooling uyumlu
- Az operasyonel yük

### ❌ Con
- HA failover yok (manuel)
- Backup yok (manuel)
- Upgrade orchestration yok
- Cluster-wide health management yok

> 🔑 **StatefulSet yeter**: Redis cache, NATS, custom worker.

---

## 🤖 Operator — Production DB için Zorunlu

### Niye?
Stateful workload'lar **karmaşık lifecycle** ister:
- Primary failover
- Automated backup + restore
- Version upgrade (rolling, validation)
- Quorum management
- Encryption rotation
- Cross-region replication

**Operator** = bu logic'i K8s controller olarak embed eder.

### Anatomi
```
[CRD: Cluster]                  ← user manifest (declarative)
   │
   ▼
[Operator (controller pod)]     ← reconcile loop
   │
   ├── StatefulSet oluşturur
   ├── PVC yönetir
   ├── Failover otomatik
   ├── Backup tetikler
   └── Upgrade orchestrate
```

### Use case
- **Postgres**: CloudNativePG, Crunchy, Zalando
- **MySQL**: Vitess, Percona, MySQL Operator
- **Redis**: Redis Operator, Redis Enterprise Operator
- **Kafka**: Strimzi
- **MongoDB**: MongoDB Community Operator
- **Elasticsearch**: ECK (Elastic Cloud on K8s)
- **etcd**: etcd Operator

> Detay: [`Operator-Patterns.md`](Operator-Patterns.md) (Postgres odaklı).

---

## 🌳 Karar Ağacı

```
START
  │
  ├── Production DB (Postgres / MySQL / Mongo)?
  │     │
  │     └── Operator zorunlu (CloudNativePG / Crunchy / vb.)
  │
  ├── Stateful queue (Kafka / NATS)?
  │     │
  │     ├── Kafka → Strimzi
  │     └── NATS → StatefulSet OK (basit setup)
  │
  ├── Cache (Redis / Memcached)?
  │     │
  │     ├── Stateless cache (data kaybı OK) → StatefulSet
  │     └── Persistent / sentinel HA → Redis Operator
  │
  ├── Search (Elasticsearch / OpenSearch)?
  │     │
  │     └── ECK / OpenSearch Operator
  │
  ├── Custom stateful workload (kendi yazdığın)?
  │     │
  │     └── StatefulSet (gerek varsa custom controller yaz)
  │
  └── Dev / lab DB?
        │
        └── StatefulSet basit (operator gereksiz overhead)
```

---

## 📊 Karşılaştırma Tablosu

| Boyut | StatefulSet | Operator |
|---|---|---|
| **Setup** | YAML | Operator install + CRD |
| **Failover** | Manuel | Otomatik |
| **Backup** | Manuel script | Native (CRD bazlı) |
| **Upgrade** | Manuel rolling | Orchestrated |
| **Configuration drift** | Manuel detect | Continuous reconcile |
| **Multi-cluster** | Manuel | Native (operator-bağlı) |
| **Operasyonel yük** | Yüksek | Düşük (operator'a bağlı) |
| **Öğrenme eğrisi** | Düşük | Orta (CRD spec) |
| **Vendor lock-in** | Yok | Operator-spesifik |
| **2026 prod öneri** | Niche | **Standart** |

---

## 🛠️ StatefulSet Best Practices (Kullanıyorsan)

### 1. PodDisruptionBudget zorunlu
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

### 2. Pod anti-affinity (farklı node)
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

### 3. Storage class fast SSD
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

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Postgres prod StatefulSet (operator yok) | Manuel failover, backup yok | CloudNativePG / Crunchy |
| Operator + manuel `kubectl edit` | Drift | GitOps + ArgoCD |
| StatefulSet + tek replica prod | SPOF | 3+ replica |
| PVC ReadWriteMany cache için | Performance | RWO + per-pod PVC |
| PDB yok | Drain'da pod kayıp | minAvailable set |
| Storage class yavaş HDD | DB latency | NVMe / SSD |
| StatefulSet upgrade `OnDelete` strategy | Manuel pod delete | RollingUpdate |
| Volume size tek tahmin | Disk full | Generous + alarm + expand |
| Operator + StatefulSet karışık | Hangi yöneliyor belirsiz | Operator yönetir, StatefulSet read-only |

---

## 📋 Decision Checklist

```
[ ] Workload türü: DB / queue / cache / search / custom?
[ ] Production mu, dev/lab mı?
[ ] HA gereksinim (failover otomatik mi?)?
[ ] Backup ihtiyacı?
[ ] Operator var mı (community / commercial)?
[ ] Operator olgunluğu (CNCF / production-grade)?
[ ] Vendor lock-in kabul edilebilir mi?
[ ] Operasyonel yük kapasitesi var mı?

Karar: StatefulSet vs Operator
```

---

## 📚 Referanslar

- **K8s StatefulSet** — kubernetes.io/docs/concepts/workloads/controllers/statefulset/
- **Operator Pattern** — kubernetes.io/docs/concepts/extend-kubernetes/operator/
- **OperatorHub.io** — operatorhub.io
- **Awesome Operators** — github.com/operator-framework/awesome-operators
- [`Operator-Patterns.md`](Operator-Patterns.md) — Postgres operator'lar
- [`Postgres-Production-Guide.md`](Postgres-Production-Guide.md)
- [`HA-Patroni-Stolon.md`](HA-Patroni-Stolon.md)
- [`Backup-Restore-Patterns.md`](Backup-Restore-Patterns.md)
- [`Connection-Pooling.md`](Connection-Pooling.md)

---

> *"StatefulSet K8s'in **temel araç**'ı; operator **uzman aracı**.
> Production DB → operator zorunlu; cache/queue → StatefulSet
> yeter. Yanlış seçim = **6 ay sonra** failover'da öğrenirsin."*
