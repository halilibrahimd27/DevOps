---
description: "Network teshis araclari cheatsheet'i: DNS icin dig, baglanti ve port testleri, 7 katmanli sorun giderme. Ping doner ama uygulama 503 verir senaryolari icin."
---
# Networking Tools Cheatsheet

> *"Pingledi, döndü; curl çalıştı; ama uygulama 503 veriyor."*
> Network'te 7 layer var, her birini test eden ayrı tool.

## 🌐 DNS

```bash
# Tek satır A record
dig +short <DOMAIN>

# Detaylı
dig <DOMAIN>
dig <DOMAIN> AAAA              # IPv6
dig <DOMAIN> MX                # mail
dig <DOMAIN> TXT               # SPF, DKIM, ownership
dig <DOMAIN> NS                # name server'lar
dig <DOMAIN> CNAME

# Resolver belirt
dig <DOMAIN> @8.8.8.8           # Google
dig <DOMAIN> @1.1.1.1           # Cloudflare
dig <DOMAIN> @<INTERNAL_DNS>    # iç DNS

# Tam path (recursive trace)
dig +trace <DOMAIN>

# Reverse DNS
dig -x <IP>
host <IP>

# DNSSEC kontrol
dig +dnssec <DOMAIN>

# /etc/hosts'tan mı yoksa DNS'ten mi?
getent hosts <DOMAIN>
```

## 📡 Ping & Latency

```bash
# Basit
ping -c 5 <HOST>
ping -i 0.2 <HOST>             # 200ms aralık
ping -s 1500 <HOST>             # MTU test (Don't Fragment için -M do)
ping -M do -s 1472 <HOST>       # 1472 + 28 IP/ICMP header = 1500

# Sürekli, statistic ile
ping -c 100 -q <HOST>          # 100 paket, sadece özet

# IPv6
ping6 <HOST>
ping -6 <HOST>

# Modern alternatif (port-based, ICMP block'lu network'ler için)
nc -zv <HOST> 443
mtr <HOST>                     # canlı traceroute
mtr --report --report-cycles 50 <HOST>
```

## 🛤️ Traceroute

```bash
# Geleneksel UDP
traceroute <HOST>
traceroute -n <HOST>            # DNS resolve etme

# ICMP
traceroute -I <HOST>

# TCP (firewall'ları bypass için)
traceroute -T -p 443 <HOST>
tcptraceroute <HOST> 443

# Modern: mtr
mtr <HOST>                     # canlı, paket loss + latency
mtr --report-wide --report-cycles 100 <HOST>
```

## 🔌 Port Tarama / Test

```bash
# Bir port açık mı? (en hızlı)
nc -zv <HOST> 443
nc -zv <HOST> 80-443           # range

# UDP
nc -zuv <HOST> 53

# nmap (ekstra detay, fingerprinting için)
nmap <HOST>                    # default top 1000 port
nmap -p 80,443 <HOST>
nmap -p- <HOST>                # tüm 65535
nmap -sV <HOST>                # service version
nmap -O <HOST>                 # OS detection (root)
nmap -sU <HOST>                # UDP

# Hızlı network discovery
nmap -sn 192.168.1.0/24        # ping sweep, host listele

# Yerel listening port'lar
ss -tunlp
ss -t -a state listening
netstat -tlnp                  # eski, ss tercih edilir
lsof -i -P -n | grep LISTEN
```

## 📦 Packet Capture

```bash
# tcpdump basics
sudo tcpdump -i any -n port 80
sudo tcpdump -i eth0 host <IP>
sudo tcpdump -i eth0 'tcp port 443 and host <IP>'

# Output'u dosyaya kaydet (Wireshark'ta açılır)
sudo tcpdump -i any -w capture.pcap port 5432
sudo tcpdump -r capture.pcap -nn      # dosyadan oku

# Hex/ASCII dump
sudo tcpdump -i any -X port 80
sudo tcpdump -i any -A port 80         # ASCII (HTTP gibi text protocol için)

# tshark (Wireshark CLI)
sudo tshark -i any -f "port 80" -T fields -e ip.src -e ip.dst -e http.host

# Kubernetes pod capture
kubectl run --rm -it netshoot --image=nicolaka/netshoot -- tcpdump -i any
# veya: kubectl debug -it <POD> --image=nicolaka/netshoot --target=<CONTAINER>
```

## 🌍 HTTP/HTTPS Testing

```bash
# curl temel
curl https://<DOMAIN>
curl -i https://<DOMAIN>           # response + body
curl -I https://<DOMAIN>           # sadece headers
curl -L https://<DOMAIN>           # redirect'leri takip
curl -v https://<DOMAIN>           # verbose (TLS handshake dahil)

# Header'ları gönder
curl -H "Authorization: Bearer <TOKEN>" -H "Content-Type: application/json" \
  -X POST -d '{"key":"value"}' https://api.<DOMAIN>/path

# Method
curl -X POST | PUT | DELETE | PATCH

# Form data
curl -F "file=@local.jpg" https://api.<DOMAIN>/upload
curl -d "param1=value1&param2=value2" https://api.<DOMAIN>/form

# Timing breakdown (her aşamanın süresi)
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

# Self-signed cert kabul (DEV only)
curl -k https://<DOMAIN>
```

## 🔐 TLS / Certificate

```bash
# Sertifika incele
echo | openssl s_client -connect <DOMAIN>:443 -servername <DOMAIN> 2>/dev/null \
  | openssl x509 -noout -text | head -30

# Expiry sadece
echo | openssl s_client -connect <DOMAIN>:443 -servername <DOMAIN> 2>/dev/null \
  | openssl x509 -noout -dates

# Sertifika zinciri
echo | openssl s_client -showcerts -connect <DOMAIN>:443 -servername <DOMAIN>

# SAN (Subject Alternative Names)
echo | openssl s_client -connect <DOMAIN>:443 -servername <DOMAIN> 2>/dev/null \
  | openssl x509 -noout -text | grep -A1 'Subject Alternative Name'

# Cipher suite test
openssl s_client -connect <DOMAIN>:443 -tls1_2 -cipher 'ECDHE-RSA-AES256-GCM-SHA384'

# nmap ile TLS scan
nmap --script ssl-enum-ciphers -p 443 <DOMAIN>

# testssl.sh (en kapsamlı)
docker run --rm -ti drwetter/testssl.sh https://<DOMAIN>
```

## 🚇 SSH Tunnel

```bash
# Local forward (lokal port → remote'taki kaynak)
# Lokal 5432 → remote 10.0.0.5:5432 (jump host üzerinden)
ssh -L 5432:10.0.0.5:5432 user@<JUMP_HOST>

# Remote forward (remote port → lokal)
# Remote 8080 → lokal 8080
ssh -R 8080:localhost:8080 user@<REMOTE>

# Dynamic / SOCKS proxy
ssh -D 1080 user@<HOST>
# Browser/curl SOCKS5 proxy: localhost:1080

# Multiple jumps (jump host üzerinden ikinci hosta)
ssh -J jump1@host1,jump2@host2 user@target
ssh -o ProxyJump=jump@<JUMP_HOST> user@<TARGET>

# Background tunnel
ssh -fN -L 5432:db:5432 user@<JUMP>
# -f: background, -N: no command

# Persistent (config'le)
# ~/.ssh/config
Host db-tunnel
  HostName <JUMP_HOST>
  User myuser
  LocalForward 5432 db-internal:5432
```

## 🔥 Firewall (iptables / ufw / nftables)

```bash
# UFW (Ubuntu, basit)
sudo ufw status verbose
sudo ufw allow 80/tcp
sudo ufw allow from 10.0.0.0/8 to any port 22
sudo ufw enable

# iptables
sudo iptables -L -n -v
sudo iptables -L -n -v -t nat       # NAT tablosu
sudo iptables-save > rules.bak
sudo iptables-restore < rules.bak

# nftables (modern replacement)
sudo nft list ruleset
```

## 📈 Bandwidth Test

```bash
# iperf3 (en doğru)
# Server tarafında:
iperf3 -s

# Client tarafında:
iperf3 -c <SERVER_IP>
iperf3 -c <SERVER_IP> -t 30 -P 4    # 30 sn, 4 parallel stream
iperf3 -c <SERVER_IP> -u -b 100M    # UDP, 100 Mbit hedef

# speedtest (Internet)
speedtest-cli
fast.com (CLI: npm i -g fast-cli)
```

## 🛠️ K8s Network Debug

```bash
# Pod'dan service'e ping/curl
kubectl run -it --rm netshoot --image=nicolaka/netshoot -- bash
# içeride:
#   ping <SVC>.<NS>
#   nslookup <SVC>.<NS>
#   curl http://<SVC>.<NS>:8080/health

# DNS sorgu
kubectl run -it --rm dns-test --image=busybox -- nslookup kubernetes.default

# NetworkPolicy testi
kubectl run --rm -it --labels="app=client" --image=curlimages/curl curl-test -- \
  curl -m 5 http://<SVC>.<NS>

# Service endpoint kontrol (selector eşleşiyor mu?)
kubectl get svc <SVC>
kubectl get endpoints <SVC>
kubectl get endpointslices -l kubernetes.io/service-name=<SVC>

# Pod-to-pod konnektivite
kubectl exec -it <POD-A> -- ping <POD-B-IP>
```

## 🆘 Acil senaryolar

| Sorun | Sıralı kontrol |
|---|---|
| `Connection refused` | Server çalışıyor mu? Port doğru mu? Firewall? `nc -zv` |
| `Connection timeout` | Network yolu var mı? `mtr` ile path; firewall drop mu? |
| `No route to host` | Routing tablosu: `ip route`, `traceroute` |
| DNS çalışmıyor | `dig`, `/etc/resolv.conf`, `systemd-resolve --status` |
| TLS error | `openssl s_client` ile cert/cipher test, expiry kontrol |
| HTTP 502/504 | upstream çalışıyor mu? Reverse proxy log; backend timeout |
| Slow response | `curl -w` ile aşama aşama timing; CDN cache miss? |
| Random 503 | Load balancer healthcheck tutarsız; pod restart döngüsü |
