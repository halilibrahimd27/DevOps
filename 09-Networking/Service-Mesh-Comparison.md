# Service Mesh Karşılaştırma — Istio, Linkerd, Cilium

> *"Service mesh kurmadan önce sor: 'Hangi problemi çözüyor?' Cevabın
> 'mTLS + observability + traffic management' değilse, **mesh ihtiyacın
> yok**."*

Bu rehber 2026 itibarıyla 3 büyük service mesh'i karşılaştırır,
"sidecar-less" yükselişini açıklar, ve hangi senaryoda hangisini
seçmen gerektiğine net cevap verir.

---

## 🎯 Service Mesh Niye Var?

Distributed sistemlerde **her servis** aynı şeyleri çözmek zorunda:
- mTLS encryption
- Retry / timeout / circuit breaker
- Observability (metrics, traces, logs)
- Traffic shaping (canary, A/B)
- Authorization

Kütüphane ile her dilde tekrar yazmak yerine **network katmanına
soyutla** = service mesh.

```
[App] ←→ [App]                ← service-to-service
   ↑          ↑
   sidecar   sidecar           ← Istio / Linkerd
   (proxy)   (proxy)
   ↑          ↑
   eBPF     eBPF              ← Cilium (sidecar-less)
   (kernel) (kernel)
```

---

## ⚖️ 3 Büyük: Istio vs Linkerd vs Cilium

### Istio
- **Data plane**: Envoy sidecar (her pod yanında)
- **Control plane**: istiod
- **Yaş**: 2017, en köklü, en zengin feature
- **Dezavantaj**: Karmaşık, sidecar overhead

### Linkerd
- **Data plane**: linkerd2-proxy (Rust, ultra-light)
- **Control plane**: Linkerd
- **Yaş**: 2018 (v2), CNCF Graduated
- **Dezavantaj**: Daha az feature (kısacalık ama bilinçli)

### Cilium Service Mesh
- **Data plane**: eBPF (kernel-level, sidecar-less!)
- **Control plane**: Cilium Operator
- **Yaş**: 2022 (mesh feature olarak)
- **Dezavantaj**: Cilium CNI gerektirir, yeni

---

## 📊 Detaylı Karşılaştırma

| Boyut | **Istio** | **Linkerd** | **Cilium SM** |
|---|---|---|---|
| **Data plane** | Envoy sidecar | linkerd2-proxy (Rust) | eBPF (sidecarless) + envoy-on-demand |
| **Sidecar memory/pod** | ~50 MB | ~10 MB | 0 (kernel) |
| **Latency overhead** | ~3 ms | ~1.5 ms | ~0.3 ms |
| **mTLS otomatik** | ✅ | ✅ (en kolay) | ✅ |
| **L7 routing** | ✅ Çok zengin | ✅ Sınırlı | ✅ (Envoy-as-needed) |
| **Traffic split / canary** | ✅ VirtualService | ✅ TrafficSplit (SMI) | ✅ Cilium L7 |
| **Multi-cluster** | ✅ Karmaşık ama tam | ✅ | ✅ Cluster Mesh |
| **AuthZ policy** | ✅ AuthorizationPolicy | ✅ Server + AuthZ | ✅ CiliumNetworkPolicy |
| **External traffic** | Gateway (Ingress) | Smaller story (genelde 3rd party Ingress) | Gateway API native |
| **Egress control** | Egress Gateway | External profile | Cilium Egress |
| **Observability** | Kiali, Jaeger, Prometheus | Linkerd Viz, Jaeger | Hubble (UI), Prometheus |
| **Setup karmaşası** | 🟥 Yüksek | 🟢 Düşük | 🟧 Orta (Cilium prereq) |
| **Öğrenme eğrisi** | 🟥 Dik | 🟢 Yumuşak | 🟧 Orta |
| **Resource maliyeti** | 🟥 Yüksek (sidecar/pod) | 🟧 Düşük | 🟢 En düşük |
| **CNCF status** | Graduated | Graduated | Graduated (CNI), Mesh Incubating |
| **Vendor neutral** | ✅ | ✅ | ✅ |
| **Ambient mode** (sidecarless Istio) | ✅ Beta | n/a | n/a (zaten sidecarless) |

---

## 🪜 "Niye sidecar-less yükselişte?" (Cilium / Istio Ambient)

### Sidecar modeli sorunları
1. **Resource maliyeti** — her pod'a +50 MB. 1000 pod = 50 GB ek RAM.
2. **Latency** — her hop +2 ms (in + out)
3. **Lifecycle karmaşası** — sidecar pod'la birlikte init/teardown timing
4. **Debug zor** — pod içinde 2 container, log'lar karışır

### Sidecar-less yaklaşımı
- **Cilium**: kernel'da eBPF programı, sidecar yok
- **Istio Ambient**: ztunnel (node-level) + waypoint (gateway-level)
- 2026'da büyük cluster'lar için **standart trend**

> 🔑 Yeni başlıyorsan **sidecar-less** öncelikli düşün. Mevcut Istio sidecar
> deployment'ın varsa ambient'a geçiş yıllar sürebilir, plan yap.

---

## 🌳 Karar Ağacı

```
Service mesh ihtiyacın gerçek mi?
│
├── HAYIR → Mesh kullanma. NetworkPolicy + cert-manager + OpenTelemetry yeter.
│
└── EVET
    │
    ├── Cilium CNI kullanıyor musun?
    │     │
    │     ├── EVET → Cilium Service Mesh
    │     │   (sidecar-less, en düşük overhead)
    │     │
    │     └── HAYIR → devam
    │
    ├── Multi-cluster + kompleks traffic management gerekli mi?
    │     │
    │     ├── EVET → Istio (Ambient mode tercih)
    │     │
    │     └── HAYIR → Linkerd (basit, hızlı, prod-ready)
    │
    └── Kurumsal compliance + ticari destek?
          │
          ├── EVET → Istio (commercial: Solo.io / Tetrate)
          │   veya Linkerd (Buoyant Enterprise)
          │
          └── HAYIR → OSS Linkerd
```

---

## 🛠️ Quick-Start: Linkerd (En Kolay)

```bash
# CLI install
curl -sL https://run.linkerd.io/install | sh

# Pre-flight check
linkerd check --pre

# Install CRDs
linkerd install --crds | kubectl apply -f -

# Install control plane
linkerd install | kubectl apply -f -

# Verify
linkerd check

# Bir namespace'i mesh'e dahil et (auto-inject)
kubectl annotate namespace <NS> linkerd.io/inject=enabled

# Deployment'ları restart → sidecar inject
kubectl rollout restart deployment -n <NS>
```

### Linkerd Viz (observability)
```bash
linkerd viz install | kubectl apply -f -
linkerd viz dashboard
```

### mTLS verify (otomatik)
```bash
linkerd viz edges -n <NS>
# Her edge "Secured" gösteriyorsa mTLS aktif
```

---

## 🛠️ Quick-Start: Cilium Service Mesh

```bash
# Cilium install (CNI olarak, mesh enabled)
helm install cilium cilium/cilium \
  -n kube-system \
  --version <VERSION> \
  --set kubeProxyReplacement=strict \
  --set k8sServiceHost=<API_SERVER> \
  --set k8sServicePort=<API_PORT> \
  --set ingressController.enabled=true \
  --set gatewayAPI.enabled=true \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true

# Verify
cilium status
cilium connectivity test
```

### Hubble UI (network observability)
```bash
cilium hubble ui   # localhost'ta UI açılır
```

### L7 policy
```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: api-allow-frontend
  namespace: <NS>
spec:
  endpointSelector:
    matchLabels: {app: api}
  ingress:
    - fromEndpoints:
        - matchLabels: {app: frontend}
      toPorts:
        - ports: [{port: "8080"}]
          rules:
            http:
              - method: GET
                path: "/api/v1/.*"
              - method: POST
                path: "/api/v1/orders"
```

---

## 🛠️ Quick-Start: Istio (Ambient Mode, 2026 Önerisi)

```bash
# Istio CLI
curl -L https://istio.io/downloadIstio | sh -
cd istio-<VERSION> && export PATH=$PWD/bin:$PATH

# Install Ambient profile
istioctl install --set profile=ambient -y

# Namespace'i ambient'e dahil et
kubectl label namespace <NS> istio.io/dataplane-mode=ambient
```

### Sidecar mode (legacy, mevcut migration için)
```bash
istioctl install --set profile=demo -y
kubectl label namespace <NS> istio-injection=enabled
kubectl rollout restart deployment -n <NS>
```

### AuthorizationPolicy (zero trust)
```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: api-allow-frontend
  namespace: <NS>
spec:
  selector: {matchLabels: {app: api}}
  action: ALLOW
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/<NS>/sa/frontend"]
```

---

## 📊 Benchmark (yaklaşık, 2025 community sonuçları)

100 RPS, basic HTTP:

| Setup | p50 latency | p99 latency | Memory/pod |
|---|---|---|---|
| **Bare K8s** (no mesh) | 2 ms | 8 ms | 0 |
| **Linkerd** | 3 ms | 11 ms | +10 MB |
| **Cilium SM** (eBPF) | 2.3 ms | 9 ms | 0 |
| **Istio Ambient** | 2.5 ms | 10 ms | 0 (waypoint başına) |
| **Istio Sidecar** | 5 ms | 18 ms | +50 MB |

> ⚠️ Benchmark **sentetik**; gerçek yüklerle test et. Trend: sidecar-less
> < sidecar.

---

## 🚧 "Service Mesh Olmadan Yapabilir miyim?"

Çoğu durumda **EVET**:

| İhtiyaç | Mesh-siz çözüm |
|---|---|
| mTLS service-to-service | cert-manager + app-side TLS / SPIFFE |
| Observability | OpenTelemetry SDK + Prometheus + Tempo |
| Retry / timeout | App-side library (Resilience4j, Polly, etc.) |
| Canary deploy | Argo Rollouts + Service split |
| AuthZ | App-side JWT + OPA sidecar |
| Network policy | Cilium NetworkPolicy (mesh olmadan) |

> 🔑 **Service mesh = aggregation.** Yukarıdaki 6 şeyi 6 ayrı tool ile
> çözüyorsan, mesh kullanılabilir. Sadece 2-3 tanesine ihtiyacın varsa
> point solutions daha basit.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "Modern olduğu için" mesh kurmak | Karmaşıklık ekler, problem çözmez | Önce ihtiyacı tanımla |
| Tüm namespace'lere sidecar inject | Kontrol/sistem pod'larında bile sidecar | Selective injection |
| Default deny olmadan AuthZ | Bypass kolay | Default deny + explicit allow |
| Mesh + L7 NetworkPolicy + cert-manager üst üste | Çakışma, debug imkansız | Sorumluluk ayrımı net |
| Ambient mode'a hazır olmadan migration | Beta features prod'da kırar | Stable release bekle, lab'da dene |
| Sidecar resource limit yok | Tüm pod'lar OOM riski | Limit ver, monitor et |
| mTLS aktif ama uygulama TLS de yapıyor | Double encryption, debug zor | Mesh termination only |
| Kontrol plane HA değil | Mesh down → cluster yarım | Multi-replica control plane |
| Observability default-on, log spam | Cost patlar | Sample rate, severity filter |
| Multi-cluster mesh, network arası latency 50 ms | Mesh fayda göstermiyor | Per-cluster mesh, federation farklı |

---

## 🎯 Senaryo-Bazlı Öneri (2026)

| Senaryo | Önerilen |
|---|---|
| < 50 microservice, K8s yeni | **Linkerd** veya mesh kullanma |
| Cilium CNI varsa | **Cilium Service Mesh** |
| 100+ microservice, multi-cluster | **Istio Ambient** |
| Compliance ağırlıklı (FSI, healthcare) | **Istio** (commercial support: Solo.io / Tetrate) |
| Edge / IoT, ultra düşük resource | **Cilium** (sidecarless) |
| Sadece mTLS lazım | cert-manager + app-side; **mesh yerine** |
| Sadece observability lazım | OpenTelemetry SDK; **mesh yerine** |

---

## 📋 Service Mesh Adoption Checklist

```
[ ] İhtiyaç dokümanı yazıldı: hangi 3+ problemi çözüyor?
[ ] Alternatif (mesh-siz çözümler) kıyaslandı
[ ] Lab cluster'da PoC, performans benchmark yapıldı
[ ] Control plane HA (3+ replica)
[ ] Selective injection (sistem ns'leri exclude)
[ ] mTLS otomatik, manuel cert işlemi yok
[ ] Default deny AuthZ → aşamalı whitelist
[ ] Observability: Prometheus + traces + Hubble/Kiali UI
[ ] Sidecar resource limits set (varsa)
[ ] Egress control: external traffic policy
[ ] Multi-cluster için federation planı
[ ] Migration planı (Ambient'a geçiş, vb.)
[ ] Ekip eğitimi yapıldı (control plane, debug, troubleshooting)
[ ] Mesh upgrade prosedürü dokümante (canary upgrade)
[ ] DR: mesh down → service-to-service ne yapar (degrade davranışı)
```

---

## 📚 Referanslar

- **Istio Docs** — istio.io
- **Linkerd Docs** — linkerd.io
- **Cilium Service Mesh** — cilium.io/use-cases/service-mesh/
- **CNCF Service Mesh Working Group**
- **SMI (Service Mesh Interface)** — vendor-neutral spec
- **Buoyant Cloud** — Linkerd commercial
- **Solo.io / Tetrate** — Istio commercial
- [`Cilium-eBPF-Intro.md`](Cilium-eBPF-Intro.md)
- [`Gateway-API-Migration.md`](Gateway-API-Migration.md)
- [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md)

---

> *"Service mesh **çözüm** değil, **soyutlamadır**. İyi seçilirse 6
> tool'u 1 yapıp ekip yükünü düşürür; kötü seçilirse 1 tool'la çıkacağın
> problem 6 tool'a yayılır."*
