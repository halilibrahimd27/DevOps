---
description: "Kyverno policy-as-code şablonları: :latest tag reddi, cosign imza doğrulama (supply chain) ve zorunlu label (cost/ownership) enforcement."
tags:
  - Template
  - Kubernetes
  - Security
  - Policy as Code
---
# Kyverno Policy Şablonları

> Admission-time enforcement: kural cluster'a girişte uygulanır, sonradan
> denetimle değil. Üçü de `validationFailureAction: Enforce` ile reddeder.
> `Audit`'e çevirerek önce gözlemle, sonra zorla. Placeholder'lar `<UPPER_CASE>` ile.
> Bu sayfa komşu dosyaların gömülü halidir; kaynak dosyalar aynı klasörde.

## Dosyalar

| Dosya | Ne zorlar | Kategori |
|---|---|---|
| [`disallow-latest-tag.yaml`](disallow-latest-tag.yaml) | `:latest` yasak, tag zorunlu | Best Practices |
| [`require-image-signature.yaml`](require-image-signature.yaml) | Sadece cosign-imzalı imaj | Supply Chain |
| [`require-labels.yaml`](require-labels.yaml) | Standart label (cost/ownership) | Best Practices |

Policy-as-code derinliği: [`08-Security/`](../../08-Security/README.md).

### 1️⃣ `disallow-latest-tag.yaml`

`:latest` prod'da rollback'i imkânsızlaştırır (hangi imaj çalışıyor belirsiz).

```yaml
# Kyverno policy — `:latest` tag'li imajları reddet
# Production'da rollback'i imkansızlaştırır; immutable tag zorunlu.

apiVersion: kyverno.io/v2beta1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
  annotations:
    policies.kyverno.io/title: Disallow Latest Tag
    policies.kyverno.io/category: Best Practices
    policies.kyverno.io/severity: medium
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: validate-tag
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "`:latest` tag prod'da yasak. Semantic version (`v1.2.3`) veya SHA digest (`@sha256:...`) kullanın."
        pattern:
          spec:
            containers:
              - image: "!*:latest"

    - name: validate-tag-exists
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Imaj tag'siz olamaz (Docker default'ı `:latest` olur)."
        pattern:
          spec:
            containers:
              - image: "*:*"
```

### 2️⃣ `require-image-signature.yaml` — supply chain gate

CI'da imzaladığın (`docker-build-push.yml` → cosign keyless) imajı, cluster girişinde doğrular. Supply-chain iplisinin admission ucu.

```yaml
# Kyverno policy — sadece imzalı imajların deploy edilmesine izin ver
# Cosign keyless OIDC ile imzalanmış imajları doğrular.
#
# Kurulum: https://kyverno.io
#
# Test:
#   kubectl run pod-test --image=ghcr.io/<ORG>/<IMAGE>:<TAG>
#   (imzasızsa: admission webhook reject)

apiVersion: kyverno.io/v2beta1
kind: ClusterPolicy
metadata:
  name: verify-image-signature
  annotations:
    policies.kyverno.io/title: Verify Image Signature
    policies.kyverno.io/category: Supply Chain Security
    policies.kyverno.io/severity: high
    policies.kyverno.io/description: >-
      Cluster'a sadece güvenilir registry'lerden gelen ve cosign ile imzalanmış
      imajların deploy edilmesine izin verir.
spec:
  validationFailureAction: Enforce       # Audit veya Enforce
  background: false
  webhookTimeoutSeconds: 30
  failurePolicy: Fail
  rules:
    - name: verify-signature
      match:
        any:
          - resources:
              kinds:
                - Pod
      # Bypass: belirli sistem namespace'leri (örnek)
      exclude:
        any:
          - resources:
              namespaces:
                - kube-system
                - kyverno
                - cert-manager
      verifyImages:
        - imageReferences:
            - "ghcr.io/<ORG>/*"
            - "<REGISTRY>/<ORG>/*"
          attestors:
            - entries:
                - keyless:
                    subject: "https://github.com/<ORG>/*"
                    issuer: "https://token.actions.githubusercontent.com"
                    rekor:
                      url: https://rekor.sigstore.dev
          # Mutate (digest pin) — imaj tag'i SHA digest'e çevirir
          mutateDigest: true
          required: true
```

### 3️⃣ `require-labels.yaml` — cost + ownership

Sahipsiz workload maliyet dağıtımını ve incident'te "kimi arayacağım"ı imkânsızlaştırır.

```yaml
# Kyverno policy — zorunlu label kontrolü (cost allocation, ownership için)
# Her workload mutlaka şu label'lara sahip olmalı:
#   - app.kubernetes.io/name
#   - app.kubernetes.io/managed-by
#   - team
#   - cost-center

apiVersion: kyverno.io/v2beta1
kind: ClusterPolicy
metadata:
  name: require-standard-labels
  annotations:
    policies.kyverno.io/title: Require Standard Labels
    policies.kyverno.io/category: Best Practices
    policies.kyverno.io/severity: medium
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-labels
      match:
        any:
          - resources:
              kinds:
                - Deployment
                - StatefulSet
                - DaemonSet
                - Job
                - CronJob
      exclude:
        any:
          - resources:
              namespaces:
                - kube-system
                - kube-public
                - kube-node-lease
      validate:
        message: |
          Tüm workload'lar şu label'lara sahip olmalı:
          - app.kubernetes.io/name
          - app.kubernetes.io/managed-by  (terraform | helm | argocd | flux)
          - team                          (örn: payments, growth, platform)
          - cost-center                   (örn: eng-1234)
        pattern:
          metadata:
            labels:
              app.kubernetes.io/name: "?*"
              app.kubernetes.io/managed-by: "?*"
              team: "?*"
              cost-center: "?*"
```

---

## 🚫 Anti-Pattern

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Gün 1'den `Enforce` | Mevcut workload'lar reddedilir, ekip policy'yi kapatır | Önce `Audit`, ihlalleri gör, sonra `Enforce` |
| İmza doğrulaması yok | İmzasız/sahte imaj cluster'a girer | `verifyImages` + cosign keyless |
| Label enforcement yok | Sahipsiz kaynak, dağıtılamayan maliyet | `require-labels` ile taban kontrol |
| `failurePolicy: Ignore` (imza policy'sinde) | Webhook düşünce policy sessizce baypas olur | Kritik gate'te `Fail` |

> *"Policy-as-code, 'lütfen böyle yap' dokümanını 'yoksa girmez' kuralına çevirir — denetim değil, engel."*
