# Crossplane — K8s API ile Cloud Resource Yönet

> *"Terraform'un imperative `apply` döngüsü değil, K8s'in **continuous
> reconciliation**'ı. Cloud resource'ları K8s CRD olarak yönet —
> drift otomatik fix, GitOps native."*

Bu rehber Crossplane'in temel kavramlarını, Terraform'a göre farkını,
ne zaman tercih edileceğini, ve **Composition** pattern'ini anlatır.

---

## 🎯 Crossplane Nedir?

> **Crossplane**: K8s control plane üstüne kurulu, **cloud resource'ları
> CRD olarak yönetiriyor**. RDS, S3, IAM, Lambda, Pub/Sub — hepsi K8s
> manifest.

```
[Git: K8s manifest]
       │
       ▼
[ArgoCD / Flux sync]
       │
       ▼
[K8s API: Crossplane CRD'leri]
       │
       ├── Bucket (AWS S3)
       ├── RDSInstance (AWS RDS)
       ├── SQLInstance (GCP CloudSQL)
       └── StorageAccount (Azure)
       │
       ▼
[Crossplane Provider]
       │
       │ (cloud API call)
       ▼
[Cloud: actual resource]
       │
       │ (continuous reconcile)
       ▼
[Drift düzeltilir, healing]
```

---

## 🆚 Crossplane vs Terraform

| Boyut | Terraform | Crossplane |
|---|---|---|
| **Mental model** | Imperative apply | K8s reconcile loop |
| **State** | tfstate (S3) | K8s API (etcd) |
| **Drift** | `terraform plan` ile fark görür | Continuous reconciliation (heal) |
| **GitOps** | Workaround (Atlantis, Spacelift) | Native (ArgoCD/Flux ile sync) |
| **Resource model** | HCL DSL | K8s YAML |
| **Multi-cloud** | ✅ | ✅ |
| **Provider** | 3000+ | ~150 (resmi) + community |
| **Compose abstraction** | Module | Composition (CRD-based) |
| **Self-service** | Atlantis ile | Native (developer K8s manifest yazar) |
| **Maturity** | Köklü | CNCF Incubating, gelişiyor |

---

## 🌳 Karar Ağacı

```
START
  │
  ├── K8s ekosistemi merkezde mi?
  │     │
  │     └── EVET → Crossplane güçlü adayı
  │
  ├── GitOps native + drift heal kritik mi?
  │     │
  │     └── EVET → Crossplane (continuous reconcile)
  │
  ├── Self-service (developer kendi RDS'ini K8s manifest ile açsın)?
  │     │
  │     └── EVET → Crossplane + Composition
  │
  ├── Geniş provider (3000+) veya niche resource?
  │     │
  │     └── Terraform/OpenTofu (provider çeşitliliği)
  │
  └── Default → Terraform/OpenTofu (köklü)
```

---

## 🚀 Crossplane Quick Start

### Install
```bash
helm install crossplane crossplane/crossplane \
  -n crossplane-system --create-namespace
```

### Provider install
```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws
spec:
  package: xpkg.upbound.io/upbound/provider-aws-s3:v1.0.0
```

### Provider auth
```yaml
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-creds
      key: creds
```

### S3 bucket oluştur
```yaml
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: my-app-logs
spec:
  forProvider:
    region: eu-west-1
    versioningConfiguration:
      - status: Enabled
  providerConfigRef:
    name: default
```

```bash
kubectl apply -f bucket.yaml
# Crossplane AWS API'ye gider, bucket oluşturur
# kubectl get buckets → Status: Ready
```

---

## 🧱 Composition — Self-Service Abstraction

> **Senaryo**: Developer "yeni servis için Postgres + S3 + IAM role" istiyor. **Tek YAML**'da tanımlasın.

### CompositeResourceDefinition (XRD)
```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xappstacks.platform.example.com
spec:
  group: platform.example.com
  names:
    kind: XAppStack
    plural: xappstacks
  claimNames:
    kind: AppStack
    plural: appstacks
  versions:
    - name: v1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              required: [appName, environment]
              properties:
                appName: {type: string}
                environment: {type: string, enum: [dev, staging, prod]}
                dbStorageGB: {type: integer, default: 50}
```

### Composition (template)
```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: appstack-default
spec:
  compositeTypeRef:
    apiVersion: platform.example.com/v1
    kind: XAppStack
  resources:
    - name: rds
      base:
        apiVersion: rds.aws.upbound.io/v1beta1
        kind: Instance
        spec:
          forProvider:
            engine: postgres
            engineVersion: "16"
            instanceClass: db.t3.medium
      patches:
        - fromFieldPath: spec.appName
          toFieldPath: metadata.name
          transforms:
            - type: string
              string: {fmt: "%s-postgres"}
        - fromFieldPath: spec.dbStorageGB
          toFieldPath: spec.forProvider.allocatedStorage

    - name: s3
      base:
        apiVersion: s3.aws.upbound.io/v1beta1
        kind: Bucket
        spec:
          forProvider:
            region: eu-west-1
      patches:
        - fromFieldPath: spec.appName
          toFieldPath: metadata.name
          transforms:
            - type: string
              string: {fmt: "%s-storage"}
```

### Developer kullanır
```yaml
apiVersion: platform.example.com/v1
kind: AppStack
metadata:
  name: payments-prod
  namespace: payments
spec:
  appName: payments
  environment: prod
  dbStorageGB: 100
```

→ Tek YAML, Crossplane RDS + S3 + IAM hepsini provision eder.

> 🔑 **Bu, Internal Developer Platform (IDP) için altın**. Backstage scaffolder ile birleşir.

---

## 🔄 GitOps Akışı

```
[Dev] → PR (k8s-config repo'da AppStack manifest)
   │
   ▼
[Review + merge]
   │
   ▼
[ArgoCD sync]
   │
   ▼
[Crossplane reconcile]
   │
   ▼
[AWS / GCP / Azure resource]
   │
   ▼
[Drift detect → heal]
```

> 🔑 Manuel `terraform apply` yok. Drift otomatik düzelir.

---

## 🛡️ Production Concerns

### 1. Secret management
- Crossplane secret'i ConfigSecretToConnectionDetails ile expose eder
- ESO ile Vault'tan secret çek

### 2. RBAC
- Provider service account'ları cluster-admin değil
- Per-team RBAC (kim hangi resource yaratabilir)

### 3. Multi-cloud setup
```yaml
# AWS provider
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata: {name: aws}
spec:
  credentials: {...}

# GCP provider
apiVersion: gcp.upbound.io/v1beta1
kind: ProviderConfig
metadata: {name: gcp}
spec:
  credentials: {...}
```

→ Aynı cluster'da multi-cloud orchestration.

### 4. Backup
- K8s etcd backup (Crossplane resource state burada)
- Cloud resource'ları cloud-side backup (RDS snapshot, vb.)

---

## 🚧 Trade-off'lar

### Crossplane Pro
- ✅ K8s-native, GitOps friendly
- ✅ Continuous reconciliation
- ✅ Self-service abstraction (Composition)
- ✅ Multi-cloud single API
- ✅ Drift heal otomatik

### Crossplane Con
- ❌ Provider çeşitliliği Terraform'dan az
- ❌ Compose öğrenme eğrisi dik
- ❌ K8s control plane Crossplane'le doluyor (etcd büyür)
- ❌ Bazı resource'lar provider'da eksik
- ❌ Debugging Terraform'dan zor

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Crossplane'i Terraform replacement gibi düşün | Use case farklı | Self-service + GitOps niche |
| Provider tüm resource için | Eksik provider sürpriz | Resource list check |
| Composition aşırı abstraction | Debug zor | Pragmatik düzey |
| K8s etcd'ye binlerce Crossplane resource | etcd boğulur | Multi-cluster veya selective |
| Provider credentials cluster-admin | Compromise blast | Per-provider IAM, least priv |
| Composition versionsuz | Breaking change | XRD versioning |
| Manuel kubectl apply | Drift | GitOps + ArgoCD |
| Crossplane + Terraform aynı resource | Race + drift | Net sınır |

---

## 📋 Crossplane Adoption Checklist

```
[ ] Provider seçimi: AWS / GCP / Azure / hepsi
[ ] Provider auth: IRSA / Workload Identity (kein static key)
[ ] Composition: en az 1 self-service abstraction
[ ] XRD: developer-facing API stable
[ ] GitOps: ArgoCD / Flux ile sync
[ ] RBAC: per-team
[ ] Secret: ESO + Vault entegrasyonu
[ ] Backup: K8s etcd + cloud resource snapshot
[ ] Monitoring: Crossplane controller metrics
[ ] Quarterly: provider version upgrade
[ ] Documentation: developer "AppStack nasıl açılır" rehberi
[ ] Backstage entegrasyonu (varsa)
```

---

## 📚 Referanslar

- **Crossplane** — crossplane.io
- **Upbound** — upbound.io (Crossplane ticari)
- **CNCF Incubating** — cncf.io
- **Crossplane Compositions** — docs.crossplane.io/latest/concepts/compositions/
- [`Terraform-Best-Practices.md`](Terraform-Best-Practices.md)
- [`OpenTofu-Migration.md`](OpenTofu-Migration.md)
- [`Pulumi-vs-Terraform.md`](Pulumi-vs-Terraform.md)
- [`13-Platform-Engineering/Internal-Developer-Platform.md`](../13-Platform-Engineering/Internal-Developer-Platform.md)
- [`13-Platform-Engineering/Golden-Paths.md`](../13-Platform-Engineering/Golden-Paths.md)

---

> *"Crossplane 'Terraform replacement' değil — **K8s-native IaC**.
> GitOps + self-service + drift-heal kritikse, Crossplane çok güçlü;
> generic IaC için Terraform/OpenTofu hâlâ kraldır."*
