---
description: "Production-grade Kubernetes manifest şablonları: probe'lu + non-root Deployment, HPA, Ingress, default-deny NetworkPolicy, PDB, least-privilege RBAC."
tags:
  - Template
  - Kubernetes
  - Security
---
# Kubernetes — Production Manifest Şablonları

> Bir workload'ı prod'a hazır hale getiren tam set. Güvenlik ayrı bir dosya
> değil; her manifest içine örülü (non-root, default-deny, least-privilege).
> Placeholder'lar `<UPPER_CASE>` ile. Bu sayfa komşu dosyaların gömülü halidir;
> kaynak dosyalar aynı klasörde.

## Dosyalar

| Dosya | Kind | Ne sağlar |
|---|---|---|
| [`deployment.yaml`](deployment.yaml) | Deployment | Probe, resource, non-root, topology spread |
| [`service.yaml`](service.yaml) | Service | ClusterIP, http + metrics port |
| [`hpa.yaml`](hpa.yaml) | HorizontalPodAutoscaler | CPU/memory hedefli, oscillation-önleyici davranış |
| [`ingress.yaml`](ingress.yaml) | Ingress | TLS, rate limit, security header'lar |
| [`networkpolicy.yaml`](networkpolicy.yaml) | NetworkPolicy | Default-deny + explicit allow |
| [`pdb.yaml`](pdb.yaml) | PodDisruptionBudget | Voluntary disruption'da minimum ayakta pod |
| [`serviceaccount-rbac.yaml`](serviceaccount-rbac.yaml) | SA + Role + RoleBinding | Least-privilege API erişimi |

Derinlik için: [`05-Kubernetes/`](../../05-Kubernetes/) ve [`08-Security/Kubernetes-Hardening.md`](../../08-Security/Kubernetes-Hardening.md).

### 1️⃣ `deployment.yaml`

Probe üçlüsü (startup/liveness/readiness), resource request/limit, non-root +
read-only root FS + dropped capabilities, ve HA için topology spread.

```yaml
# Production-grade Deployment template
# Yer tutucuları (<UPPER_CASE>) kendi değerlerinle değiştir.
# Bu template aşağıdaki en iyi pratikleri içerir:
#  - resource requests/limits
#  - readiness/liveness/startup probes
#  - non-root, read-only root FS, dropped capabilities
#  - topology spread (HA için)
#  - PodDisruptionBudget örneği (ayrı dosyada — pdb.yaml)

apiVersion: apps/v1
kind: Deployment
metadata:
  name: <APP_NAME>
  namespace: <NAMESPACE>
  labels:
    app.kubernetes.io/name: <APP_NAME>
    app.kubernetes.io/component: api
    app.kubernetes.io/part-of: <SYSTEM_NAME>
    app.kubernetes.io/managed-by: argocd
spec:
  replicas: 3
  revisionHistoryLimit: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 0           # zero-downtime için 0
  selector:
    matchLabels:
      app.kubernetes.io/name: <APP_NAME>
  template:
    metadata:
      labels:
        app.kubernetes.io/name: <APP_NAME>
        app.kubernetes.io/component: api
      annotations:
        # Prometheus scrape (eğer kullanıyorsan)
        prometheus.io/scrape: "true"
        prometheus.io/port: "9090"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: <APP_NAME>           # least-privilege sa
      automountServiceAccountToken: false       # gerekmiyorsa kapat
      terminationGracePeriodSeconds: 30
      securityContext:
        runAsNonRoot: true
        runAsUser: 65532
        runAsGroup: 65532
        fsGroup: 65532
        seccompProfile:
          type: RuntimeDefault
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app.kubernetes.io/name: <APP_NAME>
                topologyKey: kubernetes.io/hostname
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: <APP_NAME>
      containers:
        - name: app
          image: <REGISTRY>/<IMAGE>:<TAG>      # SHA-pinned önerilir (sha256:...)
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
            - name: metrics
              containerPort: 9090
              protocol: TCP
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: APP_VERSION
              value: "<VERSION>"               # release-please/Argo Image Updater set eder
          envFrom:
            - configMapRef:
                name: <APP_NAME>-config
            - secretRef:
                name: <APP_NAME>-secrets       # External Secrets Operator ile yönetilir
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 1000m                        # CPU limit'i opsiyonel — throttling yapar
              memory: 512Mi                     # OOM önler
          startupProbe:
            httpGet:
              path: /health/live
              port: http
            failureThreshold: 30
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /health/live
              port: http
            initialDelaySeconds: 0
            periodSeconds: 10
            failureThreshold: 3
            timeoutSeconds: 5
          readinessProbe:
            httpGet:
              path: /health/ready
              port: http
            initialDelaySeconds: 0
            periodSeconds: 5
            failureThreshold: 3
            timeoutSeconds: 3
          lifecycle:
            preStop:
              exec:
                # Graceful shutdown: load balancer'a "kayıyorum" deyince
                # mevcut isteklerin bitmesini bekle
                command: ["sh", "-c", "sleep 15"]
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            capabilities:
              drop: ["ALL"]
          volumeMounts:
            - name: tmp
              mountPath: /tmp
            - name: cache
              mountPath: /var/cache/app
      volumes:
        - name: tmp
          emptyDir: {}
        - name: cache
          emptyDir:
            sizeLimit: 100Mi
```

### 2️⃣ `service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: <APP_NAME>
  namespace: <NAMESPACE>
  labels:
    app.kubernetes.io/name: <APP_NAME>
spec:
  type: ClusterIP
  ports:
    - name: http
      port: 80
      targetPort: http
      protocol: TCP
    - name: metrics
      port: 9090
      targetPort: metrics
      protocol: TCP
  selector:
    app.kubernetes.io/name: <APP_NAME>
```

### 3️⃣ `hpa.yaml`

```yaml
# HorizontalPodAutoscaler — CPU/memory + custom metric
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: <APP_NAME>
  namespace: <NAMESPACE>
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: <APP_NAME>
  minReplicas: 3                  # HA için en az 3
  maxReplicas: 30
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 100              # 60sn'de %100 (2x) artırabilir
          periodSeconds: 60
        - type: Pods
          value: 4                # veya 4 pod ekle
          periodSeconds: 60
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 300        # 5dk yavaş azalt (oscillation engelle)
      policies:
        - type: Percent
          value: 50
          periodSeconds: 60
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
    # Custom metric örneği (Prometheus Adapter kurulu olmalı):
    # - type: Pods
    #   pods:
    #     metric:
    #       name: http_requests_per_second
    #     target:
    #       type: AverageValue
    #       averageValue: "100"
```

### 4️⃣ `ingress.yaml`

```yaml
# Ingress — TLS terminasyon, rate limit, basic security headers
# (NGINX Ingress Controller varsayar; Gateway API için ayrı template)

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <APP_NAME>
  namespace: <NAMESPACE>
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"

    # Rate limiting — IP başına dakika içinde 100 istek
    nginx.ingress.kubernetes.io/limit-rps: "100"
    nginx.ingress.kubernetes.io/limit-connections: "20"

    # Body size limiti
    nginx.ingress.kubernetes.io/proxy-body-size: "8m"

    # Timeout'lar
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "5"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"

    # Security headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "Referrer-Policy: strict-origin-when-cross-origin";
      more_set_headers "Permissions-Policy: geolocation=(), microphone=(), camera=()";
      more_set_headers "Strict-Transport-Security: max-age=31536000; includeSubDomains; preload";

spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - <DOMAIN>
      secretName: <APP_NAME>-tls
  rules:
    - host: <DOMAIN>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: <APP_NAME>
                port:
                  number: 80
```

### 5️⃣ `networkpolicy.yaml` — default-deny

Önce her şeyi kapat, sonra sadece gerekeni aç. DNS'e çıkış **zorunlu** — unutma.

```yaml
# NetworkPolicy — default-deny + explicit allow
# CNI'ın NetworkPolicy desteklemesi gerekir (Cilium, Calico, vb.)

# 1) Namespace içinde DEFAULT DENY (her şey kapalı)
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: <NAMESPACE>
spec:
  podSelector: {}                 # tüm pod'lar
  policyTypes:
    - Ingress
    - Egress

# 2) DNS'e (kube-dns) çıkışına izin ver — ZORUNLU
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: <NAMESPACE>
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53

# 3) Uygulamanın spesifik allow'ları
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: <APP_NAME>-allow
  namespace: <NAMESPACE>
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: <APP_NAME>
  policyTypes:
    - Ingress
    - Egress
  ingress:
    # Ingress controller'dan trafik kabul et
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: ingress-nginx
      ports:
        - protocol: TCP
          port: 8080

    # Aynı namespace'teki monitoring (prometheus scrape)
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: monitoring
          podSelector:
            matchLabels:
              app.kubernetes.io/name: prometheus
      ports:
        - protocol: TCP
          port: 9090
  egress:
    # Aynı namespace'teki Postgres'e
    - to:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: postgres
      ports:
        - protocol: TCP
          port: 5432

    # External API çağrıları (HTTPS)
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
              - 10.0.0.0/8        # internal network'lere açık değil
              - 172.16.0.0/12
              - 192.168.0.0/16
      ports:
        - protocol: TCP
          port: 443
```

### 6️⃣ `pdb.yaml`

```yaml
# PodDisruptionBudget — voluntary disruption (node drain, vs) sırasında
# en az kaç pod ayakta kalsın garantisi
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: <APP_NAME>
  namespace: <NAMESPACE>
spec:
  minAvailable: 2                  # veya: maxUnavailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: <APP_NAME>
  unhealthyPodEvictionPolicy: AlwaysAllow   # K8s 1.27+ — unhealthy pod'lar evict edilebilir
```

### 7️⃣ `serviceaccount-rbac.yaml` — least-privilege

```yaml
# Least-privilege ServiceAccount + Role + RoleBinding
# Uygulamanız Kubernetes API ile konuşuyorsa kullanılır.

apiVersion: v1
kind: ServiceAccount
metadata:
  name: <APP_NAME>
  namespace: <NAMESPACE>
automountServiceAccountToken: false   # podSpec'te ayrıca açacağız

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: <APP_NAME>
  namespace: <NAMESPACE>
rules:
  # Sadece kendi namespace'inde, sadece spesifik kaynak ve verb'ler
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  # Lease (leader election için)
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["get", "create", "update"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: <APP_NAME>
  namespace: <NAMESPACE>
subjects:
  - kind: ServiceAccount
    name: <APP_NAME>
    namespace: <NAMESPACE>
roleRef:
  kind: Role
  name: <APP_NAME>
  apiGroup: rbac.authorization.k8s.io
```

---

## 🚫 Anti-Pattern

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Probe yok | K8s hazır olmayan pod'a trafik yollar; ölü pod'u restart etmez | startup + liveness + readiness üçlüsü |
| Resource limit yok | Bir pod node'u aç bırakır; OOM komşuları vurur | request + limit; memory limit OOM sınırı |
| NetworkPolicy yok | Compromise pod tüm cluster'a yatay hareket eder | Default-deny + explicit allow |
| `cluster-admin` ServiceAccount | Compromise token = tüm cluster | Namespace-scoped Role, sadece gereken verb |
| Root container | Escape = node root | `runAsNonRoot` + `drop: ["ALL"]` + read-only FS |
| PDB yok | Node drain tüm replica'yı aynı anda düşürür | `minAvailable` ile taban garanti |

## 📋 Checklist

```
[ ] Deployment: request + limit set
[ ] Deployment: 3 probe (startup/liveness/readiness) tanımlı
[ ] Pod non-root (runAsNonRoot, drop ALL, read-only root FS)
[ ] NetworkPolicy default-deny + DNS allow uygulandı
[ ] ServiceAccount least-privilege (cluster-admin YOK)
[ ] PDB minAvailable ayarlı
[ ] İmaj SHA-pinned (`:latest` YOK)
```

> *"Güvenlik ayrı bir manifest değil — her manifestin içinde bir alan. Sonradan eklenmez, baştan örülür."*
