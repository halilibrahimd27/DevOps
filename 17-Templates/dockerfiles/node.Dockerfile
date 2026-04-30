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
