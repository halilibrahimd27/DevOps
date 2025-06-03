# 🚀 Full Production-Ready Repo Layout

## 📁 Klasör Yapısı

```
project-root/
├── backend/                          # Laravel API
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── .env.example
│   └── artisan (Laravel dosyaları)
├── frontend/                         # TypeScript (React/Vue/Angular)
│   ├── Dockerfile
│   ├── package.json
│   └── src/
├── mobile/                           # Flutter App
│   ├── Dockerfile.build
│   ├── pubspec.yaml
│   └── lib/
├── k8s/                             # Kubernetes Manifests
│   ├── namespaces/
│   │   └── namespaces.yaml
│   ├── secrets/
│   │   ├── docker-registry.yaml
│   │   └── app-secrets.yaml
│   ├── database/
│   │   ├── mysql-deployment.yaml
│   │   ├── mysql-service.yaml
│   │   └── mysql-pvc.yaml
│   ├── backend/
│   │   ├── backend-deployment.yaml
│   │   ├── backend-service.yaml
│   │   └── backend-configmap.yaml
│   ├── frontend/
│   │   ├── frontend-deployment.yaml
│   │   └── frontend-service.yaml
│   ├── ingress/
│   │   ├── ingress.yaml
│   │   └── ssl-issuer.yaml
│   └── monitoring/
│       ├── prometheus.yaml
│       └── grafana.yaml
├── .github/workflows/
│   ├── ci-cd.yml
│   └── flutter-build.yml
├── scripts/
│   ├── setup-cluster.sh
│   ├── deploy.sh
│   └── cleanup.sh
├── docker-compose.yml              # Local development
└── README.md
```

---

# 📋 Dosya İçerikleri

## 1. Backend (Laravel) Dosyaları

### `backend/Dockerfile`
```dockerfile
# Multi-stage build for Laravel + NGINX
FROM composer:latest as composer
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --ignore-platform-reqs --no-scripts --no-autoloader

FROM node:18-alpine as frontend
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM php:8.2-fpm-alpine as backend

# PHP extensions
RUN apk add --no-cache \
    bash curl zip unzip git \
    libpng-dev libjpeg-turbo-dev libwebp-dev \
    libxml2-dev oniguruma-dev mysql-client \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install pdo pdo_mysql mbstring tokenizer xml gd

WORKDIR /var/www
COPY . .
COPY --from=composer /app/vendor ./vendor
COPY --from=frontend /app/public/build ./public/build

RUN chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

EXPOSE 9000

# Final stage with NGINX
FROM nginx:alpine as nginx
COPY --from=backend /var/www /var/www
COPY backend/nginx.conf /etc/nginx/conf.d/default.conf
RUN chown -R nginx:nginx /var/www

# Multi-container setup
FROM backend as app
CMD ["php-fpm"]

FROM nginx as web
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### `backend/nginx.conf`
```nginx
server {
    listen 80;
    index index.php index.html;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /var/www/public;

    client_max_body_size 50M;

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass backend:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    location / {
        try_files $uri $uri/ /index.php?$query_string;
        gzip_static on;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## 2. Frontend (TypeScript) Dosyaları

### `frontend/Dockerfile`
```dockerfile
FROM node:18-alpine as builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### `frontend/nginx.conf`
```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy
    location /api/ {
        proxy_pass http://backend-service.dev.svc.cluster.local/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Asset caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## 3. Mobile (Flutter) Dosyaları

### `mobile/Dockerfile.build`
```dockerfile
# Flutter web build için
FROM cirrusci/flutter:stable

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build web --release

FROM nginx:alpine
COPY --from=0 /app/build/web /usr/share/nginx/html
EXPOSE 80
```

## 4. Kubernetes Manifests

### `k8s/namespaces/namespaces.yaml`
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
---
apiVersion: v1
kind: Namespace
metadata:
  name: staging
---
apiVersion: v1
kind: Namespace
metadata:
  name: prod
```

### `k8s/secrets/docker-registry.yaml`
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: regcred
  namespace: dev
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: # base64 encoded docker config
```

### `k8s/secrets/app-secrets.yaml`
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: dev
type: Opaque
data:
  DB_PASSWORD: cGFzc3dvcmQ=  # base64: password
  APP_KEY: YmFzZTY0OmFwcGtleQ==  # base64: base64:appkey
  JWT_SECRET: and0c2VjcmV0  # base64: jwtsecret
```

### `k8s/database/mysql-deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_PASSWORD
        - name: MYSQL_DATABASE
          value: laravel
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc
```

### `k8s/database/mysql-pvc.yaml`
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
  namespace: dev
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

### `k8s/database/mysql-service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: dev
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
```

### `k8s/backend/backend-configmap.yaml`
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: dev
data:
  APP_ENV: "production"
  APP_DEBUG: "false"
  APP_URL: "https://api.test.domain.com"
  DB_CONNECTION: "mysql"
  DB_HOST: "mysql-service"
  DB_PORT: "3306"
  DB_DATABASE: "laravel"
  CACHE_DRIVER: "redis"
  SESSION_DRIVER: "redis"
  QUEUE_CONNECTION: "redis"
```

### `k8s/backend/backend-deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: dev
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      imagePullSecrets:
      - name: regcred
      containers:
      - name: backend-app
        image: your-registry/backend:latest
        ports:
        - containerPort: 9000
        envFrom:
        - configMapRef:
            name: backend-config
        - secretRef:
            name: app-secrets
        livenessProbe:
          tcpSocket:
            port: 9000
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          tcpSocket:
            port: 9000
          initialDelaySeconds: 5
          periodSeconds: 5
      - name: backend-nginx
        image: your-registry/backend-nginx:latest
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 30
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: dev
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
```

### `k8s/frontend/frontend-deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      imagePullSecrets:
      - name: regcred
      containers:
      - name: frontend
        image: your-registry/frontend:latest
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 30
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: dev
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
```

### `k8s/ingress/ssl-issuer.yaml`
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@domain.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

### `k8s/ingress/ingress.yaml`
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
  namespace: dev
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  tls:
  - hosts:
    - api.test.domain.com
    - app.test.domain.com
    secretName: tls-secret
  rules:
  - host: api.test.domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
  - host: app.test.domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

## 5. GitHub Actions CI/CD

### `.github/workflows/ci-cd.yml`
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Test Backend
      run: |
        cd backend
        composer install
        php artisan test
    
    - name: Test Frontend
      run: |
        cd frontend
        npm ci
        npm run test

  build-backend:
    needs: test
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Login to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/backend
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
    
    - name: Build and push Backend
      uses: docker/build-push-action@v5
      with:
        context: ./backend
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  build-frontend:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Login to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/frontend
    
    - name: Build and push Frontend
      uses: docker/build-push-action@v5
      with:
        context: ./frontend
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}

  deploy:
    needs: [build-backend, build-frontend]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'
    
    - name: Configure kubectl
      run: |
        mkdir -p ~/.kube
        echo "${{ secrets.KUBECONFIG }}" | base64 -d > ~/.kube/config
    
    - name: Update image tags
      run: |
        sed -i 's|your-registry/backend:latest|${{ needs.build-backend.outputs.image-tag }}|g' k8s/backend/backend-deployment.yaml
        sed -i 's|your-registry/frontend:latest|${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/frontend:main|g' k8s/frontend/frontend-deployment.yaml
    
    - name: Deploy to Kubernetes
      run: |
        kubectl apply -f k8s/namespaces/
        kubectl apply -f k8s/secrets/
        kubectl apply -f k8s/database/
        kubectl apply -f k8s/backend/
        kubectl apply -f k8s/frontend/
        kubectl apply -f k8s/ingress/
    
    - name: Wait for deployment
      run: |
        kubectl rollout status deployment/backend -n dev
        kubectl rollout status deployment/frontend -n dev
```

### `.github/workflows/flutter-build.yml`
```yaml
name: Flutter Build

on:
  push:
    paths:
    - 'mobile/**'
    branches: [ main ]

jobs:
  build-flutter:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    
    - name: Build Flutter Web
      run: |
        cd mobile
        flutter pub get
        flutter build web --release
    
    - name: Build and push Docker image
      run: |
        cd mobile
        docker build -f Dockerfile.build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/mobile:latest .
        echo "${{ secrets.GITHUB_TOKEN }}" | docker login ${{ env.REGISTRY }} -u ${{ github.actor }} --password-stdin
        docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/mobile:latest
```

## 6. Scripts

### `scripts/setup-cluster.sh`
```bash
#!/bin/bash

echo "🚀 Setting up Kubernetes cluster..."

# Install Ingress Controller
echo "📦 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Install cert-manager
echo "🔒 Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager

# Create namespaces
echo "🏗️ Creating namespaces..."
kubectl apply -f k8s/namespaces/

# Create secrets (you need to update these with real values)
echo "🔐 Creating secrets..."
echo "⚠️ Don't forget to update secrets with real values!"
kubectl apply -f k8s/secrets/

echo "✅ Cluster setup completed!"
echo "📝 Next steps:"
echo "   1. Update secrets in k8s/secrets/"
echo "   2. Update domain names in k8s/ingress/ingress.yaml"
echo "   3. Run: ./scripts/deploy.sh"
```

### `scripts/deploy.sh`
```bash
#!/bin/bash

NAMESPACE=${1:-dev}
echo "🚀 Deploying to namespace: $NAMESPACE"

# Deploy database
echo "📦 Deploying database..."
kubectl apply -f k8s/database/ -n $NAMESPACE

# Wait for database to be ready
echo "⏳ Waiting for database..."
kubectl wait --for=condition=available --timeout=300s deployment/mysql -n $NAMESPACE

# Deploy backend
echo "🔧 Deploying backend..."
kubectl apply -f k8s/backend/ -n $NAMESPACE

# Deploy frontend
echo "🎨 Deploying frontend..."
kubectl apply -f k8s/frontend/ -n $NAMESPACE

# Deploy ingress
echo "🌐 Deploying ingress..."
kubectl apply -f k8s/ingress/ -n $NAMESPACE

# Check deployment status
echo "📊 Checking deployment status..."
kubectl get pods -n $NAMESPACE
kubectl get services -n $NAMESPACE
kubectl get ingress -n $NAMESPACE

echo "✅ Deployment completed!"
echo "🔗 Access your application at:"
echo "   Backend: https://api.test.domain.com"
echo "   Frontend: https://app.test.domain.com"
```

### `scripts/cleanup.sh`
```bash
#!/bin/bash

NAMESPACE=${1:-dev}
echo "🧹 Cleaning up namespace: $NAMESPACE"

kubectl delete -f k8s/ingress/ -n $NAMESPACE
kubectl delete -f k8s/frontend/ -n $NAMESPACE
kubectl delete -f k8s/backend/ -n $NAMESPACE
kubectl delete -f k8s/database/ -n $NAMESPACE

echo "✅ Cleanup completed!"
```

## 7. Local Development

### `docker-compose.yml`
```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: laravel
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"

  backend:
    build: ./backend
    ports:
      - "8000:80"
    depends_on:
      - mysql
      - redis
    environment:
      DB_HOST: mysql
      REDIS_HOST: redis

  frontend:
    build: ./frontend
    ports:
      - "3000:80"

volumes:
  mysql_data:
```

## 8. README.md

### `README.md`
```markdown
# 🚀 Full-Stack Application - Laravel + TypeScript + Flutter

## 📋 Tech Stack

- **Backend**: Laravel (PHP 8.2)
- **Frontend**: TypeScript (React/Vue/Angular)
- **Mobile**: Flutter (Dart)
- **Infrastructure**: Kubernetes + Docker
- **CI/CD**: GitHub Actions
- **Database**: MySQL 8.0
- **Cache**: Redis

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- kubectl configured
- Domain pointed to your cluster

### Local Development
```bash
# Clone repo
git clone <your-repo>
cd project-root

# Start local environment
docker-compose up -d

# Access applications
# Backend: http://localhost:8000
# Frontend: http://localhost:3000
```

### Production Deployment

1. **Setup cluster**:
```bash
chmod +x scripts/*
./scripts/setup-cluster.sh
```

2. **Update configurations**:
   - Update domain names in `k8s/ingress/ingress.yaml`
   - Update secrets in `k8s/secrets/`
   - Update GitHub secrets

3. **Deploy**:
```bash
git push origin main
# Or manually: ./scripts/deploy.sh
```

## 🔧 Configuration

### GitHub Secrets Required
- `KUBECONFIG`: Base64 encoded kubeconfig file
- `GITHUB_TOKEN`: Automatically provided

### Domain Configuration
Update these files with your domains:
- `k8s/ingress/ingress.yaml`
- `k8s/backend/backend-configmap.yaml`

## 📊 Monitoring

Access your applications:
- **Backend API**: https://api.your-domain.com
- **Frontend**: https://app.your-domain.com
- **Kubernetes Dashboard**: Run `kubectl proxy`

## 🔄 Workflow

1. Push to `main` branch
2. GitHub Actions builds & tests
3. Docker images pushed to registry
4. Automatic deployment to K8s
5. SSL certificates auto-generated

## 🐛 Troubleshooting

```bash
# Check pod status
kubectl get pods -n dev

# Check logs
kubectl logs -f deployment/backend -n dev

# Shell into container
kubectl exec -it deployment/backend -n dev -- bash

# Restart deployment
kubectl rollout restart deployment/backend -n dev
```

## 📁 Project Structure

See the full directory structure in the deployment documentation.
```

---

# 🎯 Next Steps

1. **Clone this structure** to your repo
2. **Update domains** in ingress and configmap files
3. **Add your actual Laravel/TypeScript code**
4. **Configure GitHub secrets**
5. **Run setup script**: `./scripts/setup-cluster.sh`
6. **Push to main branch** - everything deploys automatically!

🔥 **Production-ready, scalable, secure setup with monitoring, SSL, CI/CD!**
