---
description: "GitHub Actions production recipes: OIDC cloud auth, matrix build, reusable workflow, caching, and secret management explained with concrete YAML examples."
tags:
  - CI/CD
  - Git
  - Security
  - Secrets
  - AWS
---
# GitHub Actions Recipes — Production Playbook

> *"GitHub Actions YAML isn't 'magic' — it's **discipline**. Without
> reusable workflow + OIDC + composite action, you get **50 copy-pasted
> workflows** and a maintenance hell."*

This guide covers the most-needed production recipes for GitHub
Actions — OIDC cloud auth, matrix build, reusable workflow,
caching, secret management — with concrete examples.

---

## 🔐 Recipe 1: AWS Auth via OIDC (No Long-Lived Keys)

```yaml
permissions:
  id-token: write   # required for OIDC
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

> 🔑 The **`sub` condition** is critical — deploy only from the `main` branch. Accepting from any branch = compromise risk.

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

> 🔑 **Underscore prefix** (`_build-and-test`) is the reusable-workflow convention; it's hidden in the UI.

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
- Wait timer: 5 minutes
- Deployment branches: `main` only
- Environment secrets

---

## 💾 Recipe 8: Cache Patterns

### Dependencies cache
```yaml
- uses: actions/setup-node@<VERSION>
  with:
    node-version: '22'
    cache: 'npm'           # automatic node_modules cache
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
  cancel-in-progress: true   # cancel the old run when a new commit arrives
```

→ If 5 commits land in quick succession, only the last one gets tested; the first 4 are canceled.

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

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| `@main` or `@v1` action ref | Tag is mutable → supply chain risk | SHA pin (`@a1b2c3...`) |
| Long-lived AWS access key | Compromise window | OIDC |
| All secrets exposed to env | Compromise = total | Specific step `env:` |
| Workflow duplication (10+ similar) | Maintenance hell | Reusable workflow |
| Static cache key | No invalidation | Dynamic via `hashFiles(...)` |
| No cancel-in-progress | Old runs waste hours | `concurrency` |
| Matrix `fail-fast: false` always | One branch fails, still takes 12 min | True (false only for debugging) |
| Self-hosted runner persistent | Side-channel attack | Ephemeral runner |
| No environment protection in prod | Direct deploy + bug | Required reviewer |
| No path filter | Every PR runs full CI | `paths:` filter |

---

## 📋 GitHub Actions Production Checklist

```
[ ] OIDC cloud auth (no long-lived key)
[ ] Action SHA pin (kept current via Renovate)
[ ] Reusable workflow (org-wide template)
[ ] Composite action (local helper)
[ ] Concurrency: cancel-in-progress
[ ] Cache: deps + BuildKit
[ ] Path filter (selective testing)
[ ] Environment protection (for prod)
[ ] Required reviewer (manual approval for critical jobs)
[ ] Secret scope: per-environment
[ ] Logs retention: 90 days (default), separate for audit
[ ] Workflow dispatch (manual trigger)
[ ] Notification: Slack on failure
[ ] Self-hosted runner: ephemeral (if needed)
```

---

## 📚 References

- **GitHub Actions Docs** — docs.github.com/actions
- **GitHub Actions Marketplace** — github.com/marketplace?type=actions
- **starter-workflows** — github.com/actions/starter-workflows
- [`Pipeline-Patterns.md`](Pipeline-Patterns.md)
- [`Pipeline-Performance.md`](Pipeline-Performance.md)
- [`Reusable-Workflows.md`](Reusable-Workflows.md)
- [`Caching-Strategies.md`](Caching-Strategies.md)

---

> *"If you can do OIDC + multi-arch build + sign + deploy in
> **3 lines** with GitHub Actions, you're ready. If you're **copy-pasting
> 40 lines of YAML**, it's time to learn **reusable workflow**."*

---

> 🎓 **Learning Path:** This document is used as a "Read first" resource in the [`C2`](../22-Learning-Path/block-c-reproducibility/C2-ci.md) module.
