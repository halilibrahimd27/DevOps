---
description: "Production-grade DNS setup in a Kubernetes environment: a guide to preventing DNS incidents with external-dns, CoreDNS tuning, NodeLocal DNSCache and split-horizon."
tags:
  - Networking
  - Kubernetes
  - SRE
  - Incident Response
---
# DNS Strategies — external-dns, NodeLocal, CoreDNS Tuning

> *"30% of production incidents are **DNS**. The 'It's always DNS' meme
> is real: wrong TTL, slow resolution, NXDOMAIN getting cached.
> Calling DNS 'working' means it's **not being monitored**."*

This guide walks through the concrete ways to set up DNS in a K8s
environment — external-dns, CoreDNS, NodeLocal DNSCache, split-horizon —
at production grade.

---

## 🎯 K8s DNS Architecture

```
[Pod] → [resolv.conf]
            │
            ▼
        nameserver: <CoreDNS_IP>
            │
            ▼
        [CoreDNS (kube-system)]
            │
            ├── cluster.local domains → in-cluster (kube-dns plugin)
            │
            └── External domains → upstream (cloud / public DNS)
```

---

## 🔧 1️⃣ CoreDNS Tuning

### Default Corefile (kube-system/coredns ConfigMap)
```
.:53 {
    errors
    health {
       lameduck 5s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    prometheus :9153
    forward . /etc/resolv.conf {
       max_concurrent 1000
    }
    cache 30
    loop
    reload
    loadbalance
}
```

### Tuning notes
```
cache 30                   → 30s TTL positive + negative cache
prefer_udp                 → TCP fallback instead of UDP
forward . 1.1.1.1 8.8.8.8  → upstream DNS, multi-source
ttl 5                      → short TTL → faster failover
```

### Production recommendations
```
.:53 {
    errors
    health {
       lameduck 10s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       ttl 5     # fast failover when K8s service IP changes
    }
    prometheus :9153
    forward . 1.1.1.1 8.8.8.8 {
       max_concurrent 1000
       prefer_udp
       expire 10s
    }
    cache 30 {
       success 9984
       denial 9984
       prefetch 10 60s 10%
    }
    loop
    reload
    loadbalance
}
```

---

## 🚀 2️⃣ NodeLocal DNSCache

> **Problem**: Every pod goes to CoreDNS. As the cluster grows, CoreDNS gets DDoS'd.
>
> **Solution**: NodeLocal DNSCache — a local DNS cache on every node.

### Architecture
```
[Pod] → [Node-local DNSCache: 169.254.20.10]
              │
              ├── Cache hit → fast response to the pod
              │
              └── Cache miss → [CoreDNS] → upstream
```

### Install
```bash
# Vanilla
kubectl apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/dns/nodelocaldns/nodelocaldns.yaml

# Helm
helm install nodelocaldns ...
```

### Advantages
- **Latency**: 5ms → 0.5ms (cache hit)
- **CoreDNS load**: drops 80%
- **Connection storm**: prevents kube-dns DDoS
- **conntrack**: reduces UDP conntrack pressure

> 🔑 **Mandatory for large clusters in 2026**.

---

## 🌐 3️⃣ external-dns

> **Problem**: A K8s Ingress / Service is created → a DNS record is added to Route53 / Cloudflare manually.
>
> **Solution**: the external-dns controller reads K8s resources and creates DNS records automatically.

### Install (Helm)
```bash
helm install external-dns external-dns/external-dns \
  -n external-dns --create-namespace \
  --set provider=aws \
  --set aws.region=eu-west-1 \
  --set domainFilters[0]=<DOMAIN> \
  --set policy=sync \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::<ACCT>:role/external-dns
```

### Usage on an Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: payments
  annotations:
    external-dns.alpha.kubernetes.io/hostname: payments.<DOMAIN>
    external-dns.alpha.kubernetes.io/ttl: "60"
    external-dns.alpha.kubernetes.io/cloudflare-proxied: "true"
spec:
  rules:
    - host: payments.<DOMAIN>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service: {name: payments, port: {number: 80}}
```

→ external-dns adds an A record to Route53 / Cloudflare.

### Multi-cluster support
- ownerID: cluster-1 → cluster-1's records
- domainFilter: dev.<DOMAIN> vs prod.<DOMAIN>

---

## 🌍 4️⃣ Split-Horizon DNS

> Internal vs external DNS: same domain, different IP.

```
api.example.com:
  - Internet → 203.0.113.10  (public LB)
  - Internal VPC → 10.0.5.10  (private LB)
```

### Use case
- B2B customer reaches it via the public IP
- Internal microservice via the private IP (reduces latency + cost)

### Implementation
- **Route53**: Private hosted zone (VPC-bound) + public hosted zone
- **CoreDNS**: rewrite plugin
```
rewrite name api.example.com api.internal.svc.cluster.local
```

---

## 🛡️ 5️⃣ DNS Security

### DNSSEC
- **Use it**: enable at the domain registrar
- **Validate**: CoreDNS `dnssec` plugin
```
dnssec {
    response_filter
}
```

### DNS-over-TLS (DoT) / DNS-over-HTTPS (DoH)
```
forward . tls://1.1.1.1 tls://8.8.8.8 {
    tls_servername cloudflare-dns.com
}
```

→ DNS queries are encrypted; man-in-the-middle is blocked.

### NXDOMAIN attack protection
- Aggressive cache TTL (30s+)
- Rate limit per pod (no CoreDNS `rate_limit` plugin, but do it upstream)

---

## 🔍 6️⃣ DNS Troubleshooting

### Fast debug inside a pod
```bash
# Open a shell in the pod
kubectl exec -it <POD> -- sh

# Resolution test
nslookup payments.<DOMAIN>
dig payments.<DOMAIN>

# Query CoreDNS directly
dig @<COREDNS_IP> kubernetes.default.svc.cluster.local
```

### CoreDNS log
```yaml
# Add log to the Corefile
.:53 {
    log
    errors
    ...
}
```

```bash
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=100
```

### Common problems

| Symptom | Cause | Fix |
|---|---|---|
| `nslookup` timeout | NetworkPolicy denies DNS port (53) | Add an allow-dns NetPol |
| External domain won't resolve | wrong upstream DNS | Check the `forward .` config |
| `service.namespace.svc.cluster.local` won't resolve | CoreDNS down | `kubectl get pods -n kube-system` |
| Slow resolution | no NodeLocal | Install NodeLocal DNSCache |
| NXDOMAIN cache stuck | negative cache TTL too high | Lower `cache.denial` |
| Pods constantly hitting CoreDNS | DDoS pattern | NodeLocal + rate limit |

---

## 📊 DNS Monitoring

### Prometheus metrics (CoreDNS export)
```promql
# Query rate
sum(rate(coredns_dns_requests_total[5m]))

# Error rate
rate(coredns_dns_responses_total{rcode!="NOERROR"}[5m])

# Latency
histogram_quantile(0.99, rate(coredns_dns_request_duration_seconds_bucket[5m]))

# Cache hit ratio
rate(coredns_cache_hits_total[5m])
/
rate(coredns_dns_requests_total[5m])
```

### Key alerts
```yaml
- alert: CoreDNSHighErrorRate
  expr: rate(coredns_dns_responses_total{rcode!="NOERROR"}[5m]) > 0.05

- alert: CoreDNSHighLatency
  expr: histogram_quantile(0.99, rate(coredns_dns_request_duration_seconds_bucket[5m])) > 1

- alert: CoreDNSDown
  expr: up{job="kube-dns"} == 0
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| No NodeLocal DNSCache on a large cluster | CoreDNS DDoS | Install NodeLocal |
| TTL 0 — constant upstream | Latency + load | Cache 30s+ |
| TTL 24h — slow failover | Service IP change takes 24h | Cache 30s, K8s ttl 5s |
| No external-dns | Manual DNS update | external-dns + annotation |
| No TTL annotation | external-dns 5min default | Per-record TTL |
| DNSSEC off | Spoofing risk | Enable + validate |
| Plain DNS upstream | MITM | DoT or DoH |
| Single CoreDNS replica | SPOF | min 2-3 replicas + autoscaling |
| No negative cache | NXDOMAIN spam | `cache.denial` active |
| No CoreDNS resource limit | OOM kill | Set request/limit |
| Searching `.local` outside `cluster.local` | mDNS conflict | Optimize search path |
| No NetworkPolicy DNS allow | Pods can't resolve | allow-dns NetPol |
| DNS log not in the SIEM | Forensics incomplete | Log → Loki |

---

## 📋 DNS Production Checklist

```
[ ] CoreDNS HA: 3+ replicas + autoscaling
[ ] CoreDNS resources: requests/limits set
[ ] NodeLocal DNSCache installed (large cluster)
[ ] external-dns: annotation-driven DNS records
[ ] TTL: K8s ttl 5s, cache 30s, external 60s
[ ] Cache: success + denial + prefetch
[ ] Forward: multi-upstream (1.1.1.1 + 8.8.8.8)
[ ] DNSSEC enabled (registrar + CoreDNS)
[ ] DoT/DoH upstream
[ ] DNS rate limit (anti-DDoS)
[ ] Prometheus metric + alert
[ ] Log → SIEM
[ ] NetworkPolicy: allow-dns rule in every namespace
[ ] Multi-cluster: per-cluster external-dns ownerID
[ ] Split-horizon: internal + external zones (if needed)
[ ] Quarterly: DNS performance review
```

---

## 📚 References

- **CoreDNS** — coredns.io
- **NodeLocal DNSCache** — kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/
- **external-dns** — kubernetes-sigs.github.io/external-dns
- **K8s DNS Spec** — github.com/kubernetes/dns/blob/master/docs/specification.md
- [`Service-Mesh-Comparison.md`](Service-Mesh-Comparison.md)
- [`Cilium-eBPF-Intro.md`](Cilium-eBPF-Intro.md)
- [`Ingress-NGINX-Patterns.md`](Ingress-NGINX-Patterns.md)
- [`Network-Troubleshooting.md`](Network-Troubleshooting.md)

---

> *"DNS isn't 'background tooling' — it's the **backbone of production**.
> When cache, TTL, DNSSEC aren't monitored it says 'everything works';
> during an incident, spending **30 minutes** investigating, you'll know: **always
> DNS**."*
