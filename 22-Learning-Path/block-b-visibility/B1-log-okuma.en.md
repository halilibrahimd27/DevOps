---
description: "Reading logs: journalctl, structured logging, and what to log vs. not log — you can't manage a system you can't see."
level: B
module: B1
estimated_hours: 12
prerequisites: [A6]
tags: [Learning Path, Observability]
---
# B1 — Reading Logs: journalctl, Structured Logging

> *"You can't manage a system you can't see. The log is the first story the system tells you."*

**Block:** B — Visibility · **Duration:** ~12h · **Prerequisite:** [`A6`](../block-a-intuition/A6-elle-deploy.md)

## 🎯 When you finish this module
- You filter a service's logs with `journalctl` by time, service, and severity.
- You explain the difference between structured logs and plain-text logs, and why it matters.
- You decide — and justify — what must be logged and what (secrets/PII) must **never** be logged.

## 🧠 Why this, why now
The service you built in A6 will break — that's inevitable. To see it break, you first
need to know how to read its logs; in A6's final step you saw a 502 narrowed down through
the log, and now we turn that into a discipline. B2's metrics tell you "how much / how
often"; the log tells you "exactly what happened" at single-event resolution. B3's first
broken lab is built on this skill: someone who can't read a log guesses at the failure.

## 📖 How to study this
Work on your A6 VM. Deliberately break your application a few times (wrong DB password,
closed port), and each time **check the log first**, then fix it. Turn log-reading into a
reflex: "something's wrong → `journalctl` first."

## 📚 Concept map
| Term | In one sentence |
|---|---|
| **journald** | systemd's central log collector; keeps all service logs in one place |
| **`journalctl`** | your tool for querying journald |
| **Log level** | `emerg`…`debug` — how urgent the event is |
| **Structured log** | log in key-value/JSON form — machines can read it, not just humans |
| **Correlation ID** | an identifier that lets you trace a request across all services |
| **PII** | personal data (name, email, national ID) — the class that must never enter a log |
| **Log rotation** | rotating out and deleting old logs; prevents the disk from filling up |

---

## 1️⃣ journalctl: four filters

You saw `journalctl -u app` in A6. The real work is **narrowing** this log — during an
incident you read the relevant line, not a million of them:

```bash
journalctl -u app -e                      # only the 'app' service, jump to the end (newest)
journalctl -u app -f                       # live follow (fire a request, watch it)
journalctl -u app --since "10 min ago"     # time window
journalctl -u app -p err                   # only 'err' and more urgent (priority filter)
journalctl -u app --since today -p warning..err   # today, warning–err range
```

Combine these four: "what happened in the app service, at error level, in the last 10
minutes?" becomes one command — the number of lines you end up reading drops to under a
hundred.

## 2️⃣ Severity levels: not every line is equal

Syslog levels (from urgent to verbose):

| Level | What it means | Example |
|---|---|---|
| `emerg`/`alert`/`crit` | System unusable / needs immediate action | Disk full, service crashed entirely |
| `err` | An operation failed | DB connection refused |
| `warning` | Not a problem, but worth watching | Retry, slowdown |
| `notice`/`info` | Normal, notable events | "Service started", "request processed" |
| `debug` | Detailed development trace | Variable values |

During an incident, start with `-p err`; if nothing turns up, widen to `-p warning`. In
production, `debug` must be **off** — noise buries the signal and fills the disk.

## 3️⃣ Plain text or structured

Compare two log lines:

```
# plain text — a human can read it, a machine struggles
2026-07-21 10:03:12 User login failed, retrying

# structured (JSON) — both human and machine can read it
{"ts":"2026-07-21T10:03:12Z","level":"warn","event":"login_failed","user_id":"u_123","attempt":2,"request_id":"r_abc"}
```

Plain text is pleasant for a human but **can't be filtered**: you can't say "count
failed logins by user." In a structured log every field is queryable; the log systems
you'll set up after C1 (Loki, ELK) build their filters and dashboards exactly on these
fields.

> Rule: write application logs as structured (JSON). Every line needs at least:
> timestamp, level, event name, and a `request_id`/`correlation_id` to trace the
> request. This id is the only way to follow a request from service to service
> (tracing, later).

## 4️⃣ What to log

A good log line answers one question: *"What happened, for whom/what, and with what
result?"*

- **Events** — service started/stopped, a deploy happened, config changed.
- **Decisions and outcomes** — "request rejected (unauthorized)", "retry 3/3".
- **Identity (as a reference)** — a **pseudonymous** id like `user_id: u_123`, never the name/email itself.
- **Correlation** — `request_id`, so you can collect the full trace of a request.

## 5️⃣ What NOT to log — the red line

> 🔒 The log is a leak vector. Log files usually flow to a central location, get backed
> up, are retained long-term, and many people can access them. The following **never**
> go into a log: password, token, API key, session cookie, credit card number,
> authentication header (`Authorization:`), and raw PII (full name, email, national ID
> number, phone).

```
# ❌ disaster
{"event":"login","user":"ayse@example.com","password":"S3cret!","token":"eyJhbGci..."}

# ✅ safe
{"event":"login","user_id":"u_123","result":"success","request_id":"r_abc"}
```

> 🇹🇷 **KVKK note:** Writing personal data into a log is a data **processing** activity,
> and it requires a purpose, a retention period, and access restrictions. The cleanest
> solution is to **never log it at all**: use a pseudonymous `user_id` instead of the
> real email, and resolve identity in a separate, access-restricted system when you
> need to. "What goes into a log" is as much a compliance decision as an engineering one
> (see [`19-Compliance/KVKK-Practical.md`](../../19-Compliance/KVKK-Practical.md)).

## 6️⃣ Disk filling up: the log's physical limit

Logs aren't infinite; the disk they're written to fills up, and **a full disk is a
cause of outages** (one of the classic root causes of broken systems — you'll run into
it again in later blocks). See how much space journald is using and cap it:

```bash
journalctl --disk-usage                    # how much space journald is using
sudo journalctl --vacuum-time=7d           # discard logs older than 7 days
df -h /var/log                             # how full the log disk is (A1)
```

Set up rotation (rotate + compress + delete) for application logs too — otherwise
`/var/log` fills up, the service can't write, and the system stumbles. Set this up by
hand once so you know exactly what the automation handles for you in C and D.

## 7️⃣ Narrowing an incident with logs — in practice

Generalize A6's 502 example. The log-reading flow during an incident:

```bash
journalctl -u app --since "15 min ago" -p err   # 1) is there an error, when did it start
journalctl -u app -e                             # 2) the context around that error
sudo tail -50 /var/log/nginx/error.log           # 3) what's the proxy side saying
df -h; journalctl --disk-usage                    # 4) is it an infra limit (disk?)
```

At every step, form a **hypothesis** and **prove it** with the log — don't guess. Not
"it's probably the DB," but "the log says `connection refused to :5432`, so it's the
DB." This distinction (evidence vs. guessing) is the B → C transition signal, and it's
tested in B3.

## 8️⃣ Where the application logs to

To find a service's log, you first need to know **where it writes to**. Three common
places:

| Where | How to read it | When |
|---|---|---|
| **stdout/stderr** | systemd captures it → `journalctl -u <service>` | Modern apps (12-factor) — recommended |
| **Its own file** (`/var/log/app/…`) | `tail -f`, `less` | Legacy apps; you set up rotation yourself |
| **syslog / journald** (`logger`) | `journalctl` | System services, cron |

The modern rule (12-factor app): the application **never opens a log file** itself, it
just writes to stdout/stderr; the *runtime environment* decides where that goes
(systemd → journald, container → stdout → log collector). This is why, after C1,
container logs are read with `docker logs` — the application is the same, only
something different is collecting its stdout.

`journalctl` merges multiple services onto a single timeline — during an incident,
seeing nginx and application logs **together** often unlocks the answer:

```bash
journalctl -u nginx -u app --since "10 min ago"   # both in one stream, by time
```

## 9️⃣ An incident session: start to finish

A complaint comes in that your A6 service "is returning 500s." Let's solve it with
logs, without guessing:

```bash
# 1) Match the symptom to a time: when, at what level?
journalctl -u app --since "20 min ago" -p err
# Jul 21 10:31:02 app[812]: ERROR db connect failed: password authentication failed
```

```bash
# 2) See the context: what happened right before this?
journalctl -u app -e
# ... 10:30:58 config reloaded from /etc/app.env
```

Chain of evidence: the error started at `10:31:02`, and right before it (`10:30:58`)
the config was reloaded → someone changed `/etc/app.env` and the DB password is now
wrong. The hypothesis is no longer a guess — it's **proven by two log lines**. Verify
it:

```bash
# 3) Test the DB directly (bypass the app) — B's narrowing reflex
psql "postgresql://appuser:<DB_PASSWORD>@127.0.0.1:5432/appdb" -c "SELECT 1;"
# FATAL: password authentication failed for user "appuser"   → confirmed
```

Fix it (correct the password in `/etc/app.env`, `systemctl restart app`), then **prove
the symptom is gone** — don't just say "I fixed it":

```bash
curl -s http://127.0.0.1/health          # 200 ok
journalctl -u app --since "1 min ago" -p err   # empty → no new errors
```

This flow — symptom → log → evidence → fix → verify — is the core of B3's broken lab
and E3's postmortem. The only difference is scale.

## 🔟 journalctl in depth: format, fields, boot

The four filters (`-u`, `--since`, `-p`, `-f`) get the job done, but there are three
more things that really speed you up during an incident: **output format**, **field
filtering**, and the **boot boundary**.

### Change the output format
Reading the same log in a different format unlocks different questions:

```bash
journalctl -u app -o short-iso        # UTC/ISO timestamp (for correlation — B2)
journalctl -u app -o json-pretty      # see all the fields (the raw structured log)
journalctl -u app -o cat              # message only, no metadata — for a quick scan
```

`-o json-pretty` shows you which fields a log line *actually* carries in journald
(`_PID`, `_SYSTEMD_UNIT`, `_HOSTNAME`, `PRIORITY`…). These fields are filterable —
that's where the real power is.

### Filtering by field: sharper than `-u`
`-u` filters by service; but sometimes you need "just this one process" or "just this
user":

```bash
journalctl _PID=812                    # only output from process number 812
journalctl _UID=1000                   # services belonging to a specific user (A1 UID)
journalctl _SYSTEMD_UNIT=app.service PRIORITY=3   # app + only 'err' (3=err)
```

Field filters combine with **AND** logic. During an incident, "what errors did process
812 throw today?" is expressed in one line — you read ten lines instead of a million.

### Boot and kernel: know where to look
If the system restarted, "was the error before or after the restart?" is the critical
question:

```bash
journalctl -b                          # only since THIS boot (after the restart)
journalctl -b -1                       # the PREVIOUS boot (log from before the crash)
journalctl --list-boots                # boot history + ids
journalctl -k                          # kernel messages only = dmesg
```

`-b -1` is invaluable when investigating a crash: if the system went down hard, you can
only see the log from **right before the crash** by looking at the previous boot. `-k`
isolates kernel-level issues — OOM killer, disk I/O errors, hardware warnings —
journald's counterpart to the standalone `dmesg` command (kernel ring-buffer messages).

## 1️⃣1️⃣ Is the log persistent or volatile — and why it disappears

On a fresh system, `journalctl -b -1` often comes back **empty**. The reason isn't a
bug, it's a **configuration**: by default journald writes the log to memory/`/run`
(volatile), and it gets **wiped** on every restart. Making it persistent requires a
directory on disk:

```bash
journalctl --list-boots                # if it returns a single line, the log is NOT persistent
ls /var/log/journal 2>/dev/null || echo "no persistent journal"
sudo mkdir -p /var/log/journal && sudo systemd-tmpfiles --create --prefix /var/log/journal
# systemd-tmpfiles: applies the directory's correct owner/permissions per systemd's rules
sudo systemctl restart systemd-journald   # now the log survives across restarts
```

> Set this up *before* an incident. If the crashed system's log wasn't written to disk
> before it crashed, it's gone; by the time you say "let's check the log," there's
> nothing left to look at. A persistent journal is a prerequisite for diagnosis.

There's also **rate limiting**: if too many lines arrive per second, journald **drops**
some of them and writes `Suppressed N messages`. If a service is flooding the log
(noise), you lose signal, and a genuinely important line can get dropped too:

```bash
journalctl -u app | grep -i "suppressed"   # was the log dropped?
```

The fix isn't raising the line limit, it's **logging less/more meaningfully** (§2,
severity levels): `debug` off in production, one summary line per request. This is the
infrastructure-side proof of the "don't log everything" principle (closing line).

---

## 🚫 Anti-pattern table
| Anti-pattern | Why it's bad | Right |
|---|---|---|
| Writing secrets/PII/tokens to the log | Persistent, distributed leak; KVKK violation | Log a pseudonymous id; never write the secret |
| Logging everything at `debug` level | Noise buries the signal, disk fills up | `info`+ in production; `debug` off |
| Plain-text, unfilterable logs | "Count by user" is impossible | Structured (JSON) + `request_id` |
| Not setting up log rotation | `/var/log` fills up, service can't write | `journalctl --vacuum` + application rotation |
| Eyeballing the entire log during an incident | Wastes time, drowns in irrelevant lines | Narrow with `-u` + `--since` + `-p` |
| Accepting a hypothesis without evidence | You fix the wrong thing and waste time | Verify every hypothesis with a log line |
| Writing timestamps as local/unformatted | Cross-system correlation breaks | UTC + ISO-8601 (`...T10:03:12Z`) |
| Treating the log as the single source of truth | You can't see trends/rates | Log (event) + metric (trend) together — B2 |
| Not setting up a persistent journal | `-b -1` is empty after a crash; no evidence | Create `/var/log/journal`, restart journald |
| Ignoring log suppression | `Suppressed N messages` = lost signal | Log less/more meaningfully; `debug` off |

## 📖 Further reading (not now, later)
| Source | For what | When |
|---|---|---|
| [`07-Observability/Logs-Loki-vs-ELK.md`](../../07-Observability/Logs-Loki-vs-ELK.md) | Centralized log stack (Loki/ELK) — logs across multiple machines | **After C1** — once containers arrive |
| [`19-Compliance/KVKK-Practical.md`](../../19-Compliance/KVKK-Practical.md) | The compliance dimension of PII in logs | At curiosity level, before F2 (compliance) |

## 🔨 Lab
👉 [`labs/build/L07-log-okuma/`](../labs/build/L07-log-okuma/README.md) — (Task sketch: break your
A6 app in three different ways, find each one using only `journalctl` filters; also
deliberately write a log line that leaks a secret and then make it safe.)

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] You filtered a service's recent errors with `journalctl -u <service> --since "..." -p err` and showed the output.
- [ ] You traced an event (e.g., a failed request) down to a single log line, with its timestamp.
- [ ] You converted a plain-text log line into structured (JSON) form and showed which fields became queryable.
- [ ] You answered, **in writing**, "which fields must not go into the log and why," with at least one secret example and one PII example.

## 🧪 Test yourself
1. What's the difference between `journalctl -u app -p err` and `journalctl -u app`, and which one do you run **first** during an incident?
2. **Scenario:** A user says "I got an error 3 hours ago." You know the service and roughly when. What single command do you write to find the relevant log?
3. **Design:** You're about to log a login event. Which fields do you write, which do you **absolutely never** write, and why?

<details><summary>Answers</summary>

1. `-p err` shows only `err` and more urgent lines; without `-p`, it dumps everything (including info/debug). You start an incident with **`-p err` first** — it cuts the noise and quickly shows "what blew up"; if it's empty, you widen to `-p warning`.

2. Something like `journalctl -u app --since "3 hours ago" --until "2 hours ago" -p warning` — combine the service (`-u`), the time window (`--since/--until`), and the severity filter (`-p`). That way you read a handful of relevant lines instead of a million.

3. **I write:** timestamp (UTC/ISO), `level`, `event: login`, `result: success/failed`, a pseudonymous `user_id`, `request_id`, rough geography/client type (if needed). **I don't write:** password, token/session cookie, `Authorization` header, raw email/full name/national ID number. Why: a leaked secret hands over the whole account; logging PII is an unnecessary processing activity under KVKK and a leak risk. A pseudonymous id gives you enough traceability without carrying the risk.

</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| `journalctl -u app` is empty | Wrong service name / no logs at all | Find the exact name with `systemctl list-units \| grep app` |
| Too many lines, drowning | No filter applied | Narrow with `-u` + `--since` + `-p err` |
| `-f` is live but nothing streams | No requests coming in / app is silent | Fire a `curl` from another terminal, check again |
| Disk-full warning | No log rotation | `journalctl --vacuum-time=7d`; `df -h` |
| I saw a password in the log | The app is logging secrets | Fix the logging in the app; **rotate the leaked secret** |
| Timestamps don't line up | Local time / clock drift | Switch to UTC; check NTP (clock-sync protocol) status |

## 💼 Portfolio output
Not a direct artifact; a diagnostic habit. It will show up in the "incident logs" you
write in B3's broken lab and in the incident work in Block E.

## ⏭️ Up next
[`B2 — Metrics`](B2-metrik-prometheus.md)

---

> *"Logging everything is also a form of blindness: noise buries the signal."*
