---
description: "Faz 5 (Gün 11-13): Kubernetes ileri seviye kurulum; dev/staging/prod namespace'leri, RBAC ve Istio injection ile çok-ortamlı cluster yapılandırması."
tags:
  - Roadmap
  - Kubernetes
  - Service Mesh
  - Security
  - Networking
---
# ☸️ **PHASE 5: KUBERNETES ADVANCED SETUP** (Gün 11-13)

### 🏷️ **6.1 Namespace ve RBAC Setup**

```bash
# 6.1.1 Environment namespaces oluştur
cd ~/devops-infrastructure/kubernetes/base

cat > namespaces.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    environment: dev
    istio-injection: enabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    environment: staging
    istio-injection: enabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
    istio-injection: enabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
  labels:
    environment: monitoring
    istio-injection: disabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: logging
  labels:
    environment: logging
    istio-injection: disabled
EOF

kubectl apply -f namespaces.yaml

# 6.1.2 RBAC setup
cat > rbac.yaml << 'EOF'
# Developer Role - dev namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev
  name: developer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
---
# Staging Role - staging namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: staging
  name: staging-deployer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "update", "patch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
---
# Production Role - production namespace (read-only + deploy)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: production-deployer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "update", "patch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
---
# ServiceAccount for developers
apiVersion: v1
kind: ServiceAccount
metadata:
  name: developer
  namespace: dev
---
# ServiceAccount for staging
apiVersion: v1
kind: ServiceAccount
metadata:
  name: staging-deployer
  namespace: staging
---
# ServiceAccount for production
apiVersion: v1
kind: ServiceAccount
metadata:
  name: production-deployer
  namespace: production
---
# RoleBinding for developers
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: dev
subjects:
- kind: ServiceAccount
  name: developer
  namespace: dev
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
---
# RoleBinding for staging
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: staging-deployer-binding
  namespace: staging
subjects:
- kind: ServiceAccount
  name: staging-deployer
  namespace: staging
roleRef:
  kind: Role
  name: staging-deployer
  apiGroup: rbac.authorization.k8s.io
---
# RoleBinding for production
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: production-deployer-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: production-deployer
  namespace: production
roleRef:
  kind: Role
  name: production-deployer
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f rbac.yaml
```

### 📦 **6.2 StorageClass ve Persistent Volumes**

```bash
# 6.2.1 StorageClass definitions
cat > storage-classes.yaml << 'EOF'
# GP3 StorageClass (default)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
---
# GP3 Fast StorageClass
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-fast
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
  encrypted: "true"
  iops: "4000"
  throughput: "250"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
---
# IO1 StorageClass (high performance)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: io1
provisioner: ebs.csi.aws.com
parameters:
  type: io1
  fsType: ext4
  encrypted: "true"
  iops: "1000"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF

kubectl apply -f storage-classes.yaml
kubectl get storageclass
```

### 🔧 **6.3 Horizontal Pod Autoscaler (HPA) Setup**

```bash
# 6.3.1 Metrics Server kurulumu
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Metrics server düzeltmesi (EKS için)
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]'

# 6.3.2 HPA template
cat > hpa-template.yaml << 'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: sample-app-hpa
  namespace: dev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sample-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
EOF
```

### 🔄 **6.4 Cluster Autoscaler Setup**

```bash
# 6.4.1 Cluster Autoscaler kurulumu
cat > cluster-autoscaler.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    app: cluster-autoscaler
spec:
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
      annotations:
        prometheus.io/scrape: 'true'
        prometheus.io/port: '8085'
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
      - image: registry.k8s.io/autoscaling/cluster-autoscaler:v1.30.0
        name: cluster-autoscaler
        resources:
          limits:
            cpu: 100m
            memory: 300Mi
          requests:
            cpu: 100m
            memory: 300Mi
        command:
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=aws
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/CLUSTER_NAME
        env:
        - name: AWS_REGION
          value: eu-west-1
        volumeMounts:
        - name: ssl-certs
          mountPath: /etc/ssl/certs/ca-certificates.crt
          readOnly: true
        imagePullPolicy: "Always"
      volumes:
      - name: ssl-certs
        hostPath:
          path: "/etc/ssl/certs/ca-bundle.crt"
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
  name: cluster-autoscaler
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/cluster-autoscaler
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-autoscaler
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
rules:
- apiGroups: [""]
  resources: ["events", "endpoints"]
  verbs: ["create", "patch"]
- apiGroups: [""]
  resources: ["pods/eviction"]
  verbs: ["create"]
- apiGroups: [""]
  resources: ["pods/status"]
  verbs: ["update"]
- apiGroups: [""]
  resources: ["endpoints"]
  resourceNames: ["cluster-autoscaler"]
  verbs: ["get", "update"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["watch", "list", "get", "update"]
- apiGroups: [""]
  resources: ["pods", "services", "replicationcontrollers", "persistentvolumeclaims", "persistentvolumes"]
  verbs: ["watch", "list", "get"]
- apiGroups: ["extensions"]
  resources: ["replicasets", "daemonsets"]
  verbs: ["watch", "list", "get"]
- apiGroups: ["policy"]
  resources: ["poddisruptionbudgets"]
  verbs: ["watch", "list"]
- apiGroups: ["apps"]
  resources: ["statefulsets", "replicasets", "daemonsets"]
  verbs: ["watch", "list", "get"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"]
  verbs: ["watch", "list", "get"]
- apiGroups: ["batch", "extensions"]
  resources: ["jobs"]
  verbs: ["get", "list", "watch", "patch"]
- apiGroups: ["coordination.k8s.io"]
  resources: ["leases"]
  verbs: ["create"]
- apiGroups: ["coordination.k8s.io"]
  resourceNames: ["cluster-autoscaler"]
  resources: ["leases"]
  verbs: ["get", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-autoscaler
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-autoscaler
subjects:
- kind: ServiceAccount
  name: cluster-autoscaler
  namespace: kube-system
EOF

# CLUSTER_NAME'i gerçek cluster ismiyle değiştir
sed -i 's/CLUSTER_NAME/mycompany-dev-eks/g' cluster-autoscaler.yaml
kubectl apply -f cluster-autoscaler.yaml
```

### 🔒 **6.5 Network Policies**

```bash
# 6.5.1 Calico CNI kurulumu (Network Policies için)
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

# Calico configuration
cat > calico-config.yaml << 'EOF'
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 192.168.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
EOF

kubectl apply -f calico-config.yaml

# 6.5.2 Network Policy templates
cat > network-policies.yaml << 'EOF'
# Default deny all ingress traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: dev
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
# Allow ingress from same namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: dev
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: dev
---
# Allow ingress from ingress-nginx
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-nginx
  namespace: dev
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
---
# Allow database access only from backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-access
  namespace: dev
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 5432
---
# Allow monitoring namespace access
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring
  namespace: dev
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 8080
    - protocol: TCP
      port: 9090
EOF

kubectl apply -f network-policies.yaml
```

---
