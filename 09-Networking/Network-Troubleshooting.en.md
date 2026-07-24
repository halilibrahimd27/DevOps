---
description: "Systematically debugging production network issues: a guide to the decision-tree method with concrete steps using tcpdump, ss, dig, and conntrack."
tags:
  - Networking
  - SRE
  - Incident Response
  - Cheatsheet
---
# Network Troubleshooting — tcpdump, ss, dig, conntrack

> *"Connection timeout. Cause: A) NetworkPolicy, B) DNS, C) firewall,
> D) sidecar, E) MTU. If you don't know, **eliminate them in order** —
> 30% of production incidents are network-related, and they get solved
> with a **flowchart**."*

This guide covers the commands, tools, and **decision-tree** method for
systematically debugging network issues in production, with concrete commands.

---

## 🌳 Network Troubleshooting Flowchart

```
[Connection issue]
    │
    ▼
┌─────────────────────────────┐
│  1. Symptom — is it network?│
│  - timeout                   │
│  - connection refused        │
│  - 503 / 504                 │
│  - intermittent              │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│  2. Check by layer          │
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

## 🔍 Step 1: Resolution Inside the Pod

```bash
# Open a shell in the pod
kubectl exec -it <POD> -n <NS> -- sh

# DNS test
nslookup payments.<NS>.svc.cluster.local
# Expected: returns the ClusterIP

# External DNS
nslookup google.com
# Expected: a real IP

# DNS in detail (CoreDNS directly)
dig @10.96.0.10 payments.<NS>.svc.cluster.local
```

### Problems
- ❌ `;; connection timed out` → CoreDNS down, or NetPol denies the DNS port
- ❌ `NXDOMAIN` → wrong service name
- ❌ `SERVFAIL` → upstream DNS issue

---

## 🔌 Step 2: TCP Connection Test

```bash
# If nc (netcat) is available in the pod
nc -zv payments.<NS>.svc.cluster.local 8080

# Via /dev/tcp (bash built-in)
timeout 3 bash -c 'cat < /dev/tcp/payments.<NS>.svc.cluster.local/8080'

# curl
curl -v http://payments.<NS>.svc.cluster.local:8080/healthz \
  --connect-timeout 5
```

### Problems
- ❌ `Connection timed out` → NetworkPolicy block / firewall
- ❌ `Connection refused` → no service on that port / pod down
- ❌ `Connection reset` → app crash / TLS error

---

## 🛡️ Step 3: Check NetworkPolicy

```bash
# List existing NetPols
kubectl get networkpolicies -n <NS>
kubectl describe networkpolicy <POL> -n <NS>

# Nicer with Cilium
cilium policy get
cilium policy trace --src-pod <NS>/<SRC_POD> --dst-pod <NS>/<DST_POD> --dport 8080
```

### Test: NetPol bypass
```bash
# Temporarily patch the NetPol and try
kubectl annotate networkpolicy <POL> -n <NS> \
  experimental/disable=true
# Test
# Then revert
kubectl annotate networkpolicy <POL> -n <NS> \
  experimental/disable-
```

---

## 📊 Step 4: tcpdump (Inside the Pod)

```bash
# Get tcpdump available (initContainer or ephemeral container)
kubectl debug -it <POD> --image=nicolaka/netshoot -n <NS>

# Inside
tcpdump -i any -n port 8080
tcpdump -i any -n host <DEST_IP>
tcpdump -i any -n -A 'port 80'   # ASCII payload

# Filter by a specific pod IP
tcpdump -i any -n 'host <POD_IP> and port 8080'
```

### The netshoot image
[nicolaka/netshoot](https://github.com/nicolaka/netshoot) — bundles all the network tools:
- tcpdump, curl, dig, nslookup, mtr, iperf3, netcat, ss, ip, conntrack

---

## 🌊 Step 5: ss / netstat (Connection Listing)

```bash
# Active TCP connections
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

## 🔥 Step 6: conntrack (NAT Table)

```bash
# Current connections
conntrack -L | head

# Specific source
conntrack -L --src <POD_IP>

# Saturation check
cat /proc/sys/net/netfilter/nf_conntrack_count
cat /proc/sys/net/netfilter/nf_conntrack_max

# Spike (table full → connection drop)
sysctl net.netfilter.nf_conntrack_max
```

> 🔑 **A full conntrack table** means silent connection drops. It must be
> monitored on high-traffic nodes.

---

## 🌐 Step 7: kube-proxy / Cilium Service Routing

### kube-proxy (iptables mode)
```bash
# Service IP → backend pod list
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

## 🚦 Step 8: Service Mesh (Sidecar Issue)

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

## 🌍 Step 9: External Connectivity

```bash
# From pod to the internet
curl -v https://api.stripe.com --connect-timeout 5

# Egress NetworkPolicy?
kubectl describe networkpolicy -n <NS> | grep -A 10 Egress

# DNS for external?
nslookup api.stripe.com

# MTR (traceroute + ping combined)
mtr -rwc 10 api.stripe.com
```

### Cloud SG / NACL
- AWS: check Security Group + NACL
- GCP: firewall rules
- Azure: NSG

---

## 📐 Common Scenarios — Quick Fix

### Pod-Pod Same Node Timeout
1. Is NetworkPolicy default-deny active?
2. Is the CNI healthy?
3. Is the pod CIDR correct?

### Pod-Pod Cross-Node Timeout
1. In addition to the above:
2. Node-node connectivity (VPC routing)
3. Is the overlay network solid (VXLAN, BGP)?

### Pod → External 503
1. Egress NetworkPolicy?
2. NAT gateway saturation?
3. Did the external service rate-limit you?

### Intermittent 503
1. Pod killed during HPA scale-down?
2. Pod readiness probe misconfigured?
3. LB stale endpoint?

### MTU Issue (large packet drop)
```bash
# Pod MTU
ip link show eth0

# Test (Don't Fragment + large packet)
ping -M do -s 1472 <DEST>
# 1472 = 1500 - 28 (header) — IPv4 max MTU
```

### TLS Error
```bash
# Cert detail
openssl s_client -connect payments.<NS>.svc.cluster.local:443 \
  -servername payments.<NS>.svc.cluster.local

# Cert expiry
echo | openssl s_client -connect <HOST>:443 2>/dev/null | \
  openssl x509 -noout -dates
```

---

## 🛠️ Tool Catalog

| Tool | Usage |
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
| `netshoot` | Image that bundles all of the above |
| `cilium-cli`, `hubble` | eBPF dataflow |
| `istioctl` | Istio sidecar |
| `wireshark` | Capture analysis (offline) |

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| `apt-get install net-tools` in the pod | Image bloat, runtime mutation | netshoot ephemeral container |
| `iptables -nL` on every node | Bypasses iptables | Cilium / kube-proxy command |
| tcpdump on the host instead of the pod | Capture filter misses traffic | Filter with the pod CIDR |
| `ping` on a Service IP | Services don't need ICMP | curl / nc TCP test |
| Restarting the pod fixes the error but the cause is unknown | Same issue recurs | Capture + analyze |
| Manual record because external-dns "isn't working" | Drift | Check the annotation |
| Cert expiry surprise | Downtime | cert-manager + alert |
| MTU default 1500 on GCP/AWS overlay | Fragmentation | 1450 for VXLAN |
| Full conntrack table, no alarm | Silent drop | Saturation alert |
| "It's an app problem" whenever there's a sidecar | Sidecar config / mTLS | Sidecar log + config dump |

---

## 📋 Network Troubleshooting Checklist

```
[ ] netshoot image ready in the cluster (ephemeral container)
[ ] CoreDNS HA + NodeLocal DNSCache
[ ] NetworkPolicy + Cilium policy trace
[ ] Comfortable with cilium-cli + hubble observe
[ ] istioctl / linkerd viz tap (if a mesh is present)
[ ] tcpdump-in-pod runbook
[ ] conntrack max + saturation alert
[ ] MTU optimized (1450 for VXLAN)
[ ] cert expiry alert (cert-manager)
[ ] Egress NetworkPolicy + FQDN allowlist
[ ] DNS metric + alert
[ ] LB health check + readiness probe correct
[ ] On-call: network troubleshooting runbook
[ ] Quarterly: common network incident retrospective
```

---

## 📚 References

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

> *"Network troubleshooting isn't 'intuition' — it's a **flowchart**.
> A systematic layer-by-layer, tool-by-tool pass gets you to **root cause
> in 30 minutes**. Instead of asking 'is it maybe the network,' **prove
> it**."*
