---
description: "A continuous profiling guide: Pyroscope as the 4th pillar of observability, eBPF-based auto-profiling, flame graph analysis, and line-level performance detection in production."
tags:
  - Observability
  - Performance
  - Monitoring
  - SRE
---
# Continuous Profiling — Pyroscope, eBPF Profiling

> *"Trace tells you 'which span is slow'; profiling tells you **which
> line is slow**. p99 latency 5s → trace points to the DB call,
> profiling shows 'index scan, missing index' at the line level. **The 4th Pillar**."*

This guide covers continuous profiling — Pyroscope, eBPF
auto-profiling, flame graph analysis — and the practices for setting it up in production.

---

## 🎯 The 4th Pillar of Observability

```
1. Metrics    → "How much?"     (Prometheus)
2. Logs       → "Why?"          (Loki)
3. Traces     → "Where?"        (Tempo)
4. Profiles   → "Which line?"   (Pyroscope)  ← new
```

---

## 🔥 Flame Graph

```
[main()] ────────────────────────────────────────  100%
  ├── handle_request() ──────────────────────────  85%
  │   ├── parse_json() ────  10%
  │   ├── db_query() ──────────────────────────── 60%
  │   │   └── lock_wait() ────────────────  55% ⚠️
  │   └── render_response() ─  15%
  └── background_task() ────  15%
```

→ **Wide bar** = most of the CPU time is spent here. The optimization target.

---

## 🚀 Pyroscope (Grafana)

```bash
helm install pyroscope grafana/pyroscope \
  -n pyroscope --create-namespace
```

### Profile Types
| Type | What it measures |
|---|---|
| **CPU** | CPU time per function |
| **Memory (alloc)** | Allocated memory |
| **Memory (in-use)** | Live memory |
| **Goroutines** (Go) | Concurrent goroutine count |
| **Mutex** | Lock contention |
| **Block** | Goroutine blocking |

---

## 📦 Instrumentation

### Go
```go
import "github.com/grafana/pyroscope-go"

pyroscope.Start(pyroscope.Config{
    ApplicationName: "payments-api",
    ServerAddress:   "http://pyroscope:4040",
    ProfileTypes: []pyroscope.ProfileType{
        pyroscope.ProfileCPU,
        pyroscope.ProfileAllocObjects,
        pyroscope.ProfileAllocSpace,
        pyroscope.ProfileInuseObjects,
        pyroscope.ProfileInuseSpace,
    },
})
```

### Python
```python
import pyroscope

pyroscope.configure(
    application_name="payments-api",
    server_address="http://pyroscope:4040",
)
```

### Node.js
```javascript
const Pyroscope = require('@pyroscope/nodejs');

Pyroscope.init({
  serverAddress: 'http://pyroscope:4040',
  appName: 'payments-api',
});
Pyroscope.start();
```

### Java
```bash
# Java agent
java -javaagent:pyroscope.jar \
  -Dpyroscope.application.name=payments-api \
  -Dpyroscope.server.address=http://pyroscope:4040 \
  -jar app.jar
```

---

## 🦅 eBPF Auto-Profiling (No Code Change)

> Pyroscope **eBPF mode** — works with any binary, no code change required.

```bash
# DaemonSet eBPF profiler
helm install pyroscope-ebpf grafana/pyroscope \
  -n pyroscope \
  --set ebpf.enabled=true \
  --set ebpf.applicationName=k8s-cluster
```

→ The eBPF program runs on every node and profiles **every pod**. **No code change**.

> ⚠️ **Linux kernel 4.18+** + privileged DaemonSet (host PID access).

---

## 🔍 Practical Scenarios

### Scenario 1: CPU spike
```
1. Prometheus: CPU 90% (1 pod)
2. Tempo trace: handle_payment span is long
3. Pyroscope: handle_payment → json.Marshal() 50% CPU
4. Fix: pre-serialize cache or mesh proto
```

### Scenario 2: Memory leak
```
1. Memory steadily increasing, GC ineffective
2. Pyroscope inuse_objects:
   - 1 hour ago: cache 50K entries
   - Now: cache 5M entries → leak
3. Code: TTL eviction missing
4. Fix: LRU cache + TTL
```

### Scenario 3: Mutex contention
```
1. Trace: latency variable (50-2000ms)
2. Pyroscope mutex profile:
   - shared_lock 30% CPU contention
3. Fix: sync.RWMutex → atomic.Value
```

### Scenario 4: Slow DB query
```
1. Trace: db.Query 7s
2. Pyroscope: pq.Driver.Exec → libpq parse 60%
3. Fix: prepared statement
```

---

## 📊 Diff View — Before/After

> Pyroscope's strongest feature: **compare two time ranges**.

```
Time A: deploy v1.4.0 (before)
Time B: deploy v1.4.1 (after)

Diff: handle_payment +30% CPU
   │
   └── new_validation() added (new code)
        ├── regex.MustCompile (every call!) ⚠️
        └── Fix: precompile with sync.Once
```

→ Performance regression detected **per deploy**.

---

## 🎯 Continuous Profiling vs On-Demand

### On-demand (old)
- "Pod is slow, connect + grab a pprof"
- Hard during a nighttime SEV1
- Impacts production

### Continuous (new)
- Continuous profiling 24/7
- Query a past time window
- **Impact on production < 5%**

> 🔑 Pyroscope continuous: every service is profiled 24/7. **Historic data** already exists for a SEV1.

---

## 🛡️ Production Concerns

### Performance overhead
- CPU profiling: 2-5% overhead
- Memory profiling: 1-3%
- eBPF mode: 0.5-1% (kernel-level)

### Storage
- Profile data: 1 GB/hour (for 1 service)
- S3 backend (Pyroscope)
- Retention: 7-30 days

### Security
- Profile data: function names, line numbers (not sensitive)
- Memory profile: ALLOCATE pattern (not actual data)
- PII concern minimal

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Profiling only on-demand | Too late during a SEV1 | Continuous |
| All profile types active | Overhead | Only CPU + alloc |
| Sample rate 100% | Performance | 1-5% sample |
| Long retention for profile data | Cost | 7-30 days |
| eBPF mode on kernel < 4.18 | Doesn't work | Kernel upgrade |
| Code instrumentation + eBPF on the same app | Duplicate | Pick one |
| No profile diff after deploy | Regression stays invisible | A/B compare |
| Profiling without a PII concern check | Check function names | Filter |

---

## 📋 Continuous Profiling Checklist

```
[ ] Pyroscope deployed (Helm)
[ ] Backend storage: S3 (cost-effective)
[ ] eBPF profiler (kernel ≥ 4.18) or SDK
[ ] Critical services instrumented
[ ] Profile types: CPU + alloc (default)
[ ] Sample rate < 5% overhead
[ ] Grafana datasource: Pyroscope
[ ] Retention: 14-30 days
[ ] Diff view: deploy A/B compare
[ ] Trace ↔ profile drill-down (Tempo + Pyroscope)
[ ] Quarterly: profile-driven optimization
```

---

## 📚 References

- **Grafana Pyroscope** — grafana.com/oss/pyroscope
- **Parca** (alternative, eBPF) — parca.dev
- **Polar Signals** (commercial) — polarsignals.com
- **Brendan Gregg — Flame Graphs** — brendangregg.com/flamegraphs.html
- [`OpenTelemetry-Adoption.md`](OpenTelemetry-Adoption.md)
- [`Tracing-with-Tempo.md`](Tracing-with-Tempo.md)
- [`Prometheus-Best-Practices.md`](Prometheus-Best-Practices.md)
- [`Logs-Loki-vs-ELK.md`](Logs-Loki-vs-ELK.md)

---

> *"Profiling begins where the answers from **the first 3 pillars**
> (metric/log/trace) run out. 'Which service is slow?' → trace;
> 'which line is slow?' → profile. Continuous profiling is the **4th
> pillar** = a peep-hole into production."*
