# Linux Troubleshooting Cheatsheet

> *"Production'da bir şey yavaş, hangi şey?"* sorusunun çoklu pencereli cevabı.

## 🎯 USE method (Brendan Gregg)

Her resource için sırasıyla:
1. **U**tilization — kaynağın % kaç meşgul?
2. **S**aturation — kuyrukta bekleyen iş var mı?
3. **E**rrors — hata var mı?

```
Resource → Utilization → Saturation → Errors
─────────────────────────────────────────────
CPU       → top, mpstat → load avg, vmstat r → dmesg
Memory    → free, vmstat → swap, vmstat b   → dmesg OOM
Disk      → iostat -xz  → iostat avgqu-sz   → dmesg, smartctl
Network   → sar -n DEV  → sar -n EDEV       → dmesg, ethtool -S
```

## 🔥 İlk 30 saniyede ne kontrol et? (Netflix protocol)

```bash
uptime              # load avg
dmesg | tail        # kernel mesajları (OOM, hardware error)
vmstat 1 5          # CPU, memory, IO genel
mpstat -P ALL 1     # CPU per-core
pidstat 1           # process başına CPU/mem
iostat -xz 1        # disk I/O
free -m             # memory durumu
sar -n DEV 1        # network bandwidth
sar -n TCP,ETCP 1   # TCP errors/retransmits
top                 # interaktif görünüm
```

## 💻 CPU

```bash
# top: hızlı genel görünüm
top
htop                # daha güzel UI
btop                # modern alternatif

# Per-process
ps aux --sort=-%cpu | head -20
ps -eLo pid,tid,pcpu,comm | sort -k3 -rn | head      # thread bazlı

# CPU profiler (en hızlı: hangi fonksiyon yanıyor?)
sudo perf top -p <PID>
sudo perf record -F 99 -p <PID> -- sleep 30 && perf report

# Alternatif: ebpf
sudo execsnoop-bpfcc           # yeni process'leri canlı yakala
sudo opensnoop-bpfcc           # file open syscall'ları
sudo tcpconnect-bpfcc          # TCP bağlantıları

# Load average yorumu
# 1, 5, 15 dk averajları
# uptime → "load average: 2.34, 1.21, 0.89"
# CPU sayısı * 1.0 = %100 dolu
nproc                          # CPU count
cat /proc/cpuinfo | grep -c ^processor

# Context switches (yüksek = çok thread/process scheduling)
vmstat 1
# cs sütunu — saniyede context switch sayısı
```

## 💾 Memory

```bash
# Genel
free -h
free -m -s 1                   # her 1 sn refresh

# Yorum:
# total, used, free, shared, buff/cache, available
# "available" = gerçekten kullanılabilen

# Per-process (RSS = gerçek RAM, VSZ = sanal)
ps aux --sort=-%mem | head -20
ps -eo pid,user,%mem,rss,comm --sort=-%mem | head

# Top process'in detayı
cat /proc/<PID>/status | grep -E 'Vm|RSS'
cat /proc/<PID>/maps           # virtual memory map
cat /proc/<PID>/smaps          # detaylı

# Swap kullanımı (yavaşlıkla ilişkili)
swapon -s
cat /proc/swaps

# OOM (memory yedi pid'i)
dmesg | grep -i 'killed process'
journalctl -k | grep -i oom

# Cache temizliği (DEV only — prod'da YAPMA)
sync && echo 3 > /proc/sys/vm/drop_caches
```

## 💽 Disk I/O

```bash
# Disk genel kullanım
df -h                          # filesystem
df -i                          # inode (önemli — biteneye kadar fark etmezsin)
du -sh *                       # klasör boyutları
du -h --max-depth=1 / | sort -h | tail

# I/O istatistikleri
iostat -xz 1
# Önemli sütunlar:
# %util   — disk meşguliyet (>%80 = darboğaz)
# await   — ortalama I/O latency (ms)
# r/s, w/s — read/write per saniye
# avgqu-sz — kuyruk derinliği

# Per-process I/O
sudo iotop                     # interaktif
sudo iotop -o                  # sadece I/O yapanlar

# Open file'ları gör
sudo lsof
sudo lsof -p <PID>             # belirli process
sudo lsof +D /var/log          # bir dizinin altındaki açık dosyalar
sudo lsof -i :8080             # bir port'u kim açmış
sudo lsof -nP | grep deleted   # silinmiş ama hâlâ açık (disk yer açma sorunu)

# strace ile syscall'ları izle
strace -p <PID>
strace -e trace=openat,read,write -p <PID>
strace -c -p <PID>             # özet (en sık syscall)
```

## 🌐 Network

```bash
# Aktif bağlantılar (ss > netstat, daha hızlı)
ss -tunlp                      # listening port'lar
ss -tunap                      # tüm bağlantılar
ss -tn state established       # established TCP'ler
ss -s                          # özet (TCP/UDP toplamları)

# Bandwidth
sar -n DEV 1
iftop                          # interaktif
nethogs                        # process başına bandwidth
bmon                           # güzel terminal grafik

# TCP retransmit (network kalitesi)
sar -n ETCP 1
ss -i                          # her connection'ın kalite metriği

# Latency (icmp + traceroute)
ping -c 5 <HOST>
mtr <HOST>                     # canlı traceroute
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
curl -I https://<DOMAIN>       # sadece headers

# Packet capture
sudo tcpdump -i any -n port 80
sudo tcpdump -i eth0 -nn -X 'tcp port 443 and host <IP>'
sudo tcpdump -i any -w capture.pcap port 5432
# Wireshark ile aç: capture.pcap
```

## 🔍 Process Tree

```bash
# Tree görünümü
pstree -p
pstree -p <PID>
ps auxf                        # forest

# Process'in açtığı dosyalar
ls -la /proc/<PID>/fd          # file descriptor'lar
readlink -f /proc/<PID>/cwd    # working directory
readlink -f /proc/<PID>/exe    # binary path

# Process'in environment'ı
cat /proc/<PID>/environ | tr '\0' '\n'

# Limits
cat /proc/<PID>/limits
ulimit -a                      # current shell

# Niye exited? exit code
echo $?
journalctl -u <SERVICE>        # systemd service log
```

## 📜 Logs

```bash
# Systemd journal
journalctl -xe                 # son hatalar + explanation
journalctl -u nginx            # specific service
journalctl -u nginx -f         # follow
journalctl -u nginx --since "1 hour ago"
journalctl -p err              # priority error+
journalctl -k                  # kernel
journalctl --disk-usage        # journal kaç yer kaplıyor

# Geleneksel /var/log
tail -f /var/log/syslog
tail -F /var/log/nginx/access.log    # rotation-aware
multitail /var/log/syslog /var/log/nginx/error.log

# Pattern arama
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
dpkg -l                        # tüm yüklü
dpkg -L <PKG>                  # paketin dosyaları
dpkg -S /usr/bin/curl          # bu dosya hangi pakete ait?

# RHEL/CentOS (rpm/yum/dnf)
rpm -qa                        # yüklü paket listesi
rpm -ql <PKG>
rpm -qf /usr/bin/curl
dnf list installed
dnf provides /usr/bin/curl

# Manuel yüklü binary
which <CMD>
type -a <CMD>
file $(which <CMD>)
ldd $(which <CMD>)             # shared libs
```

## 🔧 Systemd

```bash
# Service durumu
systemctl status nginx
systemctl is-active nginx
systemctl is-enabled nginx

# Start/stop/restart
sudo systemctl start nginx
sudo systemctl restart nginx
sudo systemctl reload nginx    # sıkı config reload (downtime yok)

# Boot'ta başlasın
sudo systemctl enable --now nginx
sudo systemctl disable nginx

# Servis listesi
systemctl list-units --type=service
systemctl list-units --failed
systemctl list-unit-files

# Service ne zaman başladı, RAM/CPU?
systemctl status nginx          # Memory, CPU columnları
systemctl show nginx --property=MemoryCurrent

# Timer (cron alternatifi)
systemctl list-timers
systemctl status backup.timer
```

## 🔐 User / Permissions

```bash
# Login bilgileri
id
whoami
groups
who                            # kim login
last                           # login geçmişi
lastb                          # başarısız login

# sudo log
journalctl _COMM=sudo
grep sudo /var/log/auth.log

# File permissions
ls -la
stat <FILE>

# Recursive permission düzeltme
find /path -type d -exec chmod 755 {} \;
find /path -type f -exec chmod 644 {} \;

# ACL (extended permissions)
getfacl <FILE>
setfacl -m u:appuser:rw <FILE>
```

## 🚨 Acil senaryolar

| Sorun | Hızlı kontrol |
|---|---|
| Sistem yavaş | `top`, `vmstat 1`, `iostat -xz 1`, `dmesg` |
| Disk dolu | `df -h`, `du -sh /var/log/*`, `lsof +D / | grep deleted` |
| OOM Killer | `dmesg | grep -i killed`, `journalctl -k | grep oom` |
| Process don | `kill -3 <PID>` (Java thread dump) veya `gdb -p <PID>` |
| Port açık değil | `ss -tlnp | grep <PORT>`, firewall: `iptables -L`, `ufw status` |
| Yüksek load ama CPU boşta | Disk I/O wait — `iostat`, `iotop` |
| Network throughput düşük | `ethtool eth0` (link speed), `mtr <HOST>`, `iperf3` test |
| DNS yavaş | `dig +trace <DOMAIN>`, `/etc/resolv.conf`, NodeLocal DNSCache |
| SSH yavaş login | DNS reverse: `/etc/ssh/sshd_config` `UseDNS no` |
| Time drift | `timedatectl status`, `chronyc sources` |
