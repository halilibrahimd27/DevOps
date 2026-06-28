---
description: "Kubernetes ortaminda production-grade DNS kurulumu: external-dns, CoreDNS tuning, NodeLocal DNSCache ve split-horizon ile DNS incident'larini onleme rehberi."
tags:
  - Networking
  - Kubernetes
  - SRE
  - Incident Response
---
# DNS Strategies — external-dns, NodeLocal, CoreDNS Tuning

> *"Production'da %30 incident **DNS**'tedir. 'It's always DNS' meme'si
> gerçekçi: TTL yanlış, çözümleme yavaş, NXDOMAIN cache ediliyor.
> DNS'i 'çalışıyor' demek **monitor edilmiyor** demektir."*

Bu rehber K8s ortamında DNS'i — external-dns, CoreDNS, NodeLocal
DNSCache, split-horizon — production-grade kurmanın somut yollarını
anlatır.

---

## 🎯 K8s DNS Mimarisi

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

### Tuning notları
```
cache 30                   → 30s TTL pozitif + negatif cache
prefer_udp                 → UDP yerine TCP fallback
forward . 1.1.1.1 8.8.8.8  → upstream DNS, multi-source
ttl 5                      → kısa TTL → daha hızlı failover
```

### Production önerileri
```
.:53 {
    errors
    health {
       lameduck 10s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       ttl 5     # K8s service IP değişiminde hızlı failover
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

> **Sorun**: Her pod CoreDNS'e gider. Cluster büyüdükçe CoreDNS DDoS oluyor.
>
> **Çözüm**: NodeLocal DNSCache — her node'da local DNS cache.

### Mimari
```
[Pod] → [Node-local DNSCache: 169.254.20.10]
              │
              ├── Cache hit → pod'a hızlı response
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

### Avantajlar
- **Latency**: 5ms → 0.5ms (cache hit)
- **CoreDNS yükü**: %80 azalır
- **Connection storm**: kube-dns DDoS önler
- **conntrack**: UDP conntrack pressure azalır

> 🔑 **2026'da büyük cluster'lar için zorunlu**.

---

## 🌐 3️⃣ external-dns

> **Sorun**: K8s Ingress / Service oluştu → Route53 / Cloudflare'e DNS record manuel eklenir.
>
> **Çözüm**: external-dns controller K8s resource'larını okur, otomatik DNS record yaratır.

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

### Ingress'te kullanım
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

→ external-dns Route53 / Cloudflare'e A record ekler.

### Multi-cluster support
- ownerID: cluster-1 → cluster-1's records
- domainFilter: dev.<DOMAIN> vs prod.<DOMAIN>

---

## 🌍 4️⃣ Split-Horizon DNS

> Internal vs external DNS: aynı domain farklı IP.

```
api.example.com:
  - Internet → 203.0.113.10  (public LB)
  - Internal VPC → 10.0.5.10  (private LB)
```

### Use case
- B2B müşteri public IP'den erişir
- Internal microservice private IP'den (latency + cost azaltır)

### Implementation
- **Route53**: Private hosted zone (VPC-bound) + public hosted zone
- **CoreDNS**: rewrite plugin
```
rewrite name api.example.com api.internal.svc.cluster.local
```

---

## 🛡️ 5️⃣ DNS Security

### DNSSEC
- **Kullan**: domain registrar'da enable
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

→ DNS query'ler şifreli; man-in-the-middle engellenir.

### NXDOMAIN attack koruması
- Cache TTL agresif (30s+)
- Rate limit per pod (CoreDNS `rate_limit` plugin yok ama upstream'de)

---

## 🔍 6️⃣ DNS Troubleshooting

### Pod içinde hızlı debug
```bash
# Pod'a shell aç
kubectl exec -it <POD> -- sh

# Resolution test
nslookup payments.<DOMAIN>
dig payments.<DOMAIN>

# CoreDNS direkt sorgu
dig @<COREDNS_IP> kubernetes.default.svc.cluster.local
```

### CoreDNS log
```yaml
# Corefile'a log ekle
.:53 {
    log
    errors
    ...
}
```

```bash
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=100
```

### Yaygın sorunlar

| Belirti | Neden | Fix |
|---|---|---|
| `nslookup` timeout | NetworkPolicy DNS port (53) deny ediyor | NetPol allow-dns ekle |
| External domain çözmüyor | upstream DNS yanlış | `forward .` config kontrol |
| `service.namespace.svc.cluster.local` çözmüyor | CoreDNS down | `kubectl get pods -n kube-system` |
| Yavaş resolution | NodeLocal yok | NodeLocal DNSCache install |
| NXDOMAIN cache yapışmış | Negatif cache TTL yüksek | `cache.denial` düşür |
| Pod'lar sürekli CoreDNS'e | DDoS pattern | NodeLocal + rate limit |

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

### Anahtar alarmlar
```yaml
- alert: CoreDNSHighErrorRate
  expr: rate(coredns_dns_responses_total{rcode!="NOERROR"}[5m]) > 0.05

- alert: CoreDNSHighLatency
  expr: histogram_quantile(0.99, rate(coredns_dns_request_duration_seconds_bucket[5m])) > 1

- alert: CoreDNSDown
  expr: up{job="kube-dns"} == 0
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| NodeLocal DNSCache yok büyük cluster'da | CoreDNS DDoS | NodeLocal install |
| TTL 0 — sürekli upstream | Latency + load | Cache 30s+ |
| TTL 24h — failover yavaş | Service IP değişimi 24h | Cache 30s, K8s ttl 5s |
| External-dns yok | Manuel DNS update | external-dns + annotation |
| TTL annotation yok | external-dns 5min default | Per-record TTL |
| DNSSEC kapalı | Spoofing riski | Enable + validate |
| Plain DNS upstream | MITM | DoT veya DoH |
| Single CoreDNS replica | SPOF | min 2-3 replica + autoscaling |
| Negatif cache yok | NXDOMAIN spam | `cache.denial` aktif |
| CoreDNS resource limit yok | OOM kill | Request/limit set |
| `cluster.local` dışına `.local` arama | mDNS conflict | Search path optimize |
| NetworkPolicy DNS allow yok | Pod'lar resolution yapamaz | allow-dns NetPol |
| DNS log SIEM'de değil | Forensic eksik | Log → Loki |

---

## 📋 DNS Production Checklist

```
[ ] CoreDNS HA: 3+ replica + autoscaling
[ ] CoreDNS resource: requests/limits set
[ ] NodeLocal DNSCache install (büyük cluster)
[ ] external-dns: annotation-driven DNS records
[ ] TTL: K8s ttl 5s, cache 30s, external 60s
[ ] Cache: success + denial + prefetch
[ ] Forward: multi-upstream (1.1.1.1 + 8.8.8.8)
[ ] DNSSEC enabled (registrar + CoreDNS)
[ ] DoT/DoH upstream
[ ] DNS rate limit (anti-DDoS)
[ ] Prometheus metric + alert
[ ] Log → SIEM
[ ] NetworkPolicy: allow-dns kuralı her namespace
[ ] Multi-cluster: per-cluster external-dns ownerID
[ ] Split-horizon: internal + external zones (gerekiyorsa)
[ ] Quarterly: DNS performance review
```

---

## 📚 Referanslar

- **CoreDNS** — coredns.io
- **NodeLocal DNSCache** — kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/
- **external-dns** — kubernetes-sigs.github.io/external-dns
- **K8s DNS Spec** — github.com/kubernetes/dns/blob/master/docs/specification.md
- [`Service-Mesh-Comparison.md`](Service-Mesh-Comparison.md)
- [`Cilium-eBPF-Intro.md`](Cilium-eBPF-Intro.md)
- [`Ingress-NGINX-Patterns.md`](Ingress-NGINX-Patterns.md)
- [`Network-Troubleshooting.md`](Network-Troubleshooting.md)

---

> *"DNS 'arka plan tooling' değil — **production'ın belkemiği**.
> Cache, TTL, DNSSEC, monitor edilmediğinde 'her şey çalışıyor' der;
> incident anında **30 dakika** araştırırken bilirsin: **always
> DNS**."*
