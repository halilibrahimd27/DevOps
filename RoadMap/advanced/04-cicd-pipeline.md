# 🔄 **PHASE 4: CI/CD PIPELINE KURULUMU** (Gün 8-10)

### 🛠️ **5.1 Jenkins on Kubernetes Setup**

```bash
# 5.1.1 Jenkins namespace ve RBAC oluştur
cd ~/devops-infrastructure/kubernetes/base
mkdir -p jenkins

cat > jenkins/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: jenkins
  labels:
    name: jenkins
EOF

cat > jenkins/serviceaccount.yaml << 'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: jenkins
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: jenkins
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["create","delete","get","list","patch","update","watch"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create","delete","get","list","patch","update","watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get","list","watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get","list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: jenkins
subjects:
- kind: ServiceAccount
  name: jenkins
  namespace: jenkins
EOF

cat > jenkins/pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pvc
  namespace: jenkins
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 10Gi
EOF

cat > jenkins/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      serviceAccountName: jenkins
      containers:
      - name: jenkins
        image: jenkins/jenkins:2.414.1-lts-jdk11
        ports:
        - containerPort: 8080
        - containerPort: 50000
        env:
        - name: JAVA_OPTS
          value: "-Xmx2048m -Dhudson.slaves.NodeProvisioner.MARGIN=50 -Dhudson.slaves.NodeProvisioner.MARGIN0=0.85"
        - name: JENKINS_OPTS
          value: "--httpPort=8080"
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        - name: docker-sock
          mountPath: /var/run/docker.sock
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 5
        readinessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
      volumes:
      - name: jenkins-home
        persistentVolumeClaim:
          claimName: jenkins-pvc
      - name: docker-sock
        hostPath:
          path: /var/run/docker.sock
      securityContext:
        fsGroup: 1000
        runAsUser: 1000
EOF

cat > jenkins/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: jenkins
  namespace: jenkins
spec:
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  - name: jnlp
    port: 50000
    targetPort: 50000
  selector:
    app: jenkins
  type: ClusterIP
EOF

cat > jenkins/ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jenkins
  namespace: jenkins
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - jenkins.yourdomain.com
    secretName: jenkins-tls
  rules:
  - host: jenkins.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: jenkins
            port:
              number: 8080
EOF

# 5.1.2 Jenkins deploy
kubectl apply -f jenkins/
kubectl get pods -n jenkins
kubectl logs -f deployment/jenkins -n jenkins
```

### 🌐 **5.2 NGINX Ingress Controller Setup**

```bash
# 5.2.1 NGINX Ingress Controller kurulumu
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-cross-zone-load-balancing-enabled"="true"

# 5.2.2 Ingress controller durumunu kontrol et
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# 5.2.3 External IP'yi al
EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "External LoadBalancer: $EXTERNAL_IP"
```

### 🔐 **5.3 Cert-Manager Setup (SSL/TLS)**

```bash
# 5.3.1 Cert-Manager kurulumu
helm repo add jetstack https://charts.jetstack.io
helm repo update

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0

# 5.3.2 Let's Encrypt ClusterIssuer
cat > ~/devops-infrastructure/kubernetes/base/cert-manager-issuer.yaml << 'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@yourdomain.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@yourdomain.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

kubectl apply -f ~/devops-infrastructure/kubernetes/base/cert-manager-issuer.yaml

# 5.3.3 Cert-manager durumunu kontrol et
kubectl get pods -n cert-manager
kubectl get clusterissuers
```

### 🔧 **5.4 Jenkins Initial Setup**

```bash
# 5.4.1 Jenkins admin password'unu al
kubectl exec -n jenkins -it deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword

# 5.4.2 Jenkins URL'sine eriş (port-forward ile)
kubectl port-forward -n jenkins svc/jenkins 8080:8080

# 5.4.3 Jenkins Initial Setup (Browser üzerinden)
# http://localhost:8080
# - Initial password gir
# - Suggested plugins install et
# - Admin user oluştur
# - Jenkins URL'yi ayarla

# 5.4.4 Essential Jenkins plugins kurulumu (Browser üzerinden)
# Manage Jenkins -> Manage Plugins -> Available
# - Blue Ocean
# - Pipeline
# - Git Pipeline for Blue Ocean
# - Docker Pipeline
# - Kubernetes CLI
# - GitHub Integration
# - Slack Notification
# - Build Timestamp
# - AnsiColor
# - Workspace Cleanup
```

### 📝 **5.5 Jenkins Pipeline as Code**

```bash
# 5.5.1 Shared Pipeline Library oluştur
mkdir -p ~/devops-infrastructure/jenkins/shared-library/{vars,src,resources}

cat > ~/devops-infrastructure/jenkins/shared-library/vars/buildAndPush.groovy << 'EOF'
def call(Map config) {
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
                  - name: kubectl
                    image: bitnami/kubectl:latest
                    command:
                    - cat
                    tty: true
                  - name: helm
                    image: alpine/helm:latest
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
            IMAGE_NAME = "${config.imageName}"
            GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
            BUILD_VERSION = "${env.BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
        }
        
        stages {
            stage('Checkout') {
                steps {
                    checkout scm
                }
            }
            
            stage('Build Info') {
                steps {
                    script {
                        currentBuild.displayName = "#${env.BUILD_NUMBER} - ${BUILD_VERSION}"
                        currentBuild.description = "Branch: ${env.BRANCH_NAME}"
                    }
                }
            }
            
            stage('Lint Dockerfile') {
                steps {
                    container('docker') {
                        sh '''
                            echo "🔍 Linting Dockerfile..."
                            # Dockerfile linting would go here
                        '''
                    }
                }
            }
            
            stage('Build Docker Image') {
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
            
            stage('Security Scan') {
                steps {
                    container('docker') {
                        sh '''
                            echo "🛡️ Running security scan..."
                            # Trivy scanning would go here
                        '''
                    }
                }
            }
            
            stage('Deploy to Dev') {
                when {
                    branch 'develop'
                }
                steps {
                    container('kubectl') {
                        sh '''
                            echo "🚀 Deploying to development..."
                            kubectl set image deployment/${IMAGE_NAME} ${IMAGE_NAME}=${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION} -n dev
                            kubectl rollout status deployment/${IMAGE_NAME} -n dev
                        '''
                    }
                }
            }
            
            stage('Deploy to Staging') {
                when {
                    branch 'main'
                }
                steps {
                    container('kubectl') {
                        sh '''
                            echo "🚀 Deploying to staging..."
                            kubectl set image deployment/${IMAGE_NAME} ${IMAGE_NAME}=${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION} -n staging
                            kubectl rollout status deployment/${IMAGE_NAME} -n staging
                        '''
                    }
                }
            }
            
            stage('Deploy to Production') {
                when {
                    buildingTag()
                }
                steps {
                    script {
                        timeout(time: 5, unit: 'MINUTES') {
                            input message: 'Deploy to production?', ok: 'Deploy'
                        }
                    }
                    container('kubectl') {
                        sh '''
                            echo "🚀 Deploying to production..."
                            kubectl set image deployment/${IMAGE_NAME} ${IMAGE_NAME}=${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION} -n production
                            kubectl rollout status deployment/${IMAGE_NAME} -n production
                        '''
                    }
                }
            }
        }
        
        post {
            success {
                slackSend(
                    channel: '#deployments',
                    color: 'good',
                    message: "✅ ${IMAGE_NAME} v${BUILD_VERSION} deployed successfully to ${env.BRANCH_NAME}"
                )
            }
            failure {
                slackSend(
                    channel: '#deployments',
                    color: 'danger',
                    message: "❌ ${IMAGE_NAME} v${BUILD_VERSION} deployment failed on ${env.BRANCH_NAME}"
                )
            }
        }
    }
}
EOF

# 5.5.2 Sample application Jenkinsfile
cat > ~/devops-infrastructure/jenkins/sample-Jenkinsfile << 'EOF'
@Library('shared-library') _

buildAndPush([
    imageName: 'mycompany/sample-app'
])
EOF
```

### 🔐 **5.6 Jenkins Credentials Setup**

```bash
# 5.6.1 GitHub credentials secret oluştur
kubectl create secret generic github-registry-credentials \
  --from-literal=username=YOUR_GITHUB_USERNAME \
  --from-literal=password=YOUR_GITHUB_TOKEN \
  --namespace=jenkins

# 5.6.2 AWS credentials secret oluştur
kubectl create secret generic aws-credentials \
  --from-literal=access-key-id=YOUR_AWS_ACCESS_KEY \
  --from-literal=secret-access-key=YOUR_AWS_SECRET_KEY \
  --namespace=jenkins

# 5.6.3 Jenkins'te credentials ekle (Browser üzerinden)
# Manage Jenkins -> Manage Credentials -> Global -> Add Credentials
# - GitHub Token: Kind=Username with password, ID=github-registry-credentials
# - AWS Credentials: Kind=AWS Credentials, ID=aws-credentials
# - Kubeconfig: Kind=Secret file, ID=kubeconfig
```

---
