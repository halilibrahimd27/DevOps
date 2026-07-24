---
description: "Multi-stage Docker build patterns and anti-patterns: a guide to shrinking images 10x with builder/runner separation, language-specific examples, and cache optimization."
tags:
  - Containers
  - Docker
  - Performance
  - Security
---
# Multi-Stage Builds — Small, Secure, Fast Images

> *"Single-stage Dockerfile = build tools + runtime in the same image.
> Result: 1.5 GB image, 200 CVEs, slow pull. With **multi-stage**, the
> same app is 30 MB, 2 CVEs, pulled in 5 seconds."*

This guide covers multi-stage Docker build patterns, anti-patterns,
language-specific examples, and cache optimization.

---

## 🎯 Why Multi-Stage?

### Single-stage (bad)
```dockerfile
FROM golang:1.23
WORKDIR /app
COPY . .
RUN go build -o myapp .
CMD ["./myapp"]
```

→ Image: **~800 MB** (Go toolchain + GCC + libc + all the source).

### Multi-stage (good)
```dockerfile
# Build stage
FROM golang:1.23 AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /myapp .

# Runtime stage
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /myapp /myapp
USER nonroot:nonroot
ENTRYPOINT ["/myapp"]
```

→ Image: **~30 MB**. No build tools, just the binary.

---

## 📐 Pattern Catalog

### 1. Builder + Distroless Runtime
```dockerfile
FROM <LANG>:<VERSION> AS builder
# build...

FROM gcr.io/distroless/<TYPE>:nonroot
COPY --from=builder /artifact /artifact
USER nonroot:nonroot
ENTRYPOINT ["/artifact"]
```

### 2. Builder + Scratch (Go static binary)
```dockerfile
FROM golang:1.23 AS builder
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags='-s -w' -o /myapp .

FROM scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /myapp /myapp
USER 65534:65534
ENTRYPOINT ["/myapp"]
```

→ Scratch image is **0 bytes**; just the binary + CA bundle.

### 3. Multi-builder (parallel)
```dockerfile
FROM golang:1.23 AS go-builder
RUN go build -o /server .

FROM node:22 AS web-builder
RUN npm ci && npm run build

FROM gcr.io/distroless/nodejs22-debian12:nonroot
COPY --from=go-builder /server /server
COPY --from=web-builder /app/dist /static
USER nonroot
ENTRYPOINT ["/server"]
```

→ Go + Node build in parallel, at the same time (BuildKit).

### 4. Cache mount (BuildKit)
```dockerfile
# syntax=docker/dockerfile:1.7

FROM rust:1.75 AS builder
WORKDIR /app

# Cargo cache mount: doesn't end up in the layer, only used during the build
COPY Cargo.toml Cargo.lock ./
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo fetch

COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo build --release && \
    cp target/release/myapp /myapp

FROM gcr.io/distroless/cc-debian12:nonroot
COPY --from=builder /myapp /myapp
USER nonroot
ENTRYPOINT ["/myapp"]
```

→ First build 5 min, second build 30 seconds (cache hit).

### 5. Test stage (in CI)
```dockerfile
FROM node:22 AS deps
COPY package*.json ./
RUN npm ci

FROM deps AS test
COPY . .
RUN npm test

FROM deps AS build
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
```

```bash
# CI: run only the test stage
docker build --target=test -t app:test .
docker build -t app:latest .   # full build
```

---

## 🔧 Language-Specific Examples

### Go
```dockerfile
FROM golang:1.23 AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download   # Layer cache: skipped as long as deps haven't changed
COPY . .
RUN CGO_ENABLED=0 go build -ldflags='-s -w' -o /myapp .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /myapp /myapp
USER nonroot
ENTRYPOINT ["/myapp"]
```

### Python
```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM gcr.io/distroless/python3-debian12:nonroot
COPY --from=builder /opt/venv /opt/venv
COPY . /app
WORKDIR /app
ENV PATH="/opt/venv/bin:$PATH"
USER nonroot
ENTRYPOINT ["python", "main.py"]
```

### Node.js
```dockerfile
FROM node:22-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM gcr.io/distroless/nodejs22-debian12:nonroot
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
USER nonroot
EXPOSE 3000
CMD ["dist/server.js"]
```

### Java (Spring Boot)
```dockerfile
FROM eclipse-temurin:21-jdk-jammy AS builder
WORKDIR /src
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=builder /src/target/*.jar app.jar
USER 1000:1000
ENTRYPOINT ["java", "-jar", "app.jar"]
```

> 🔑 For Java, a custom JRE with **JLink** → image 100 MB → 50 MB.

### Rust (FFI with CGO)
```dockerfile
FROM rust:1.75 AS builder
WORKDIR /src
RUN apt-get update && apt-get install -y libssl-dev pkg-config
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf src
COPY src ./src
RUN cargo build --release

FROM gcr.io/distroless/cc-debian12:nonroot
COPY --from=builder /src/target/release/myapp /myapp
USER nonroot
ENTRYPOINT ["/myapp"]
```

---

## 📊 Image Size Comparison

| Language | Naive | Optimal multi-stage |
|---|---|---|
| Go | 800 MB | **15 MB** (scratch) |
| Rust | 1.2 GB | **20 MB** (distroless cc) |
| Python | 900 MB | **80 MB** (distroless python) |
| Node | 1 GB | **100 MB** (distroless nodejs) |
| Java | 700 MB | **180 MB** (JRE only) |

> 🔑 **80-95% reduction in most cases**.

---

## 🚀 BuildKit Features

### Parallel stages
```dockerfile
FROM alpine AS stage-a
RUN sleep 10 && echo "a" > /a

FROM alpine AS stage-b
RUN sleep 10 && echo "b" > /b

FROM alpine
COPY --from=stage-a /a /a
COPY --from=stage-b /b /b
```

→ stage-a + stage-b run **in parallel** (BuildKit).

### Cache mount types
```dockerfile
# Type: cache (build cache)
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y curl

# Type: bind (read-only, from source)
RUN --mount=type=bind,source=secrets,target=/secrets \
    process-secrets

# Type: secret (one-time, not left in the layer)
RUN --mount=type=secret,id=mytoken \
    curl -H "Authorization: Bearer $(cat /run/secrets/mytoken)" ...

# Type: ssh
RUN --mount=type=ssh \
    git clone git@github.com:<ORG>/<PRIV_REPO>.git
```

### Build arg
```dockerfile
ARG VERSION=latest
LABEL version=${VERSION}
```

```bash
docker build --build-arg VERSION=1.4.0 -t app:1.4.0 .
```

### Heredoc (Dockerfile syntax 1.4+)
```dockerfile
RUN <<EOF
apt-get update
apt-get install -y curl jq
rm -rf /var/lib/apt/lists/*
EOF
```

→ Single RUN layer, multi-line script, more readable.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| Single-stage build | Build tools end up in runtime | Multi-stage |
| `apt-get install` with no cache cleanup | Image bloat | `&& rm -rf /var/lib/apt/lists/*` |
| `COPY . .` right at the start | No cache hit | `COPY package*.json` first, `npm ci`, then `COPY .` |
| `latest` tag as base | No reproducibility | Pinned version (digest pin is even better) |
| `USER root` | RCE → close to host | `USER nonroot` |
| `RUN curl ... | bash` | Supply chain risk | Pinned version + checksum |
| Secret in a build arg | Stays in the layer | `--mount=type=secret` |
| BuildKit disabled | No cache mount + parallel builds | `DOCKER_BUILDKIT=1` |
| No `.dockerignore` | `.git`, `.env`, `node_modules` end up in the image | Aggressive .dockerignore |
| ubuntu instead of distroless | 200 MB extra + CVEs | distroless / chainguard |
| No multi-arch | Doesn't run on ARM clusters | `docker buildx build --platform linux/amd64,linux/arm64` |

---

## 📋 Multi-Stage Best Practices Checklist

```
[ ] Multi-stage: build + runtime separate
[ ] Builder: full SDK, Runtime: distroless / scratch
[ ] Cache layer optimization (deps first, source after)
[ ] BuildKit cache mount (Cargo, Go, Maven)
[ ] `.dockerignore` aggressive
[ ] USER nonroot
[ ] Pinned base image (digest)
[ ] Multi-arch build (`buildx --platform`)
[ ] Test stage (for CI)
[ ] BuildKit secret mount (no leak)
[ ] Image size CI gate (< 100 MB target)
[ ] CVE scan (Trivy)
[ ] cosign sign (release)
[ ] SBOM generate
```

---

## 📚 References

- **Dockerfile Reference** — docs.docker.com/reference/dockerfile/
- **BuildKit Docs** — docs.docker.com/build/buildkit/
- **Distroless Images** — github.com/GoogleContainerTools/distroless
- [`Dockerfile-Best-Practices.md`](Dockerfile-Best-Practices.md)
- [`Distroless-and-Chainguard.md`](Distroless-and-Chainguard.md)
- [`BuildKit-Tips.md`](BuildKit-Tips.md)
- [`Image-Signing-Cosign.md`](Image-Signing-Cosign.md)
- [`08-Security/Container-Image-Scanning.md`](../08-Security/Container-Image-Scanning.md)

---

> *"Multi-stage build isn't 'optional' — it's the **2026 Dockerfile
> standard**. A team pushing a 1 GB image and complaining that 'storage
> is expensive' envies the one doing the same job with a **30 MB image**."*

---

> 🎓 **Learning Path:** This document is used as the "Read first" resource in the [`C1`](../22-Learning-Path/block-c-reproducibility/C1-container.md) module.
