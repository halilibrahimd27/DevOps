---
description: "Multi-stage Docker build pattern'leri ve anti-pattern'leri: builder/runner ayrımı, dil-spesifik örnekler ve cache optimizasyonu ile imajı 10x küçültme rehberi."
tags:
  - Containers
  - Docker
  - Performance
  - Security
---
# Multi-Stage Builds — Küçük, Güvenli, Hızlı Image

> *"Tek-stage Dockerfile = build araçları + runtime aynı image'da.
> Sonuç: 1.5 GB image, 200 CVE, slow pull. **Multi-stage** ile aynı
> uygulama 30 MB, 2 CVE, 5 saniyede pull."*

Bu rehber multi-stage Docker build'in pattern'lerini, anti-pattern'leri,
dil-spesifik örnekleri ve cache optimization'ı anlatır.

---

## 🎯 Niye Multi-Stage?

### Tek-stage (kötü)
```dockerfile
FROM golang:1.23
WORKDIR /app
COPY . .
RUN go build -o myapp .
CMD ["./myapp"]
```

→ Image: **~800 MB** (Go toolchain + GCC + libc + tüm source).

### Multi-stage (iyi)
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

→ Image: **~30 MB**. Build araçları yok, sadece binary.

---

## 📐 Pattern Kataloğu

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

→ Scratch image **0 byte**; sadece binary + CA bundle.

### 3. Multi-builder (paralel)
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

→ Go + Node aynı anda paralel build (BuildKit).

### 4. Cache mount (BuildKit)
```dockerfile
# syntax=docker/dockerfile:1.7

FROM rust:1.75 AS builder
WORKDIR /app

# Cargo cache mount: layer'a girmez, sadece build sırasında kullanılır
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

→ İlk build 5 dk, ikinci build 30 saniye (cache hit).

### 5. Test stage (CI'da)
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
# CI: sadece test stage'i çalıştır
docker build --target=test -t app:test .
docker build -t app:latest .   # full build
```

---

## 🔧 Dil-Spesifik Örnekler

### Go
```dockerfile
FROM golang:1.23 AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download   # Layer cache: deps değişmediği sürece skip
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

> 🔑 Java için **JLink** ile custom JRE → image 100 MB → 50 MB.

### Rust (CGO ile FFI)
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

## 📊 Image Size Karşılaştırması

| Dil | Naif | Optimal multi-stage |
|---|---|---|
| Go | 800 MB | **15 MB** (scratch) |
| Rust | 1.2 GB | **20 MB** (distroless cc) |
| Python | 900 MB | **80 MB** (distroless python) |
| Node | 1 GB | **100 MB** (distroless nodejs) |
| Java | 700 MB | **180 MB** (JRE only) |

> 🔑 **Çoğu durumda %80-95 küçülme**.

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

→ stage-a + stage-b **paralel** çalışır (BuildKit).

### Cache mount type'lar
```dockerfile
# Type: cache (build cache)
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y curl

# Type: bind (read-only, source'tan)
RUN --mount=type=bind,source=secrets,target=/secrets \
    process-secrets

# Type: secret (one-time, layer'da yok)
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

→ Tek RUN layer, multi-line script, daha okunur.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tek-stage build | Build araçları runtime'da | Multi-stage |
| `apt-get install` cache temizliği yok | Image bloat | `&& rm -rf /var/lib/apt/lists/*` |
| `COPY . .` baştan | Cache hit yok | `COPY package*.json` önce, `npm ci`, sonra `COPY .` |
| `latest` tag base | Reproducibility yok | Pinned version (digest pin daha iyi) |
| `USER root` | RCE → host yakını | `USER nonroot` |
| `RUN curl ... | bash` | Supply chain risk | Pinned version + checksum |
| Secret build arg'da | Layer'da kalır | `--mount=type=secret` |
| BuildKit kapalı | Cache mount + parallel yok | `DOCKER_BUILDKIT=1` |
| `.dockerignore` yok | `.git`, `.env`, `node_modules` image'a girer | Aggressive .dockerignore |
| Distroless yerine ubuntu | 200 MB extra + CVE | distroless / chainguard |
| Multi-arch yok | ARM cluster'a çalışmaz | `docker buildx build --platform linux/amd64,linux/arm64` |

---

## 📋 Multi-Stage Best Practices Checklist

```
[ ] Multi-stage: build + runtime ayrı
[ ] Builder: full SDK, Runtime: distroless / scratch
[ ] Cache layer optimization (deps önce, source sonra)
[ ] BuildKit cache mount (Cargo, Go, Maven)
[ ] `.dockerignore` aggressive
[ ] USER nonroot
[ ] Pinned base image (digest)
[ ] Multi-arch build (`buildx --platform`)
[ ] Test stage (CI için)
[ ] BuildKit secret mount (no leak)
[ ] Image size CI gate (< 100 MB hedef)
[ ] CVE scan (Trivy)
[ ] cosign sign (release)
[ ] SBOM generate
```

---

## 📚 Referanslar

- **Dockerfile Reference** — docs.docker.com/reference/dockerfile/
- **BuildKit Docs** — docs.docker.com/build/buildkit/
- **Distroless Images** — github.com/GoogleContainerTools/distroless
- [`Dockerfile-Best-Practices.md`](Dockerfile-Best-Practices.md)
- [`Distroless-and-Chainguard.md`](Distroless-and-Chainguard.md)
- [`BuildKit-Tips.md`](BuildKit-Tips.md)
- [`Image-Signing-Cosign.md`](Image-Signing-Cosign.md)
- [`08-Security/Container-Image-Scanning.md`](../08-Security/Container-Image-Scanning.md)

---

> *"Multi-stage build 'optional' değil — **2026 Dockerfile standardı**.
> 1 GB image push edip 'storage pahalı' diyen ekip, **30 MB image**
> ile aynı işi yapanı kıskanır."*
