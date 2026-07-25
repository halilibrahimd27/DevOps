---
description: "Kyverno policy-as-code templates: :latest tag rejection, cosign signature verification (supply chain) and mandatory label (cost/ownership) enforcement."
tags:
  - Template
  - Kubernetes
  - Security
  - Policy as Code
---
# Kyverno Policy Templates

> Admission-time enforcement: the rule is applied at cluster entry, not
> afterward via auditing. All three reject with `validationFailureAction: Enforce`.
> Switch to `Audit` to observe first, then enforce. Placeholders use `<UPPER_CASE>`.
> This page is the embedded form of the neighboring files; source files are in the same folder.

## Files

| File | What it enforces | Category |
|---|---|---|
| [`disallow-latest-tag.yaml`](disallow-latest-tag.yaml) | `:latest` forbidden, tag required | Best Practices |
| [`require-image-signature.yaml`](require-image-signature.yaml) | Only cosign-signed images | Supply Chain |
| [`require-labels.yaml`](require-labels.yaml) | Standard labels (cost/ownership) | Best Practices |

Policy-as-code depth: [`08-Security/`](../../08-Security/README.md).

### 1️⃣ `disallow-latest-tag.yaml`

`:latest` makes rollback impossible in prod (which image is running is unclear).

```yaml
# Kyverno policy — reject images with the `:latest` tag
# Makes rollback impossible in production; immutable tag required.

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
        message: "The `:latest` tag is forbidden in prod. Use a semantic version (`v1.2.3`) or SHA digest (`@sha256:...`)."
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
        message: "An image cannot be tagless (Docker defaults to `:latest`)."
        pattern:
          spec:
            containers:
              - image: "*:*"
```

### 2️⃣ `require-image-signature.yaml` — supply chain gate

The image you signed in CI (`docker-build-push.yml` → cosign keyless) is verified at cluster entry. The admission end of the supply-chain thread.

```yaml
# Kyverno policy — only allow signed images to be deployed
# Verifies images signed with cosign keyless OIDC.
#
# Install: https://kyverno.io
#
# Test:
#   kubectl run pod-test --image=ghcr.io/<ORG>/<IMAGE>:<TAG>
#   (if unsigned: admission webhook reject)

apiVersion: kyverno.io/v2beta1
kind: ClusterPolicy
metadata:
  name: verify-image-signature
  annotations:
    policies.kyverno.io/title: Verify Image Signature
    policies.kyverno.io/category: Supply Chain Security
    policies.kyverno.io/severity: high
    policies.kyverno.io/description: >-
      Only allows images from trusted registries and signed with cosign
      to be deployed to the cluster.
spec:
  validationFailureAction: Enforce       # Audit or Enforce
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
      # Bypass: specific system namespaces (example)
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
          # Mutate (digest pin) — converts the image tag to a SHA digest
          mutateDigest: true
          required: true
```

### 3️⃣ `require-labels.yaml` — cost + ownership

An unowned workload makes cost allocation and "who do I call" during an incident impossible.

```yaml
# Kyverno policy — mandatory label check (for cost allocation, ownership)
# Every workload must have the following labels:
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
          All workloads must have the following labels:
          - app.kubernetes.io/name
          - app.kubernetes.io/managed-by  (terraform | helm | argocd | flux)
          - team                          (e.g., payments, growth, platform)
          - cost-center                   (e.g., eng-1234)
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

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| `Enforce` from day 1 | Existing workloads get rejected, the team disables the policy | First `Audit`, see the violations, then `Enforce` |
| No signature verification | Unsigned/forged images enter the cluster | `verifyImages` + cosign keyless |
| No label enforcement | Unowned resources, undistributable cost | Baseline check via `require-labels` |
| `failurePolicy: Ignore` (in the signature policy) | If the webhook goes down, the policy is silently bypassed | `Fail` on a critical gate |

> *"Policy-as-code turns the 'please do it this way' document into a 'or it won't get in' rule — a barrier, not an audit."*
