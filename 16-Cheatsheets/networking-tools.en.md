---
description: "Network diagnostics tools cheatsheet: dig for DNS, connectivity and port tests, 7-layer troubleshooting. For scenarios where ping works but the app returns 503."
tags:
  - Cheatsheet
  - Networking
  - Incident Response
---
# Networking Tools Cheatsheet

> *"Ping ran, came back; curl worked; but the app returns 503."*
> The network has 7 layers, and there's a separate tool for testing each one.

## 🌐 DNS

```bash
# Single-line A record
dig +short <DOMAIN>

# Detailed
dig <DOMAIN>
dig <DOMAIN> AAAA              # IPv6
dig <DOMAIN> MX                # mail
dig <DOMAIN> TXT               # SPF, DKIM, ownership
dig <DOMAIN> NS                # name servers
dig <DOMAIN> CNAME

# Specify resolver
dig <DOMAIN> @8.8.8.8           # Google
dig <DOMAIN> @1.1.1.1           # Cloudflare
dig <DOMAIN> @<INTERNAL_DNS>    # internal DNS

# Full path (recursive trace)
dig +trace <DOMAIN>

# Reverse DNS
dig -x <IP>
host <IP>

# DNSSEC check
dig +dnssec <DOMAIN>

# From /etc/hosts or from DNS?
getent hosts <DOMAIN>
```

## 📡 Ping & Latency

```bash
# Simple
ping -c 5 <HOST>
ping -i 0.2 <HOST>             # 200ms interval
ping -s 1500 <HOST>             # MTU test (-M do for Don't Fragment)
ping -M do -s 1472 <HOST>       # 1472 + 28 IP/ICMP header = 1500

# Continuous, with statistics
ping -c 100 -q <HOST>          # 100 packets, summary only

# IPv6
ping6 <HOST>
ping -6 <HOST>

# Modern alternative (port-based, for networks that block ICMP)
nc -zv <HOST> 443
mtr <HOST>                     # live traceroute
mtr --report --report-cycles 50 <HOST>
```

## 🛤️ Traceroute

```bash
# Traditional UDP
traceroute <HOST>
traceroute -n <HOST>            # don't resolve DNS

# ICMP
traceroute -I <HOST>

# TCP (to bypass firewalls)
traceroute -T -p 443 <HOST>
tcptraceroute <HOST> 443

# Modern: mtr
mtr <HOST>                     # live, packet loss + latency
mtr --report-wide --report-cycles 100 <HOST>
```

## 🔌 Port Scan / Test

```bash
# Is a port open? (fastest)
nc -zv <HOST> 443
nc -zv <HOST> 80-443           # range

# UDP
nc -zuv <HOST> 53

# nmap (extra detail, for fingerprinting)
nmap <HOST>                    # default top 1000 ports
nmap -p 80,443 <HOST>
nmap -p- <HOST>                # all 65535
nmap -sV <HOST>                # service version
nmap -O <HOST>                 # OS detection (root)
nmap -sU <HOST>                # UDP

# Fast network discovery
nmap -sn 192.168.1.0/24        # ping sweep, list hosts

# Local listening ports
ss -tunlp
ss -t -a state listening
netstat -tlnp                  # old, ss is preferred
lsof -i -P -n | grep LISTEN
```

## 📦 Packet Capture

```bash
# tcpdump basics
sudo tcpdump -i any -n port 80
sudo tcpdump -i eth0 host <IP>
sudo tcpdump -i eth0 'tcp port 443 and host <IP>'

# Save output to a file (opens in Wireshark)
sudo tcpdump -i any -w capture.pcap port 5432
sudo tcpdump -r capture.pcap -nn      # read from file

# Hex/ASCII dump
sudo tcpdump -i any -X port 80
sudo tcpdump -i any -A port 80         # ASCII (for text protocols like HTTP)

# tshark (Wireshark CLI)
sudo tshark -i any -f "port 80" -T fields -e ip.src -e ip.dst -e http.host

# Kubernetes pod capture
kubectl run --rm -it netshoot --image=nicolaka/netshoot -- tcpdump -i any
# or: kubectl debug -it <POD> --image=nicolaka/netshoot --target=<CONTAINER>
```

## 🌍 HTTP/HTTPS Testing

```bash
# curl basics
curl https://<DOMAIN>
curl -i https://<DOMAIN>           # response + body
curl -I https://<DOMAIN>           # headers only
curl -L https://<DOMAIN>           # follow redirects
curl -v https://<DOMAIN>           # verbose (includes TLS handshake)

# Send headers
curl -H "Authorization: Bearer <TOKEN>" -H "Content-Type: application/json" \
  -X POST -d '{"key":"value"}' https://api.<DOMAIN>/path

# Method
curl -X POST | PUT | DELETE | PATCH

# Form data
curl -F "file=@local.jpg" https://api.<DOMAIN>/upload
curl -d "param1=value1&param2=value2" https://api.<DOMAIN>/form

# Timing breakdown (duration of each stage)
curl -w '\n
time_namelookup:    %{time_namelookup}\n
time_connect:       %{time_connect}\n
time_appconnect:    %{time_appconnect}\n
time_pretransfer:   %{time_pretransfer}\n
time_starttransfer: %{time_starttransfer}\n
time_total:         %{time_total}\n
http_code:          %{http_code}\n' \
  -o /dev/null -s https://<DOMAIN>

# Specific resolver (DNS bypass)
curl --resolve <DOMAIN>:443:<IP> https://<DOMAIN>

# TLS version test
curl --tlsv1.2 --tls-max 1.2 https://<DOMAIN>
curl --tlsv1.3 https://<DOMAIN>

# Client cert
curl --cert client.crt --key client.key https://<DOMAIN>

# Accept self-signed cert (DEV only)
curl -k https://<DOMAIN>
```

## 🔐 TLS / Certificate

```bash
# Inspect certificate
echo | openssl s_client -connect <DOMAIN>:443 -servername <DOMAIN> 2>/dev/null \
  | openssl x509 -noout -text | head -30

# Expiry only
echo | openssl s_client -connect <DOMAIN>:443 -servername <DOMAIN> 2>/dev/null \
  | openssl x509 -noout -dates

# Certificate chain
echo | openssl s_client -showcerts -connect <DOMAIN>:443 -servername <DOMAIN>

# SAN (Subject Alternative Names)
echo | openssl s_client -connect <DOMAIN>:443 -servername <DOMAIN> 2>/dev/null \
  | openssl x509 -noout -text | grep -A1 'Subject Alternative Name'

# Cipher suite test
openssl s_client -connect <DOMAIN>:443 -tls1_2 -cipher 'ECDHE-RSA-AES256-GCM-SHA384'

# TLS scan with nmap
nmap --script ssl-enum-ciphers -p 443 <DOMAIN>

# testssl.sh (most comprehensive)
docker run --rm -ti drwetter/testssl.sh https://<DOMAIN>
```

## 🚇 SSH Tunnel

```bash
# Local forward (local port → resource on remote)
# Local 5432 → remote 10.0.0.5:5432 (via jump host)
ssh -L 5432:10.0.0.5:5432 user@<JUMP_HOST>

# Remote forward (remote port → local)
# Remote 8080 → local 8080
ssh -R 8080:localhost:8080 user@<REMOTE>

# Dynamic / SOCKS proxy
ssh -D 1080 user@<HOST>
# Browser/curl SOCKS5 proxy: localhost:1080

# Multiple jumps (via jump host to a second host)
ssh -J jump1@host1,jump2@host2 user@target
ssh -o ProxyJump=jump@<JUMP_HOST> user@<TARGET>

# Background tunnel
ssh -fN -L 5432:db:5432 user@<JUMP>
# -f: background, -N: no command

# Persistent (via config)
# ~/.ssh/config
Host db-tunnel
  HostName <JUMP_HOST>
  User myuser
  LocalForward 5432 db-internal:5432
```

## 🔥 Firewall (iptables / ufw / nftables)

```bash
# UFW (Ubuntu, simple)
sudo ufw status verbose
sudo ufw allow 80/tcp
sudo ufw allow from 10.0.0.0/8 to any port 22
sudo ufw enable

# iptables
sudo iptables -L -n -v
sudo iptables -L -n -v -t nat       # NAT table
sudo iptables-save > rules.bak
sudo iptables-restore < rules.bak

# nftables (modern replacement)
sudo nft list ruleset
```

## 📈 Bandwidth Test

```bash
# iperf3 (most accurate)
# On the server side:
iperf3 -s

# On the client side:
iperf3 -c <SERVER_IP>
iperf3 -c <SERVER_IP> -t 30 -P 4    # 30 sec, 4 parallel streams
iperf3 -c <SERVER_IP> -u -b 100M    # UDP, 100 Mbit target

# speedtest (Internet)
speedtest-cli
fast.com (CLI: npm i -g fast-cli)
```

## 🛠️ K8s Network Debug

```bash
# Ping/curl from pod to service
kubectl run -it --rm netshoot --image=nicolaka/netshoot -- bash
# inside:
#   ping <SVC>.<NS>
#   nslookup <SVC>.<NS>
#   curl http://<SVC>.<NS>:8080/health

# DNS query
kubectl run -it --rm dns-test --image=busybox -- nslookup kubernetes.default

# NetworkPolicy test
kubectl run --rm -it --labels="app=client" --image=curlimages/curl curl-test -- \
  curl -m 5 http://<SVC>.<NS>

# Service endpoint check (does selector match?)
kubectl get svc <SVC>
kubectl get endpoints <SVC>
kubectl get endpointslices -l kubernetes.io/service-name=<SVC>

# Pod-to-pod connectivity
kubectl exec -it <POD-A> -- ping <POD-B-IP>
```

## 🆘 Emergency scenarios

| Issue | Ordered checks |
|---|---|
| `Connection refused` | Is the server running? Is the port correct? Firewall? `nc -zv` |
| `Connection timeout` | Is there a network path? Trace path with `mtr`; is firewall dropping it? |
| `No route to host` | Routing table: `ip route`, `traceroute` |
| DNS not working | `dig`, `/etc/resolv.conf`, `systemd-resolve --status` |
| TLS error | Test cert/cipher with `openssl s_client`, check expiry |
| HTTP 502/504 | Is upstream running? Reverse proxy log; backend timeout |
| Slow response | Stage-by-stage timing with `curl -w`; CDN cache miss? |
| Random 503 | Load balancer healthcheck inconsistent; pod restart loop |
