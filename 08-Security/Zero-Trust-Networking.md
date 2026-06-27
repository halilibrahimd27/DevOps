---
description: "Zero Trust networking'i uygulanabilir kilan rehber: NIST 800-207 prensipleri, BeyondCorp, her yerde mTLS, service mesh authZ ve workload identity."
---
# Zero-Trust Networking — "Network Sınırı" Yalanı Bitti

> *"VPN'in arkasında olan her şey güvenilir" diye düşünmek 2026'da
> SolarWinds'ten beri **antika**. Saldırgan içeride; **her bağlantı
> yeniden ispat etmeli**."*

Zero Trust = "kimseye varsayılan güven yok; her erişim **doğrulanmış
kimlik + kontekst + en az ayrıcalık**". Bu rehber kavramı **uygulanabilir**
hale indirir: BeyondCorp prensipleri, mTLS her yerde, service mesh
authZ ve workload identity.

---

## 🎯 Zero Trust Prensipleri (NIST 800-207)

| Prensip | Pratik anlamı |
|---|---|
| **Never trust, always verify** | Her API çağrısı authenticated + authorized |
| **Least privilege** | Hiçbir kimliğin gerek olmayan erişimi yok |
| **Assume breach** | Saldırgan zaten içeride varsay, lateral movement engelle |
| **Verify explicitly** | Identity + device + context + behavior her seferinde |
| **Micro-segmentation** | Network seviyesinde ince granül izolasyon |
| **End-to-end encryption** | Network güvenli olsa bile veri encrypted |

---

## 🏛️ Mimarinin Değişimi

### Eski (perimeter-based)
```
[INTERNET] → [FIREWALL/VPN] → [TRUSTED INTERNAL NETWORK]
                                        │
                          ┌─────────────┼─────────────┐
                          ▼             ▼             ▼
                       App A         App B         Database
                    (full trust)   (full trust)  (full trust)
```
**Sorun:** Bir tane app compromise → diğer her şey hedef.

### Zero Trust
```
[ANY NETWORK]
     │
     ▼
[Identity Provider (OIDC)] ← her istek burada doğrulanır
     │
     ▼
[Policy Engine] ← her istek için "izinli mi?" kararı
     │
┌────┴────────────────────┐
▼                          ▼
App A ←mTLS+JWT→ App B ←mTLS+JWT→ Database
(her bağlantı kanıtlanmış)
```

---

## 🛂 Identity-Based Access (BeyondCorp)

### Geleneksel
- Geliştirici → VPN → internal IP → app
- VPN compromise = full network access

### BeyondCorp / Zero Trust Access
- Geliştirici → laptop'tan direkt internet → app
- Her istek IdP'de auth → device posture check → policy decision

**Pratik araçlar:**
| Araç | Niche |
|---|---|
| **Cloudflare Access** | SaaS, kolay kurulum |
| **Tailscale** | WireGuard tabanlı, ekip dostu |
| **Pomerium** | Self-hosted, OSS |
| **Teleport** | SSH/Kubernetes/DB access ile |
| **Google IAP** | GCP ekosistem |
| **AWS Verified Access** | AWS ekosistem |

### Tailscale ACL örneği
```hcl
{
  "groups": {
    "group:devs":  ["alice@example.com", "bob@example.com"],
    "group:sre":   ["ops@example.com"],
  },
  "acls": [
    // Devs sadece dev cluster'a
    {"action": "accept", "src": ["group:devs"], "dst": ["tag:dev-cluster:*"]},
    // SRE her cluster'a
    {"action": "accept", "src": ["group:sre"], "dst": ["tag:k8s:*"]},
    // DB direkt erişim yok, bastion üzerinden
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

Workload'lar (pod, VM, lambda) için **kriptografik kimlik**. Static
credential yok; her workload'a kısa-ömürlü cert (SVID).

### SPIFFE ID
```
spiffe://prod.example.com/ns/payments/sa/api-server
```
= "production trust domain'inde, payments namespace'inde, api-server SA'sı".

### SPIRE Server + Agent
```bash
# SPIRE server (control plane)
helm install spire spiffe/spire \
  -n spire --create-namespace

# Her node'a agent DaemonSet
# Agent → workload'a SVID dağıtır
```

### Workload tarafı (SDK)
```go
// Go: workload SVID alır
import "github.com/spiffe/go-spiffe/v2/workloadapi"

source, _ := workloadapi.NewX509Source(ctx)
defer source.Close()

svid, _ := source.GetX509SVID()
// svid.Certificates → mTLS için kullanılır
```

```python
# Python (pyspiffe)
from pyspiffe.workloadapi.default_workload_api_client import DefaultWorkloadApiClient

client = DefaultWorkloadApiClient()
svid_response = client.fetch_x509_svids()
```

---

## 🕸️ Service Mesh ile Zero Trust (Istio / Linkerd / Cilium)

### Karşılaştırma

| Özellik | **Istio** | **Linkerd** | **Cilium Service Mesh** |
|---|---|---|---|
| Sidecar | Envoy proxy | linkerd2-proxy (Rust) | Sidecarless (eBPF) |
| Performans | Orta (sidecar overhead) | İyi | En iyi (eBPF) |
| mTLS otomatik | ✅ | ✅ | ✅ |
| L7 policy | ✅ (zengin) | Sınırlı | ✅ (Cilium NetworkPolicy) |
| Setup | Karmaşık | Basit | K8s + Cilium gerektirir |
| Best for | Multi-cluster, kompleks | Hızlı başla, basit ihtiyaç | Cilium kullanıyorsan |

> 🔑 **Pratik öneri:** Yeni başlıyorsan **Linkerd**. Cilium varsa **Cilium
> Service Mesh** (sidecarless). Multi-cluster + kompleks routing varsa
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
  {}   # boş policy = deny all
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

### JWT-bağlı request policy
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
# linkerd: namespace tüm communication mTLS
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

> 🔑 **L7 zero trust:** Sadece "API'den DB'ye port 5432 izinli" değil, **"hangi
> HTTP method, hangi path, hangi header"** seviyesinde.

---

## 🔑 mTLS Her Yerde

### Niye?
- Internal network "güvenli" varsayımı çöktü
- Network sniffer compromise → unencrypted traffic'i okur
- Compliance (PCI DSS, HIPAA, ISO 27001) — internal mTLS bekleniyor

### Kim verir?
| Yöntem | Cert lifecycle |
|---|---|
| **Istio Citadel** | Otomatik, 24h rotation |
| **Linkerd identity** | Otomatik, 24h |
| **cert-manager + intermediate CA** | Manual veya auto-rotate |
| **SPIFFE/SPIRE** | Workload-bound, kısa ömürlü |
| **HashiCorp Vault PKI** | Dynamic, esnek |

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

## 🛂 Egress Control: "Pod Internet'e Çıkmasın" (Beklenmedikçe)

Zero trust = ingress kadar **egress** önemli. Compromise → C2 callback engellensin.

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

### Whitelist: sadece DNS + internal + belirli external
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

> 🚨 **Önce audit, sonra enforce.** Mevcut traffic'i 1-2 hafta logla, baseline
> oluştur, sonra deny-all + whitelist.

---

## 🧰 Bastion / Jump Host Modern Hali

### Eski: SSH bastion
```
dev → SSH → bastion (paylaşımlı kullanıcı, password) → internal hosts
```
Sorunlar: paylaşımlı kullanıcı, audit zor, key paylaşımı.

### Modern: Teleport / AWS SSM Session Manager / Cloudflare Zero Trust
- **Identity-bound** (OIDC, kişiye özel)
- **Audit** her komut kayıt
- **Session recording**
- **Just-in-time** access (PIM): sadece onay sonrası 1 saat

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

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "VPN içindeyim, güvendeyim" | VPN compromise = full access | Identity-bound + per-request auth |
| Paylaşımlı SSH key (`ec2-user.pem`) | Audit yok, rotation imkansız | Teleport / SSM Session Manager |
| Internal API'lar mTLS'siz | Network sniffer okur | mTLS her servis-servis |
| Pod'lar internet'e açık egress | C2 callback engelsiz | Default-deny egress + allowlist |
| Tek IdP token uzun ömürlü | Compromise window büyük | Short TTL + refresh + step-up MFA |
| Service-to-service auth: shared secret env'de | Compromise lateralize | mTLS / SPIFFE workload identity |
| K8s ServiceAccount token mount default-on | Lateral movement | `automountServiceAccountToken: false` |
| Network policy var ama L4 (port) only | HTTP path/method anomalisi yakalanamaz | Cilium L7 / Istio AuthZ |
| BeyondCorp setup'ta device posture check yok | Compromised laptop tüm erişimi alır | Cloudflare Access + device cert |
| Audit log internal-only, SIEM yok | Forensic eksik | Tüm policy decision SIEM'de |

---

## 📊 Olgunluk Modeli (CISA Zero Trust Maturity Model)

| Pillar | Traditional | Initial | Advanced | Optimal |
|---|---|---|---|---|
| **Identity** | Username/password | MFA | OIDC + risk-based | Phishing-resistant + continuous |
| **Devices** | Trust on connect | Inventory | Health check | Continuous compliance check |
| **Networks** | Static perimeter | Some segments | Micro-segments | Software-defined per workload |
| **Apps** | Public/Internal | TLS everywhere | mTLS + JWT | Workload identity (SPIFFE) |
| **Data** | Backup | Encryption at rest | Classification + DLP | Continuous risk scoring |

> **2026 hedefi (orta-büyük şirket):** Çoğu pillar'da **Advanced**, kritik
> alanlarda (data, identity) **Optimal**'a yaklaşmak.

---

## 📋 Zero Trust Migration Checklist

```
[ ] IdP merkezi (OIDC) — tüm user erişim oradan
[ ] MFA zorunlu (her IdP login)
[ ] Phishing-resistant MFA (FIDO2 / WebAuthn) hedefte
[ ] Device posture check (managed laptop, encrypted disk, OS güncel)
[ ] BeyondCorp gateway (Cloudflare Access / Tailscale / Pomerium)
[ ] VPN'siz mimari hedef olarak yazılı
[ ] Workload identity (SPIFFE veya cloud-native: AWS IRSA, GCP Workload Identity)
[ ] mTLS service-to-service her yerde (service mesh ya da SPIFFE)
[ ] L4 + L7 NetworkPolicy (Cilium veya Istio)
[ ] Default-deny egress + allowlist
[ ] DNS audit (egress'te FQDN bazında)
[ ] SSH/DB access: Teleport veya equivalent (kişiye-bound, audit, MFA)
[ ] Just-in-time access (PIM) kritik sistemler için
[ ] Tüm authZ kararı audit log → SIEM
[ ] Quarterly: zero trust gap analizi (CISA modeli üzerinden)
```

---

## 📚 Referanslar

- **NIST 800-207** — Zero Trust Architecture
- **CISA Zero Trust Maturity Model v2.0**
- **Google BeyondCorp Papers** — beyondcorp.com
- **SPIFFE Spec** — spiffe.io
- **Istio Security Docs** — istio.io/latest/docs/concepts/security/
- **Linkerd Policy Docs** — linkerd.io/2/features/server-policy/
- **Cilium Network Policy** — docs.cilium.io
- [`Kubernetes-Hardening.md`](Kubernetes-Hardening.md) — RBAC + NetworkPolicy
- [`Secrets-Management.md`](Secrets-Management.md) — workload identity
- [`09-Networking/`](../09-Networking/) — service mesh deep-dive (Faz 3)

---

> *"Zero trust 'yeni VPN' değildir; **mimari değişim**. 'Network'e
> güvenmek' yerine **kimliğe + kanıta** güvenmektir. Geçiş 2-3 yıl sürer;
> başlamayan, **eskimiş** kalmaktır."*
