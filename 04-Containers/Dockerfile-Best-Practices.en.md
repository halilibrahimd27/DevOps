---
description: "A 20-item Dockerfile best practices list that improves build speed, image size, and security: multi-stage, layer/cache, and least privilege."
tags:
  - Containers
  - Docker
  - Security
  - Performance
  - Cheatsheet
---
# Dockerfile Best Practices — 20 Items

> *"The smaller the image, the more secure, the faster, and the
> fewer errors."*

---

## 🎯 Goals

Each item improves these three axes:
- 🚀 **Build speed** (cache hit, parallelization)
- 📦 **Image size** (no unnecessary layers/files)
- 🛡️ **Security** (least privilege, small attack surface, fewer CVEs)

---

## 1. Use multi-stage builds (ALWAYS)

Keep build dependencies (compiler, dev libs) out of the runtime.

```dockerfile
# ❌ Bad: all tools stay in the image
FROM golang:1.23
WORKDIR /app
COPY . .
RUN go build -o app
CMD ["./app"]
# → Final image ~700 MB

# ✅ Good: copy the build artifact into a clean image
FROM golang:1.23 AS build
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o /out/app

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/app /app/app
USER 65532
ENTRYPOINT ["/app/app"]
# → Final image ~12 MB
```

## 2. Distroless / Chainguard / Alpine — keep the base image small

| Base | Size | CVE | Usage |
|---|---|---|---|
| `ubuntu:22.04` | 77 MB | Many | ❌ avoid |
| `debian:bullseye-slim` | 80 MB | Medium | ⚠️ if no alternative |
| `alpine:3.19` | 7 MB | Few | ✅ suitable (musl libc matters) |
| `gcr.io/distroless/static` | 2 MB | Very few | ✅✅ for Go static binaries |
| `cgr.dev/chainguard/<lang>` | 5-30 MB | Minimal, daily update | ✅✅ production sweet spot |

## 3. `.dockerignore` is mandatory

Don't send unnecessary files to the build context — it slows things down and can leak secrets.

```
# .dockerignore
.git
.gitignore
.github
.vscode
.idea
node_modules
*.md
!README.md
.env
.env.*
*.log
dist/
build/
test/
docs/
**/__pycache__
*.tar
*.zip
Dockerfile
docker-compose*.yml
.terraform/
*.tfstate*
```

## 4. Layer order — least-changing first

Every `RUN`/`COPY` is a layer; for cache hits, put **the least-changing content on top**.

```dockerfile
# ❌ Bad: source code copied too early → npm install reruns on every commit
FROM node:22-alpine
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build

# ✅ Good
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./        # changes rarely
RUN npm ci --omit=dev                         # cache hit
COPY . .                                       # changes often
RUN npm run build
```

## 5. Combine `RUN` commands (but sensibly)

Every `RUN` adds a layer. Combine them, but don't lose loggability.

```dockerfile
# ❌ Three layers
RUN apt-get update
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*

# ✅ One layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*
```

`--no-install-recommends` is critical — `recommended` packages bloat the image.

## 6. `USER` — non-root is mandatory

Closes off container escape vectors.

```dockerfile
# ✅ Already set in distroless
FROM gcr.io/distroless/base-debian12:nonroot
USER 65532

# ✅ Create manually
RUN groupadd -r app -g 65532 && \
    useradd -r -g app -u 65532 -m -d /home/app app
USER app
```

> If the code left in the image runs as ROOT, you can't even bypass
> the `runAsNonRoot: true` Pod Security Standard (the image fails).

## 7. Add `HEALTHCHECK` (for compose)

Not needed if you have K8s probes, but useful for docker compose / standalone.

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://localhost:8080/health || exit 1
```

## 8. `EXPOSE` is for documentation purposes

It doesn't actually publish the port (but it has documentation value).

```dockerfile
EXPOSE 8080 9090
```

## 9. Use `ENV`, no hardcoding

```dockerfile
# ❌ Real value at build time
ENV API_KEY="<HARDCODED>"

# ✅ Defaults, overridable at runtime
ENV NODE_ENV=production \
    PORT=8080 \
    LOG_LEVEL=info
```

> Secrets are NEVER built into env. Use `docker run -e` or a secret manager.

## 10. `ARG` build-time variables

```dockerfile
ARG VERSION=dev
ARG COMMIT=unknown
RUN echo "Building ${VERSION} (${COMMIT})" && \
    go build -ldflags "-X main.Version=${VERSION}"
```

```bash
docker build --build-arg VERSION=1.2.3 --build-arg COMMIT=$(git rev-parse HEAD) .
```

## 11. `LABEL` — OCI annotations

```dockerfile
LABEL org.opencontainers.image.source="https://github.com/<ORG>/<REPO>"
LABEL org.opencontainers.image.revision="<GIT_SHA>"
LABEL org.opencontainers.image.version="<VERSION>"
LABEL org.opencontainers.image.created="<RFC3339_TIMESTAMP>"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.description="<APP_NAME>"
```

## 12. `COPY --chown` — avoid needing chown at runtime

```dockerfile
# ✅
COPY --chown=app:app . /app/

# ❌ (extra layer)
COPY . /app/
RUN chown -R app:app /app
```

## 13. BuildKit cache mount

Use the cache during build without writing it into the image.

```dockerfile
# syntax=docker/dockerfile:1.7
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    go build -o /out/app
```

```dockerfile
# Python pip
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# npm
RUN --mount=type=cache,target=/root/.npm \
    npm ci
```

## 14. BuildKit secret mount

Use the secret during build, don't save it into the image.

```dockerfile
# syntax=docker/dockerfile:1.7
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm ci
```

```bash
docker build --secret id=npm_token,src=$HOME/.npmrc .
```

## 15. SSH agent forward (for private repo installs)

```dockerfile
# syntax=docker/dockerfile:1.7
RUN --mount=type=ssh \
    git clone git@github.com:<ORG>/private-lib.git
```

```bash
docker build --ssh default .
```

## 16. `CMD` array form

```dockerfile
# ❌ Shell form — process isn't PID 1, sh is, signal handling breaks
CMD node app.js

# ✅ Exec form — node is PID 1, SIGTERM arrives directly
CMD ["node", "app.js"]
```

## 17. `tini` or `dumb-init` for signal handling (for Node/PHP/Python)

```dockerfile
RUN apk add --no-cache tini
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "app.js"]
```

Otherwise:
- Zombie child processes accumulate
- SIGTERM isn't propagated properly
- Graceful shutdown doesn't work

## 18. Specific tag, never `:latest`

```dockerfile
# ❌
FROM node:latest
FROM nginx

# ✅
FROM node:22.11.0-alpine3.19
FROM nginx:1.27.2-alpine

# ✅✅ SHA-pinned (safest — resistant to supply chain attacks)
FROM node@sha256:abc123...
```

## 19. Vulnerability scan is mandatory (in CI)

```bash
# After build
docker build -t app .

# Trivy
trivy image --severity HIGH,CRITICAL --exit-code 1 app

# Grype
grype app --fail-on high

# Docker Scout
docker scout cves app
```

Integrate into the CI pipeline: fail if HIGH/CRITICAL found.

## 20. Signing (cosign)

```bash
# Build & push
docker build -t <REGISTRY>/<IMAGE>:<TAG> .
docker push <REGISTRY>/<IMAGE>:<TAG>

# Sign (keyless OIDC, with GitHub Actions identity)
cosign sign --yes <REGISTRY>/<IMAGE>:<TAG>

# Enforce in the cluster with Kyverno verifyImages
```

---

## 📋 Typical Dockerfile patterns

### Go static binary (~10 MB final)

[`17-Templates/dockerfiles/go.Dockerfile`](../17-Templates/dockerfiles/go.Dockerfile)

### Node.js prod (~150 MB)

[`17-Templates/dockerfiles/node.Dockerfile`](../17-Templates/dockerfiles/node.Dockerfile)

### Python prod (~200 MB)

[`17-Templates/dockerfiles/python.Dockerfile`](../17-Templates/dockerfiles/python.Dockerfile)

---

## 🚦 Anti-patterns (avoid)

| ❌ Anti-pattern | ✅ Solution |
|---|---|
| `apt-get install` cache not cleaned | `&& rm -rf /var/lib/apt/lists/*` |
| `npm install` (ignores lock file) | `npm ci` |
| `pip install` no lock file | `uv` or `pip install --no-deps -r requirements.lock` |
| `chmod -R 777` | least privilege, correct ownership |
| `RUN cd /app && do_thing` | `WORKDIR /app` + `RUN do_thing` |
| Everything in one monolithic `RUN` | Split into logical groups, keep debuggable |
| Secret in an env var | BuildKit secret mount, injection at runtime |
| `COPY .` copies everything | `COPY src/ /app/src` or `.dockerignore` |
| `ADD` fetching a file from a URL | Use `curl -fsSL` (`ADD`'s magic behavior is confusing) |
| SystemD inside a container | Container init isn't a process supervisor |
| N processes in 1 container | 1 container = 1 concern |

---

## 🎯 Image size targets (realistic)

| Stack | Size target |
|---|---|
| Go binary (static) | < 20 MB |
| Rust binary (static) | < 20 MB |
| Java JRE | < 200 MB (jlink + Alpine) |
| Node.js (prod deps only) | < 200 MB |
| Python (uv + slim) | < 200 MB |
| .NET runtime | < 150 MB |
| nginx alpine | < 50 MB |

> A 1 GB+ image means there's hidden fat somewhere. Analyze layers with `dive <IMAGE>`.

---

## 🛠️ Tooling

```bash
# Layer-level disk usage
dive <IMAGE>
docker history <IMAGE>

# Build progress
DOCKER_BUILDKIT=1 docker build --progress=plain .

# Multi-platform
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 --push .

# Lint
hadolint Dockerfile
```

---

## 📚 Further Reading

- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Distroless](https://github.com/GoogleContainerTools/distroless)
- [Chainguard Images](https://images.chainguard.dev)
- [`05-Kubernetes/Production-Checklist.md`](../05-Kubernetes/Production-Checklist.md) — for image usage

---

## 📋 Checklist

```
[ ] Multi-stage build is used; build tools aren't in the final image
[ ] Base image is small and fixed (distroless/chainguard/alpine) — no `:latest`, tag is pinned
[ ] `.dockerignore` exists; `.git`, `.env`, `node_modules` don't go into the build context
[ ] Layer order is cache-friendly: dependency manifest first, source code after
[ ] Container runs non-root (`USER` set; numeric like UID 65532)
[ ] Secrets aren't embedded in the image at build/runtime — BuildKit secret mount or runtime injection
[ ] `CMD`/`ENTRYPOINT` use exec (array) form; tini/dumb-init for signal handling (Node/Python/PHP)
[ ] CI vulnerability scan (Trivy/Grype/Scout) fails on HIGH+CRITICAL
[ ] OCI labels (source, revision, version) added; image is signed (cosign)
[ ] Final image meets its size target; hidden fat checked with `dive`/`docker history`
```

---

## 📚 References

- [`Multi-Stage-Builds.md`](Multi-Stage-Builds.md) — multi-stage in depth
- [`Distroless-and-Chainguard.md`](Distroless-and-Chainguard.md) — choosing a minimal base image
- [`Image-Signing-Cosign.md`](Image-Signing-Cosign.md) — signing and verify flow
- [`../08-Security/Container-Image-Scanning.md`](../08-Security/Container-Image-Scanning.md) — CVE scanning pipeline
- [`../08-Security/SLSA-and-SBOM.md`](../08-Security/SLSA-and-SBOM.md) — supply chain and SBOM
- [Docker Build best practices](https://docs.docker.com/build/building/best-practices/) — official documentation

---

> *"A good Dockerfile isn't luck, it's discipline: keep build residue out with multi-stage, order layers cache-friendly, pin versions, and abandon root — an image that settles for `:latest` goes to the trash, not to production."*

---

> 🎓 **Learning Path:** This document is used as the "Read first" resource in the [`C1`](../22-Learning-Path/block-c-reproducibility/C1-container.md) module.
