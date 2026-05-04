# Network Troubleshooting — tcpdump, ss, dig, conntrack

> *"Connection timeout. Sebep: A) NetworkPolicy, B) DNS, C) firewall,
> D) sidecar, E) MTU. Bilemiyorsan **sırayla elemine et** —
> production'da %30 incident network, **flowchart** ile çözülür."*

Bu rehber prod'da network sorunlarını sistemli debug eden komutları,
araçları, ve **karar ağacı** yöntemini somut komutlarla anlatır.

---

## 🌳 Network Troubleshooting Flowchart

```
[Connection sorunu]
    │
    ▼
┌─────────────────────────────┐
│  1. Symptom — net mi?       │
│  - timeout                   │
│  - connection refused        │
│  - 503 / 504                 │
│  - intermittent              │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│  2. Layer'a göre kontrol    │
│  L3 (IP) → L4 (TCP/UDP)     │
│  → L7 (HTTP)                │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│  3. Pod-pod, pod-svc, ext?  │
│  - Same node                 │
│  - Cross-node                │
│  - Cross-cluster             │
│  - Internet                  │
└──────────────┬──────────────┘
               │
               ▼
        ROOT CAUSE
```

---

## 🔍 Adım 1: Pod İçinde Resolution

```bash
# Pod'a shell aç
kubectl exec -it <POD> -n <NS> -- sh

# DNS test
nslookup payments.<NS>.svc.cluster.local
# Beklenen: ClusterIP geri dönecek

# External DNS
nslookup google.com
# Beklenen: real IP

# DNS detaylı (CoreDNS direkt)
dig @10.96.0.10 payments.<NS>.svc.cluster.local
```

### Sorunlar
- ❌ `;; connection timed out` → CoreDNS down veya NetPol DNS port deny
- ❌ `NXDOMAIN` → service yanlış isim
- ❌ `SERVFAIL` → upstream DNS issue

---

## 🔌 Adım 2: TCP Bağlantı Test

```bash
# Pod'da nc (netcat) varsa
nc -zv payments.<NS>.svc.cluster.local 8080

# /dev/tcp ile (bash built-in)
timeout 3 bash -c 'cat < /dev/tcp/payments.<NS>.svc.cluster.local/8080'

# curl
curl -v http://payments.<NS>.svc.cluster.local:8080/healthz \
  --connect-timeout 5
```

### Sorunlar
- ❌ `Connection timed out` → NetworkPolicy block / firewall
- ❌ `Connection refused` → port'ta servis yok / pod down
- ❌ `Connection reset` → app crash / TLS hatası

---

## 🛡️ Adım 3: NetworkPolicy Kontrol

```bash
# Mevcut NetPol'leri listele
kubectl get networkpolicies -n <NS>
kubectl describe networkpolicy <POL> -n <NS>

# Cilium varsa daha güzel
cilium policy get
cilium policy trace --src-pod <NS>/<SRC_POD> --dst-pod <NS>/<DST_POD> --dport 8080
```

### Test: NetPol bypass
```bash
# Geçici olarak NetPol'ü patch'le ve dene
kubectl annotate networkpolicy <POL> -n <NS> \
  experimental/disable=true
# Test
# Sonra geri al
kubectl annotate networkpolicy <POL> -n <NS> \
  experimental/disable-
```

---

## 📊 Adım 4: tcpdump (Pod İçinde)

```bash
# tcpdump bulundur (initContainer veya ephemeral container)
kubectl debug -it <POD> --image=nicolaka/netshoot -n <NS>

# İçerde
tcpdump -i any -n port 8080
tcpdump -i any -n host <DEST_IP>
tcpdump -i any -n -A 'port 80'   # ASCII payload

# Belirli pod IP'si filter
tcpdump -i any -n 'host <POD_IP> and port 8080'
```

### netshoot image
[nicolaka/netshoot](https://github.com/nicolaka/netshoot) — tüm network tool'ları içerir:
- tcpdump, curl, dig, nslookup, mtr, iperf3, netcat, ss, ip, conntrack

---

## 🌊 Adım 5: ss / netstat (Connection Listing)

```bash
# Aktif TCP connections
ss -tunap

# Listening ports
ss -tlnp

# Establishment + state
ss -tan state established
ss -tan state time-wait

# Specific port
ss -tan src :8080
```

---

## 🔥 Adım 6: conntrack (NAT Table)

```bash
# Mevcut connections
conntrack -L | head

# Specific source
conntrack -L --src <POD_IP>

# Saturation kontrol
cat /proc/sys/net/netfilter/nf_conntrack_count
cat /proc/sys/net/netfilter/nf_conntrack_max

# Spike (table dolu → connection drop)
sysctl net.netfilter.nf_conntrack_max
```

> 🔑 **conntrack table dolu** = sessiz connection drop. Yüksek-traffic node'larda izlenmesi şart.

---

## 🌐 Adım 7: kube-proxy / Cilium Service Routing

### kube-proxy (iptables mode)
```bash
# Service IP → backend pod listesi
iptables -t nat -L KUBE-SERVICES -n
iptables -t nat -L KUBE-SVC-<HASH> -n
```

### Cilium (eBPF mode)
```bash
# Cilium service map
cilium service list

# Specific service
cilium service get <ID>

# Endpoint identity
cilium endpoint list
```

---

## 🚦 Adım 8: Service Mesh (Sidecar Issue)

### Istio
```bash
# Sidecar status
istioctl proxy-status

# Sidecar config dump
istioctl proxy-config cluster <POD> -n <NS>
istioctl proxy-config route <POD> -n <NS>
istioctl proxy-config listener <POD> -n <NS>

# Sidecar log
kubectl logs <POD> -c istio-proxy -n <NS> --tail=50
```

### Linkerd
```bash
linkerd viz tap deploy/<DEPLOY> -n <NS>
linkerd viz top deploy/<DEPLOY> -n <NS>
linkerd viz edges -n <NS>
```

### Cilium (mesh)
```bash
cilium hubble observe --pod <NS>/<POD> --follow
```

---

## 🌍 Adım 9: External Connectivity

```bash
# Pod'dan internete
curl -v https://api.stripe.com --connect-timeout 5

# Egress NetworkPolicy?
kubectl describe networkpolicy -n <NS> | grep -A 10 Egress

# DNS for external?
nslookup api.stripe.com

# MTR (traceroute + ping kombinasyonu)
mtr -rwc 10 api.stripe.com
```

### Cloud SG / NACL
- AWS: Security Group + NACL kontrol
- GCP: Firewall rules
- Azure: NSG

---

## 📐 Yaygın Senaryolar — Hızlı Çözüm

### Pod-Pod Same Node Timeout
1. NetworkPolicy default-deny aktif mi?
2. CNI healthy mi?
3. Pod CIDR doğru mu?

### Pod-Pod Cross-Node Timeout
1. Yukarıdakilere ek:
2. Node-node connectivity (VPC routing)
3. Overlay network sağlam mı (VXLAN, BGP)?

### Pod → External 503
1. Egress NetworkPolicy?
2. NAT gateway saturation?
3. External service rate-limit'ledi mi?

### Intermittent 503
1. HPA scale-down'da pod kill?
2. Pod readiness probe yanlış?
3. LB stale endpoint?

### MTU Issue (büyük packet drop)
```bash
# Pod MTU
ip link show eth0

# Test (Don't Fragment + büyük packet)
ping -M do -s 1472 <DEST>
# 1472 = 1500 - 28 (header) — IPv4 max MTU
```

### TLS Hata
```bash
# Cert detay
openssl s_client -connect payments.<NS>.svc.cluster.local:443 \
  -servername payments.<NS>.svc.cluster.local

# Cert expiry
echo | openssl s_client -connect <HOST>:443 2>/dev/null | \
  openssl x509 -noout -dates
```

---

## 🛠️ Tool Kataloğu

| Tool | Kullanım |
|---|---|
| `dig`, `nslookup` | DNS resolution |
| `nc`, `telnet` | TCP port test |
| `curl -v` | HTTP request + headers |
| `tcpdump` | Packet capture |
| `ss`, `netstat` | Connection listing |
| `conntrack` | NAT table |
| `iptables -nL` | Firewall rules |
| `mtr` | Path tracing |
| `iperf3` | Bandwidth test |
| `netshoot` | Hepsini birden taşıyan image |
| `cilium-cli`, `hubble` | eBPF dataflow |
| `istioctl` | Istio sidecar |
| `wireshark` | Capture analiz (offline) |

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Pod'da `apt-get install net-tools` | Image bloat, runtime mod | netshoot ephemeral container |
| `iptables -nL` her node'da | İptables aşılıyor | Cilium / kube-proxy command |
| tcpdump host yerine pod'da | Capture filter kaçar | Pod CIDR ile filter |
| Service IP'ye `ping` | ICMP service'lerde gerek yok | curl / nc TCP test |
| Restart pod hatayı çözer ama sebep bilinmez | Aynı sorun tekrar | Capture + analyze |
| External-dns çalışmıyor diye manual record | Drift | Annotation kontrol |
| Cert expiry sürpriz | Down | cert-manager + alert |
| MTU default 1500 GCP/AWS overlay | Fragmentation | VXLAN için 1450 |
| conntrack table dolu, alarm yok | Sessiz drop | Saturation alert |
| Sidecar varsa "app sorunu" | Sidecar config / mTLS | Sidecar log + config dump |

---

## 📋 Network Troubleshooting Checklist

```
[ ] netshoot image cluster'da hazır (ephemeral container)
[ ] CoreDNS HA + NodeLocal DNSCache
[ ] NetworkPolicy + Cilium policy trace
[ ] cilium-cli + hubble observe alışkın
[ ] istioctl / linkerd viz tap (mesh varsa)
[ ] tcpdump pod'da çalıştırma rehberi (runbook)
[ ] conntrack max + saturation alert
[ ] MTU optimize (VXLAN için 1450)
[ ] cert expiry alert (cert-manager)
[ ] Egress NetworkPolicy + FQDN allowlist
[ ] DNS metric + alert
[ ] LB health check + readiness probe doğru
[ ] On-call: network troubleshoot runbook
[ ] Quarterly: yaygın network incident retrospective
```

---

## 📚 Referanslar

- **netshoot** — github.com/nicolaka/netshoot
- **tcpdump cheat sheet** — packetlife.net
- **Cilium debug** — docs.cilium.io
- **Istio troubleshooting** — istio.io/docs/ops/diagnostic-tools/
- **Linkerd debugging** — linkerd.io/2/tasks/debugging-your-service/
- [`Service-Mesh-Comparison.md`](Service-Mesh-Comparison.md)
- [`Cilium-eBPF-Intro.md`](Cilium-eBPF-Intro.md)
- [`DNS-Strategies.md`](DNS-Strategies.md)
- [`Ingress-NGINX-Patterns.md`](Ingress-NGINX-Patterns.md)
- [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md)
- [`11-SRE/Runbook-Template.md`](../11-SRE/Runbook-Template.md)

---

> *"Network troubleshooting 'sezgi' değil — **flowchart**.
> Layer-by-layer + tool-by-tool sistemli geçiş, **30 dakikada
> root cause**. 'Acaba network mı' demek yerine **kanıtla**."*
