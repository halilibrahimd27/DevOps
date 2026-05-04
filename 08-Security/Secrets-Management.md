# Secrets Management — Production'da Sır Yönetimi

> *"Sır, Git history'ye giren her şeydir. Bir kez girdi mi, oradadır —
> commit'i silmek dosyayı silmez, **sırrı yakar**."*

DB parolası, API key, TLS private key, OAuth client secret, kubeconfig
token, S3 access key — hepsi sırdır. Bu rehber bunları "doğru" yöneten
modern stack'i karşılaştırır ve karar ağacı verir.

---

## 🎯 Tehdit Modeli

| Saldırgan profili | Senaryo | Ne kapatırız |
|---|---|---|
| **Casual leak** | Yeni geliştirici `.env`'i commit'liyor | gitleaks pre-commit + .gitignore |
| **History dive** | İşten ayrılan kişi eski commit'lerden token alıyor | Token rotation, BFG/git-filter-repo |
| **Compromised CI** | CI runner'ı ele geçiriliyor | OIDC, short-lived token |
| **Compromised pod** | RCE pod env var'larını okuyor | File mount tmpfs, no env |
| **Insider** | Geniş yetkili dev tüm sırları görüyor | Per-team Vault namespace, audit |
| **Cloud provider compromise** | Saldırgan KMS provider'a sızıyor | Encryption-at-rest + envelope encryption + per-region key |

> 🔑 **Asgari prensip:** Hiçbir sır clear-text Git'e girmemeli. Hiçbir sır
> uzun-ömürlü olmamalı. Hiçbir kişi ihtiyaç duymadığı sırrı görmemeli.

---

## 🪜 Olgunluk Seviyeleri

| Level | Durum | Risk |
|---|---|---|
| **L0** | `.env` Git'te | Catastrophic — commit history'de sır var |
| **L1** | `.env` `.gitignore`'da, paylaşımlar Slack'te | Yüksek — paylaşım denetimi yok |
| **L2** | Secret manager (Bitwarden/1Password) ekip içi | Orta — uygulama hâlâ env var ile alıyor |
| **L3** | Vault / Cloud Secrets Manager + manuel inject | İyi — rotation manuel |
| **L4** | Vault + ESO + dynamic creds + audit log | **Hedef** — short-lived, otomatik rotate |
| **L5** | L4 + zero-trust + workload identity (SPIFFE) | İleri — multi-cluster, multi-cloud |

---

## 🔍 Çözüm Karşılaştırması

| Çözüm | Tip | Best for | Sınırlar |
|---|---|---|---|
| **HashiCorp Vault** | Self-hosted secret manager | Multi-cloud, on-prem, dynamic credentials | Operasyon yükü (HA, unseal, backup) |
| **AWS Secrets Manager** | Managed | Tek-cloud AWS | Vendor lock-in, cross-region maliyet |
| **GCP Secret Manager** | Managed | Tek-cloud GCP | Aynı |
| **Azure Key Vault** | Managed | Tek-cloud Azure | Aynı |
| **External Secrets Operator (ESO)** | K8s controller | Yukarıdakileri K8s'e yansıtır | Kendisi backend değil |
| **SOPS (Mozilla)** | File encryption | Git'te şifreli secret commit | Rotation manuel, multi-recipient yönetimi karmaşık |
| **Sealed Secrets (Bitnami)** | K8s controller | GitOps + cluster-scoped şifreleme | Sadece K8s, key compromise → tüm secret döner |
| **AWS SSM Parameter Store** | Managed (basic) | Basit config + secret, ucuz | Rotation yok, version history zayıf |
| **Doppler / Infisical** | SaaS | Startup hızı, multi-env UI | SaaS lock-in, compliance gerektirir |

---

## 🌳 Karar Ağacı

```
START
  │
  ├── K8s kullanıyor musun?
  │     │
  │     ├── EVET → ESO + (Vault | AWS SM | GCP SM | Azure KV)
  │     │           └── GitOps zorunlu mu?
  │     │                 └── EVET → SOPS *configmap* için, ESO *secret* için
  │     │
  │     └── HAYIR → CI/CD + cloud-native secret manager
  │
  ├── Multi-cloud / on-prem var mı?
  │     │
  │     └── EVET → Vault (managed yerine self-hosted, tek API)
  │
  ├── Compliance (SOC2, ISO27001, KVKK) gerekiyor mu?
  │     │
  │     └── EVET → Vault Enterprise veya cloud-native + audit log shipping
  │
  └── Bütçe sıfır, küçük takım?
        │
        └── EVET → SOPS + age key + cloud KMS (ücretsiz katmanlar)
```

---

## 🛠️ HashiCorp Vault Kurulumu (Production-Grade)

### Mimari
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

### Helm install (production değerleri)
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

### İlk init + unseal
```bash
# Init (sadece bir kez!)
kubectl exec -n vault vault-0 -- vault operator init \
  -key-shares=5 -key-threshold=3 -format=json > vault-init.json

# Auto-unseal AWS KMS ile yapıyorsan zaten unseal otomatik;
# manuel KMS yoksa (lab env):
kubectl exec -n vault vault-0 -- vault operator unseal <KEY_1>
kubectl exec -n vault vault-0 -- vault operator unseal <KEY_2>
kubectl exec -n vault vault-0 -- vault operator unseal <KEY_3>

# vault-init.json → KASA: 5 unseal key + root token.
# 5 key → 5 farklı kişiye paylaş. Root token → en kısa sürede revoke.
```

> 🚨 `vault-init.json` Git'e GİRMEMELİ. **5 fiziksel/AirGap kasa**'ya
> paylaşılmalı. Root token'ı kullandıktan sonra **revoke et**, oncall için
> ayrı bir admin policy oluştur.

### Audit log
```bash
vault audit enable file file_path=/vault/audit/audit.log
# veya syslog → SIEM
vault audit enable syslog tag="vault" facility="AUTH"
```

---

## 🔑 Vault Secret Engines (en çok kullanılan)

### 1. KV v2 (statik secret)
```bash
vault secrets enable -path=kv kv-v2

vault kv put kv/<APP>/db username=app password=<PWD>
vault kv get kv/<APP>/db
vault kv metadata get kv/<APP>/db   # version history
```

### 2. Database secret engine (dynamic credentials)
**En güçlü feature** — Vault gerektiğinde DB user yaratır, TTL sonunda siler.

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

# Uygulama TTL=1h kullanıcı alır
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
Uygulama **plaintext'i Vault'a yollar**, encrypted bytes alır. Key Vault'tan çıkmaz.

```bash
vault secrets enable transit
vault write -f transit/keys/<APP>-key

# Encrypt
echo -n "kart-no-1234" | base64 | \
  vault write transit/encrypt/<APP>-key plaintext=-

# Decrypt
vault write transit/decrypt/<APP>-key ciphertext=<CIPHERTEXT>
```

> 🔑 **PCI/PII varsa** transit veya cloud KMS kullan — uygulama anahtarı asla
> görmez, audit'te her decrypt çağrısı görünür.

---

## 🔐 External Secrets Operator (K8s)

K8s `Secret` kaynağı'nı otomatik üretir, kaynak Vault/AWS SM vs.

### Kurulum
```bash
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace
```

### Vault auth: Kubernetes auth method
```bash
# Vault'ta enable
vault auth enable kubernetes

vault write auth/kubernetes/config \
  kubernetes_host="https://<K8S_API>" \
  token_reviewer_jwt="$(kubectl get secret <SA_TOKEN> -o jsonpath='{.data.token}' | base64 -d)" \
  kubernetes_ca_cert=@/path/to/ca.crt

# Policy: <APP> sadece kendi path'ini okuyabilir
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
    name: <APP>-db    # bu K8s secret oluşur
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

> 🔑 Secret 1 saatte bir Vault'tan çekilir. Vault'ta rotate edersen K8s
> secret de güncellenir. Pod yeniden başlat: `reloader` annotation veya
> `Stakater Reloader` controller.

---

## 📦 SOPS — Git'te Şifreli Commit

GitOps yapıyorsan ConfigMap/Secret manifest'leri Git'te olmalı ama
clear-text olmamalı. SOPS bunu çözer.

### Kurulum
```bash
brew install sops age
age-keygen -o key.txt
# public key'i .sops.yaml'a koy
```

### .sops.yaml
```yaml
creation_rules:
  - path_regex: \.(yaml|yml)$
    encrypted_regex: '^(data|stringData)$'   # SADECE secret bölümü şifreli
    age: |
      age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p,
      age1...
```

### Şifreli secret oluştur
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
git add db-secret.yaml   # şifreli — güvenli commit
```

### Cluster'da decrypt: helm-secrets veya FluxCD SOPS support
- ArgoCD: `argocd-vault-plugin` veya `helm-secrets` plugin
- Flux: `decryption.provider: sops` native destek

> ⚠️ **SOPS limit'i:** age private key bir yerlerde durmalı. Genelde
> Vault'a koyup CI'da çekersin → SOPS'la Vault'u **birlikte** kullanmak en sağlam akış.

---

## 🌱 Sealed Secrets (Bitnami)

K8s'e özel; controller cluster-scoped public key ile şifre çözer.

```bash
# Şifrele
kubectl create secret generic db --dry-run=client \
  --from-literal=password=<PWD> -o yaml | \
  kubeseal --controller-namespace=kube-system -o yaml > db-sealed.yaml

git add db-sealed.yaml   # güvenli
```

| ✅ | ❌ |
|---|---|
| Setup hızlı | Tek key, kaybedilirse felaket |
| GitOps friendly | Multi-cluster için her cluster ayrı key |
| Operatör tarafı temiz | Rotation karmaşık (controller key rotate → tüm secret yeniden seal) |

---

## 🔐 CI/CD'de Secret Yönetimi

### GitHub Actions: OIDC ile cloud auth (uzun-ömürlü key YOK)
```yaml
permissions:
  id-token: write   # OIDC için zorunlu
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@<VERSION>
        with:
          role-to-assume: arn:aws:iam::<ACCOUNT>:role/<ROLE>
          aws-region: <REGION>
      # access-key-id / secret-access-key YOK
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

## 🧹 Secret Sızıntısı Olduğunda (Incident Playbook)

> ⏱️ **Saat ileri.** Secret leaked anlaşıldığında saniyeler önemli.

### 1. Rotate — IMMEDIATELY
- DB password → yeni password set, eskisini revoke
- API key → revoke + reissue
- TLS private key → yeni cert, eski cert revoke (CRL/OCSP)
- IAM access key → deactivate + delete

### 2. Audit — kim, ne zaman, ne yaptı?
- CloudTrail / Cloud audit logs
- Vault audit log
- Database audit (postgres `pg_stat_activity`)

### 3. Git history temizliği (kabuk operasyon, kök neden değil)
```bash
# git-filter-repo (önerilen)
pip install git-filter-repo
git filter-repo --path <DOSYA> --invert-paths

# veya BFG
bfg --delete-files <DOSYA>

# remote'a force-push
git push --force --all
git push --force --tags
```

> ⚠️ **Önemli:** Sırrı sadece Git'ten silmek **yetmez**. Saldırgan zaten
> kopyaladı kabul et. **Rotation > git history temizliği.** Ama yine de
> history'yi temizle ki yeni biri tekrar kullanmasın.

### 4. Kök neden + postmortem
- Pre-commit hook neden kaçırdı?
- Secret manager'a niye konmamış?
- Geliştirici eğitimi ihtiyacı?
- Bkz [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md)

---

## 🔍 Detection — Sızıntı Olduğunu Nasıl Anlarsın?

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

### GitHub Secret Scanning (ücretsiz, public repo'lara açık)
- Settings → Code security → Secret scanning
- Push protection: secret içeren commit'i red eder

### Cloud-native scanning
- AWS Macie (S3 bucket'larda PII/secret tarama)
- Google DLP, Azure Purview

### Vault audit anomalisi
```bash
# 24 saatte 100x normal okuma → anomali
vault audit log içinde:
  "request.operation":"read"
  "auth.policies":["<APP>-read"]
  count > <THRESHOLD>
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| `.env` Git'te | Commit history sonsuza kadar | `.gitignore` + `.env.example` |
| Secret env var olarak pod'a | `ps`, crash dump, error log'da görünür | File mount tmpfs |
| Tek `cluster-admin` token tüm CI'da | Compromise → cluster down | OIDC + namespace-scoped |
| Vault root token uygulamada | Saldırgan tüm secret'ları okur | AppRole / K8s auth + minimal policy |
| Secret rotate edilmiyor | "Fail kapamadan değiştirmeyelim" | Quarterly rotation, dynamic creds |
| Test environment'ta prod secret | Test'te leak → prod compromise | Per-env secret, hiç paylaşma |
| Slack/email ile secret paylaşımı | Loglarda kalır | 1Password share, expiring link |
| Vault'a internet'ten direkt erişim | Brute force / DDoS | Private network + bastion |
| Sealed Secrets controller key backup yok | Cluster düşerse tüm secret çöp | Off-cluster encrypted backup |
| Dynamic creds yok, statik 6 aylık password | Compromise window 6 ay | TTL=1h dynamic creds |
| `git secrets` veya gitleaks **yok** | Yeni geliştirici secret commit'liyor | Pre-commit + CI scan zorunlu |

---

## 📋 Asgari Hijyen Checklist

```
[ ] .gitignore: .env, *.pem, *.key, *credentials*
[ ] gitleaks pre-commit hook tüm geliştirici makinelerinde
[ ] CI'da gitleaks/trufflehog her PR'da çalışıyor
[ ] Git history'de secret yok (geçmişe dönük taradın)
[ ] GitHub Secret Scanning + Push Protection açık
[ ] Production secret'lar Vault/cloud SM'de, K8s Secret'ta plaintext yok
[ ] etcd encryption-at-rest açık (KMS provider)
[ ] ESO veya equivalent ile uygulamalara inject ediliyor
[ ] DB credentials dynamic (Vault DB engine veya cloud IAM)
[ ] CI/CD: OIDC, hiçbir uzun-ömürlü cloud key yok
[ ] Vault audit log → SIEM'e ship ediliyor
[ ] Secret rotation policy yazılı + kalendere alınmış
[ ] Incident playbook'u var, ekip tatbikat yaptı
[ ] PCI/PII gerektiren alanlarda transit encryption (Vault Transit veya KMS envelope)
[ ] Insider threat: per-team Vault namespace, kross erişim yok
```

---

## 📚 Referanslar

- **HashiCorp Vault Documentation** — vaultproject.io/docs
- **External Secrets Operator** — external-secrets.io
- **SOPS + age** — github.com/getsops/sops
- **OWASP Secrets Management Cheat Sheet** — cheatsheetseries.owasp.org
- [`Kubernetes-Hardening.md`](Kubernetes-Hardening.md) — etcd encryption + RBAC kısmı
- [`DevSecOps-Pipeline.md`](DevSecOps-Pipeline.md) — pre-commit + CI scan kısmı
- [`19-Compliance/`](../19-Compliance/) (Faz 4) — KVKK/GDPR sırrı saklama yükümlülükleri

---

> *"Sırrın güvenliği teknolojinin değil **disiplinin** ürünüdür. En iyi
> Vault kurulumu, ekibin 'secret commit etmemeyi' refleks haline
> getirmeyen bir kültürle çalışmaz."*
