# Policy-as-Code — Kyverno vs OPA Gatekeeper

> *"Ekipte 14 mühendis, 200 namespace, 3 cluster. Hangi pod root mu çalışıyor,
> hangisi resource limit'sız, hangisi public image mı çekiyor — manuel
> review ölçeklenmez. **Kod yazmıştır, kod denetlesin.**"*

Bu rehber Kubernetes admission policy ekosisteminin iki büyük oyuncusunu
karşılaştırır, hazır policy katalogu verir, ve "production'a girerken
hangi 10 policy mutlaka olmalı" sorusunun cevabını verir.

---

## 🎯 Policy-as-Code Nedir?

```
┌─────────────────────────────────────────────────────────────────┐
│                       Kullanıcı (kubectl apply)                  │
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
      │ ekler/    │   │  Gatekeeper  │   │              │
      │ değiştir  │   │  ALLOW/DENY  │   │              │
      └───────────┘   └──────────────┘   └──────────────┘
```

**Policy-as-Code = "kuralı kodla, Git'te tut, CI'da test et, cluster otomatik enforce etsin."**

---

## ⚖️ Kyverno vs OPA Gatekeeper

| Özellik | **Kyverno** | **OPA Gatekeeper** |
|---|---|---|
| **DSL** | YAML (Kubernetes-native) | Rego (yeni dil öğren) |
| **Öğrenme eğrisi** | Düşük | Orta-yüksek |
| **K8s odak** | Sadece K8s | K8s + Terraform + Envoy + ... |
| **Mutation** | Native, güçlü | Sınırlı (mutating webhook ayrı) |
| **Image verify (cosign)** | Native | Eklenti gerekir |
| **Generate (yan kaynak)** | Native (`generate` rule) | Yok |
| **CLI test** | `kyverno test` | `gator test` |
| **Performance** | İyi | İyi |
| **Topluluk** | CNCF Incubating | CNCF Graduated, daha köklü |
| **Best for** | Sadece K8s, hızlı başla | Multi-product, Rego know-how var |

> 🔑 **Pratik öneri (2026):** Yeni bir cluster başlatıyorsan **Kyverno**.
> Zaten Rego biliyorsan veya OPA'yı non-K8s için kullanıyorsan **Gatekeeper**.

---

## 🛠️ Kyverno

### Kurulum
```bash
helm install kyverno kyverno/kyverno \
  -n kyverno --create-namespace \
  --set replicaCount=3 \
  --set webhooks.failurePolicy=Fail   # production: Fail, lab: Ignore
```

### İlk policy: latest tag yasak
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
  background: true                    # mevcut kaynaklarda da audit
  rules:
    - name: validate-image-tag
      match:
        any:
          - resources:
              kinds: [Pod]
      validate:
        message: "':latest' tag yasak; explicit version veya digest kullan."
        pattern:
          spec:
            containers:
              - image: "!*:latest"
              - image: "*:*"
```

### Mutating policy: default labels ekle
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

### Generate policy: namespace açıldığında otomatik NetworkPolicy
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
          mutateDigest: true   # tag → digest dönüştür
          required: true
```

### CLI test (CI'da policy regression yakala)
```bash
# kyverno-cli ile policy test
kyverno test ./policies/

# Test struct
# tests/
# ├── policies/disallow-latest-tag.yaml
# ├── resources/pod-good.yaml      # pass beklenir
# ├── resources/pod-bad.yaml       # fail beklenir
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

### Kurulum
```bash
helm install gatekeeper gatekeeper/gatekeeper \
  -n gatekeeper-system --create-namespace
```

### ConstraintTemplate: yeniden kullanılabilir kural
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

### Constraint: template'i parametrelendir
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

## 🛡️ "Asgari Hijyen 10" Policy Katalogu

Production cluster'a girişte **mutlaka** olması gereken 10 policy:

| # | Policy | Niye |
|---|---|---|
| 1 | `disallow-latest-tag` | Reproducibility, rollback |
| 2 | `require-resource-limits` | Noisy neighbor, OOM kill |
| 3 | `require-non-root` | Privilege escalation |
| 4 | `disallow-privileged` | Container escape |
| 5 | `restrict-host-namespaces` | hostPID/hostNetwork/hostIPC kapalı |
| 6 | `disallow-host-path` | Node FS izolasyonu |
| 7 | `verify-image-signatures` | Supply chain |
| 8 | `restrict-image-registries` | Sadece allow-listed registry |
| 9 | `require-labels` | cost-center, owner, env |
| 10 | `default-deny-network-policy` | Namespace açılırken auto-generate |

Her birini bir Kyverno ClusterPolicy olarak hazırla. Hazır şablonlar: [`17-Templates/kyverno-policies/`](../17-Templates/kyverno-policies/).

### Tam set örneği
```yaml
# policies/01-disallow-latest-tag.yaml
# policies/02-require-resource-limits.yaml
# policies/03-require-non-root.yaml
# ...
# policies/10-default-deny-netpol.yaml
```

GitOps ile ArgoCD/Flux apply.

---

## 📊 Dry-Run / Audit Mode (production'a sokmadan önce)

> ⚠️ **Asla** ilk denemede `validationFailureAction: Enforce`. Önce **Audit**.

### Aşamalı rollout
```yaml
# Hafta 1: Audit (logla, engelle değil)
spec:
  validationFailureAction: Audit

# Hafta 2: Audit + warn (kullanıcıya warning)
spec:
  validationFailureAction: Audit
  webhookConfiguration:
    matchPolicy: Equivalent
# Kyverno warnings PolicyReport'a düşer

# Hafta 3: Enforce (ihlal eden kaynak reddedilir)
spec:
  validationFailureAction: Enforce
```

### PolicyReport'tan rapor
```bash
kubectl get policyreports -A
kubectl get clusterpolicyreports

# Detay
kubectl describe policyreport -n <NS> <NAME>
```

### Grafana panel: ihlal trendi
```promql
sum by (policy) (
  kyverno_policy_results_total{rule_result="fail"}
)
```

---

## 🌍 Multi-Cluster Policy Yönetimi

### Sorun
- 5 cluster, 50 policy → manuel sync imkansız
- Policy versioning yok
- Drift fark edilmez

### Çözüm: GitOps + ApplicationSet
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: kyverno-policies
spec:
  generators:
    - clusters: {}    # tüm registered cluster'lar
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

### Policy promotion akışı
```
[dev cluster]    [staging cluster]   [prod cluster]
    Audit  →→→→→→  Audit  →→→→→→→→→  Enforce
    7 gün           14 gün             ✓
```

PR ile `dev/audit` → `staging/audit` → `prod/enforce`. Her stage'de bir hafta gözlemle.

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

### Policy değişikliği bir PR'a düşer:
1. `kyverno test` çalışır
2. `kyverno apply --warn-exit-code 1` ile mevcut cluster'da kaç ihlal yaratacağını gösterir
3. Reviewer onay verir
4. Merge → Argo sync → cluster'da Audit
5. 7 gün sonra → Enforce

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| İlk gün `Enforce` | Cluster yarısı broken | Audit → 1 hafta gözlemle → Enforce |
| Policy Git'te değil | Drift, kim ekledi belirsiz | GitOps + ApplicationSet |
| Test yok | Regresyon prod'da yakalanır | `kyverno test` CI'da |
| Tek dev cluster'da test | Edge case'ler kaçar | Multi-cluster promotion |
| Exception ad-hoc | "X namespace'e açıldı" 6 ay sonra unutulur | `exclude:` rule + comment + expiry |
| Kural çok geniş ("require labels") | False positive bombardımanı | Spesifik (require team+cost-center) |
| Sadece validate, mutate kullanılmıyor | Developer her seferinde aynı şeyi yazar | Mutate ile default'lar otomatik |
| Webhook timeout = 5s + Fail policy | API server tıkanır | TimeoutSeconds=10, failurePolicy=Fail (production), Ignore (lab) |
| Policy `Pod` match ediyor, `Deployment` değil | Sadece pod create'de tetiklenir, deployment "kabul" olur | Hem Pod hem Deployment match |
| `kyverno` kendisi root + cluster-admin | Compromise → cluster sahibi | Kyverno operatörü minimum RBAC ile |

---

## 📋 Production'a Geçiş Checklist

```
[ ] Kyverno (veya Gatekeeper) HA kurulu (3 replica)
[ ] failurePolicy: Fail (production), Ignore (dev)
[ ] webhookTimeoutSeconds: 10
[ ] Policy'ler Git repo'da (örn: <ORG>/k8s-policies)
[ ] CI: kyverno test her PR'da
[ ] CI: kyverno apply --warn ile cluster impact preview
[ ] Audit mode 1+ hafta önce, ihlal sayısı baseline
[ ] PolicyReport → Grafana / SIEM
[ ] Asgari 10 policy aktif (yukarıdaki tablo)
[ ] Exception'lar kayıtlı (PR template + expiry)
[ ] Multi-cluster: ApplicationSet ile sync
[ ] Promotion: dev/audit → staging/audit → prod/enforce
[ ] Policy değişikliği oncall'a notify (Slack #platform-changes)
[ ] Quarterly: policy katalog review (eskiyen kural temizle)
```

---

## 📚 Referanslar

- **Kyverno** — kyverno.io
- **Kyverno Policy Library** — kyverno.io/policies
- **OPA Gatekeeper** — open-policy-agent.github.io/gatekeeper
- **Gatekeeper Library** — open-policy-agent.github.io/gatekeeper-library
- **CNCF Policy WG** — github.com/cncf/sig-security
- [`Kubernetes-Hardening.md`](Kubernetes-Hardening.md) — PSS + admission birlikte
- [`SLSA-and-SBOM.md`](SLSA-and-SBOM.md) — verifyImages kısmı
- [`17-Templates/kyverno-policies/`](../17-Templates/kyverno-policies/) — hazır policy

---

> *"Policy-as-Code kuralı yazılı hale getirir; **enforcement** kuralı
> uygulanır hale getirir. Kural Git'te durup cluster'da yoksa, kural
> değil **niyet** beyanıdır."*
