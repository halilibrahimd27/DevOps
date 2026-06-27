---
description: "Faz 9 (Gün 21-22): GitOps ve deployment otomasyonu; ArgoCD kurulumu, CLI yükleme, initial admin parolası alma ve ArgoCD ingress yapılandırması."
---
# 🎯 **PHASE 9: GITOPS & DEPLOYMENT AUTOMATION** (Gün 21-22)

### 🔄 **10.1 ArgoCD Setup**

```bash
# 10.1.1 ArgoCD kurulumu
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 10.1.2 ArgoCD CLI kurulumu
wget https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# 10.1.3 ArgoCD initial password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD admin password: $ARGOCD_PASSWORD"

# 10.1.4 ArgoCD ingress
cat > argocd-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - argocd.yourdomain.com
    secretName: argocd-tls
  rules:
  - host: argocd.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
EOF

kubectl apply -f argocd-ingress.yaml

# 10.1.5 ArgoCD server configuration
kubectl patch configmap argocd-cmd-params-cm -n argocd --patch '{"data":{"server.insecure":"true"}}'
kubectl rollout restart deployment argocd-server -n argocd

# 10.1.6 ArgoCD login
argocd login argocd.yourdomain.com --username admin --password $ARGOCD_PASSWORD --insecure
```

### 📁 **10.2 GitOps Repository Structure**

```bash
# 10.2.1 GitOps repository oluştur
cd ~/
git clone https://github.com/yourusername/gitops-config.git
cd gitops-config

# Repository structure
mkdir -p {applications/{dev,staging,production},infrastructure/{monitoring,logging,security},bootstrap}

# 10.2.2 Application of Applications pattern
cat > bootstrap/root-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/gitops-config.git
    targetRevision: main
    path: bootstrap
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# 10.2.3 Infrastructure applications
cat > bootstrap/infrastructure-apps.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring-stack
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/gitops-config.git
    targetRevision: main
    path: infrastructure/monitoring
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: logging-stack
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/gitops-config.git
    targetRevision: main
    path: infrastructure/logging
  destination:
    server: https://kubernetes.default.svc
    namespace: logging
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: security-stack
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/gitops-config.git
    targetRevision: main
    path: infrastructure/security
  destination:
    server: https://kubernetes.default.svc
    namespace: security
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# 10.2.4 Environment-specific applications
cat > bootstrap/dev-apps.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dev-applications
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/gitops-config.git
    targetRevision: main
    path: applications/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# 10.2.5 Sample application manifest
cat > applications/dev/sample-app.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: dev
  labels:
    app: sample-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        runAsGroup: 10001
        fsGroup: 10001
      containers:
      - name: app
        image: ghcr.io/yourusername/sample-app:v1.0.0
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: url
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 10001
          runAsGroup: 10001
          capabilities:
            drop:
            - ALL
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
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: tmp
          mountPath: /tmp
      volumes:
      - name: tmp
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app
  namespace: dev
  labels:
    app: sample-app
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 8080
    name: http
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sample-app
  namespace: dev
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - app-dev.yourdomain.com
    secretName: sample-app-tls
  rules:
  - host: app-dev.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: sample-app
            port:
              number: 80
EOF

# Git'e commit
git add .
git commit -m "Initial GitOps repository structure"
git push origin main
```

### 🚀 **10.3 Progressive Delivery with Argo Rollouts**

```bash
# 10.3.1 Argo Rollouts kurulumu
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# 10.3.2 Argo Rollouts CLI
wget https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
sudo install -m 555 kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
rm kubectl-argo-rollouts-linux-amd64

# 10.3.3 Canary deployment example
cat > applications/dev/sample-app-rollout.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: sample-app-rollout
  namespace: dev
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {}
      - setWeight: 40
      - pause: {duration: 10}
      - setWeight: 60
      - pause: {duration: 10}
      - setWeight: 80
      - pause: {duration: 10}
      canaryService: sample-app-canary
      stableService: sample-app-stable
      trafficRouting:
        nginx:
          stableIngress: sample-app-stable
          annotationPrefix: nginx.ingress.kubernetes.io
          additionalIngressAnnotations:
            canary-by-header: X-Canary
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 2
        args:
        - name: service-name
          value: sample-app-canary.dev.svc.cluster.local
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: app
        image: ghcr.io/yourusername/sample-app:v1.0.0
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: url
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
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app-stable
  namespace: dev
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 8080
    name: http
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app-canary
  namespace: dev
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 8080
    name: http
---
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
  namespace: dev
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 30s
    successCondition: result[0] >= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090
        query: |
          sum(irate(
            http_requests_total{job="{{args.service-name}}",status!~"5.*"}[5m]
          )) /
          sum(irate(
            http_requests_total{job="{{args.service-name}}"}[5m]
          ))
EOF

# 10.3.4 Blue-Green deployment example
cat > applications/staging/sample-app-bluegreen.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: sample-app-bluegreen
  namespace: staging
spec:
  replicas: 3
  strategy:
    blueGreen:
      activeService: sample-app-active
      previewService: sample-app-preview
      autoPromotionEnabled: false
      scaleDownDelaySeconds: 30
      prePromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: sample-app-preview.staging.svc.cluster.local
      postPromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: sample-app-active.staging.svc.cluster.local
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: app
        image: ghcr.io/yourusername/sample-app:v1.0.0
        ports:
        - containerPort: 8080
          name: http
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app-active
  namespace: staging
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 8080
    name: http
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app-preview
  namespace: staging
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 8080
    name: http
EOF

# Changes'ları commit et
git add .
git commit -m "Add progressive delivery configurations"
git push origin main
```

### 🔧 **10.4 CI/CD Integration with GitOps**

```bash
# 10.4.1 Image updater için ArgoCD configuration
cat > argocd-image-updater.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-image-updater-config
  namespace: argocd
data:
  registries.conf: |
    registries:
    - name: GitHub Container Registry
      prefix: ghcr.io
      api_url: https://ghcr.io
      credentials: ext:/scripts/auth1.sh
      credsexpire: 10h
  ssh_config: |
    Host github.com
        User git
        IdentitiesOnly yes
        IdentityFile ~/.ssh/id_rsa
        StrictHostKeyChecking no
---
apiVersion: v1
kind: Secret
metadata:
  name: argocd-image-updater-secret
  namespace: argocd
type: Opaque
stringData:
  auth1.sh: |
    #!/bin/sh
    echo "username:$GITHUB_TOKEN"
EOF

kubectl apply -f argocd-image-updater.yaml

# 10.4.2 Application annotation for image updates
cat > applications/dev/sample-app-with-image-updater.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-app
  namespace: argocd
  annotations:
    argocd-image-updater.argoproj.io/image-list: myapp=ghcr.io/yourusername/sample-app
    argocd-image-updater.argoproj.io/write-back-method: git
    argocd-image-updater.argoproj.io/git-branch: main
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/gitops-config.git
    targetRevision: main
    path: applications/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# 10.4.3 Updated Jenkins pipeline with GitOps
cat > ~/devops-infrastructure/jenkins/gitops-pipeline.groovy << 'EOF'
@Library('shared-library') _

pipeline {
    agent {
        kubernetes {
            yaml """
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: docker
                image: docker:latest
                command:
                - cat
                tty: true
                volumeMounts:
                - mountPath: /var/run/docker.sock
                  name: docker-sock
              - name: git
                image: alpine/git:latest
                command:
                - cat
                tty: true
              volumes:
              - name: docker-sock
                hostPath:
                  path: /var/run/docker.sock
            """
        }
    }
    
    environment {
        DOCKER_REGISTRY = 'ghcr.io'
        IMAGE_NAME = 'yourusername/sample-app'
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
        BUILD_VERSION = "v1.0.${env.BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
        GITOPS_REPO = 'https://github.com/yourusername/gitops-config.git'
    }
    
    stages {
        stage('Build & Push') {
            steps {
                container('docker') {
                    script {
                        def image = docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION}")
                        docker.withRegistry("https://${DOCKER_REGISTRY}", 'github-registry-credentials') {
                            image.push()
                            image.push("latest")
                        }
                    }
                }
            }
        }
        
        stage('Update GitOps Repo') {
            steps {
                container('git') {
                    withCredentials([usernamePassword(credentialsId: 'github-credentials', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_TOKEN')]) {
                        sh '''
                            git config --global user.email "jenkins@company.com"
                            git config --global user.name "Jenkins CI"
                            
                            # Clone GitOps repository
                            git clone https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/yourusername/gitops-config.git
                            cd gitops-config
                            
                            # Update image tag in deployment manifest
                            sed -i "s|image: ${DOCKER_REGISTRY}/${IMAGE_NAME}:.*|image: ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION}|g" applications/dev/sample-app.yaml
                            
                            # Commit and push changes
                            git add .
                            git commit -m "Update ${IMAGE_NAME} to ${BUILD_VERSION}"
                            git push origin main
                        '''
                    }
                }
            }
        }
    }
    
    post {
        success {
            slackSend(
                channel: '#deployments',
                color: 'good',
                message: "✅ ${IMAGE_NAME}:${BUILD_VERSION} built and GitOps updated successfully"
            )
        }
        failure {
            slackSend(
                channel: '#deployments',
                color: 'danger',
                message: "❌ Pipeline failed for ${IMAGE_NAME}:${BUILD_VERSION}"
            )
        }
    }
}
EOF

# 10.4.4 ArgoCD'ye root application'ı deploy et
kubectl apply -f ~/gitops-config/bootstrap/root-app.yaml

echo "GitOps setup completed!"
echo "ArgoCD UI: https://argocd.yourdomain.com"
echo "Login: admin / $ARGOCD_PASSWORD"
```

---
