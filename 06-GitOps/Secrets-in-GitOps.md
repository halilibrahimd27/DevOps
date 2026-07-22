---
description: "GitOps'ta secret yönetimi: Sealed Secrets, SOPS, External Secrets Operator ve ArgoCD Vault Plugin karşılaştırması; Git'te şifreli, cluster'da çözük."
tags:
  - GitOps
  - Secrets
  - Security
  - Kubernetes
---
# Secrets in GitOps — Git'e Sır Koyabilir misin?

> *"GitOps 'her şey Git'te' der. Sırlar da. Ama **plaintext değil** —
> bu **hilenin** kuralı: Git'te şifreli + cluster'da çözük."*

Bu rehber GitOps akışında secret yönetiminin somut çözümlerini —
Sealed Secrets, SOPS, External Secrets Operator, ArgoCD Vault Plugin
— karşılaştırır ve hangi senaryoda hangisini seçmen gerektiğine net
cevap verir.

---

## 🎯 Sorun

GitOps'un ruhu: **cluster state = Git'tekinin kopyası**. Ama:
- DB password'u Git'te plaintext olamaz
- API key'i public repo'ya commit edilemez
- Vault token'ı history'de kalamaz

→ **Çözüm**: Git'te **şifreli**, cluster'da **çözük**.

---

## ⚖️ 4 Yaklaşım — Karşılaştırma

| Yaklaşım | Tip | GitOps fit | 2026 öneri |
|---|---|---|---|
| **Sealed Secrets** | K8s controller | ✅ Native | ✅ Küçük-orta |
| **SOPS + age/PGP** | File encryption | ✅ ArgoCD plugin / Flux native | ✅ Multi-recipient |
| **External Secrets Operator** | K8s operator + external store | ✅ Native | ✅ **Production önerisi** |
| **ArgoCD Vault Plugin** | ArgoCD plugin | ⚠️ ArgoCD-specific | ⚠️ Niche |

---

## 🌳 Karar Ağacı

```
START
  │
  ├── Backend secret manager var mı? (Vault, AWS SM, GCP SM, Azure KV)
  │     │
  │     ├── EVET → External Secrets Operator (ESO)
  │     │   - En güvenli + esnek
  │     │   - Backend zaten audit + rotation yapıyor
  │     │
  │     └── HAYIR → devam
  │
  ├── Multi-cluster + multi-recipient (DevOps + dev + CI all decrypt)?
  │     │
  │     └── EVET → SOPS + age (PGP modern alternatif)
  │            - Birden çok kişi/cluster decrypt edebilir
  │            - Git'te şifreli commit
  │
  ├── K8s-only, basit setup?
  │     │
  │     └── EVET → Sealed Secrets
  │            - Bitnami, popüler
  │            - Cluster public key ile kapsüllenir
  │
  └── ArgoCD-spesifik, basit ihtiyaç?
         │
         └── EVET → argocd-vault-plugin
               - Sadece ArgoCD render zamanında çağrı
```

---

## 🌱 Sealed Secrets

### Mimari
```
[Geliştirici] kubeseal --> [Şifreli SealedSecret YAML] --> Git
                                                            │
                                              [ArgoCD sync]
                                                            ▼
                                              [Cluster: SealedSecret]
                                                            │
                                              [Sealed-Secrets Controller]
                                              private key ile decrypt
                                                            ▼
                                              [Cluster: K8s Secret]
                                              (pod env / mount)
```

### Kurulum
```bash
helm install sealed-secrets sealed-secrets/sealed-secrets \
  -n kube-system

# CLI tool
brew install kubeseal
```

### Şifreleme
```bash
# 1. Plain Secret yaz (Git'e KOYMA!)
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

# 2. Şifrele (cluster public key ile)
kubeseal --format yaml \
  --controller-namespace=kube-system \
  --controller-name=sealed-secrets \
  < db-secret.yaml > db-sealed.yaml

# 3. Plain dosyayı SİL (Git'e girmesin)
rm db-secret.yaml
git add db-sealed.yaml   # şifreli, güvenli
```

### Cluster'da çözüm
- Sealed-Secrets controller `SealedSecret` görür
- Private key ile decrypt eder
- `Secret` resource oluşturur
- Pod normal env/mount kullanır

### ✅ Pro
- Setup hızlı
- Git'te tamamen otomatik
- Multi-namespace destek

### ❌ Con
- **Tek private key** — kaybedilirse felaket
- Multi-cluster için her cluster ayrı key (her secret yeniden seal)
- Key rotation karmaşık
- Cluster-bound (cluster sıfırlanırsa secret çöp)

> 🔑 **Backup zorunlu**: controller'ın private key'ini off-cluster yedekle (Vault, KMS, AirGap kasa).

---

## 🔐 SOPS + age — Multi-Recipient

### Mimari
```
[Geliştirici] sops -e         [Git: şifreli YAML]    [ArgoCD/Flux]
              age key  ─────▶     commit         ─────▶ decrypt + apply
                                                    age private key
```

### Kurulum
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
    encrypted_regex: '^(data|stringData)$'   # SADECE bu alanlar şifreli
    age: |
      age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p,
      age1prod_cluster_key,
      age1ci_pipeline_key
```

> 🔑 **Multi-recipient**: 3 farklı public key — 3 farklı taraf decrypt edebilir (geliştirici, prod cluster, CI). Birinin key'i compromise olursa diğerleri çalışmaya devam.

### Şifrele
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

# In-place encrypt (creation_rules uygulanır)
sops -e -i db-secret.yaml
git add db-secret.yaml   # data alanları şifreli
```

### Edit
```bash
sops db-secret.yaml   # editör'de plain açar, kaydetmesinde tekrar şifreler
```

### Flux ile kullanım (native)
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: payments
spec:
  decryption:
    provider: sops
    secretRef:
      name: sops-age   # private key burada
  path: ./apps/payments/overlays/prod
```

### ArgoCD ile (helm-secrets veya kustomize-with-sops plugin)
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
- Git'te diff okunabilir (sadece data field'ları şifreli)
- age modern, PGP'den hızlı
- Backup: age key Vault'ta dur

### ❌ Con
- Setup biraz teknik
- ArgoCD'de plugin gerekir
- Key dağıtımı disiplin

---

## 🎯 External Secrets Operator (ESO) — 2026 Önerisi

### Mimari
```
[Vault / AWS SM / GCP SM]
        ↑
        │ ESO controller
        │
[K8s ExternalSecret CR (Git'te)]  ─────▶  [K8s Secret (cluster'da)]
   "Vault'tan kv/<APP>/db oku"             pod env/mount
```

> 🔑 **Git'te SECRET YOK**. Sadece "Vault'taki secret'ı buraya getir" tarif var.

### Kurulum
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

### ExternalSecret (Git'te)
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
    name: payments-db        # bu K8s Secret oluşur
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

> Bu `ExternalSecret` Git'te commit edilebilir → **secret içermez**.
> Vault'a referans verir.

### ✅ Pro
- **Git'te plaintext yok, şifreli yok — sadece referans**
- Vault'taki secret rotation otomatik yansır
- Multi-cluster desteği (ClusterSecretStore)
- Audit log Vault'ta merkezi
- Dynamic credentials (Vault DB engine)

### ❌ Con
- Vault (veya equivalent) operasyonel yük
- Bootstrap problem: Vault auth için K8s SA → Vault token zinciri

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
# Manifest'te placeholder
apiVersion: v1
kind: Secret
metadata:
  name: db-creds
stringData:
  password: <path:kv/payments/db#password>   # ArgoCD render zamanında resolve
```

> ⚠️ ArgoCD-spesifik. Flux'a göç için yeniden yazmak gerekir.

---

## 🔄 Bootstrap Sorunu (Çözüm)

ESO Vault'a auth için K8s ServiceAccount token kullanır. Ama Vault bootstrap edilmemişse?

### Cold-start akışı
```
1. Cluster ayağa kalkar (boş)
2. Vault external (managed) → çalışıyor
3. Manuel: Vault K8s auth backend kur
4. ESO install (Helm)
5. ClusterSecretStore manifest apply (sadece config, no secret)
6. ExternalSecret'lar GitOps ile akmaya başlar
```

### Alternatif: AWS IAM / GCP Workload Identity
ESO **direkt cloud SM** ile konuşabilir → Vault yok, cloud-native:
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

→ K8s SA → IAM Role (IRSA) → AWS SM erişim. **Vault'suz multi-secret.**

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Plain Secret YAML Git'te | Sızıntı an meselesi | Sealed/SOPS/ESO |
| Sealed-Secrets controller key backup yok | Cluster döndüğünde tüm secret çöp | Off-cluster encrypted backup |
| Tek private key (SOPS + tek age key) | Compromise = total compromise | Multi-recipient |
| ESO refreshInterval `30s` | Vault DDoS | 1h+ refresh, push-based event'le mümkün |
| Dev / staging / prod aynı secret | Compromise yayılır | Per-env Vault path |
| Vault root token CI'da | Compromise = cluster sahibi | AppRole / K8s auth, minimal policy |
| Secret Git history'de plaintext (eski commit) | Geçmiş hâlâ tehdit | git-filter-repo + rotate |
| ESO ClusterSecretStore tüm namespace'lerden okunabilir | Cross-tenant | Namespaced SecretStore |
| Encryption key Git'te | "Şifreliyiz" iddiası saçma | Off-Git: KMS / 1Password / kasa |
| `kubeseal` plain Secret'i Git'e fark etmeden push | Yanlış stage | Pre-commit gitleaks |

---

## 📋 GitOps Secret Strategy Checklist

```
[ ] Yaklaşım seçildi (ADR/RFC ile gerekçeli)
[ ] Sealed-Secrets: controller key off-cluster backup
[ ] SOPS: age multi-recipient (dev + prod + CI)
[ ] ESO: Vault/cloud-native auth + per-namespace store
[ ] ExternalSecret refresh: 1h+ (DDoS önle)
[ ] Per-env secret separation (dev/staging/prod ayrı)
[ ] gitleaks pre-commit hook
[ ] CI secret scan (gitleaks-action)
[ ] Git history secret-free (geçmiş tarandı)
[ ] Secret rotation otomatik (Vault DB engine ya da scheduled)
[ ] Audit log → SIEM (Vault audit veya cloud audit)
[ ] DR plan: secret manager down → cluster ne olur?
[ ] Documentation: yeni secret nasıl eklenir
[ ] Quarterly: secret usage review (ölü secret'lar?)
```

---

## 📚 Referanslar

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

> *"GitOps'ta secret 'çelişki' değil — **disiplin sorusu**. Doğru
> seçilirse Git tek kaynak olur, secret'lar Vault'tan akar; yanlış
> seçilirse ya Git'te plaintext, ya manuel kubectl, ya da **iki
> sistem arasında drift**."*

---

> 🎓 **Öğrenme Patikası:** Bu doküman [`D3`](../22-Learning-Path/block-d-orchestration/D3-secret-yonetimi.md) modülünde "Önce oku" kaynağı olarak kullanılıyor.
