---
description: "The guide that makes Zero Trust networking actionable: NIST 800-207 principles, BeyondCorp, mTLS everywhere, service mesh authZ and workload identity."
tags:
  - Security
  - Networking
  - Service Mesh
  - Kubernetes
---
# Zero-Trust Networking — The "Network Perimeter" Lie Is Over

> *"Thinking 'everything behind the VPN is trusted' has been **antique** since
> SolarWinds in 2026. The attacker is already inside; **every connection must
> re-prove itself**."*

Zero Trust = "no default trust for anyone; every access is **verified
identity + context + least privilege**." This guide boils the concept down to
something **actionable**: BeyondCorp principles, mTLS everywhere, service mesh
authZ and workload identity.

---

## 🎯 Zero Trust Principles (NIST 800-207)

| Principle | Practical meaning |
|---|---|
| **Never trust, always verify** | Every API call authenticated + authorized |
| **Least privilege** | No identity has access it doesn't need |
| **Assume breach** | Assume the attacker is already inside, block lateral movement |
| **Verify explicitly** | Identity + device + context + behavior every single time |
| **Micro-segmentation** | Fine-grained isolation at the network level |
| **End-to-end encryption** | Data encrypted even if the network is secure |

---

## 🏛️ The Architecture Shift

### Old (perimeter-based)
```
[INTERNET] → [FIREWALL/VPN] → [TRUSTED INTERNAL NETWORK]
                                        │
                          ┌─────────────┼─────────────┐
                          ▼             ▼             ▼
                       App A         App B         Database
                    (full trust)   (full trust)  (full trust)
```
**Problem:** One app compromised → everything else is a target.

### Zero Trust
```
[ANY NETWORK]
     │
     ▼
[Identity Provider (OIDC)] ← every request is verified here
     │
     ▼
[Policy Engine] ← "is it allowed?" decision for every request
     │
┌────┴────────────────────┐
▼                          ▼
App A ←mTLS+JWT→ App B ←mTLS+JWT→ Database
(every connection proven)
```

---

## 🛂 Identity-Based Access (BeyondCorp)

### Traditional
- Developer → VPN → internal IP → app
- VPN compromise = full network access

### BeyondCorp / Zero Trust Access
- Developer → straight from laptop over the internet → app
- Every request authed at the IdP → device posture check → policy decision

**Practical tools:**
| Tool | Niche |
|---|---|
| **Cloudflare Access** | SaaS, easy setup |
| **Tailscale** | WireGuard-based, team-friendly |
| **Pomerium** | Self-hosted, OSS |
| **Teleport** | With SSH/Kubernetes/DB access |
| **Google IAP** | GCP ecosystem |
| **AWS Verified Access** | AWS ecosystem |

### Tailscale ACL example
```hcl
{
  "groups": {
    "group:devs":  ["alice@example.com", "bob@example.com"],
    "group:sre":   ["ops@example.com"],
  },
  "acls": [
    // Devs only to the dev cluster
    {"action": "accept", "src": ["group:devs"], "dst": ["tag:dev-cluster:*"]},
    // SRE to every cluster
    {"action": "accept", "src": ["group:sre"], "dst": ["tag:k8s:*"]},
    // No direct DB access, via bastion
    {"action": "accept", "src": ["group:sre"], "dst": ["tag:bastion:22"]},
  ],
  "tagOwners": {
    "tag:k8s":      ["group:sre"],
    "tag:bastion":  ["group:sre"],
  },
}
```

---

## 🔐 Workload Identity: SPIFFE/SPIRE

**Cryptographic identity** for workloads (pod, VM, lambda). No static
credential; a short-lived cert (SVID) for every workload.

### SPIFFE ID
```
spiffe://prod.example.com/ns/payments/sa/api-server
```
= "the api-server SA, in the payments namespace, in the production trust domain".

### SPIRE Server + Agent
```bash
# SPIRE server (control plane)
helm install spire spiffe/spire \
  -n spire --create-namespace

# Agent DaemonSet on every node
# Agent → distributes SVIDs to workloads
```

### Workload side (SDK)
```go
// Go: workload fetches SVID
import "github.com/spiffe/go-spiffe/v2/workloadapi"

source, _ := workloadapi.NewX509Source(ctx)
defer source.Close()

svid, _ := source.GetX509SVID()
// svid.Certificates → used for mTLS
```

```python
# Python (pyspiffe)
from pyspiffe.workloadapi.default_workload_api_client import DefaultWorkloadApiClient

client = DefaultWorkloadApiClient()
svid_response = client.fetch_x509_svids()
```

---

## 🕸️ Zero Trust with a Service Mesh (Istio / Linkerd / Cilium)

### Comparison

| Feature | **Istio** | **Linkerd** | **Cilium Service Mesh** |
|---|---|---|---|
| Sidecar | Envoy proxy | linkerd2-proxy (Rust) | Sidecarless (eBPF) |
| Performance | Medium (sidecar overhead) | Good | Best (eBPF) |
| Automatic mTLS | ✅ | ✅ | ✅ |
| L7 policy | ✅ (rich) | Limited | ✅ (Cilium NetworkPolicy) |
| Setup | Complex | Simple | Requires K8s + Cilium |
| Best for | Multi-cluster, complex | Quick start, simple needs | If you already use Cilium |

> 🔑 **Practical advice:** If you're just starting, **Linkerd**. If you have Cilium,
> **Cilium Service Mesh** (sidecarless). If you have multi-cluster + complex routing,
> **Istio**.

---

## 🔒 Istio AuthorizationPolicy

### Default deny
```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: default-deny
  namespace: <NAMESPACE>
spec:
  {}   # empty policy = deny all
```

### Whitelist: API → DB
```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: api-to-db
  namespace: <NAMESPACE>
spec:
  selector:
    matchLabels:
      app: postgres
  action: ALLOW
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/<NS>/sa/api-server"]
      to:
        - operation:
            ports: ["5432"]
```

### JWT-bound request policy
```yaml
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: jwt-auth
  namespace: <NAMESPACE>
spec:
  selector:
    matchLabels:
      app: api
  jwtRules:
    - issuer: "https://<IDP>"
      jwksUri: "https://<IDP>/.well-known/jwks.json"
      audiences: ["api.example.com"]

---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: require-jwt
  namespace: <NAMESPACE>
spec:
  selector:
    matchLabels:
      app: api
  action: ALLOW
  rules:
    - from:
        - source:
            requestPrincipals: ["*"]
      when:
        - key: request.auth.claims[scope]
          values: ["read", "write"]
```

---

## 🛡️ Linkerd Zero Trust

```yaml
# linkerd: all communication in the namespace is mTLS
apiVersion: policy.linkerd.io/v1beta3
kind: Server
metadata:
  name: api-http
  namespace: <NS>
spec:
  podSelector:
    matchLabels:
      app: api
  port: http
  proxyProtocol: HTTP/1

---
apiVersion: policy.linkerd.io/v1beta3
kind: AuthorizationPolicy
metadata:
  name: api-auth
  namespace: <NS>
spec:
  targetRef:
    group: policy.linkerd.io
    kind: Server
    name: api-http
  requiredAuthenticationRefs:
    - kind: ServiceAccount
      name: frontend
      namespace: <NS>
```

---

## 🌐 Cilium NetworkPolicy (L7)

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: api-zero-trust
  namespace: <NS>
spec:
  endpointSelector:
    matchLabels:
      app: api
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: frontend
            io.kubernetes.pod.namespace: <NS>
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
          rules:
            http:
              - method: "GET"
                path: "/api/v1/users(/[0-9]+)?"
              - method: "POST"
                path: "/api/v1/orders"
                headers:
                  - 'Content-Type: application/json'
  egress:
    - toEndpoints:
        - matchLabels:
            app: postgres
      toPorts:
        - ports:
            - port: "5432"
              protocol: TCP
    - toFQDNs:
        - matchName: "api.stripe.com"
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
```

> 🔑 **L7 zero trust:** Not just "port 5432 from API to DB is allowed", but at the
> **"which HTTP method, which path, which header"** level.

---

## 🔑 mTLS Everywhere

### Why?
- The "internal network is secure" assumption has collapsed
- Network sniffer compromise → reads unencrypted traffic
- Compliance (PCI DSS, HIPAA, ISO 27001) — internal mTLS is expected

### Who issues it?
| Method | Cert lifecycle |
|---|---|
| **Istio Citadel** | Automatic, 24h rotation |
| **Linkerd identity** | Automatic, 24h |
| **cert-manager + intermediate CA** | Manual or auto-rotate |
| **SPIFFE/SPIRE** | Workload-bound, short-lived |
| **HashiCorp Vault PKI** | Dynamic, flexible |

### cert-manager + cluster-internal CA
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: internal-ca
spec:
  ca:
    secretName: internal-ca-key-pair
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: api-tls
  namespace: <NS>
spec:
  secretName: api-tls
  issuerRef:
    name: internal-ca
    kind: ClusterIssuer
  dnsNames:
    - api.<NS>.svc.cluster.local
  duration: 720h
  renewBefore: 240h
```

---

## 🛂 Egress Control: "Keep the Pod Off the Internet" (Unless Expected)

Zero trust = **egress** matters as much as ingress. Compromise → block the C2 callback.

### Default-deny egress
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-egress
  namespace: <NS>
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress: []
```

### Whitelist: only DNS + internal + specific external
```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: egress-allowlist
  namespace: <NS>
spec:
  endpointSelector: {}
  egress:
    - toEndpoints:
        - matchLabels:
            "k8s:io.kubernetes.pod.namespace": kube-system
            "k8s:k8s-app": kube-dns
      toPorts:
        - ports: [{port: "53", protocol: ANY}]
    - toEntities: [cluster]
    - toFQDNs:
        - matchName: "api.stripe.com"
        - matchName: "registry.npmjs.org"
        - matchPattern: "*.amazonaws.com"
```

> 🚨 **Audit first, enforce later.** Log existing traffic for 1-2 weeks, build a
> baseline, then deny-all + whitelist.

---

## 🧰 The Modern Version of the Bastion / Jump Host

### Old: SSH bastion
```
dev → SSH → bastion (shared user, password) → internal hosts
```
Problems: shared user, hard to audit, key sharing.

### Modern: Teleport / AWS SSM Session Manager / Cloudflare Zero Trust
- **Identity-bound** (OIDC, per-person)
- **Audit** every command recorded
- **Session recording**
- **Just-in-time** access (PIM): only after approval, for 1 hour

```yaml
# Teleport role
kind: role
version: v7
metadata:
  name: db-readonly
spec:
  allow:
    db_labels: {env: prod, role: readonly}
    db_users: ['{{external.email}}']
    db_names: ['app']
  options:
    max_session_ttl: 1h
    require_session_mfa: true
    record_session: {default: strict}
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| "I'm inside the VPN, I'm safe" | VPN compromise = full access | Identity-bound + per-request auth |
| Shared SSH key (`ec2-user.pem`) | No audit, rotation impossible | Teleport / SSM Session Manager |
| Internal APIs without mTLS | Network sniffer reads it | mTLS on every service-to-service |
| Pods with open egress to the internet | C2 callback unblocked | Default-deny egress + allowlist |
| A single long-lived IdP token | Large compromise window | Short TTL + refresh + step-up MFA |
| Service-to-service auth: shared secret in env | Compromise lateralizes | mTLS / SPIFFE workload identity |
| K8s ServiceAccount token mount default-on | Lateral movement | `automountServiceAccountToken: false` |
| NetworkPolicy exists but L4 (port) only | HTTP path/method anomaly can't be caught | Cilium L7 / Istio AuthZ |
| No device posture check in BeyondCorp setup | A compromised laptop gets all access | Cloudflare Access + device cert |
| Audit log internal-only, no SIEM | Forensics missing | Every policy decision in the SIEM |

---

## 📊 Maturity Model (CISA Zero Trust Maturity Model)

| Pillar | Traditional | Initial | Advanced | Optimal |
|---|---|---|---|---|
| **Identity** | Username/password | MFA | OIDC + risk-based | Phishing-resistant + continuous |
| **Devices** | Trust on connect | Inventory | Health check | Continuous compliance check |
| **Networks** | Static perimeter | Some segments | Micro-segments | Software-defined per workload |
| **Apps** | Public/Internal | TLS everywhere | mTLS + JWT | Workload identity (SPIFFE) |
| **Data** | Backup | Encryption at rest | Classification + DLP | Continuous risk scoring |

> **2026 target (mid-to-large company):** **Advanced** in most pillars, approaching
> **Optimal** in critical areas (data, identity).

---

## 📋 Zero Trust Migration Checklist

```
[ ] IdP centralized (OIDC) — all user access goes through it
[ ] MFA mandatory (on every IdP login)
[ ] Phishing-resistant MFA (FIDO2 / WebAuthn) as the target
[ ] Device posture check (managed laptop, encrypted disk, OS up to date)
[ ] BeyondCorp gateway (Cloudflare Access / Tailscale / Pomerium)
[ ] VPN-less architecture written down as the target
[ ] Workload identity (SPIFFE or cloud-native: AWS IRSA, GCP Workload Identity)
[ ] mTLS service-to-service everywhere (service mesh or SPIFFE)
[ ] L4 + L7 NetworkPolicy (Cilium or Istio)
[ ] Default-deny egress + allowlist
[ ] DNS audit (per-FQDN on egress)
[ ] SSH/DB access: Teleport or equivalent (per-person, audit, MFA)
[ ] Just-in-time access (PIM) for critical systems
[ ] Every authZ decision → audit log → SIEM
[ ] Quarterly: zero trust gap analysis (via the CISA model)
```

---

## 📚 References

- **NIST 800-207** — Zero Trust Architecture
- **CISA Zero Trust Maturity Model v2.0**
- **Google BeyondCorp Papers** — beyondcorp.com
- **SPIFFE Spec** — spiffe.io
- **Istio Security Docs** — istio.io/latest/docs/concepts/security/
- **Linkerd Policy Docs** — linkerd.io/2/features/server-policy/
- **Cilium Network Policy** — docs.cilium.io
- [`Kubernetes-Hardening.md`](Kubernetes-Hardening.md) — RBAC + NetworkPolicy
- [`Secrets-Management.md`](Secrets-Management.md) — workload identity
- [`09-Networking/`](../09-Networking/README.md) — service mesh deep-dive (Phase 3)

---

> *"Zero trust isn't a 'new VPN'; it's an **architectural shift**. Instead of
> 'trusting the network', it's trusting **identity + proof**. The transition takes
> 2-3 years; whoever doesn't start stays **obsolete**."*
