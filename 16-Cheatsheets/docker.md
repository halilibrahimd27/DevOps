---
description: "Docker pratik komut notlari: image build, build-arg, BuildKit/buildx ile multi-platform build ve cache, run, exec, network, volume ve prune islemleri."
---
# Docker Cheatsheet

## 🔨 Build

```bash
# Basit build
docker build -t <REGISTRY>/<IMAGE>:<TAG> .

# Specific Dockerfile
docker build -f deploy/Dockerfile.prod -t app:prod .

# Build arg geçir
docker build --build-arg VERSION=1.2.3 --build-arg COMMIT=$(git rev-parse HEAD) -t app .

# Multi-platform build (BuildKit/buildx)
docker buildx build --platform linux/amd64,linux/arm64 -t <REGISTRY>/<IMAGE>:<TAG> --push .

# Cache'e öncelik ver (büyük imajlar için)
docker buildx build \
  --cache-from type=registry,ref=<REGISTRY>/<IMAGE>:cache \
  --cache-to type=registry,ref=<REGISTRY>/<IMAGE>:cache,mode=max \
  -t <REGISTRY>/<IMAGE>:<TAG> .

# Secret mount (Dockerfile'da `--mount=type=secret,id=<ID>`)
docker build --secret id=npm,src=$HOME/.npmrc -t app .

# SSH agent forward (private repo install için)
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

# Ephemeral container, exit'te sil
docker run --rm -it ubuntu:22.04 bash

# Read-only filesystem (security)
docker run --rm -it --read-only --tmpfs /tmp <IMAGE>

# Resource limits
docker run -d --memory=512m --cpus=0.5 --pids-limit=100 <IMAGE>

# Non-root override (image root user'a ayarlanmış olabilir)
docker run --user 1000:1000 <IMAGE>

# Network seç
docker run --network bridge|host|none|<NET_NAME> <IMAGE>

# Linux capabilities ayarla (least privilege)
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE <IMAGE>
```

## 🐚 Exec / Logs / Stats

```bash
# Çalışan container'a gir
docker exec -it app /bin/sh
docker exec -it app /bin/bash

# Tek komut çalıştır
docker exec app printenv DB_HOST
docker exec app cat /etc/hostname

# Loglar
docker logs app
docker logs -f --tail=100 --since=10m app
docker logs app 2>&1 | grep ERROR

# Resource kullanımı
docker stats
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Container detayı (her şey)
docker inspect app
docker inspect app --format '{{.NetworkSettings.IPAddress}}'
docker inspect app --format '{{json .Mounts}}' | jq
```

## 🌐 Networks

```bash
# Network listesi
docker network ls
docker network inspect bridge

# Custom network
docker network create app-net
docker network create --driver bridge --subnet 172.20.0.0/16 app-net

# Container'ı network'e bağla
docker network connect app-net app
docker network disconnect bridge app

# DNS isim çözümlemesi (custom network'te otomatik)
docker run --network app-net --name api <IMAGE>
docker run --network app-net curlimages/curl curl http://api:8080  # hostname olarak çalışır
```

## 💾 Volumes

```bash
# Volume listesi
docker volume ls
docker volume inspect <VOLUME>

# Named volume
docker run -v pgdata:/var/lib/postgresql/data postgres:16

# Bind mount (host path)
docker run -v $(pwd)/config:/etc/app:ro <IMAGE>

# tmpfs (RAM'de, disk yazmaz — security için)
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
# Tüm durmuş container'lar
docker container prune

# Tüm referans verilmemiş image'lar (dangling)
docker image prune

# Tüm kullanılmayan image'lar (dangling + unreferenced)
docker image prune -a

# Volume'lar (DİKKAT: data silinir)
docker volume prune

# Hepsi tek komutla
docker system prune -a --volumes

# Disk kullanımı raporu
docker system df
docker system df -v       # detaylı
```

## 🔐 Registry

```bash
# Login
docker login <REGISTRY>
docker login ghcr.io -u <USER>             # token stdin'den

# Tag + push
docker tag local-image <REGISTRY>/<IMAGE>:<TAG>
docker push <REGISTRY>/<IMAGE>:<TAG>

# Pull specific platform
docker pull --platform linux/arm64 <IMAGE>

# Image manifest (digest'i öğren)
docker manifest inspect <REGISTRY>/<IMAGE>:<TAG>
```

## 🐳 Compose

```bash
# Up + detached
docker compose up -d
docker compose up -d --build           # tekrar build et
docker compose up -d --force-recreate

# Down
docker compose down
docker compose down -v                  # volume'leri de sil

# Specific service
docker compose up -d api
docker compose restart api
docker compose logs -f api

# Config validate
docker compose config
docker compose config --quiet           # syntax check, çıktı yok

# Service exec
docker compose exec api /bin/sh

# Resource sınırı
docker compose ps
docker compose top
docker compose stats
```

## 📋 BuildKit özel komutları

```bash
# BuildKit aktif et
export DOCKER_BUILDKIT=1

# buildx instance oluştur (multi-platform için gerekli)
docker buildx create --name mybuilder --use
docker buildx ls
docker buildx inspect --bootstrap

# History inspect (cache hit/miss debug)
docker buildx build --progress=plain ...
```

## 🔍 Image incele

```bash
# Layer'lara bak (her birinin boyutu)
docker history <IMAGE>
docker history <IMAGE> --no-trunc

# Image içeriği (filesystem)
docker save <IMAGE> -o image.tar
tar tf image.tar
# veya:
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest <IMAGE>

# Image labels
docker inspect <IMAGE> --format '{{json .Config.Labels}}' | jq

# Image config
docker inspect <IMAGE> --format '{{json .Config}}' | jq
```

## ⚡ Faydalı one-liner'lar

```bash
# Tüm container'ları durdur
docker stop $(docker ps -q)

# Tüm container'ları sil (durmuş + çalışan)
docker rm -f $(docker ps -aq)

# Bir image'a bağlı tüm container'ları öldür
docker ps -a -q --filter ancestor=<IMAGE> | xargs docker rm -f

# Belirli pattern'lı image'ları sil
docker images --format '{{.Repository}}:{{.Tag}}' | grep '<PATTERN>' | xargs docker rmi

# Container disk kullanımı
docker ps --size

# Image vulnerability scan
docker scout cves <IMAGE>
trivy image <IMAGE>
grype <IMAGE>
```

## 🆘 "Acil" senaryolar

| Sorun | Çözüm |
|---|---|
| `Cannot connect to Docker daemon` | `sudo systemctl start docker`; user `docker` group'ta mı? |
| `permission denied` (volume mount) | SELinux: `:Z` ekle (`-v $PWD:/app:Z`); user/group eşleştir |
| Imaj çok büyük | `dive` ile layer analizi; multi-stage build; `.dockerignore` |
| Build cache hit etmiyor | `COPY` sırasını değiştir (least-changing önce); `--no-cache` ile diff'i gör |
| `OCI runtime exec failed` | imaj `/bin/sh` veya `/bin/bash` içermiyor; `BusyBox` ile başla |
| Container restarting (loop) | `docker logs <NAME>` → entrypoint hatası; `restart: no` ile başlat, `docker exec` |
| `no space left on device` | `docker system prune -a --volumes`; `df -h /var/lib/docker` |
