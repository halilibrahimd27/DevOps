---
description: "CI/CD pipeline patternleri: lint, test, security scan, build, image scan, imzalama, SBOM ve GitOps promote adimlarinin sirali katmanlama referansi."
tags:
  - CI/CD
  - Security
  - SBOM
  - GitOps
---
# CI/CD Pipeline Patterns

> *"Pipeline'ın 10 dakika sürüyorsa ekip 'bekleyim de bir kahve içeyim'
> diyor. 30 dakika sürüyorsa context-switch'le başka iş yapıyor.
> 1 saat sürüyorsa pipeline ölü demektir."*

---

## 🎯 Pipeline'ın görevleri (sırasıyla)

```
1. Lint & Format                  (10-30 sn)
2. Test                           (1-3 dk)
3. Security scan (SAST/SCA)       (1-2 dk)
4. Build artifact (image)         (1-3 dk, cached)
5. Image vulnerability scan       (30 sn-1 dk)
6. Image sign + SBOM              (10 sn)
7. E2E / smoke (preview env)      (3-5 dk)
8. Promote / GitOps update        (10 sn)
─────────────────────────────────────────────
   Toplam PR feedback hedefi:     < 10 dk
```

> 10 dakika geçilirse: paralel çalış, cache iyileştir, test'leri parçala.

---

## 📋 Temel pattern'ler

### Pattern 1: Layered (sırayla, fail-fast)

```
Lint → Test → SAST → Build → Sign → Scan → Smoke → Deploy
   ↓     ↓     ↓       ↓      ↓       ↓        ↓
   her aşama bir öncekini doğrular; biri fail = sonrakiler skip
```

**Ne zaman:** Küçük-orta servisler. Net, debug kolay.

```yaml
# GitHub Actions örneği
jobs:
  lint:    { ... }
  test:    { needs: [lint] }
  sast:    { needs: [test] }
  build:   { needs: [sast] }
  scan:    { needs: [build] }
  smoke:   { needs: [scan] }
  deploy:  { needs: [smoke], if: github.ref == 'refs/heads/main' }
```

### Pattern 2: Parallel Fan-out

```
        ┌── Lint ───┐
        │           │
PR ─────┼── Test ───┼── Build ── Scan ── Sign ── Deploy
        │           │
        └── SAST ───┘
            │
            └── SCA ─┘
```

İlk üç bağımsız → paralel; build önce hepsinin geçmesini bekler.

**Ne zaman:** Hız öncelikli; her aşama bağımsızsa.

```yaml
jobs:
  lint:  { runs-on: ubuntu-latest, steps: [...] }
  test:  { runs-on: ubuntu-latest, steps: [...] }
  sast:  { runs-on: ubuntu-latest, steps: [...] }
  sca:   { runs-on: ubuntu-latest, steps: [...] }
  build:
    needs: [lint, test, sast, sca]
    runs-on: ubuntu-latest
    # ...
```

### Pattern 3: Matrix Build

Aynı kodu birden fazla ortamda (dil versiyonu, OS, arch).

```yaml
test:
  runs-on: ${{ matrix.os }}
  strategy:
    fail-fast: false
    matrix:
      os: [ubuntu-latest, macos-latest]
      node: [20, 22, 23]
      include:
        - os: ubuntu-latest
          node: 22
          coverage: true                # sadece bir matrix'te coverage
  steps:
    - uses: actions/setup-node@v4
      with: { node-version: ${{ matrix.node }} }
    - run: npm ci && npm test
```

### Pattern 4: DAG (GitLab CI / Argo Workflows)

Karmaşık bağımlılıklar; "bunu bekle, şuna bağlı değil" diyebilirsin.

```yaml
# GitLab CI
deploy-prod:
  stage: deploy
  needs:
    - build-image
    - integration-test
  # `unit-test` ve `lint` bu job için gerekmiyor; bekleme yok
```

### Pattern 5: Reusable / Callable Workflow

Aynı iş akışını N repo'da tekrar yazma.

```yaml
# .github/workflows/_build-app.yml (template repo'da)
on:
  workflow_call:
    inputs:
      app-name: { required: true, type: string }
    outputs:
      image-digest:
        value: ${{ jobs.build.outputs.digest }}

jobs:
  build:
    # ...
```

```yaml
# Caller workflow (tüketici repo'da)
jobs:
  build:
    uses: <ORG>/.github/.github/workflows/_build-app.yml@main
    with: { app-name: payments }
    secrets: inherit
```

> 💡 **`<ORG>/.github` repo'su** GitHub'da özel — org-wide template'ler oraya konur, otomatik tüm repo'lara açılır.

---

## ⚡ Hız optimizasyonu

### A. Caching

| Stack | Ne cache'lenmeli |
|---|---|
| Node.js | `~/.npm`, `node_modules`, `.next/cache` |
| Python | `~/.cache/pip`, `.venv` (uv kullanıyorsan `~/.cache/uv`) |
| Go | `~/.cache/go-build`, `~/go/pkg/mod` |
| Rust | `~/.cargo`, `target/` |
| Docker | BuildKit `cache-from/cache-to` (registry veya GHA) |
| Maven/Gradle | `~/.m2`, `~/.gradle` |

```yaml
# GitHub Actions example
- uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      node_modules
    key: npm-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
    restore-keys: npm-${{ runner.os }}-
```

### B. Test parçalama (sharding)

```yaml
test:
  runs-on: ubuntu-latest
  strategy:
    matrix:
      shard: [1/4, 2/4, 3/4, 4/4]
  steps:
    - run: npm test -- --shard=${{ matrix.shard }}
```

### C. Sadece değişen dosyaları test (monorepo için)

```yaml
- uses: dorny/paths-filter@v3
  id: changes
  with:
    filters: |
      api: 'apps/api/**'
      web: 'apps/web/**'
- if: steps.changes.outputs.api == 'true'
  run: npm test --workspace=api
```

Daha gelişmiş: **Nx affected**, **Bazel target tracking**, **Turborepo**.

### D. BuildKit registry cache

```bash
docker buildx build \
  --cache-from type=registry,ref=<REGISTRY>/<IMAGE>:cache \
  --cache-to type=registry,ref=<REGISTRY>/<IMAGE>:cache,mode=max \
  --push .
```

### E. Self-hosted runner (büyük org)

GitHub-hosted runner = 2 CPU, 7 GB RAM. Kendi runner'ın 16 CPU + 64 GB
olabilir → 5x hız mümkün. Maliyet: ekstra altyapı + güvenlik.

---

## 🔐 Güvenlik

### OIDC ile cloud auth (uzun-ömürlü key yok)

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/gh-actions-role
          aws-region: <REGION>
      - run: aws s3 sync ./dist s3://<BUCKET>/
```

```hcl
# Terraform: AWS IAM role + GitHub OIDC trust
resource "aws_iam_role" "gh_actions" {
  name = "gh-actions-role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = { Federated = "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com" }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:<ORG>/<REPO>:ref:refs/heads/main"
        }
      }
    }]
  })
}
```

### Secret yönetimi

- ✅ GitHub Secrets / GitLab Variables — masked
- ✅ Vault / AWS Secrets Manager — runtime'da fetch
- ❌ `.github/workflows/*.yml` içinde plain
- ❌ Logged variable (`echo "${{ secrets.X }}"`) — masked olmasına rağmen pipe'lardan sızabilir

### Permission scoping

GitHub Actions default = repo'da read+write. Kısıtla:

```yaml
permissions:
  contents: read
  id-token: write       # OIDC için
  packages: write       # ghcr.io push için
  # diğer her şey explicit eklenmeli
```

---

## 🎯 Branch Strategy + Pipeline

### Trunk-based + feature flag (önerilen)

```
main (sürekli deploy edilebilir)
  ↓ kısa-ömürlü branch (1-2 gün)
  feature/auth → PR → CI → review → squash merge → main
                                                   ↓
                                              auto-deploy to dev
                                                   ↓
                                              promote staging
                                                   ↓
                                              promote prod (manual approval)
```

### Pipeline farkları

| Branch | Hangi adımlar |
|---|---|
| Feature branch | lint, test, sast, build, scan (no deploy) |
| Main | + sign, push image, GitOps tag bump (auto-deploy dev) |
| Tag (v1.2.3) | + production deploy (manual approval) |

```yaml
deploy-prod:
  if: startsWith(github.ref, 'refs/tags/v')
  environment:
    name: production
    url: https://<DOMAIN>
  # `environment` GitHub'da manual approval ister
```

---

## 🚀 Progressive Delivery

### Canary (Argo Rollouts)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  strategy:
    canary:
      steps:
        - setWeight: 5
        - pause: { duration: 5m }
        - analysis:
            templates:
              - templateName: success-rate
        - setWeight: 25
        - pause: { duration: 10m }
        - analysis:
            templates:
              - templateName: success-rate
        - setWeight: 50
        - pause: { duration: 30m }
        - setWeight: 100
```

Otomatik analysis fail → rollback.

### Blue/Green

```yaml
strategy:
  blueGreen:
    activeService: my-app-active
    previewService: my-app-preview
    autoPromotionEnabled: false   # manuel onay
```

### Feature Flag

Kod prod'da ama kapalı; per-cohort açma. Tools: LaunchDarkly, Flagsmith,
OpenFeature (vendor-neutral SDK).

```python
if feature_flags.is_enabled("new-checkout", user_id=user.id):
    return new_checkout_flow(...)
else:
    return old_checkout_flow(...)
```

---

## 📊 Pipeline Metrikleri

Her pipeline ekibe DORA metric çıkarır:

```promql
# Deployment frequency (per day)
sum(rate(pipeline_runs_total{branch="main",status="success"}[7d])) * 86400

# Lead time (commit → deploy, p95)
histogram_quantile(0.95, sum by (le) (rate(commit_to_deploy_seconds_bucket[7d])))

# Change failure rate
sum(rate(deploy_failures_total[7d])) / sum(rate(deploys_total[7d]))

# Time to restore (incident → resolved, p95)
histogram_quantile(0.95, sum by (le) (rate(incident_duration_seconds_bucket[7d])))
```

---

## ⚠️ Anti-pattern'ler

| ❌ Anti-pattern | ✅ Çözüm |
|---|---|
| Tüm CI sequential | Paralel fan-out + matrix |
| `npm install` her run'da | `npm ci` + cache |
| 10 farklı YAML CI workflow | Reusable workflow + composite action |
| Production deploy CI'dan otomatik | GitOps repo PR + ArgoCD reconcile |
| Secret env var'da plain | OIDC veya Vault fetch |
| "Bypass approval" power user | Bypass'sız policy-as-code |
| Test 30 dk sürüyor | Sharding + selective test |
| Image build her PR'da no-cache | BuildKit cache + COPY sırası |
| `latest` tag deploy | Semantic / SHA-pinned tag |
| CI'da bir adım manuel ("re-run") | Otomatik retry + flaky test ayrımı |

---

## 🎓 Pipeline Maturity Levels

```
Level 1: "It works"          — manuel adımlar, tek-tıkla deploy
Level 2: "Automated"          — push → CI → auto-deploy dev
Level 3: "Tested"             — CI'da unit + integration test, fail = no deploy
Level 4: "Secured"            — SAST/SCA/IaC scan + image sign + Kyverno verify
Level 5: "Observed"           — DORA metric'ler track ediliyor, pipeline'a feedback
Level 6: "Optimized"          — pipeline P95 latency < 10 dk, parallel + cache
Level 7: "Self-healing"       — failed deploy auto-rollback, error budget gate
```

Her ekip nerede olduğunu bilmeli ve bir sonraki seviyeyi hedeflemeli.

---

## 📚 Devamı

- [`17-Templates/github-actions/`](../17-Templates/github-actions/) — hazır workflow'lar
- [`08-Security/DevSecOps-Pipeline.md`](../08-Security/DevSecOps-Pipeline.md)
- [`06-GitOps/`](../06-GitOps/) — pipeline → ArgoCD → cluster akışı
- [Continuous Delivery — Jez Humble & David Farley]
