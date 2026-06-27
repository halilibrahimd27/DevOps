---
description: "GitHub Actions production tarifleri: OIDC cloud auth, matrix build, reusable workflow, caching ve secret yonetimi somut YAML ornekleriyle anlatilir."
---
# GitHub Actions Recipes — Production Tarifleri

> *"GitHub Actions YAML 'magic' değil — **disiplin**. Reusable
> workflow + OIDC + composite action olmadan, **kopya-yapıştır
> 50 workflow** maintenance cehennemi."*

Bu rehber GitHub Actions için en sık ihtiyaç duyulan production
tariflerini — OIDC cloud auth, matrix build, reusable workflow,
caching, secret management — somut örneklerle sunar.

---

## 🔐 Recipe 1: OIDC ile AWS Auth (Uzun-ömürlü Key Yok)

```yaml
permissions:
  id-token: write   # OIDC için zorunlu
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>

      - uses: aws-actions/configure-aws-credentials@<VERSION>
        with:
          role-to-assume: arn:aws:iam::<ACCOUNT>:role/github-actions-deploy
          aws-region: eu-west-1
          role-session-name: github-${{ github.run_id }}

      - run: aws sts get-caller-identity
      - run: aws s3 ls
```

### IAM trust relationship
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::<ACCOUNT>:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:<ORG>/<REPO>:ref:refs/heads/main"
      }
    }
  }]
}
```

> 🔑 **`sub` Condition** kritik — sadece `main` branch'ten deploy. Her branch'ten kabul = compromise riski.

---

## 🌐 Recipe 2: GCP Workload Identity Federation

```yaml
permissions:
  id-token: write

steps:
  - uses: google-github-actions/auth@<VERSION>
    with:
      workload_identity_provider: 'projects/<PROJECT_NUM>/locations/global/workloadIdentityPools/github/providers/github'
      service_account: 'github-deploy@<PROJECT>.iam.gserviceaccount.com'

  - uses: google-github-actions/setup-gcloud@<VERSION>

  - run: gcloud storage ls
```

---

## 🚀 Recipe 3: Multi-Arch Docker Build + Push

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write
    steps:
      - uses: actions/checkout@<VERSION>

      - uses: docker/setup-qemu-action@<VERSION>
      - uses: docker/setup-buildx-action@<VERSION>

      - uses: docker/login-action@<VERSION>
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/metadata-action@<VERSION>
        id: meta
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=sha,prefix=,suffix=,format=short

      - uses: docker/build-push-action@<VERSION>
        id: build
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - uses: sigstore/cosign-installer@<VERSION>
      - name: Sign image (keyless)
        run: |
          cosign sign --yes \
            ghcr.io/${{ github.repository }}@${{ steps.build.outputs.digest }}
```

---

## 🔁 Recipe 4: Matrix Build (Multi-Version)

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        node: [20, 22]
        os: [ubuntu-latest, macos-latest]
        include:
          - node: 22
            os: ubuntu-latest
            coverage: true
        exclude:
          - node: 20
            os: macos-latest
    steps:
      - uses: actions/checkout@<VERSION>
      - uses: actions/setup-node@<VERSION>
        with:
          node-version: ${{ matrix.node }}
          cache: 'npm'
      - run: npm ci
      - run: npm test
      - if: matrix.coverage
        uses: codecov/codecov-action@<VERSION>
```

---

## ♻️ Recipe 5: Reusable Workflow

```yaml
# .github/workflows/_build-and-test.yml (REUSABLE)
on:
  workflow_call:
    inputs:
      node-version:
        required: true
        type: string
      run-coverage:
        required: false
        type: boolean
        default: false
    outputs:
      build-id:
        value: ${{ jobs.build.outputs.build-id }}
    secrets:
      NPM_TOKEN:
        required: true

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      build-id: ${{ steps.id.outputs.build-id }}
    steps:
      - uses: actions/checkout@<VERSION>
      - uses: actions/setup-node@<VERSION>
        with:
          node-version: ${{ inputs.node-version }}
          cache: 'npm'
          registry-url: 'https://registry.npmjs.org'
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
      - run: npm ci
      - run: npm test
      - if: ${{ inputs.run-coverage }}
        run: npm run coverage
      - id: id
        run: echo "build-id=$(uuidgen)" >> $GITHUB_OUTPUT
```

```yaml
# .github/workflows/ci.yml (CALLER)
on: [push, pull_request]

jobs:
  test:
    uses: ./.github/workflows/_build-and-test.yml
    with:
      node-version: '22'
      run-coverage: true
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

> 🔑 **Underscore prefix** (`_build-and-test`) reusable convention; UI'da gizlenir.

---

## 🧱 Recipe 6: Composite Action (Local)

```yaml
# .github/actions/setup/action.yml
name: 'Setup Project'
description: 'Checkout + Node + deps install'

inputs:
  node-version:
    required: false
    default: '22'

runs:
  using: 'composite'
  steps:
    - uses: actions/checkout@<VERSION>

    - uses: actions/setup-node@<VERSION>
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'

    - run: npm ci
      shell: bash
```

```yaml
# Caller
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: ./.github/actions/setup
        with:
          node-version: '22'
      - run: npm run build
```

---

## 🔒 Recipe 7: Environment Protection + Manual Approval

```yaml
jobs:
  deploy-prod:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://payments.<DOMAIN>
    needs: [build, test]
    steps:
      - run: ./deploy.sh
```

GitHub UI: Settings → Environments → `production`
- Required reviewers: @platform-team
- Wait timer: 5 dakika
- Deployment branches: `main` only
- Environment secrets

---

## 💾 Recipe 8: Cache Patterns

### Dependencies cache
```yaml
- uses: actions/setup-node@<VERSION>
  with:
    node-version: '22'
    cache: 'npm'           # otomatik node_modules cache
```

### Custom cache
```yaml
- uses: actions/cache@<VERSION>
  with:
    path: |
      ~/.cargo/registry
      ~/.cargo/git
      target
    key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}
    restore-keys: |
      ${{ runner.os }}-cargo-
```

### BuildKit cache
```yaml
- uses: docker/build-push-action@<VERSION>
  with:
    cache-from: |
      type=registry,ref=<REGISTRY>/<APP>:cache
      type=gha,scope=${{ github.workflow }}
    cache-to: |
      type=registry,ref=<REGISTRY>/<APP>:cache,mode=max
      type=gha,scope=${{ github.workflow }},mode=max
```

---

## 🔄 Recipe 9: Concurrency (Cancel Old Runs)

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true   # yeni commit gelirse eskiyi iptal et
```

→ 5 commit hızlı atılırsa sadece son'unu test eder, ilk 4'ü iptal.

---

## 🌍 Recipe 10: Conditional Steps + Path Filter

```yaml
on:
  pull_request:
    paths:
      - 'backend/**'
      - 'package.json'

jobs:
  test:
    if: github.event.pull_request.draft == false
    runs-on: ubuntu-latest
    steps:
      - uses: dorny/paths-filter@<VERSION>
        id: changes
        with:
          filters: |
            backend:
              - 'backend/**'
            frontend:
              - 'frontend/**'

      - if: steps.changes.outputs.backend == 'true'
        run: cd backend && npm test

      - if: steps.changes.outputs.frontend == 'true'
        run: cd frontend && npm test
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| `@main` veya `@v1` action ref | Tag mutable → supply chain risk | SHA pin (`@a1b2c3...`) |
| Long-lived AWS access key | Compromise window | OIDC |
| Tüm secret env'ye exposed | Compromise = total | Specific step `env:` |
| Workflow tekrarı (10+ benzer) | Maintenance hell | Reusable workflow |
| Cache key static | İnvalidasyon yok | `hashFiles(...)` ile dynamic |
| Cancel-in-progress yok | Eski run'lar saatler boş | `concurrency` |
| Matrix `fail-fast: false` her zaman | Bir dal hata, hâlâ 12 dk | True (debug için false) |
| Self-hosted runner persistent | Side-channel attack | Ephemeral runner |
| Env protection yok prod'da | Direct deploy + bug | Required reviewer |
| Path filter yok | Her PR full CI | `paths:` filter |

---

## 📋 GitHub Actions Production Checklist

```
[ ] OIDC cloud auth (uzun-ömürlü key yok)
[ ] Action SHA pin (Renovate ile güncel)
[ ] Reusable workflow (org-wide template)
[ ] Composite action (local helper)
[ ] Concurrency: cancel-in-progress
[ ] Cache: deps + BuildKit
[ ] Path filter (selective testing)
[ ] Environment protection (prod için)
[ ] Required reviewer (manuel approval critical job)
[ ] Secret scope: per-environment
[ ] Logs retention: 90 gün (default), audit için ayrı
[ ] Workflow dispatch (manual trigger)
[ ] Notification: Slack on failure
[ ] Self-hosted runner: ephemeral (gerekirse)
```

---

## 📚 Referanslar

- **GitHub Actions Docs** — docs.github.com/actions
- **GitHub Actions Marketplace** — github.com/marketplace?type=actions
- **starter-workflows** — github.com/actions/starter-workflows
- [`Pipeline-Patterns.md`](Pipeline-Patterns.md)
- [`Pipeline-Performance.md`](Pipeline-Performance.md)
- [`Reusable-Workflows.md`](Reusable-Workflows.md)
- [`Caching-Strategies.md`](Caching-Strategies.md)

---

> *"GitHub Actions ile **3 satırda** OIDC + multi-arch build +
> sign + deploy yapabiliyorsan hazırsın. **40 satır YAML kopyala-
> yapıştır** yapıyorsan, **reusable workflow** öğrenme zamanı."*
