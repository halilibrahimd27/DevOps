---
description: "Step-by-step, CIS Benchmark-based prod-grade Kubernetes hardening: threat model, API server hardening, RBAC, NetworkPolicy and Pod Security Standards guide."
tags:
  - Security
  - Kubernetes
  - Networking
  - Compliance
---
# Kubernetes Hardening — 2026 Production Guide

> *"Saying the default Kubernetes config 'works' is like 'elegantly closing' a
> bank vault door without actually locking it. It's not knowing how to close
> it that matters, but **closing it correctly**."*

This guide goes step by step through taking a Kubernetes cluster to
**prod-grade** level. It builds on the CIS Benchmark, but instead of saying
"touch this line" it explains **why you touch it**.

---

## 🎯 Target Threat Model

| Attacker profile | Vector | Control |
|---|---|---|
| **Compromised pod** | RCE → lateral movement inside the cluster | NetworkPolicy, RBAC, PSS |
| **Compromised node** | kubelet credential → pod hijack | Node-level seccomp, AppArmor |
| **Compromised supply chain** | Malicious image | cosign verify, image scan, admission |
| **Insider threat** | Broad RBAC → data exfiltration | Least-privilege, audit log |
| **Internet-facing API** | Direct attack on the Kubernetes API | Private API, OIDC, network ACL |
| **Misconfigured ingress** | Publicly exposed dashboard | Policy-as-code, default-deny |

---

## 1️⃣ Cluster API Server Hardening

### Anonymous auth disabled
```bash
# kube-apiserver flag
--anonymous-auth=false
```
The default is `true` — it must be disabled. Otherwise `system:anonymous` can gain read access to many endpoints.

### User authentication: OIDC
- Static tokens (`--token-auth-file`) are **BANNED**.
- Use ServiceAccount token + OIDC.
- Enterprise IdP integration (Keycloak, Auth0, Azure AD, Google Workspace).

```yaml
# kube-apiserver
--oidc-issuer-url=https://<IDP_URL>
--oidc-client-id=<CLIENT_ID>
--oidc-username-claim=email
--oidc-groups-claim=groups
```

### Audit logging
No audit by default — turn it on **without fail**.

```yaml
# audit-policy.yaml (example)
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - RequestReceived
rules:
  # Full log for Secret operations
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["secrets", "configmaps"]
  # exec/portforward are critical
  - level: Request
    resources:
      - group: ""
        resources: ["pods/exec", "pods/portforward", "pods/proxy"]
  # Metadata is enough for the rest of the writes
  - level: Metadata
    verbs: ["create", "update", "patch", "delete"]
  # Reads are the noisy ones
  - level: None
    verbs: ["get", "list", "watch"]
```

```bash
--audit-log-path=/var/log/kube-audit.log
--audit-log-maxage=30
--audit-log-maxbackup=10
--audit-log-maxsize=100
--audit-policy-file=/etc/kubernetes/audit-policy.yaml
```

> 🔑 **Audit log → SIEM.** Ship it to Wazuh / Splunk / Loki. If it stays only in a file, nobody looks at it.

### API server: public or private?
- ✅ **Private** + bastion / VPN + cloud-native auth proxy (e.g. AWS EKS Private endpoint + Tailscale).
- ⚠️ If public: IP allow-list, `--enable-admission-plugins=NodeRestriction`, MFA-bound OIDC.
- ❌ Public + token-only auth: **stop right there, a breach is only a matter of time.**

---

## 2️⃣ Pod Security Standards (PSS)

PSP (Pod Security Policy) was **removed** (k8s 1.25+). Use **PSS + admission** instead.

| Profile | Usage |
|---|---|
| **privileged** | System components (CNI, CSI). Only `kube-system`. |
| **baseline** | Traditional workloads; root blocked but some things allowed. |
| **restricted** | **2026 target.** All app namespaces. |

### Apply the restricted profile at the namespace level
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: <NAMESPACE>
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### What does `restricted` enforce?
- `runAsNonRoot: true`
- `allowPrivilegeEscalation: false`
- `readOnlyRootFilesystem: true` *(recommended, not mandatory in restricted)*
- `seccompProfile.type: RuntimeDefault`
- Capabilities: `drop: [ALL]`, additions: only `NET_BIND_SERVICE`
- Restricted volume types (no hostPath; emptyDir/configMap/secret/projected/pvc/csi allowed)

### Pod manifest example (restricted-compliant)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  template:
    spec:
      automountServiceAccountToken: false
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        runAsGroup: 10001
        fsGroup: 10001
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: app
          image: <REGISTRY>/<APP>:<DIGEST>
          imagePullPolicy: IfNotPresent
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: [ALL]
          resources:
            requests: {cpu: 100m, memory: 128Mi}
            limits: {cpu: 500m, memory: 512Mi}
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: tmp
          emptyDir: {}
```

> ⚠️ `automountServiceAccountToken: false` — if the pod doesn't need a
> ServiceAccount token, **disable it**. It blocks access to the API from
> inside a compromised container.

---

## 3️⃣ NetworkPolicy: Default-Deny

Default Kubernetes networking: **everything can talk to everything.** This is the
biggest lateral-movement vector.

### Default-deny in every namespace
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: <NAMESPACE>
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
```

The moment this is applied, **no traffic passes** — including DNS. Then add a **whitelist**:

### DNS permission (always needed)
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: <NAMESPACE>
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

### Service-to-service whitelist
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-to-postgres
  namespace: <NAMESPACE>
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes: [Ingress]
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: api
      ports:
        - protocol: TCP
          port: 5432
```

### L7 NetworkPolicy with Cilium / Calico
Standard NetworkPolicy is L4 (port). Cilium gives you L7:

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: api-to-payment-service
spec:
  endpointSelector:
    matchLabels: {app: api}
  egress:
    - toEndpoints:
        - matchLabels: {app: payment}
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
          rules:
            http:
              - method: "POST"
                path: "/charge"
              - method: "GET"
                path: "/health"
```

> 🔑 **On the way into production:** every namespace should start with
> `default-deny` + `allow-dns`. Then the service owner adds the required rules via PR.

---

## 4️⃣ RBAC — Least Privilege

### Anti-pattern: sharing cluster-admin
```bash
# ❌ NEVER DO THIS
kubectl create clusterrolebinding dev-admin \
  --clusterrole=cluster-admin --user=dev@example.com
```

### Correct: namespace-bound role + group
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: app-team-a
  name: developer
rules:
  - apiGroups: ["", "apps"]
    resources: ["pods", "deployments", "services", "configmaps"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["pods/log", "pods/exec"]
    verbs: ["get", "list", "create"]
  # Secret read is DELIBERATELY absent
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-a-developers
  namespace: app-team-a
subjects:
  - kind: Group
    name: team-a-devs    # OIDC group claim
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

### RBAC audit query
```bash
# Who gets cluster-admin?
kubectl get clusterrolebindings -o json | \
  jq '.items[] | select(.roleRef.name=="cluster-admin") |
      {name: .metadata.name, subjects: .subjects}'

# who can write to which resource
kubectl auth can-i --list --as=<USER>

# find dangerous roles that use wildcards
kubectl get clusterroles -o json | \
  jq '.items[] | select(.rules[]?.verbs[]? == "*" or .rules[]?.resources[]? == "*") |
      .metadata.name'
```

### ServiceAccount token: don't create a token if you don't use one
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: <APP>
automountServiceAccountToken: false
```

K8s 1.24+ no longer auto-creates a secret for a SA. That's good — it requires an explicit token.

---

## 5️⃣ Secret Management

> Details: [`Secrets-Management.md`](Secrets-Management.md). Summary rules here.

| Don't | Do |
|---|---|
| Keeping secrets in Git | Encrypted commit with SOPS / sealed-secrets |
| Thinking a cluster `Secret` (base64) is enough | Vault + External Secrets Operator |
| Injecting secrets via `env` (visible in `ps`) | File mount + tmpfs |
| A single secret shared across all apps | A separate secret per service |
| Manual secret rotation | ESO + secret rotator → automatic |

### etcd encryption-at-rest
```yaml
# /etc/kubernetes/encryption.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources: ["secrets"]
    providers:
      - kms:
          name: <KMS_NAME>
          endpoint: unix:///var/run/kmsplugin/socket.sock
          cachesize: 1000
      - identity: {}    # fallback (read existing unencrypted)
```

> ⚠️ By default, secrets in etcd are **plaintext base64**. Without a KMS provider,
> anyone who steals an etcd snapshot reads the secrets.

---

## 6️⃣ Image Security

### Signature requirement at admission (Kyverno)
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signatures
spec:
  validationFailureAction: Enforce
  rules:
    - name: verify-signature
      match:
        any:
          - resources:
              kinds: [Pod]
      verifyImages:
        - imageReferences:
            - "<REGISTRY>/*"
          attestors:
            - entries:
                - keyless:
                    subject: "https://github.com/<ORG>/*"
                    issuer: "https://token.actions.githubusercontent.com"
```

### Image policy catalog
```yaml
# Banned: latest tag
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
spec:
  validationFailureAction: Enforce
  rules:
    - name: validate-image-tag
      match:
        any:
          - resources:
              kinds: [Pod]
      validate:
        message: "':latest' tag is banned; use a version/digest."
        pattern:
          spec:
            containers:
              - image: "!*:latest"
```

Ready-made templates: [`17-Templates/kyverno-policies/`](../17-Templates/kyverno-policies/).

### Image scan gate (Trivy)
```yaml
# .github/workflows/scan.yml
- uses: aquasecurity/trivy-action@<VERSION>
  with:
    image-ref: <REGISTRY>/<APP>:${{ github.sha }}
    format: sarif
    output: trivy.sarif
    severity: CRITICAL,HIGH
    exit-code: 1   # CRITICAL/HIGH → fail
    ignore-unfixed: true   # don't make noise when there's no fix
```

---

## 7️⃣ Node Hardening

### Kubelet
```yaml
# /var/lib/kubelet/config.yaml
authentication:
  anonymous: {enabled: false}
  webhook: {enabled: true}
authorization:
  mode: Webhook
readOnlyPort: 0           # 10255 disabled
protectKernelDefaults: true
streamingConnectionIdleTimeout: 5m
makeIPTablesUtilChains: true
eventRecordQPS: 0         # prevents event-spam DDoS
```

### Container runtime: containerd
- Docker shim → containerd (k8s 1.24+ default)
- gVisor (`--runtime=runsc`) sandbox for untrusted workloads
- Kata Containers when VM-level isolation is needed

### seccomp default
Cluster-wide default seccomp profile:
```yaml
# kubelet config
seccompDefault: true   # k8s 1.27+ stable
```

### AppArmor / SELinux
- Ubuntu/Debian → AppArmor profile per pod:
  ```yaml
  metadata:
    annotations:
      container.apparmor.security.beta.kubernetes.io/<CONTAINER>: runtime/default
  ```
- RHEL/CentOS → SELinux Enforcing.

---

## 8️⃣ Runtime Security (Falco / Tetragon)

"Build-time" security alone isn't enough. Anomalies in running pods:

```yaml
# Falco rule example
- rule: Shell in container
  desc: A shell was started inside a container (should not happen outside debugging)
  condition: >
    container and proc.name in (bash, sh, zsh)
    and not container.image.repository in (allowed_debug_images)
  output: >
    Shell in container (user=%user.name container=%container.name
    cmd=%proc.cmdline)
  priority: WARNING
  tags: [container, shell]
```

Tetragon (eBPF) has lower overhead than Falco and integrates with the Cilium ecosystem.

> Details: [`Runtime-Security.md`](Runtime-Security.md) (Phase 2).

---

## 9️⃣ CIS Benchmark Automation

```bash
# kube-bench: CIS Benchmark check
docker run --rm --pid=host \
  -v /etc:/etc:ro -v /var:/var:ro \
  aquasec/kube-bench:latest run --targets node,policies

# Cluster-wide kube-hunter (penetration-test perspective)
docker run --rm aquasec/kube-hunter:latest --remote <CLUSTER_API>
```

Run it once a week in CI → report to Slack/PagerDuty.

---

## 🔟 Multi-Tenancy (Soft Multi-Tenancy)

Different teams on the same cluster:

| Control | Purpose |
|---|---|
| **Namespace per team** | Logical separation |
| **ResourceQuota** | Keep one tenant from consuming the cluster |
| **LimitRange** | Default request/limit |
| **NetworkPolicy** | No cross-tenant traffic |
| **PSS restricted** | No privilege escalation |
| **PriorityClass** | System pods > tenant pods |
| **NodeSelector / Taint** | Tenant isolation at the node level (hard-tenancy approach) |

For **hard multi-tenancy** (e.g. isolated clusters per SaaS customer):
- vCluster, Capsule or cluster-per-tenant.
- Hard tenancy on the same cluster = the attacker eventually breaks out (via a kernel exploit).

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| `kubectl create clusterrolebinding ...cluster-admin` | Becomes owner of the whole cluster | Namespace-bound Role + group |
| `image: nginx` (no tag) | Pulls `latest` | Digest pin: `nginx@sha256:...` |
| `runAsUser: 0` | Container = root | `runAsNonRoot: true`, UID 10000+ |
| `hostNetwork: true` (unnecessary) | Pod on the node IP | Expose via a Service |
| `hostPath: /` | Node FS open to the pod | PV/PVC, CSI |
| `privileged: true` | All capabilities open | Only for DaemonSets, don't push into restricted |
| Default ServiceAccount + token mount | Explicit access to the API | `automountServiceAccountToken: false` |
| `no NetworkPolicy` | Every pod to every pod | Default-deny + whitelist |
| `Secret` as an env var | Visible in the process list | File mount tmpfs |
| No audit log | Forensics impossible | Audit + SIEM |
| Public API server + token | Breach is a matter of time | Private API + OIDC + MFA |

---

## 📋 Hardening Checklist (for sprint zero)

```
[ ] Audit log enabled + shipped to SIEM
[ ] OIDC integrated, no static tokens
[ ] API server private or IP allow-list + MFA
[ ] etcd encryption-at-rest (KMS provider)
[ ] PSS: restricted enforce on non-system namespaces
[ ] NetworkPolicy: default-deny + DNS whitelist on all namespaces
[ ] RBAC: cluster-admin <= 2 people, everyone else namespace-bound
[ ] ServiceAccount: unused token mount disabled
[ ] Image: digest pinning, signed images, Kyverno verifyImages
[ ] Image scan: Trivy in CI, CRITICAL/HIGH = fail
[ ] Secrets: Vault + ESO or equivalent, no plaintext in etcd
[ ] kube-bench: once a week, report the results
[ ] Falco/Tetragon: at least a "shell in container" + "writes to /etc" alert
[ ] LimitRange + ResourceQuota in every namespace
[ ] Container: runAsNonRoot, readOnlyRootFilesystem, drop ALL caps
[ ] seccompDefault=true (k8s ≥1.27)
[ ] Backup: etcd + PV snapshot + restore drill
```

---

## 📚 References

- **CIS Kubernetes Benchmark v1.10** (2025) — automated with `kube-bench`
- **NSA/CISA Kubernetes Hardening Guide** v1.2
- **Kubernetes Pod Security Standards** — kubernetes.io/docs/concepts/security/pod-security-standards/
- **Falco Rules** — falco.org/docs/rules/
- [`DevSecOps-Pipeline.md`](DevSecOps-Pipeline.md) — the pipeline side
- [`Policy-as-Code-OPA-Kyverno.md`](Policy-as-Code-OPA-Kyverno.md) (Phase 2)
- [`Secrets-Management.md`](Secrets-Management.md) (Phase 2)
- [`05-Kubernetes/Production-Checklist.md`](../05-Kubernetes/Production-Checklist.md) — operational checklist
- [`17-Templates/kyverno-policies/`](../17-Templates/kyverno-policies/) — ready-made policy examples

---

> *"Hardening isn't a 'one-time thing' — it's **continuous compliance**.
> A cluster drifts out of the checklist within a week; without automation,
> the drift goes unnoticed."*

---

> 🎓 **Learning Path:** This document is used as a "Read first" resource in the [`D1`](../22-Learning-Path/block-d-orchestration/D1-k8s-temel.md) module.
