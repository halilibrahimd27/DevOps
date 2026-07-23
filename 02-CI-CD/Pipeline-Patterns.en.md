---
description: "CI/CD pipeline patterns: an ordered layering reference for the lint, test, security scan, build, image scan, signing, SBOM and GitOps promote steps."
tags:
  - CI/CD
  - Security
  - SBOM
  - GitOps
---
# CI/CD Pipeline Patterns

> *"If your pipeline takes 10 minutes, the team says 'let me wait and grab
> a coffee.' If it takes 30 minutes, they context-switch to other work.
> If it takes 1 hour, the pipeline is dead."*

---

## 🎯 The pipeline's jobs (in order)

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

> If you exceed 10 minutes: run in parallel, improve caching, split up the tests.

---

## 📋 Core patterns

### Pattern 1: Layered (sequential, fail-fast)

```
Lint → Test → SAST → Build → Sign → Scan → Smoke → Deploy
   ↓     ↓     ↓       ↓      ↓       ↓        ↓
   her aşama bir öncekini doğrular; biri fail = sonrakiler skip
```

**When:** Small-to-medium services. Clear, easy to debug.

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

The first three are independent → run in parallel; build waits for all of them to pass first.

**When:** Speed is the priority; when each stage is independent.

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

The same code across multiple environments (language version, OS, arch).

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

Complex dependencies; you can say "wait for this, but it doesn't depend on that."

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

Don't rewrite the same workflow across N repos.

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

> 💡 **The `<ORG>/.github` repo** is special on GitHub — org-wide templates go there and become automatically available to all repos.

---

## ⚡ Speed optimization

### A. Caching

| Stack | What to cache |
|---|---|
| Node.js | `~/.npm`, `node_modules`, `.next/cache` |
| Python | `~/.cache/pip`, `.venv` (if you use uv: `~/.cache/uv`) |
| Go | `~/.cache/go-build`, `~/go/pkg/mod` |
| Rust | `~/.cargo`, `target/` |
| Docker | BuildKit `cache-from/cache-to` (registry or GHA) |
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

### B. Test splitting (sharding)

```yaml
test:
  runs-on: ubuntu-latest
  strategy:
    matrix:
      shard: [1/4, 2/4, 3/4, 4/4]
  steps:
    - run: npm test -- --shard=${{ matrix.shard }}
```

### C. Test only changed files (for monorepos)

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

More advanced: **Nx affected**, **Bazel target tracking**, **Turborepo**.

### D. BuildKit registry cache

```bash
docker buildx build \
  --cache-from type=registry,ref=<REGISTRY>/<IMAGE>:cache \
  --cache-to type=registry,ref=<REGISTRY>/<IMAGE>:cache,mode=max \
  --push .
```

### E. Self-hosted runner (large org)

A GitHub-hosted runner = 2 CPU, 7 GB RAM. Your own runner can be 16 CPU + 64 GB
→ up to 5x speedup possible. Cost: extra infrastructure + security.

---

## 🔐 Security

### Cloud auth with OIDC (no long-lived keys)

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

### Secret management

- ✅ GitHub Secrets / GitLab Variables — masked
- ✅ Vault / AWS Secrets Manager — fetched at runtime
- ❌ Plain inside `.github/workflows/*.yml`
- ❌ Logged variable (`echo "${{ secrets.X }}"`) — can leak through pipes even though masked

### Permission scoping

GitHub Actions default = read+write on the repo. Restrict it:

```yaml
permissions:
  contents: read
  id-token: write       # OIDC için
  packages: write       # ghcr.io push için
  # diğer her şey explicit eklenmeli
```

---

## 🎯 Branch Strategy + Pipeline

### Trunk-based + feature flag (recommended)

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

### Pipeline differences

| Branch | Which steps |
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

Automatic analysis fail → rollback.

### Blue/Green

```yaml
strategy:
  blueGreen:
    activeService: my-app-active
    previewService: my-app-preview
    autoPromotionEnabled: false   # manuel onay
```

### Feature Flag

The code is in prod but off; turn it on per-cohort. Tools: LaunchDarkly, Flagsmith,
OpenFeature (vendor-neutral SDK).

```python
if feature_flags.is_enabled("new-checkout", user_id=user.id):
    return new_checkout_flow(...)
else:
    return old_checkout_flow(...)
```

---

## 📊 Pipeline Metrics

Every pipeline produces DORA metrics for the team:

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

## ⚠️ Anti-patterns

| ❌ Anti-pattern | ✅ Solution |
|---|---|
| All CI sequential | Parallel fan-out + matrix |
| `npm install` on every run | `npm ci` + cache |
| 10 different YAML CI workflows | Reusable workflow + composite action |
| Production deploy automatic from CI | GitOps repo PR + ArgoCD reconcile |
| Secret in plain env var | OIDC or Vault fetch |
| "Bypass approval" power user | Bypass-free policy-as-code |
| Tests take 30 min | Sharding + selective test |
| Image build with no-cache on every PR | BuildKit cache + COPY ordering |
| `latest` tag deploy | Semantic / SHA-pinned tag |
| A manual step in CI ("re-run") | Automatic retry + flaky test separation |

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

Every team should know where it stands and aim for the next level.

---

## 📋 Checklist

```
[ ] PR feedback süresi < 10 dk — geçen pipeline'lar paralel/cache ile sıkıştırıldı
[ ] Pipeline fail-fast: bir aşama fail = sonrakiler skip
[ ] Bağımsız aşamalar (lint/test/sast/sca) paralel fan-out ile koşuyor
[ ] Stack'e göre cache aktif (npm/pip/go/cargo/m2/BuildKit)
[ ] Cloud auth OIDC ile — uzun-ömürlü key repo'da yok
[ ] GitHub Actions `permissions:` explicit kısıtlandı (default read+write değil)
[ ] Secret'lar Secrets/Vault'tan; YAML içinde plain yok, log'a echo edilmiyor
[ ] Image build → sign + SBOM → vulnerability scan zinciri kuruldu
[ ] Production deploy CI'dan otomatik değil; GitOps PR + manual approval üzerinden
[ ] `latest` tag yasak — semantic/SHA-pinned tag deploy ediliyor
[ ] DORA metric'ler (deploy freq, lead time, CFR, MTTR) track ediliyor
```

---

## 📚 References

- [`Pipeline-Performance.md`](Pipeline-Performance.md) — cache, sharding, selective test in depth
- [`Reusable-Workflows.md`](Reusable-Workflows.md) — org-wide callable workflow patterns
- [`08-Security/DevSecOps-Pipeline.md`](../08-Security/DevSecOps-Pipeline.md) — SAST/SCA/scan gates
- [`08-Security/SLSA-and-SBOM.md`](../08-Security/SLSA-and-SBOM.md) — signing + provenance + SBOM
- [`06-GitOps/`](../06-GitOps/) — pipeline → ArgoCD → cluster promote flow
- [GitHub Actions docs](https://docs.github.com/en/actions)

---

## 📚 Further reading

- [`17-Templates/github-actions/`](../17-Templates/github-actions/) — ready-made workflows
- [`08-Security/DevSecOps-Pipeline.md`](../08-Security/DevSecOps-Pipeline.md)
- [`06-GitOps/`](../06-GitOps/) — pipeline → ArgoCD → cluster flow
- [Continuous Delivery — Jez Humble & David Farley]

---

> *"A pipeline should be layered, not fancy: order the steps for fast feedback, fail fast, automate the security gates — every step that stays manual gets skipped sooner or later."*

---

> 🎓 **Learning Path:** This document is used as a "Read first" resource in the [`C2`](../22-Learning-Path/block-c-reproducibility/C2-ci.md) module.
