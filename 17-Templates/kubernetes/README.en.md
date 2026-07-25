---
description: "Production-grade Kubernetes manifest templates: Deployment with probes + non-root, HPA, Ingress, default-deny NetworkPolicy, PDB, least-privilege RBAC."
tags:
  - Template
  - Kubernetes
  - Security
---
# Kubernetes — Production Manifest Templates

> The full set that makes a workload prod-ready. Security is not a separate file;
> it is woven into every manifest (non-root, default-deny, least-privilege).
> Placeholders use `<UPPER_CASE>`. This page is the embedded form of the neighboring
> files; the source files live in the same folder.

## Files

| File | Kind | What it provides |
|---|---|---|
| [`deployment.yaml`](deployment.yaml) | Deployment | Probes, resources, non-root, topology spread |
| [`service.yaml`](service.yaml) | Service | ClusterIP, http + metrics port |
| [`hpa.yaml`](hpa.yaml) | HorizontalPodAutoscaler | CPU/memory targeted, oscillation-preventing behavior |
| [`ingress.yaml`](ingress.yaml) | Ingress | TLS, rate limit, security headers |
| [`networkpolicy.yaml`](networkpolicy.yaml) | NetworkPolicy | Default-deny + explicit allow |
| [`pdb.yaml`](pdb.yaml) | PodDisruptionBudget | Minimum standing pods during voluntary disruption |
| [`serviceaccount-rbac.yaml`](serviceaccount-rbac.yaml) | SA + Role + RoleBinding | Least-privilege API access |

For depth: [`05-Kubernetes/`](../../05-Kubernetes/) and [`08-Security/Kubernetes-Hardening.md`](../../08-Security/Kubernetes-Hardening.md).

### 1️⃣ `deployment.yaml`

Probe triad (startup/liveness/readiness), resource request/limit, non-root +
read-only root FS + dropped capabilities, and topology spread for HA.

```yaml
# Production-grade Deployment template
# Replace the placeholders (<UPPER_CASE>) with your own values.
# This template includes the following best practices:
#  - resource requests/limits
#  - readiness/liveness/startup probes
#  - non-root, read-only root FS, dropped capabilities
#  - topology spread (for HA)
#  - PodDisruptionBudget example (in a separate file — pdb.yaml)

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
      maxUnavailable: 0           # 0 for zero-downtime
  selector:
    matchLabels:
      app.kubernetes.io/name: <APP_NAME>
  template:
    metadata:
      labels:
        app.kubernetes.io/name: <APP_NAME>
        app.kubernetes.io/component: api
      annotations:
        # Prometheus scrape (if you use it)
        prometheus.io/scrape: "true"
        prometheus.io/port: "9090"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: <APP_NAME>           # least-privilege sa
      automountServiceAccountToken: false       # turn off if not needed
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
          image: <REGISTRY>/<IMAGE>:<TAG>      # SHA-pinned recommended (sha256:...)
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
              value: "<VERSION>"               # set by release-please/Argo Image Updater
          envFrom:
            - configMapRef:
                name: <APP_NAME>-config
            - secretRef:
                name: <APP_NAME>-secrets       # managed via External Secrets Operator
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 1000m                        # CPU limit is optional — it throttles
              memory: 512Mi                     # prevents OOM
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
                # Graceful shutdown: once you tell the load balancer "I'm draining",
                # wait for existing requests to finish
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
  minReplicas: 3                  # at least 3 for HA
  maxReplicas: 30
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 100              # can grow 100% (2x) in 60s
          periodSeconds: 60
        - type: Pods
          value: 4                # or add 4 pods
          periodSeconds: 60
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 300        # scale down slowly over 5min (prevent oscillation)
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
    # Custom metric example (Prometheus Adapter must be installed):
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
# Ingress — TLS termination, rate limit, basic security headers
# (assumes NGINX Ingress Controller; separate template for Gateway API)

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <APP_NAME>
  namespace: <NAMESPACE>
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"

    # Rate limiting — 100 requests per IP within a minute
    nginx.ingress.kubernetes.io/limit-rps: "100"
    nginx.ingress.kubernetes.io/limit-connections: "20"

    # Body size limit
    nginx.ingress.kubernetes.io/proxy-body-size: "8m"

    # Timeouts
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

First close everything, then open only what is needed. Egress to DNS is **mandatory** — don't forget it.

```yaml
# NetworkPolicy — default-deny + explicit allow
# The CNI must support NetworkPolicy (Cilium, Calico, etc.)

# 1) DEFAULT DENY within the namespace (everything closed)
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: <NAMESPACE>
spec:
  podSelector: {}                 # all pods
  policyTypes:
    - Ingress
    - Egress

# 2) Allow egress to DNS (kube-dns) — MANDATORY
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

# 3) The application's specific allows
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
    # Accept traffic from the ingress controller
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

    # Monitoring in the same namespace (prometheus scrape)
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
    # To Postgres in the same namespace
    - to:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: postgres
      ports:
        - protocol: TCP
          port: 5432

    # External API calls (HTTPS)
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
              - 10.0.0.0/8        # not open to internal networks
              - 172.16.0.0/12
              - 192.168.0.0/16
      ports:
        - protocol: TCP
          port: 443
```

### 6️⃣ `pdb.yaml`

```yaml
# PodDisruptionBudget — guarantee of the minimum number of pods staying up
# during voluntary disruption (node drain, etc.)
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: <APP_NAME>
  namespace: <NAMESPACE>
spec:
  minAvailable: 2                  # or: maxUnavailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: <APP_NAME>
  unhealthyPodEvictionPolicy: AlwaysAllow   # K8s 1.27+ — unhealthy pods can be evicted
```

### 7️⃣ `serviceaccount-rbac.yaml` — least-privilege

```yaml
# Least-privilege ServiceAccount + Role + RoleBinding
# Used if your application talks to the Kubernetes API.

apiVersion: v1
kind: ServiceAccount
metadata:
  name: <APP_NAME>
  namespace: <NAMESPACE>
automountServiceAccountToken: false   # we'll enable it separately in the podSpec

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: <APP_NAME>
  namespace: <NAMESPACE>
rules:
  # Only in its own namespace, only specific resources and verbs
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  # Lease (for leader election)
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

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| No probes | K8s sends traffic to a not-ready pod; won't restart a dead pod | startup + liveness + readiness triad |
| No resource limit | One pod starves the node; OOM hits its neighbors | request + limit; memory limit as OOM boundary |
| No NetworkPolicy | A compromised pod moves laterally across the whole cluster | Default-deny + explicit allow |
| `cluster-admin` ServiceAccount | Compromised token = the whole cluster | Namespace-scoped Role, only the needed verbs |
| Root container | Escape = node root | `runAsNonRoot` + `drop: ["ALL"]` + read-only FS |
| No PDB | Node drain takes down all replicas at once | Baseline guarantee with `minAvailable` |

## 📋 Checklist

```
[ ] Deployment: request + limit set
[ ] Deployment: 3 probes (startup/liveness/readiness) defined
[ ] Pod non-root (runAsNonRoot, drop ALL, read-only root FS)
[ ] NetworkPolicy default-deny + DNS allow applied
[ ] ServiceAccount least-privilege (NO cluster-admin)
[ ] PDB minAvailable configured
[ ] Image SHA-pinned (NO `:latest`)
```

> *"Security is not a separate manifest — it's a field inside every manifest. It isn't added later, it's woven in from the start."*
