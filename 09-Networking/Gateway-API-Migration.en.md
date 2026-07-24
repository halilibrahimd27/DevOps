---
description: "Guide to migrating from Ingress to Gateway API: why it's needed, the persona-based CRD model, a step-by-step migration plan, and the pitfalls to expect during the transition."
tags:
  - Networking
  - Kubernetes
  - Platform Engineering
  - Roadmap
---
# Gateway API — Ingress's Successor, the Standard in 2026

> *"Ingress was designed in 2015: one CRD, one team type (cluster-ops),
> HTTP only. In 2026 **5 different personas** work on Kubernetes networking;
> Gateway API gives each of them their own CRDs. It is the official successor to Ingress."*

This guide walks through the move from Ingress to Gateway API: why, how, with
which steps, and which pitfalls to expect — with concrete examples.

---

## 🎯 Why Gateway API?

### Ingress's problems

| Problem | Description |
|---|---|
| **Single CRD** | `Ingress` → everything lives here (TLS, route, traffic split, header...) |
| **Annotation hell** | Vendor-specific annotations: `nginx.ingress.kubernetes.io/...`, `traefik.ingress.kubernetes.io/...` |
| **HTTP-focused** | TCP/UDP/TLS are not native |
| **Poor mesh integration** | Combining Ingress with a mesh is a hack |
| **No persona split** | Cluster-ops + dev on the same resource |
| **No conformance test** | Every vendor interprets it differently |

### The Gateway API solution

| Component | Persona | Responsibility |
|---|---|---|
| **GatewayClass** | Infrastructure provider | "This cluster has this controller" |
| **Gateway** | Cluster-ops | LoadBalancer + listener config |
| **HTTPRoute** | App developer | This app's route + traffic split |
| **TCPRoute / UDPRoute / TLSRoute** | App developer | Non-HTTP protocol |
| **GRPCRoute** | App developer | gRPC routing |
| **ReferenceGrant** | App developer | Share a cross-namespace TLS cert |

```
[GatewayClass]              ← Provider (e.g. cilium-class)
       ↓
[Gateway]                   ← Cluster ops sets it up (LB, port, TLS)
       ↓
[HTTPRoute / TCPRoute / ...]  ← App dev writes it (path, backend, weights)
       ↓
[Service / Backend]
```

---

## 🆚 Ingress vs Gateway API

| Feature | Ingress | Gateway API |
|---|---|---|
| HTTP routing | ✅ | ✅ |
| TCP/UDP/TLS | ❌ (annotation hack) | ✅ Native |
| gRPC | ❌ | ✅ |
| Traffic split (canary) | Annotation | ✅ Native (weight) |
| Header manipulation | Annotation | ✅ Filter |
| Authentication | Annotation | ✅ AuthFilter (extension) |
| Cross-namespace | ❌ | ✅ ReferenceGrant |
| Multi-cluster | ❌ | ✅ (depends on the Gateway controller) |
| Conformance test | ❌ | ✅ |
| Vendor-neutral | ⚠️ (annotations differ) | ✅ |
| Persona split | ❌ | ✅ |

---

## 🚀 Quick Start

### 1️⃣ Install the CRDs
```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/<VERSION>/standard-install.yaml
```

### 2️⃣ Pick a controller
Controllers that support Gateway API in 2026:

| Controller | Notes |
|---|---|
| **Cilium** | eBPF-based, native support (recommended) |
| **Istio** | Unified with the service mesh |
| **NGINX Gateway Fabric** | The next-gen NGINX |
| **Envoy Gateway** | Pure Envoy, vendor-neutral |
| **Contour** | Project Contour |
| **Traefik** | Traefik 3+ |
| **HAProxy** | Enterprise |

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

### 4️⃣ HTTPRoute (app dev side)
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

> 🔑 Argo Rollouts and Flagger have native Gateway API support.
> Automatic staged (10% → 50% → 100%) canary.

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

→ "Users with the beta header see the new version; everyone else gets stable."

---

## 🔧 Filters — Header Manipulation

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

The app dev writes the HTTPRoute in their own namespace, but **the gateway lives in another namespace** (because cluster-ops manages it). ReferenceGrant grants permission:

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

> ⚠️ **Do it in stages.** New routes on Gateway API, old Ingresses migrated gradually.

### Week 1: Preparation
- Install the Gateway API CRDs
- Pick a controller + run it in parallel (alongside the Ingress controller)
- Define GatewayClass + Gateway (TLS and listeners only)

### Weeks 2-3: New services
- Use HTTPRoute for new service launches
- Don't touch existing Ingresses

### Weeks 4-12: Migrate what exists
- One PR per service: Ingress → HTTPRoute
- DNS/LB don't change (same Gateway IP)
- Observe: Hubble / access log

### Weeks 12-16: Remove the old Ingress controller
- Ingress usage hits zero → uninstall the controller
- LBs onto a single Gateway controller

### Migration tool: `ingress2gateway`
```bash
# Tool that converts an existing Ingress to an HTTPRoute
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
      mode: Terminate    # GW terminates, backend is HTTP
      certificateRefs:
        - name: <CERT_SECRET>
```

> If you need backend mTLS, use `BackendTLSPolicy` for the Gateway → backend hop
> (extension API).

### TLSRoute (passthrough)
```yaml
listeners:
  - name: tls-passthrough
    port: 443
    protocol: TLS
    tls:
      mode: Passthrough  # backend does its own TLS
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
spec:
  hostnames: ["api.<DOMAIN>"]
  rules:
    - backendRefs: [{name: api-svc, port: 443}]
```

### Authentication (extension)
Gateway API has no native auth, but there are vendor extensions:
- **Cilium**: AuthFilter (OIDC, mTLS)
- **Istio**: AuthorizationPolicy (separate CRD)
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

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Using Ingress + Gateway API equally | Confusion, drift | Migration plan + sunset Ingress |
| Gateway + 100 HTTPRoutes in one namespace | YAML chaos | Gateway in the team namespace, routes in app namespaces |
| No cross-namespace permission | TLS cert can't be shared | ReferenceGrant |
| Using annotations (old habit) | Gateway API has native features | Filter / Policy CRD |
| TLS Terminate + plain HTTP backend | Pod-to-pod plaintext | mTLS service-to-service |
| No persona split done | Every dev changes the Gateway → chaos | Gateway = cluster-ops, Route = dev |
| Big-bang migration | Breakage in production | Staged, 12 weeks |
| No conformance check | Vendor-specific lock-in | Run the conformance test suite |
| Old Ingress controller still installed | Wasted LB resources | Sunset plan |

---

## 📋 Gateway API Adoption Checklist

```
[ ] CRDs installed (Standard or Experimental channel)
[ ] Controller chosen (Cilium / Istio / Envoy / NGINX)
[ ] GatewayClass defined
[ ] Gateway (TLS + listener) is up
[ ] At least 1 service in prod via HTTPRoute
[ ] ReferenceGrant for cross-namespace
[ ] Migration plan (conversion with ingress2gateway)
[ ] Observability (Hubble / Prometheus)
[ ] TLS automation with cert-manager
[ ] Canary with Argo Rollouts / Flagger
[ ] Persona split: cluster-ops vs app-dev
[ ] Sunset date for the old Ingress controller
[ ] Vendor compliance via conformance test
[ ] DR: Gateway down → backup controller
[ ] Quarterly: spec update (Gateway API is rapidly evolving)
```

---

## 📚 References

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

> *"Using Ingress in 2026 still works — but it's an **aging** architecture.
> Let new services be born on Gateway API, and migrate the old ones
> gradually. In 2027 Ingress will be in 'legacy mode'."*
