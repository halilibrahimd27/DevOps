---
description: "CI pipeline optimization: a protocol for cutting a 30-minute CI down to 90 seconds via caching, parallelization, selective testing and runner-choice techniques."
tags:
  - CI/CD
  - Performance
  - Cost Optimization
---
# Pipeline Performance — Cut "10-Minute CI" Down to 90 Seconds

> *"If CI takes 30 minutes, half your engineers are **off doing something
> else** after opening a PR. This isn't the story of the time you invested
> yesterday — it's the story of the time you're **losing today**."*

This guide covers the concrete techniques for optimizing a CI pipeline —
caching, parallelization, selective testing, runner choice —
with a "30 minutes → 90 seconds" goal.

---

## 🎯 Why It Matters

| CI duration | Impact |
|---|---|
| > 30 min | Trunk-based impossible, devs waiting |
| 10-30 min | Painful, waiting + context switch |
| 5-10 min | Tolerable |
| 2-5 min | Sweet spot |
| < 2 min | Excellent (tight feedback loop) |

**Target (2026 high-performance teams)**: PR pipeline **< 5 min**.

---

## 📐 Measure First — Profile It

```yaml
# .github/workflows/ci.yml
on: [pull_request]

jobs:
  measure:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>

      - name: Time setup
        run: echo "T0: $(date +%s)" > /tmp/timing
      
      # ... record the duration with echo for each step
```

More pragmatic: **GitHub Actions** already gives you durations. **Buildkite/CircleCI** UIs show a duration breakdown.

### Typical bottlenecks
1. **Image pull** (ubuntu-latest 30s+)
2. **Dependency install** (`npm ci` 2-3 min)
3. **Build** (Webpack, Maven, Cargo)
4. **Test** (especially E2E/integration)
5. **Artifact upload/download**

---

## 🚀 10 Speed-Boosting Techniques

### 1. **Cache Dependencies**
```yaml
# Node
- uses: actions/setup-node@<VERSION>
  with:
    node-version: '20'
    cache: 'npm'

# Python
- uses: actions/setup-python@<VERSION>
  with:
    python-version: '3.12'
    cache: 'pip'

# Go
- uses: actions/setup-go@<VERSION>
  with:
    go-version: '1.23'
    cache: true
```

### 2. **Docker Layer Cache (BuildKit)**
```yaml
- uses: docker/setup-buildx-action@<VERSION>

- uses: docker/build-push-action@<VERSION>
  with:
    context: .
    push: true
    tags: <REGISTRY>/<APP>:${{ github.sha }}
    cache-from: type=registry,ref=<REGISTRY>/<APP>:cache
    cache-to: type=registry,ref=<REGISTRY>/<APP>:cache,mode=max
```

### 3. **Build Cache Mount**
```dockerfile
# Dockerfile — BuildKit cache mount
FROM rust:1.75 AS builder
WORKDIR /app
COPY . .
# make the Cargo target dir a cache mount
RUN --mount=type=cache,target=/app/target \
    --mount=type=cache,target=/usr/local/cargo/registry \
    cargo build --release
```

→ First build 5 min, second build (cache hit) 30 seconds.

### 4. **Parallel Matrix**
```yaml
strategy:
  matrix:
    test-suite: [unit, integration, e2e]
    node-version: ['18', '20']
  fail-fast: true   # stop if one branch breaks
jobs:
  test:
    steps:
      - run: npm test -- --suite=${{ matrix.test-suite }}
```

→ 6 parallel jobs × 2 min = 2 min (instead of 12 min sequential).

### 5. **Test Sharding**
```yaml
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: pytest --shard=${{ matrix.shard }}/4
```

→ 4 parallel runners, test time /4.

```javascript
// Jest sharding
{
  "scripts": {
    "test:shard1": "jest --shard=1/4",
    "test:shard2": "jest --shard=2/4"
  }
}
```

### 6. **Selective Testing**
```yaml
- name: Detect changed paths
  uses: dorny/paths-filter@<VERSION>
  id: changes
  with:
    filters: |
      backend:
        - 'backend/**'
      frontend:
        - 'frontend/**'

- name: Test backend
  if: steps.changes.outputs.backend == 'true'
  run: cd backend && npm test

- name: Test frontend
  if: steps.changes.outputs.frontend == 'true'
  run: cd frontend && npm test
```

> 🔑 **Test only the affected path.** PR only changed docs → no test.

### Nx / Turborepo affected
```bash
# Nx
nx affected:test --base=main --head=HEAD

# Turborepo
turbo run test --filter=...[origin/main]
```

### 7. **Faster Runners**
```yaml
runs-on: ubuntu-latest        # 2 vCPU, 7 GB
# vs
runs-on: ubuntu-latest-4-cores   # GitHub larger runner: 4 vCPU
runs-on: ubuntu-latest-16-cores  # 16 vCPU, premium
```

### 8. **Self-Hosted Runners**
- Cloud larger runner > self-hosted maintenance
- But for specific needs (GPU, special hardware) go self-hosted
- Ephemeral runner pattern: a fresh VM for each job

```yaml
runs-on: [self-hosted, linux, x64, gpu]
```

### 9. **Artifact Optimization**
```yaml
# ❌ Slow: upload the entire node_modules
- uses: actions/upload-artifact@<VERSION>
  with:
    path: ./

# ✅ Only what's needed
- uses: actions/upload-artifact@<VERSION>
  with:
    name: build-output
    path: |
      dist/
      build/
    retention-days: 7
    compression-level: 6
```

### 10. **Test pyramid optimization**
- **Unit** many (fast, parallel)
- **Integration** medium
- **E2E** few (slow, for critical paths)

```
       /\
      /E2E\         <-- 5-10 tests, only on main
     /------\
    /Integration\  <-- 50 tests, on the PR
   /------------\
  /     Unit     \  <-- 500+ tests, every PR
 /----------------\
```

---

## 🔬 Anti-Pattern Hunt

### `apt-get install` in every job
```yaml
# ❌ 1 min of apt in every job
- run: apt-get install -y curl jq

# ✅ Custom Docker image
container: <REGISTRY>/ci-base:latest
```

### Running all tests even on `main`
```yaml
# ✅ E2E only on main
- run: npm run test:e2e
  if: github.ref == 'refs/heads/main'
```

### Image pull in every job
```yaml
# ❌ 5 jobs pull the same image
container: node:20

# ✅ First job pulls, artifact cache
- uses: actions/cache@<VERSION>
  with:
    path: /tmp/docker-cache
    key: docker-${{ hashFiles('Dockerfile') }}
```

---

## ⚙️ Advanced Techniques

### Conditional matrix expansion
```yaml
strategy:
  matrix:
    test-type: [unit]
    include:
      - test-type: integration
        if: github.event_name == 'pull_request' && github.base_ref == 'main'
```

### Composite Action (reuse)
```yaml
# .github/actions/setup/action.yml
runs:
  using: "composite"
  steps:
    - uses: actions/checkout@<VERSION>
    - uses: actions/setup-node@<VERSION>
      with: {node-version: '20', cache: 'npm'}
    - run: npm ci
      shell: bash
```

```yaml
# .github/workflows/ci.yml
jobs:
  build:
    steps:
      - uses: ./.github/actions/setup
      - run: npm run build
```

### Reusable Workflow
```yaml
# .github/workflows/reusable-test.yml
on:
  workflow_call:
    inputs:
      shard: {required: true, type: number}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: pytest --shard=${{ inputs.shard }}/4
```

```yaml
# Caller
jobs:
  test-shard-1:
    uses: ./.github/workflows/reusable-test.yml
    with: {shard: 1}
  # ...
```

### Buildkit remote cache
```yaml
- uses: docker/build-push-action@<VERSION>
  with:
    cache-from: |
      type=gha,scope=${{ github.workflow }}
      type=registry,ref=<REGISTRY>/<APP>:cache
    cache-to: |
      type=gha,scope=${{ github.workflow }},mode=max
      type=registry,ref=<REGISTRY>/<APP>:cache,mode=max
```

---

## 📊 Realistic Performance Targets

| Pipeline stage | Target |
|---|---|
| **Checkout** | < 5s |
| **Setup (lang + deps)** | < 30s (cached) |
| **Lint + format** | < 30s |
| **Unit test** | < 60s |
| **SAST + SCA** | < 90s |
| **Build artifact** | < 120s |
| **Integration test (selective)** | < 180s |
| **Total PR pipeline** | **< 5 min** |

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| No cache | 2-3 min dep install every job | `cache: true` for every language |
| All tests on every PR | Slow feedback | Selective + sharding |
| Sequential matrix | Lost parallel gains | Parallel via `matrix:` |
| Thinking `runs-on: ubuntu-latest` is already enough | 2 vCPU bottleneck | Larger runner for critical jobs |
| No Docker layer cache | Image rebuild 5+ min | BuildKit cache-from/to |
| `apt-get install` every job | 1 min × N jobs | Custom CI image |
| E2E on every PR | 15+ min | Only on main or nightly |
| Artifact uncompressed + long retention | Storage cost, slow download | Compress + 7-day retention |
| Workflow duplication | Maintenance hell | Reusable workflow / composite action |
| `fail-fast: false` always | One branch broke, you're still waiting 12 min | `fail-fast: true` (false for debugging) |
| Deep-cloning git history in CI | Slow checkout | `fetch-depth: 1` |
| Always uploading test report HTML | Only needed on failure | Conditional upload via `if: failure()` |

---

## 📋 Pipeline Performance Checklist

```
[ ] CI < 5 min (PR pipeline)
[ ] Cache: dependencies (npm/pip/go/maven)
[ ] Cache: Docker layer (BuildKit)
[ ] Selective testing (changed paths)
[ ] Test sharding (4+ shards for large suites)
[ ] Parallel matrix (test types, envs)
[ ] Larger runner (for critical jobs)
[ ] Composite action / Reusable workflow
[ ] Custom CI image (no apt-get spam)
[ ] Artifact: compress + 7-day retention
[ ] E2E only on main
[ ] `fetch-depth: 1` checkout
[ ] CI metric dashboard (avg duration trend)
[ ] Quarterly: pipeline review (what's slowing down?)
[ ] Pre-commit hooks (lint locally)
[ ] Cancel-in-progress: cancel the old one when a new commit lands
```

---

## 📚 References

- **GitHub Actions Performance** — github.com/actions/runner-images
- **BuildKit Cache** — docs.docker.com/build/cache/
- **Nx Affected** — nx.dev
- **Turborepo Caching** — turbo.build/repo/docs/core-concepts/caching
- **Pre-commit** — pre-commit.com
- [`Pipeline-Patterns.md`](Pipeline-Patterns.md)
- [`01-Git-Workflow/Trunk-Based-Development.md`](../01-Git-Workflow/Trunk-Based-Development.md) — a prerequisite for fast CI

---

> *"Fast CI isn't a 'luxury,' it's **discipline**. A team that gets used to
> slow CI loses its 'small PR' culture; a team that loses small PRs loses
> its **quality-control mechanism**."*
