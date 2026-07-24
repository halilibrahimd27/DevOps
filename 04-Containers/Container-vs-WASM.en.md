---
description: "WebAssembly (WASM) and WASI's advantages/disadvantages as a server-side runtime compared to containers, and when to choose it in 2026."
tags:
  - Containers
  - Docker
  - Performance
  - Field Notes
---
# Container vs WASM — Is a New Runtime Coming?

> *"Containers arrived in 2014 claiming they'd 'kill the VM'; today
> VMs are still everywhere, containers just an extra layer. WASM is
> claimed to 'kill the container' in 2025 — **but reality is more
> complicated**."*

This guide covers where WebAssembly (WASM) stands as a server-side
runtime, its advantages/disadvantages compared to containers, and
**when to choose it in 2026**.

---

## 🎯 What Is WASM?

> **WebAssembly (WASM)**: A low-level bytecode format designed for
> the browser. With **WASI** (WebAssembly System Interface) it also
> runs server-side.

```
[Source: Rust / Go / C / AssemblyScript]
         │
         ▼
[Compile to .wasm bytecode]
         │
         ▼
[WASM Runtime: wasmtime / wasmer / wasmedge]
         │
         ▼
[Execute, sandboxed]
```

---

## ⚖️ Container vs WASM — Comparison

| Dimension | **Container** | **WASM** |
|---|---|---|
| **Size** | 30-500 MB | 1-10 MB |
| **Cold start** | 1-5 seconds | **< 1 ms** |
| **Memory** | 100+ MB | 1-50 MB |
| **Isolation** | Kernel namespace + cgroup | Sandbox (capability-based) |
| **Portability** | OS+arch dependent | Platform-independent |
| **Networking** | Native | WASI limited |
| **Filesystem** | Native | WASI limited |
| **Threading** | Native | Limited (new) |
| **Ecosystem** | Very rich | New, limited |
| **Mature** | 10+ years | Server-side ~2 years |
| **Best for** | General workloads | Edge, FaaS, sandbox, plugin |

---

## 🌳 Which Niche Does WASM Fit?

### ✅ WASM fits
1. **Edge computing** (Cloudflare Workers, Fastly Compute@Edge)
   - Cold start is critical (in ms)
   - 10K+ tenants per server
2. **FaaS / Serverless**
   - Size + cold start sensitivity
3. **Plugin / extension systems**
   - Envoy, Istio Wasm filter
   - Database stored procedures (sandboxed)
4. **Untrusted code execution**
   - Multi-tenant SaaS code editor
   - Online code playgrounds
5. **Embedded / IoT**
   - Low resource

### ❌ WASM isn't a fit yet
1. Stateful service (DB)
2. Heavy networking (TCP server, gRPC)
3. ML inference (no GPU)
4. Existing ecosystem (hard to convert a binary to WASM)
5. System-level access (kernel modules, device drivers)

> 🔑 **2026 reality**: Container is **default**, WASM is a **specialized use case**.

---

## 🏃 WASM Server-Side Runtimes

| Runtime | Description |
|---|---|
| **wasmtime** | Bytecode Alliance, Rust | Production-ready |
| **wasmer** | Commercial backing, Rust | Production-ready |
| **wasmedge** | CNCF Sandbox, edge focused | Production-ready |
| **wasmer-js** | WASM in a JS host | Embedded |
| **Spin (Fermyon)** | WASM application framework | Higher-level |

---

## 🚀 WASM on K8s

### containerd + runwasi
```bash
# Install the runwasi shim on the K8s node
curl -L https://github.com/deislabs/runwasi/releases/download/<VERSION>/containerd-shim-wasmtime-x86_64-unknown-linux-musl.tar.gz | \
  tar -xz -C /usr/local/bin

# containerd config
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.wasmtime]
  runtime_type = "io.containerd.wasmtime.v1"
```

### RuntimeClass
```yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: wasmtime
handler: wasmtime
---
apiVersion: v1
kind: Pod
metadata:
  name: wasm-app
spec:
  runtimeClassName: wasmtime
  containers:
    - name: app
      image: <REGISTRY>/<APP>:wasm   # .wasm inside the OCI image
```

### Spin (Fermyon)
```bash
# Hello world
spin new http-rust hello
spin build
spin up   # runs locally

# Deploy to K8s
spin k8s deploy
```

---

## 📊 Performance — Real Numbers

### Cold start (simple HTTP handler)
| Runtime | Cold start |
|---|---|
| Container (Go static, Lambda) | 200-500 ms |
| Container (Node.js, K8s) | 1-3 s |
| WASM (wasmtime) | **< 1 ms** |
| WASM (Cloudflare Workers) | **5-50 ms** (full network) |

### Size
| Format | Size |
|---|---|
| Distroless Go binary | 15 MB |
| WASM Go binary | 5 MB |
| WASM Rust binary | 1-3 MB |
| WASM AssemblyScript | < 100 KB |

### Memory footprint
| Runtime | Idle memory |
|---|---|
| Container Go pod | 30-50 MB |
| WASM module | 1-10 MB |

> 🔑 **WASM is 10-50x more efficient** in edge scenarios. But there's a trade-off (ecosystem, debugging).

---

## 🛠️ Practical Examples

### 1. Cloudflare Workers
```typescript
// JavaScript / TypeScript
export default {
  async fetch(request: Request): Promise<Response> {
    return new Response("Hello from edge!");
  }
};
```

→ Cloudflare Workers uses a V8 isolate (WASM is also supported). Worldwide deploy in 1 second.

### 2. Spin HTTP API (Rust)
```rust
use spin_sdk::http::{IntoResponse, Request, Response};
use spin_sdk::http_component;

#[http_component]
fn handle_request(req: Request) -> anyhow::Result<impl IntoResponse> {
    Ok(Response::builder()
        .status(200)
        .body("Hello from WASM!")
        .build())
}
```

```bash
spin build
spin up    # local
spin deploy   # Fermyon Cloud
```

### 3. Envoy WASM Filter
```rust
// Custom HTTP filter
use proxy_wasm::traits::*;
use proxy_wasm::types::*;

struct MyFilter;

impl HttpContext for MyFilter {
    fn on_http_request_headers(&mut self, _: usize, _: bool) -> Action {
        self.set_http_request_header("X-Custom", Some("hello"));
        Action::Continue
    }
}
```

```yaml
# Istio EnvoyFilter
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
spec:
  configPatches:
    - applyTo: HTTP_FILTER
      patch:
        operation: INSERT_BEFORE
        value:
          name: envoy.filters.http.wasm
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
            config:
              vm_config:
                code:
                  local:
                    filename: /etc/envoy/myfilter.wasm
```

---

## 🚧 WASI Limitations (2026)

| Feature | Status |
|---|---|
| File I/O | ✅ Stable |
| Networking (sockets) | 🟡 Preview (WASI Preview 2) |
| Threading | 🟡 Preview |
| Crypto | 🟡 Preview |
| Async | 🟡 Component Model |
| SIMD | ✅ |
| GC | 🟡 Preview |

> 🔑 **WASI is still maturing in 2026**. Check network-heavy WASM workloads carefully in production.

---

## 🌳 Decision Tree

```
START
  │
  ├── Edge / serverless / cold-start critical?
  │     │
  │     └── YES → WASM (Cloudflare Workers, Spin)
  │
  ├── Plugin / extension / sandbox?
  │     │
  │     └── YES → WASM (Envoy, OpenPolicy, plugin systems)
  │
  ├── Untrusted multi-tenant code?
  │     │
  │     └── YES → WASM (security-by-default sandbox)
  │
  ├── Existing app + ecosystem (DB, networking, mature libs)?
  │     │
  │     └── YES → Container
  │
  └── Default → Container
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| The claim "WASM kills the container" | Hype, ecosystem is insufficient | Use it niche-specifically |
| Porting the whole app to WASM | WASI limitations | Choose it for edge/plugin |
| Keeping the DB in WASM | State management doesn't fit WASM | Container DB |
| No WASM debugging tools | Logging is hard | Verbose logs + tracing |
| Using containers for everything | Insufficient in edge scenarios | Hybrid (container + WASM edge) |
| WASM module as a monolith | No component model | Microservice/component split |
| WASM image doesn't conform to OCI | K8s push fails | Wasm OCI annotation |
| "Jump on the new hype" | Some features aren't production-ready | Conservative + use case-specific |

---

## 📋 WASM Adoption Checklist

```
[ ] Use case clear (edge, plugin, sandbox?)
[ ] Runtime selection (wasmtime / wasmer / wasmedge)
[ ] WASI limitations evaluation (network, threading)
[ ] Build pipeline: Rust/Go/AssemblyScript → .wasm
[ ] OCI image format (containerd compatibility)
[ ] K8s RuntimeClass (runwasi)
[ ] Observability: log + trace
[ ] Security: capability-based sandboxing
[ ] Performance benchmark (vs container baseline)
[ ] Migration plan (hybrid container + WASM)
```

---

## 📚 References

- **WebAssembly** — webassembly.org
- **WASI** — wasi.dev
- **Bytecode Alliance** — bytecodealliance.org
- **Spin (Fermyon)** — spin.fermyon.com
- **wasmtime** — wasmtime.dev
- **wasmedge** — wasmedge.org
- **runwasi (containerd)** — github.com/deislabs/runwasi
- **Cloudflare Workers** — workers.cloudflare.com
- [`Multi-Stage-Builds.md`](Multi-Stage-Builds.md)
- [`Dockerfile-Best-Practices.md`](Dockerfile-Best-Practices.md)

---

> *"WASM isn't 'the container's successor' — it's a **niche
> complement**. In 2026 it **beats containers by 10x** in edge +
> plugin + sandbox use cases; but for generic workloads, **the
> container is still king**."*
