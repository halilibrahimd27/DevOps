---
description: "Comparison of Kyverno and OPA Gatekeeper, the two big players in the Kubernetes admission policy ecosystem: a ready-made policy catalog and the 10 policies mandatory before going to production."
tags:
  - Security
  - Policy as Code
  - Kubernetes
  - Compliance
---
# Policy-as-Code — Kyverno vs OPA Gatekeeper

> *"The team has 14 engineers, 200 namespaces, 3 clusters. Which pod is running
> as root, which one has no resource limits, which one is pulling a public
> image — manual review doesn't scale. **Code wrote it, let code review it.**"*

This guide compares the two big players in the Kubernetes admission policy
ecosystem, gives you a ready-made policy catalog, and answers the question
of "which 10 policies must exist before going to production."

---

## 🎯 What Is Policy-as-Code?

```
┌─────────────────────────────────────────────────────────────────┐
│                        User (kubectl apply)                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                ┌────────────────────────────┐
                │   Kubernetes API Server    │
                └─────────────┬──────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
      ┌───────────┐   ┌──────────────┐   ┌──────────────┐
      │ Mutating  │   │  Validating  │   │   Storage    │
      │ Admission │   │  Admission   │   │    (etcd)    │
      │           │   │              │   │              │
      │ Kyverno   │   │  Kyverno /   │   │              │
      │ adds /    │   │  Gatekeeper  │   │              │
      │ modifies  │   │  ALLOW/DENY  │   │              │
      └───────────┘   └──────────────┘   └──────────────┘
```

**Policy-as-Code = "write the rule in code, keep it in Git, test it in CI, let the cluster enforce it automatically."**

---

## ⚖️ Kyverno vs OPA Gatekeeper

| Feature | **Kyverno** | **OPA Gatekeeper** |
|---|---|---|
| **DSL** | YAML (Kubernetes-native) | Rego (learn a new language) |
| **Learning curve** | Low | Medium-high |
| **K8s focus** | K8s only | K8s + Terraform + Envoy + ... |
| **Mutation** | Native, powerful | Limited (separate mutating webhook) |
| **Image verify (cosign)** | Native | Requires a plugin |
| **Generate (side resource)** | Native (`generate` rule) | None |
| **CLI test** | `kyverno test` | `gator test` |
| **Performance** | Good | Good |
| **Community** | CNCF Incubating | CNCF Graduated, more established |
| **Best for** | K8s only, get started fast | Multi-product, existing Rego know-how |

> 🔑 **Practical recommendation (2026):** Starting a new cluster? Use **Kyverno**.
> Already know Rego, or using OPA outside K8s too? Use **Gatekeeper**.

---

## 🛠️ Kyverno

### Installation
```bash
helm install kyverno kyverno/kyverno \
  -n kyverno --create-namespace \
  --set replicaCount=3 \
  --set webhooks.failurePolicy=Fail   # production: Fail, lab: Ignore
```

### First policy: ban the `latest` tag
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
  annotations:
    policies.kyverno.io/title: Disallow Latest Tag
    policies.kyverno.io/category: Best Practices
    policies.kyverno.io/severity: medium
spec:
  validationFailureAction: Enforce   # Audit | Enforce
  background: true                    # also audits existing resources
  rules:
    - name: validate-image-tag
      match:
        any:
          - resources:
              kinds: [Pod]
      validate:
        message: "':latest' tag is banned; use an explicit version or digest."
        pattern:
          spec:
            containers:
              - image: "!*:latest"
              - image: "*:*"
```

### Mutating policy: add default labels
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-default-labels
spec:
  rules:
    - name: add-team-label
      match:
        any:
          - resources:
              kinds: [Deployment, StatefulSet]
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              cost-center: "{{ request.namespace }}"
              managed-by: kyverno
```

### Generate policy: auto-create a NetworkPolicy when a namespace opens
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: generate-default-deny-netpol
spec:
  rules:
    - name: default-deny
      match:
        any:
          - resources:
              kinds: [Namespace]
      exclude:
        any:
          - resources:
              namespaces: [kube-system, kyverno, ingress-nginx]
      generate:
        kind: NetworkPolicy
        apiVersion: networking.k8s.io/v1
        name: default-deny-all
        namespace: "{{ request.object.metadata.name }}"
        synchronize: true
        data:
          spec:
            podSelector: {}
            policyTypes: [Ingress, Egress]
```

### VerifyImages: cosign keyless
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-images
spec:
  validationFailureAction: Enforce
  webhookTimeoutSeconds: 30
  rules:
    - name: verify-cosign
      match:
        any:
          - resources:
              kinds: [Pod]
      verifyImages:
        - imageReferences:
            - "ghcr.io/<ORG>/*"
          attestors:
            - entries:
                - keyless:
                    subject: "https://github.com/<ORG>/*"
                    issuer: "https://token.actions.githubusercontent.com"
          mutateDigest: true   # convert tag → digest
          required: true
```

### CLI test (catch policy regressions in CI)
```bash
# policy test with kyverno-cli
kyverno test ./policies/

# Test structure
# tests/
# ├── policies/disallow-latest-tag.yaml
# ├── resources/pod-good.yaml      # expected to pass
# ├── resources/pod-bad.yaml       # expected to fail
# └── kyverno-test.yaml            # asserts
```

```yaml
# kyverno-test.yaml
name: disallow-latest-tag-test
policies:
  - ../policies/disallow-latest-tag.yaml
resources:
  - resources/pod-good.yaml
  - resources/pod-bad.yaml
results:
  - policy: disallow-latest-tag
    rule: validate-image-tag
    resource: pod-good
    result: pass
  - policy: disallow-latest-tag
    rule: validate-image-tag
    resource: pod-bad
    result: fail
```

---

## 🛠️ OPA Gatekeeper

### Installation
```bash
helm install gatekeeper gatekeeper/gatekeeper \
  -n gatekeeper-system --create-namespace
```

### ConstraintTemplate: a reusable rule
```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items: {type: string}
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels
        violation[{"msg": msg}] {
          required := input.parameters.labels
          provided := input.review.object.metadata.labels
          missing := required[_]
          not provided[missing]
          msg := sprintf("Missing label: %v", [missing])
        }
```

### Constraint: parameterize the template
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: ns-must-have-team
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: [Namespace]
  parameters:
    labels: ["team", "cost-center", "env"]
```

### Test
```bash
gator test --filename=policies/ --image=<IMAGE>
```

---

## 🛡️ The "Minimum Hygiene 10" Policy Catalog

The 10 policies that **must** be in place before a production cluster goes live:

| # | Policy | Why |
|---|---|---|
| 1 | `disallow-latest-tag` | Reproducibility, rollback |
| 2 | `require-resource-limits` | Noisy neighbor, OOM kill |
| 3 | `require-non-root` | Privilege escalation |
| 4 | `disallow-privileged` | Container escape |
| 5 | `restrict-host-namespaces` | hostPID/hostNetwork/hostIPC disabled |
| 6 | `disallow-host-path` | Node FS isolation |
| 7 | `verify-image-signatures` | Supply chain |
| 8 | `restrict-image-registries` | Only allow-listed registries |
| 9 | `require-labels` | cost-center, owner, env |
| 10 | `default-deny-network-policy` | Auto-generate when a namespace opens |

Prepare each of these as a Kyverno ClusterPolicy. Ready-made templates: [`17-Templates/kyverno-policies/`](../17-Templates/kyverno-policies/).

### Full set example
```yaml
# policies/01-disallow-latest-tag.yaml
# policies/02-require-resource-limits.yaml
# policies/03-require-non-root.yaml
# ...
# policies/10-default-deny-netpol.yaml
```

Apply via GitOps with ArgoCD/Flux.

---

## 📊 Dry-Run / Audit Mode (before going to production)

> ⚠️ **Never** go straight to `validationFailureAction: Enforce` on the first try. Start with **Audit**.

### Phased rollout
```yaml
# Week 1: Audit (log it, don't block it)
spec:
  validationFailureAction: Audit

# Week 2: Audit + warn (warning shown to the user)
spec:
  validationFailureAction: Audit
  webhookConfiguration:
    matchPolicy: Equivalent
# Kyverno warnings land in the PolicyReport

# Week 3: Enforce (violating resource gets rejected)
spec:
  validationFailureAction: Enforce
```

### Reporting from PolicyReport
```bash
kubectl get policyreports -A
kubectl get clusterpolicyreports

# Detail
kubectl describe policyreport -n <NS> <NAME>
```

### Grafana panel: violation trend
```promql
sum by (policy) (
  kyverno_policy_results_total{rule_result="fail"}
)
```

---

## 🌍 Multi-Cluster Policy Management

### Problem
- 5 clusters, 50 policies → manual sync is impossible
- No policy versioning
- Drift goes unnoticed

### Solution: GitOps + ApplicationSet
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: kyverno-policies
spec:
  generators:
    - clusters: {}    # all registered clusters
  template:
    metadata:
      name: 'kyverno-policies-{{name}}'
    spec:
      project: platform
      source:
        repoURL: https://github.com/<ORG>/policies
        targetRevision: main
        path: kyverno
      destination:
        name: '{{name}}'
        namespace: kyverno
      syncPolicy:
        automated: {prune: true, selfHeal: true}
```

### Policy promotion flow
```
[dev cluster]    [staging cluster]   [prod cluster]
    Audit  →→→→→→  Audit  →→→→→→→→→  Enforce
    7 days          14 days            ✓
```

Via PR: `dev/audit` → `staging/audit` → `prod/enforce`. Observe for a week at each stage.

---

## 🧪 Policy CI/CD

### .github/workflows/policy-test.yml
```yaml
on: pull_request

jobs:
  kyverno-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>

      - name: Install kyverno-cli
        run: |
          curl -LO https://github.com/kyverno/kyverno/releases/download/<VER>/kyverno-cli_<VER>_linux_x86_64.tar.gz
          tar -xvf kyverno-cli_*.tar.gz
          sudo mv kyverno /usr/local/bin/

      - name: Test policies
        run: kyverno test ./policies

      - name: Validate against sample manifests
        run: |
          kyverno apply ./policies/ --resource=./test-manifests/
```

### A policy change goes through a PR:
1. `kyverno test` runs
2. `kyverno apply --warn-exit-code 1` shows how many violations it would trigger in the current cluster
3. Reviewer approves
4. Merge → Argo sync → Audit in the cluster
5. After 7 days → Enforce

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| `Enforce` on day one | Half the cluster breaks | Audit → observe for 1 week → Enforce |
| Policy not in Git | Drift, unclear who added what | GitOps + ApplicationSet |
| No tests | Regressions get caught in prod | `kyverno test` in CI |
| Testing on a single dev cluster only | Edge cases slip through | Multi-cluster promotion |
| Ad-hoc exceptions | "Opened up for namespace X" is forgotten 6 months later | `exclude:` rule + comment + expiry |
| Rule too broad ("require labels") | Flood of false positives | Be specific (require team+cost-center) |
| Validate only, mutate never used | Developer writes the same boilerplate every time | Defaults set automatically via mutate |
| Webhook timeout = 5s + Fail policy | API server gets clogged | TimeoutSeconds=10, failurePolicy=Fail (production), Ignore (lab) |
| Policy matches `Pod`, not `Deployment` | Only fires on pod create; the deployment gets "accepted" | Match both Pod and Deployment |
| `kyverno` itself runs as root + cluster-admin | Compromise → owns the cluster | Kyverno operator with minimum RBAC |

---

## 📋 Go-to-Production Checklist

```
[ ] Kyverno (or Gatekeeper) installed HA (3 replicas)
[ ] failurePolicy: Fail (production), Ignore (dev)
[ ] webhookTimeoutSeconds: 10
[ ] Policies live in a Git repo (e.g. <ORG>/k8s-policies)
[ ] CI: kyverno test on every PR
[ ] CI: kyverno apply --warn for a cluster impact preview
[ ] Audit mode running 1+ week beforehand, baseline violation count
[ ] PolicyReport → Grafana / SIEM
[ ] Minimum 10 policies active (table above)
[ ] Exceptions on record (PR template + expiry)
[ ] Multi-cluster: synced via ApplicationSet
[ ] Promotion: dev/audit → staging/audit → prod/enforce
[ ] Policy changes notify oncall (Slack #platform-changes)
[ ] Quarterly: policy catalog review (retire stale rules)
```

---

## 📚 References

- **Kyverno** — kyverno.io
- **Kyverno Policy Library** — kyverno.io/policies
- **OPA Gatekeeper** — open-policy-agent.github.io/gatekeeper
- **Gatekeeper Library** — open-policy-agent.github.io/gatekeeper-library
- **CNCF Policy WG** — github.com/cncf/sig-security
- [`Kubernetes-Hardening.md`](Kubernetes-Hardening.md) — PSS + admission together
- [`SLSA-and-SBOM.md`](SLSA-and-SBOM.md) — the verifyImages section
- [`17-Templates/kyverno-policies/`](../17-Templates/kyverno-policies/) — ready-made policies

---

> *"Policy-as-Code puts the rule in writing; **enforcement** makes the
> rule actually apply. If the rule sits in Git but isn't in the cluster,
> it's not a rule — it's a declaration of **intent**."*
