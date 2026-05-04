# Cilium & eBPF — 30 Dakikada Modern Network Stack

> *"kube-proxy, iptables, sidecar — 2014'ün K8s networking
> mimarisidir. 2026'da **Cilium + eBPF** o stack'i **kernel'e
> taşır**, sidecar'ı yok eder, performansı 10x'ler."*

Bu rehber Cilium ve altındaki eBPF teknolojisini DevOps mühendisi için
**pratik** açıklar: ne, niye, nasıl kurulur, hangi feature'ı niye seçersin.

---

## 🎯 eBPF Nedir?

> **eBPF**: Linux kernel içinde **sandbox'lı program** çalıştırma
> framework'ü. Userspace'e veri kopyalamadan, kernel'in içinden
> ağ paketi, syscall, dosya sistemi etkinliklerine müdahale eder.

```
[Userspace tool]                    [Kernel]
   │                                   │
   │ Eski yöntem:                      │
   │   1. Paket geldi → kernel         │
   │   2. Userspace'e kopyala          │
   │   3. iptables kuralı uygula       │
   │   4. Geri kernel'e dön            │
   │   5. Paket gönder                 │
   │                                   │
   │ eBPF yöntem:                      │
   │   1. Paket geldi → eBPF program   │
   │   2. Kernel içinde karar          │
   │   3. Paket gönder                 │
   │     (userspace yok!)              │
```

**Sonuç**: 10x daha az CPU, 10x daha düşük latency, observability bedava.

---

## 🔑 Cilium = K8s için eBPF Networking

| Geleneksel K8s | Cilium |
|---|---|
| kube-proxy (iptables) | eBPF (kernel-level) |
| CNI: Flannel/Calico (manuel L3) | Cilium CNI (otomatik) |
| NetworkPolicy: L4 (port) | L3/L4/L7 (HTTP method, path) |
| Service mesh: sidecar | Sidecarless (ya da Envoy on-demand) |
| Observability: tcpdump | Hubble (kernel-level visibility) |

> 🔑 **Cilium = CNI + NetworkPolicy + Service Mesh + Observability** — 4 tool'u 1 araçta birleştirir.

---

## 🪄 Niye eBPF/Cilium 2026'da Standart?

### 1. Performans
| Test | iptables | eBPF (Cilium) |
|---|---|---|
| Service forwarding latency | 0.5 ms | 0.05 ms |
| 100K services scaling | Yavaş (chain'ler) | Hızlı (hash table) |
| Pod-to-pod throughput | 8 Gbps | 30+ Gbps (XDP) |

### 2. Observability
- **Hubble** → her paketi kernel-level izle
- Service-to-service flow graph
- L7 protocol parsing (HTTP, gRPC, Kafka)

### 3. Güvenlik
- **L7 NetworkPolicy** (geleneksel L4'ün ötesi)
- **Tetragon** runtime security
- **mTLS** (Cilium Service Mesh)

### 4. kube-proxy replacement
- iptables yerine eBPF
- Service routing 100K+ scale'de hızlı
- ClusterIP, NodePort, LoadBalancer hepsi eBPF

---

## 🚀 30 Dakikada Cilium Kurulumu

### Pre-requisite
- Linux kernel ≥ 5.10 (önerilir ≥ 5.15)
- K8s 1.27+
- Mevcut CNI yok (yeni cluster ya da migration)

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

# Hello world: 2 pod connectivity test
cilium connectivity test
```

### 4️⃣ Hubble UI (network observability)
```bash
cilium hubble ui
# localhost'ta UI açar — service map, flow log canlı
```

---

## 🛡️ NetworkPolicy — L7 Power

### Geleneksel K8s NetworkPolicy (L4)
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

→ "Frontend → API port 8080 izinli." Ama hangi HTTP method? Hangi path? Bilemez.

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

→ "Frontend sadece bu spesifik path'lere bu method'larla erişebilir." Compromised frontend pod, **/admin** endpoint'ine ulaşamaz.

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
# 2 cluster'ı bağla
cilium clustermesh enable --context cluster-1
cilium clustermesh enable --context cluster-2

cilium clustermesh connect \
  --context cluster-1 \
  --destination-context cluster-2
```

→ Pod'lar cluster'lar arası **direkt** konuşur (VPN/proxy yok). Service discovery cross-cluster.

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

## 🎯 Tipik Use Case'ler

### 1. kube-proxy Kaldır
Eski iptables'lı kube-proxy yorgun: 1000+ servis cluster'da iptables chain spaghetti. Cilium eBPF replace eder, K8s 100K scale'a kadar hızlı.

### 2. Service Mesh (Sidecar'sız)
Geleneksel Istio/Linkerd: her pod'a sidecar (50 MB/pod). Cilium Service Mesh: kernel'de, **0 overhead**. mTLS + traffic management + L7 routing.

### 3. eBPF-based Runtime Security (Tetragon)
Falco rule'ların eBPF versiyonu. Daha düşük overhead, **kill** yapabilir (Falco sadece detect).

### 4. Egress Gateway
Cilium egress gateway → cluster'dan çıkan trafiği specific IP'den çıkar (3rd party'nin allow-list'i için).

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
    egressIP: 203.0.113.10   # static IP, Stripe whitelist'te
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

> ⚠️ **CNI değişimi büyük operasyon.** Yeni cluster'da başla, eskisini drain et.

### Adımlar
1. Yeni cluster Cilium ile (kubeadm + helm install)
2. App'leri yeni cluster'a aşamalı taşı (multi-cluster Service via mesh)
3. Eski cluster drain
4. DNS / LB switch

### Migration testleri
```bash
# Connectivity test
cilium connectivity test

# Performance benchmark
ipref3, netperf — eski vs yeni cluster

# Observability
Hubble UI canlı flow → eski tcpdump'tan farkı
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Eski Linux kernel (5.4) | eBPF feature'lar eksik | Kernel ≥ 5.15 |
| kube-proxy + Cilium ikisi birden | Çakışma | `kubeProxyReplacement=true` |
| L4 NetworkPolicy yeterli sanmak | Compromised pod, allow port'ta her path'e | L7 policy |
| Hubble UI public expose | Network secret expose | Internal-only ingress |
| Encryption disabled | Pod-pod traffic plaintext | WireGuard veya IPsec |
| ClusterMesh tasarımsız | Latency surprise (cross-region 100ms) | Federation kararı net |
| FQDN egress allowlist yok | Compromise → C2 callback | DNS-based egress |
| Cilium upgrade test yok | Production'da network down | Lab cluster + canary |
| eBPF program crash → cluster'a etki | Hata mode | Cilium safe mode + rollback |
| Hubble retention 1 saat | Forensic eksik | Loki / Elastic'e ship |

---

## 📋 Cilium Adoption Checklist

```
[ ] Linux kernel ≥ 5.15 (cluster node'larında)
[ ] K8s ≥ 1.27
[ ] kubeProxyReplacement = true
[ ] Cilium 1.16+ (LTS branch)
[ ] Hubble enabled (relay + ui)
[ ] Encryption: WireGuard veya IPsec
[ ] L7 NetworkPolicy critical service'lerde
[ ] FQDN egress allowlist (3rd party)
[ ] kube-proxy uninstall (eski cluster ise)
[ ] Hubble metrics → Prometheus + Grafana
[ ] Hubble flow log → Loki / Elastic
[ ] Connectivity test CI'da (`cilium connectivity test`)
[ ] Cilium upgrade prosedürü dokümante (canary)
[ ] ClusterMesh (multi-cluster ise) çalışıyor
[ ] Tetragon (runtime security) — opsiyonel ama önerilen
[ ] Service mesh (eğer mesh ihtiyacı var ise)
```

---

## 📚 Referanslar

- **Cilium Docs** — docs.cilium.io
- **eBPF.io** — ebpf.io
- **Hubble** — github.com/cilium/hubble
- **Tetragon** — tetragon.io
- **Liz Rice — Learning eBPF** (kitap)
- **Isovalent Labs** — isovalent.com/labs (interactive lab'lar)
- [`Service-Mesh-Comparison.md`](Service-Mesh-Comparison.md)
- [`Gateway-API-Migration.md`](Gateway-API-Migration.md)
- [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md)
- [`08-Security/Runtime-Security.md`](../08-Security/Runtime-Security.md)
- [`05-Kubernetes/Production-Checklist.md`](../05-Kubernetes/Production-Checklist.md)

---

> *"eBPF 'yeni hot teknoloji' değil — Linux kernel'in **sessiz devrimi**.
> 2026'da hâlâ iptables ile uğraşan ekip, 2010'un mimarisini 2026'da
> yaşatıyor demektir."*
