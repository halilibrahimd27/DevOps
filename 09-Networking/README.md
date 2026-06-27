---
description: "Kubernetes networking rehber dizini: cluster ici/disi network kavramlari, eBPF dunyasi, service mesh ve Ingress'ten Gateway API'ye gecis konulari."
---
# 09 · Networking

> *"`curl` çalışıyor ama `dig` yanlış IP veriyor, NetworkPolicy boğuyor,
> service mesh sidecar'ı 503 dönüyor — production'da %30 incident
> network'tedir."*

Cluster içi ve cluster dışı network kavramları, modern eBPF dünyası,
Ingress'ten Gateway API'ye geçiş.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`Service-Mesh-Comparison.md`](Service-Mesh-Comparison.md) | Istio vs Linkerd vs Cilium Service Mesh — niye sidecar-less yükselişte |
| [`Cilium-eBPF-Intro.md`](Cilium-eBPF-Intro.md) | eBPF dünyasına 30 dk'da giriş, kube-proxy replacement |
| [`Ingress-NGINX-Patterns.md`](Ingress-NGINX-Patterns.md) | TLS termination, rate-limit, canary, dış-dünya integrations |
| [`Gateway-API-Migration.md`](Gateway-API-Migration.md) | Ingress → Gateway API: route splitting, TCP/UDP, HTTPRoute, mesh integration |
| [`DNS-Strategies.md`](DNS-Strategies.md) | external-dns, split-horizon, NodeLocal DNSCache, CoreDNS tuning |
| [`Network-Troubleshooting.md`](Network-Troubleshooting.md) | tcpdump, ss, dig, conntrack: connection sorunları flowchart'ı |

## Service mesh karşılaştırma (özet)

| Özellik | Istio | Linkerd | Cilium SM |
|---|---|---|---|
| Data plane | Envoy sidecar | linkerd2-proxy (Rust) | eBPF (sidecar-less) |
| Resource overhead | Yüksek (~50MB/pod) | Düşük (~10MB/pod) | Çok düşük (kernel-level) |
| Feature surface | Çok geniş | Minimalist | Geniş, network-first |
| Multi-cluster | Var (karmaşık) | Var | Var (Cluster Mesh) |
| L7 mTLS | Var | Var | Var |
| Öğrenme eğrisi | Dik | Yumuşak | Orta |
| 2026 trendi | Stable, Ambient mode | Niche, sevgi dolu | Yükselişte |

## "Niye Gateway API?"

| Ingress (legacy) | Gateway API |
|---|---|
| Tek CRD (Ingress) | Çoklu rol-based CRD (GatewayClass, Gateway, HTTPRoute, ...) |
| Annotation üzerinden vendor-spesifik | Standardize edilmiş spec |
| Ekip izolasyonu zayıf | Cluster ops + app dev rolleri ayrı CRD'lerde |
| HTTP odaklı | HTTP/TCP/UDP/TLS desteği |
| Mesh-Ingress entegrasyonu kötü | Service mesh ile native entegrasyon |
| Tüm vendor'lar farklı yorumluyor | Conformance test suite var |

## Anti-pattern'ler

- ❌ ClusterIP yerine NodePort prod'da (port management cehennemi)
- ❌ Service mesh "neden" düşünülmeden eklenir (gerçek gerek yok)
- ❌ NetworkPolicy yok (default permissive — herkes herkesle konuşur)
- ❌ DNS round-robin client-side load balancer yerine
- ❌ Ingress controller yetkisiz tarafa expose edilmiş
