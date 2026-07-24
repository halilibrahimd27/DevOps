---
description: "Running Ingress and Gateway API side by side: migration strategy, the hybrid pattern (new services on Gateway, old ones on Ingress), and when to pick which."
tags:
  - Networking
  - Kubernetes
  - Platform Engineering
---
# Ingress vs Gateway API — Side by Side, Which One When

> *"In 2026 Ingress is 'aging' but still widespread; Gateway API is new and
> becoming the standard. **Running both at once** is the reality
> of the transition period — one cluster, two APIs."*

This guide summarizes running Ingress + Gateway API **in parallel**, the
migration strategy, and the "new service on Gateway, old one on Ingress"
hybrid pattern.

> Details:
> - [`Gateway-API-Migration.md`](Gateway-API-Migration.md) — full migration plan
> - [`Ingress-NGINX-Patterns.md`](Ingress-NGINX-Patterns.md) — Ingress in production
> - [`Service-Mesh-Comparison.md`](Service-Mesh-Comparison.md) — the mesh side

---

## 🆚 Quick Comparison

| Feature | Ingress (legacy) | Gateway API (new) |
|---|---|---|
| **API maturity** | GA, well-established | GA (HTTPRoute), TCPRoute beta |
| **Persona split** | Single CRD | GatewayClass + Gateway + Route, separate |
| **Protocol** | HTTP-focused | HTTP, gRPC, TCP, UDP, TLS |
| **Cross-namespace** | ❌ | ✅ ReferenceGrant |
| **Traffic split** | Annotation | ✅ Native weight |
| **Controller** | Controller-specific annotations | Standardized |
| **Conformance** | ❌ | ✅ Test suite |

> 🔑 **2026 recommendation**: New services go on **Gateway API**. Existing Ingresses **migrate gradually**.

---

## 🌳 Hybrid Setup (During the Transition)

```
[Cluster]
  │
  ├── ingress-nginx (Ingress controller)
  │   ├── old-app-1 (Ingress)
  │   └── old-app-2 (Ingress)
  │
  └── cilium / envoy gateway (Gateway controller)
      ├── new-app-1 (HTTPRoute)
      └── new-app-2 (HTTPRoute)
```

→ Both controllers are installed in parallel. **Same LB or separate**.

---

## 🔄 Migration Strategy (Summary)

### 1. Week 1: Preparation
- Install the Gateway API CRDs
- Set up a new Gateway controller (Cilium / Envoy / Contour)
- Don't touch existing Ingresses

### 2. Weeks 2-4: New services on Gateway API
- Onboarding guide: new service = HTTPRoute
- Don't touch the old ones

### 3. Weeks 4-12: Migrate what exists (per-service PR)
- Convert with `ingress2gateway` + manual review
- Per-service PR + canary
- DNS/LB don't change (same external IP)

### 4. Weeks 12-16: Sunset
- Ingress usage hits 0 → uninstall the controller

---

## 🛠️ Practical Decision — For New Services

### Decision tree
```
New service launch:
  │
  ├── HTTP only + simple?
  │     │
  │     ├── Is the cluster Gateway API-ready?
  │     │     │
  │     │     ├── YES → Gateway API (HTTPRoute)
  │     │     └── NO → Ingress (but add it to the Gateway migration roadmap)
  │
  ├── gRPC / TCP / UDP?
  │     │
  │     └── Gateway API is mandatory (Ingress doesn't support it)
  │
  ├── Multi-cluster + advanced routing?
  │     │
  │     └── Gateway API + service mesh
  │
  └── Quick prototype, "I'll fix it later"?
        │
        └── Ingress (with the existing controller)
```

---

## 📋 Hybrid Cluster Hygiene

### Preventing collisions on the same host
```
example.com:
  /api/*    → Gateway API (HTTPRoute)
  /legacy/* → Ingress (old)
```

→ **Path-based split**. Ingress on 80/443, Gateway API on 80/443 — same DNS, separate LB.

### Cleaner: Subdomain split
```
api.example.com    → Gateway API (new)
legacy.example.com → Ingress (temporary)
```

### LB separation
- Old LB: attached to the Ingress controller
- New LB: attached to the Gateway controller
- Cost +1 LB, but clean

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Same host running both Ingress and Gateway | Collisions, hard to debug | Separate by path/subdomain |
| Big-bang migration | Breaks production | Staged + canary |
| New service on Ingress | Tech debt | Gateway API by default |
| No sunset plan for the old Ingress | Runs in parallel forever | 12-16 week sunset target |
| Calling Gateway API "still too new" | Spec is stable, most controllers are GA | Production-ready in 2026 |
| No migration tool | Manual conversion causes errors | `ingress2gateway` |

---

## 📚 References

- **Gateway API Spec** — gateway-api.sigs.k8s.io
- **ingress2gateway** — github.com/kubernetes-sigs/ingress2gateway
- [`Gateway-API-Migration.md`](Gateway-API-Migration.md) — detailed migration
- [`Ingress-NGINX-Patterns.md`](Ingress-NGINX-Patterns.md) — Ingress in production
- [`Service-Mesh-Comparison.md`](Service-Mesh-Comparison.md)
- [`Cilium-eBPF-Intro.md`](Cilium-eBPF-Intro.md)

---

## 📋 Checklist

```
[ ] Gateway API CRDs are installed and the controller (Cilium / Envoy / Contour) is up
[ ] The new-service onboarding guide says "default = HTTPRoute", Ingress is the exception only
[ ] No Ingress + Gateway collision on the same host during the hybrid period (path/subdomain split is clear)
[ ] Old LB (Ingress) vs new LB (Gateway) separation, or the path-split, is a documented deliberate decision
[ ] Existing Ingresses are converted with `ingress2gateway` and go through manual review
[ ] Migration isn't big-bang; it proceeds via per-service PR + canary
[ ] Services that need gRPC/TCP/UDP are routed to Gateway API (not left on Ingress)
[ ] There's a 12-16 week sunset target for the old Ingress, with a tracking metric (remaining Ingress count)
[ ] DNS/external IP doesn't change during migration (no downtime for users)
```

---

> *"2026 = **the transition year**. Raise the newborns on Gateway API,
> let the old ones age gracefully (temporarily), and with a planned sunset
> get to Gateway API-only tomorrow."*
