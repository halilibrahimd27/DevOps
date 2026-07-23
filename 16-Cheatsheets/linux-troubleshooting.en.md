---
description: "Linux troubleshooting cheatsheet: CPU, memory, disk, and network diagnostics with Brendan Gregg's USE method. Tools for finding what's slow in production."
tags:
  - Cheatsheet
  - Incident Response
  - Performance
  - SRE
---
# Linux Troubleshooting Cheatsheet

> *"Something in production is slow — which thing?"* The multi-pane answer to that question.

## 🎯 USE method (Brendan Gregg)

For each resource, in order:
1. **U**tilization — what % of the resource is busy?
2. **S**aturation — is there work queued/waiting?
3. **E**rrors — are there any errors?

```
Resource → Utilization → Saturation → Errors
─────────────────────────────────────────────
CPU       → top, mpstat → load avg, vmstat r → dmesg
Memory    → free, vmstat → swap, vmstat b   → dmesg OOM
Disk      → iostat -xz  → iostat avgqu-sz   → dmesg, smartctl
Network   → sar -n DEV  → sar -n EDEV       → dmesg, ethtool -S
```

## 🔥 What to check in the first 30 seconds? (Netflix protocol)

```bash
uptime              # load avg
dmesg | tail        # kernel messages (OOM, hardware error)
vmstat 1 5          # CPU, memory, IO overview
mpstat -P ALL 1     # CPU per-core
pidstat 1           # per-process CPU/mem
iostat -xz 1        # disk I/O
free -m             # memory status
sar -n DEV 1        # network bandwidth
sar -n TCP,ETCP 1   # TCP errors/retransmits
top                 # interactive view
```

## 💻 CPU

```bash
# top: quick overview
top
htop                # nicer UI
btop                # modern alternative

# Per-process
ps aux --sort=-%cpu | head -20
ps -eLo pid,tid,pcpu,comm | sort -k3 -rn | head      # thread-level

# CPU profiler (fastest: which function is burning?)
sudo perf top -p <PID>
sudo perf record -F 99 -p <PID> -- sleep 30 && perf report

# Alternative: ebpf
sudo execsnoop-bpfcc           # catch new processes live
sudo opensnoop-bpfcc           # file open syscalls
sudo tcpconnect-bpfcc          # TCP connections

# Reading load average
# 1, 5, 15 minute averages
# uptime → "load average: 2.34, 1.21, 0.89"
# CPU count * 1.0 = 100% full
nproc                          # CPU count
cat /proc/cpuinfo | grep -c ^processor

# Context switches (high = lots of thread/process scheduling)
vmstat 1
# cs column — context switches per second
```

## 💾 Memory

```bash
# Overview
free -h
free -m -s 1                   # refresh every 1s

# Reading it:
# total, used, free, shared, buff/cache, available
# "available" = what's actually usable

# Per-process (RSS = actual RAM, VSZ = virtual)
ps aux --sort=-%mem | head -20
ps -eo pid,user,%mem,rss,comm --sort=-%mem | head

# Detail of the top process
cat /proc/<PID>/status | grep -E 'Vm|RSS'
cat /proc/<PID>/maps           # virtual memory map
cat /proc/<PID>/smaps          # detailed

# Swap usage (correlates with slowness)
swapon -s
cat /proc/swaps

# OOM (which pid ate the memory)
dmesg | grep -i 'killed process'
journalctl -k | grep -i oom

# Clearing the cache (DEV only — do NOT do this in prod)
sync && echo 3 > /proc/sys/vm/drop_caches
```

## 💽 Disk I/O

```bash
# Disk overview
df -h                          # filesystem
df -i                          # inodes (important — you won't notice until they run out)
du -sh *                       # folder sizes
du -h --max-depth=1 / | sort -h | tail

# I/O statistics
iostat -xz 1
# Key columns:
# %util   — disk busy (>80% = bottleneck)
# await   — average I/O latency (ms)
# r/s, w/s — reads/writes per second
# avgqu-sz — queue depth

# Per-process I/O
sudo iotop                     # interactive
sudo iotop -o                  # only processes doing I/O

# See open files
sudo lsof
sudo lsof -p <PID>             # specific process
sudo lsof +D /var/log          # open files under a directory
sudo lsof -i :8080             # who has this port open
sudo lsof -nP | grep deleted   # deleted but still open (disk space issue)

# Trace syscalls with strace
strace -p <PID>
strace -e trace=openat,read,write -p <PID>
strace -c -p <PID>             # summary (most frequent syscalls)
```

## 🌐 Network

```bash
# Active connections (ss > netstat, faster)
ss -tunlp                      # listening ports
ss -tunap                      # all connections
ss -tn state established       # established TCP connections
ss -s                          # summary (TCP/UDP totals)

# Bandwidth
sar -n DEV 1
iftop                          # interactive
nethogs                        # bandwidth per process
bmon                           # nice terminal graph

# TCP retransmits (network quality)
sar -n ETCP 1
ss -i                          # per-connection quality metrics

# Latency (icmp + traceroute)
ping -c 5 <HOST>
mtr <HOST>                     # live traceroute
mtr --report --report-cycles 100 <HOST>

# DNS
dig <DOMAIN>
dig +short <DOMAIN>
dig +trace <DOMAIN>            # full path
dig <DOMAIN> @8.8.8.8          # specific resolver
host <DOMAIN>
nslookup <DOMAIN>

# HTTP debug
curl -v https://<DOMAIN>
curl -w '\n%{time_namelookup} %{time_connect} %{time_total}\n' -o /dev/null -s https://<DOMAIN>
curl -I https://<DOMAIN>       # headers only

# Packet capture
sudo tcpdump -i any -n port 80
sudo tcpdump -i eth0 -nn -X 'tcp port 443 and host <IP>'
sudo tcpdump -i any -w capture.pcap port 5432
# Open with Wireshark: capture.pcap
```

## 🔍 Process Tree

```bash
# Tree view
pstree -p
pstree -p <PID>
ps auxf                        # forest

# Files opened by the process
ls -la /proc/<PID>/fd          # file descriptors
readlink -f /proc/<PID>/cwd    # working directory
readlink -f /proc/<PID>/exe    # binary path

# Process's environment
cat /proc/<PID>/environ | tr '\0' '\n'

# Limits
cat /proc/<PID>/limits
ulimit -a                      # current shell

# Why did it exit? exit code
echo $?
journalctl -u <SERVICE>        # systemd service log
```

## 📜 Logs

```bash
# Systemd journal
journalctl -xe                 # recent errors + explanation
journalctl -u nginx            # specific service
journalctl -u nginx -f         # follow
journalctl -u nginx --since "1 hour ago"
journalctl -p err              # priority error+
journalctl -k                  # kernel
journalctl --disk-usage        # how much space the journal takes up

# Traditional /var/log
tail -f /var/log/syslog
tail -F /var/log/nginx/access.log    # rotation-aware
multitail /var/log/syslog /var/log/nginx/error.log

# Pattern search
grep -E 'ERROR|FATAL' /var/log/app.log
zgrep 'ERROR' /var/log/app.log.*.gz   # rotated logs
journalctl | grep -i 'error\|fatal\|panic'
```

## 📦 Package Management

```bash
# Debian/Ubuntu (apt)
apt list --installed
apt search <PKG>
apt show <PKG>
apt-cache depends <PKG>
dpkg -l                        # all installed
dpkg -L <PKG>                  # package's files
dpkg -S /usr/bin/curl          # which package owns this file?

# RHEL/CentOS (rpm/yum/dnf)
rpm -qa                        # installed package list
rpm -ql <PKG>
rpm -qf /usr/bin/curl
dnf list installed
dnf provides /usr/bin/curl

# Manually installed binary
which <CMD>
type -a <CMD>
file $(which <CMD>)
ldd $(which <CMD>)             # shared libs
```

## 🔧 Systemd

```bash
# Service status
systemctl status nginx
systemctl is-active nginx
systemctl is-enabled nginx

# Start/stop/restart
sudo systemctl start nginx
sudo systemctl restart nginx
sudo systemctl reload nginx    # config reload (no downtime)

# Start on boot
sudo systemctl enable --now nginx
sudo systemctl disable nginx

# Service list
systemctl list-units --type=service
systemctl list-units --failed
systemctl list-unit-files

# When did the service start, RAM/CPU?
systemctl status nginx          # Memory, CPU columns
systemctl show nginx --property=MemoryCurrent

# Timer (cron alternative)
systemctl list-timers
systemctl status backup.timer
```

## 🔐 User / Permissions

```bash
# Login info
id
whoami
groups
who                            # who's logged in
last                           # login history
lastb                          # failed logins

# sudo log
journalctl _COMM=sudo
grep sudo /var/log/auth.log

# File permissions
ls -la
stat <FILE>

# Recursive permission fix
find /path -type d -exec chmod 755 {} \;
find /path -type f -exec chmod 644 {} \;

# ACL (extended permissions)
getfacl <FILE>
setfacl -m u:appuser:rw <FILE>
```

## 🚨 Emergency scenarios

| Issue | Quick check |
|---|---|
| System slow | `top`, `vmstat 1`, `iostat -xz 1`, `dmesg` |
| Disk full | `df -h`, `du -sh /var/log/*`, `lsof +D / | grep deleted` |
| OOM Killer | `dmesg | grep -i killed`, `journalctl -k | grep oom` |
| Process hung | `kill -3 <PID>` (Java thread dump) or `gdb -p <PID>` |
| Port not open | `ss -tlnp | grep <PORT>`, firewall: `iptables -L`, `ufw status` |
| High load but CPU idle | Disk I/O wait — `iostat`, `iotop` |
| Low network throughput | `ethtool eth0` (link speed), `mtr <HOST>`, `iperf3` test |
| DNS slow | `dig +trace <DOMAIN>`, `/etc/resolv.conf`, NodeLocal DNSCache |
| SSH login slow | DNS reverse: `/etc/ssh/sshd_config` `UseDNS no` |
| Time drift | `timedatectl status`, `chronyc sources` |

---

> 🎓 **Learning Path:** This document is used as the "Read first" resource in the [`B3`](../22-Learning-Path/block-b-visibility/B3-ilk-kirik-lab.md) module.
