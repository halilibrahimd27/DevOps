---
description: "Distroless and Chainguard images, why they're the 2026 standard, base image CVE comparison, migration strategy, and a practical guide to the trade-offs."
tags:
  - Containers
  - Docker
  - Security
  - SBOM
---
# Distroless & Chainguard — The 0-CVE Image Strategy

> *"Ubuntu base = 100+ CVE, daily. Alpine = ~30 CVE. Distroless =
> ~5 CVE. Chainguard = **near-zero CVE, daily rebuild**. The answer to
> 'which base?' already changed by 2026."*

This guide covers distroless and Chainguard images, why they're the
**2026 standard**, the migration strategy, and the trade-offs.

---

## 📊 Base Image Comparison

| Base | Size | CVE (typical) | Shell? | Package manager? | Use case |
|---|---|---|---|---|---|
| `ubuntu:22.04` | 78 MB | 100+ | ✅ bash | apt | Dev / debug |
| `debian:12-slim` | 80 MB | 50+ | ✅ bash | apt | Dev |
| `alpine:3.19` | 7 MB | ~30 | ✅ ash | apk | Lightweight |
| `gcr.io/distroless/static-debian12` | 2 MB | ~5 | ❌ | ❌ | Go static |
| `gcr.io/distroless/cc-debian12` | 20 MB | ~10 | ❌ | ❌ | C/C++/Rust |
| `gcr.io/distroless/python3-debian12` | 50 MB | ~10 | ❌ | ❌ | Python |
| `gcr.io/distroless/nodejs22-debian12` | 75 MB | ~10 | ❌ | ❌ | Node |
| `cgr.dev/chainguard/static` | 2 MB | **~0** | ❌ | ❌ | Go static |
| `cgr.dev/chainguard/python` | 40 MB | **~0** | ❌ | ❌ | Python |
| `cgr.dev/chainguard/node` | 70 MB | **~0** | ❌ | ❌ | Node |
| `scratch` | 0 MB | 0 | ❌ | ❌ | Static binary only |

> 🔑 **Chainguard < Distroless < Alpine < Debian/Ubuntu** (in terms of CVEs).

---

## 🎯 What Is Distroless?

> **Distroless**: A Google project that contains only **application
> runtime dependencies**. No shell, package manager, or debugger.

### What's inside?
- Runtime libraries (libc, ssl)
- CA certificates
- /etc/passwd (nonroot user)
- timezone data
- (in some) Java JRE / Python interpreter / Node runtime

### What's not inside?
- Shell (bash, sh)
- apt, apk, rpm, npm
- curl, wget, vim
- find, grep, ls

> 🔑 **Even if an attacker compromises it**, they can't run commands inside → exfiltration becomes hard.

### Variants
| Image | Contents |
|---|---|
| `distroless/static` | CA + nonroot user (for Go static binaries) |
| `distroless/base` | static + glibc + libssl (CGo binaries) |
| `distroless/cc` | base + libgcc (C/C++/Rust) |
| `distroless/python3` | cc + Python runtime |
| `distroless/nodejs22` | cc + Node 22 |
| `distroless/java21` | base + JRE 21 |

### Tags
- `:latest` (mutable, don't use)
- `:debug` (busybox shell — for debugging only)
- `:nonroot` (UID 65532, recommended)
- `:debug-nonroot` (combined)
- `@sha256:...` (digest pin, safest)

---

## 🦅 Chainguard Images

> **Chainguard**: A startup founded in 2022. Built on **Wolfi** (a mini
> distro). Commits to daily rebuild + **near-zero CVE**.

### Advantages
- **0 CVE target** (most images)
- **Daily rebuild** — image stays current when a new CVE is disclosed
- **SBOM + signature** attached to every image
- **glibc-based** (not musl — avoids Alpine's issues)
- **FIPS 140-3** versions available
- **Reproducible builds**

### Free vs Paid
- `cgr.dev/chainguard/<IMAGE>:latest` → free, public images
- `cgr.dev/chainguard-private/<IMAGE>` → paid, daily-rebuild older versions

### Example
```dockerfile
# Free, latest
FROM cgr.dev/chainguard/python:latest

# Paid (daily rebuild + version-pinned)
FROM cgr.dev/chainguard-private/python:3.12.7
```

---

## 🚀 Migration: Ubuntu → Distroless

### Step 1: Move to a multi-stage build
```dockerfile
# Old (single-stage Ubuntu)
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y python3
COPY . /app
CMD ["python3", "/app/main.py"]

# New (multi-stage)
FROM python:3.12-slim AS builder
RUN python -m venv /opt/venv
COPY requirements.txt .
RUN /opt/venv/bin/pip install -r requirements.txt

FROM gcr.io/distroless/python3-debian12:nonroot
COPY --from=builder /opt/venv /opt/venv
COPY . /app
WORKDIR /app
ENV PATH="/opt/venv/bin:$PATH"
USER nonroot
CMD ["python", "main.py"]
```

### Step 2: Keep build tools in the builder
```dockerfile
# ❌ No apt in distroless
RUN apt-get install -y curl   # FAIL

# ✅ Do it in the builder
FROM debian:12-slim AS builder
RUN apt-get install -y curl ca-certificates
COPY ... ...

FROM gcr.io/distroless/cc-debian12:nonroot
COPY --from=builder /usr/bin/curl /usr/bin/curl
```

### Step 3: Debugging without a shell
```bash
# No shell in the production image
docker exec -it <CONTAINER> sh   # FAIL

# Use an ephemeral container for debugging
kubectl debug -it <POD> --image=nicolaka/netshoot --target=<CONTAINER>

# or use the distroless:debug image (for debugging only)
FROM gcr.io/distroless/python3-debian12:debug-nonroot
```

---

## 🔧 Build vs Runtime Image

### Build: full SDK
```dockerfile
FROM golang:1.23 AS builder
# all tools are present
RUN go build ...
```

### Runtime: minimal
```dockerfile
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /myapp /myapp
USER nonroot
ENTRYPOINT ["/myapp"]
```

> 🔑 **Build tools have no business being at runtime**. Multi-stage is mandatory.

---

## 🛡️ Production Security Hardening

### 1. UID 65532 (nonroot)
```dockerfile
USER nonroot   # or 65532
```

### 2. Read-only filesystem
```yaml
# K8s deployment
securityContext:
  readOnlyRootFilesystem: true
volumeMounts:
  - name: tmp
    mountPath: /tmp
volumes:
  - name: tmp
    emptyDir: {}
```

### 3. Drop all capabilities
```yaml
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]
  seccompProfile:
    type: RuntimeDefault
```

### 4. Cosign sign + Kyverno verify
See [`Image-Signing-Cosign.md`](Image-Signing-Cosign.md) and [`08-Security/Policy-as-Code-OPA-Kyverno.md`](../08-Security/Policy-as-Code-OPA-Kyverno.md).

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| `FROM ubuntu:latest` at runtime | 100+ CVEs + 78 MB | distroless / chainguard |
| Shell in production | Interactive compromise | Shell-free runtime |
| `RUN apt-get install` in the runtime image | Dev tool at runtime | Do it in the builder, COPY into runtime |
| `:latest` distroless tag | Mutable | Digest pin |
| Distroless + USER root | Uses default UID | `:nonroot` or `USER 65532` |
| Alpine + glibc app | musl incompatibilities | distroless (glibc) |
| Chainguard `latest` free + production | Major version skip risk | Pinned + paid |
| SSH into prod image for debugging | Attacker vector | `kubectl debug --image=netshoot` |
| No build cache | Every build is a full rebuild | BuildKit cache mount |
| No SBOM | Supply chain unknown | `--sbom=true` |

---

## 📋 Distroless Adoption Checklist

```
[ ] Every prod image is multi-stage
[ ] Runtime: distroless or chainguard
[ ] USER nonroot
[ ] Digest pin (`@sha256:...`)
[ ] readOnlyRootFilesystem: true (K8s)
[ ] Drop ALL capabilities
[ ] BuildKit cache mount
[ ] cosign sign + verify (Kyverno)
[ ] SBOM attached (`--sbom=true`)
[ ] Trivy scan: 0 CRITICAL/HIGH (fix-available)
[ ] Image size dashboard (in CI)
[ ] Multi-arch build (`buildx`)
[ ] `:debug` variant or ephemeral container for debugging
[ ] Quarterly: base image upgrade (new distro version)
```

---

## 📚 References

- **Distroless** — github.com/GoogleContainerTools/distroless
- **Chainguard Images** — chainguard.dev/chainguard-images
- **Wolfi** (Chainguard's distro) — github.com/wolfi-dev
- **Cosign** — github.com/sigstore/cosign
- [`Dockerfile-Best-Practices.md`](Dockerfile-Best-Practices.md)
- [`Multi-Stage-Builds.md`](Multi-Stage-Builds.md)
- [`Image-Signing-Cosign.md`](Image-Signing-Cosign.md)
- [`08-Security/Container-Image-Scanning.md`](../08-Security/Container-Image-Scanning.md)
- [`08-Security/Kubernetes-Hardening.md`](../08-Security/Kubernetes-Hardening.md)

---

> *"Distroless isn't 'extreme' — it's the **2026 production standard**.
> A team that pushes images to prod on an Ubuntu base fights a **CVE
> backlog mountain**; a team that pushes with Chainguard reports
> **near-zero CVE**."*
