---
description: "Faz 3 (Gün 6-7): Containerization ve registry; GitHub Container Registry kurulumu, login, image push ve Docker multi-stage build şablonlarının hazırlanması."
tags:
  - Roadmap
  - Docker
  - Containers
  - CI/CD
---
# 🐳 **PHASE 3: CONTAINERIZATION VE REGISTRY** (Gün 6-7)

### 📦 **4.1 GitHub Container Registry Setup**

```bash
# 4.1.1 GitHub Personal Access Token oluştur
# GitHub -> Settings -> Developer settings -> Personal access tokens -> Tokens (classic)
# Permissions: write:packages, read:packages, delete:packages

# 4.1.2 GitHub Container Registry'ye login
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 4.1.3 Test image push
docker pull hello-world
docker tag hello-world ghcr.io/yourusername/hello-world:latest
docker push ghcr.io/yourusername/hello-world:latest
```

### 🏗️ **4.2 Docker Multi-Stage Build Templates**

```bash
# 4.2.1 Docker templates dizini
cd ~/devops-infrastructure/docker
mkdir -p {nodejs,python,golang,java,nginx}

# 4.2.2 Node.js Dockerfile template
cat > nodejs/Dockerfile << 'EOF'
# Multi-stage build for Node.js applications
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Build application
RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy built application from builder stage
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start application
CMD ["node", "dist/index.js"]
EOF

# 4.2.3 Python Dockerfile template
cat > python/Dockerfile << 'EOF'
# Multi-stage build for Python applications
FROM python:3.11-slim AS builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.11-slim AS production

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    dumb-init \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# Set working directory
WORKDIR /app

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python healthcheck.py

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start application
CMD ["python", "app.py"]
EOF

# 4.2.4 Golang Dockerfile template
cat > golang/Dockerfile << 'EOF'
# Multi-stage build for Go applications
FROM golang:1.21-alpine AS builder

# Install git for go modules
RUN apk add --no-cache git

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build application with optimizations
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o main .

# Production stage
FROM scratch AS production

# Add ca-certificates for HTTPS
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binary from builder
COPY --from=builder /app/main /main

# Expose port
EXPOSE 8080

# Health check (for scratch images, implement in Go)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/main", "-health"]

# Start application
ENTRYPOINT ["/main"]
EOF

# 4.2.5 Docker Compose template
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d myapp"]
      interval: 30s
      timeout: 5s
      retries: 3

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 5s
      retries: 3

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
EOF

# 4.2.6 .dockerignore
cat > .dockerignore << 'EOF'
# Git
.git
.gitignore

# Documentation
README.md
CHANGELOG.md
docs/

# Dependencies
node_modules/
vendor/
__pycache__/
*.pyc
target/

# Build artifacts
dist/
build/
*.log

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local
.env.*.local

# Testing
coverage/
.nyc_output/
test-results/

# Terraform
*.tfstate
*.tfstate.*
.terraform/

# Docker
Dockerfile*
docker-compose*
EOF
```

### 🔒 **4.3 Container Security Scanning Setup**

```bash
# 4.3.1 Trivy kurulumu (vulnerability scanner)
# Ubuntu/Debian
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install trivy

# macOS
brew install trivy

# 4.3.2 Hadolint kurulumu (Dockerfile linter)
# Ubuntu/Debian
wget -O hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
chmod +x hadolint
sudo mv hadolint /usr/local/bin/

# macOS
brew install hadolint

# 4.3.3 Container security scanning script
cat > ~/devops-infrastructure/scripts/container-security-scan.sh << 'EOF'
#!/bin/bash

# Container Security Scanning Script
set -e

IMAGE_NAME=$1
if [ -z "$IMAGE_NAME" ]; then
    echo "Usage: $0 <image-name>"
    exit 1
fi

echo "🔍 Starting security scan for $IMAGE_NAME..."

# 1. Dockerfile linting
echo "📋 Running Dockerfile lint..."
if [ -f "Dockerfile" ]; then
    hadolint Dockerfile || echo "⚠️  Dockerfile linting issues found"
else
    echo "❌ Dockerfile not found"
fi

# 2. Image vulnerability scanning
echo "🛡️  Running vulnerability scan..."
trivy image --exit-code 1 --severity HIGH,CRITICAL $IMAGE_NAME

# 3. Configuration scanning
echo "⚙️  Running configuration scan..."
trivy config --exit-code 1 .

# 4. Secret scanning
echo "🔐 Running secret scan..."
trivy fs --exit-code 1 --scanners secret .

echo "✅ Security scan completed for $IMAGE_NAME"
EOF

chmod +x ~/devops-infrastructure/scripts/container-security-scan.sh

# 4.3.4 Pre-commit hooks için security scanning
cat > ~/devops-infrastructure/.pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/hadolint/hadolint
    rev: v2.12.0
    hooks:
      - id: hadolint-docker
        args: [--config, .hadolint.yaml]

  - repo: https://github.com/aquasecurity/trivy
    rev: v0.48.0
    hooks:
      - id: trivy-docker
        args: [--exit-code, "1", --severity, "HIGH,CRITICAL"]

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict
EOF

# Hadolint config
cat > ~/devops-infrastructure/.hadolint.yaml << 'EOF'
ignored:
  - DL3008  # Pin versions in apt get install
  - DL3009  # Delete the apt-get lists after installing something
  - DL3015  # Avoid additional packages by specifying --no-install-recommends

trusted-registries:
  - docker.io
  - ghcr.io
  - quay.io
EOF
```

---
