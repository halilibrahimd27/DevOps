---
description: "Secret management in GitOps: a comparison of Sealed Secrets, SOPS, External Secrets Operator, and ArgoCD Vault Plugin — encrypted in Git, decrypted in the cluster."
tags:
  - GitOps
  - Secrets
  - Security
  - Kubernetes
---
# Secrets in GitOps — Can You Put a Secret in Git?

> *"GitOps says 'everything lives in Git.' Secrets too. But **not
> plaintext** — that's the rule of the **trick**: encrypted in Git +
> decrypted in the cluster."*

This guide compares the concrete secret-management solutions for a
GitOps workflow — Sealed Secrets, SOPS, External Secrets Operator,
ArgoCD Vault Plugin — and gives you a clear answer for which one to
pick in which scenario.

---

## 🎯 The Problem

The spirit of GitOps: **cluster state = a copy of what's in Git**. But:
- A DB password can't sit in Git as plaintext
- An API key can't be committed to a public repo
- A Vault token can't stay in history

→ **Solution**: **Encrypted** in Git, **decrypted** in the cluster.

---

## ⚖️ 4 Approaches — Comparison

| Approach | Type | GitOps fit | 2026 recommendation |
|---|---|---|---|
| **Sealed Secrets** | K8s controller | ✅ Native | ✅ Small-to-medium |
| **SOPS + age/PGP** | File encryption | ✅ ArgoCD plugin / Flux native | ✅ Multi-recipient |
| **External Secrets Operator** | K8s operator + external store | ✅ Native | ✅ **Production recommendation** |
| **ArgoCD Vault Plugin** | ArgoCD plugin | ⚠️ ArgoCD-specific | ⚠️ Niche |

---

## 🌳 Decision Tree

```
START
  │
  ├── Do you have a backend secret manager? (Vault, AWS SM, GCP SM, Azure KV)
  │     │
  │     ├── YES → External Secrets Operator (ESO)
  │     │   - Most secure + most flexible
  │     │   - The backend already handles audit + rotation
  │     │
  │     └── NO → continue
  │
  ├── Multi-cluster + multi-recipient (DevOps + dev + CI all decrypt)?
  │     │
  │     └── YES → SOPS + age (PGP as a modern alternative)
  │            - Multiple people/clusters can decrypt
  │            - Encrypted commit in Git
  │
  ├── K8s-only, simple setup?
  │     │
  │     └── YES → Sealed Secrets
  │            - Bitnami, popular
  │            - Sealed with the cluster's public key
  │
  └── ArgoCD-specific, simple need?
         │
         └── YES → argocd-vault-plugin
               - Called only at ArgoCD render time
```

---

## 🌱 Sealed Secrets

### Architecture
```
[Developer] kubeseal --> [Encrypted SealedSecret YAML] --> Git
                                                            │
                                              [ArgoCD sync]
                                                            ▼
                                              [Cluster: SealedSecret]
                                                            │
                                              [Sealed-Secrets Controller]
                                              decrypts with private key
                                                            ▼
                                              [Cluster: K8s Secret]
                                              (pod env / mount)
```

### Install
```bash
helm install sealed-secrets sealed-secrets/sealed-secrets \
  -n kube-system

# CLI tool
brew install kubeseal
```

### Encryption
```bash
# 1. Write a plain Secret (do NOT put this in Git!)
cat > db-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: db-creds
  namespace: payments
type: Opaque
stringData:
  password: <PWD>
EOF

# 2. Encrypt it (with the cluster public key)
kubeseal --format yaml \
  --controller-namespace=kube-system \
  --controller-name=sealed-secrets \
  < db-secret.yaml > db-sealed.yaml

# 3. DELETE the plain file (keep it out of Git)
rm db-secret.yaml
git add db-sealed.yaml   # encrypted, safe
```

### Decryption in the cluster
- The Sealed-Secrets controller sees the `SealedSecret`
- Decrypts it with the private key
- Creates a `Secret` resource
- The pod uses env/mount as usual

### ✅ Pro
- Fast setup
- Fully automatic in Git
- Multi-namespace support

### ❌ Con
- **Single private key** — losing it is a disaster
- Multi-cluster needs a separate key per cluster (every secret re-sealed)
- Key rotation is complex
- Cluster-bound (secret becomes trash if the cluster is wiped)

> 🔑 **Backup is mandatory**: back up the controller's private key off-cluster (Vault, KMS, an air-gapped vault).

---

## 🔐 SOPS + age — Multi-Recipient

### Architecture
```
[Developer] sops -e         [Git: encrypted YAML]    [ArgoCD/Flux]
              age key  ─────▶     commit         ─────▶ decrypt + apply
                                                    age private key
```

### Install
```bash
brew install sops age

# age key pair
age-keygen -o /etc/sops/age/keys.txt
# Public key: age1xyz...
```

### `.sops.yaml`
```yaml
creation_rules:
  - path_regex: \.(yaml|yml)$
    encrypted_regex: '^(data|stringData)$'   # ONLY these fields are encrypted
    age: |
      age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p,
      age1prod_cluster_key,
      age1ci_pipeline_key
```

> 🔑 **Multi-recipient**: 3 different public keys — 3 different parties can decrypt (developer, prod cluster, CI). If one key is compromised, the others keep working.

### Encrypt
```bash
# Plain
cat > db-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: db-creds
type: Opaque
stringData:
  password: <PWD>
EOF

# In-place encrypt (creation_rules applied)
sops -e -i db-secret.yaml
git add db-secret.yaml   # data fields are encrypted
```

### Edit
```bash
sops db-secret.yaml   # opens plain in the editor, re-encrypts on save
```

### Usage with Flux (native)
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: payments
spec:
  decryption:
    provider: sops
    secretRef:
      name: sops-age   # private key lives here
  path: ./apps/payments/overlays/prod
```

### With ArgoCD (helm-secrets or kustomize-with-sops plugin)
```yaml
# argocd-cm config
data:
  configManagementPlugins: |
    - name: kustomize-with-sops
      generate:
        command: ["sh", "-c"]
        args: ["kustomize build --enable-alpha-plugins ."]
```

### ✅ Pro
- Multi-recipient, multi-cluster
- Readable diff in Git (only data fields are encrypted)
- age is modern, faster than PGP
- Backup: keep the age key in Vault

### ❌ Con
- Setup is somewhat technical
- Needs a plugin in ArgoCD
- Key distribution requires discipline

---

## 🎯 External Secrets Operator (ESO) — 2026 Recommendation

### Architecture
```
[Vault / AWS SM / GCP SM]
        ↑
        │ ESO controller
        │
[K8s ExternalSecret CR (in Git)]  ─────▶  [K8s Secret (in the cluster)]
   "read kv/<APP>/db from Vault"             pod env/mount
```

> 🔑 **No secret in Git**. Only a recipe that says "fetch this secret from Vault."

### Install
```bash
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace
```

### ClusterSecretStore (Vault auth)
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-prod
spec:
  provider:
    vault:
      server: "https://vault.<DOMAIN>:8200"
      path: "kv"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "<ESO_ROLE>"
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
```

### ExternalSecret (in Git)
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: payments-db
  namespace: payments
spec:
  refreshInterval: "1h"
  secretStoreRef:
    name: vault-prod
    kind: ClusterSecretStore
  target:
    name: payments-db        # this K8s Secret gets created
    template:
      type: Opaque
      data:
        DATABASE_URL: "postgresql://{{ .username }}:{{ .password }}@<DB_HOST>:5432/{{ .dbname }}"
  data:
    - secretKey: username
      remoteRef:
        key: payments/db
        property: username
    - secretKey: password
      remoteRef:
        key: payments/db
        property: password
    - secretKey: dbname
      remoteRef:
        key: payments/db
        property: dbname
```

> This `ExternalSecret` can be committed to Git → **contains no secret**.
> It only references Vault.

### ✅ Pro
- **No plaintext in Git, nothing encrypted either — just a reference**
- Secret rotation in Vault is reflected automatically
- Multi-cluster support (ClusterSecretStore)
- Audit log centralized in Vault
- Dynamic credentials (Vault DB engine)

### ❌ Con
- Vault (or an equivalent) is operational overhead
- Bootstrap problem: K8s SA → Vault token chain needed for Vault auth

---

## 🛠️ ArgoCD Vault Plugin

```yaml
# argocd-cm
configManagementPlugins: |
  - name: argocd-vault-plugin
    init:
      command: [bash, -c]
      args: [helm dependency build]
    generate:
      command: [bash, -c]
      args: [helm template . | argocd-vault-plugin generate -]
```

```yaml
# Placeholder in the manifest
apiVersion: v1
kind: Secret
metadata:
  name: db-creds
stringData:
  password: <path:kv/payments/db#password>   # resolved at ArgoCD render time
```

> ⚠️ ArgoCD-specific. Migrating to Flux means rewriting this.

---

## 🔄 The Bootstrap Problem (and Its Fix)

ESO uses a K8s ServiceAccount token to auth to Vault. But what if Vault hasn't been bootstrapped yet?

### Cold-start flow
```
1. Cluster comes up (empty)
2. Vault is external (managed) → already running
3. Manually set up the Vault K8s auth backend
4. Install ESO (Helm)
5. Apply the ClusterSecretStore manifest (config only, no secret)
6. ExternalSecrets start flowing in via GitOps
```

### Alternative: AWS IAM / GCP Workload Identity
ESO can talk to a **cloud SM directly** → no Vault, cloud-native:
```yaml
provider:
  aws:
    service: SecretsManager
    region: eu-west-1
    auth:
      jwt:
        serviceAccountRef:
          name: external-secrets
```

→ K8s SA → IAM Role (IRSA) → AWS SM access. **Multi-secret without Vault.**

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| Plain Secret YAML in Git | Leak is a matter of time | Sealed/SOPS/ESO |
| No backup of the Sealed-Secrets controller key | Every secret becomes trash when the cluster is rebuilt | Off-cluster encrypted backup |
| A single private key (SOPS + one age key) | Compromise = total compromise | Multi-recipient |
| ESO `refreshInterval` of `30s` | Vault DDoS | 1h+ refresh, push-based events where possible |
| Same secret for dev / staging / prod | Compromise spreads | Per-env Vault path |
| Vault root token in CI | Compromise = owner of the cluster | AppRole / K8s auth, minimal policy |
| Secret in Git history as plaintext (old commit) | The past is still a threat | git-filter-repo + rotate |
| ESO ClusterSecretStore readable from every namespace | Cross-tenant exposure | Namespaced SecretStore |
| Encryption key stored in Git | The "we're encrypted" claim is absurd | Off-Git: KMS / 1Password / vault |
| `kubeseal` plain Secret accidentally pushed to Git | Wrong stage | Pre-commit gitleaks |

---

## 📋 GitOps Secret Strategy Checklist

```
[ ] Approach chosen (justified via ADR/RFC)
[ ] Sealed-Secrets: controller key backed up off-cluster
[ ] SOPS: age multi-recipient (dev + prod + CI)
[ ] ESO: Vault/cloud-native auth + per-namespace store
[ ] ExternalSecret refresh: 1h+ (prevent DDoS)
[ ] Per-env secret separation (dev/staging/prod separate)
[ ] gitleaks pre-commit hook
[ ] CI secret scan (gitleaks-action)
[ ] Git history secret-free (history has been scanned)
[ ] Secret rotation automated (Vault DB engine or scheduled)
[ ] Audit log → SIEM (Vault audit or cloud audit)
[ ] DR plan: what happens to the cluster if the secret manager goes down?
[ ] Documentation: how to add a new secret
[ ] Quarterly: secret usage review (any dead secrets?)
```

---

## 📚 References

- **Sealed Secrets** — github.com/bitnami-labs/sealed-secrets
- **SOPS** — github.com/getsops/sops
- **age** — github.com/FiloSottile/age
- **External Secrets Operator** — external-secrets.io
- **ArgoCD Vault Plugin** — github.com/argoproj-labs/argocd-vault-plugin
- **HashiCorp Vault K8s Auth** — vaultproject.io/docs/auth/kubernetes
- [`ArgoCD-Setup.md`](ArgoCD-Setup.md)
- [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md) — Vault deep-dive
- [`08-Security/Kubernetes-Hardening.md`](../08-Security/Kubernetes-Hardening.md) — etcd encryption

---

> *"A secret in GitOps isn't a 'contradiction' — it's a **question of
> discipline**. Choose right, and Git stays the single source of
> truth while secrets flow from Vault; choose wrong, and you get
> plaintext in Git, manual `kubectl` runs, or **drift between two
> systems**."*

---

> 🎓 **Learning Path:** This document is used as the "Read first" resource in the [`D3`](../22-Learning-Path/block-d-orchestration/D3-secret-yonetimi.md) module.
