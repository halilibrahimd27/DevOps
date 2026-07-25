---
description: "Networking I: TCP/IP, ports, and routing — seeing how two machines talk at the packet level."
level: A
module: A2
estimated_hours: 14
prerequisites: [A1]
tags: [Learning Path, Networking]
---
# A2 — Networking I: TCP/IP, Ports, Routing

> *"Under every 'I can't connect' there's always a layer, a port, or a route."*

**Block:** A — Intuition · **Duration:** ~14h · **Prerequisite:** [`A1`](A1-linux-temeli.md)

## 🎯 When you finish this module
- You can narrow down which layer a connection broke at (IP, port, or routing).
- You can find and explain which port is being listened on by whom on a machine.
- You can trace the path (routing) between two machines and show where it stops.

## 🧠 Why this, why now
In A1 you got to know a single machine; real systems talk across machines. To
understand DNS, HTTP, and TLS (A3) you first need to see what a packet, a port, and a
route are. Most production failures take the form "A can't reach B" — and solving that
means narrowing down **which layer** the break is in. This module builds that
narrowing reflex.

## 📖 How to study this
Read the body, run every command on your own machine. When you need two machines: a
VM + your host machine, or two VMs, will do ([`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md)).
(You can retry this with a container-based setup once you learn it in Block C — no
need for that yet.) The modern tool is `iproute2` (`ip`, `ss`); `ifconfig`/`netstat`
are old and missing on some systems — learn `ip`/`ss`.

## 📚 Concept map
| Term | In one sentence |
|---|---|
| **IP address** | The address of a network interface (e.g. `192.168.1.10`) |
| **CIDR / subnet** | An address block and its mask (`192.168.1.0/24` = 256 addresses) |
| **Port** | A number from 0–65535 pointing to a specific service on a machine |
| **Socket** | The `<IP>:<port>` pair — one end of a connection |
| **TCP** | Reliable, ordered, connection-oriented transport (does a handshake) |
| **UDP** | Connectionless, "send and forget" transport (DNS, some metrics) |
| **Gateway** | The router you hand a packet to when leaving your own network |
| **Routing table** | The rules for "send the packet for this destination out this interface/gateway" |

---

## 1️⃣ The layer model — good enough

Think of the network in four practical layers. A failure is always in **one** layer;
your job is to find that layer:

| Layer | Question | Tool |
|---|---|---|
| **Link** (physical/interface) | Is the interface up, does it have an IP? | `ip addr`, `ip link` |
| **IP** (address/route) | Is there a path to the destination? | `ping`, `ip route`, `traceroute` |
| **Transport** (TCP/UDP + port) | Is the right port open, is it listening? | `ss`, `nc`, `telnet` |
| **Application** (HTTP/DNS/TLS) | Is the service giving a meaningful reply? | `curl`, `dig` (in A3) |

When you say "I can't connect," walk this table top to bottom: **first
interface/IP, then route, then port, and last application.** Starting from the bottom
is a vain search for the error at the top.

## 2️⃣ Seeing your own address and interfaces

```bash
ip addr                 # all interfaces and their IPs (short: ip a)
# 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
#    inet 192.168.1.10/24 brd 192.168.1.255 scope global eth0
ip link                 # interfaces' UP/DOWN status (no IP)
```

`192.168.1.10/24` carries two pieces of information: the **address**
(`192.168.1.10`) and the **mask** (`/24`). `/24` says the first 24 bits are the
network part → this network is the range `192.168.1.0`–`192.168.1.255`. Two machines
within the same `/24` talk directly; machines on a different network go through a
**gateway**.

| CIDR | Address count | Typical use |
|---|---|---|
| `/24` | 256 | A small local network / subnet |
| `/16` | 65,536 | A large private network (e.g. `10.0.0.0/16`) |
| `/32` | 1 | A single host (when writing a rule/route) |

### What the mask does — at the bit level

`/24` says the first **24 bits** of the address are the network, and the remaining
8 bits are the host. Within `192.168.1.0/24`:

```
192.168.1.  0    → network address (host bits all 0) — "the network itself"
192.168.1.  1    → first usable host (usually the gateway)
192.168.1.254    → last usable host
192.168.1.255    → broadcast (host bits all 1) — "everyone on this network"
```

The mask decides whether a machine reaches another address **directly** or through
the gateway: if the destination is inside the same network/mask, directly;
otherwise, to the gateway. The frequent answer to "why can't these two machines see
each other" is a **wrong mask** — each thinks it's on a different network and looks
for a gateway.

Know the private ranges — these aren't routed on the internet, they're local:
`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`. You'll see these blocks again when
setting up a cloud VPC in C4.

### NAT: how a private address works on the internet

If private addresses aren't routed on the internet, how does your machine at
`192.168.1.10` open a website? Thanks to **NAT** (Network Address Translation): the
gateway (your home/office router, or a cloud NAT gateway) replaces the outgoing
packet's private source address with its own **public** address, and translates the
returning reply back. This way, thousands of private addresses go out from behind a
single public address.

The practical consequence: connecting to a machine **from outside** is different
from connecting from inside to outside. Reaching a service behind NAT from outside
needs an explicit rule on the router (port forward) or a load balancer. In C4/Block
D, this is often the root cause behind "my service is running but I can't reach it
from the internet."

### ARP and DHCP — finding your neighbor and your address

Two machines on the same network actually talk using the **hardware (MAC) address**,
not the IP. What translates IP to MAC is **ARP**:

```bash
ip neigh                # ARP table: which IP is at which MAC (my neighbors)
```

Where did your machine get its IP from? If you didn't set it manually, via **DHCP**:
when it joins the network, a DHCP server leases it an IP, mask, gateway, and DNS
server. This is the source of "the machine has no IP at all" or "it got an IP from
the wrong network" failures — if `ip addr` is empty or shows an unexpected block,
look at DHCP.

## 3️⃣ Port and socket: who's listening

A machine can have many services; each listens on a **port**. `<IP>:<port>`
defines a socket. Web typically listens on `80` (HTTP) and `443` (HTTPS), SSH on
`22`, PostgreSQL on `5432`.

```bash
ss -ltnp                # listening TCP ports + which process (-p, needs sudo)
# State   Recv-Q  Local Address:Port   Process
# LISTEN  0       0.0.0.0:80           users:(("nginx",pid=812,fd=6))
sudo ss -ltnp | grep :80    # who's listening on 80
sudo lsof -i :80            # same question, using A1's lsof
```

`0.0.0.0:80` means "I'm listening on 80 on all interfaces"; `127.0.0.1:80` means
"I'm reachable only from this machine" (localhost). If you can't connect to a
service from outside, this is the frequent cause: the service bound to
`127.0.0.1`, not `0.0.0.0`.

### Probing a port by hand

```bash
nc -vz <TARGET_IP> 5432      # is 5432 open? (connection attempt with netcat)
# Connection to <TARGET_IP> 5432 port [tcp/*] succeeded!   ← open
curl -v telnet://<TARGET_IP>:5432    # if you don't have nc
```

### TCP's three-way handshake and connection states

Setting up a TCP connection takes three steps: `SYN → SYN-ACK → ACK`. Looking at a
connection's state answers the question "is it stuck, established, or closing":

```bash
ss -tan                     # all TCP connections + their states
# ESTAB   established connection        TIME-WAIT  closed, cleaning up
# SYN-SENT handshake stuck halfway (the other side isn't responding!)
```

If you see a lot of `SYN-SENT`: either the other side is down, or a firewall is
silently dropping the packets. This clue will come in handy in 5️⃣.

## 4️⃣ Routing: the packet's path

Every packet leaving your own network gets routed by consulting the **routing
table**:

```bash
ip route                    # routing table (short: ip r)
# default via 192.168.1.1 dev eth0        ← gateway for "everywhere else"
# 192.168.1.0/24 dev eth0 proto kernel    ← local network, direct
```

The `default via ...` line is the **default gateway**: if the destination doesn't
match any other rule, the packet goes there. If you can't get out of the local
network at all (`ping 1.1.1.1` doesn't work), this is the first place to check —
is there a default route?

```bash
ping -c 3 1.1.1.1           # can I reach it at the IP level? (1.1.1.1 = Cloudflare DNS)
traceroute 1.1.1.1          # which hops the packet passes, where it stops
mtr 1.1.1.1                 # live combination of traceroute + ping (if installed)
```

> If `ping 1.1.1.1` works but `ping google.com` doesn't: you're reaching the IP,
> but the **name isn't resolving** — the problem isn't the network, it's DNS (A3's
> topic). This single observation cuts your troubleshooting in half.

## 5️⃣ Two different "I can't connect"s: refused vs. timed out

This is the most valuable distinction in diagnosis; the two point to completely
different causes:

| Symptom | What it means | Likely cause |
|---|---|---|
| **Connection refused** | The packet arrived, but **nobody's listening on that port** | Service not running / wrong port / bound to `127.0.0.1` |
| **Connection timed out** | **No reply ever came** | Firewall silently dropping it / no route / machine down |

```bash
nc -vz <TARGET_IP> 8080
# ... Connection refused        → you REACHED the target machine; no service there
# ... Connection timed out      → you did NOT reach the target; network/firewall
```

"Refused" is good news: the network is working, the problem is in the service (go
back to A1: is the process up, is it listening on the right port?). "Timeout"
points to a network/firewall problem. Being able to make this distinction
automatically is the actual reflex this module gives you.

Probing the firewall (if it's local):

```bash
sudo iptables -L -n -v      # classic firewall rules
sudo nft list ruleset       # modern (nftables) equivalent
sudo ufw status             # Ubuntu's simple front end (if installed)
```

## 6️⃣ TCP or UDP — and an end-to-end example

Most services (HTTP, SSH, DB) use **TCP**: a connection is set up, packets arrive
ordered and reliable, and lost ones get retransmitted. **UDP** is connectionless
and "send and forget": it trades reliability for speed. DNS (A3) mostly uses UDP
to ask small questions quickly; live video/gaming also lean toward UDP.

The practical distinction pays off in diagnosis: you can probe a TCP port cleanly
with `nc -vz` (handshake succeeds/fails). UDP has no "success" signal — if no
reply comes back, whether "the port is closed" or "the packet was dropped" is
ambiguous. That's why UDP services (e.g. DNS) are tested at the application level
(`dig`, A3).

**An end-to-end example** — when you run `curl http://<TARGET_IP>:8080`, in order:

```bash
ip addr                          # 1. Do I have an IP, is the interface UP?
ip route get <TARGET_IP>         # 2. Which path do I take to this destination (direct or via gateway)?
ping -c1 <TARGET_IP>             # 3. Am I reaching it at the IP level?
nc -vz <TARGET_IP> 8080          # 4. Is port 8080 open/listening (refused vs timeout)?
curl -v http://<TARGET_IP>:8080  # 5. Is the application giving a meaningful reply?
```

Each step assumes the previous one. If 3 doesn't work, trying 4-5 is pointless; if
4 gives "refused" the problem is in the service (A1), if it gives "timeout" it's in
the network/firewall. These five commands turn "why can't I connect" from a guess
into **evidence** — the core of the first broken lab in B3.

---

## 🚫 Anti-pattern table
| Anti-pattern | Why it's bad | Right |
|---|---|---|
| Binding a service to `0.0.0.0` and assuming it's safe | Reachable from all interfaces; gets exposed unintentionally | Use `127.0.0.1` if you don't need it; make external exposure a deliberate choice |
| Treating "timeout" and "refused" as the same thing | Mixes up two completely different causes, sends you looking in the wrong place | Determine which one it is first, then branch |
| Starting network troubleshooting from the application | You end up hunting in vain at the top for an error that's actually at the bottom (IP/port) | Bottom-up: interface → route → port → application |
| Saying "the network's fine" because `ping` works | `ping` is ICMP (a network protocol with no concept of ports, measuring reachability); the TCP port can still be closed | Verify the port separately with `nc`/`ss` |
| Sticking with `netstat`/`ifconfig` | Deprecated; missing on some systems | Use `ss` and `ip` |
| "Hiding" a port for security (obscurity) | A port scan takes seconds; hiding isn't protection | Close access with a rule (firewall), not by hiding it |
| A broad firewall rule that opens everything | Enlarges the attack surface | Least exposure: only the port/source you need |

## 📖 Further reading (not now, later)
| Source | For what | When |
|---|---|---|
| `man ss`, `man ip` | Full reference for `ss`/`ip` subcommands | When you're curious about a flag |
| The [`09-Networking/`](../../09-Networking/README.md) folder | In-cluster Kubernetes networking (service mesh, eBPF, Gateway API) | **After Block D** — it's all cluster-internal, too advanced for now |

> Note: all of `09-Networking/`'s content is K8s networking and is far beyond this
> module's level. Don't open it now; it'll make sense after D1.

## 🔨 Lab
👉 [`labs/build/L02-ag-tcp-ip/`](../labs/build/L02-ag-tcp-ip/README.md) — (Task draft: bind a
service on different ports/interfaces, verify what's listening with `ss`/`nc`;
deliberately produce and distinguish "refused" and "timeout" conditions.)

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] You found a listening port with `ss -ltnp` (or `lsof -i`) and matched it to the process listening on it — command + output.
- [ ] You narrowed down a connection layer by layer: you applied the `ip addr` → `ip route` → `ping` → `nc/ss` sequence to a failure and showed **which layer it broke at**.
- [ ] You **wrote down** the difference between "connection refused" and "connection timed out," along with the cause each one points to.
- [ ] You **wrote down** the difference between `127.0.0.1` and `0.0.0.0`, illustrating the situation that makes a service "unreachable from outside."

## 🧪 Test yourself
1. In `ss -ltn` output, one line says `127.0.0.1:5432`, another says `0.0.0.0:80`. If you try connecting to these two services from another machine, what happens, and why?
2. **Scenario:** An application can't connect to its database. `nc -vz <DB_IP> 5432` gives "timed out." What are your first three checks?
3. **Design:** A DB should be reachable only from the application server, never from the internet. How do you set this up at the network level (addressing + listening + firewall)?

<details><summary>Answers</summary>

1. `0.0.0.0:80` is **reachable** from another machine (it's listening on all interfaces). `127.0.0.1:5432` is reachable only from its own machine; if you try from outside you get **connection refused** (nobody's listening on that interface). This is the most frequent cause of "I can't connect to a service from outside."

2. "Timed out" → you **can't reach** the target (network/firewall), not a service problem. (a) Is there a route: `ping <DB_IP>` / `ip route`. (b) Is a firewall getting in the way: where does `traceroute <DB_IP>` stop. (c) Is the port actually listening on the DB machine (if you have access there): `sudo ss -ltnp | grep 5432`. If it had been "refused" the network would be fine and you'd look at the service; since it's "timeout" you look at the network/firewall.

3. Bind the DB only to a private (internal) IP, not `0.0.0.0` — ideally on a dedicated subnet. Limit listening to the interface the application server can reach. On the firewall, open `5432` **only** to the app server's IP (`/32`), reject every other source. That way, even if the port is scanned, it's reachable only from that one source — least exposure.

</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| `Connection refused` | Service not running / wrong port / bound to `127.0.0.1` | Go back to A1: is the process up, use `ss -ltnp` to see which address/port it holds |
| `Connection timed out` | Firewall dropping it / no route / machine down | `ping`, `traceroute`, firewall rules |
| `ping IP` works, `ping name` doesn't | DNS problem, not the network | A3's topic; continue with the IP for now |
| `ss: command not found` | Minimal system | `sudo apt install iproute2` (Debian/Ubuntu) |
| `Network is unreachable` | No default route | `ip route` — is there a `default via ...` line |
| I changed the port, still seeing the old behavior | Service wasn't reloaded | Restart the service / `kill -HUP` (A1) |

## 💼 Portfolio output
No direct output; networking concepts turn into concrete output in A6's manual
deploy (service + port + firewall) and B3's broken lab.

## ⏭️ Up next
[`A3 — Networking II: DNS → HTTP → TLS/Certificate`](A3-ag-dns-http-tls.md)

---

> *"The network isn't magic; every step is visible, every break stops somewhere."*
