---
description: "Secrets management in production: comparison of the modern stack — Vault, ESO, SOPS and Sealed Secrets — for handling DB passwords, API keys and tokens, plus a decision tree."
tags:
  - Security
  - Secrets
  - Kubernetes
  - Compliance
---
# Secrets Management — Handling Secrets in Production

> *"A secret is anything that has entered Git history. Once it's in, it's
> there — deleting the commit doesn't delete the file, it **burns the secret**."*

DB password, API key, TLS private key, OAuth client secret, kubeconfig
token, S3 access key — all are secrets. This guide compares the modern
stack that handles them "the right way" and gives you a decision tree.

---

## 🎯 Threat Model

| Attacker profile | Scenario | What we shut down |
|---|---|---|
| **Casual leak** | New developer commits `.env` | gitleaks pre-commit + .gitignore |
| **History dive** | A departing employee pulls a token from old commits | Token rotation, BFG/git-filter-repo |
| **Compromised CI** | The CI runner gets taken over | OIDC, short-lived token |
| **Compromised pod** | RCE reads pod env vars | File mount tmpfs, no env |
| **Insider** | A broadly-privileged dev sees every secret | Per-team Vault namespace, audit |
| **Cloud provider compromise** | Attacker breaches the KMS provider | Encryption-at-rest + envelope encryption + per-region key |

> 🔑 **Minimum principle:** No secret should enter Git in clear text. No secret
> should be long-lived. No person should see a secret they don't need.

---

## 🪜 Maturity Levels

| Level | State | Risk |
|---|---|---|
| **L0** | `.env` in Git | Catastrophic — secret lives in commit history |
| **L1** | `.env` in `.gitignore`, shared over Slack | High — no audit trail on sharing |
| **L2** | Secret manager (Bitwarden/1Password) within the team | Medium — app still pulls via env var |
| **L3** | Vault / Cloud Secrets Manager + manual inject | Good — rotation is manual |
| **L4** | Vault + ESO + dynamic creds + audit log | **Target** — short-lived, auto-rotated |
| **L5** | L4 + zero-trust + workload identity (SPIFFE) | Advanced — multi-cluster, multi-cloud |

---

## 🔍 Solution Comparison

| Solution | Type | Best for | Limits |
|---|---|---|---|
| **HashiCorp Vault** | Self-hosted secret manager | Multi-cloud, on-prem, dynamic credentials | Operational overhead (HA, unseal, backup) |
| **AWS Secrets Manager** | Managed | Single-cloud AWS | Vendor lock-in, cross-region cost |
| **GCP Secret Manager** | Managed | Single-cloud GCP | Same |
| **Azure Key Vault** | Managed | Single-cloud Azure | Same |
| **External Secrets Operator (ESO)** | K8s controller | Mirrors the above into K8s | Not a backend itself |
| **SOPS (Mozilla)** | File encryption | Committing encrypted secrets in Git | Rotation manual, multi-recipient management is complex |
| **Sealed Secrets (Bitnami)** | K8s controller | GitOps + cluster-scoped encryption | K8s only, key compromise → all secrets must be rotated |
| **AWS SSM Parameter Store** | Managed (basic) | Simple config + secret, cheap | No rotation, weak version history |
| **Doppler / Infisical** | SaaS | Startup speed, multi-env UI | SaaS lock-in, requires compliance review |

---

## 🌳 Decision Tree

```
START
  │
  ├── Are you using K8s?
  │     │
  │     ├── YES → ESO + (Vault | AWS SM | GCP SM | Azure KV)
  │     │           └── Is GitOps mandatory?
  │     │                 └── YES → SOPS for *configmap*, ESO for *secret*
  │     │
  │     └── NO → CI/CD + cloud-native secret manager
  │
  ├── Any multi-cloud / on-prem?
  │     │
  │     └── YES → Vault (self-hosted instead of managed, single API)
  │
  ├── Do you need compliance (SOC2, ISO27001, KVKK)?
  │     │
  │     └── YES → Vault Enterprise or cloud-native + audit log shipping
  │
  └── Zero budget, small team?
        │
        └── YES → SOPS + age key + cloud KMS (free tiers)
```

---

## 🛠️ HashiCorp Vault Setup (Production-Grade)

### Architecture
```
                ┌──────────────────────────────────────┐
                │          Vault HA Cluster            │
                │   (3 node, Raft storage backend)     │
                │   Auto-unseal: AWS KMS / GCP KMS     │
                │   TLS internal + external            │
                └──┬───────────────┬──────────────┬────┘
                   │               │              │
              ┌────▼────┐    ┌─────▼────┐   ┌────▼────┐
              │  ESO    │    │  CI/CD   │   │  Apps   │
              │  K8s    │    │  GitHub  │   │  AppRole│
              │  auth   │    │  OIDC    │   │  / JWT  │
              └─────────┘    └──────────┘   └─────────┘
```

### Helm install (production values)
```yaml
# vault-values.yaml
server:
  ha:
    enabled: true
    replicas: 3
    raft:
      enabled: true
      setNodeId: true
      config: |
        ui = true
        listener "tcp" {
          tls_disable = 0
          tls_cert_file = "/vault/userconfig/vault-tls/tls.crt"
          tls_key_file  = "/vault/userconfig/vault-tls/tls.key"
        }
        storage "raft" {
          path = "/vault/data"
          retry_join {
            leader_api_addr = "https://vault-0.vault-internal:8200"
          }
        }
        seal "awskms" {
          region     = "<AWS_REGION>"
          kms_key_id = "<KMS_KEY_ID>"
        }

  resources:
    requests: {cpu: 250m, memory: 256Mi}
    limits: {cpu: 1000m, memory: 1Gi}

  auditStorage:
    enabled: true
    size: 10Gi
```

```bash
helm install vault hashicorp/vault \
  --namespace vault --create-namespace \
  -f vault-values.yaml --version <CHART_VERSION>
```

### First init + unseal
```bash
# Init (only once!)
kubectl exec -n vault vault-0 -- vault operator init \
  -key-shares=5 -key-threshold=3 -format=json > vault-init.json

# If you're doing auto-unseal with AWS KMS, unseal is already automatic;
# if there's no managed KMS (lab env):
kubectl exec -n vault vault-0 -- vault operator unseal <KEY_1>
kubectl exec -n vault vault-0 -- vault operator unseal <KEY_2>
kubectl exec -n vault vault-0 -- vault operator unseal <KEY_3>

# vault-init.json → VAULT: 5 unseal keys + root token.
# 5 keys → share with 5 different people. Root token → revoke as soon as possible.
```

> 🚨 `vault-init.json` MUST NOT enter Git. It must be shared across **5
> physical/AirGap vaults**. After using the root token, **revoke it** and
> create a separate admin policy for oncall.

### Audit log
```bash
vault audit enable file file_path=/vault/audit/audit.log
# or syslog → SIEM
vault audit enable syslog tag="vault" facility="AUTH"
```

---

## 🔑 Vault Secret Engines (most used)

### 1. KV v2 (static secret)
```bash
vault secrets enable -path=kv kv-v2

vault kv put kv/<APP>/db username=app password=<PWD>
vault kv get kv/<APP>/db
vault kv metadata get kv/<APP>/db   # version history
```

### 2. Database secret engine (dynamic credentials)
**The most powerful feature** — Vault creates a DB user on demand and deletes it at the end of the TTL.

```bash
vault secrets enable database

vault write database/config/postgres \
  plugin_name=postgresql-database-plugin \
  allowed_roles="readonly,readwrite" \
  connection_url="postgresql://{{username}}:{{password}}@<DB_HOST>:5432/<DB_NAME>" \
  username=<VAULT_DB_ADMIN> \
  password=<VAULT_DB_ADMIN_PWD>

vault write database/roles/readonly \
  db_name=postgres \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
                       GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" max_ttl="24h"

# App gets a credential with TTL=1h
vault read database/creds/readonly
```

### 3. PKI (TLS certs)
```bash
vault secrets enable -path=pki_int pki

vault write pki_int/issue/internal \
  common_name="<SERVICE>.<NAMESPACE>.svc.cluster.local" \
  ttl=72h
```

### 4. Transit (encryption-as-a-service)
The app **sends plaintext to Vault** and gets encrypted bytes back. The key never leaves Vault.

```bash
vault secrets enable transit
vault write -f transit/keys/<APP>-key

# Encrypt
echo -n "card-no-1234" | base64 | \
  vault write transit/encrypt/<APP>-key plaintext=-

# Decrypt
vault write transit/decrypt/<APP>-key ciphertext=<CIPHERTEXT>
```

> 🔑 **If you have PCI/PII** use transit or cloud KMS — the app never sees the
> key, and every decrypt call shows up in the audit log.

---

## 🔐 External Secrets Operator (K8s)

Automatically produces a K8s `Secret` resource, sourced from Vault/AWS SM etc.

### Setup
```bash
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace
```

### Vault auth: Kubernetes auth method
```bash
# Enable in Vault
vault auth enable kubernetes

vault write auth/kubernetes/config \
  kubernetes_host="https://<K8S_API>" \
  token_reviewer_jwt="$(kubectl get secret <SA_TOKEN> -o jsonpath='{.data.token}' | base64 -d)" \
  kubernetes_ca_cert=@/path/to/ca.crt

# Policy: <APP> can only read its own path
vault policy write <APP>-read - <<EOF
path "kv/data/<APP>/*" { capabilities = ["read"] }
EOF

# Role: K8s SA "<APP>-sa" → <APP>-read policy
vault write auth/kubernetes/role/<APP> \
  bound_service_account_names="<APP>-sa" \
  bound_service_account_namespaces="<NAMESPACE>" \
  policies="<APP>-read" \
  ttl="1h"
```

### ClusterSecretStore + ExternalSecret
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault
spec:
  provider:
    vault:
      server: "https://vault.<DOMAIN>:8200"
      path: "kv"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "<APP>"
          serviceAccountRef:
            name: "<APP>-sa"
            namespace: "<NAMESPACE>"
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: <APP>-db
  namespace: <NAMESPACE>
spec:
  refreshInterval: "1h"
  secretStoreRef:
    name: vault
    kind: ClusterSecretStore
  target:
    name: <APP>-db    # this K8s secret is created
    template:
      type: Opaque
      data:
        DATABASE_URL: "postgresql://{{ .username }}:{{ .password }}@<DB_HOST>:5432/<DB>"
  data:
    - secretKey: username
      remoteRef:
        key: <APP>/db
        property: username
    - secretKey: password
      remoteRef:
        key: <APP>/db
        property: password
```

> 🔑 The secret is pulled from Vault once an hour. If you rotate it in Vault,
> the K8s secret updates too. Restart the pod: `reloader` annotation or the
> `Stakater Reloader` controller.

---

## 📦 SOPS — Encrypted Commit in Git

If you're doing GitOps, ConfigMap/Secret manifests have to live in Git but
must not be clear-text. SOPS solves this.

### Setup
```bash
brew install sops age
age-keygen -o key.txt
# put the public key into .sops.yaml
```

### .sops.yaml
```yaml
creation_rules:
  - path_regex: \.(yaml|yml)$
    encrypted_regex: '^(data|stringData)$'   # ONLY the secret section is encrypted
    age: |
      age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p,
      age1...
```

### Create an encrypted secret
```bash
cat > db-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: db
  namespace: <NAMESPACE>
type: Opaque
stringData:
  username: app
  password: <PWD>
EOF

sops -e -i db-secret.yaml
git add db-secret.yaml   # encrypted — safe to commit
```

### Decrypt in the cluster: helm-secrets or FluxCD SOPS support
- ArgoCD: `argocd-vault-plugin` or the `helm-secrets` plugin
- Flux: `decryption.provider: sops` native support

> ⚠️ **SOPS limitation:** the age private key has to live somewhere. Usually
> you put it in Vault and pull it in CI → using SOPS **together** with Vault is the most robust flow.

---

## 🌱 Sealed Secrets (Bitnami)

K8s-specific; the controller decrypts with a cluster-scoped public key.

```bash
# Encrypt
kubectl create secret generic db --dry-run=client \
  --from-literal=password=<PWD> -o yaml | \
  kubeseal --controller-namespace=kube-system -o yaml > db-sealed.yaml

git add db-sealed.yaml   # safe
```

| ✅ | ❌ |
|---|---|
| Fast setup | Single key, disaster if lost |
| GitOps friendly | For multi-cluster, a separate key per cluster |
| Clean on the operator side | Rotation is complex (rotating the controller key → every secret must be re-sealed) |

---

## 🔐 Secret Management in CI/CD

### GitHub Actions: cloud auth via OIDC (NO long-lived key)
```yaml
permissions:
  id-token: write   # required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@<VERSION>
        with:
          role-to-assume: arn:aws:iam::<ACCOUNT>:role/<ROLE>
          aws-region: <REGION>
      # NO access-key-id / secret-access-key
```

```yaml
# AWS IAM trust relationship
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Federated": "arn:aws:iam::<ACCOUNT>:oidc-provider/token.actions.githubusercontent.com"},
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {"token.actions.githubusercontent.com:aud": "sts.amazonaws.com"},
      "StringLike": {"token.actions.githubusercontent.com:sub": "repo:<ORG>/<REPO>:ref:refs/heads/main"}
    }
  }]
}
```

### GitLab CI: ID token
```yaml
deploy:
  id_tokens:
    AWS_TOKEN:
      aud: https://gitlab.example.com
  script:
    - aws sts assume-role-with-web-identity ...
```

---

## 🧹 When a Secret Leaks (Incident Playbook)

> ⏱️ **The clock is running.** Once a leak is understood, seconds matter.

### 1. Rotate — IMMEDIATELY
- DB password → set a new password, revoke the old one
- API key → revoke + reissue
- TLS private key → new cert, revoke the old cert (CRL/OCSP)
- IAM access key → deactivate + delete

### 2. Audit — who, when, what did they do?
- CloudTrail / Cloud audit logs
- Vault audit log
- Database audit (postgres `pg_stat_activity`)

### 3. Git history cleanup (surface operation, not root cause)
```bash
# git-filter-repo (recommended)
pip install git-filter-repo
git filter-repo --path <FILE> --invert-paths

# or BFG
bfg --delete-files <FILE>

# force-push to remote
git push --force --all
git push --force --tags
```

> ⚠️ **Important:** Deleting the secret from Git alone is **not enough**. Assume
> the attacker already copied it. **Rotation > git history cleanup.** But clean
> the history anyway so a new person can't reuse it.

### 4. Root cause + postmortem
- Why did the pre-commit hook miss it?
- Why wasn't it in the secret manager?
- Is developer training needed?
- See [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md)

---

## 🔍 Detection — How Do You Know There's a Leak?

### Pre-commit (gitleaks)
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: <VERSION>
    hooks:
      - id: gitleaks
```

### CI scan
```yaml
- name: Gitleaks scan
  uses: gitleaks/gitleaks-action@<VERSION>
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### GitHub Secret Scanning (free, open to public repos)
- Settings → Code security → Secret scanning
- Push protection: rejects a commit containing a secret

### Cloud-native scanning
- AWS Macie (scans S3 buckets for PII/secrets)
- Google DLP, Azure Purview

### Vault audit anomaly
```bash
# 100x normal reads in 24 hours → anomaly
in the vault audit log:
  "request.operation":"read"
  "auth.policies":["<APP>-read"]
  count > <THRESHOLD>
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| `.env` in Git | Commit history forever | `.gitignore` + `.env.example` |
| Secret as an env var into the pod | Shows up in `ps`, crash dumps, error logs | File mount tmpfs |
| A single `cluster-admin` token across all of CI | Compromise → cluster down | OIDC + namespace-scoped |
| Vault root token in the app | Attacker reads every secret | AppRole / K8s auth + minimal policy |
| Secret never rotated | "Let's not change it before something breaks" | Quarterly rotation, dynamic creds |
| Prod secret in the test environment | Leak in test → prod compromise | Per-env secret, never shared |
| Sharing secrets over Slack/email | Stays in logs | 1Password share, expiring link |
| Direct access to Vault from the internet | Brute force / DDoS | Private network + bastion |
| No backup of the Sealed Secrets controller key | If the cluster dies, every secret is garbage | Off-cluster encrypted backup |
| No dynamic creds, static 6-month password | 6-month compromise window | TTL=1h dynamic creds |
| **No** `git secrets` or gitleaks | New developer commits a secret | Pre-commit + CI scan mandatory |

---

## 📋 Minimum Hygiene Checklist

```
[ ] .gitignore: .env, *.pem, *.key, *credentials*
[ ] gitleaks pre-commit hook on every developer machine
[ ] gitleaks/trufflehog runs on every PR in CI
[ ] No secret in Git history (you scanned retroactively)
[ ] GitHub Secret Scanning + Push Protection enabled
[ ] Production secrets in Vault/cloud SM, no plaintext in K8s Secret
[ ] etcd encryption-at-rest enabled (KMS provider)
[ ] Injected into apps via ESO or equivalent
[ ] DB credentials are dynamic (Vault DB engine or cloud IAM)
[ ] CI/CD: OIDC, no long-lived cloud key anywhere
[ ] Vault audit log → shipped to SIEM
[ ] Secret rotation policy written down + on the calendar
[ ] Incident playbook exists, team ran a drill
[ ] Transit encryption in PCI/PII areas (Vault Transit or KMS envelope)
[ ] Insider threat: per-team Vault namespace, no cross access
```

---

## 📚 References

- **HashiCorp Vault Documentation** — vaultproject.io/docs
- **External Secrets Operator** — external-secrets.io
- **SOPS + age** — github.com/getsops/sops
- **OWASP Secrets Management Cheat Sheet** — cheatsheetseries.owasp.org
- [`Kubernetes-Hardening.md`](Kubernetes-Hardening.md) — etcd encryption + RBAC section
- [`DevSecOps-Pipeline.md`](DevSecOps-Pipeline.md) — pre-commit + CI scan section
- [`19-Compliance/`](../19-Compliance/) (Phase 4) — KVKK (Turkey's Personal Data Protection Law, No. 6698) / GDPR secret-retention obligations

---

> *"The security of a secret is a product of **discipline**, not technology. The
> best Vault setup won't work with a culture that hasn't made 'don't commit
> secrets' a reflex for the team."*

---

> 🎓 **Learning Path:** This document is used as a "read first" resource in the [`D3`](../22-Learning-Path/block-d-orchestration/D3-secret-yonetimi.md) module.
