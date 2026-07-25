---
description: "Before you start: set up your working environment, get comfortable with the terminal, and learn how this path works."
level: A
module: A0
estimated_hours: 6
prerequisites: []
tags: [Learning Path, Getting Started]
---
# A0 — Before You Start: Environment, Terminal, and How This Path Works

> *"Before you can learn a tool, you have to be able to hold it. This module puts the terminal in your hands."*

**Block:** A — Intuition · **Duration:** ~6h · **Prerequisite:** none (the path's actual entry point)

## 🎯 When you finish this module
- You have a working Linux terminal on your own machine; you can run commands in it and read their output.
- You run a command, read the error when it fails, and find help on your own with `--help`/`man`.
- You know this path's read → do → verify → advance loop, and where to mark your progress.

## 🧠 Why this, why now
A1 drops you straight into processes, file permissions, and the user model. But to
see any of that, you first need **a working Linux**, **a terminal you can type into
without fear**, and **knowing where to look when you get stuck**. This module builds
that foundation: environment + terminal ergonomics + the path's user manual. If we
left these for A1, A1 couldn't keep its promise of "assuming no prior knowledge." A0
is short but it isn't optional — every command from here on runs on the machine you
set up right here.

> If your environment is already set up (terminal opens, commands run, you use an
> editor), A0 is just a check for you: clear the acceptance criteria below in
> 20 minutes and jump to A1. If you're not sure, don't skip — [`PLACEMENT.md`](../PLACEMENT.md)
> settles this with a test.

## 📖 How to study this
This module is **hands-on**; it's not text to read and move past. Run every command
**on your own machine**, see the output with your own eyes. Keep two files open
alongside this module:
- [`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md) → three ways to set up a local Linux
  (WSL2 / Multipass / VirtualBox). The setup steps are there; we don't repeat them here.
- [`STUDY-METHOD.md`](../STUDY-METHOD.md) → the read/do ratio and the external-resource
  contract. The rule is simple: **don't move to the next section until you've run
  every command you just read.**

## 📚 Concept map
| Term | In one sentence |
|---|---|
| **CLI** | Command-Line Interface — a text interface you drive by typing commands (keyboard, not mouse) |
| **Terminal** | The window/app that displays the CLI (the screen hosting the shell) |
| **Shell** | The program that takes the command you type and runs it (`bash`, `zsh`) |
| **Prompt** | The shell's "I'm waiting for your command" marker (`<user>@<machine>:~$`) |
| **Command / argument / flag** | `ls -l /etc` → command=`ls`, flag=`-l`, argument=`/etc` |
| **Exit code** | The number a command leaves behind when it finishes: `0` success, `not 0` error |
| **Path** | A file/directory's address: absolute (`/etc/hosts`) or relative (`../log`) |

---

## 1️⃣ What DevSecOps stands for — the shape of the path

It's the fusion of three words — three separate jobs meeting on **the same team**:

| Piece | Question | In this path |
|---|---|---|
| **Dev** (development) | How is the application written/packaged? | A4, A5, C1, C2 |
| **Ops** (operations) | How is the application run and kept up? | A6, B, D, E |
| **Sec** (security) | How is it built secure **from the start**? | not a separate block — a thread woven through all of them |

"Sec" not being a separate block is deliberate. Leaving security for last is the
most common mistake this repo criticizes; so security flows through from day one
(users/permissions in A1, RBAC in D1). Detail: [`CURRICULUM.md`](../CURRICULUM.md) →
"Security as an internal thread".

The path's body is six blocks; the order is built on **dependency**, not technology —
each step's justification is that it's required to understand the next one:

```
A Intuition → B Visibility → C Reproducibility → D Orchestration → E Ownership → F Judgment
```

You don't need to memorize the map now. Just know **where you're headed**:
[`README.md`](../README.md) explains, in one page, who this path serves and how.
A0's job is to leave you at A1's door with a working terminal in hand.

## 2️⃣ Set up your environment: four pieces

If you're starting from scratch, you need four things. The third and fourth are
quick; the real work is setting up the second.

| Piece | For what | Where from |
|---|---|---|
| **Terminal** | The window where you type commands | Comes built-in on Linux/macOS; on Windows via WSL2 |
| **Local Linux** | The operating system this path runs on | [`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md) → 🐧 section |
| **Text editor** | You'll write config/scripts | `nano` (for now) — below |
| **GitHub account** | You'll use Git in A4, CI in C2, both on this | Free account at github.com |

**We deliberately left containers off this list.** Docker is a Block C concept; in
Block A you need to see a real operating system with your own hands — the layer
underneath the abstraction. In A6 you'll bring up an application **by hand** (no
container); that requires a real Linux box.

When you finish setup, these two commands should work — if they do, your environment
is ready:

```bash
uname -a            # kernel + architecture: you should see "Linux ... x86_64" or "... aarch64"
whoami              # who you're logged in as right now (must NOT be root, should be a normal user)
```

> If you're on an Apple Silicon Mac or an ARM-based machine, `uname -m` will tell you
> `aarch64`/`arm64`. That's not a problem, but later, when downloading binaries
> (node_exporter, kubectl…), you'll need to pick the right architecture. Note it now:
> **which architecture are you on?**

## 3️⃣ Get comfortable with the terminal: prompt, command, interrupt

The terminal looks intimidating because it's empty — it doesn't tell you what to
do. But its language is simple. Break down one line:

```
halil@devbox:~$ ls -l /etc
└─┬─┘ └──┬─┘     ┬  ┬ └─┬┘
  │      │       │  │   └─ argument: which directory — /etc
  │      │       │  └───── flag: "long form" — -l
  │      │       └──────── command: what to do — ls
  │      └──────────────── machine name — devbox
  └─────────────────────── username — halil
```

The trailing symbol tells you who you are:

| Symbol | Meaning | Caution |
|---|---|---|
| `$` | You're a normal user | Everyday work happens here |
| `#` | You're **root** (full privileges) | Any command may be irreversible — think twice |

`~` means your home directory (`/home/<user>`); the prompt shows which directory
you're in.

### Running a command and knowing when it's "done"

Type the command, press **Enter**. The shell runs it, output lands on screen, then
the prompt comes back — if the prompt is back, the command **is done**. When you
want to check whether it succeeded, you can ask:

```bash
ls /etc
echo $?             # the exit code of the previous command: 0 = success, any other number = error
```

`$?` is your first "did it work?" tool. For now, one thing is enough: **`0` is
good, `not 0` is bad.** The why and how goes deeper in A5 (Bash).

### Keys that keep you in control

If a command hangs or you typed something wrong, don't panic — the keyboard is
yours:

| Key | What it does | When |
|---|---|---|
| `Ctrl-C` | **Interrupt** the running command | A command won't end / is hanging |
| `Ctrl-D` | Input ended (EOF) / exit the shell | Closing a session |
| `Ctrl-L` | Clear the screen (same as `clear`) | Tidying up a cluttered screen |
| `Ctrl-A` / `Ctrl-E` | Jump to start / end of line | Fixing a long command |
| `Tab` | **Complete** a command/file name | Avoiding typos |
| `↑` / `↓` | Browse previous commands | Re-running the same command |

`Tab` completion and `↑` history are one habit, not two: you type less, you make
fewer mistakes. The `history` command dumps your entire history.

### Copy-paste: the most dangerous habit

You'll copy commands from the internet — that's normal. But there are two traps:

1. **Smart quotes.** Web pages print curly quotes like `"` `"` instead of `"`; the
   shell doesn't understand them, and the command breaks. When in doubt, type the
   quote by hand as a straight `"`/`'`.
2. **Running it without understanding it.** Before pasting a command, **read what
   it does.** Blindly running a line containing `sudo`, `rm`, or `| bash` means
   letting someone do whatever they want on your machine as root. Rule (reinforced
   in Section 5): **before you run it, get to know every part with `--help`/`man`.**

## 4️⃣ Navigate the filesystem: get around with five commands

A1 goes deep into the filesystem (permissions, inodes, disk space). A0's job is
more modest: **being able to move around without getting lost.** Five commands are
enough.

```bash
pwd                 # "print working directory" — where am I right now?
ls                  # what's in this directory
cd /etc             # go to a directory (change directory)
cd ..               # go up one directory
cat /etc/hostname   # print a short file's contents to the screen
less /etc/services  # read a long file page by page — q to quit, / to search inside it
```

The rule for reading paths:

| Form | Where |
|---|---|
| `/etc/hosts` | **Absolute** path — full address from the root (`/`) |
| `log/app.log` | **Relative** path — relative to your current directory |
| `~` | Your home directory (`/home/<user>`) |
| `.` | This directory |
| `..` | One directory up |
| `cd -` | Go back to the previous directory you were in |

> There's no such thing as "I'm lost": `pwd` always tells you where you are, `cd ~`
> takes you home. If you want to see a directory tree visually, `tree` (if not
> installed, `sudo apt install tree`) does the job.

## 5️⃣ Get help: nobody memorizes this

Senior engineers don't memorize commands; they **find help fast.** Three doors:

```bash
ls --help           # quick summary: list of flags, one screen
man ls              # full manual: everything about it — / to search, q to quit
type ls             # what/where this command is (a shell builtin or a program)
```

`--help` is a "reminder," `man` is the "official, complete reference." When you're
wondering what a flag does, try `--help` first, and `man` if that's not enough.
`man` isn't an external link — it's inside your system, there even without
internet.

### Reading an error message

The most expensive habit of a beginner is retrying without reading the error. But
the error message is often **the solution itself**:

```bash
$ cat /etc/shadow
cat: /etc/shadow: Permission denied      # ← the last line tells you exactly what happened
```

Rule: **read the last line.** Search for the part you don't understand (here,
`Permission denied`) verbatim. This will come back as a permission bit in A1, an
RBAC `forbidden` in D1 — the common language of all of them is "what did the
system tell you?"

You're not alone when you get stuck: every module has a `🆘 If you're stuck` table,
and there's a path-wide [`TROUBLESHOOTING.md`](../TROUBLESHOOTING.md). When/how to
search externally is written in [`STUDY-METHOD.md`](../STUDY-METHOD.md) — not
randomly, by contract.

## 6️⃣ Edit a file: `nano`

In A6 you'll write a `systemd` unit, an nginx config, a `.env` file. For that you
need an editor. `vim` and `emacs` are powerful, but right now their learning curve
gets in the way — so start with **`nano`**:

```bash
nano notlar.txt     # open the file (creates it if missing)
# ... write ...
# Ctrl-O  → save (asks for the filename, confirm with Enter)
# Ctrl-X  → exit
```

`nano`'s bottom bar already lists the commands (`^O` = `Ctrl-O`). No memorizing.
Move to `vim` later if you're curious; for now the point is the editor being a
tool, not an obstacle.

## 7️⃣ How to work through this path

This isn't a reading list, it's a curriculum. Every module follows the same loop:

```
read → do (lab / command) → verify (acceptance criterion) → next module if you pass / go back if you don't
```

Four habits make this path work:

1. **Don't move to the next module before clearing the acceptance criterion.**
   "I understood" isn't a criterion; a criterion is a command's output or a
   sentence you wrote.
2. **Mark your progress.** Copy [`PROGRESS-TEMPLATE.md`](../PROGRESS-TEMPLATE.md)
   for yourself; check off each module as you finish it. This file tells you where
   you left off.
3. **Decide where to start with a test.** If you're starting from scratch, start
   here (A0→A1). If you already know Linux/code, [`PLACEMENT.md`](../PLACEMENT.md)
   lets you **skip** a block — but through a check test, not just "I already know
   this."
4. **Every block closes with an exam.** The `STAGE-EXAM.md` at the end of the
   block (in the block's folder) is the gate: the command runs, the output is
   correct, the reasoning is written down.

And the unchanging rule: **every lab runs locally first, without spending money.**
You only touch the cloud after Block C, and only with a mandatory budget alarm —
[`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md).

---

## 🚫 Anti-pattern table
| Anti-pattern | Why it's bad | Right |
|---|---|---|
| Pasting a command from the internet without understanding it | `sudo`/`rm`/`\| bash` can do irreversible damage to your machine | Get to know every part with `--help`/`man` before running it |
| Doing daily work at the root (`#`) prompt | One wrong command can take down the whole system | Normal user (`$`), a single `sudo` only when needed |
| Retrying without reading the error message | The error is often the solution itself | Read the last line, search for the part you don't understand verbatim |
| Trying to memorize commands | That's what `man`/`--help` are for, not human memory | Make finding help fast a habit |
| Typing every character by hand | Typos + wasted time | `Tab` completion + `↑` history |
| Forcing yourself to learn `vim` because it's the "real editor" | The learning curve gets in the way of the actual work | Start with `nano`, save `vim` for later |
| Jumping to A1 before your environment is ready | You have nowhere to run commands, every step stalls | Get `uname -a`/`whoami` working first, then A1 |
| Running a command with curly/smart quotes | The shell doesn't recognize `"` `"`, the command breaks | Use straight `"`/`'`, type it by hand when in doubt |

## ✅ Acceptance criteria
Don't move to A1 until all of these are verified:
- [ ] You opened a Linux terminal on your own machine; you pasted the output of `uname -a` and `whoami` into `report.txt` (or your progress file). `whoami` shows a normal user, not root.
- [ ] You navigated between at least two directories with `pwd`, `ls`, `cd <directory>`, `cd ..`; you read a file's contents with `cat` (or `less`) and exited `less` with `q`.
- [ ] You created a file with `nano` (or an editor), wrote a line into it, and saved it; you showed the content was correct with `cat <file>`.
- [ ] You opened `man ls` alongside `ls --help` (exited `man` with `q`) and **wrote** the difference between the two in one sentence.
- [ ] You copied `PROGRESS-TEMPLATE.md` for yourself and marked A0 as complete.

## 🧪 Test yourself
1. You see `#` instead of `$` at the end of the prompt. What does this mean, and why should you be more careful?
2. **Scenario:** You ran a command and the terminal said `command not found`. Without looking at documentation, what are your first two checks?
3. **Design:** An installation page online tells you to run `curl <URL> | sudo bash` in a single line. What do you do before running it, and why?

<details><summary>Answers</summary>

1. The `#` prompt shows you're **root** (a fully privileged user); `$` is a normal user. Root crosses every permission boundary, so a wrong command (deleting, overwriting) can do irreversible damage. Do daily work at `$`, and elevate only when needed with a single `sudo` — that's how you narrow the blast radius of a compromised or mistaken command.

2. **(a)** Check the spelling — most "command not found" errors are a single typo; try `Tab` completion. **(b)** Is the command actually installed: if `type <command>` / `which <command>` returns nothing, the program isn't installed → install it with your package manager (`sudo apt install <package>`). What `PATH` is and why a command goes "not found" goes deeper in A1.

3. I don't **run it blindly.** `| sudo bash` means "run whatever this URL returns, as root" — it demands full trust in the source. First I capture `curl <URL>`'s output (without `| bash`) to a file/screen and **read it**; I understand what it does line by line with `--help`/`man`; I make sure the source is trustworthy. Only then do I run it. This is the path's "don't run it without understanding it" rule, applied for the first time.

</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| Terminal/WSL2 won't open at all | Local Linux isn't set up | [`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md) → 🐧 "Bring up a local Linux" |
| `command not found` | Command isn't installed, or was typed wrong | `type <command>`; if missing, `sudo apt install <package>` |
| `man` opened, I can't get out | Stuck in the `man`/`less` pager | The `q` key (quit) |
| Can't exit `nano` | Don't know the save/exit keys | `Ctrl-X`; `Y` to the save prompt, `Enter` for the filename |
| The command I copied keeps erroring | Curly (smart) quotes | Type the quote by hand as a straight `"`/`'` |
| Command is hanging, prompt won't return | Command isn't finishing / waiting for input | `Ctrl-C` (interrupt) or `Ctrl-D` (input ended) |

## 💼 Portfolio output
There's no direct portfolio output here; this is a foundational skill. But the
environment you set up **is the prerequisite for every lab that follows** — you'll
run every command from A1 to F5 right here.

## ⏭️ Up next
[`A1 — Linux Fundamentals: Process, Filesystem, Permissions, User/Group`](A1-linux-temeli.md)

---

> *"The terminal isn't an empty screen; it's the first language you speak with the system. This module is that language's alphabet."*
