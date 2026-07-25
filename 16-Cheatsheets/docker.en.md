---
description: "Docker practical command notes: image build, build-arg, multi-platform build and cache with BuildKit/buildx, run, exec, network, volume, and prune operations."
tags:
  - Cheatsheet
  - Docker
  - Containers
---
# Docker Cheatsheet

## 🔨 Build

```bash
# Simple build
docker build -t <REGISTRY>/<IMAGE>:<TAG> .

# Specific Dockerfile
docker build -f deploy/Dockerfile.prod -t app:prod .

# Pass build arg
docker build --build-arg VERSION=1.2.3 --build-arg COMMIT=$(git rev-parse HEAD) -t app .

# Multi-platform build (BuildKit/buildx)
docker buildx build --platform linux/amd64,linux/arm64 -t <REGISTRY>/<IMAGE>:<TAG> --push .

# Prioritize cache (for large images)
docker buildx build \
  --cache-from type=registry,ref=<REGISTRY>/<IMAGE>:cache \
  --cache-to type=registry,ref=<REGISTRY>/<IMAGE>:cache,mode=max \
  -t <REGISTRY>/<IMAGE>:<TAG> .

# Secret mount (in Dockerfile: `--mount=type=secret,id=<ID>`)
docker build --secret id=npm,src=$HOME/.npmrc -t app .

# SSH agent forward (for private repo install)
docker build --ssh default -t app .
```

## ▶️ Run

```bash
# Detached + named + port + volume + env
docker run -d \
  --name app \
  --restart unless-stopped \
  -p 8080:8080 \
  -v $(pwd)/data:/app/data \
  -e DB_HOST=postgres \
  --env-file .env \
  <REGISTRY>/<IMAGE>:<TAG>

# Ephemeral container, remove on exit
docker run --rm -it ubuntu:22.04 bash

# Read-only filesystem (security)
docker run --rm -it --read-only --tmpfs /tmp <IMAGE>

# Resource limits
docker run -d --memory=512m --cpus=0.5 --pids-limit=100 <IMAGE>

# Non-root override (image may be set to root user)
docker run --user 1000:1000 <IMAGE>

# Select network
docker run --network bridge|host|none|<NET_NAME> <IMAGE>

# Set Linux capabilities (least privilege)
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE <IMAGE>
```

## 🐚 Exec / Logs / Stats

```bash
# Enter a running container
docker exec -it app /bin/sh
docker exec -it app /bin/bash

# Run a single command
docker exec app printenv DB_HOST
docker exec app cat /etc/hostname

# Logs
docker logs app
docker logs -f --tail=100 --since=10m app
docker logs app 2>&1 | grep ERROR

# Resource usage
docker stats
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Container details (everything)
docker inspect app
docker inspect app --format '{{.NetworkSettings.IPAddress}}'
docker inspect app --format '{{json .Mounts}}' | jq
```

## 🌐 Networks

```bash
# Network list
docker network ls
docker network inspect bridge

# Custom network
docker network create app-net
docker network create --driver bridge --subnet 172.20.0.0/16 app-net

# Connect container to a network
docker network connect app-net app
docker network disconnect bridge app

# DNS name resolution (automatic on custom networks)
docker run --network app-net --name api <IMAGE>
docker run --network app-net curlimages/curl curl http://api:8080  # works as hostname
```

## 💾 Volumes

```bash
# Volume list
docker volume ls
docker volume inspect <VOLUME>

# Named volume
docker run -v pgdata:/var/lib/postgresql/data postgres:16

# Bind mount (host path)
docker run -v $(pwd)/config:/etc/app:ro <IMAGE>

# tmpfs (in RAM, no disk write — for security)
docker run --tmpfs /tmp:size=100M,mode=1777 <IMAGE>

# Volume backup
docker run --rm -v pgdata:/data -v $(pwd):/backup ubuntu \
  tar czf /backup/pgdata.tar.gz /data

# Volume restore
docker run --rm -v pgdata:/data -v $(pwd):/backup ubuntu \
  bash -c "cd /data && tar xzf /backup/pgdata.tar.gz --strip 1"
```

## 🧹 Prune (cleanup)

```bash
# All stopped containers
docker container prune

# All unreferenced images (dangling)
docker image prune

# All unused images (dangling + unreferenced)
docker image prune -a

# Volumes (CAUTION: data is deleted)
docker volume prune

# Everything in one command
docker system prune -a --volumes

# Disk usage report
docker system df
docker system df -v       # detailed
```

## 🔐 Registry

```bash
# Login
docker login <REGISTRY>
docker login ghcr.io -u <USER>             # token from stdin

# Tag + push
docker tag local-image <REGISTRY>/<IMAGE>:<TAG>
docker push <REGISTRY>/<IMAGE>:<TAG>

# Pull specific platform
docker pull --platform linux/arm64 <IMAGE>

# Image manifest (get the digest)
docker manifest inspect <REGISTRY>/<IMAGE>:<TAG>
```

## 🐳 Compose

```bash
# Up + detached
docker compose up -d
docker compose up -d --build           # rebuild
docker compose up -d --force-recreate

# Down
docker compose down
docker compose down -v                  # also remove volumes

# Specific service
docker compose up -d api
docker compose restart api
docker compose logs -f api

# Config validate
docker compose config
docker compose config --quiet           # syntax check, no output

# Service exec
docker compose exec api /bin/sh

# Resource limit
docker compose ps
docker compose top
docker compose stats
```

## 📋 BuildKit-specific commands

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# Create buildx instance (required for multi-platform)
docker buildx create --name mybuilder --use
docker buildx ls
docker buildx inspect --bootstrap

# History inspect (cache hit/miss debug)
docker buildx build --progress=plain ...
```

## 🔍 Inspect image

```bash
# Inspect layers (size of each)
docker history <IMAGE>
docker history <IMAGE> --no-trunc

# Image contents (filesystem)
docker save <IMAGE> -o image.tar
tar tf image.tar
# or:
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest <IMAGE>

# Image labels
docker inspect <IMAGE> --format '{{json .Config.Labels}}' | jq

# Image config
docker inspect <IMAGE> --format '{{json .Config}}' | jq
```

## ⚡ Useful one-liners

```bash
# Stop all containers
docker stop $(docker ps -q)

# Remove all containers (stopped + running)
docker rm -f $(docker ps -aq)

# Kill all containers tied to an image
docker ps -a -q --filter ancestor=<IMAGE> | xargs docker rm -f

# Remove images matching a pattern
docker images --format '{{.Repository}}:{{.Tag}}' | grep '<PATTERN>' | xargs docker rmi

# Container disk usage
docker ps --size

# Image vulnerability scan
docker scout cves <IMAGE>
trivy image <IMAGE>
grype <IMAGE>
```

## 🆘 "Emergency" scenarios

| Issue | Solution |
|---|---|
| `Cannot connect to Docker daemon` | `sudo systemctl start docker`; is the user in the `docker` group? |
| `permission denied` (volume mount) | SELinux: add `:Z` (`-v $PWD:/app:Z`); match user/group |
| Image too large | layer analysis with `dive`; multi-stage build; `.dockerignore` |
| Build cache not hitting | reorder `COPY` (least-changing first); see the diff with `--no-cache` |
| `OCI runtime exec failed` | image doesn't contain `/bin/sh` or `/bin/bash`; start with `BusyBox` |
| Container restarting (loop) | `docker logs <NAME>` → entrypoint error; start with `restart: no`, `docker exec` |
| `no space left on device` | `docker system prune -a --volumes`; `df -h /var/lib/docker` |
