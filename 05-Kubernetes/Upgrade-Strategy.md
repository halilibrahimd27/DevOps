---
description: "Kubernetes cluster'i zero-downtime upgrade rehberi: release cycle, upgrade disiplini, rollback, deprecated API gecisi, managed vs self-managed farklari."
tags:
  - Kubernetes
  - SRE
  - Platform Engineering
  - Incident Response
---
# Kubernetes Upgrade Strategy — Zero-Downtime Versiyon Migration

> *"K8s 4 ayda bir minor versiyon yayınlar. Skip eden ekip 1 yılda
> 3 versiyon geride kalır → security patch alamaz, deprecated API
> kullanır. **Disiplinli upgrade** = quarterly cycle."*

Bu rehber K8s cluster'ı zero-downtime upgrade etmek için planlama,
test, rollback strateji ve managed/self-managed farklarını anlatır.

---

## 📅 K8s Release Cycle

```
v1.30 — Nisan 2024
v1.31 — Ağustos 2024
v1.32 — Aralık 2024
v1.33 — Nisan 2025
v1.34 — Ağustos 2025
...

Support: 14 ay (3 minor version active)
EOL: support sona erdiğinde CVE patch yok
```

> 🔑 **2026 hedefi**: Cluster N-1 versiyonda. (Mevcut N-2 → uyarı, N-3 → kritik.)

---

## 🪜 Upgrade Disiplini

### Quarterly cycle (önerilen)
```
Q1: minor +1 (örn: 1.30 → 1.31)
Q2: minor +1 (1.31 → 1.32)
Q3: minor +1
Q4: minor +1
```

### "Major skip" yasak
```
1.28 → 1.31  ❌ (skip 2 versiyon)
1.28 → 1.29 → 1.30 → 1.31  ✅
```

→ K8s skip versiyon supported değil (bazı API incompatibility).

---

## 🚀 Upgrade Akışı (Detaylı)

### Hafta 1: Hazırlık
- Release notes oku (deprecated API'ler)
- `kubectl convert` veya `pluto detect` ile deprecated API tara
- Test cluster'da upgrade dene

### Hafta 2: Lab cluster'da test
```bash
# Lab cluster
eksctl upgrade cluster --name=<LAB> --version=1.31

# Smoke test
kubectl get nodes   # ready mi
kubectl get pods -A | grep -v Running  # crash var mı

# Workload health
helm test <RELEASE>
```

### Hafta 3: Staging cluster
- Lab başarılı → staging'e uygula
- Production-like load ile soak test (1 hafta gözlem)
- Smoke test + canary

### Hafta 4: Production
- Bakım penceresi (low-traffic saat)
- Aşamalı: control plane → worker node'lar
- Health check her aşama
- Rollback hazır

---

## 🛡️ Aşamalar (Self-Managed kubeadm)

### 1. Control Plane upgrade
```bash
# İlk control plane node
sudo apt-get update
sudo apt-get install -y kubeadm=1.31.0-1.1
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.31.0

# kubelet + kubectl
sudo apt-get install -y kubelet=1.31.0-1.1 kubectl=1.31.0-1.1
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Diğer control plane node'lar
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

> 🔑 **Aşamalı**: 1 node bir kerede. Tüm cluster aynı anda upgrade'e ASLA.

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

# Veya rolling AMI rotation
```

### GKE
```bash
# Control plane (otomatik veya manuel)
gcloud container clusters upgrade <CLUSTER> --master --cluster-version=1.31.0

# Node pool
gcloud container clusters upgrade <CLUSTER> --node-pool=<NP>
```

### AKS
```bash
az aks upgrade --resource-group=<RG> --name=<CLUSTER> --kubernetes-version=1.31.0
```

> 🔑 **Managed**: control plane SLA cloud sağlayıcının. Worker upgrade kontrolün altında.

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

# Output: hangi resource deprecated API kullanıyor
```

### `kubectl convert`
```bash
kubectl convert -f deployment.yaml --output-version=apps/v1
```

---

## 📊 Pre-Upgrade Checklist

```
[ ] Release notes okundu (deprecated, removed API'ler)
[ ] pluto / kubent ile deprecated API tarama
[ ] Helm chart compatibility check (chart version yeni K8s'i destekliyor mu)
[ ] Operator compatibility (cert-manager, ingress-nginx, vb.)
[ ] PodDisruptionBudget tanımlı (drain için)
[ ] etcd backup alındı
[ ] Lab cluster'da upgrade tested
[ ] Staging cluster'da soak test
[ ] Rollback planı yazılı
[ ] Bakım penceresi duyurusu (status page)
[ ] On-call hazır
```

---

## 🔄 Rollback Stratejisi

### Self-managed
```bash
# Control plane downgrade SUPPORTED DEĞİL
# Çözüm: yeni cluster + workload migration

# Worker node downgrade
sudo apt-get install -y kubelet=1.30.0-1.1 kubectl=1.30.0-1.1
sudo systemctl restart kubelet
```

### Managed
- EKS: Cluster downgrade desteklenmez
- Çözüm: Yedek cluster
- ⚠️ **Upgrade öncesi mutlaka backup**

> 🔑 **Pratik**: Production upgrade'i **mavi/yeşil** cluster ile yap (fresh cluster + workload migration). Eski cluster yedek.

---

## 🟦🟩 Blue/Green Cluster Upgrade

```
[Blue cluster: v1.30 (current prod)]
         │
         ▼
[Yeni Green cluster: v1.31 (fresh)]
   │
   │ ArgoCD sync (workload deploy)
   │
   ▼
[Green cluster: smoke test, soak]
   │
   │ Traffic gradually shift (DNS / LB weight)
   │
   ▼
[Green: %100 traffic]
   │
   │ 2 hafta gözlem
   │
   ▼
[Blue cluster decom]
```

> 🔑 En güvenli. **Maliyet**: 2x cluster 2-4 hafta. **Risk minimize**.

---

## 🧪 Smoke Test (Post-Upgrade)

```bash
# Node ready
kubectl get nodes
# Tüm Ready, doğru version

# Pod healthy
kubectl get pods -A --field-selector=status.phase!=Running
# Boş olmalı (CrashLoop yok)

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

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Skip 2+ minor | API incompatibility | Sıralı upgrade |
| Lab + staging atlanır | Production'da öğrenilir | Aşamalı dev → staging → prod |
| Tüm node aynı anda upgrade | Tüm cluster down | Aşamalı, 1 node bir kerede |
| etcd backup yok | Recovery imkansız | Mandatory |
| PDB yok | Drain başarısız | Min available 1+ |
| Deprecated API tarama yok | Sürpriz hata | pluto / kubent |
| Operator compatibility check yok | Operator broken | Helm chart version |
| Rollback plan yok | Felaket | Blue/green ya da yedek |
| Status page'e duyuru yok | Müşteri panic | Maintenance window |
| Yıllık 1 upgrade | 4 versiyon geride | Quarterly |
| Self-managed + insan müdahalesi | Hata oranı | Automation (Ansible / scripts) |

---

## 📋 K8s Upgrade Production Checklist

```
[ ] Quarterly upgrade cadence yazılı
[ ] N-1 versiyon hedef (current: N+1 olan stable)
[ ] Lab → staging → prod aşamalı
[ ] Pluto / kubent deprecated API check
[ ] etcd backup pre-upgrade
[ ] PDB tanımlı (min available 1+)
[ ] Helm chart + operator compatibility verified
[ ] Smoke test script hazır
[ ] Rollback plan (blue/green tercih)
[ ] On-call rotation upgrade window
[ ] Status page duyurusu
[ ] Post-upgrade soak test (1 hafta)
[ ] Postmortem (gap'ler bir sonraki upgrade'e feedback)
[ ] Annual: upgrade strategy review
```

---

## 📚 Referanslar

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

> *"K8s upgrade 'bir gün yaparız' değil — **quarterly disiplin**.
> Skip yapan ekip 6 ay sonra **3 versiyon geride** + security
> patch alamayan + deprecated API ile yığılı; **disciplined**
> ekip her çeyrek 1 versiyon ileri."*
