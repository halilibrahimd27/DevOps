---
description: "CI/CD cache katmanlari rehberi: dependency, build, Docker layer ve test result cache stratejileri somut config ornekleriyle; pipeline'i dakikalara indirir."
---
# Caching Strategies — Build, Test, Deploy Cache

> *"Cache hit %0 = 'biz yeni başlıyoruz' demek. Production CI'da
> cache hit %80+ olmalı. **Cache stratejisi**, 30 dk pipeline'ı
> 3 dk'ya indirir."*

Bu rehber CI/CD'de farklı cache katmanlarını — dependency, build,
Docker layer, test result — strateji + somut config ile anlatır.

---

## 🪜 Cache Katmanları

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
    cache: 'npm'   # otomatik
    # Veya:
    # cache: 'yarn'
    # cache: 'pnpm'
```

Manuel:
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

Manuel:
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

Manuel:
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

> 🔑 **Turborepo remote cache** S3'te → tüm developer + CI paylaşır.

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

### Registry-backed cache (paylaşımlı)
```yaml
- uses: docker/build-push-action@<VERSION>
  with:
    cache-from: type=registry,ref=<REGISTRY>/<APP>:cache
    cache-to: type=registry,ref=<REGISTRY>/<APP>:cache,mode=max
```

→ Birden fazla CI / dev makinesi aynı cache'i paylaşır.

### Inline cache
```yaml
- uses: docker/build-push-action@<VERSION>
  with:
    push: true
    tags: <REGISTRY>/<APP>:latest
    cache-from: type=registry,ref=<REGISTRY>/<APP>:latest
    cache-to: type=inline   # cache image'in içinde
```

→ Image'in içine cache embed; basit ama image boyutu artar.

### BuildKit cache mount (Dockerfile içinde)
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

→ İlk build 5 dk, ikinci build (kod değişti) 30 saniye.

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
  # -count=1 cache disable; production için sadece etkilenen path'i test
```

### Pytest cache
```yaml
- uses: actions/cache@<VERSION>
  with:
    path: .pytest_cache
    key: ${{ runner.os }}-pytest-${{ hashFiles('**/conftest.py', '**/pytest.ini') }}
```

### Selective test (test cache değil ama hızlandırır)
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

→ npmjs.org down olsa bile build çalışır + daha hızlı.

### Container registry mirror
```yaml
# /etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
  endpoint = ["https://mirror.<INTERNAL>.com"]
```

→ Docker Hub rate limit + supply chain attack koruması.

---

## 📐 Cache Key Strategy

### İyi key
```
${{ runner.os }}-${{ matrix.node }}-deps-${{ hashFiles('**/package-lock.json') }}
```
- **OS** dahil (linux ≠ macos cache)
- **Version** dahil (Node 18 ≠ 22)
- **Lockfile hash** → invalidasyon doğru

### Kötü key
```
deps-cache   # OS bağımsız, version bağımsız, hash bağımsız → çakışma
```

### Restore-keys (fallback)
```yaml
key: ${{ runner.os }}-deps-${{ hashFiles('package-lock.json') }}
restore-keys: |
  ${{ runner.os }}-deps-       # exact match yoksa partial
```

---

## 📊 Cache Effectiveness Ölçümü

### Cache hit rate
```bash
# GitHub Actions log
"Cache restored from key: ..."   # hit
"Cache not found for input keys: ..."   # miss
```

### Hedef
- Dependency cache: **%90+ hit**
- Docker layer cache: **%70+ hit**
- Build cache: **%50+ hit**

### Quarterly review
- En sık miss eden cache → key strategy gözden geçir
- Cache size trend (10+ GB ise temizle)
- TTL vs invalidation rate

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Cache yok | Her build 5+ dk dep install | `cache: true` her dil |
| Cache key static | Asla invalidate olmaz | `hashFiles(...)` |
| Restore-keys yok | İlk build cache miss | Fallback partial match |
| OS bağımsız key | Cross-OS contamination | `${{ runner.os }}` dahil |
| Branch başına cache yok | Main + branch çakışması | `${{ github.ref_name }}` ile |
| BuildKit cache mode `min` | Sadece final layer | `mode=max` (tüm intermediate) |
| Cache size sonsuz | 50+ GB artifact birikir | Periodic cleanup + size limit |
| Sensitive data cache'de | Compromise → secret leak | Cache'e secret yazma |
| Multi-arch build cache karışık | amd64 / arm64 birbirine | Per-platform cache |
| `actions/cache@v1` (eski) | Bug + slow | Latest pinned SHA |
| Test cache prod'da | Stale result | `-count=1` veya cache disable |

---

## 📋 Cache Strategy Checklist

```
[ ] Dependency cache: tüm dil/framework için
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
[ ] Secret data cache'e girmiyor
[ ] Per-platform multi-arch cache
```

---

## 📚 Referanslar

- **actions/cache** — github.com/actions/cache
- **BuildKit Cache** — docs.docker.com/build/cache
- **Turborepo Caching** — turbo.build/repo/docs/core-concepts/caching
- **Nx Affected** — nx.dev
- [`Pipeline-Performance.md`](Pipeline-Performance.md)
- [`GitHub-Actions-Recipes.md`](GitHub-Actions-Recipes.md)
- [`GitLab-CI-Recipes.md`](GitLab-CI-Recipes.md)

---

> *"Cache 'optional optimization' değil — **CI'ın temel disiplini**.
> Cache hit %30'da çalışan ekip, Saturday gece 'pipeline yavaş'
> postmortem yazar; %90'da çalışan ekip **erken gider**."*
