---
description: "Kubernetes multi-tenancy modelleri: soft (namespace + RBAC), hard, vCluster ve cluster-per-tenant; izolasyon, maliyet ve kullanim karsilastirmasi."
tags:
  - Kubernetes
  - Security
  - Networking
  - Platform Engineering
  - Policy as Code
---
# Multi-Tenancy Patterns — Soft, Hard, Hibrit

> *"Tek cluster + 10 ekip. 'Her ekip kendi namespace'i' diyen ekip,
> 6 ay sonra 'team A team B'nin secret'larını görüyor' postmortem'i
> yazar. **Multi-tenancy** disiplin gerektirir."*

Bu rehber K8s multi-tenancy modellerini — soft, hard, vCluster, cluster-per-tenant — karşılaştırır.

---

## ⚖️ 4 Multi-Tenancy Modeli

| Model | İzolasyon | Maliyet | Kullanım |
|---|---|---|---|
| **Soft (namespace)** | Logical | Düşük | Aynı org, güvenilen ekipler |
| **Hard (NS + policy)** | Strong logical | Düşük-orta | Internal tenant'lar, audit gerekli |
| **vCluster** | Virtual cluster | Orta | API isolation gerekli, cluster-admin per tenant |
| **Cluster-per-tenant** | Physical | Yüksek | SaaS müşteri başına, full isolation |

---

## 🌱 1️⃣ Soft Multi-Tenancy (Namespace + RBAC)

### Mimari
```
[Cluster]
  ├── namespace: team-a
  │   ├── pod, service, secret (team-a)
  │   └── RoleBinding: team-a → developer role
  ├── namespace: team-b
  │   ├── ...
  │   └── RoleBinding: team-b → developer role
  └── namespace: team-c
```

### Manifest
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: team-a
  labels:
    team: team-a
    pod-security.kubernetes.io/enforce: restricted
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: team-a
  name: developer
rules:
  - apiGroups: ["", "apps"]
    resources: ["pods", "deployments", "services", "configmaps"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-a-devs
  namespace: team-a
subjects:
  - kind: Group
    name: <ORG>:team-a
roleRef:
  kind: Role
  name: developer
```

### ✅ Pro
- Hızlı setup
- Cluster maliyeti tek
- Network arası kolay (NetworkPolicy ile filtre)

### ❌ Con
- Cluster-level resource (CRD, MutatingWebhook) shared
- Privileged escape → tüm cluster
- Resource exhaustion (1 tenant tüm CPU)

---

## 🛡️ 2️⃣ Hard Multi-Tenancy (Soft + Policies)

Soft + ek katman:

### ResourceQuota
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a-quota
  namespace: team-a
spec:
  hard:
    requests.cpu: "20"
    requests.memory: 40Gi
    limits.cpu: "40"
    limits.memory: 80Gi
    persistentvolumeclaims: "10"
    services.loadbalancers: "2"
    pods: "100"
```

### LimitRange (default request/limit)
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: team-a
spec:
  limits:
    - default:
        cpu: 500m
        memory: 512Mi
      defaultRequest:
        cpu: 100m
        memory: 128Mi
      type: Container
```

### NetworkPolicy default-deny
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: team-a
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
```

### Pod Security Standards
```yaml
metadata:
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### Kyverno policies
- `disallow-privileged-containers`
- `disallow-host-namespaces`
- `require-resource-limits`
- `restrict-image-registries`

### Capsule (multi-tenancy operator)
```yaml
apiVersion: capsule.clastix.io/v1beta2
kind: Tenant
metadata:
  name: team-a
spec:
  owners:
    - kind: Group
      name: <ORG>:team-a
  namespaceOptions:
    quota: 10
  resourceQuotas:
    items:
      - hard:
          limits.cpu: "20"
          limits.memory: 40Gi
  networkPolicies:
    items:
      - podSelector: {}
        policyTypes: [Ingress, Egress]
```

> 🔑 Capsule: tenant-aware namespace + quota + policy management.

---

## 🌐 3️⃣ vCluster — Virtual Cluster

> Bir K8s cluster içinde **mini K8s control plane** çalıştır. Her tenant kendi virtual cluster'ı.

### Setup
```bash
vcluster create team-a --namespace vcluster-team-a
```

### Mimari
```
[Host Cluster: prod]
  └── Namespace: vcluster-team-a
      ├── Virtual control plane (k3s / vcluster api-server)
      ├── etcd (sqlite veya separate)
      └── Pod'lar host cluster'da çalışır
          (vcluster pod'larını sync eder)
```

### Tenant erişimi
```bash
vcluster connect team-a
kubectl config use-context vcluster_team-a
kubectl get nodes   # virtual nodes
```

### ✅ Pro
- Tenant **cluster-admin** olabilir kendi vcluster'ında
- CRD'ler tenant'a izole
- Multi-tenant SaaS için ideal

### ❌ Con
- Operasyonel karmaşıklık
- Performance overhead (control plane çoğaltma)
- Network latency (host ↔ vcluster)

> 🔑 **Use case**: Her ekibin kendi cert-manager'ı, kendi CRD'si gerekiyorsa.

---

## 🏢 4️⃣ Cluster-per-Tenant (Hard Isolation)

```
[Cluster A] = Tenant 1
[Cluster B] = Tenant 2
[Cluster C] = Tenant 3
...
```

### ✅ Pro
- Mutlak izolasyon
- Compliance (kernel-level)
- Müşteri verisi sızıntı imkansız (cluster-level)

### ❌ Con
- Maliyet 10x (her cluster için master + worker)
- Operasyonel yük (N cluster yönetim)
- ArgoCD ApplicationSet zorunlu

### Use case: SaaS premium tier
- Banking, healthcare müşteri başına cluster
- Compliance-driven
- ROI yüksek müşteri için

---

## 🌳 Karar Ağacı

```
START
  │
  ├── Internal team'ler (aynı org, güven OK)?
  │     │
  │     └── Soft multi-tenancy (namespace + RBAC)
  │
  ├── Internal team'ler ama compliance + audit?
  │     │
  │     └── Hard (Capsule + Kyverno + ResourceQuota)
  │
  ├── Tenant kendi cluster-admin olmalı (CRD, operator)?
  │     │
  │     └── vCluster
  │
  └── SaaS premium müşteri + compliance + tam izolasyon?
         │
         └── Cluster-per-tenant
```

---

## 🚧 Yaygın Sorunlar

### Resource starvation
- 1 tenant tüm CPU'yu yedi → diğerleri pending
- **Çözüm**: ResourceQuota + LimitRange

### Cross-namespace network
- team-a pod'u team-b service'ine konuşuyor
- **Çözüm**: NetworkPolicy default-deny + explicit allow

### Privileged escape
- team-a tenant'ı `securityContext.privileged: true` deniyor
- **Çözüm**: PSS restricted + Kyverno verify

### Cluster-level resource competition
- Ingress controller paylaşımlı, port çakışması
- **Çözüm**: Per-tenant Ingress veya tek Ingress + multi-host

### Audit log mixing
- "Kim ne yaptı?" zor
- **Çözüm**: Audit policy per-namespace + structured log

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tek namespace, "labels ile ayır" | Logical isolation yok | Per-tenant namespace |
| ResourceQuota yok | Noisy neighbor | Quota + LimitRange |
| NetworkPolicy yok | Cross-tenant traffic | Default-deny + allowlist |
| PSS baseline (restricted değil) | Privileged escape | restricted enforce |
| Cluster-admin tenant'a verme | Compromise = cluster | vCluster veya Role-based |
| CRD shared, tenant ihtiyacı farklı | Conflict | vCluster |
| Audit yok / shared | Forensic eksik | Per-namespace audit policy |
| Ingress controller paylaşımlı, port çakışması | Hata | Multi-host veya per-tenant |
| Storage class shared, tenant boyut limiti yok | Disk full | Per-tenant storage quota |
| Tenant başına separate K8s SA yok | Cross-tenant token kullanım | Per-tenant ServiceAccount |

---

## 📋 Multi-Tenancy Production Checklist

```
[ ] Tenancy modeli seçimi (soft / hard / vCluster / cluster-per)
[ ] Per-tenant namespace
[ ] RBAC: Role + RoleBinding per tenant
[ ] ResourceQuota
[ ] LimitRange (default request/limit)
[ ] NetworkPolicy: default-deny + allowlist
[ ] PSS: restricted enforce
[ ] Kyverno policies (disallow-privileged, vb.)
[ ] Audit policy per-namespace
[ ] Storage class quota
[ ] Per-tenant Ingress veya multi-host
[ ] Per-tenant cert-manager namespace (varsa)
[ ] Capsule veya equivalent operator (büyük org)
[ ] Quarterly: tenant audit (cross-tenant violation?)
[ ] DR: tenant başına backup strategy
```

---

## 📚 Referanslar

- **K8s Multi-Tenancy WG** — github.com/kubernetes-sigs/multi-tenancy
- **Capsule** — capsule.clastix.io
- **vCluster** — vcluster.com
- **Kiosk** — github.com/loft-sh/kiosk (vCluster eski sürüm)
- [`Production-Checklist.md`](Production-Checklist.md)
- [`08-Security/Kubernetes-Hardening.md`](../08-Security/Kubernetes-Hardening.md)
- [`08-Security/Policy-as-Code-OPA-Kyverno.md`](../08-Security/Policy-as-Code-OPA-Kyverno.md)
- [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md)

---

> *"Multi-tenancy 'birkaç namespace açtım' değil — **disiplin
> kontroller**. ResourceQuota + NetworkPolicy + PSS + audit olmadan
> 'multi-tenant' iddiası **fasada**."*
