---
description: "Kubernetes multi-tenancy models: soft (namespace + RBAC), hard, vCluster, and cluster-per-tenant; isolation, cost, and use-case comparison."
tags:
  - Kubernetes
  - Security
  - Networking
  - Platform Engineering
  - Policy as Code
---
# Multi-Tenancy Patterns — Soft, Hard, Hybrid

> *"One cluster + 10 teams. The team that says 'every team gets its own
> namespace' writes the 'team A is reading team B's secrets' postmortem
> six months later. **Multi-tenancy** takes discipline."*

This guide compares K8s multi-tenancy models — soft, hard, vCluster, cluster-per-tenant.

---

## ⚖️ The 4 Multi-Tenancy Models

| Model | Isolation | Cost | Use case |
|---|---|---|---|
| **Soft (namespace)** | Logical | Low | Same org, trusted teams |
| **Hard (NS + policy)** | Strong logical | Low-medium | Internal tenants, audit required |
| **vCluster** | Virtual cluster | Medium | API isolation required, cluster-admin per tenant |
| **Cluster-per-tenant** | Physical | High | Per-customer SaaS, full isolation |

---

## 🌱 1️⃣ Soft Multi-Tenancy (Namespace + RBAC)

### Architecture
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
- Fast setup
- Single cluster cost
- Easy inter-namespace networking (filter with NetworkPolicy)

### ❌ Con
- Cluster-level resources (CRD, MutatingWebhook) are shared
- Privileged escape → the whole cluster
- Resource exhaustion (one tenant grabs all CPU)

---

## 🛡️ 2️⃣ Hard Multi-Tenancy (Soft + Policies)

Soft + an extra layer:

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

> Run a **mini K8s control plane** inside a K8s cluster. Each tenant gets its own virtual cluster.

### Setup
```bash
vcluster create team-a --namespace vcluster-team-a
```

### Architecture
```
[Host Cluster: prod]
  └── Namespace: vcluster-team-a
      ├── Virtual control plane (k3s / vcluster api-server)
      ├── etcd (sqlite or separate)
      └── Pods run on the host cluster
          (vcluster syncs the pods)
```

### Tenant access
```bash
vcluster connect team-a
kubectl config use-context vcluster_team-a
kubectl get nodes   # virtual nodes
```

### ✅ Pro
- A tenant can be **cluster-admin** in its own vcluster
- CRDs are isolated to the tenant
- Ideal for multi-tenant SaaS

### ❌ Con
- Operational complexity
- Performance overhead (control plane duplication)
- Network latency (host ↔ vcluster)

> 🔑 **Use case**: When every team needs its own cert-manager, its own CRD.

---

## 🏢 4️⃣ Cluster-per-Tenant (Hard Isolation)

```
[Cluster A] = Tenant 1
[Cluster B] = Tenant 2
[Cluster C] = Tenant 3
...
```

### ✅ Pro
- Absolute isolation
- Compliance (kernel-level)
- Customer-data leakage impossible (cluster-level)

### ❌ Con
- 10x cost (master + worker per cluster)
- Operational burden (managing N clusters)
- ArgoCD ApplicationSet mandatory

### Use case: SaaS premium tier
- A cluster per banking, healthcare customer
- Compliance-driven
- For high-ROI customers

---

## 🌳 Decision Tree

```
START
  │
  ├── Internal teams (same org, trust OK)?
  │     │
  │     └── Soft multi-tenancy (namespace + RBAC)
  │
  ├── Internal teams but compliance + audit?
  │     │
  │     └── Hard (Capsule + Kyverno + ResourceQuota)
  │
  ├── Tenant must be its own cluster-admin (CRD, operator)?
  │     │
  │     └── vCluster
  │
  └── SaaS premium customer + compliance + full isolation?
         │
         └── Cluster-per-tenant
```

---

## 🚧 Common Problems

### Resource starvation
- One tenant ate all the CPU → the others go pending
- **Fix**: ResourceQuota + LimitRange

### Cross-namespace network
- A team-a pod talks to a team-b service
- **Fix**: NetworkPolicy default-deny + explicit allow

### Privileged escape
- The team-a tenant tries `securityContext.privileged: true`
- **Fix**: PSS restricted + Kyverno verify

### Cluster-level resource competition
- Shared Ingress controller, port collision
- **Fix**: Per-tenant Ingress, or a single Ingress + multi-host

### Audit log mixing
- "Who did what?" is hard to answer
- **Fix**: Per-namespace audit policy + structured logs

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Single namespace, "separate by labels" | No logical isolation | Per-tenant namespace |
| No ResourceQuota | Noisy neighbor | Quota + LimitRange |
| No NetworkPolicy | Cross-tenant traffic | Default-deny + allowlist |
| PSS baseline (not restricted) | Privileged escape | restricted enforce |
| Granting a tenant cluster-admin | Compromise = cluster | vCluster or Role-based |
| Shared CRD, tenant needs differ | Conflict | vCluster |
| No audit / shared | Forensics gap | Per-namespace audit policy |
| Shared Ingress controller, port collision | Errors | Multi-host or per-tenant |
| Shared storage class, no per-tenant size limit | Disk full | Per-tenant storage quota |
| No separate K8s SA per tenant | Cross-tenant token use | Per-tenant ServiceAccount |

---

## 📋 Multi-Tenancy Production Checklist

```
[ ] Tenancy model selection (soft / hard / vCluster / cluster-per)
[ ] Per-tenant namespace
[ ] RBAC: Role + RoleBinding per tenant
[ ] ResourceQuota
[ ] LimitRange (default request/limit)
[ ] NetworkPolicy: default-deny + allowlist
[ ] PSS: restricted enforce
[ ] Kyverno policies (disallow-privileged, etc.)
[ ] Audit policy per-namespace
[ ] Storage class quota
[ ] Per-tenant Ingress or multi-host
[ ] Per-tenant cert-manager namespace (if needed)
[ ] Capsule or an equivalent operator (large org)
[ ] Quarterly: tenant audit (cross-tenant violation?)
[ ] DR: per-tenant backup strategy
```

---

## 📚 References

- **K8s Multi-Tenancy WG** — github.com/kubernetes-sigs/multi-tenancy
- **Capsule** — capsule.clastix.io
- **vCluster** — vcluster.com
- **Kiosk** — github.com/loft-sh/kiosk (older vCluster version)
- [`Production-Checklist.md`](Production-Checklist.md)
- [`08-Security/Kubernetes-Hardening.md`](../08-Security/Kubernetes-Hardening.md)
- [`08-Security/Policy-as-Code-OPA-Kyverno.md`](../08-Security/Policy-as-Code-OPA-Kyverno.md)
- [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md)

---

> *"Multi-tenancy isn't 'I opened a few namespaces' — it's **disciplined
> controls**. Without ResourceQuota + NetworkPolicy + PSS + audit, the
> 'multi-tenant' claim is a **facade**."*
