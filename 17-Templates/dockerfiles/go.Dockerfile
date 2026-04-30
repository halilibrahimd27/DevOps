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
