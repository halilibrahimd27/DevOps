---
description: "Pod-level debugging rehberi: kubectl describe/logs, ephemeral container, distroless image debug, CrashLoopBackOff ve OOMKilled gibi yaygin senaryolar."
tags:
  - Kubernetes
  - Incident Response
  - SRE
  - Containers
  - Cheatsheet
---
# Debugging Pods — `kubectl debug`, ephemeral, exec rehberi

> *"`kubectl logs` çıktı vermiyor, pod CrashLoopBackOff. Production'da
> distroless image, shell yok. **Pod debug'ı bilmek**, gece SEV2
> dakikalarını ya 5 dakika ya 60 dakika yapar."*

Bu rehber pod-level debugging için somut komutları, ephemeral
container, distroless image debug ve yaygın senaryoları anlatır.

---

## 🔍 Adım 1: `kubectl describe pod`

```bash
kubectl describe pod <POD> -n <NS>
```

### İncele
- **Status / Reason**: CrashLoopBackOff, OOMKilled, ImagePullBackOff
- **Events**: scheduling, image pull, liveness probe fail
- **Containers / Last State**: exit code, reason

### Yaygın reason'lar
| Reason | Çözüm |
|---|---|
| `ImagePullBackOff` | imagePullSecret? registry credential? |
| `CrashLoopBackOff` | logs incele, exit code |
| `OOMKilled` | Memory limit yetersiz |
| `Pending` | Node yok, taint, resource yetersiz |
| `Init:Error` | Init container hata |
| `CreateContainerConfigError` | ConfigMap / Secret eksik |

---

## 📜 Adım 2: `kubectl logs`

```bash
# Mevcut log
kubectl logs <POD> -n <NS>

# Önceki crash'in log'u (CrashLoopBackOff için kritik)
kubectl logs <POD> -n <NS> --previous

# Multi-container pod
kubectl logs <POD> -n <NS> -c <CONTAINER>

# Tüm container
kubectl logs <POD> -n <NS> --all-containers

# Tail + follow
kubectl logs <POD> -n <NS> -f --tail=100

# Time-based
kubectl logs <POD> -n <NS> --since=1h --since-time="2026-05-04T14:30:00Z"
```

> 🔑 **`--previous`** crash debug'ın altın anahtarı. Crash sırasındaki son log'u verir.

---

## 🐚 Adım 3: `kubectl exec` (Shell varsa)

```bash
# Shell aç
kubectl exec -it <POD> -n <NS> -- sh
# veya
kubectl exec -it <POD> -n <NS> -- bash

# Tek komut
kubectl exec <POD> -n <NS> -- ps aux
kubectl exec <POD> -n <NS> -- env
kubectl exec <POD> -n <NS> -- cat /etc/resolv.conf
```

### Distroless / scratch image (shell yok!)
```bash
kubectl exec -it <POD> -- sh   # FAIL: "no such file"
```

→ **`kubectl debug`** kullan (aşağıda).

---

## 🩺 Adım 4: `kubectl debug` (Ephemeral Container)

> K8s 1.23+ stable. **Distroless / scratch image** debug için altın.

### Mevcut pod'a ephemeral container
```bash
kubectl debug -it <POD> --image=nicolaka/netshoot --target=<CONTAINER> -n <NS>
```

→ **netshoot** image'ı (curl, dig, tcpdump, ss, nc) ile aynı pod'da shell.

### `--target` (process namespace share)
```bash
kubectl debug -it <POD> --image=busybox --target=<MAIN_CONTAINER>
# busybox container, ana container'ın process namespace'ini paylaşır
ps aux   # ana container'ın process'lerini görür
```

### Pod kopyası ile debug
```bash
kubectl debug <POD> --image=nicolaka/netshoot --copy-to=<POD>-debug --share-processes
# Original pod intact, kopyası debug için
```

### Node debug
```bash
kubectl debug node/<NODE> -it --image=ubuntu
# Node'a privileged container açar
chroot /host
# Node'un filesystem'i
```

---

## 🌐 Adım 5: Network Debug

```bash
# DNS test
kubectl exec <POD> -- nslookup kubernetes.default.svc

# Service connectivity
kubectl exec <POD> -- nc -zv <SERVICE>.<NS>.svc.cluster.local 80

# External
kubectl exec <POD> -- curl -v https://api.example.com

# tcpdump (netshoot ephemeral container)
kubectl debug -it <POD> --image=nicolaka/netshoot
tcpdump -i any -n port 80

# NetworkPolicy debug
kubectl describe networkpolicy -n <NS>
cilium policy trace --src-pod <NS>/<POD> --dst-pod <NS>/<DST>
```

> Detay: [`09-Networking/Network-Troubleshooting.md`](../09-Networking/Network-Troubleshooting.md).

---

## 📦 Adım 6: ConfigMap / Secret Debug

```bash
# Pod'a inject edilmiş env vars
kubectl exec <POD> -- env | grep -i app

# ConfigMap içeriği
kubectl get configmap <CM> -n <NS> -o yaml

# Secret (base64)
kubectl get secret <SEC> -n <NS> -o jsonpath='{.data}' | jq

# Secret decode
kubectl get secret <SEC> -n <NS> -o jsonpath='{.data.password}' | base64 -d

# Mounted secret pod içinde
kubectl exec <POD> -- ls /etc/secrets
kubectl exec <POD> -- cat /etc/secrets/api-key
```

---

## 💾 Adım 7: Volume Debug

```bash
# Pod'un volume'leri
kubectl describe pod <POD> | grep -A 10 Volumes

# PV / PVC durumu
kubectl get pvc -n <NS>
kubectl describe pvc <PVC> -n <NS>

# Volume içeriği (pod içinde)
kubectl exec <POD> -- ls /var/data
kubectl exec <POD> -- df -h
```

---

## 🔥 Adım 8: Resource / Performance

```bash
# CPU + Memory
kubectl top pod <POD> -n <NS>
kubectl top node

# Resource limits
kubectl get pod <POD> -n <NS> -o jsonpath='{.spec.containers[*].resources}'

# Heap dump (Java)
kubectl exec <POD> -- jmap -dump:format=b,file=/tmp/heap.hprof <PID>
kubectl cp <NS>/<POD>:/tmp/heap.hprof ./heap.hprof
# MAT veya VisualVM ile aç

# Go pprof
kubectl port-forward <POD> 6060:6060
go tool pprof http://localhost:6060/debug/pprof/heap
```

---

## 🚨 Senaryo: CrashLoopBackOff

```bash
# 1. Status
kubectl get pod <POD> -n <NS>
# CrashLoopBackOff (5)

# 2. Events
kubectl describe pod <POD> -n <NS>
# Last State: Terminated, Reason: Error, Exit Code: 1

# 3. Crash log (önemli!)
kubectl logs <POD> -n <NS> --previous
# Output: "Failed to connect to database: ..."

# 4. ConfigMap / Secret check
kubectl exec <POD> -- env | grep DATABASE
# DATABASE_URL belki yanlış

# 5. Network test
kubectl debug -it <POD> --image=nicolaka/netshoot
nc -zv <DB>.<NS>.svc.cluster.local 5432
# Connection refused → service yok veya NetPol blocking
```

---

## 🚨 Senaryo: ImagePullBackOff

```bash
kubectl describe pod <POD> -n <NS>
# Failed to pull image "<REGISTRY>/<APP>:<TAG>": ...
# unauthorized: authentication required

# imagePullSecret check
kubectl get pod <POD> -o yaml | grep imagePullSecrets

# Secret içeriği
kubectl get secret <PULL_SECRET> -o yaml

# Manuel test
docker pull <REGISTRY>/<APP>:<TAG>
# Çalışıyor mu?
```

---

## 🚨 Senaryo: Pending (Schedule Failed)

```bash
kubectl describe pod <POD> -n <NS>
# Events:
# Warning  FailedScheduling  ...  0/3 nodes are available:
#   3 Insufficient cpu, 3 Insufficient memory.

# Nedenler
# - Resource yetersiz → Cluster Autoscaler / Karpenter
# - Taint mismatch → tolerations ekle
# - PV yok → StorageClass + PV provision
# - NodeAffinity match yok → labels kontrol
```

---

## 🚨 Senaryo: Liveness Probe Fail (Crash Loop)

```bash
kubectl describe pod <POD>
# Liveness probe failed: HTTP probe failed with statuscode: 503

# Probe config
kubectl get pod <POD> -o yaml | grep -A 10 livenessProbe

# Probe çok agresif mi?
# initialDelaySeconds çok az
# timeoutSeconds çok az
# failureThreshold çok düşük
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| `kubectl logs` `--previous` ihmal | Crash sebebi kayıp | Her crash'te `--previous` |
| Distroless'a SSH dene | Shell yok | `kubectl debug --image=netshoot` |
| Production pod'a debug image build | Image rebuild + deploy | Ephemeral container |
| Liveness initialDelay 0 | Crash loop | App startup time'a göre |
| Resource limit profile yapmadan tahmin | OOM / throttle | Profile + buffer |
| Tek pod inceleyip "service down" | Replica seti unutulur | Tüm replica'ları kontrol |
| Network sorunu → "kubectl restart" | Sebep bilinmez | tcpdump + dig |
| Heap dump alıp pod restart | Dump dosyası kayıp | `kubectl cp` ile çek |
| Pod debug için cluster-admin | Yetki abused | RBAC ile sınırlı debug role |

---

## 📋 Pod Debug Toolkit Checklist

```
[ ] netshoot image cluster'da hazır (imagePullPolicy: Always)
[ ] kubectl debug command runbook'ta
[ ] Liveness/readiness probe config dokümante
[ ] Heap dump prosedürü (Java/Go)
[ ] Log aggregation (Loki) + structured logging
[ ] ConfigMap / Secret yönetim disipline (ESO)
[ ] Resource profile baseline (her servis)
[ ] Pod debug RBAC (sadece SRE / on-call)
[ ] PodDisruptionBudget tanımlı
[ ] On-call: pod debug runbook (her tier alarm için)
```

---

## 📚 Referanslar

- **kubectl debug** — kubernetes.io/docs/tasks/debug/debug-application/
- **Ephemeral Containers** — kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/
- **netshoot** — github.com/nicolaka/netshoot
- **Troubleshooting Pods** — kubernetes.io/docs/tasks/debug/debug-application/debug-pods/
- [`Production-Checklist.md`](Production-Checklist.md)
- [`HPA-VPA-KEDA.md`](HPA-VPA-KEDA.md)
- [`Resource-Limits-Guide.md`](Resource-Limits-Guide.md)
- [`09-Networking/Network-Troubleshooting.md`](../09-Networking/Network-Troubleshooting.md)
- [`11-SRE/Runbook-Template.md`](../11-SRE/Runbook-Template.md)

---

> *"Pod debug 'tool seçmek' değil — **systemic flow**. describe →
> logs --previous → exec/debug → network test. **5 dakikada
> root cause** ya da **60 dakika tahminle** geçen vardiya."*

---

> 🎓 **Öğrenme Patikası:** Bu doküman [`D1`](../22-Learning-Path/block-d-orchestration/D1-k8s-temel.md) modülünde "Önce oku" kaynağı olarak kullanılıyor.
