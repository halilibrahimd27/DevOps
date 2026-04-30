# Dockerfile Best Practices — 20 Madde

> *"Imaj ne kadar küçük olursa o kadar güvenli, o kadar hızlı, o kadar
> az hata."*

---

## 🎯 Hedefler

Her madde şu üç ekseni iyileştirir:
- 🚀 **Build hızı** (cache hit, paralelizasyon)
- 📦 **Imaj boyutu** (gereksiz layer/dosya yok)
- 🛡️ **Güvenlik** (least privilege, az attack surface, az CVE)

---

## 1. Multi-stage build kullan (HER ZAMAN)

Build dependencies (compiler, dev libs) runtime'a girmesin.

```dockerfile
# ❌ Kötü: tüm araçlar imajda kalır
FROM golang:1.23
WORKDIR /app
COPY . .
RUN go build -o app
CMD ["./app"]
# → Final imaj ~700 MB

# ✅ İyi: build artifact'ı temiz imaja kopyala
FROM golang:1.23 AS build
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o /out/app

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/app /app/app
USER 65532
ENTRYPOINT ["/app/app"]
# → Final imaj ~12 MB
```

## 2. Distroless / Chainguard / Alpine — base image küçük olsun

| Base | Boyut | CVE | Kullanım |
|---|---|---|---|
| `ubuntu:22.04` | 77 MB | Çok | ❌ kaçın |
| `debian:bullseye-slim` | 80 MB | Orta | ⚠️ alternatif yoksa |
| `alpine:3.19` | 7 MB | Az | ✅ uygun (musl libc fark eder) |
| `gcr.io/distroless/static` | 2 MB | Çok az | ✅✅ Go static binary için |
| `cgr.dev/chainguard/<lang>` | 5-30 MB | Minimal, daily update | ✅✅ production sweet spot |

## 3. `.dockerignore` mutlaka var

Build context'e gereksiz dosya gönderme — yavaşlatır, secret leak yapabilir.

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

## 4. Layer sırası — least-changing önce

Her `RUN`/`COPY` bir layer; cache hit için **az değişen üstte** olsun.

```dockerfile
# ❌ Kötü: kaynak kodu erken kopyalanır → her commit'te npm install tekrar çalışır
FROM node:22-alpine
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build

# ✅ İyi
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./        # az değişir
RUN npm ci --omit=dev                         # cache hit
COPY . .                                       # sık değişir
RUN npm run build
```

## 5. `RUN` komutlarını birleştir (ama mantıklı şekilde)

Her `RUN` bir layer ekler. Birleştir, ama loglanabilirliği kaybetme.

```dockerfile
# ❌ Üç layer
RUN apt-get update
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*

# ✅ Tek layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*
```

`--no-install-recommends` kritik — `recommended` paketler imajı şişirir.

## 6. `USER` — non-root zorunlu

Container escape vektörlerini kapatır.

```dockerfile
# ✅ Distroless'ta hazır
FROM gcr.io/distroless/base-debian12:nonroot
USER 65532

# ✅ Manuel oluştur
RUN groupadd -r app -g 65532 && \
    useradd -r -g app -u 65532 -m -d /home/app app
USER app
```

> Image'da kalan kod ROOT olarak çalışıyorsa, `runAsNonRoot: true` Pod
> Security Standard'ı bile bypass edemezsin (image fail eder).

## 7. `HEALTHCHECK` ekle (compose için)

K8s probe varsa gerekmez ama docker compose / standalone için faydalı.

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://localhost:8080/health || exit 1
```

## 8. `EXPOSE` belge amaçlı

Aslında port'u publish etmiyor (ama dokümantasyon değer).

```dockerfile
EXPOSE 8080 9090
```

## 9. `ENV` kullan, hardcoded yok

```dockerfile
# ❌ Build time'da gerçek değer
ENV API_KEY="<HARDCODED>"

# ✅ Defaults, runtime override edilebilir
ENV NODE_ENV=production \
    PORT=8080 \
    LOG_LEVEL=info
```

> Secret'lar env'de ASLA build edilmez. `docker run -e` ile veya secret manager.

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

## 12. `COPY --chown` — runtime'da chown'a gerek kalmasın

```dockerfile
# ✅
COPY --chown=app:app . /app/

# ❌ (extra layer)
COPY . /app/
RUN chown -R app:app /app
```

## 13. BuildKit cache mount

Build sırasında cache'i imaja yazmadan kullan.

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

Secret'ı build sırasında kullan, imaja kaydetme.

```dockerfile
# syntax=docker/dockerfile:1.7
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm ci
```

```bash
docker build --secret id=npm_token,src=$HOME/.npmrc .
```

## 15. SSH agent forward (private repo install için)

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
# ❌ Shell form — process PID 1 değil sh, signal handling bozulur
CMD node app.js

# ✅ Exec form — node PID 1, SIGTERM doğrudan gelir
CMD ["node", "app.js"]
```

## 17. `tini` veya `dumb-init` ile signal handling (Node/PHP/Python için)

```dockerfile
RUN apk add --no-cache tini
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "app.js"]
```

Aksi halde:
- Zombie child process'ler birikir
- SIGTERM düzgün propagate edilmez
- Graceful shutdown çalışmaz

## 18. Specific tag, asla `:latest`

```dockerfile
# ❌
FROM node:latest
FROM nginx

# ✅
FROM node:22.11.0-alpine3.19
FROM nginx:1.27.2-alpine

# ✅✅ SHA-pinned (en güvenli — supply chain saldırısı resistant)
FROM node@sha256:abc123...
```

## 19. Vulnerability scan zorunlu (CI'da)

```bash
# Build sonrası
docker build -t app .

# Trivy
trivy image --severity HIGH,CRITICAL --exit-code 1 app

# Grype
grype app --fail-on high

# Docker Scout
docker scout cves app
```

CI pipeline'a entegre: HIGH/CRITICAL bulunursa fail.

## 20. Imzalama (cosign)

```bash
# Build & push
docker build -t <REGISTRY>/<IMAGE>:<TAG> .
docker push <REGISTRY>/<IMAGE>:<TAG>

# Sign (keyless OIDC, GitHub Actions identity ile)
cosign sign --yes <REGISTRY>/<IMAGE>:<TAG>

# Cluster'da Kyverno verifyImages ile zorunlu kıl
```

---

## 📋 Tipik Dockerfile patterns

### Go static binary (~10 MB final)

[`17-Templates/dockerfiles/go.Dockerfile`](../17-Templates/dockerfiles/go.Dockerfile)

### Node.js prod (~150 MB)

[`17-Templates/dockerfiles/node.Dockerfile`](../17-Templates/dockerfiles/node.Dockerfile)

### Python prod (~200 MB)

[`17-Templates/dockerfiles/python.Dockerfile`](../17-Templates/dockerfiles/python.Dockerfile)

---

## 🚦 Anti-pattern'ler (kaçın)

| ❌ Anti-pattern | ✅ Çözüm |
|---|---|
| `apt-get install` cache temizlenmemiş | `&& rm -rf /var/lib/apt/lists/*` |
| `npm install` (lock file görmezden gelir) | `npm ci` |
| `pip install` lock file yok | `uv` veya `pip install --no-deps -r requirements.lock` |
| `chmod -R 777` | least privilege, doğru ownership |
| `RUN cd /app && do_thing` | `WORKDIR /app` + `RUN do_thing` |
| Tek monolitik `RUN` ile her şey | Mantıksal gruplara böl, debug edilebilir kalsın |
| Secret env var'da | BuildKit secret mount, runtime'da injection |
| `COPY .` her şeyi | `COPY src/ /app/src` ya da `.dockerignore` |
| `add` URL'den dosya çek | `curl -fsSL` ile (`ADD` magic'i karışık) |
| SystemD container içinde | Container init = process supervisor değil |
| 1 container'da N process | 1 container = 1 concern |

---

## 🎯 Imaj boyut hedefleri (gerçekçi)

| Stack | Boyut hedef |
|---|---|
| Go binary (static) | < 20 MB |
| Rust binary (static) | < 20 MB |
| Java JRE | < 200 MB (jlink + Alpine) |
| Node.js (prod deps only) | < 200 MB |
| Python (uv + slim) | < 200 MB |
| .NET runtime | < 150 MB |
| nginx alpine | < 50 MB |

> 1 GB+ imaj = bir yerlerde gizli yağ var. `dive <IMAGE>` ile layer analizi yap.

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

## 📚 Devamı

- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Distroless](https://github.com/GoogleContainerTools/distroless)
- [Chainguard Images](https://images.chainguard.dev)
- [`05-Kubernetes/Production-Checklist.md`](../05-Kubernetes/Production-Checklist.md) — image kullanımı için
