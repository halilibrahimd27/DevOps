# Container vs WASM — Yeni Runtime Geliyor mu?

> *"Container 2014'te 'VM'i öldürdü' iddiasıyla geldi; bugün VM hâlâ
> her yerde, container ek katman. WASM 2025'te 'container'ı
> öldürecek' diye iddia ediliyor — **ama gerçeklik daha karmaşık**."*

Bu rehber WebAssembly (WASM)'ın server-side runtime olarak nerede
durduğunu, container'a göre avantaj/dezavantajını, ve **2026'da ne
zaman tercih** edileceğini anlatır.

---

## 🎯 WASM Nedir?

> **WebAssembly (WASM)**: Tarayıcı için tasarlanmış low-level bytecode
> formatı. **WASI** (WebAssembly System Interface) ile server-side de
> çalışır.

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

## ⚖️ Container vs WASM — Karşılaştırma

| Boyut | **Container** | **WASM** |
|---|---|---|
| **Boyut** | 30-500 MB | 1-10 MB |
| **Cold start** | 1-5 saniye | **< 1 ms** |
| **Memory** | 100+ MB | 1-50 MB |
| **Isolation** | Kernel namespace + cgroup | Sandbox (capability-based) |
| **Portability** | OS+arch bağımlı | Platform-independent |
| **Networking** | Native | WASI sınırlı |
| **Filesystem** | Native | WASI sınırlı |
| **Threading** | Native | Sınırlı (yeni) |
| **Ecosystem** | Çok zengin | Yeni, sınırlı |
| **Mature** | 10+ yıl | Server-side ~2 yıl |
| **Best for** | Genel iş yükü | Edge, FaaS, sandbox, plugin |

---

## 🌳 WASM'ın Hangi Niche?

### ✅ WASM uygun
1. **Edge computing** (Cloudflare Workers, Fastly Compute@Edge)
   - Cold start kritik (ms cinsinden)
   - 10K+ tenant per server
2. **FaaS / Serverless**
   - Boyut + cold start hassasiyet
3. **Plugin / Extension sistemleri**
   - Envoy, Istio Wasm filter
   - Database stored procedures (sandboxed)
4. **Untrusted code execution**
   - Multi-tenant SaaS code editor
   - Online code playgrounds
5. **Embedded / IoT**
   - Düşük resource

### ❌ WASM henüz uygun değil
1. Stateful service (DB)
2. Heavy networking (TCP server, gRPC)
3. ML inference (GPU yok)
4. Existing ecosystem (binary'i WASM'a çevirmek zor)
5. System-level access (kernel modules, device drivers)

> 🔑 **2026 gerçek**: Container **default**, WASM **specialize use case**.

---

## 🏃 WASM Server-Side Runtime'ları

| Runtime | Açıklama |
|---|---|
| **wasmtime** | Bytecode Alliance, Rust | Production-ready |
| **wasmer** | Commercial backing, Rust | Production-ready |
| **wasmedge** | CNCF Sandbox, edge focused | Production-ready |
| **wasmer-js** | JS host'ta WASM | Embedded |
| **Spin (Fermyon)** | WASM application framework | Higher-level |

---

## 🚀 K8s'de WASM

### containerd + runwasi
```bash
# K8s node'da runwasi shim install
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
      image: <REGISTRY>/<APP>:wasm   # OCI image içinde .wasm
```

### Spin (Fermyon)
```bash
# Hello world
spin new http-rust hello
spin build
spin up   # local'de çalışır

# K8s'e deploy
spin k8s deploy
```

---

## 📊 Performance — Gerçek Sayılar

### Cold start (basit HTTP handler)
| Runtime | Cold start |
|---|---|
| Container (Go static, Lambda) | 200-500 ms |
| Container (Node.js, K8s) | 1-3 s |
| WASM (wasmtime) | **< 1 ms** |
| WASM (Cloudflare Workers) | **5-50 ms** (full network) |

### Boyut
| Format | Boyut |
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

> 🔑 **WASM 10-50x daha verimli** edge senaryolarda. Ama trade-off var (ecosystem, debugging).

---

## 🛠️ Pratik Örnekler

### 1. Cloudflare Workers
```typescript
// JavaScript / TypeScript
export default {
  async fetch(request: Request): Promise<Response> {
    return new Response("Hello from edge!");
  }
};
```

→ Cloudflare Workers V8 isolate kullanır (WASM da destek). Worldwide deploy 1 saniyede.

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

> 🔑 **2026'da WASI hâlâ olgunlaşıyor**. Production'da network-heavy WASM workload kontrol et.

---

## 🌳 Karar Ağacı

```
START
  │
  ├── Edge / serverless / cold-start kritik?
  │     │
  │     └── EVET → WASM (Cloudflare Workers, Spin)
  │
  ├── Plugin / extension / sandbox?
  │     │
  │     └── EVET → WASM (Envoy, OpenPolicy, plugin systems)
  │
  ├── Untrusted multi-tenant code?
  │     │
  │     └── EVET → WASM (security-by-default sandbox)
  │
  ├── Existing app + ecosystem (DB, networking, mature libs)?
  │     │
  │     └── EVET → Container
  │
  └── Default → Container
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "WASM container'ı öldürür" iddiası | Hype, ecosystem yetersiz | Niche-spesifik kullan |
| Tüm app WASM'a port | WASI limitasyonları | Edge/plugin için seç |
| WASM ile DB tutmak | State management WASM uygun değil | Container DB |
| WASM debugging tool yok | Logging zor | Verbose log + tracing |
| Container'ı her şey için kullanmak | Edge senaryoda yetersiz | Hybrid (container + WASM edge) |
| WASM module monolith | Component model yok | Microservice/component split |
| WASM image OCI'ye uygun değil | K8s push fail | Wasm OCI annotation |
| "Yeni hype'a atla" | Production-ready değil bazı feature | Conservative + use case-specific |

---

## 📋 WASM Adoption Checklist

```
[ ] Use case clear (edge, plugin, sandbox?)
[ ] Runtime seçimi (wasmtime / wasmer / wasmedge)
[ ] WASI limitations evaluation (network, threading)
[ ] Build pipeline: Rust/Go/AssemblyScript → .wasm
[ ] OCI image format (containerd uyumluluk)
[ ] K8s RuntimeClass (runwasi)
[ ] Observability: log + trace
[ ] Security: capability-based sandboxing
[ ] Performance benchmark (vs container baseline)
[ ] Migration plan (hybrid container + WASM)
```

---

## 📚 Referanslar

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

> *"WASM 'container'ın halefi' değil — **niche tamamlayıcı**.
> 2026'da edge + plugin + sandbox use case'lerde **container'ı
> 10x geçer**; ama generic workload için **container hâlâ
> kraldır**."*
