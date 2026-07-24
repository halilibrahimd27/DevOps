---
description: "A practical intro to Cilium and eBPF: kube-proxy replacement, a sidecar-less architecture, and how the modern kernel-based network stack is built."
tags:
  - Networking
  - Cilium
  - Kubernetes
  - Performance
  - Service Mesh
---
# Cilium & eBPF — A Modern Network Stack in 30 Minutes

> *"kube-proxy, iptables, sidecar — that's the 2014 K8s networking
> architecture. In 2026, **Cilium + eBPF** moves that stack **into the
> kernel**, kills the sidecar, and 10x's performance."*

This guide explains Cilium and the eBPF technology beneath it for the DevOps
engineer in **practical** terms: what, why, how to install, and which feature to pick and why.

---

## 🎯 What Is eBPF?

> **eBPF**: a framework for running **sandboxed programs** inside the Linux
> kernel. Without copying data to userspace, it hooks into network packets,
> syscalls, and filesystem activity from within the kernel.

```
[Userspace tool]                    [Kernel]
   │                                   │
   │ Old approach:                     │
   │   1. Packet arrives → kernel      │
   │   2. Copy to userspace            │
   │   3. Apply iptables rule          │
   │   4. Return to kernel             │
   │   5. Send packet                  │
   │                                   │
   │ eBPF approach:                    │
   │   1. Packet arrives → eBPF program│
   │   2. Decide inside the kernel     │
   │   3. Send packet                  │
   │     (no userspace!)               │
```

**Result**: 10x less CPU, 10x lower latency, observability for free.

---

## 🔑 Cilium = eBPF Networking for K8s

| Traditional K8s | Cilium |
|---|---|
| kube-proxy (iptables) | eBPF (kernel-level) |
| CNI: Flannel/Calico (manual L3) | Cilium CNI (automatic) |
| NetworkPolicy: L4 (port) | L3/L4/L7 (HTTP method, path) |
| Service mesh: sidecar | Sidecarless (or Envoy on-demand) |
| Observability: tcpdump | Hubble (kernel-level visibility) |

> 🔑 **Cilium = CNI + NetworkPolicy + Service Mesh + Observability** — it merges 4 tools into 1.

---

## 🪄 Why Is eBPF/Cilium the Standard in 2026?

### 1. Performance
| Test | iptables | eBPF (Cilium) |
|---|---|---|
| Service forwarding latency | 0.5 ms | 0.05 ms |
| 100K services scaling | Slow (chains) | Fast (hash table) |
| Pod-to-pod throughput | 8 Gbps | 30+ Gbps (XDP) |

### 2. Observability
- **Hubble** → watch every packet at kernel level
- Service-to-service flow graph
- L7 protocol parsing (HTTP, gRPC, Kafka)

### 3. Security
- **L7 NetworkPolicy** (beyond traditional L4)
- **Tetragon** runtime security
- **mTLS** (Cilium Service Mesh)

### 4. kube-proxy replacement
- eBPF instead of iptables
- Fast service routing at 100K+ scale
- ClusterIP, NodePort, LoadBalancer all eBPF

---

## 🚀 Installing Cilium in 30 Minutes

### Pre-requisite
- Linux kernel ≥ 5.10 (≥ 5.15 recommended)
- K8s 1.27+
- No existing CNI (new cluster or migration)

### 1️⃣ kubeadm cluster (no kube-proxy)
```bash
kubeadm init \
  --skip-phases=addon/kube-proxy \
  --pod-network-cidr=10.244.0.0/16
```

### 2️⃣ Cilium install (Helm)
```bash
helm repo add cilium https://helm.cilium.io/

helm install cilium cilium/cilium \
  --namespace kube-system \
  --version <VERSION> \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=<API_HOST> \
  --set k8sServicePort=6443 \
  --set ingressController.enabled=true \
  --set gatewayAPI.enabled=true \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set encryption.enabled=true \
  --set encryption.type=wireguard
```

### 3️⃣ Verify
```bash
cilium status

# Hello world: 2-pod connectivity test
cilium connectivity test
```

### 4️⃣ Hubble UI (network observability)
```bash
cilium hubble ui
# Opens the UI on localhost — service map, live flow logs
```

---

## 🛡️ NetworkPolicy — L7 Power

### Traditional K8s NetworkPolicy (L4)
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow-frontend
spec:
  podSelector: {matchLabels: {app: api}}
  ingress:
    - from:
        - podSelector: {matchLabels: {app: frontend}}
      ports:
        - port: 8080
```

→ "Frontend → API port 8080 allowed." But which HTTP method? Which path? It can't tell.

### Cilium L7 NetworkPolicy
```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: api-l7
spec:
  endpointSelector: {matchLabels: {app: api}}
  ingress:
    - fromEndpoints:
        - matchLabels: {app: frontend}
      toPorts:
        - ports: [{port: "8080", protocol: TCP}]
          rules:
            http:
              - method: GET
                path: "/api/v1/users(/[0-9]+)?"
              - method: POST
                path: "/api/v1/orders"
                headers:
                  - 'Content-Type: application/json'
```

→ "Frontend can only reach these specific paths with these methods." A compromised frontend pod **cannot** reach the **/admin** endpoint.

### kafka, gRPC, DNS L7
```yaml
# Kafka topic-level filter
ingress:
  - toPorts:
      - ports: [{port: "9092"}]
        rules:
          kafka:
            - role: produce
              topic: orders
            - role: consume
              topic: payments
```

```yaml
# DNS allowlist (egress)
egress:
  - toFQDNs:
      - matchName: "api.stripe.com"
      - matchPattern: "*.amazonaws.com"
    toPorts: [{port: "443", protocol: TCP}]
```

---

## 🌐 Cilium Cluster Mesh (Multi-Cluster)

```bash
# Connect 2 clusters
cilium clustermesh enable --context cluster-1
cilium clustermesh enable --context cluster-2

cilium clustermesh connect \
  --context cluster-1 \
  --destination-context cluster-2
```

→ Pods talk **directly** across clusters (no VPN/proxy). Cross-cluster service discovery.

---

## 👁️ Hubble — Network Observability

```bash
# Real-time flow log
hubble observe --follow

# Top talkers
hubble observe --output json | jq -s 'group_by(.flow.source.namespace) | sort_by(length) | reverse | .[0:5]'

# HTTP request rate per service
hubble observe --type l7 --protocol http --output table
```

### Metrics (Prometheus)
```promql
# DNS error rate
hubble_dns_responses_total{rcode!="No Error"}

# HTTP 5xx rate
hubble_http_responses_total{status=~"5.."}

# Network policy denied
hubble_drop_total{reason="Policy denied"}
```

---

## 🎯 Typical Use Cases

### 1. Drop kube-proxy
The old iptables-based kube-proxy is worn out: in a 1000+ service cluster it's iptables chain spaghetti. Cilium eBPF replaces it, fast up to K8s 100K scale.

### 2. Service Mesh (Sidecar-less)
Traditional Istio/Linkerd: a sidecar per pod (50 MB/pod). Cilium Service Mesh: in the kernel, **0 overhead**. mTLS + traffic management + L7 routing.

### 3. eBPF-based Runtime Security (Tetragon)
The eBPF version of Falco rules. Lower overhead, and it can **kill** (Falco only detects).

### 4. Egress Gateway
Cilium egress gateway → send cluster-exiting traffic out from a specific IP (for a 3rd party's allow-list).

```yaml
apiVersion: cilium.io/v2
kind: CiliumEgressGatewayPolicy
metadata:
  name: stripe-egress
spec:
  selectors:
    - podSelector: {matchLabels: {app: payments}}
  destinationCIDRs:
    - "0.0.0.0/0"
  egressGateway:
    nodeSelector:
      matchLabels: {node-role: egress-gw}
    egressIP: 203.0.113.10   # static IP, on Stripe's whitelist
```

### 5. Bandwidth Manager
Pod-level bandwidth limit (priority class):
```yaml
metadata:
  annotations:
    kubernetes.io/egress-bandwidth: "10M"
    kubernetes.io/ingress-bandwidth: "100M"
```

---

## 🔄 Migration: Calico/Flannel → Cilium

> ⚠️ **A CNI switch is a big operation.** Start on a new cluster and drain the old one.

### Steps
1. New cluster with Cilium (kubeadm + helm install)
2. Move apps to the new cluster in stages (multi-cluster Service via mesh)
3. Drain the old cluster
4. DNS / LB switch

### Migration tests
```bash
# Connectivity test
cilium connectivity test

# Performance benchmark
ipref3, netperf — old vs new cluster

# Observability
Hubble UI live flow → how it differs from old tcpdump
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Old Linux kernel (5.4) | eBPF features are missing | Kernel ≥ 5.15 |
| kube-proxy + Cilium both at once | Conflict | `kubeProxyReplacement=true` |
| Assuming L4 NetworkPolicy is enough | Compromised pod hits every path on the allowed port | L7 policy |
| Hubble UI exposed publicly | Network secrets exposed | Internal-only ingress |
| Encryption disabled | Pod-to-pod traffic in plaintext | WireGuard or IPsec |
| ClusterMesh without a design | Latency surprise (cross-region 100ms) | A clear federation decision |
| No FQDN egress allowlist | Compromise → C2 callback | DNS-based egress |
| No Cilium upgrade test | Network down in production | Lab cluster + canary |
| eBPF program crash → cluster impact | Failure mode | Cilium safe mode + rollback |
| Hubble retention 1 hour | Forensics gap | Ship to Loki / Elastic |

---

## 📋 Cilium Adoption Checklist

```
[ ] Linux kernel ≥ 5.15 (on cluster nodes)
[ ] K8s ≥ 1.27
[ ] kubeProxyReplacement = true
[ ] Cilium 1.16+ (LTS branch)
[ ] Hubble enabled (relay + ui)
[ ] Encryption: WireGuard or IPsec
[ ] L7 NetworkPolicy on critical services
[ ] FQDN egress allowlist (3rd party)
[ ] kube-proxy uninstalled (if an old cluster)
[ ] Hubble metrics → Prometheus + Grafana
[ ] Hubble flow log → Loki / Elastic
[ ] Connectivity test in CI (`cilium connectivity test`)
[ ] Cilium upgrade procedure documented (canary)
[ ] ClusterMesh (if multi-cluster) working
[ ] Tetragon (runtime security) — optional but recommended
[ ] Service mesh (if you need a mesh)
```

---

## 📚 References

- **Cilium Docs** — docs.cilium.io
- **eBPF.io** — ebpf.io
- **Hubble** — github.com/cilium/hubble
- **Tetragon** — tetragon.io
- **Liz Rice — Learning eBPF** (book)
- **Isovalent Labs** — isovalent.com/labs (interactive labs)
- [`Service-Mesh-Comparison.md`](Service-Mesh-Comparison.md)
- [`Gateway-API-Migration.md`](Gateway-API-Migration.md)
- [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md)
- [`08-Security/Runtime-Security.md`](../08-Security/Runtime-Security.md)
- [`05-Kubernetes/Production-Checklist.md`](../05-Kubernetes/Production-Checklist.md)

---

> *"eBPF isn't 'the new hot technology' — it's the Linux kernel's **quiet
> revolution**. A team still wrestling with iptables in 2026 is keeping
> 2010's architecture alive in 2026."*
