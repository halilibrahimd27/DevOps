---
description: "Ingress-NGINX production patterns: TLS termination, rate limiting, canary deployments, auth, and WAF settings explained with concrete annotation examples."
tags:
  - Networking
  - Kubernetes
  - Security
---
# Ingress-NGINX Patterns — TLS, Rate Limit, Canary, Auth

> *"Ingress-NGINX is still the most widely used K8s ingress controller
> in 2026. Moving new services to Gateway API is the right move, but
> **you also need to know your existing Ingress fleet** — annotation
> hell leads to surprise incidents."*

This guide walks through Ingress-NGINX's production patterns — TLS
termination, rate limiting, canary, auth, WAF — with concrete examples.

> 📌 **Gateway API** is recommended for new services. See [`Gateway-API-Migration.md`](Gateway-API-Migration.md).

---

## 🚀 Production Setup

```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  -f values-prod.yaml
```

```yaml
# values-prod.yaml
controller:
  replicaCount: 3
  
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
      service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
      service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"

  config:
    use-forwarded-headers: "true"
    compute-full-forwarded-for: "true"
    use-proxy-protocol: "true"
    
    # TLS
    ssl-protocols: "TLSv1.2 TLSv1.3"
    ssl-ciphers: "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:..."
    hsts: "true"
    hsts-max-age: "31536000"
    hsts-include-subdomains: "true"
    hsts-preload: "true"
    
    # Performance
    keep-alive-requests: "10000"
    upstream-keepalive-connections: "320"
    
    # Limits
    proxy-body-size: "8m"
    client-max-body-size: "8m"
    
    # Logging
    log-format-escape-json: "true"
    log-format-upstream: '{"timestamp":"$time_iso8601","request_id":"$req_id","remote_addr":"$remote_addr","method":"$request_method","host":"$host","path":"$request_uri","status":$status,"upstream_status":$upstream_status,"upstream_response_time":$upstream_response_time,"request_time":$request_time,"user_agent":"$http_user_agent"}'

  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
    prometheusRule:
      enabled: true

  resources:
    requests: {cpu: 250m, memory: 256Mi}
    limits: {cpu: 1000m, memory: 1Gi}
  
  podDisruptionBudget:
    enabled: true
    minAvailable: 2
  
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70

  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app.kubernetes.io/component: controller
          topologyKey: kubernetes.io/hostname
```

---

## 🔒 TLS — Automated with cert-manager

### ClusterIssuer (Let's Encrypt)
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: <ADMIN_EMAIL>
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

### Ingress with TLS
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: payments
  namespace: payments
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - payments.<DOMAIN>
      secretName: payments-tls
  rules:
    - host: payments.<DOMAIN>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: payments
                port:
                  number: 80
```

### Wildcard cert (DNS-01)
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: <ADMIN_EMAIL>
    privateKeySecretRef:
      name: letsencrypt-dns-key
    solvers:
      - dns01:
          route53:
            region: <REGION>
```

---

## 🚦 Rate Limit

### Per IP
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "10"           # 10 req/sec/IP
    nginx.ingress.kubernetes.io/limit-rpm: "300"          # 300 req/min/IP
    nginx.ingress.kubernetes.io/limit-connections: "20"   # 20 concurrent conn/IP
    nginx.ingress.kubernetes.io/limit-burst-multiplier: "5"   # burst tolerance
```

### For a specific endpoint (path-based)
```yaml
# Stricter limit for the login endpoint
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-login
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "2"           # brute force protection
    nginx.ingress.kubernetes.io/limit-rpm: "20"
spec:
  rules:
    - host: api.<DOMAIN>
      http:
        paths:
          - path: /v1/auth/login
            pathType: Exact
            backend:
              service: {name: auth-svc, port: {number: 80}}
```

---

## 🐦 Canary Deployment

### Header-based canary (test traffic)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: payments-canary
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-by-header: "X-Beta"
    nginx.ingress.kubernetes.io/canary-by-header-value: "true"
spec:
  rules:
    - host: payments.<DOMAIN>
      http:
        paths:
          - path: /
            backend:
              service: {name: payments-canary, port: {number: 80}}
```

→ `X-Beta: true` header → goes to the canary service. All other traffic goes to stable.

### Weight-based canary
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"   # 10% canary
```

### Cookie-based canary (sticky)
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-by-cookie: "canary-user"
```

> 🔑 **Argo Rollouts / Flagger** integrate with Ingress-NGINX for
> automatic staged canary rollouts.

---

## 🔐 Authentication

### Basic Auth
```bash
htpasswd -c auth admin
kubectl create secret generic basic-auth --from-file=auth -n <NS>
```

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
```

### External Auth (oauth2-proxy)
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/auth-url: "https://oauth.<DOMAIN>/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://oauth.<DOMAIN>/oauth2/start?rd=$escaped_request_uri"
    nginx.ingress.kubernetes.io/auth-response-headers: "X-Auth-Email,X-Auth-User"
```

### mTLS (client cert)
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/auth-tls-secret: "<NAMESPACE>/ca-secret"
    nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"
    nginx.ingress.kubernetes.io/auth-tls-verify-depth: "1"
    nginx.ingress.kubernetes.io/auth-tls-pass-certificate-to-upstream: "true"
```

---

## 🛡️ ModSecurity (WAF)

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/enable-modsecurity: "true"
    nginx.ingress.kubernetes.io/enable-owasp-core-rules: "true"
    nginx.ingress.kubernetes.io/modsecurity-snippet: |
      SecRuleEngine On
      SecAuditLog /var/log/modsec_audit.log
      SecAuditLogParts ABCFHZ
```

→ OWASP Core Rule Set blocks XSS / SQLi / RFI / LFI.

---

## 🌐 CORS

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://app.<DOMAIN>"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-headers: "Authorization,Content-Type,X-Requested-With"
    nginx.ingress.kubernetes.io/cors-allow-credentials: "true"
    nginx.ingress.kubernetes.io/cors-max-age: "600"
```

---

## 🔄 Header Manipulation

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "Strict-Transport-Security: max-age=31536000; includeSubDomains";
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "Referrer-Policy: strict-origin-when-cross-origin";
      more_set_headers "Permissions-Policy: geolocation=(), camera=(), microphone=()";
```

---

## 🔁 Redirect

### HTTPS redirect
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
```

### URL rewrite
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
    - http:
        paths:
          - path: /api(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service: {name: api-svc, port: {number: 80}}
```

→ `/api/users` → forwarded to the `/users` backend.

### Permanent redirect
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/permanent-redirect: "https://new-domain.<DOMAIN>$request_uri"
    nginx.ingress.kubernetes.io/permanent-redirect-code: "301"
```

---

## 📊 Monitoring + Alerting

### Key metrics
```promql
# Request rate
rate(nginx_ingress_controller_requests[5m])

# 5xx error rate
sum(rate(nginx_ingress_controller_requests{status=~"5.."}[5m]))
/
sum(rate(nginx_ingress_controller_requests[5m]))

# p99 latency
histogram_quantile(0.99,
  sum(rate(nginx_ingress_controller_request_duration_seconds_bucket[5m])) by (le, ingress)
)

# Conn count
nginx_ingress_controller_nginx_process_connections{state="active"}
```

### Alerts
```yaml
- alert: IngressHigh5xx
  expr: |
    sum(rate(nginx_ingress_controller_requests{status=~"5.."}[5m])) by (ingress)
    /
    sum(rate(nginx_ingress_controller_requests[5m])) by (ingress) > 0.05
  for: 5m

- alert: IngressLatencyHigh
  expr: |
    histogram_quantile(0.99, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket[5m])) by (le, ingress)) > 2
  for: 10m

- alert: IngressCertExpiring
  expr: nginx_ingress_controller_ssl_expire_time_seconds - time() < 14*24*3600
  annotations:
    summary: "SSL cert expiring in <14 days"

- alert: IngressControllerDown
  expr: up{job="ingress-nginx-controller"} == 0
  for: 5m
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Single Ingress controller replica | SPOF | 3+ replicas + PDB |
| Public exposure without TLS | Sniffer + browser warning | cert-manager + Let's Encrypt |
| No HSTS | Downgrade attack | HSTS preload |
| No rate limit | DDoS / brute force | Per-IP + path-based |
| No ModSecurity / WAF | OWASP top 10 exposed | ModSecurity + OWASP CRS |
| Annotation clutter (40+) | Unmanageable | Move common annotations to a ConfigMap |
| Wildcard cert on a single Ingress | Compromise = the whole wildcard | Per-domain cert |
| `proxy-body-size` default 1MB | Upload service fails | Increase per service need |
| Plaintext logging | PII / sensitive data | log-format JSON + sensitive masking |
| Configuration snippet exposed | RCE risk | Enable `allow-snippet-annotations: false` |
| LB type: CLB | Old, slow | NLB (AWS) / Network LB |
| Manual canary annotations | Drift, errors | Argo Rollouts / Flagger |
| No custom error page | Default NGINX page looks bad | custom error backend |

---

## 📋 Production Checklist

```
[ ] HA: 3+ replicas + PDB
[ ] Automated TLS with cert-manager
[ ] HSTS preload + force-ssl-redirect
[ ] ssl-protocols TLSv1.2+ only
[ ] Rate limit: per-IP + path-based
[ ] ModSecurity + OWASP CRS
[ ] CORS: explicit allow-origin (don't use wildcard)
[ ] Security headers (X-Frame, X-Content-Type, etc.)
[ ] proxy-body-size sized to service needs
[ ] Log format: JSON (Loki/SIEM-friendly)
[ ] Sensitive data masking (PII)
[ ] Prometheus metrics + ServiceMonitor
[ ] Alert: 5xx, latency, cert-expiring, controller-down
[ ] Upgrade: minor version quarterly
[ ] Annotation snippet not exposed (snippet protection)
[ ] LoadBalancer: NLB (AWS) / native cloud
[ ] Cross-zone LB enabled
[ ] Multi-AZ pod anti-affinity
[ ] WAF audit log → SIEM
[ ] Disaster recovery: backup + restore plan
```

---

## 📚 References

- **Ingress-NGINX Docs** — kubernetes.github.io/ingress-nginx
- **NGINX Configuration Annotations** — kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations
- **OWASP Core Rule Set** — coreruleset.org
- **cert-manager** — cert-manager.io
- [`Gateway-API-Migration.md`](Gateway-API-Migration.md) — the new standard
- [`Service-Mesh-Comparison.md`](Service-Mesh-Comparison.md)
- [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md)
- [`05-Kubernetes/Production-Checklist.md`](../05-Kubernetes/Production-Checklist.md)

---

> *"Ingress-NGINX hasn't 'gone stale' — **annotation hell** has.
> Keep your existing Ingress fleet secure; let new services be
> born on Gateway API. **The two run in parallel** for 12-18 months."*
