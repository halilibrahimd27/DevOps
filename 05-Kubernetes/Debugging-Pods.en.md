---
description: "Pod-level debugging guide: kubectl describe/logs, ephemeral containers, distroless image debugging, and common scenarios like CrashLoopBackOff and OOMKilled."
tags:
  - Kubernetes
  - Incident Response
  - SRE
  - Containers
  - Cheatsheet
---
# Debugging Pods — `kubectl debug`, ephemeral, exec Guide

> *"`kubectl logs` gives no output, the pod is CrashLoopBackOff. It's a
> distroless image in production, no shell. **Knowing how to debug a
> pod** turns your midnight SEV2 into either a 5-minute fix or a
> 60-minute guessing game."*

This guide covers concrete commands for pod-level debugging, ephemeral
containers, distroless image debugging, and common scenarios.

---

## 🔍 Step 1: `kubectl describe pod`

```bash
kubectl describe pod <POD> -n <NS>
```

### Inspect
- **Status / Reason**: CrashLoopBackOff, OOMKilled, ImagePullBackOff
- **Events**: scheduling, image pull, liveness probe failures
- **Containers / Last State**: exit code, reason

### Common reasons
| Reason | Fix |
|---|---|
| `ImagePullBackOff` | imagePullSecret? registry credential? |
| `CrashLoopBackOff` | Check logs, exit code |
| `OOMKilled` | Memory limit too low |
| `Pending` | No node, taint, insufficient resources |
| `Init:Error` | Init container error |
| `CreateContainerConfigError` | Missing ConfigMap / Secret |

---

## 📜 Step 2: `kubectl logs`

```bash
# Current log
kubectl logs <POD> -n <NS>

# Log from the previous crash (critical for CrashLoopBackOff)
kubectl logs <POD> -n <NS> --previous

# Multi-container pod
kubectl logs <POD> -n <NS> -c <CONTAINER>

# All containers
kubectl logs <POD> -n <NS> --all-containers

# Tail + follow
kubectl logs <POD> -n <NS> -f --tail=100

# Time-based
kubectl logs <POD> -n <NS> --since=1h --since-time="2026-05-04T14:30:00Z"
```

> 🔑 **`--previous`** is the golden key of crash debugging. It gives you the last log before the crash.

---

## 🐚 Step 3: `kubectl exec` (if a shell exists)

```bash
# Open a shell
kubectl exec -it <POD> -n <NS> -- sh
# or
kubectl exec -it <POD> -n <NS> -- bash

# Single command
kubectl exec <POD> -n <NS> -- ps aux
kubectl exec <POD> -n <NS> -- env
kubectl exec <POD> -n <NS> -- cat /etc/resolv.conf
```

### Distroless / scratch image (no shell!)
```bash
kubectl exec -it <POD> -- sh   # FAIL: "no such file"
```

→ Use **`kubectl debug`** (below).

---

## 🩺 Step 4: `kubectl debug` (Ephemeral Container)

> K8s 1.23+ stable. Golden for debugging **distroless / scratch images**.

### Ephemeral container on an existing pod
```bash
kubectl debug -it <POD> --image=nicolaka/netshoot --target=<CONTAINER> -n <NS>
```

→ Shell in the same pod using the **netshoot** image (curl, dig, tcpdump, ss, nc).

### `--target` (process namespace share)
```bash
kubectl debug -it <POD> --image=busybox --target=<MAIN_CONTAINER>
# the busybox container shares the main container's process namespace
ps aux   # shows the main container's processes
```

### Debugging with a pod copy
```bash
kubectl debug <POD> --image=nicolaka/netshoot --copy-to=<POD>-debug --share-processes
# Original pod stays intact, the copy is for debugging
```

### Node debug
```bash
kubectl debug node/<NODE> -it --image=ubuntu
# Opens a privileged container on the node
chroot /host
# The node's filesystem
```

---

## 🌐 Step 5: Network Debug

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

> Details: [`09-Networking/Network-Troubleshooting.md`](../09-Networking/Network-Troubleshooting.md).

---

## 📦 Step 6: ConfigMap / Secret Debug

```bash
# Env vars injected into the pod
kubectl exec <POD> -- env | grep -i app

# ConfigMap contents
kubectl get configmap <CM> -n <NS> -o yaml

# Secret (base64)
kubectl get secret <SEC> -n <NS> -o jsonpath='{.data}' | jq

# Secret decode
kubectl get secret <SEC> -n <NS> -o jsonpath='{.data.password}' | base64 -d

# Mounted secret inside the pod
kubectl exec <POD> -- ls /etc/secrets
kubectl exec <POD> -- cat /etc/secrets/api-key
```

---

## 💾 Step 7: Volume Debug

```bash
# The pod's volumes
kubectl describe pod <POD> | grep -A 10 Volumes

# PV / PVC status
kubectl get pvc -n <NS>
kubectl describe pvc <PVC> -n <NS>

# Volume contents (inside the pod)
kubectl exec <POD> -- ls /var/data
kubectl exec <POD> -- df -h
```

---

## 🔥 Step 8: Resource / Performance

```bash
# CPU + Memory
kubectl top pod <POD> -n <NS>
kubectl top node

# Resource limits
kubectl get pod <POD> -n <NS> -o jsonpath='{.spec.containers[*].resources}'

# Heap dump (Java)
kubectl exec <POD> -- jmap -dump:format=b,file=/tmp/heap.hprof <PID>
kubectl cp <NS>/<POD>:/tmp/heap.hprof ./heap.hprof
# Open with MAT or VisualVM

# Go pprof
kubectl port-forward <POD> 6060:6060
go tool pprof http://localhost:6060/debug/pprof/heap
```

---

## 🚨 Scenario: CrashLoopBackOff

```bash
# 1. Status
kubectl get pod <POD> -n <NS>
# CrashLoopBackOff (5)

# 2. Events
kubectl describe pod <POD> -n <NS>
# Last State: Terminated, Reason: Error, Exit Code: 1

# 3. Crash log (important!)
kubectl logs <POD> -n <NS> --previous
# Output: "Failed to connect to database: ..."

# 4. ConfigMap / Secret check
kubectl exec <POD> -- env | grep DATABASE
# DATABASE_URL might be wrong

# 5. Network test
kubectl debug -it <POD> --image=nicolaka/netshoot
nc -zv <DB>.<NS>.svc.cluster.local 5432
# Connection refused → the service doesn't exist, or NetPol is blocking
```

---

## 🚨 Scenario: ImagePullBackOff

```bash
kubectl describe pod <POD> -n <NS>
# Failed to pull image "<REGISTRY>/<APP>:<TAG>": ...
# unauthorized: authentication required

# imagePullSecret check
kubectl get pod <POD> -o yaml | grep imagePullSecrets

# Secret contents
kubectl get secret <PULL_SECRET> -o yaml

# Manual test
docker pull <REGISTRY>/<APP>:<TAG>
# Does it work?
```

---

## 🚨 Scenario: Pending (Schedule Failed)

```bash
kubectl describe pod <POD> -n <NS>
# Events:
# Warning  FailedScheduling  ...  0/3 nodes are available:
#   3 Insufficient cpu, 3 Insufficient memory.

# Causes
# - Insufficient resources → Cluster Autoscaler / Karpenter
# - Taint mismatch → add tolerations
# - No PV → StorageClass + PV provision
# - No NodeAffinity match → check labels
```

---

## 🚨 Scenario: Liveness Probe Fail (Crash Loop)

```bash
kubectl describe pod <POD>
# Liveness probe failed: HTTP probe failed with statuscode: 503

# Probe config
kubectl get pod <POD> -o yaml | grep -A 10 livenessProbe

# Is the probe too aggressive?
# initialDelaySeconds too low
# timeoutSeconds too low
# failureThreshold too low
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Skipping `--previous` on `kubectl logs` | Crash reason is lost | `--previous` on every crash |
| Trying to SSH into distroless | No shell | `kubectl debug --image=netshoot` |
| Building a debug image for a production pod | Image rebuild + deploy | Ephemeral container |
| Liveness initialDelay 0 | Crash loop | Set based on app startup time |
| Guessing resource limits without profiling | OOM / throttle | Profile + buffer |
| Checking one pod and calling it "service down" | The replica set is forgotten | Check all replicas |
| Network issue → "kubectl restart" | Root cause stays unknown | tcpdump + dig |
| Taking a heap dump and restarting the pod | The dump file is lost | Pull it out with `kubectl cp` |
| cluster-admin for pod debugging | Privilege abused | RBAC-scoped debug role |

---

## 📋 Pod Debug Toolkit Checklist

```
[ ] netshoot image ready in the cluster (imagePullPolicy: Always)
[ ] kubectl debug command in the runbook
[ ] Liveness/readiness probe config documented
[ ] Heap dump procedure (Java/Go)
[ ] Log aggregation (Loki) + structured logging
[ ] ConfigMap / Secret management disciplined (ESO)
[ ] Resource profile baseline (per service)
[ ] Pod debug RBAC (SRE / on-call only)
[ ] PodDisruptionBudget defined
[ ] On-call: pod debug runbook (for every tier alarm)
```

---

## 📚 References

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

> *"Pod debugging isn't 'picking a tool' — it's a **systemic flow**.
> describe → logs --previous → exec/debug → network test. **Root
> cause in 5 minutes**, or a shift spent **guessing for 60**."*

---

> 🎓 **Learning Path:** This document is used as a "Read first" resource in the [`D1`](../22-Learning-Path/block-d-orchestration/D1-k8s-temel.md) module.
