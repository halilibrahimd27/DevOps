---
description: "Linux basics: process, filesystem, permissions, and user/group — the ground everything else stands on."
level: A
module: A1
estimated_hours: 16
prerequisites: [A0]
tags: [Learning Path, Linux]
---
# A1 — Linux Basics: Process, Filesystem, Permissions, User/Group

> *"Every abstraction beneath an engineer eventually bottoms out at a Linux process."*

**Block:** A — Intuition · **Duration:** ~16h · **Prerequisite:** [`A0`](A0-baslamadan-once.md) (a working terminal)

## 🎯 When you finish this module
- You can find a running process, inspect its resource use (CPU/memory/open files), and stop it.
- You can read a file's permission/ownership string and fix it safely with `chmod`/`chown`.
- You can explain the boundary between user, group, and `sudo` as a security boundary.

## 🧠 Why this, why now
Every module that follows (networking, deploy, containers, K8s) runs inside a Linux box.
Without seeing the process, file, and permission model, you can't read a single failure.
A container is a process; a `Permission denied` is a permission bit; a "disk full" is an
inode or block count. That's why the path starts here and assumes no prior knowledge —
it doesn't want you to memorize commands, it wants you to **hear what the system is
telling you**.

## 📖 How to study this
This module's body is the repo's **teaching** content, not a list of links. Read each
section, **run the command on your own machine**, see the output with your own eyes.
You need a local Linux: a physical machine, WSL2 (a layer running a real Linux kernel
on top of Windows), or a virtual machine (VirtualBox + Ubuntu Server). The setup path is
in [`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md). (We deliberately left out containers —
that's a Block C concept; in A1 you need to see a real operating system by hand.)
For the read/do ratio, see [`STUDY-METHOD.md`](../STUDY-METHOD.md) — the rule is simple:
**don't move to the next section until you've run every command you just read.**

## 📚 Concept map
| Term | In one sentence |
|---|---|
| **Process** | A running instance of a program the kernel runs, with a PID |
| **PID / PPID** | A process's identity / the identity of the parent process that started it |
| **Signal** | An interrupt the kernel sends to a process (`TERM`, `KILL`, `HUP`) |
| **Inode** | The record holding a file's metadata (permissions, owner, size) — not its name |
| **Mode bits** | A file's `rwx` permission string (read/write/execute) |
| **UID / GID** | User ID / group ID — the numbers permissions are based on |
| **`sudo`** | Running a single command with another user's (usually `root`) authority |

---

## 1️⃣ Mental model: everything is a process and a file

You understand a running Linux system with two questions: **which processes are
running** and **which files are they touching**. Almost every "it's not working"
bottoms out at one of these two: the process is dead/hasn't started, or it can't
access a file (config, port, socket, log).

The heart of the Unix philosophy is this: **most resources look like a file.** A disk
(`/dev/sda`), a network socket, even a running process's own information
(`/proc/<PID>/`) is read through the filesystem. That's why learning "file permissions"
is really learning "access to the system."

```bash
# See the process chain carrying your current session
ps -o pid,ppid,user,comm --forest
# pid  ppid user comm
# 1811 1810 halil bash      ← your shell
# 1899 1811 halil   \_ ps   ← ps, the shell's child
```

Every process has a **parent** (PPID). At the top of the chain sits PID 1 (`systemd`
or `init`) — the ancestor of everything on the system. In A6, when you put a service
under `systemd`, you'll be making it a permanent branch of exactly this tree.

## 2️⃣ Process: find, inspect, stop

### Seeing what's running

```bash
ps aux                      # snapshot list of all processes (user, %CPU, %MEM, command)
ps aux | grep -i nginx      # narrow down by name
pgrep -a nginx              # same job, direct: PID + command line
top                         # live, continuously refreshing table (press q to quit)
htop                        # top's more readable version (if not installed: sudo apt install htop)
```

Inside `top`, watch the `%CPU` and `%MEM` columns; sort by CPU with `P`, by memory with
`M`. This is the first place to look when someone says "the machine is slow": **which
process is eating the resource?**

### Looking inside a process

Every process exposes itself under `/proc/<PID>/`:

```bash
PID=$(pgrep -n nginx)               # PID of the most recently started nginx
cat /proc/$PID/cmdline | tr '\0' ' '  # the exact command it was started with
ls -l /proc/$PID/cwd                 # which directory it's running in
ls -l /proc/$PID/fd                  # open file descriptors (log, socket, DB connection)
```

The standard way to show open files is `lsof`:

```bash
sudo lsof -p $PID           # which files/sockets this process holds open
sudo lsof -i :8080          # WHO is listening on port 8080 (we'll see this again in A2)
```

> Deleted a file with `rm` but the disk didn't free up? A process is probably still
> holding it open. `lsof | grep deleted` reveals this. It's the classic cause of
> "I deleted it but it didn't go away."

### Stopping — sending a signal

`kill` doesn't actually mean "kill" — it means "send a signal." Choosing the right
signal matters:

```bash
kill -TERM $PID     # polite: "finish up and shut down" (default) — SIGTERM
kill -HUP  $PID     # "reread your config" (most services support this) — SIGHUP
kill -KILL $PID     # forced: the kernel destroys the process instantly — SIGKILL (-9)
```

| Signal | What it does | When |
|---|---|---|
| `TERM` (15) | Graceful shutdown; the process can clean up | **Make this your default choice** |
| `HUP` (1) | Config reload (nginx and most _daemons_ — services that run continuously in the background) | Refreshing settings without restarting |
| `KILL` (9) | Instant termination; NO cleanup | Only when `TERM` gets no response |

> 🚫 Don't make `kill -9` a reflex. `KILL` doesn't even give the process a chance to
> say "shutting down": half-written files, unreleased locks, corrupted state can be
> left behind. `TERM` first, `KILL` only if there's no response.

## 3️⃣ Filesystem: path, inode, space

### Reading the path

Linux has a single tree, rooted at `/`. There's no `C:`/`D:` like Windows; disks are
**mounted** at a point in this tree. The standard layout (FHS):

| Path | What's there |
|---|---|
| `/etc` | System-wide config (text files) |
| `/var/log` | Logs (you'll dig into this a lot in B1) |
| `/home/<USER>` | User files |
| `/usr/bin`, `/bin` | Executable programs |
| `/tmp` | Temporary; may be wiped on reboot |
| `/proc`, `/sys` | The kernel's live state (not real files) |

```bash
pwd                 # where am I (print working directory)
ls -la              # what's in this directory — including hidden (.) files, long format
find /etc -name "*.conf" -type f 2>/dev/null   # search for files by name, swallow errors
find /var/log -mmin -10                         # files changed in the last 10 minutes
```

### Space: "disk full" is two different things

```bash
df -h               # how full the filesystems are (by block) — human readable
df -i               # inode usage — by FILE COUNT
du -sh /var/log/*   # which subdirectory takes up how much space
```

If `df -h` shows 100%, the disk blocks are full. But if `df -h` shows plenty of room
and the system still says "no space left," the **inodes** have run out: a large
number of small files (e.g., millions of session files) consume inodes, not blocks.
Knowing this distinction will pay off in B3's broken lab.

```bash
# Find the top 10 space hogs (the classic "why did the disk fill up" hunt)
sudo du -x -h / 2>/dev/null | sort -rh | head -10
```

## 4️⃣ Permission model: rwx, octal, ownership

The first column of `ls -l` output tells you everything about a file:

```
-rw-r--r--  1 halil  developers  1240  ...  app.conf
│└┬┘└┬┘└┬┘    └─┬─┘  └────┬────┘
│ │   │  └ other:  r--   → everyone besides owner and group
│ │   └── group:   r--   → developers group
│ └────── owner:   rw-   → halil
└──────── type: - file, d directory, l symbolic link
```

Three permissions, for three audiences: **owner / group / other**. Each is `r`
(read), `w` (write), `x` (execute — for a directory, "enter it"). Octal equivalent:
`r=4, w=2, x=1`, summed.

| Symbolic | Octal | Meaning |
|---|---|---|
| `rwx` | 7 | read + write + execute |
| `rw-` | 6 | read + write |
| `r--` | 4 | read only |
| `rw-r--r--` | 644 | owner writes, everyone reads (typical config) |
| `rw-r-----` | 640 | owner writes, group reads, others nothing (secret file) |
| `rwx------` | 700 | only the owner can do anything (private directory) |

```bash
chmod 640 app.conf          # in octal: rw-r-----
chmod g+r,o-rwx app.conf    # symbolically: same result, step by step
stat app.conf               # shows the full permissions, owner, timestamps
```

### Ownership

```bash
chown halil:developers app.conf   # owner=halil, group=developers
chown :developers app.conf        # change only the group
sudo chown -R app:app /srv/app    # hand an entire directory tree over to a service
```

> 🚫 **`chmod 777` isn't a solution, it's a white flag.** Slapping `777` on a
> "Permission denied" hides the failure instead of finding its cause: it makes the
> file writable by everyone and erases the security boundary. The right move: find
> **which user is trying to access it, which bit is missing** — and grant only that.

### `umask`: what permissions new files are born with

```bash
umask               # e.g. 0022 → new files are born 644, new directories 755
```

`umask` isn't an "add permission" mask, it's a "strip permission" mask: it subtracts
from `666` (the file ceiling). A `0022` mask strips `w` for group/other. The answer
to why a service's files are always born world-readable is usually here.

## 5️⃣ User, group, and `sudo`: the security boundary

### Who am I, what am I a member of

```bash
id                  # uid, gid, and every group you belong to
whoami              # just the username
groups              # just your group memberships
getent passwd halil # the user's record (shell, home directory, UID)
```

Users live in `/etc/passwd`, groups in `/etc/group`, password hashes in
`/etc/shadow` (readable only by root). A service user (e.g., `www-data`, `postgres`)
is usually a user that **can't log in**, one that only does its own job — you'll set
this up yourself in A6.

### `su` vs `sudo`: why `sudo` won

```bash
su -                # fully switch to another user (root by default) — needs THEIR password
sudo <command>      # run a SINGLE command as root — YOUR OWN password + sudoers permission
sudo -u postgres psql   # run as a specific user, not root
```

`sudo` is the standard for three reasons: (1) you don't share the root password, (2)
every `sudo` call is **logged** (`/var/log/auth.log`) — who, when, which command,
(3) you can narrow authority down to the command level. Who can run what with `sudo`
is managed via `/etc/sudoers` (and `visudo`).

> This is the first **security boundary** on the path, and the thread starts here:
> what a user can do = their identity (UID) + memberships (GID) + `sudo` authority.
> In D1 you'll see the Kubernetes equivalent of this (RBAC: who, on which resource,
> can do what) — same question, different system. The "least privilege" principle
> starts here, on a single machine.

### Why we avoid root

Root crosses every boundary; if a bug or a compromised process is root, it can do
**anything**. So: everyday work as a normal user, `sudo` for a single command when
elevation is needed. Services run as their own restricted users, not `root`. This
habit comes back as the "running as root" anti-pattern in the container world
(Block D).

## 6️⃣ Input/output, redirection, and environment

Every process is born with three standard streams: **stdin** (0, input), **stdout**
(1, normal output), **stderr** (2, error output). Being able to redirect these is how
you say "send output to a file," "separate out the error," "chain two commands
together" — and it's indispensable for diagnosis.

```bash
command > out.txt         # write stdout to a file (overwrite)
command >> out.txt        # APPEND stdout to a file (at the end)
command 2> err.txt        # only stderr to a file
command > out.txt 2>&1    # stdout + stderr to the same file
command 2>/dev/null       # discard errors (silence them) — use with care
commandA | commandB       # connect A's stdout to B's stdin (pipe)
```

> The order of `2>&1` matters: "redirect stderr to **wherever stdout currently
> goes**." `> out.txt 2>&1` is correct; `2>&1 > out.txt` leaves stderr at its old
> destination. If you can't see a command's error, you've probably redirected
> stderr in the wrong order.

The pipe (`|`) is the heart of Unix: you chain small tools together to do big work.
In A5 you'll build scripts on top of this; for now, just see the chain:

```bash
ps aux | grep nginx | grep -v grep | awk '{print $2}'   # filter out nginx PIDs
journalctl -u <SERVICE> | grep -i error | tail -20        # last 20 error lines (goes deeper in B1)
```

### Environment variables and `PATH`

Every process carries an **environment**: `KEY=VALUE` pairs. The most critical one
is `PATH` — this is how the shell knows which directories to search for a command:

```bash
echo "$PATH"            # directories where commands are searched for (: separated)
which <command>         # where a command is found in PATH
export APP_ENV=prod     # define a variable for this shell (and its children)
env | sort              # all environment variables
```

A frequent cause of "command not found" is that the command isn't in `PATH`
(especially under `sudo`, `PATH` can differ). Putting secrets (passwords, tokens) in
environment variables is common, but beware: `env` output and `/proc/<PID>/environ`
can leak them — secrets management is D3's topic.

---

## 🚫 Anti-pattern table
| Anti-pattern | Why it's bad | Right |
|---|---|---|
| `kill -9` as reflex | Dies without cleanup; corrupted state/locks remain | `TERM` first, `KILL` only if no response |
| "Fixing" with `chmod 777` | Erases the permission boundary, hides the failure | Find the missing bit, grant only that (`640`/`750`) |
| Doing everything as root | One mistake hits the whole system | Normal user + a single `sudo` |
| Checking `df -h` and forgetting inodes | Can't explain "there's space but I can't write" | `df -h` for blocks, `df -i` for file count |
| Running a service as the root user | Unlimited authority if compromised | A dedicated, login-less user for the service |
| Blindly `kill`ing the result of `ps aux | grep x` | You might kill the wrong PID (even `grep` itself) | `pgrep`/`pkill`, or verify the PID |
| Looking for the password in `/etc/passwd` | Hashes are in `/etc/shadow`, `passwd` is just metadata | Know the right file; don't log/copy the secret |
| Mistaking a symlink for a real file | You edit/delete the wrong target | See the `->` target with `ls -l` |

## 📖 Further reading (not now, later)
| Source | For what | When |
|---|---|---|
| [`16-Cheatsheets/linux-troubleshooting.md`](../../16-Cheatsheets/linux-troubleshooting.md) | USE method + systematic failure narrowing | **After B3** — too early now |
| `man <command>` (e.g. `man ps`, `man chmod`) | The official, full reference for every command | When you're curious about a flag |

> Note: `man` pages live on your system, they're not an external link. Instead of
> memorizing a command, make a habit of searching inside `man` with `/` — that alone
> is a skill.

## 🔨 Lab
👉 [`labs/build/L01-linux-temeli/`](../labs/build/L01-linux-temeli/) — (Task outline: find-
inspect-stop a given process; pull a directory tree's permissions into `750`/`640`
order; create a service user.)

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] You found a process by name and ran a command sequence showing its PID, working directory, and **at least one open file** (`pgrep` → `/proc/<PID>/` or `lsof -p`), and wrote these three values to `report.txt`.
- [ ] You pulled a file's permission to `chmod 640` and verified it with `stat` (or `ls -l`); changed its owner with `chown` and showed it.
- [ ] You put `df -h` and `df -i` output side by side and explained **in writing** the two different meanings of "disk full."
- [ ] You **wrote**, in your own words (3-5 sentences), the user vs. group vs. `sudo` boundary, tying it to the "least privilege" principle.

## 🧪 Test yourself
1. You saw `-rw-r-----` in `ls -l` output. Write it in octal and say what each of the three audiences (owner/group/other) can do.
2. **Scenario:** A service won't start, saying "address already in use / port taken." Without looking at documentation, what are your first three commands?
3. **Design:** A web server should be able to only read `/srv/app/config.yml` but never modify it; it should be able to write its logs under `/var/log/app/`. How would you set up the user, group, and permissions, and why?

<details><summary>Answers</summary>

1. **`640`.** Owner: read+write (`rw-`). Group: read only (`r--`). Other: nothing (`---`). A typical "shared within the group, closed to the world" config/secret file layout.

2. Narrow it down in order: **(a)** who holds the port — `sudo lsof -i :<PORT>` or `sudo ss -ltnp | grep :<PORT>`; **(b)** what/whose that process is — take the resulting PID to `ps -p <PID> -o pid,user,comm`; **(c)** what the service's own log says — `journalctl -u <SERVICE> -n 50` (goes deeper in B1). Not a guess, evidence: see which process holds the port.

3. Create a dedicated, login-less user+group for the service (e.g. `appuser:appgroup`). `chown root:appgroup` + `chmod 640` on `config.yml` → the service **reads** it through the group, can't write. `chown appuser:appgroup /var/log/app` + `chmod 750` on the log directory → the service writes its own log. This way the service can't modify the config (even if compromised, it can't break the setting) but it can still do its job — **least privilege**.

</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| `Permission denied` | Missing `r`/`w`/`x` bit or wrong ownership | Read the bits with `ls -l`, see your identity with `id`; don't grant `777`, grant the missing bit |
| `kill` "No such process" | PID changed / process already died / wrong PID | Get the current PID with `pgrep -a <name>` |
| `sudo: command not found` | `PATH` differs under `sudo` | Give the full path (`sudo /usr/sbin/<command>`) or use `sudo -i` |
| "No space left" but `df -h` is empty | Inodes ran out | `df -i`; find the directory leaving behind lots of small files |
| Deleted it, disk didn't free up | A process is holding the file open | `lsof | grep deleted` → restart the process |
| `chown: invalid user` | User/group doesn't exist | Check with `getent passwd <name>` / `getent group <name>` |

## 💼 Portfolio output
No direct portfolio output; this is foundational competency. The evidence shows up
in later blocks' outputs (A6's manual deploy, B3's broken-lab diagnosis flow).

## ⏭️ Up next
[`A2 — Networking I: TCP/IP, Port, Routing`](A2-ag-tcp-ip.md)

---

> *"Knowing Linux isn't memorizing tools; it's being able to hear what the system is telling you."*
