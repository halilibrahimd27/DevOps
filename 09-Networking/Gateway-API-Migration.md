---
description: "Ingress'ten Gateway API'ye geçiş rehberi: niye gerekli, persona-bazlı CRD modeli, adım adım migration planı ve geçiş sırasında beklenen tuzaklar."
tags:
  - Networking
  - Kubernetes
  - Platform Engineering
  - Roadmap
---
# Gateway API — Ingress'in Halefi, 2026'da Standart

> *"Ingress 2015'te tasarlandı: tek CRD, tek tip ekibe (cluster-ops),
> sadece HTTP. 2026'da **5 farklı persona** Kubernetes ağında çalışıyor;
> Gateway API onlara farklı CRD'ler verir. Ingress'in halefi resmidir."*

Bu rehber Ingress'ten Gateway API'ye geçişi: niye, nasıl, hangi adımlarla
ve hangi tuzakları beklediğini somut örneklerle anlatır.

---

## 🎯 Niye Gateway API?

### Ingress'in problemleri

| Sorun | Açıklama |
|---|---|
| **Tek CRD** | `Ingress` → her şey burada (TLS, route, traffic split, header...) |
| **Annotation cehennem** | Vendor-spesifik annotation: `nginx.ingress.kubernetes.io/...`, `traefik.ingress.kubernetes.io/...` |
| **HTTP odaklı** | TCP/UDP/TLS native değil |
| **Mesh entegrasyonu kötü** | Ingress'i mesh'le birleştirmek hack |
| **Persona ayrımı yok** | Cluster-ops + dev aynı resource'ta |
| **Conformance test yok** | Her vendor farklı yorumluyor |

### Gateway API çözümü

| Bileşen | Persona | Sorumluluk |
|---|---|---|
| **GatewayClass** | Infrastructure provider | "Bu cluster'da bu controller var" |
| **Gateway** | Cluster-ops | LoadBalancer + listener config |
| **HTTPRoute** | App developer | Bu app'in route + traffic split |
| **TCPRoute / UDPRoute / TLSRoute** | App developer | Non-HTTP protocol |
| **GRPCRoute** | App developer | gRPC routing |
| **ReferenceGrant** | App developer | Cross-namespace TLS cert paylaş |

```
[GatewayClass]              ← Provider (örn: cilium-class)
       ↓
[Gateway]                   ← Cluster ops kurar (LB, port, TLS)
       ↓
[HTTPRoute / TCPRoute / ...]  ← App dev yazar (path, backend, weights)
       ↓
[Service / Backend]
```

---

## 🆚 Ingress vs Gateway API

| Özellik | Ingress | Gateway API |
|---|---|---|
| HTTP routing | ✅ | ✅ |
| TCP/UDP/TLS | ❌ (annotation hack) | ✅ Native |
| gRPC | ❌ | ✅ |
| Traffic split (canary) | Annotation | ✅ Native (weight) |
| Header manipulation | Annotation | ✅ Filter |
| Authentication | Annotation | ✅ AuthFilter (extension) |
| Cross-namespace | ❌ | ✅ ReferenceGrant |
| Multi-cluster | ❌ | ✅ (Gateway-controller'a bağlı) |
| Conformance test | ❌ | ✅ |
| Vendor-neutral | ⚠️ (annotation farklı) | ✅ |
| Persona ayrımı | ❌ | ✅ |

---

## 🚀 Quick Start

### 1️⃣ CRD'leri install et
```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/<VERSION>/standard-install.yaml
```

### 2️⃣ Controller seç
2026'da Gateway API destekleyen controller'lar:

| Controller | Notlar |
|---|---|
| **Cilium** | eBPF-tabanlı, native destek (önerilen) |
| **Istio** | Service mesh ile birleşik |
| **NGINX Gateway Fabric** | NGINX yeni nesil |
| **Envoy Gateway** | Pure Envoy, vendor-neutral |
| **Contour** | Project Contour |
| **Traefik** | Traefik 3+ |
| **HAProxy** | Kurumsal |

### 3️⃣ GatewayClass + Gateway
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: cilium
spec:
  controllerName: io.cilium/gateway-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: prod-gateway
  namespace: gateway-system
spec:
  gatewayClassName: cilium
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      tls:
        mode: Terminate
        certificateRefs:
          - name: prod-tls
            kind: Secret
      allowedRoutes:
        namespaces:
          from: All
    - name: http-redirect
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
```

### 4️⃣ HTTPRoute (app dev tarafı)
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: payments
  namespace: payments
spec:
  parentRefs:
    - name: prod-gateway
      namespace: gateway-system
  hostnames:
    - "payments.<DOMAIN>"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api/v1
      backendRefs:
        - name: payments-svc
          port: 8080
```

---

## 🔀 Canary Deployment — Native Traffic Split

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: payments-canary
spec:
  parentRefs: [{name: prod-gateway, namespace: gateway-system}]
  hostnames: ["payments.<DOMAIN>"]
  rules:
    - matches: [{path: {type: PathPrefix, value: /}}]
      backendRefs:
        - name: payments-stable
          port: 8080
          weight: 90
        - name: payments-canary
          port: 8080
          weight: 10
```

> 🔑 Argo Rollouts, Flagger Gateway API'ye native destek veriyor.
> Otomatik aşamalı (10% → 50% → 100%) canary.

---

## 🏷️ Header-Based Routing

```yaml
rules:
  - matches:
      - headers:
          - name: X-Beta-User
            value: "true"
    backendRefs:
      - name: payments-beta
        port: 8080
  - matches:
      - path: {type: PathPrefix, value: /}
    backendRefs:
      - name: payments-stable
        port: 8080
```

→ "Beta header'ı olan kullanıcılar yeni versiyonu gör; herkes stable."

---

## 🔧 Filter'lar — Header Manipülasyonu

```yaml
rules:
  - matches: [{path: {type: PathPrefix, value: /api}}]
    filters:
      - type: RequestHeaderModifier
        requestHeaderModifier:
          add:
            - name: X-Forwarded-By
              value: gateway-api
          remove:
            - X-Internal-Token
      - type: ResponseHeaderModifier
        responseHeaderModifier:
          add:
            - name: Strict-Transport-Security
              value: "max-age=31536000; includeSubDomains"
    backendRefs:
      - {name: api-svc, port: 8080}
```

---

## 🌍 Cross-Namespace — ReferenceGrant

App dev kendi namespace'inde HTTPRoute yazar ama **gateway başka namespace'te** (cluster-ops yönettiği için). ReferenceGrant izin verir:

```yaml
# gateway-system/grant.yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: payments-can-attach
  namespace: gateway-system
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      namespace: payments
  to:
    - group: ""
      kind: Service
```

---

## 🔄 Migration: Ingress → Gateway API

> ⚠️ **Aşamalı yap.** Yeni route'lar Gateway API'de, eski Ingress'ler gradual migrate.

### 1. Hafta: Hazırlık
- Gateway API CRD install
- Controller seç + paralel kur (Ingress controller ile beraber)
- GatewayClass + Gateway tanımla (sadece TLS, listener)

### 2-3. Hafta: Yeni servisler
- Yeni servis launch'unda HTTPRoute kullan
- Mevcut Ingress'ler dokunma

### 4-12. Hafta: Mevcut göç
- Servis başına PR: Ingress → HTTPRoute
- DNS/LB değişmez (aynı Gateway IP)
- Gözlem: Hubble / access log

### 12-16. Hafta: Eski Ingress controller kaldır
- Ingress kullanımı sıfır → controller uninstall
- LB'ler tek Gateway controller'a

### Migration tool: `ingress2gateway`
```bash
# Mevcut Ingress'i HTTPRoute'a çevirme tool
go install sigs.k8s.io/ingress2gateway@latest

ingress2gateway print --providers ingress-nginx \
  --namespaces payments \
  > payments-httproutes.yaml
```

---

## 🛡️ Security Considerations

### TLS termination
```yaml
listeners:
  - name: https
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate    # GW termine eder, backend HTTP
      certificateRefs:
        - name: <CERT_SECRET>
```

> Backend mTLS gerekiyorsa Gateway → backend arası `BackendTLSPolicy` kullan
> (extension API).

### TLSRoute (passthrough)
```yaml
listeners:
  - name: tls-passthrough
    port: 443
    protocol: TLS
    tls:
      mode: Passthrough  # backend kendi TLS'i yapar
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
spec:
  hostnames: ["api.<DOMAIN>"]
  rules:
    - backendRefs: [{name: api-svc, port: 443}]
```

### Authentication (extension)
Gateway API native auth yok ama vendor extension:
- **Cilium**: AuthFilter (OIDC, mTLS)
- **Istio**: AuthorizationPolicy (CRD ayrı)
- **Envoy Gateway**: SecurityPolicy

---

## 📊 Observability

```yaml
# Cilium Hubble Gateway metrics
gateway_http_requests_total{gateway="prod-gateway", route="payments"}
gateway_http_request_duration_seconds_bucket{...}
```

```promql
# 5xx error rate
sum(rate(gateway_http_requests_total{status=~"5.."}[5m])) by (route)
/
sum(rate(gateway_http_requests_total[5m])) by (route)
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Ingress + Gateway API ikisini eşit kullan | Karmaşa, drift | Migration plan + sunset Ingress |
| Tek namespace'te Gateway + 100 HTTPRoute | YAML chaos | Gateway team-namespace'de, route app-namespace'te |
| Cross-namespace izin yoksa | TLS cert paylaşılmaz | ReferenceGrant |
| Annotation kullanımı (eski alışkanlık) | Gateway API native özellik var | Filter / Policy CRD |
| TLS Terminate + backend HTTP plain | Pod-pod plaintext | mTLS service-to-service |
| Persona ayrımı yapılmamış | Her dev Gateway'i değiştirir → kaos | Gateway = cluster-ops, Route = dev |
| Migration big-bang | Production'da kırılma | Aşamalı, 12 hafta |
| Conformance kontrol yok | Vendor-spesifik bağ | Conformance test suite çalıştır |
| Eski Ingress controller hâlâ kurulu | LB resource israfı | Sunset planı |

---

## 📋 Gateway API Adoption Checklist

```
[ ] CRD install (Standard veya Experimental channel)
[ ] Controller seçimi yapıldı (Cilium / Istio / Envoy / NGINX)
[ ] GatewayClass tanımlı
[ ] Gateway (TLS + listener) ayağa kalktı
[ ] HTTPRoute ile en az 1 servis prod'da
[ ] Cross-namespace için ReferenceGrant
[ ] Migration plan (ingress2gateway ile dönüşüm)
[ ] Observability (Hubble / Prometheus)
[ ] Cert-manager ile TLS otomasyonu
[ ] Argo Rollouts / Flagger ile canary
[ ] Persona ayrımı: cluster-ops vs app-dev
[ ] Eski Ingress controller sunset tarihi
[ ] Conformance test ile vendor compliance
[ ] DR: Gateway down → backup controller
[ ] Quarterly: spec güncellemesi (Gateway API rapidly evolving)
```

---

## 📚 Referanslar

- **Gateway API Docs** — gateway-api.sigs.k8s.io
- **Gateway API Conformance** — github.com/kubernetes-sigs/gateway-api
- **ingress2gateway** — github.com/kubernetes-sigs/ingress2gateway
- **Cilium Gateway API** — docs.cilium.io
- **Istio Gateway API** — istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/
- [`Cilium-eBPF-Intro.md`](Cilium-eBPF-Intro.md)
- [`Service-Mesh-Comparison.md`](Service-Mesh-Comparison.md)
- [`Ingress-NGINX-Patterns.md`](Ingress-NGINX-Patterns.md)
- [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md)

---

> *"Ingress'i 2026'da kullanmak hâlâ çalışır — ama **eskiyen** bir
> mimaridir. Yeni servisler Gateway API'de doğsun, eskiler kademeli
> taşınsın. 2027'de Ingress 'legacy mode' olacak."*
