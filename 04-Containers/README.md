---
description: "Container imajlarini hizli, kucuk ve guvenli yapmak icin 2026 referansi: Dockerfile best practices, multi-stage, distroless, BuildKit ve Cosign imzalama."
tags:
  - Containers
  - Docker
  - Security
  - Roadmap
---
# 04 · Containers

> *"Son commit-image-deploy döngüsünü 90 saniyede yapamayan ekip,
> production hata düzeltmesinde 3 saatte yapar."*

Container imajlarınızın **hızlı**, **küçük**, **güvenli** olması için
2026 referansı.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`Dockerfile-Best-Practices.md`](Dockerfile-Best-Practices.md) | 20 madde: layer, cache, user, healthcheck, COPY sırası |
| [`Multi-Stage-Builds.md`](Multi-Stage-Builds.md) | Builder/runner ayrımı, dağıtım imajı 10x küçültme |
| [`Distroless-and-Chainguard.md`](Distroless-and-Chainguard.md) | `gcr.io/distroless`, Chainguard images, minimal CVE attack surface |
| [`BuildKit-Tips.md`](BuildKit-Tips.md) | Cache mount, secret mount, SSH agent forwarding, multi-platform |
| [`Image-Signing-Cosign.md`](Image-Signing-Cosign.md) | Sigstore + cosign keyless imzalama, Kyverno verifyImages |
| [`Container-vs-WASM.md`](Container-vs-WASM.md) | Wasm ne zaman container'ı yener (Spin, wasmCloud) |

## "İyi imaj" karar listesi

- [ ] Multi-stage build (final imaj sadece runtime'ı içerir)
- [ ] Non-root user (`USER 65532` veya isim)
- [ ] `HEALTHCHECK` tanımlı
- [ ] `COPY --chown` ile ownership doğru
- [ ] Tag'ler `:latest` değil semantic (`:v1.2.3`, `:sha-abc1234`)
- [ ] Imaj imzalı (cosign) ve SBOM eşliğinde
- [ ] Vulnerability scan başarılı (Trivy/Grype)
- [ ] Imaj boyutu < 100 MB (scratch/distroless ile < 30 MB)
- [ ] `.dockerignore` ile gereksiz dosyalar dışarıda

## Tipik base image seçimi

| Kullanım | Önerilen 2026 |
|---|---|
| Go binary | `gcr.io/distroless/static-debian12` (8 MB) |
| Node.js | `cgr.dev/chainguard/node:latest` veya `node:20-alpine` |
| Python | `cgr.dev/chainguard/python:latest` veya `python:3.12-slim` |
| Java | `cgr.dev/chainguard/jre:latest` veya `eclipse-temurin:21-jre-alpine` |
| .NET | `mcr.microsoft.com/dotnet/runtime:8.0-alpine` |
| Generic | `cgr.dev/chainguard/wolfi-base` (rolling, security-focused) |

> ❌ **Kaçın:** `ubuntu:22.04`, `centos:7`, `debian:bullseye` (büyük, fazla CVE).
