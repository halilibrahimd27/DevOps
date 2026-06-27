---
description: "CI pipeline optimizasyonu: caching, parallelization, selective testing ve runner secimi teknikleriyle 30 dakikalik CI'yi 90 saniyeye indirme protokolu."
---
# Pipeline Performance — "10 Dakikalık CI"yi 90 Saniyeye İndir

> *"CI 30 dakika sürüyorsa, mühendislerin yarısı PR açtıktan
> sonra **başka iş yapıyor**. Bu, dün yatırdığınız zamanın değil,
> **bugün kaybettiğiniz** zamanın hikâyesi."*

Bu rehber CI pipeline'ı optimize etmenin somut tekniklerini —
caching, parallelization, selective testing, runner choice —
"30 dakika → 90 saniye" hedefiyle anlatır.

---

## 🎯 Niye Önemli?

| CI süresi | Etki |
|---|---|
| > 30 dk | Trunk-based imkansız, dev'ler bekliyor |
| 10-30 dk | Acılı, bekleme + context switch |
| 5-10 dk | Tolere edilebilir |
| 2-5 dk | Sweet spot |
| < 2 dk | Mükemmel (tight feedback loop) |

**Hedef (2026 yüksek-performans ekipler)**: PR pipeline **< 5 dk**.

---

## 📐 Önce Ölç — Profil Çıkar

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
      
      # ... her adım için echo ile süre kaydet
```

Daha pragmatik: **GitHub Actions** zaten süre verir. **Buildkite/CircleCI** UI'lar süre dökümü gösterir.

### Tipik bottleneck'ler
1. **Image pull** (ubuntu-latest 30s+)
2. **Dependency install** (`npm ci` 2-3 dk)
3. **Build** (Webpack, Maven, Cargo)
4. **Test** (özellikle E2E/integration)
5. **Artifact upload/download**

---

## 🚀 Hız Kazandırıcı 10 Teknik

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
# Cargo target dir'ini cache mount yap
RUN --mount=type=cache,target=/app/target \
    --mount=type=cache,target=/usr/local/cargo/registry \
    cargo build --release
```

→ İlk build 5 dk, ikinci build (cache hit) 30 saniye.

### 4. **Parallel Matrix**
```yaml
strategy:
  matrix:
    test-suite: [unit, integration, e2e]
    node-version: ['18', '20']
  fail-fast: true   # bir dal kırılırsa durdur
jobs:
  test:
    steps:
      - run: npm test -- --suite=${{ matrix.test-suite }}
```

→ 6 paralel job × 2 dk = 2 dk (sıralı 12 dk yerine).

### 5. **Test Sharding**
```yaml
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: pytest --shard=${{ matrix.shard }}/4
```

→ 4 paralel runner, test süresi /4.

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

> 🔑 **Sadece etkilenen path için test.** PR sadece docs değiştirmiş → test yok.

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
- Ama spesifik ihtiyaçlar (GPU, special hardware) için self-hosted
- Ephemeral runner pattern: her job için fresh VM

```yaml
runs-on: [self-hosted, linux, x64, gpu]
```

### 9. **Artifact Optimization**
```yaml
# ❌ Yavaş: tüm node_modules upload
- uses: actions/upload-artifact@<VERSION>
  with:
    path: ./

# ✅ Sadece gerekenler
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
- **Unit** çok (hızlı, paralel)
- **Integration** orta
- **E2E** az (yavaş, kritik path için)

```
       /\
      /E2E\         <-- 5-10 test, sadece main'de
     /------\
    /Integration\  <-- 50 test, PR'da
   /------------\
  /     Unit     \  <-- 500+ test, her PR
 /----------------\
```

---

## 🔬 Anti-Pattern Hunt

### `apt-get install` her job'da
```yaml
# ❌ Her job 1 dk apt
- run: apt-get install -y curl jq

# ✅ Custom Docker image
container: <REGISTRY>/ci-base:latest
```

### Tüm test'leri `main`'de bile çalıştır
```yaml
# ✅ E2E sadece main'de
- run: npm run test:e2e
  if: github.ref == 'refs/heads/main'
```

### Image pull her job'da
```yaml
# ❌ Aynı imajı 5 job pull eder
container: node:20

# ✅ İlk job pull, artifact cache
- uses: actions/cache@<VERSION>
  with:
    path: /tmp/docker-cache
    key: docker-${{ hashFiles('Dockerfile') }}
```

---

## ⚙️ İleri Teknikler

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

| Pipeline aşaması | Hedef |
|---|---|
| **Checkout** | < 5s |
| **Setup (lang + deps)** | < 30s (cached) |
| **Lint + format** | < 30s |
| **Unit test** | < 60s |
| **SAST + SCA** | < 90s |
| **Build artifact** | < 120s |
| **Integration test (selective)** | < 180s |
| **Total PR pipeline** | **< 5 dk** |

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Cache yok | Her job 2-3 dk dep install | `cache: true` her dil için |
| Tüm test her PR'da | Yavaş feedback | Selective + sharding |
| Sequential matrix | Paralel kazanım kayıp | `matrix:` ile paralel |
| `runs-on: ubuntu-latest` zaten yetiyor düşünce | 2 vCPU bottleneck | Larger runner kritik job için |
| Docker layer cache yok | Image rebuild 5+ dk | BuildKit cache-from/to |
| `apt-get install` her job | 1 dk × N job | Custom CI image |
| E2E her PR'da | 15+ dk | Sadece main veya gece |
| Artifact uncompressed + uzun retention | Storage maliyet, indir yavaş | Compress + 7 gün retention |
| Workflow tekrarı | Maintenance hell | Reusable workflow / composite action |
| `fail-fast: false` her zaman | Bir dal kırıldı, hâlâ 12 dk bekliyorsun | `fail-fast: true` (debug için false) |
| CI'da git history derin clone | Yavaş checkout | `fetch-depth: 1` |
| Test report HTML upload her zaman | İhtiyaç sadece fail'de | `if: failure()` ile koşullu upload |

---

## 📋 Pipeline Performance Checklist

```
[ ] CI < 5 dk (PR pipeline)
[ ] Cache: dependencies (npm/pip/go/maven)
[ ] Cache: Docker layer (BuildKit)
[ ] Selective testing (changed paths)
[ ] Test sharding (4+ shard büyük suite'lerde)
[ ] Parallel matrix (test types, env'ler)
[ ] Larger runner (kritik job'lar için)
[ ] Composite action / Reusable workflow
[ ] Custom CI image (apt-get spam yok)
[ ] Artifact: compress + retention 7 gün
[ ] E2E sadece main'de
[ ] `fetch-depth: 1` checkout
[ ] CI metric dashboard (avg duration trend)
[ ] Quarterly: pipeline review (yavaşlayan ne?)
[ ] Pre-commit hooks (lint local'de)
[ ] Cancel-in-progress: yeni commit gelince eski iptal
```

---

## 📚 Referanslar

- **GitHub Actions Performance** — github.com/actions/runner-images
- **BuildKit Cache** — docs.docker.com/build/cache/
- **Nx Affected** — nx.dev
- **Turborepo Caching** — turbo.build/repo/docs/core-concepts/caching
- **Pre-commit** — pre-commit.com
- [`Pipeline-Patterns.md`](Pipeline-Patterns.md)
- [`01-Git-Workflow/Trunk-Based-Development.md`](../01-Git-Workflow/Trunk-Based-Development.md) — fast CI ön koşulu

---

> *"Hızlı CI 'lüks' değil, **disiplin**. Yavaş CI'ya alışan ekip,
> 'küçük PR' kültürünü kaybeder; küçük PR kaybeden ekip, **kalite
> kontrol mekanizmasını** kaybeder."*
