---
description: "Kubernetes networking guide index: in-cluster/out-of-cluster network concepts, the eBPF world, service mesh, and the shift from Ingress to Gateway API."
tags:
  - Networking
  - Kubernetes
  - Service Mesh
  - Roadmap
---
# 09 · Networking

> *"`curl` works but `dig` returns the wrong IP, NetworkPolicy is choking
> traffic, the service mesh sidecar is returning 503s — 30% of production
> incidents are network-related."*

In-cluster and out-of-cluster network concepts, the modern eBPF world,
and the shift from Ingress to Gateway API.

## Contents

| File | Topic |
|---|---|
| [`Service-Mesh-Comparison.md`](Service-Mesh-Comparison.md) | Istio vs Linkerd vs Cilium Service Mesh — why sidecar-less is on the rise |
| [`Cilium-eBPF-Intro.md`](Cilium-eBPF-Intro.md) | A 30-minute intro to the eBPF world, kube-proxy replacement |
| [`Ingress-NGINX-Patterns.md`](Ingress-NGINX-Patterns.md) | TLS termination, rate limiting, canary, external-world integrations |
| [`Gateway-API-Migration.md`](Gateway-API-Migration.md) | Ingress → Gateway API: route splitting, TCP/UDP, HTTPRoute, mesh integration |
| [`DNS-Strategies.md`](DNS-Strategies.md) | external-dns, split-horizon, NodeLocal DNSCache, CoreDNS tuning |
| [`Network-Troubleshooting.md`](Network-Troubleshooting.md) | tcpdump, ss, dig, conntrack: a flowchart for connection issues |

## Service mesh comparison (summary)

| Feature | Istio | Linkerd | Cilium SM |
|---|---|---|---|
| Data plane | Envoy sidecar | linkerd2-proxy (Rust) | eBPF (sidecar-less) |
| Resource overhead | High (~50MB/pod) | Low (~10MB/pod) | Very low (kernel-level) |
| Feature surface | Very broad | Minimalist | Broad, network-first |
| Multi-cluster | Yes (complex) | Yes | Yes (Cluster Mesh) |
| L7 mTLS | Yes | Yes | Yes |
| Learning curve | Steep | Gentle | Moderate |
| 2026 trend | Stable, Ambient mode | Niche, well-loved | On the rise |

## "Why Gateway API?"

| Ingress (legacy) | Gateway API |
|---|---|
| Single CRD (Ingress) | Multiple role-based CRDs (GatewayClass, Gateway, HTTPRoute, ...) |
| Vendor-specific via annotations | Standardized spec |
| Weak team isolation | Cluster ops + app dev roles split across separate CRDs |
| HTTP-focused | HTTP/TCP/UDP/TLS support |
| Poor mesh-Ingress integration | Native integration with service mesh |
| Every vendor interprets it differently | Has a conformance test suite |

## Anti-patterns

- ❌ NodePort instead of ClusterIP in production (port management hell)
- ❌ Service mesh added without thinking through the "why" (no real need for it)
- ❌ No NetworkPolicy (default permissive — everyone talks to everyone)
- ❌ DNS round-robin instead of a client-side load balancer
- ❌ Ingress controller exposed to an unauthorized party
