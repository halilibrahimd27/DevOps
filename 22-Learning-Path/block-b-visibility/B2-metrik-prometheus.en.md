---
description: "Metrics: Prometheus basics, what to measure, and cardinality — keeping a system's pulse in numbers."
level: B
module: B2
estimated_hours: 12
prerequisites: [A6, B1]
tags: [Learning Path, Observability]
---
# B2 — Metrics: Prometheus Basics, Cardinality

> *"A log tells you about an event; a metric shows you a trend. Without both, you're guessing."*

**Block:** B — Visibility · **Duration:** ~12h · **Prerequisite:** [`A6`](../block-a-intuition/A6-elle-deploy.md), [`B1`](B1-log-okuma.md)

## 🎯 When you finish this module
- You'll run an exporter on the A6 VM and show how Prometheus collects metrics by **pulling** (pull) them.
- You'll write your first PromQL query and read a system's basic health indicators (CPU, memory, request rate).
- You'll explain why cardinality is a cost and a risk, and which labels to avoid.

## 🧠 Why this, why now
In B1 you saw a single **event**: "this request just failed". But you can't answer "did
the error rate go up in the last hour?" by reading logs one by one — that's a **trend**,
and trends are a metric's job. The SLOs in E1 (error budgets, latency targets) are built
directly on top of these metrics; you can't put an SLO on something you don't measure.
This module runs **before containers**, on the A6 VM; the K8s-based Prometheus setup is
in Block D.

## 📖 How to study this
Set up node_exporter + Prometheus by hand on the A6 VM, open the Prometheus UI in a
browser, and try the queries there. **See** every metric: `up`, `node_cpu_seconds_total`.
Read the cardinality depth in
[`Prometheus-Best-Practices.md`](../../07-Observability/Prometheus-Best-Practices.md) —
this module gets you to the level where you can read it; it doesn't repeat it.

## 📚 Concept map
| Term | In one sentence |
|---|---|
| **Metric** | A numeric measurement that changes over time (CPU %, request count, latency) |
| **Pull model** | Prometheus **pulls** data from targets' `/metrics` endpoint (the app doesn't push) |
| **Exporter** | A tool that exposes a system's state in a form Prometheus can read (e.g. node_exporter) |
| **Label** | A key-value pair that dimensions a metric (e.g. `method="GET"`) |
| **Cardinality** | The number of label combinations a metric has — if it explodes, it chokes Prometheus |
| **PromQL** | Prometheus's query language |
| **Counter / Gauge / Histogram** | The three basic metric types |

---

## 1️⃣ What a metric is, and how it differs from a log

A log is a record of an **event** ("request failed at 10:03:12"). A metric, on the other
hand, is a **number's value over time**: every 15 seconds, "active connections right
now: 42", "total requests: 19,204". A log answers "what just happened"; a metric answers
"what's the trend".

| | Log | Metric |
|---|---|---|
| Unit | Single event | Number spread over time |
| Question | "What exactly happened?" | "How much / how often / what's the trend?" |
| Cost | Grows with line count | Grows with series (label combination) count |
| Example | "Login failed (u_123)" | "Last 5 min login error rate: 2%" |

## 2️⃣ The pull model: Prometheus pulls, the app doesn't push

Prometheus **visits the `/metrics` endpoint of every target it watches at regular
intervals** and reads the current values (scrape). The app doesn't "send" data; it just
exposes current values on an HTTP endpoint. A raw metrics endpoint looks like this:

```
# HELP http_requests_total Total HTTP request count
# TYPE http_requests_total counter
http_requests_total{method="GET",status="200"} 1027
http_requests_total{method="GET",status="500"} 3
```

Prometheus pulls this from an address like `<VM_IP>:9100/metrics`. The "who pulls whom"
relationship is defined in `scrape_configs` in `prometheus.yml`.

## 3️⃣ Set up an exporter and collect

Set up node_exporter (machine metrics: CPU/memory/disk) on the A6 VM **as a systemd
service** — no Docker needed (that's Block C's territory):

```bash
# 1) determine version + architecture — write the current version from the official release instead of <VERSION> (no :latest)
VER=<VERSION>
case "$(uname -m)" in x86_64) ARCH=amd64;; aarch64|arm64) ARCH=arm64;; esac  # the VM's architecture (Apple Silicon → arm64)
curl -sSL -o /tmp/node_exporter.tgz \
  "https://github.com/prometheus/node_exporter/releases/download/v${VER}/node_exporter-${VER}.linux-${ARCH}.tar.gz"
tar -xzf /tmp/node_exporter.tgz -C /tmp
sudo install "/tmp/node_exporter-${VER}.linux-${ARCH}/node_exporter" /usr/local/bin/

# 2) separate service user + systemd unit (the pattern from A6)
sudo useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter
sudo tee /etc/systemd/system/node_exporter.service >/dev/null <<'UNIT'
[Unit]
Description=Prometheus Node Exporter
After=network.target
[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter --web.listen-address=127.0.0.1:9100
Restart=on-failure
[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload && sudo systemctl enable --now node_exporter
curl -s http://127.0.0.1:9100/metrics | head    # are metrics coming through? (A3 curl)
```

**Set up Prometheus itself** with the same pattern (binary + separate service user +
systemd unit) — but it differs from node_exporter in two ways: it reads a **config
file** (`prometheus.yml`) and it serves a web UI on port **9090**:

```bash
# 1) download the binary (same VER + ARCH pattern as node_exporter)
PVER=<VERSION>
curl -sSL -o /tmp/prom.tgz \
  "https://github.com/prometheus/prometheus/releases/download/v${PVER}/prometheus-${PVER}.linux-${ARCH}.tar.gz"
tar -xzf /tmp/prom.tgz -C /tmp
sudo install "/tmp/prometheus-${PVER}.linux-${ARCH}/prometheus" /usr/local/bin/

# 2) config + data dir + service user (you define the target = node_exporter here)
sudo useradd --system --no-create-home --shell /usr/sbin/nologin prometheus
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo tee /etc/prometheus/prometheus.yml >/dev/null <<'YML'
scrape_configs:
  - job_name: node
    static_configs:
      - targets: ["127.0.0.1:9100"]
YML
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

# 3) systemd unit — config file and data path are given as flags (node_exporter didn't have these)
sudo tee /etc/systemd/system/prometheus.service >/dev/null <<'UNIT'
[Unit]
Description=Prometheus
After=network.target
[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.listen-address=127.0.0.1:9090
Restart=on-failure
[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload && sudo systemctl enable --now prometheus
curl -s http://127.0.0.1:9090/-/ready    # "Prometheus is Ready." → up
```

If you want the fast path, the L08 lab also gives you the same stack with a small
`docker compose` — but you'll learn Docker in **C1**; for now, that `docker compose up
-d` is just a ready-made recipe, not the concept.

Open the Prometheus UI in a browser (`127.0.0.1:9090`), and confirm the target is `UP`
via **Status → Targets**.
The `up` metric itself is your first health indicator: `1` = target reachable, `0` = not.

## 4️⃣ The three metric types

| Type | What it does | Example |
|---|---|---|
| **Counter** | Only increases (or resets) | `http_requests_total` — total requests |
| **Gauge** | Goes up and down, instant value | `node_memory_available_bytes` — free memory |
| **Histogram** | Distributes values into buckets | `http_request_duration_seconds` — latency distribution |

Rule: if you want a thing's **rate/ratio**, use a counter (apply `rate()` on top of it);
if you want an **instant level**, use a gauge; if you want a **distribution/percentile**,
use a histogram. (p95 latency = the duration under which 95% of requests complete; it's
more honest than an average, because a few slow requests get hidden by the average but
not by p95.)

## 5️⃣ Your first PromQL queries

Try these in the Prometheus UI (Graph tab):

```promql
up                                        # which targets are up (1/0)
rate(node_cpu_seconds_total{mode="idle"}[5m])   # 5 min CPU idle rate
node_memory_MemAvailable_bytes            # instant free memory
rate(http_requests_total{status="500"}[5m])     # error rate — returns "no data" for NOW (app exporter comes in E1; see §6)
```

`rate(...[5m])` gives you a counter's per-second increase rate over the last 5 minutes —
not "total requests", but "requests per second". You read counters with `rate()` almost
always; a raw counter value (a number that keeps climbing) is meaningless on its own.

## 6️⃣ What to measure: the four golden signals

Don't try to measure everything; start a service with these four (Google SRE's "four
golden signals" — they'll turn into SLOs in E1):

| Signal | Its question | Example metric |
|---|---|---|
| **Latency** | How long does a request take? | `http_request_duration_seconds` (p95) |
| **Traffic** | How much load is there? | `rate(http_requests_total[5m])` |
| **Errors** | How much of it fails? | `rate(http_requests_total{status=~"5.."}[5m])` |
| **Saturation** | How full is the resource? | CPU/memory/disk utilization |

These four summarize a service's health at a glance. You add more later.

> ⚠️ The Latency/Traffic/Errors examples (`http_requests_total`,
> `http_request_duration_seconds`) require an **application exporter** — you'll
> instrument the app later (when setting up SLOs in E1); you're not producing this yet
> in this module. For now, practice with the **Saturation** signal (CPU/memory/disk)
> that node_exporter gives you — the L08 lab has you do exactly that.

## 7️⃣ Cardinality: a metric's hidden cost

Prometheus keeps a separate time series for every **unique label combination**.
If you put something with unbounded values into a label, the series count explodes:

```
# ❌ cardinality bomb — every user/request is a separate series
http_requests_total{user_id="u_1", request_id="r_abc", path="/x?t=1737451200"}

# ✅ bounded label set
http_requests_total{method="GET", route="/orders/:id", status="500"}
```

Values like `user_id`, `request_id`, raw URLs, timestamps, or emails —
**unbounded/high-cardinality** values — can't be labels: each one generates millions of
series and crashes Prometheus out of memory (a classic OOM). Labels must come from
**bounded, known-in-advance** sets (`method`, `status`, the `route` template). This is
the metric-side counterpart of the "don't log everything" principle (B1): resolution
isn't free.

> Depth (naming conventions, retention, recording rules, HA):
> [`Prometheus-Best-Practices.md`](../../07-Observability/Prometheus-Best-Practices.md).
> For now, one rule is enough: **don't put a high-cardinality value in a label.**

## 8️⃣ What `[5m]` means: instant vector vs range vector

In PromQL, every query returns one of two result types, and this distinction trips up
beginners the most:

| Type | What it returns | Example |
|---|---|---|
| **Instant vector** | For each series, a **single**, most-recent value | `node_memory_MemAvailable_bytes` |
| **Range vector** | For each series, the **raw points from the last N time** | `node_cpu_seconds_total[5m]` |

`[5m]` turns a metric into a range vector: "all the measurement points from the last 5
minutes". It can't be graphed on its own — it's an **array**, not a single number.
Functions like `rate()`, `increase()`, `avg_over_time()` **require a range vector** and
reduce it to a single instant value:

```promql
node_cpu_seconds_total                 # instant: a raw, ever-increasing counter (meaningless)
node_cpu_seconds_total[5m]             # range: raw points from the last 5 min (can't be graphed)
rate(node_cpu_seconds_total[5m])       # the marriage of the two: per-second increase rate ✅
```

Almost every "`expected type range vector`" / no-data error comes from this confusion:
you put a counter in without `rate()`, or gave a gauge an unnecessary `[5m]`. Rule:
**counter → always `rate(...[range])`; gauge → bare (instant).**

## 9️⃣ Follow a scrape step by step + meta-metrics

On every `scrape_interval` (e.g. 15s), Prometheus does the following, one step at a
time: fires a `GET` at the target's `/metrics` endpoint → parses the response → writes
the current value for each series **with its own timestamp**. The app is unaware of
this whole process; it just exposes current values.

Prometheus also generates **meta-metrics** about the scrape itself — these are like "an
eye watching the eye": they show the health of targets without ever touching the target:

| Meta-metric | What it tells you | Why you look at it |
|---|---|---|
| `up` | Was the target reachable (1/0) | Your first health indicator; the core of alerting (E2) |
| `scrape_duration_seconds` | How long the scrape took | If it's slowing down, the target or `/metrics` is bloating |
| `scrape_samples_scraped` | How many series came in | **Early cardinality warning** — if it suddenly balloons, see §7 |

Worked example — read the root disk's fill percentage on the A6 VM with a single query
(divide two gauges, convert to the "full" ratio with `1 -`):

```promql
100 * (1 - node_filesystem_avail_bytes{mountpoint="/"}
           / node_filesystem_size_bytes{mountpoint="/"})
```

This is the metric counterpart of `df -h` from B1: instead of a one-off command, you see
the same fact **over time** — is the disk filling slowly, or did it suddenly jump? "Disk
full" is a broken-lab root cause (B3); seeing it as a trend **before** an incident is
preventing the failure.

> **Staleness:** if a target disappears, Prometheus marks its series "stale" after ~5 min
> and the graph cuts off. When you see `up == 0`, it means the **target went down**, not
> that data is absent — don't confuse the two.

`scrape_interval` is a **tradeoff**: shortening it (e.g. 5s) gives finer resolution but
means more series-points per target → more disk/CPU. Lengthening it (e.g. 60s) is
cheaper but you'll miss a sudden spike between two measurements. 15s is reasonable to
start with; "measuring more often" isn't a reflex, it's a decision that needs
justification (the retention math is in the deep-dive).

## 🔟 (Briefly) visualization

A metric is a raw number; you see it on a dashboard (Grafana). The goal in this module
is being able to write and read the query in Prometheus; Grafana dashboards and alerting
go deeper in Block E. For now, Prometheus's own Graph UI is enough.

> 🔒 The `/metrics` endpoint content can leak. Don't put **secrets/PII into metrics or
> labels** (same rule as B1). Don't leave the metrics endpoint open to the internet; as
> in A6, keep it reachable only from `127.0.0.1`/the internal network, and put
> authentication in front of it if needed — otherwise an attacker reads your service's
> internal structure and traffic.

---

## 🚫 Anti-pattern table
| Anti-pattern | Why it's bad | Right |
|---|---|---|
| Putting `user_id`/`request_id`/raw URLs in labels | Cardinality explodes, Prometheus OOMs | Bounded, known labels (`method`, `route` template, `status`) |
| Putting a raw counter on a graph | An ever-increasing number is meaningless | Read the rate with `rate(counter[5m])` |
| Trying to measure every metric | Noise + cost, the signal gets lost | Start with the four golden signals |
| Writing secrets/PII into a metric/label | `/metrics` leaks it (same as B1) | Never secrets/PII in a metric; keep the endpoint internal |
| Exposing the `/metrics` endpoint to the internet | Internal structure and traffic get exposed | `127.0.0.1`/internal network + auth if needed |
| Metrics but no logs (or vice versa) | One gives you the trend, the other the event; you're half-blind | Use both together (B1 + B2) |
| Measuring without thinking about retention/limits | Disk/memory fills up, OOM 6 months later | Retention + cardinality budget (deep-dive) |
| Assuming the exporter is `push` and trying to "send" data | Prometheus **pulls**; wrong mental model | The app exposes `/metrics`, Prometheus scrapes it |
| Giving a counter `[5m]` and forgetting `rate()` | "expected range vector" / a meaningless line | Counter → `rate(...[5m])`; gauge → bare |
| Assuming `up == 0` means "no data" | The target is down, not silent; you miss the alert | Watch the `up`/`scrape_*` meta-metrics |

## 📖 Read first / further reading
| Source | For what | When |
|---|---|---|
| [`07-Observability/Prometheus-Best-Practices.md`](../../07-Observability/Prometheus-Best-Practices.md) | Cardinality, naming, retention, recording rules | After finishing this module (depth) |
| [`07-Observability/Alerting-Done-Right.md`](../../07-Observability/Alerting-Done-Right.md) | Going from metrics to alerts | **Before E2** — not now |

## 🔨 Lab
👉 [`labs/build/L08-metrik/`](../labs/build/L08-metrik/README.md) — (Task outline: set up
node_exporter + Prometheus with systemd on the A6 VM, query at least two of the four
golden signals with PromQL, and deliberately add a high-cardinality label to observe how
the series count explodes.)

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] An exporter is running on the VM, the target shows `UP` on Prometheus's **Targets** screen; the `up` query returns `1`.
- [ ] You wrote a PromQL query that returns a health indicator (e.g. `rate(...[5m])`) and showed its output.
- [ ] You gave an example of a label that leads to high cardinality and explained **in writing** why it's avoided (series explosion → OOM).
- [ ] You **wrote down** the difference between a counter and a gauge, and which one you read with `rate()`, with an example.

## 🧪 Test yourself
1. What does Prometheus's "pull" model mean? If the app isn't sending data, how does Prometheus get it?
2. **Scenario:** A graph is plotting `http_requests_total` and you see a steadily rising straight line; you want "request rate". How do you fix the query?
3. **Design:** An engineer says "let's add a `request_id` label to the metric so we can see every request individually". What do you say, and why?

<details><summary>Answers</summary>

1. Prometheus visits the `/metrics` HTTP endpoint of every target it watches at regular intervals (scrape interval) and **pulls** the current values. The app doesn't send anything anywhere; it just exposes current metrics on an endpoint. "Who pulls whom" is defined in `scrape_configs`.

2. `http_requests_total` is a counter; its raw form is meaningless because it's a number that keeps rising. To see the rate, you use `rate(http_requests_total[5m])` — this gives you the per-second increase rate over the last 5 minutes, i.e. "how many requests per second".

3. **No.** `request_id` has unbounded cardinality; every unique value creates a separate time series, exploding cardinality and driving Prometheus to OOM. Per-request resolution is the **log's** job (B1), not the metric's — there, `request_id` is a field. Metrics are for trends; their labels must come from bounded, known sets (`method`, `status`, the `route` template).

</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| Target `DOWN` / `up`=0 | Exporter isn't running or the port is closed | `systemctl status`; `curl 127.0.0.1:9100/metrics` (A6/A2) |
| `/metrics` empty / can't connect | Exporter is listening on the wrong address | Verify the actual port with `ss -tlnp` (A2) |
| PromQL "no data" | Wrong metric name/label | Find the metric name via autocomplete in the UI |
| Counter graph keeps rising | `rate()` wasn't used | Wrap it with `rate(metric[5m])` |
| Prometheus memory is bloating / OOM | Cardinality explosion | Remove the high-cardinality label (deep-dive) |
| Query is very slow | Wide range / too many series | Narrow the range; recording rule (deep-dive) |

## 💼 Portfolio output
A working basic metrics setup (exporter + Prometheus + a few PromQL queries) — it'll
evolve into an SLO in E1 and an alert in E2. Document the setup steps like you did in A6.

## ⏭️ Up next
[`B3 — First Broken Lab`](B3-ilk-kirik-lab.md)

---

> *"You can't measure everything; knowing what you don't measure is also a decision."*
