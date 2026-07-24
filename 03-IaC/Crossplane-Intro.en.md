---
description: "Guide to managing cloud resources as K8s CRDs with Crossplane: continuous reconciliation, how it differs from Terraform, the Composition pattern, and GitOps-native workflows."
tags:
  - IaC
  - Kubernetes
  - GitOps
  - Platform Engineering
---
# Crossplane — Manage Cloud Resources via the K8s API

> *"Not Terraform's imperative `apply` loop, but K8s's **continuous
> reconciliation**. Manage cloud resources as K8s CRDs — drift is
> auto-fixed, GitOps native."*

This guide covers Crossplane's core concepts, how it differs from
Terraform, when to choose it, and the **Composition** pattern.

---

## 🎯 What Is Crossplane?

> **Crossplane**: built on top of the K8s control plane, it **manages
> cloud resources as CRDs**. RDS, S3, IAM, Lambda, Pub/Sub — all as K8s
> manifests.

```
[Git: K8s manifest]
       │
       ▼
[ArgoCD / Flux sync]
       │
       ▼
[K8s API: Crossplane CRDs]
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
[Drift is corrected, healing]
```

---

## 🆚 Crossplane vs Terraform

| Dimension | Terraform | Crossplane |
|---|---|---|
| **Mental model** | Imperative apply | K8s reconcile loop |
| **State** | tfstate (S3) | K8s API (etcd) |
| **Drift** | See diffs with `terraform plan` | Continuous reconciliation (heal) |
| **GitOps** | Workaround (Atlantis, Spacelift) | Native (sync with ArgoCD/Flux) |
| **Resource model** | HCL DSL | K8s YAML |
| **Multi-cloud** | ✅ | ✅ |
| **Provider** | 3000+ | ~150 (official) + community |
| **Compose abstraction** | Module | Composition (CRD-based) |
| **Self-service** | Via Atlantis | Native (developers write K8s manifests) |
| **Maturity** | Established | CNCF Incubating, maturing |

---

## 🌳 Decision Tree

```
START
  │
  ├── Is the K8s ecosystem at the center?
  │     │
  │     └── YES → Crossplane is a strong candidate
  │
  ├── Is GitOps-native + drift heal critical?
  │     │
  │     └── YES → Crossplane (continuous reconcile)
  │
  ├── Self-service (developers spin up their own RDS via a K8s manifest)?
  │     │
  │     └── YES → Crossplane + Composition
  │
  ├── Broad provider set (3000+) or a niche resource?
  │     │
  │     └── Terraform/OpenTofu (provider variety)
  │
  └── Default → Terraform/OpenTofu (established)
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

### Create an S3 bucket
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
# Crossplane calls the AWS API and creates the bucket
# kubectl get buckets → Status: Ready
```

---

## 🧱 Composition — Self-Service Abstraction

> **Scenario**: A developer wants "Postgres + S3 + IAM role for a new service." Let them declare it in a **single YAML**.

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

### The developer uses it
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

→ One YAML, and Crossplane provisions RDS + S3 + IAM all together.

> 🔑 **This is gold for an Internal Developer Platform (IDP)**. It pairs with the Backstage scaffolder.

---

## 🔄 GitOps Flow

```
[Dev] → PR (AppStack manifest in the k8s-config repo)
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

> 🔑 No manual `terraform apply`. Drift heals automatically.

---

## 🛡️ Production Concerns

### 1. Secret management
- Crossplane exposes secrets via ConfigSecretToConnectionDetails
- Pull secrets from Vault with ESO

### 2. RBAC
- Provider service accounts are not cluster-admin
- Per-team RBAC (who can create which resource)

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

→ Multi-cloud orchestration in the same cluster.

### 4. Backup
- K8s etcd backup (Crossplane resource state lives here)
- Cloud-side backup for cloud resources (RDS snapshot, etc.)

---

## 🚧 Trade-offs

### Crossplane Pro
- ✅ K8s-native, GitOps friendly
- ✅ Continuous reconciliation
- ✅ Self-service abstraction (Composition)
- ✅ Multi-cloud single API
- ✅ Automatic drift heal

### Crossplane Con
- ❌ Fewer providers than Terraform
- ❌ Steep learning curve for Compose
- ❌ The K8s control plane fills up with Crossplane (etcd grows)
- ❌ Some resources are missing from the provider
- ❌ Debugging is harder than Terraform

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Think of Crossplane as a Terraform replacement | Different use case | Self-service + GitOps niche |
| One provider for every resource | Missing provider = surprise | Check the resource list |
| Over-abstracting with Composition | Hard to debug | Pragmatic level |
| Thousands of Crossplane resources in K8s etcd | etcd chokes | Multi-cluster or selective |
| Provider credentials as cluster-admin | Compromise blast | Per-provider IAM, least privilege |
| Unversioned Composition | Breaking change | XRD versioning |
| Manual kubectl apply | Drift | GitOps + ArgoCD |
| Crossplane + Terraform on the same resource | Race + drift | Clear boundary |

---

## 📋 Crossplane Adoption Checklist

```
[ ] Provider choice: AWS / GCP / Azure / all
[ ] Provider auth: IRSA / Workload Identity (no static keys)
[ ] Composition: at least 1 self-service abstraction
[ ] XRD: stable developer-facing API
[ ] GitOps: sync with ArgoCD / Flux
[ ] RBAC: per-team
[ ] Secret: ESO + Vault integration
[ ] Backup: K8s etcd + cloud resource snapshot
[ ] Monitoring: Crossplane controller metrics
[ ] Quarterly: provider version upgrade
[ ] Documentation: developer guide "how to open an AppStack"
[ ] Backstage integration (if any)
```

---

## 📚 References

- **Crossplane** — crossplane.io
- **Upbound** — upbound.io (commercial Crossplane)
- **CNCF Incubating** — cncf.io
- **Crossplane Compositions** — docs.crossplane.io/latest/concepts/compositions/
- [`Terraform-Best-Practices.md`](Terraform-Best-Practices.md)
- [`OpenTofu-Migration.md`](OpenTofu-Migration.md)
- [`Pulumi-vs-Terraform.md`](Pulumi-vs-Terraform.md)
- [`13-Platform-Engineering/Internal-Developer-Platform.md`](../13-Platform-Engineering/Internal-Developer-Platform.md)
- [`13-Platform-Engineering/Golden-Paths.md`](../13-Platform-Engineering/Golden-Paths.md)

---

> *"Crossplane isn't a 'Terraform replacement' — it's **K8s-native IaC**.
> When GitOps + self-service + drift-heal are critical, Crossplane is very
> strong; for generic IaC, Terraform/OpenTofu is still king."*
