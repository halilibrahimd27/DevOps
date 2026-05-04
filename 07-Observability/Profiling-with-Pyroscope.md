# Continuous Profiling — Pyroscope, eBPF Profiling

> *"Trace 'hangi span yavaş' söyler; profiling **hangi line yavaş**
> söyler. p99 latency 5s → trace DB call'da, profiling ise 'index
> taraması, missing index' line-level olarak gösterir. **4. Pillar**."*

Bu rehber continuous profiling'i — Pyroscope, eBPF auto-profiling,
flame graph analizi — production'da kurma pratiklerini anlatır.

---

## 🎯 4. Pillar of Observability

```
1. Metrics    → "Ne kadar?"     (Prometheus)
2. Logs       → "Niye?"          (Loki)
3. Traces     → "Nerede?"        (Tempo)
4. Profiles   → "Hangi line?"    (Pyroscope)  ← yeni
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

→ **Wide bar** = CPU time'ın çoğu burada. Optimize hedefi.

---

## 🚀 Pyroscope (Grafana)

```bash
helm install pyroscope grafana/pyroscope \
  -n pyroscope --create-namespace
```

### Profiles tipleri
| Type | Ne ölçer |
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

> Pyroscope **eBPF mode** — herhangi bir binary, code change gerek yok.

```bash
# DaemonSet eBPF profiler
helm install pyroscope-ebpf grafana/pyroscope \
  -n pyroscope \
  --set ebpf.enabled=true \
  --set ebpf.applicationName=k8s-cluster
```

→ Tüm node'larda eBPF program çalışır, **tüm pod'ları** profile eder. **Code change yok**.

> ⚠️ **Linux kernel 4.18+** + privileged DaemonSet (host PID erişimi).

---

## 🔍 Pratik Senaryolar

### Senaryo 1: CPU spike
```
1. Prometheus: CPU 90% (1 pod)
2. Tempo trace: handle_payment span uzun
3. Pyroscope: handle_payment → json.Marshal() %50 CPU
4. Fix: pre-serialize cache veya mesh proto
```

### Senaryo 2: Memory leak
```
1. Memory steady artıyor, GC etkisiz
2. Pyroscope inuse_objects:
   - 1 saat önce: cache 50K entries
   - Şimdi: cache 5M entries → leak
3. Code: TTL eviction eksik
4. Fix: LRU cache + TTL
```

### Senaryo 3: Mutex contention
```
1. Trace: latency variable (50-2000ms)
2. Pyroscope mutex profile:
   - shared_lock %30 CPU contention
3. Fix: sync.RWMutex → atomic.Value
```

### Senaryo 4: Slow DB query
```
1. Trace: db.Query 7s
2. Pyroscope: pq.Driver.Exec → libpq parse %60
3. Fix: prepared statement
```

---

## 📊 Diff View — Before/After

> Pyroscope'un en güçlü feature: **iki zaman aralığını karşılaştır**.

```
Time A: deploy v1.4.0 (öncesi)
Time B: deploy v1.4.1 (sonrası)

Diff: handle_payment +%30 CPU
   │
   └── new_validation() ekledik (yeni code)
        ├── regex.MustCompile (her call!) ⚠️
        └── Fix: sync.Once ile precompile
```

→ Performance regression **deploy bazında** tespit.

---

## 🎯 Continuous Profiling vs On-Demand

### On-demand (eski)
- "Pod yavaş, bağlan + pprof al"
- Gece SEV1'de zor
- Production'a impact

### Continuous (yeni)
- 7/24 sürekli profile
- Geçmiş zaman dilimini sorgula
- **Production'a impact < %5**

> 🔑 Pyroscope continuous: 24/7 her servis profilenir. SEV1'de **historic data** zaten var.

---

## 🛡️ Production Concerns

### Performance overhead
- CPU profiling: %2-5 overhead
- Memory profiling: %1-3
- eBPF mode: %0.5-1 (kernel-level)

### Storage
- Profile veri 1 GB/saat (1 servis için)
- S3 backend (Pyroscope)
- Retention: 7-30 gün

### Security
- Profile veri: function names, line numbers (sensitive değil)
- Memory profile: ALLOCATE pattern (not actual data)
- PII concern minimal

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Profiling on-demand sadece | SEV1'de geç | Continuous |
| Tüm profile type aktif | Overhead | Sadece CPU + alloc |
| Sample rate %100 | Performance | %1-5 sample |
| Profile data uzun retention | Cost | 7-30 gün |
| eBPF mode kernel < 4.18 | Çalışmaz | Kernel upgrade |
| Code instrument + eBPF aynı app | Duplicate | Birini seç |
| Profile diff yok deploy sonrası | Regression görünmez | A/B compare |
| PII concern olmadan profile | Function name kontrol | Filter |

---

## 📋 Continuous Profiling Checklist

```
[ ] Pyroscope deploy (Helm)
[ ] Backend storage: S3 (cost-effective)
[ ] eBPF profiler (kernel ≥ 4.18) veya SDK
[ ] Critical service'ler instrumented
[ ] Profile types: CPU + alloc (default)
[ ] Sample rate < %5 overhead
[ ] Grafana datasource: Pyroscope
[ ] Retention: 14-30 gün
[ ] Diff view: deploy A/B compare
[ ] Trace ↔ profile drill-down (Tempo + Pyroscope)
[ ] Quarterly: profile-driven optimization
```

---

## 📚 Referanslar

- **Grafana Pyroscope** — grafana.com/oss/pyroscope
- **Parca** (alternative, eBPF) — parca.dev
- **Polar Signals** (commercial) — polarsignals.com
- **Brendan Gregg — Flame Graphs** — brendangregg.com/flamegraphs.html
- [`OpenTelemetry-Adoption.md`](OpenTelemetry-Adoption.md)
- [`Tracing-with-Tempo.md`](Tracing-with-Tempo.md)
- [`Prometheus-Best-Practices.md`](Prometheus-Best-Practices.md)
- [`Logs-Loki-vs-ELK.md`](Logs-Loki-vs-ELK.md)

---

> *"Profiling **3 pillar'ın** (metric/log/trace) cevabı bittiğinde
> başlar. 'Hangi servis yavaş?' → trace; 'hangi line yavaş?' →
> profile. Continuous profiling **4. pillar** = production'a
> peep-hole."*
