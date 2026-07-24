---
description: "BuildKit's modern Docker build features: cache mount, secret mount, multi-platform, and frontend syntax. Explained with concrete Dockerfile examples."
tags:
  - Containers
  - Docker
  - Performance
  - Secrets
---
# BuildKit Tips — Modern Docker Build

> *"BuildKit has existed since Docker 18.09, and became default in 2024.
> A team still building with `DOCKER_BUILDKIT=0` — no **parallel stages**,
> no **cache mount**, no **secret mount** — ships images that are
> **3x slower** to build and **2x bigger**."*

This guide walks through BuildKit's modern features — cache mount, secret
mount, multi-platform, frontend syntax — with concrete Dockerfile examples.

---

## 🎯 What Is BuildKit?

> **BuildKit**: Docker's next-generation image build engine.
> Faster, parallel, secure.

### Legacy Docker build vs BuildKit

| Feature | Legacy | BuildKit |
|---|---|---|
| Parallel stages | ❌ | ✅ |
| Cache mount | ❌ | ✅ |
| Secret mount (no leak) | ❌ | ✅ |
| Multi-platform | Manual | ✅ Native |
| SBOM generation | ❌ | ✅ |
| Provenance | ❌ | ✅ |
| Frontend syntax | Single (Dockerfile) | Pluggable (Dockerfile, Bazel, Buildpacks) |

### Enable
```bash
# Single build
DOCKER_BUILDKIT=1 docker build -t app .

# Daemon-wide (default on Docker 23+)
echo '{"features": {"buildkit": true}}' > /etc/docker/daemon.json

# buildx (multi-platform)
docker buildx create --use
```

---

## 🚀 1️⃣ Cache Mount

> Cache used during the build, without entering the layer.

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

> 🔑 **Cache mount doesn't enter the image layer** — it's only used during the build. Image size is unaffected.

---

## 🔐 2️⃣ Secret Mount (Build-Time)

> Use the secret during the build, **don't let it stay in the layer**.

### CLI side
```bash
echo "$NPM_TOKEN" > /tmp/npm_token
docker buildx build --secret id=npm,src=/tmp/npm_token .
```

### Dockerfile side
```dockerfile
RUN --mount=type=secret,id=npm \
    cat /run/secrets/npm | npm config set //registry.npmjs.org/:_authToken=$(cat) && \
    npm ci

# Or with ENV
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

> 🔑 **The secret isn't in history**, isn't in the layer, isn't in the image. **Only present at build runtime**.

---

## 🌐 3️⃣ SSH Mount (Private Repo)

```bash
docker buildx build --ssh default .
```

```dockerfile
RUN --mount=type=ssh \
    git clone git@github.com:<ORG>/<PRIVATE_REPO>.git
```

→ Uses the host's SSH agent; the private key is never in the image.

---

## 📦 4️⃣ Bind Mount (Read-Only Source)

```dockerfile
RUN --mount=type=bind,source=secrets,target=/secrets \
    process-secrets-file /secrets/api.key
```

→ The source `secrets/` folder is mounted read-only; it's never copied into the image.

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
# Use TARGETPLATFORM for cross-compilation
FROM --platform=$BUILDPLATFORM golang:1.23 AS builder
ARG TARGETOS TARGETARCH
WORKDIR /src
COPY . .
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /myapp .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /myapp /myapp
ENTRYPOINT ["/myapp"]
```

> 🔑 **Cross-compilation beats QEMU emulation**: 10x faster multi-arch builds.

---

## 📊 6️⃣ SBOM + Provenance

```bash
docker buildx build \
  --sbom=true \
  --provenance=mode=max \
  -t <REGISTRY>/<APP>:<TAG> \
  --push .
```

→ SBOM (CycloneDX) + SLSA provenance are attached to the image as attestations.

```bash
# Verify
docker buildx imagetools inspect <REGISTRY>/<APP>:<TAG> --format '{{json .SBOM}}'
docker buildx imagetools inspect <REGISTRY>/<APP>:<TAG> --format '{{json .Provenance}}'
```

---

## 🔁 7️⃣ Cache Backends

### inline (cache inside the image)
```bash
docker buildx build \
  --cache-to type=inline \
  -t <REGISTRY>/<APP>:latest --push .
```

→ Embeds the cache inside the image; simple, but the image size grows.

### registry (shared)
```bash
docker buildx build \
  --cache-from type=registry,ref=<REGISTRY>/<APP>:cache \
  --cache-to type=registry,ref=<REGISTRY>/<APP>:cache,mode=max \
  -t <REGISTRY>/<APP>:<TAG> --push .
```

→ Cache lives under a separate tag; shared between CI and dev.

### gha (GitHub Actions cache)
```yaml
- uses: docker/build-push-action@<VERSION>
  with:
    cache-from: type=gha,scope=${{ github.workflow }}
    cache-to: type=gha,scope=${{ github.workflow }},mode=max
```

→ Native GitHub Actions cache (10 GB free quota per repo).

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

→ The Dockerfile parser's version. **`1.7+`** brings heredoc, parameterized COPY, and more.

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

### Verbose build log
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

### `BUILDKIT_INLINE_CACHE` (older Docker)
```dockerfile
# For inline cache on older Docker daemons
ARG BUILDKIT_INLINE_CACHE=1
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| Not using cache mount | Every build does a full re-fetch | `--mount=type=cache` |
| Secret in a build arg | Stays in the layer | `--mount=type=secret` |
| No multi-platform | Won't run on an ARM cluster | `buildx --platform` |
| QEMU instead of cross-compile | 10x slower | Cross-compile via TARGETOS / TARGETARCH |
| BuildKit disabled | No parallelism, no cache | DOCKER_BUILDKIT=1 (default on 23+) |
| No `Dockerfile` syntax declaration | Newer features unavailable | `# syntax=docker/dockerfile:1.7` |
| Cache-to `mode=min` | Only the final layer | `mode=max` |
| Always using inline cache | Image bloat | Registry cache (in CI) |
| No SBOM | Supply chain stays unknown | `--sbom=true` |
| No cache for `RUN apt-get` | Apt download repeats every time | `--mount=type=cache,target=/var/cache/apt` |

---

## 📋 BuildKit Production Checklist

```
[ ] BuildKit enabled (DOCKER_BUILDKIT=1)
[ ] Dockerfile: `# syntax=docker/dockerfile:1.7`
[ ] Cache mount: deps cache (cargo/go/npm/maven/apt)
[ ] Secret mount: build-time secret
[ ] Multi-platform: linux/amd64 + linux/arm64
[ ] Cross-compile (TARGETPLATFORM)
[ ] Cache backend: registry or gha
[ ] mode=max (full cache)
[ ] SBOM: --sbom=true
[ ] Provenance: --provenance=mode=max
[ ] Multi-stage build
[ ] BuildKit driver: docker-container (advanced)
[ ] CI: cache hit rate dashboard
```

---

## 📚 References

- **BuildKit** — github.com/moby/buildkit
- **Dockerfile Syntax** — docs.docker.com/reference/dockerfile/
- **buildx** — github.com/docker/buildx
- **BuildKit Frontends** — github.com/moby/buildkit#exploring-llb
- [`Multi-Stage-Builds.md`](Multi-Stage-Builds.md)
- [`Distroless-and-Chainguard.md`](Distroless-and-Chainguard.md)
- [`Dockerfile-Best-Practices.md`](Dockerfile-Best-Practices.md)
- [`02-CI-CD/Caching-Strategies.md`](../02-CI-CD/Caching-Strategies.md)

---

> *"BuildKit isn't an 'optional optimization' — it **is** modern Docker
> build. A team that skips cache mount, multi-platform, and secret mount
> is still running **2018's Docker**."*
