---
description: "First broken lab: find and prove the fault on a deliberately-broken VM system using logs and metrics."
level: B
module: B3
estimated_hours: 12
prerequisites: [B1, B2]
tags: [Learning Path, Debugging]
---
# B3 — First Broken Lab

> *"A tutorial says 'set this up'; a broken lab says 'fix this.' The second one grows engineers."*

**Block:** B — Visibility · **Duration:** ~12h · **Prerequisite:** [`B1`](B1-log-okuma.md), [`B2`](B2-metrik-prometheus.md)

## 🎯 When you finish this module
- Without being told what broke, you'll narrow down a fault systematically, starting only from the symptom.
- You'll **prove** your hypothesis with logs and metrics, not guesswork.
- You'll write up the path to root cause so someone else can follow it.

## 🧠 Why this, why now
The broken lab is the backbone of the path from B3 onward. Until now you've always
**built**; building is a skill, but the real engineering is being able to **bring back**
something you didn't build when it breaks. Before moving to Block C (adding
complexity — container, CI, Terraform), you need to show that you can see the system
you built (B1/B2) and prove a fault. **This module is the exam for the B → C
transition signal:** *"Can you narrow down why a service won't come up, in three
commands, without opening a doc?"*

## 📖 How to study this
K01 broken lab's `README.md` tells you **only the symptom** ("the service isn't
responding"). It doesn't say what broke — saying so would kill the whole lesson.
**Don't open** the `hints/` folder early: narrow it down yourself first. When you get
stuck, go in order: `hint-1` (direction) → `hint-2` (narrow down) → `hint-3` (almost
the answer). While solving, keep a `teshis.md` — write down what you observed and what
you concluded at each step. That file is the real output of this module.

## 📚 Concept map
| Term | In one sentence |
|---|---|
| **Symptom** | The observed wrong behavior ("returns 502") — not the cause |
| **Root cause** | The actual reason producing the symptom ("wrong DB password") |
| **Hypothesis** | A testable guess about the cause |
| **Evidence** | Concrete output that confirms/refutes a hypothesis (a log line, a metric) |
| **Bisection (narrowing down)** | Splitting the system into layers to halve the fault's location |
| **USE method** | Utilization / Saturation / Errors — a resource-bottleneck scan |

---

## 1️⃣ Tutorial vs broken lab: why this difference is everything

A tutorial shows the happy path: follow the steps, it works. But in production the
steps don't wait for you; you run into a broken, half-done, contradictory state and
**nobody tells you what broke.** The broken lab simulates that reality. What it teaches
isn't a command, it's an **attitude**: method instead of panic.

## 2️⃣ Diagnostic discipline: symptom → hypothesis → evidence → fix

Solving a fault isn't improvisation — it's a small scientific method:

```
1. Clarify the symptom   → "What exactly is wrong? When did it start?"
2. Form a hypothesis     → "I think it can't connect to the DB."
3. Gather evidence       → does journalctl show 'connection refused to :5432'?
4. Does the evidence support the hypothesis?
     yes → fix it, then VERIFY (is the symptom gone?)
     no  → new hypothesis, back to step 2
```

The critical part is step 3: **prove every hypothesis with an output.** "It's probably
the DB" isn't a diagnosis, it's a guess; you'll fix the wrong spot on it and burn hours.
B1 (logs) and B2 (metrics) existed exactly to supply this evidence.

## 3️⃣ Narrowing down: split the system into layers

Recall the architecture you built in A6 — the fault is in one link of this chain:

```
browser → nginx → application → database
                    ↑ underneath: OS (permissions, disk, port, DNS, clock)
```

Test each layer one by one, **halving** the fault's location:

```bash
curl -s http://127.0.0.1/health        # via nginx — working?
curl -s http://127.0.0.1:<APP_PORT>/health   # direct to app — working?
psql "postgresql://.../appdb" -c "SELECT 1;" # DB — connecting?
```

If `curl 127.0.0.1/health` fails but `curl :<APP_PORT>/health` works → the problem is
**between** nginx and the application (proxy config, port). If both fail → it's in the
application or below it. Each pair of commands halves the search space — you get to
root cause in four commands.

## 4️⃣ The three-command reflex (A → B transition signal)

When a service won't come up, the first three commands you run without opening a doc:

```bash
systemctl status <service>              # 1) is it running, failed, what does it say
journalctl -u <service> -e -p err       # 2) why it exited — recent errors (B1)
ss -tlnp | grep <PORT>                  # 3) is the port actually listening (A2)
```

Add a resource check on top: `df -h` (is disk full — a very common root cause) and
`free -h` (memory). This reflex is the transition signal itself — it should come
automatically, in order, without thinking.

## 5️⃣ Resource bottlenecks: the USE method

If a system is "slow" or "stalling," look at **resources**, not individual services.
The USE method asks three questions per resource:

| | Question | Command |
|---|---|---|
| **U**tilization | How busy is it? | `top`, `mpstat` |
| **S**aturation | Is there a queue/wait? | `uptime` (load), `vmstat` |
| **E**rrors | Is an error counter climbing? | `dmesg`, `journalctl -p err` |

> `mpstat`/`vmstat`/`dmesg` may be new — don't go deep on them for now; `top`, `uptime`,
> and `journalctl -k` (= `dmesg`) are enough. Detail is in the cheatsheet deep-dive below.

Depth (Brendan Gregg's USE method, the 60-second checklist):
[`16-Cheatsheets/linux-troubleshooting.md`](../../16-Cheatsheets/linux-troubleshooting.md).
This cheatsheet is now **readable for you** — you finished A1–A6 and B1–B2; a doc that
was a "wall" at the start is now a tool in your kit.

## 6️⃣ Common root-cause classes

The breakage in the broken labs is realistic. The most common classes:

| Class | Symptom | First check |
|---|---|---|
| **Permission** (permission denied) | Service can't reach a file/port | `ls -l`, `journalctl` (A1 permission model) |
| **Port conflict** | `Address already in use` | `ss -tlnp \| grep <PORT>` |
| **Disk full** | Write errors, service crashes | `df -h`, `df -i` (inode) |
| **DNS** | "name not resolved", timeout | `dig`, `/etc/resolv.conf` (A3) |
| **systemd unit** | `failed`, wrong `ExecStart`/path | `systemctl status`, unit file (A6) |
| **Clock drift** | TLS/certificate/auth errors | `timedatectl`, NTP |
| **Wrong config** | Service starts, behaves wrong | Config diff, `nginx -t` |

> 🔒 `permission denied` is a **security boundary**, not an annoying obstacle. "Fixing"
> it with `chmod 777` or by running the service as `root` doesn't close the fault, it
> opens a hole — exactly the mistake this repo criticizes throughout. The right fix:
> understand **which user needs access to which resource and why**, and grant the
> narrowest permission (A1/A6 least-privilege).

## 7️⃣ Writing the diagnostic flow

Finding the root cause is half the job; **writing it down** is the other half. A good
diagnostic note contains:

- **Symptom** — what you observed (with the full output).
- **Narrowing steps** — which hypothesis you eliminated with which evidence.
- **Root cause** — the actual reason.
- **Fix** — what you did, and how you verified the symptom was gone.
- **Why it happened / how to prevent it next time** — for the next person.

This structure isn't a coincidence; it's the core of the **blameless postmortem** in
E3. What you write here for a solo lab is a draft of the document you'll write there
for a team.

## 8️⃣ Hint discipline: rescuing yourself early

Hints aren't a failure, they're a calibrated safety net. But **opening them early**
steals the lesson. Rule: don't open a hint before you've tested a hypothesis with
evidence. Order:

- `hint-1` → direction ("look at this layer").
- `hint-2` → narrow down ("pay attention to the output of this command").
- `hint-3` → almost the answer.

If you opened `hint-3`, that's fine — but afterward read `solution.md` and separately
study **the diagnostic flow** (not the answer, but how you get there). That flow is
what's actually being taught.

## 9️⃣ A diagnosis start to finish: the method at work

Don't leave the method abstract — walk it end to end once. (This example
**deliberately doesn't match K01's hidden cause**; the goal is to show the flow, not
give the answer.) Here's the symptom: *"The app comes up but during checkout it logs
`name resolution failed` and the request drops."*

**1) Clarify the symptom.** When did it start, always or intermittently?

```bash
journalctl -u app --since "30 min ago" -p err     # B1
# 11:02:14 app: ERROR calling payments: dial tcp: lookup api.payments.local: name resolution failed
```

The error says **DNS** (A3). Hypothesis: the app can't resolve the name
`api.payments.local`.

**2) Split the layer — is the problem in the app or the system's DNS?** Take the app
out of the equation, try resolving the name directly:

```bash
dig +short api.payments.local      # returns empty → the system can't resolve it either (app is innocent)
dig +short google.com              # this is empty too → DNS is completely broken, not just this name
```

Two commands halved the search space: the problem isn't in the app, it's in **the
machine's DNS resolution**. Digging further into the app's log would have wasted time.

**3) Get to root cause — why is DNS broken?**

```bash
cat /etc/resolv.conf               # which resolver? (A3) — e.g. empty or an unreachable IP
ss -u -a | grep :53                # is DNS traffic going out (A2)
ping -c1 <RESOLVER_IP>             # is there network to the resolver
```

If `ping` to the resolver in `resolv.conf` fails, the root cause is **network/resolver
access**; if the resolver is correct but not responding, it's the **resolver service**.
Every step eliminated one hypothesis with one output — no guessing.

**4) Fix it, then VERIFY.** After fixing the resolver, don't say "fixed it" — **prove
the symptom is gone**, from the outermost point (where the user sees it):

```bash
dig +short api.payments.local      # now returns an IP
curl -s http://127.0.0.1/checkout  # 200 — the user path works
journalctl -u app --since "2 min ago" -p err   # empty → no new errors
```

The whole flow boils down to four questions: *What's wrong? In which layer? Why?
Actually fixed?* That's exactly what you need to do in the broken lab — only the cause
differs each time.

## 🔟 Time-box, side effects, and when to stop

Three more disciplines matter as much as the method itself; they're a rehearsal for
the incident work in Block E:

- **Time-box.** Don't get stuck on one hypothesis. Say "if I can't try and prove this
  path in 15 minutes, I'll go back and switch layers." In the broken lab, this is the
  threshold for opening a hint; in a real incident, it's the escalation threshold.
- **Watch for side effects.** A fix can create a **new** fault (you changed a config,
  something else broke). After fixing, verify the **whole** system, not just the one
  symptom: `systemctl status`, a few end-to-end `curl`s, `journalctl -p err`.
- **When to stop and ask for help.** Being stuck isn't a failure; being stuck
  **silently for hours** is. In the broken lab the order is `hint-1 → 2 → 3 →
  solution.md`. In real life the order is: write up what you've proven (symptom +
  what you tried + what you eliminated) and **escalate** — the core of the on-call
  discipline you'll see in E2/E3. You escalate with "**what I've proven**," not "what
  I haven't tried."

> 🔒 The most common mistake under pressure is skipping diagnosis for a "quick fix":
> `chmod 777`, run the service as `root`, disable a security check. This closes the
> fault by opening a **hole** (A1/A6). The time-box exists exactly to prevent this —
> haste makes security the first thing sacrificed.

---

## 🚫 Anti-pattern table
| Anti-pattern | Why it's bad | Right |
|---|---|---|
| Attaching the symptom to an unproven cause | Fixes the wrong spot, wastes hours | Prove every hypothesis with log/metric |
| Random "let me also try this" | Untraceable, unreproducible, creates new faults | Narrow down layer by layer (bisection) |
| Getting past `permission denied` with `chmod 777` | Closes the fault, opens a security hole | Right user + narrowest permission (A1/A6) |
| Opening a hint at the first snag | Skips exercising the diagnostic muscle | Try the three-command reflex + one hypothesis first |
| Fixing without verifying | The symptom may still be there | Prove the symptom is gone after the fix |
| Fixing the symptom instead of the root cause | Restarting the service brings the fault back | Find the actual cause; restart is deferral, not a fix |
| Not writing up the diagnosis | Starts from zero next time; the team doesn't learn | Keep a `teshis.md` (seed of the E3 postmortem) |
| Working from guesswork alone | "Probably the DB" ≠ diagnosis | Evidence = the B → C transition itself |
| Stuck on one hypothesis for hours | Wasted time, tunnel vision | Set a time-box; switch layers when it runs out |
| Checking only the one symptom after a fix | A side effect may have created a new fault | Verify the whole (`status`, end-to-end `curl`, `-p err`) |
| Escalating with "what I haven't tried" | The other side starts from zero | Escalate with "what I've **proven**" (E2/E3) |

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`16-Cheatsheets/linux-troubleshooting.md`](../../16-Cheatsheets/linux-troubleshooting.md) | USE method + 60-second checklist — diagnostic framework | ~25 min |

## 💥 Broken lab
👉 [`labs/broken/K01-kirik-vm/`](../labs/broken/K01-kirik-vm/) — Symptom: "The service
won't come up / isn't responding." The realistic cause is hidden (wrong permission /
port conflict / disk full / systemd unit error). `README.md` **never** says what
broke — it gives only the symptom.

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] You solved K01: `bash labs/broken/K01-kirik-vm/verify.sh` passes with zero errors.
- [ ] You wrote a `teshis.md` showing the root cause with log/metric **evidence** (symptom → narrowing → root cause → fix → verification).
- [ ] You **wrote up** the answer to "which three commands, without opening a doc, did you narrow down with" — with the commands and their reasons (A → B signal).
- [ ] You proved with a separate command that the symptom was **gone** after the fix (not just claimed "fixed it").

## 🧪 Test yourself
1. What's the difference between "symptom" and "root cause"? Which one is "returns 502"?
2. **Scenario:** `curl 127.0.0.1/health` → 502. Which command do you run first to bisect the system toward root cause, and what do the two possible outcomes mean?
3. **Design:** You fixed a fault but never fully understood why it happened; restarting the service fixed it. Is the job done? Why?

<details><summary>Answers</summary>

1. Symptom = the observed wrong behavior; root cause = the actual reason producing it. "Returns 502" is a **symptom** — it means nginx can't reach the backend app, but *why* it can't (app dead, wrong port, DB dropped it) is the root cause, and it still needs to be found.

2. `curl -s http://127.0.0.1:<APP_PORT>/health` — skip nginx and go **straight to the app**. (a) If it works: the app is fine, the problem is between nginx and the app (proxy config/port) → narrow the search there. (b) If this also fails: the problem is in the app or below it (DB, permission, systemd) → eliminate nginx, dig into the app's log. One command halved the search space.

3. **No, the job isn't done.** The restart temporarily closed the symptom but the root cause is still there — the same fault will come back. Find the root cause with evidence (log/metric), apply the real fix, and write "why restart isn't enough" into `teshis.md`. Restart isn't a diagnosis, it's deferral — this distinction is the foundation of the incident discipline in Block E.

</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| I don't know where to start | The symptom isn't clarified | Write "what exactly is wrong?"; apply the three-command reflex |
| Everything looks normal | You're looking at the wrong layer | Switch layers (nginx→app→DB→OS); `df -h`/`free -h` |
| My hypothesis didn't hold | Natural — part of the elimination process | Form a new hypothesis, go back to step 2; test it with evidence |
| I fixed it but it came back | The symptom was fixed, not the root cause | Find the actual cause; restart isn't deferral-proof |
| I'm blocked, can't move forward | The diagnostic muscle is still developing | `hints/` in order: hint-1 → 2 → 3; then study the flow in `solution.md` |

## 💼 Portfolio output
The `teshis.md` you wrote — the first page of an "incident log." It evolves into a
blameless postmortem in E3; documents like this are the concrete evidence that you can
say "I solved a real fault with method."

## ⏭️ Up next
[`C0 — Ops for Python`](../block-c-reproducibility/C0-ops-python.md)

---

> *"Being able to narrow down a fault without help is the real skill this path teaches."*
