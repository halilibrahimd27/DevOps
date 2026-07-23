---
description: "2026 reference for making container images fast, small, and secure: Dockerfile best practices, multi-stage, distroless, BuildKit, and Cosign signing."
tags:
  - Containers
  - Docker
  - Security
  - Roadmap
---
# 04 · Containers

> *"A team that can't do the last commit-image-deploy cycle in 90
> seconds does it in 3 hours during a production incident fix."*

The 2026 reference for making your container images **fast**,
**small**, and **secure**.

## Contents

| File | Topic |
|---|---|
| [`Dockerfile-Best-Practices.md`](Dockerfile-Best-Practices.md) | 20 items: layers, cache, user, healthcheck, COPY order |
| [`Multi-Stage-Builds.md`](Multi-Stage-Builds.md) | Builder/runner separation, 10x shrinking the shipped image |
| [`Distroless-and-Chainguard.md`](Distroless-and-Chainguard.md) | `gcr.io/distroless`, Chainguard images, minimal CVE attack surface |
| [`BuildKit-Tips.md`](BuildKit-Tips.md) | Cache mount, secret mount, SSH agent forwarding, multi-platform |
| [`Image-Signing-Cosign.md`](Image-Signing-Cosign.md) | Sigstore + cosign keyless signing, Kyverno verifyImages |
| [`Container-vs-WASM.md`](Container-vs-WASM.md) | When Wasm beats containers (Spin, wasmCloud) |

## "Good image" decision list

- [ ] Multi-stage build (final image contains only the runtime)
- [ ] Non-root user (`USER 65532` or a name)
- [ ] `HEALTHCHECK` defined
- [ ] Correct ownership via `COPY --chown`
- [ ] Tags are semantic, not `:latest` (`:v1.2.3`, `:sha-abc1234`)
- [ ] Image signed (cosign) and accompanied by an SBOM
- [ ] Vulnerability scan passes (Trivy/Grype)
- [ ] Image size < 100 MB (< 30 MB with scratch/distroless)
- [ ] Unneeded files excluded via `.dockerignore`

## Typical base image choice

| Use case | Recommended for 2026 |
|---|---|
| Go binary | `gcr.io/distroless/static-debian12` (8 MB) |
| Node.js | `cgr.dev/chainguard/node:latest` or `node:20-alpine` |
| Python | `cgr.dev/chainguard/python:latest` or `python:3.12-slim` |
| Java | `cgr.dev/chainguard/jre:latest` or `eclipse-temurin:21-jre-alpine` |
| .NET | `mcr.microsoft.com/dotnet/runtime:8.0-alpine` |
| Generic | `cgr.dev/chainguard/wolfi-base` (rolling, security-focused) |

> ❌ **Avoid:** `ubuntu:22.04`, `centos:7`, `debian:bullseye` (large, too many CVEs).
