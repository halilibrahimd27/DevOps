---
description: "Multi-stage Dockerfile şablonları (Go, Node.js, Python): distroless/non-root runtime, cache mount'lu build, küçük ve az-CVE final imaj."
tags:
  - Template
  - Docker
  - Security
---
# Multi-Stage Dockerfile Şablonları

> Kopyala-değiştir. Üçü de aynı disipline uyar: build ve runtime ayrı stage,
> runtime non-root, final imaj küçük. Placeholder'lar `<UPPER_CASE>` ile.
> Bu sayfa komşu dosyaların gömülü halidir; kaynak dosyalar aynı klasörde.

## Dosyalar

| Dosya | Runtime tabanı | Öne çıkan |
|---|---|---|
| [`go.Dockerfile`](go.Dockerfile) | `distroless/static` | Statik binary, ~10 MB final imaj |
| [`node.Dockerfile`](node.Dockerfile) | `node:22-alpine` + `tini` | deps/build/runtime 3 stage, prod-only modules |
| [`python.Dockerfile`](python.Dockerfile) | `python:3.12-slim` | `uv` ile hızlı install, venv taşıma |

## Ortak karar: niye multi-stage

- **Build araçları runtime'a sızmaz.** Derleyici, dev bağımlılık, kaynak kod final imajda yok — saldırı yüzeyi ve CVE sayısı düşer.
- **Non-root runtime.** Üçü de UID 65532 ile çalışır; compromise container root değil.
- **Cache mount** (`--mount=type=cache`): bağımlılık indirmesi katman cache'ine değil, build cache'ine gider — reproducible ve hızlı.

### 1️⃣ Go — distroless static

```dockerfile
# Multi-stage Go build → distroless static (final imaj ~10 MB)
#
# Build:
#   docker build -f go.Dockerfile -t <REGISTRY>/<IMAGE>:<TAG> .
#
# Notes:
#   - CGO_ENABLED=0  → fully static binary
#   - distroless/static  → /etc/passwd, ca-certificates, tzdata var; shell yok

# ----- Stage 1: Build -----
FROM golang:1.23-alpine AS build

WORKDIR /src

# Bağımlılıkları önce kopyala (cache hit için)
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# Kaynak kodu kopyala
COPY . .

# Build (statik, küçük)
ARG VERSION=dev
ARG COMMIT=unknown
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux \
    go build \
      -trimpath \
      -ldflags="-w -s -X main.Version=${VERSION} -X main.Commit=${COMMIT}" \
      -o /out/app \
      ./cmd/app

# ----- Stage 2: Runtime -----
FROM gcr.io/distroless/static-debian12:nonroot

# Etiketler (registry'de görünür)
LABEL org.opencontainers.image.source="https://github.com/<ORG>/<REPO>"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.description="<APP_NAME>"

WORKDIR /app

# Sadece binary'yi kopyala
COPY --from=build /out/app /app/app

# Non-root user (distroless'in built-in nonroot user'ı UID 65532)
USER 65532:65532

EXPOSE 8080

# Healthcheck (opsiyonel — K8s probe varsa gerek yok)
# HEALTHCHECK CMD ["/app/app", "health"]

ENTRYPOINT ["/app/app"]
```

### 2️⃣ Node.js — 3 stage (deps / build / runtime)

```dockerfile
# Multi-stage Node.js build (TypeScript)
# - Build stage'de tüm dev dependencies var
# - Runtime'da sadece production deps + dist/

# ----- Stage 1: Dependencies -----
FROM node:22-alpine AS deps

WORKDIR /app

# package files'ı önce (cache hit)
COPY package.json package-lock.json* ./

# Production-only deps (runtime için)
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev --audit=false --fund=false

# ----- Stage 2: Build -----
FROM node:22-alpine AS build

WORKDIR /app

COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --audit=false --fund=false

COPY . .

# Build (TypeScript → JS, vite/webpack/tsc)
RUN npm run build

# ----- Stage 3: Runtime -----
FROM node:22-alpine AS runtime

# Non-root user (alpine'da 'node' user var)
RUN apk add --no-cache tini && \
    addgroup -g 65532 nonroot 2>/dev/null || true && \
    adduser -u 65532 -G nonroot -D nonroot 2>/dev/null || true

WORKDIR /app

# Sadece production node_modules + build çıktısı
COPY --from=deps  --chown=nonroot:nonroot /app/node_modules ./node_modules
COPY --from=build --chown=nonroot:nonroot /app/dist         ./dist
COPY --chown=nonroot:nonroot package.json ./

USER nonroot

EXPOSE 3000

ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=384"

# tini = PID 1, signal handling + zombie reap
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "dist/index.js"]

# ───────────────────────────────────────────────────────────
# Alternatif: Chainguard ile (daha küçük, daha az CVE)
#
# FROM cgr.dev/chainguard/node:latest AS runtime
# WORKDIR /app
# COPY --from=deps  --chown=nonroot:nonroot /app/node_modules ./node_modules
# COPY --from=build --chown=nonroot:nonroot /app/dist         ./dist
# CMD ["dist/index.js"]
```

### 3️⃣ Python — `uv` ile hızlı install

```dockerfile
# Multi-stage Python build
# - uv ile hızlı dependency install (pip'ten 10-100x hızlı)
# - Distroless'a yakın final imaj
#
# Alternatif paketleyici: uv (Astral) | poetry | pip

# ----- Stage 1: Build venv -----
FROM python:3.12-slim AS build

# uv kurulum (Astral'in modern Python paketleyicisi)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0

WORKDIR /app

# Bağımlılıkları yükle (cache friendly)
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

# Uygulama kodunu kopyala
COPY . .
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# ----- Stage 2: Runtime -----
FROM python:3.12-slim AS runtime

# Güvenlik: non-root user
RUN groupadd -r app -g 65532 && \
    useradd -r -g app -u 65532 -m -d /home/app app && \
    apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# venv ve uygulama kodu
COPY --from=build --chown=app:app /app /app

# venv'i path'e ekle
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random

USER app

EXPOSE 8000

# uvicorn / gunicorn / fastapi
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# ───────────────────────────────────────────────────────────
# Alternatif: Chainguard
#
# FROM cgr.dev/chainguard/python:latest AS runtime
# WORKDIR /app
# COPY --from=build --chown=nonroot:nonroot /app /app
# ENV PATH="/app/.venv/bin:$PATH"
# CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## 🚫 Anti-Pattern

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tek stage, build araçları imajda | Derleyici + kaynak kod runtime'da → büyük saldırı yüzeyi | Multi-stage; runtime'a sadece artefakt kopyala |
| `latest` base image | Reproducible değil; sürpriz CVE | Sürüm pinle (`node:22-alpine`), ideal SHA digest |
| Root user runtime | Compromise container = root | `USER 65532` + non-root taban |
| `COPY . .` sonra `.dockerignore` yok | `node_modules`, `.git`, secret sızar | `.dockerignore` ekle, sadece gerekeni kopyala |

> *"İmaj küçüldükçe hem push/pull hızlanır hem taranacak CVE azalır — küçük imaj güvenlik kararıdır."*
