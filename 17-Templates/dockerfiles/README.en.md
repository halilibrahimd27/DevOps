---
description: "Multi-stage Dockerfile templates (Go, Node.js, Python): distroless/non-root runtime, build with cache mounts, small and low-CVE final image."
tags:
  - Template
  - Docker
  - Security
---
# Multi-Stage Dockerfile Templates

> Copy-modify. All three follow the same discipline: build and runtime are separate stages,
> runtime is non-root, the final image is small. Placeholders use `<UPPER_CASE>`.
> This page is the embedded form of the neighboring files; the source files are in the same folder.

## Files

| File | Runtime base | Highlight |
|---|---|---|
| [`go.Dockerfile`](go.Dockerfile) | `distroless/static` | Static binary, ~10 MB final image |
| [`node.Dockerfile`](node.Dockerfile) | `node:22-alpine` + `tini` | deps/build/runtime 3 stages, prod-only modules |
| [`python.Dockerfile`](python.Dockerfile) | `python:3.12-slim` | Fast install with `uv`, venv transfer |

## Shared decision: why multi-stage

- **Build tools don't leak into runtime.** The compiler, dev dependencies, and source code are absent from the final image — attack surface and CVE count drop.
- **Non-root runtime.** All three run as UID 65532; a compromised container is not root.
- **Cache mount** (`--mount=type=cache`): dependency downloads go to the build cache, not the layer cache — reproducible and fast.

### 1️⃣ Go — distroless static

```dockerfile
# Multi-stage Go build → distroless static (final image ~10 MB)
#
# Build:
#   docker build -f go.Dockerfile -t <REGISTRY>/<IMAGE>:<TAG> .
#
# Notes:
#   - CGO_ENABLED=0  → fully static binary
#   - distroless/static  → has /etc/passwd, ca-certificates, tzdata; no shell

# ----- Stage 1: Build -----
FROM golang:1.23-alpine AS build

WORKDIR /src

# Copy dependencies first (for cache hit)
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# Copy source code
COPY . .

# Build (static, small)
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

# Labels (visible in the registry)
LABEL org.opencontainers.image.source="https://github.com/<ORG>/<REPO>"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.description="<APP_NAME>"

WORKDIR /app

# Copy only the binary
COPY --from=build /out/app /app/app

# Non-root user (distroless's built-in nonroot user is UID 65532)
USER 65532:65532

EXPOSE 8080

# Healthcheck (optional — not needed if a K8s probe exists)
# HEALTHCHECK CMD ["/app/app", "health"]

ENTRYPOINT ["/app/app"]
```

### 2️⃣ Node.js — 3 stages (deps / build / runtime)

```dockerfile
# Multi-stage Node.js build (TypeScript)
# - All dev dependencies present in the build stage
# - Only production deps + dist/ in runtime

# ----- Stage 1: Dependencies -----
FROM node:22-alpine AS deps

WORKDIR /app

# package files first (cache hit)
COPY package.json package-lock.json* ./

# Production-only deps (for runtime)
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

# Non-root user ('node' user exists in alpine)
RUN apk add --no-cache tini && \
    addgroup -g 65532 nonroot 2>/dev/null || true && \
    adduser -u 65532 -G nonroot -D nonroot 2>/dev/null || true

WORKDIR /app

# Only production node_modules + build output
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
# Alternative: with Chainguard (smaller, fewer CVEs)
#
# FROM cgr.dev/chainguard/node:latest AS runtime
# WORKDIR /app
# COPY --from=deps  --chown=nonroot:nonroot /app/node_modules ./node_modules
# COPY --from=build --chown=nonroot:nonroot /app/dist         ./dist
# CMD ["dist/index.js"]
```

### 3️⃣ Python — fast install with `uv`

```dockerfile
# Multi-stage Python build
# - Fast dependency install with uv (10-100x faster than pip)
# - Final image close to distroless
#
# Alternative packager: uv (Astral) | poetry | pip

# ----- Stage 1: Build venv -----
FROM python:3.12-slim AS build

# uv installation (Astral's modern Python packager)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0

WORKDIR /app

# Install dependencies (cache friendly)
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

# Copy application code
COPY . .
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# ----- Stage 2: Runtime -----
FROM python:3.12-slim AS runtime

# Security: non-root user
RUN groupadd -r app -g 65532 && \
    useradd -r -g app -u 65532 -m -d /home/app app && \
    apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# venv and application code
COPY --from=build --chown=app:app /app /app

# add venv to path
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random

USER app

EXPOSE 8000

# uvicorn / gunicorn / fastapi
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# ───────────────────────────────────────────────────────────
# Alternative: Chainguard
#
# FROM cgr.dev/chainguard/python:latest AS runtime
# WORKDIR /app
# COPY --from=build --chown=nonroot:nonroot /app /app
# ENV PATH="/app/.venv/bin:$PATH"
# CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## 🚫 Anti-Pattern

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Single stage, build tools in the image | Compiler + source code in runtime → large attack surface | Multi-stage; copy only the artifact into runtime |
| `latest` base image | Not reproducible; surprise CVE | Pin the version (`node:22-alpine`), ideally SHA digest |
| Root user runtime | Compromised container = root | `USER 65532` + non-root base |
| `COPY . .` without `.dockerignore` | `node_modules`, `.git`, secrets leak | Add `.dockerignore`, copy only what's needed |

> *"As the image shrinks, push/pull gets faster and there are fewer CVEs to scan — a small image is a security decision."*
