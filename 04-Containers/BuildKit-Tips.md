---
description: "BuildKit'in modern Docker build feature'lari: cache mount, secret mount, multi-platform ve frontend syntax. Somut Dockerfile ornekleriyle anlatim."
tags:
  - Containers
  - Docker
  - Performance
  - Secrets
---
# BuildKit Tips — Modern Docker Build

> *"Docker 18.09'tan beri BuildKit var, 2024'te default. Hâlâ
> `DOCKER_BUILDKIT=0` ile build yapan ekip, **paralel stage**,
> **cache mount**, **secret mount** olmadan **3x yavaş** + **2x
> büyük** image üretir."*

Bu rehber BuildKit'in modern feature'larını — cache mount, secret mount,
multi-platform, frontend syntax — somut Dockerfile örnekleriyle anlatır.

---

## 🎯 BuildKit Nedir?

> **BuildKit**: Docker'ın yeni nesil image build engine.
> Daha hızlı, paralel, secure.

### Eski Docker build vs BuildKit

| Özellik | Legacy | BuildKit |
|---|---|---|
| Paralel stages | ❌ | ✅ |
| Cache mount | ❌ | ✅ |
| Secret mount (no leak) | ❌ | ✅ |
| Multi-platform | Manuel | ✅ Native |
| SBOM generation | ❌ | ✅ |
| Provenance | ❌ | ✅ |
| Frontend syntax | Tek (Dockerfile) | Pluggable (Dockerfile, Bazel, Buildpacks) |

### Enable
```bash
# Tek build
DOCKER_BUILDKIT=1 docker build -t app .

# Daemon-wide (default Docker 23+)
echo '{"features": {"buildkit": true}}' > /etc/docker/daemon.json

# buildx (multi-platform)
docker buildx create --use
```

---

## 🚀 1️⃣ Cache Mount

> Layer'a girmeden, build sırasında kullanılan cache.

### Cargo (Rust)
```dockerfile
# syntax=docker/dockerfile:1.7

FROM rust:1.75 AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo fetch

COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo build --release && \
    cp target/release/myapp /myapp
```

### Go modules
```dockerfile
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    go build -o /myapp .
```

### npm
```dockerfile
RUN --mount=type=cache,target=/root/.npm \
    npm ci
```

### Maven
```dockerfile
RUN --mount=type=cache,target=/root/.m2 \
    mvn package -DskipTests
```

### apt
```dockerfile
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get install -y curl
```

> 🔑 **Cache mount image layer'a girmez** — sadece build sırasında kullanılır. Image size etkilenmez.

---

## 🔐 2️⃣ Secret Mount (Build-Time)

> Secret'ı build sırasında kullan, **layer'da kalmasın**.

### CLI tarafı
```bash
echo "$NPM_TOKEN" > /tmp/npm_token
docker buildx build --secret id=npm,src=/tmp/npm_token .
```

### Dockerfile tarafı
```dockerfile
RUN --mount=type=secret,id=npm \
    cat /run/secrets/npm | npm config set //registry.npmjs.org/:_authToken=$(cat) && \
    npm ci

# Veya ENV ile
RUN --mount=type=secret,id=npm \
    NPM_TOKEN=$(cat /run/secrets/npm) npm ci
```

### GitHub Actions
```yaml
- uses: docker/build-push-action@<VERSION>
  with:
    secrets: |
      "npm=${{ secrets.NPM_TOKEN }}"
```

> 🔑 **Secret history'de yok**, layer'da yok, image'da yok. **Sadece build runtime'da**.

---

## 🌐 3️⃣ SSH Mount (Private Repo)

```bash
docker buildx build --ssh default .
```

```dockerfile
RUN --mount=type=ssh \
    git clone git@github.com:<ORG>/<PRIVATE_REPO>.git
```

→ Host'un SSH agent'ı kullanılır, private key image'da yok.

---

## 📦 4️⃣ Bind Mount (Read-Only Source)

```dockerfile
RUN --mount=type=bind,source=secrets,target=/secrets \
    process-secrets-file /secrets/api.key
```

→ Kaynak `secrets/` klasörü read-only mount; image'a kopyalanmaz.

---

## 🌍 5️⃣ Multi-Platform Build

```bash
docker buildx create --use --name multibuild
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t <REGISTRY>/<APP>:<TAG> \
  --push .
```

```dockerfile
# Cross-compile için TARGETPLATFORM kullan
FROM --platform=$BUILDPLATFORM golang:1.23 AS builder
ARG TARGETOS TARGETARCH
WORKDIR /src
COPY . .
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /myapp .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /myapp /myapp
ENTRYPOINT ["/myapp"]
```

> 🔑 **Cross-compilation > QEMU emulation**: 10x daha hızlı multi-arch build.

---

## 📊 6️⃣ SBOM + Provenance

```bash
docker buildx build \
  --sbom=true \
  --provenance=mode=max \
  -t <REGISTRY>/<APP>:<TAG> \
  --push .
```

→ SBOM (CycloneDX) + SLSA provenance image'a attestation olarak attach.

```bash
# Verify
docker buildx imagetools inspect <REGISTRY>/<APP>:<TAG> --format '{{json .SBOM}}'
docker buildx imagetools inspect <REGISTRY>/<APP>:<TAG> --format '{{json .Provenance}}'
```

---

## 🔁 7️⃣ Cache Backend'leri

### inline (image içinde cache)
```bash
docker buildx build \
  --cache-to type=inline \
  -t <REGISTRY>/<APP>:latest --push .
```

→ Image'in içine cache embed; basit ama image boyutu artar.

### registry (paylaşımlı)
```bash
docker buildx build \
  --cache-from type=registry,ref=<REGISTRY>/<APP>:cache \
  --cache-to type=registry,ref=<REGISTRY>/<APP>:cache,mode=max \
  -t <REGISTRY>/<APP>:<TAG> --push .
```

→ Cache ayrı tag'de; CI + dev paylaşır.

### gha (GitHub Actions cache)
```yaml
- uses: docker/build-push-action@<VERSION>
  with:
    cache-from: type=gha,scope=${{ github.workflow }}
    cache-to: type=gha,scope=${{ github.workflow }},mode=max
```

→ GitHub Actions native cache (10 GB free quota per repo).

### local
```bash
docker buildx build \
  --cache-from type=local,src=/tmp/cache \
  --cache-to type=local,dest=/tmp/cache,mode=max .
```

---

## 🎨 8️⃣ Frontend Syntax

```dockerfile
# syntax=docker/dockerfile:1.7
```

→ Dockerfile parser'ın versiyonu. **`1.7+`** ile heredoc, parametreli COPY, vb.

### Heredoc
```dockerfile
# syntax=docker/dockerfile:1.7
RUN <<EOF
apt-get update
apt-get install -y curl jq
rm -rf /var/lib/apt/lists/*
EOF
```

### Parameterized COPY
```dockerfile
ARG VERSION
COPY --chown=nonroot:nonroot --chmod=755 ./bin /usr/local/bin
```

### Conditional COPY
```dockerfile
COPY --from=base /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
```

---

## 🔍 9️⃣ Debugging

### Build log verbose
```bash
docker buildx build --progress=plain -t app .
```

### Inspect specific stage
```bash
docker buildx build --target=builder -t app-debug .
docker run -it app-debug sh
```

### `--no-cache` (debugging)
```bash
docker buildx build --no-cache -t app .
```

### `BUILDKIT_INLINE_CACHE` (eski Docker)
```dockerfile
# Daha eski Docker daemon'larda inline cache için
ARG BUILDKIT_INLINE_CACHE=1
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Cache mount kullanmama | Her build full re-fetch | `--mount=type=cache` |
| Secret build arg'da | Layer'da kalır | `--mount=type=secret` |
| Multi-platform yok | ARM cluster'a çalışmaz | `buildx --platform` |
| Cross-compile yerine QEMU | 10x yavaş | TARGETOS / TARGETARCH ile cross-compile |
| BuildKit kapalı | Paralel + cache yok | DOCKER_BUILDKIT=1 (varsayılan 23+) |
| `Dockerfile` syntax declare yok | Eski feature'lar yok | `# syntax=docker/dockerfile:1.7` |
| Cache-to `mode=min` | Sadece final layer | `mode=max` |
| Inline cache her zaman | Image bloat | Registry cache (CI'da) |
| SBOM yok | Supply chain bilinmez | `--sbom=true` |
| `RUN apt-get` cache yok | Apt download tekrar | `--mount=type=cache,target=/var/cache/apt` |

---

## 📋 BuildKit Production Checklist

```
[ ] BuildKit enabled (DOCKER_BUILDKIT=1)
[ ] Dockerfile: `# syntax=docker/dockerfile:1.7`
[ ] Cache mount: deps cache (cargo/go/npm/maven/apt)
[ ] Secret mount: build-time secret
[ ] Multi-platform: linux/amd64 + linux/arm64
[ ] Cross-compile (TARGETPLATFORM)
[ ] Cache backend: registry veya gha
[ ] mode=max (full cache)
[ ] SBOM: --sbom=true
[ ] Provenance: --provenance=mode=max
[ ] Multi-stage build
[ ] BuildKit driver: docker-container (advanced)
[ ] CI: cache hit rate dashboard
```

---

## 📚 Referanslar

- **BuildKit** — github.com/moby/buildkit
- **Dockerfile Syntax** — docs.docker.com/reference/dockerfile/
- **buildx** — github.com/docker/buildx
- **BuildKit Frontends** — github.com/moby/buildkit#exploring-llb
- [`Multi-Stage-Builds.md`](Multi-Stage-Builds.md)
- [`Distroless-and-Chainguard.md`](Distroless-and-Chainguard.md)
- [`Dockerfile-Best-Practices.md`](Dockerfile-Best-Practices.md)
- [`02-CI-CD/Caching-Strategies.md`](../02-CI-CD/Caching-Strategies.md)

---

> *"BuildKit 'optional optimization' değil — **modern Docker build'in
> kendisi**. Cache mount + multi-platform + secret mount kullanmayan
> ekip, **2018'in Docker'ı** ile çalışıyor demektir."*
