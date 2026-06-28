---
description: "Ingress-NGINX production pattern'leri: TLS termination, rate limit, canary deployment, auth ve WAF ayarlari somut annotation ornekleriyle anlatilir."
tags:
  - Networking
  - Kubernetes
  - Security
---
# Ingress-NGINX Patterns — TLS, Rate Limit, Canary, Auth

> *"Ingress-NGINX 2026'da hâlâ en yaygın K8s ingress controller. Yeni
> servisleri Gateway API'ye taşımak doğru, **mevcut Ingress flotanı
> tanımak da gerekli** — annotation cehennemi sürpriz incident'lara yol
> açar."*

Bu rehber Ingress-NGINX'in production pattern'lerini — TLS termination,
rate limit, canary, auth, WAF — somut örneklerle anlatır.

> 📌 Yeni servisler için **Gateway API** önerilir. Bkz [`Gateway-API-Migration.md`](Gateway-API-Migration.md).

---

## 🚀 Production Kurulumu

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

## 🔒 TLS — cert-manager ile Otomatik

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

### IP başına
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "10"           # 10 req/sec/IP
    nginx.ingress.kubernetes.io/limit-rpm: "300"          # 300 req/min/IP
    nginx.ingress.kubernetes.io/limit-connections: "20"   # 20 concurrent conn/IP
    nginx.ingress.kubernetes.io/limit-burst-multiplier: "5"   # burst tolerance
```

### Specific endpoint için (path-based)
```yaml
# Login endpoint daha sıkı limit
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

### Header-based canary (test trafiği)
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

→ `X-Beta: true` header → canary servisine. Diğer trafik stable'a.

### Weight-based canary
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"   # %10 canary
```

### Cookie-based canary (sticky)
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-by-cookie: "canary-user"
```

> 🔑 **Argo Rollouts / Flagger** otomatik aşamalı canary için Ingress-NGINX
> ile birleşir.

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
    nginx.ingress.kubernetes.io/auth-tls-secret: "default/ca-secret"
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

→ OWASP Core Rule Set ile XSS / SQLi / RFI / LFI engellenir.

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

→ `/api/users` → `/users` backend'e.

### Permanent redirect
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/permanent-redirect: "https://new-domain.<DOMAIN>$request_uri"
    nginx.ingress.kubernetes.io/permanent-redirect-code: "301"
```

---

## 📊 Monitoring + Alerting

### Anahtar metrikler
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

### Alarmlar
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

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tek Ingress controller replica | SPOF | 3+ replica + PDB |
| TLS olmadan public expose | Sniffer + browser warning | cert-manager + Let's Encrypt |
| HSTS yok | Downgrade attack | HSTS preload |
| Rate limit yok | DDoS / brute force | IP başına + path-based |
| ModSecurity / WAF yok | OWASP top 10 açık | ModSecurity + OWASP CRS |
| Annotation kalabalığı (40+) | Yönetilmez | Common annotation'ları ConfigMap'e |
| Wildcard cert tek bir Ingress'te | Compromise = tüm wildcard | Per-domain cert |
| `proxy-body-size` default 1MB | Upload servisi düşer | Servis ihtiyacına göre artır |
| Logging plaintext | PII / sensitive data | log-format JSON + sensitive masking |
| Configuration snippet exposed | RCE riski | `allow-snippet-annotations: false` enable |
| LB type: CLB | Eski, yavaş | NLB (AWS) / Network LB |
| Canary annotation manuel | Drift, hata | Argo Rollouts / Flagger |
| Custom error page yok | Default NGINX page çirkin | custom error backend |

---

## 📋 Production Checklist

```
[ ] HA: 3+ replica + PDB
[ ] cert-manager ile TLS otomatik
[ ] HSTS preload + force-ssl-redirect
[ ] ssl-protocols TLSv1.2+ only
[ ] Rate limit: IP başına + path-based
[ ] ModSecurity + OWASP CRS
[ ] CORS: explicit allow-origin (wildcard kullanma)
[ ] Security headers (X-Frame, X-Content-Type, etc.)
[ ] proxy-body-size servis ihtiyacına göre
[ ] Log format: JSON (Loki/SIEM-friendly)
[ ] Sensitive data masking (PII)
[ ] Prometheus metrics + ServiceMonitor
[ ] Alert: 5xx, latency, cert-expiring, controller-down
[ ] Upgrade: minor versiyonu quarterly
[ ] Annotation snippet exposed değil (snippet protection)
[ ] LoadBalancer: NLB (AWS) / native cloud
[ ] Cross-zone LB enabled
[ ] Multi-AZ pod anti-affinity
[ ] WAF audit log → SIEM
[ ] Disaster recovery: backup + restore plan
```

---

## 📚 Referanslar

- **Ingress-NGINX Docs** — kubernetes.github.io/ingress-nginx
- **NGINX Configuration Annotations** — kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations
- **OWASP Core Rule Set** — coreruleset.org
- **cert-manager** — cert-manager.io
- [`Gateway-API-Migration.md`](Gateway-API-Migration.md) — yeni standart
- [`Service-Mesh-Comparison.md`](Service-Mesh-Comparison.md)
- [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md)
- [`05-Kubernetes/Production-Checklist.md`](../05-Kubernetes/Production-Checklist.md)

---

> *"Ingress-NGINX 'eskimedi' — **annotation cehennemi** eskidi.
> Mevcut Ingress flotanı güvenli tutmak gerek; yeni servisleri
> Gateway API'ye doğmak gerek. **İkisi paralel** çalışır 12-18 ay."*
