# 🚀 GitHub Actions Pipeline Kurulum Rehberi

## 📁 **ADIM 1: Repository Yapısını Organize Et**

### Proje Klasör Yapısı:
```
my-devops-project/
├── .github/
│   └── workflows/
│       ├── ci-cd.yml
│       └── cleanup.yml
├── k8s/
│   ├── base/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── ingress.yaml
│   │   └── kustomization.yaml
│   ├── staging/
│   │   └── kustomization.yaml
│   └── production/
│       ├── cluster-a/
│       │   └── kustomization.yaml
│       └── cluster-b/
│           └── kustomization.yaml
├── src/
│   ├── app.js (örnek uygulama)
│   ├── package.json
│   └── Dockerfile
├── scripts/
│   ├── health-check.sh
│   └── deploy.sh
├── README.md
└── .dockerignore
```

---

## 🐳 **ADIM 2: Örnek Uygulama ve Dockerfile Hazırla**

### Basit Node.js Uygulaması (`src/app.js`):
```javascript
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Health check endpoints
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/ready', (req, res) => {
  res.status(200).json({ status: 'ready', timestamp: new Date().toISOString() });
});

app.get('/', (req, res) => {
  res.json({ 
    message: 'Hello from DevOps Pipeline!', 
    version: process.env.APP_VERSION || '1.0.0',
    cluster: process.env.CLUSTER_NAME || 'unknown'
  });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
```

### `src/package.json`:
```json
{
  "name": "devops-demo-app",
  "version": "1.0.0",
  "description": "Demo app for DevOps pipeline",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "test": "echo \"No tests yet\" && exit 0"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

### Optimized Dockerfile (`src/Dockerfile`):
```dockerfile
# Multi-stage build for smaller image
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine AS production
WORKDIR /app

# Security: Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Copy application
COPY --from=builder /app/node_modules ./node_modules
COPY --chown=nextjs:nodejs . .

# Security: Run as non-root
USER nextjs

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["npm", "start"]
```

### `.dockerignore`:
```
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
coverage
.nyc_output
.DS_Store
.vscode
.github
k8s
scripts
```

---

## ⚙️ **ADIM 3: Kubernetes Manifests Hazırla**

### Base Deployment (`k8s/base/deployment.yaml`):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: devops-app
  labels:
    app: devops-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: devops-app
  template:
    metadata:
      labels:
        app: devops-app
    spec:
      containers:
      - name: app
        image: ghcr.io/USERNAME/devops-app:latest # Bu kısmı kendi username'inle değiştir
        ports:
        - containerPort: 3000
        env:
        - name: APP_VERSION
          value: "1.0.0"
        - name: CLUSTER_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        startupProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 30
```

### Service (`k8s/base/service.yaml`):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: devops-app-service
  labels:
    app: devops-app
spec:
  selector:
    app: devops-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: ClusterIP
```

### Ingress (`k8s/base/ingress.yaml`):
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: devops-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - host: devops-app.local # Test için local host
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: devops-app-service
            port:
              number: 80
```

### Base Kustomization (`k8s/base/kustomization.yaml`):
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- deployment.yaml
- service.yaml
- ingress.yaml

commonLabels:
  environment: base
  project: devops-demo
```

### Staging Kustomization (`k8s/staging/kustomization.yaml`):
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: staging

resources:
- ../base

patchesStrategicMerge:
- deployment-patch.yaml

commonLabels:
  environment: staging

images:
- name: ghcr.io/USERNAME/devops-app
  newTag: staging-latest
```

### Staging Deployment Patch (`k8s/staging/deployment-patch.yaml`):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: devops-app
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: app
        env:
        - name: ENVIRONMENT
          value: "staging"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
```

---

## 🔧 **ADIM 4: GitHub Actions Workflow Oluştur**

### Ana CI/CD Pipeline (`.github/workflows/ci-cd.yml`):
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
  build-and-test:
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
      image-digest: ${{ steps.build.outputs.digest }}
      version: ${{ steps.version.outputs.version }}
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
      with:
        fetch-depth: 0

    - name: Set up Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: src/package-lock.json

    - name: Install dependencies
      run: |
        cd src
        npm ci

    - name: Run tests
      run: |
        cd src
        npm test

    - name: Generate version
      id: version
      run: |
        if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
          VERSION="v$(date +%Y%m%d)-${GITHUB_SHA:0:7}"
        else
          VERSION="${{ github.ref_name }}-${GITHUB_SHA:0:7}"
        fi
        echo "version=$VERSION" >> $GITHUB_OUTPUT
        echo "Generated version: $VERSION"

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
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=raw,value=${{ steps.version.outputs.version }}
          type=raw,value=latest,enable={{is_default_branch}}

    - name: Build and push Docker image
      id: build
      uses: docker/build-push-action@v5
      with:
        context: ./src
        platforms: linux/amd64
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

    - name: Sign container image
      run: |
        echo "Container image built and pushed successfully!"
        echo "Tags: ${{ steps.meta.outputs.tags }}"

  deploy-staging:
    needs: build-and-test
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    environment: staging
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Setup kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'

    - name: Setup Kustomize
      run: |
        curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
        sudo mv kustomize /usr/local/bin/

    - name: Setup kubeconfig for staging
      run: |
        mkdir -p ~/.kube
        echo "${{ secrets.KUBECONFIG_STAGING }}" | base64 -d > ~/.kube/config
        chmod 600 ~/.kube/config

    - name: Create staging namespace
      run: |
        kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -

    - name: Deploy to staging
      run: |
        cd k8s/staging
        kustomize edit set image ghcr.io/${{ github.repository }}=${{ needs.build-and-test.outputs.image-tag }}
        kustomize build . | kubectl apply -f -
        
    - name: Wait for deployment
      run: |
        kubectl rollout status deployment/devops-app -n staging --timeout=300s
        
    - name: Verify deployment
      run: |
        kubectl get pods -n staging
        kubectl get services -n staging
        
    - name: Run health check
      run: |
        # Pod seviyesinde health check
        kubectl exec -n staging deployment/devops-app -- curl -f http://localhost:3000/health
        echo "✅ Staging deployment successful!"

  deploy-production:
    needs: build-and-test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    
    strategy:
      matrix:
        cluster: [cluster-a, cluster-b]
      fail-fast: false
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Setup kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'

    - name: Setup Kustomize
      run: |
        curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
        sudo mv kustomize /usr/local/bin/

    - name: Setup kubeconfig for ${{ matrix.cluster }}
      run: |
        mkdir -p ~/.kube
        if [[ "${{ matrix.cluster }}" == "cluster-a" ]]; then
          echo "${{ secrets.KUBECONFIG_PROD_A }}" | base64 -d > ~/.kube/config
        else
          echo "${{ secrets.KUBECONFIG_PROD_B }}" | base64 -d > ~/.kube/config
        fi
        chmod 600 ~/.kube/config

    - name: Create production namespace
      run: |
        kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -

    - name: Deploy to ${{ matrix.cluster }}
      run: |
        cd k8s/production/${{ matrix.cluster }}
        kustomize edit set image ghcr.io/${{ github.repository }}=${{ needs.build-and-test.outputs.image-tag }}
        kustomize build . | kubectl apply -f -
        
    - name: Wait for deployment on ${{ matrix.cluster }}
      run: |
        kubectl rollout status deployment/devops-app -n production --timeout=300s
        
    - name: Verify deployment on ${{ matrix.cluster }}
      run: |
        kubectl get pods -n production
        kubectl get services -n production
        
    - name: Health check on ${{ matrix.cluster }}
      run: |
        kubectl exec -n production deployment/devops-app -- curl -f http://localhost:3000/health
        echo "✅ Production deployment successful on ${{ matrix.cluster }}!"

    - name: Post-deployment notification
      if: success()
      run: |
        echo "🚀 Successfully deployed to ${{ matrix.cluster }}"
        echo "Version: ${{ needs.build-and-test.outputs.version }}"
        echo "Image: ${{ needs.build-and-test.outputs.image-tag }}"

  cleanup:
    needs: [deploy-staging, deploy-production]
    if: always()
    runs-on: ubuntu-latest
    
    steps:
    - name: Cleanup old images
      run: |
        echo "🧹 Cleanup job completed (placeholder for future image cleanup logic)"
```

---

## 🔑 **ADIM 5: GitHub Secrets Kurulumu**

### Repository Settings → Secrets and Variables → Actions

Aşağıdaki secret'ları eklemen gerekiyor:

#### 1. Kubeconfig Files:
```bash
# Staging cluster için kubeconfig'i base64 encode et
cat ~/.kube/config | base64 -w 0
# Çıktıyı KUBECONFIG_STAGING olarak ekle

# Production cluster-a için (aynı işlemi production cluster'ınla tekrarla)
# KUBECONFIG_PROD_A olarak ekle

# Production cluster-b için (ikinci production cluster kurulduğunda)
# KUBECONFIG_PROD_B olarak ekle
```

#### 2. Environment Variables (Opsiyonel):
- `SLACK_WEBHOOK_URL`: Bildirimler için
- `DOCKER_REGISTRY_PASSWORD`: Ekstra güvenlik için

---

## 🚀 **ADIM 6: İlk Deployment Test**

### 1. Repository'yi Oluştur ve Push Et:
```bash
# GitHub'da yeni repo oluştur: my-devops-project

# Local'de initialize et
git init
git add .
git commit -m "Initial DevOps pipeline setup"
git branch -M main
git remote add origin https://github.com/USERNAME/my-devops-project.git
git push -u origin main

# Development branch oluştur
git checkout -b develop
git push -u origin develop
```

### 2. Kubernetes'te Ingress Controller Kurulumu:
```bash
# NGINX Ingress Controller kur
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml

# Ingress controller'ın çalıştığını kontrol et
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

### 3. Test Deployment:
```bash
# Develop branch'e push yaparak staging deploy'u tetikle
echo "Test change" >> README.md
git add README.md
git commit -m "Test staging deployment"
git push origin develop

# GitHub Actions'ı izle
# https://github.com/USERNAME/my-devops-project/actions
```

### 4. Local Test:
```bash
# Staging'e deploy edildikten sonra test et
kubectl get pods -n staging
kubectl get svc -n staging

# Port forward ile test
kubectl port-forward -n staging service/devops-app-service 8080:80

# Browser'da http://localhost:8080 aç
# Ya da curl ile test et
curl http://localhost:8080
curl http://localhost:8080/health
```

## 🚨 **Troubleshooting**

### GitHub Actions Hataları:
```bash
# Actions sekmesinde hata görürsen, logs'u kontrol et
# Yaygın hatalar:
# 1. Kubeconfig secret eksik/yanlış
# 2. Image tag formatting hataları
# 3. Kubernetes namespace yoksa

# Debug için manuel test:
kubectl auth can-i get pods --namespace staging
kubectl get nodes
```

### Deployment Hataları:
```bash
# Pod'ların durumunu kontrol et
kubectl get pods -n staging
kubectl describe pod POD_NAME -n staging
kubectl logs POD_NAME -n staging

# Service connectivity test
kubectl exec -it POD_NAME -n staging -- curl http://devops-app-service/health
```
