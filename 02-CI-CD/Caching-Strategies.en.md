---
description: "CI/CD cache layers guide: dependency, build, Docker layer, and test result cache strategies with concrete config examples — brings the pipeline down to minutes."
tags:
  - CI/CD
  - Performance
  - Docker
  - Containers
---
# Caching Strategies — Build, Test, Deploy Cache

> *"Cache hit 0% means 'we're just starting out.' In production CI,
> cache hit should be 80%+. A **cache strategy** turns a 30 min
> pipeline into a 3 min one."*

This guide covers the different cache layers in CI/CD — dependency,
build, Docker layer, test result — with strategy and concrete config.

---

## 🪜 Cache Layers

```
[Source Code]
    │
    ▼
[1. Dependency Cache]    ← npm, pip, go, cargo, maven
    │
    ▼
[2. Build Cache]          ← compile output (target/, dist/, .next/)
    │
    ▼
[3. Docker Layer Cache]   ← BuildKit, registry cache
    │
    ▼
[4. Test Cache]           ← Jest, Go test cache, etc.
    │
    ▼
[5. Artifact Cache]       ← release artifact, internal package
```

---

## 🔧 1️⃣ Dependency Cache

### Node.js (npm / yarn / pnpm)
```yaml
- uses: actions/setup-node@<VERSION>
  with:
    node-version: '22'
    cache: 'npm'   # automatic
    # Or:
    # cache: 'yarn'
    # cache: 'pnpm'
```

Manual:
```yaml
- uses: actions/cache@<VERSION>
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-npm-
```

### Python (pip / poetry / uv)
```yaml
- uses: actions/setup-python@<VERSION>
  with:
    python-version: '3.12'
    cache: 'pip'
```

### Go
```yaml
- uses: actions/setup-go@<VERSION>
  with:
    go-version: '1.23'
    cache: true
```

Manual:
```yaml
- uses: actions/cache@<VERSION>
  with:
    path: |
      ~/.cache/go-build
      ~/go/pkg/mod
    key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
```

### Rust (Cargo)
```yaml
- uses: Swatinem/rust-cache@<VERSION>
```

Manual:
```yaml
- uses: actions/cache@<VERSION>
  with:
    path: |
      ~/.cargo/registry
      ~/.cargo/git
      target/
    key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}
```

### Maven / Gradle
```yaml
- uses: actions/cache@<VERSION>
  with:
    path: ~/.m2/repository
    key: ${{ runner.os }}-maven-${{ hashFiles('**/pom.xml') }}
```

---

## 🏗️ 2️⃣ Build Cache

### Webpack / Next.js
```yaml
- uses: actions/cache@<VERSION>
  with:
    path: |
      .next/cache
      ~/.cache/webpack
    key: ${{ runner.os }}-build-${{ hashFiles('**/package-lock.json') }}-${{ hashFiles('src/**') }}
    restore-keys: |
      ${{ runner.os }}-build-${{ hashFiles('**/package-lock.json') }}-
      ${{ runner.os }}-build-
```

### Turborepo
```yaml
- uses: actions/cache@<VERSION>
  with:
    path: .turbo
    key: ${{ runner.os }}-turbo-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-turbo-
```

> 🔑 **Turborepo remote cache** in S3 → shared by all developers + CI.

### Nx
```yaml
- run: npx nx affected --target=test --base=main
  env:
    NX_CACHE_DIRECTORY: ${{ github.workspace }}/.nx
```

### Bazel
```yaml
- uses: actions/cache@<VERSION>
  with:
    path: |
      ~/.cache/bazel
      ~/.cache/bazelisk
    key: ${{ runner.os }}-bazel-${{ hashFiles('WORKSPACE', '**/BUILD.bazel') }}
```

---

## 🐳 3️⃣ Docker Layer Cache (BuildKit)

### GitHub Actions cache backend
```yaml
- uses: docker/setup-buildx-action@<VERSION>

- uses: docker/build-push-action@<VERSION>
  with:
    context: .
    push: true
    tags: <REGISTRY>/<APP>:${{ github.sha }}
    cache-from: type=gha,scope=${{ github.workflow }}
    cache-to: type=gha,scope=${{ github.workflow }},mode=max
```

### Registry-backed cache (shared)
```yaml
- uses: docker/build-push-action@<VERSION>
  with:
    cache-from: type=registry,ref=<REGISTRY>/<APP>:cache
    cache-to: type=registry,ref=<REGISTRY>/<APP>:cache,mode=max
```

→ Multiple CI / dev machines share the same cache.

### Inline cache
```yaml
- uses: docker/build-push-action@<VERSION>
  with:
    push: true
    tags: <REGISTRY>/<APP>:latest
    cache-from: type=registry,ref=<REGISTRY>/<APP>:latest
    cache-to: type=inline   # cache embedded inside the image
```

→ Cache embedded inside the image; simple, but image size grows.

### BuildKit cache mount (inside the Dockerfile)
```dockerfile
FROM rust:1.75 AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
# Cargo target + registry cache
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo fetch

COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo build --release && \
    cp target/release/myapp /myapp
```

→ First build 5 min, second build (code changed) 30 sec.

---

## 🧪 4️⃣ Test Cache

### Jest (built-in)
```yaml
- uses: actions/cache@<VERSION>
  with:
    path: /tmp/jest_rs
    key: ${{ runner.os }}-jest-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-jest-
```

### Go test cache
```yaml
- run: go test -count=1 ./...
  # -count=1 disables cache; in production, only test the affected path
```

### Pytest cache
```yaml
- uses: actions/cache@<VERSION>
  with:
    path: .pytest_cache
    key: ${{ runner.os }}-pytest-${{ hashFiles('**/conftest.py', '**/pytest.ini') }}
```

### Selective test (not a test cache, but speeds things up)
```bash
# Nx
npx nx affected --target=test --base=main

# Turborepo
turbo run test --filter=...[origin/main]

# Bazel
bazel test --test_strategy=remote //... --target=//apps/payments:test
```

---

## 🚀 5️⃣ Artifact Cache

### Internal package registry (Verdaccio, Nexus, Artifactory)
```yaml
# .npmrc
registry=https://npm.<INTERNAL>.com
//npm.<INTERNAL>.com/:_authToken=${NPM_TOKEN}
```

→ Build still works even if npmjs.org is down + it's faster.

### Container registry mirror
```yaml
# /etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
  endpoint = ["https://mirror.<INTERNAL>.com"]
```

→ Docker Hub rate limit + supply chain attack protection.

---

## 📐 Cache Key Strategy

### Good key
```
${{ runner.os }}-${{ matrix.node }}-deps-${{ hashFiles('**/package-lock.json') }}
```
- **OS** included (linux ≠ macos cache)
- **Version** included (Node 18 ≠ 22)
- **Lockfile hash** → correct invalidation

### Bad key
```
deps-cache   # OS-independent, version-independent, hash-independent → collision
```

### Restore-keys (fallback)
```yaml
key: ${{ runner.os }}-deps-${{ hashFiles('package-lock.json') }}
restore-keys: |
  ${{ runner.os }}-deps-       # partial if no exact match
```

---

## 📊 Measuring Cache Effectiveness

### Cache hit rate
```bash
# GitHub Actions log
"Cache restored from key: ..."   # hit
"Cache not found for input keys: ..."   # miss
```

### Target
- Dependency cache: **90%+ hit**
- Docker layer cache: **70%+ hit**
- Build cache: **50%+ hit**

### Quarterly review
- The cache that misses most often → review the key strategy
- Cache size trend (clean up if 10+ GB)
- TTL vs invalidation rate

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| No cache | Every build spends 5+ min on dep install | `cache: true` for every language |
| Static cache key | Never invalidates | `hashFiles(...)` |
| No restore-keys | First build is a cache miss | Fallback partial match |
| OS-independent key | Cross-OS contamination | Include `${{ runner.os }}` |
| No per-branch cache | Main + branch collide | With `${{ github.ref_name }}` |
| BuildKit cache mode `min` | Only the final layer | `mode=max` (all intermediates) |
| Unlimited cache size | 50+ GB of artifacts pile up | Periodic cleanup + size limit |
| Sensitive data in the cache | Compromise → secret leak | Don't write secrets to the cache |
| Mixed multi-arch build cache | amd64 / arm64 collide | Per-platform cache |
| `actions/cache@v1` (old) | Bug + slow | Latest pinned SHA |
| Test cache in prod | Stale result | `-count=1` or disable cache |

---

## 📋 Cache Strategy Checklist

```
[ ] Dependency cache: for every language/framework
[ ] Docker layer cache: BuildKit GHA / registry
[ ] Cache key: OS + version + lockfile hash
[ ] Restore-keys: partial match fallback
[ ] BuildKit cache-to: mode=max
[ ] Cache mount Dockerfile (Cargo, Go target)
[ ] Internal package registry mirror
[ ] Container registry mirror
[ ] Selective testing (Nx / Turbo affected)
[ ] Cache hit rate dashboard
[ ] Quarterly: cache effectiveness review
[ ] Cache size limit + cleanup
[ ] No secret data goes into the cache
[ ] Per-platform multi-arch cache
```

---

## 📚 References

- **actions/cache** — github.com/actions/cache
- **BuildKit Cache** — docs.docker.com/build/cache
- **Turborepo Caching** — turbo.build/repo/docs/core-concepts/caching
- **Nx Affected** — nx.dev
- [`Pipeline-Performance.md`](Pipeline-Performance.md)
- [`GitHub-Actions-Recipes.md`](GitHub-Actions-Recipes.md)
- [`GitLab-CI-Recipes.md`](GitLab-CI-Recipes.md)

---

> *"Cache isn't 'optional optimization' — it's **CI's core discipline**.
> A team running at 30% cache hit writes a Saturday-night 'pipeline is slow'
> postmortem; a team at 90% **goes home early**."*
