---
description: "Zero-downtime upgrade guide for a Kubernetes cluster: release cycle, upgrade discipline, rollback, deprecated API migration, and managed vs self-managed differences."
tags:
  - Kubernetes
  - SRE
  - Platform Engineering
  - Incident Response
---
# Kubernetes Upgrade Strategy — Zero-Downtime Version Migration

> *"K8s ships a minor version every 4 months. A team that skips falls
> 3 versions behind in a year → no security patches, running deprecated
> APIs. **Disciplined upgrade** = quarterly cycle."*

This guide covers planning, testing, rollback strategy, and
managed/self-managed differences for upgrading a K8s cluster with zero
downtime.

---

## 📅 K8s Release Cycle

```
v1.30 — April 2024
v1.31 — August 2024
v1.32 — December 2024
v1.33 — April 2025
v1.34 — August 2025
...

Support: 14 months (3 minor versions active)
EOL: no CVE patches once support ends
```

> 🔑 **2026 target**: Cluster on N-1 version. (Currently N-2 → warning, N-3 → critical.)

---

## 🪜 Upgrade Discipline

### Quarterly cycle (recommended)
```
Q1: minor +1 (e.g. 1.30 → 1.31)
Q2: minor +1 (1.31 → 1.32)
Q3: minor +1
Q4: minor +1
```

### "Major skip" forbidden
```
1.28 → 1.31  ❌ (skip 2 versions)
1.28 → 1.29 → 1.30 → 1.31  ✅
```

→ K8s does not support skipping versions (some API incompatibility).

---

## 🚀 Upgrade Flow (Detailed)

### Week 1: Preparation
- Read release notes (deprecated APIs)
- Scan for deprecated APIs with `kubectl convert` or `pluto detect`
- Try the upgrade on a test cluster

### Week 2: Test on a lab cluster
```bash
# Lab cluster
eksctl upgrade cluster --name=<LAB> --version=1.31

# Smoke test
kubectl get nodes   # are they ready
kubectl get pods -A | grep -v Running  # any crashes

# Workload health
helm test <RELEASE>
```

### Week 3: Staging cluster
- Lab succeeded → apply to staging
- Soak test with production-like load (1 week of observation)
- Smoke test + canary

### Week 4: Production
- Maintenance window (low-traffic hour)
- Staged: control plane → worker nodes
- Health check at every stage
- Rollback ready

---

## 🛡️ Stages (Self-Managed kubeadm)

### 1. Control Plane upgrade
```bash
# First control plane node
sudo apt-get update
sudo apt-get install -y kubeadm=1.31.0-1.1
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.31.0

# kubelet + kubectl
sudo apt-get install -y kubelet=1.31.0-1.1 kubectl=1.31.0-1.1
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Other control plane nodes
sudo kubeadm upgrade node
```

### 2. Worker node upgrade
```bash
# Drain
kubectl drain <NODE> --ignore-daemonsets --delete-emptydir-data

# Upgrade
sudo apt-get install -y kubeadm=1.31.0-1.1
sudo kubeadm upgrade node
sudo apt-get install -y kubelet=1.31.0-1.1 kubectl=1.31.0-1.1
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Uncordon
kubectl uncordon <NODE>
```

> 🔑 **Staged**: one node at a time. NEVER upgrade the whole cluster at once.

---

## ☁️ Managed K8s Upgrade

### EKS
```bash
# Control plane
aws eks update-cluster-version --name=<CLUSTER> --kubernetes-version=1.31

# Wait
aws eks wait cluster-active --name=<CLUSTER>

# Node group (managed)
aws eks update-nodegroup-version --cluster-name=<CLUSTER> --nodegroup-name=<NG>

# Or rolling AMI rotation
```

### GKE
```bash
# Control plane (automatic or manual)
gcloud container clusters upgrade <CLUSTER> --master --cluster-version=1.31.0

# Node pool
gcloud container clusters upgrade <CLUSTER> --node-pool=<NP>
```

### AKS
```bash
az aks upgrade --resource-group=<RG> --name=<CLUSTER> --kubernetes-version=1.31.0
```

> 🔑 **Managed**: the control plane SLA is the cloud provider's. Worker upgrade is under your control.

---

## 🔍 Deprecated API Detection

### `pluto`
```bash
brew install fairwindsops/tap/pluto

# Cluster scan
pluto detect-helm
pluto detect-files /path/to/manifests

# Output:
# autoscaling/v2beta2 → autoscaling/v2 (1.26+)
# extensions/v1beta1 → networking.k8s.io/v1
```

### `kube-no-trouble` (kubent)
```bash
kubent --target-version 1.31

# Output: which resource uses a deprecated API
```

### `kubectl convert`
```bash
kubectl convert -f deployment.yaml --output-version=apps/v1
```

---

## 📊 Pre-Upgrade Checklist

```
[ ] Release notes read (deprecated, removed APIs)
[ ] Deprecated API scan with pluto / kubent
[ ] Helm chart compatibility check (does the chart version support the new K8s)
[ ] Operator compatibility (cert-manager, ingress-nginx, etc.)
[ ] PodDisruptionBudget defined (for drain)
[ ] etcd backup taken
[ ] Upgrade tested on a lab cluster
[ ] Soak test on a staging cluster
[ ] Rollback plan written
[ ] Maintenance window announcement (status page)
[ ] On-call ready
```

---

## 🔄 Rollback Strategy

### Self-managed
```bash
# Control plane downgrade NOT SUPPORTED
# Solution: new cluster + workload migration

# Worker node downgrade
sudo apt-get install -y kubelet=1.30.0-1.1 kubectl=1.30.0-1.1
sudo systemctl restart kubelet
```

### Managed
- EKS: Cluster downgrade is not supported
- Solution: Backup cluster
- ⚠️ **Always back up before upgrading**

> 🔑 **Practical**: Do the production upgrade with a **blue/green** cluster (fresh cluster + workload migration). The old cluster is the backup.

---

## 🟦🟩 Blue/Green Cluster Upgrade

```
[Blue cluster: v1.30 (current prod)]
         │
         ▼
[New Green cluster: v1.31 (fresh)]
   │
   │ ArgoCD sync (workload deploy)
   │
   ▼
[Green cluster: smoke test, soak]
   │
   │ Traffic gradually shift (DNS / LB weight)
   │
   ▼
[Green: 100% traffic]
   │
   │ 2 weeks of observation
   │
   ▼
[Blue cluster decom]
```

> 🔑 The safest. **Cost**: 2x cluster for 2-4 weeks. **Risk minimized**.

---

## 🧪 Smoke Test (Post-Upgrade)

```bash
# Node ready
kubectl get nodes
# All Ready, correct version

# Pod healthy
kubectl get pods -A --field-selector=status.phase!=Running
# Should be empty (no CrashLoop)

# Critical workload
kubectl rollout status deploy/payments -n payments
helm test ingress-nginx
helm test cert-manager

# DNS
kubectl run -it dns-test --image=busybox --rm -- nslookup kubernetes

# Network
kubectl run -it net-test --image=nicolaka/netshoot --rm -- curl -k https://kubernetes
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Skip 2+ minor | API incompatibility | Sequential upgrade |
| Lab + staging skipped | You learn in production | Staged dev → staging → prod |
| Upgrading all nodes at once | Whole cluster down | Staged, one node at a time |
| No etcd backup | Recovery impossible | Mandatory |
| No PDB | Drain fails | Min available 1+ |
| No deprecated API scan | Surprise failure | pluto / kubent |
| No operator compatibility check | Operator broken | Helm chart version |
| No rollback plan | Disaster | Blue/green or a backup |
| No status page announcement | Customer panic | Maintenance window |
| 1 upgrade per year | 4 versions behind | Quarterly |
| Self-managed + manual intervention | Error rate | Automation (Ansible / scripts) |

---

## 📋 K8s Upgrade Production Checklist

```
[ ] Quarterly upgrade cadence written
[ ] N-1 version target (current: the stable N+1)
[ ] Lab → staging → prod staged
[ ] Pluto / kubent deprecated API check
[ ] etcd backup pre-upgrade
[ ] PDB defined (min available 1+)
[ ] Helm chart + operator compatibility verified
[ ] Smoke test script ready
[ ] Rollback plan (blue/green preferred)
[ ] On-call rotation upgrade window
[ ] Status page announcement
[ ] Post-upgrade soak test (1 week)
[ ] Postmortem (gaps feed back into the next upgrade)
[ ] Annual: upgrade strategy review
```

---

## 📚 References

- **K8s Release Notes** — kubernetes.io/releases/
- **Deprecated API Migration Guide** — kubernetes.io/docs/reference/using-api/deprecation-guide/
- **kubeadm Upgrade** — kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
- **pluto** — github.com/FairwindsOps/pluto
- **kubent** — github.com/doitintl/kube-no-trouble
- [`Production-Checklist.md`](Production-Checklist.md)
- [`Multi-Tenancy-Patterns.md`](Multi-Tenancy-Patterns.md)
- [`HPA-VPA-KEDA.md`](HPA-VPA-KEDA.md)
- [`Resource-Limits-Guide.md`](Resource-Limits-Guide.md)

---

> *"A K8s upgrade isn't 'we'll do it someday' — it's **quarterly
> discipline**. A team that skips is **3 versions behind** 6 months
> later, unable to get security patches, piled up with deprecated
> APIs; a **disciplined** team moves 1 version forward each quarter."*
