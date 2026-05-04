# Chaos Engineering — Kontrollü Hata Yaratmak

> *"Production'da incident'ı **bekleyen ekip**, ihlal anında öğrenir.
> Production'a **kontrollü hata enjekte eden ekip**, ihlali **simülasyonda
> yakalar**. Game day, prod'a güven inşa etmenin tek yoludur."*

Bu rehber chaos engineering'i — game day, fault injection, Litmus,
Chaos Mesh — ekibin kültürüne entegre etmenin somut yollarını anlatır.

---

## 🎯 Chaos Engineering Nedir?

> **Chaos Engineering**: Sisteme **kontrollü hata** enjekte ederek
> "production'da çalışacağı umulan" davranışı **doğrulamak**.

```
Hipotez: "Region down olursa, kullanıcı %1'den az etkilenir."
   │
   ▼
Deney: us-west-2 region'ı simülasyonla down et
   │
   ▼
Gözlem: gerçek metric ne gösterdi?
   │
   ▼
Sonuç: Hipotez ✓ veya gap (öğrenme)
```

> 🔑 **Ders**: gerçek incident'tan **önce** öğren. Pahalı bir ders olmadan.

---

## 🪜 Olgunluk Modeli

| Level | Pratik |
|---|---|
| **L1** | Yıllık manuel game day (1-2 senaryo) |
| **L2** | Quarterly game day, bazı tool (Chaos Toolkit) |
| **L3** | Aylık game day + CI'da staging chaos test |
| **L4** | Production'da continuous chaos (controlled blast radius) |
| **L5** | Self-service chaos: dev kendi servisi için test eder |

> 🎯 **2026 hedefi**: L3. L4 için olgun ekip + sağlam observability.

---

## 🛠️ Chaos Tool'ları

| Tool | Tip | K8s |
|---|---|---|
| **Chaos Mesh** | CRD-based | ✅ Native |
| **Litmus Chaos** | CRD-based | ✅ Native |
| **AWS Fault Injection Simulator** | Cloud-native | AWS |
| **Gremlin** | SaaS | Cross-platform |
| **Chaos Toolkit** | CLI | Cross-platform |
| **Pumba** | Docker | Container-only |

> 🔑 K8s ekosistemi → **Chaos Mesh** veya **Litmus**. AWS-native → FIS.

---

## 🚀 Chaos Mesh — Quick Start

### Kurulum
```bash
helm install chaos-mesh chaos-mesh/chaos-mesh \
  -n chaos-mesh --create-namespace \
  --set chaosDaemon.runtime=containerd \
  --set chaosDaemon.socketPath=/run/containerd/containerd.sock
```

### Pod Kill experiment
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: payment-pod-kill
  namespace: chaos-mesh
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces: [payments]
    labelSelectors:
      app: payments-api
  duration: '0s'   # tek seferlik
  scheduler:
    cron: '@every 24h'   # günlük
```

### Network delay
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: payment-db-latency
spec:
  action: delay
  mode: all
  selector:
    namespaces: [payments]
    labelSelectors: {app: payments-api}
  delay:
    latency: '500ms'
    correlation: '50'
    jitter: '50ms'
  direction: to
  target:
    selector:
      namespaces: [postgres]
    mode: all
  duration: '5m'
```

### CPU stress
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: api-cpu-stress
spec:
  mode: one
  selector:
    namespaces: [payments]
    labelSelectors: {app: payments-api}
  stressors:
    cpu:
      workers: 4
      load: 90
  duration: '10m'
```

---

## 🎮 Game Day Senaryo Kataloğu

### Tier 1: Single component
| Senaryo | Süre |
|---|---|
| Random pod kill | 10 dk |
| Single node drain | 15 dk |
| DB primary failover | 20 dk |
| Redis cache flush | 10 dk |
| Service mesh sidecar restart | 10 dk |

### Tier 2: Network
| Senaryo | Süre |
|---|---|
| Partition between services | 20 dk |
| Internet egress block (3rd party) | 15 dk |
| DNS failure | 15 dk |
| Latency spike (50ms → 2s) | 30 dk |
| Packet loss %10 | 20 dk |

### Tier 3: Region / Cloud
| Senaryo | Süre |
|---|---|
| Single AZ down | 30 dk |
| Region failover | 60 dk |
| Cloud provider API outage | 45 dk |
| Certificate expiry | 30 dk |

### Tier 4: Süpriz (her şey birden)
| Senaryo | Süre |
|---|---|
| 3 saat boyunca random fault'lar | 3 saat |
| Black Friday simülasyonu (10x traffic + arıza) | 4 saat |

---

## 📋 Game Day Akışı

```
T-1 hafta: Senaryo + hipotez yazılı
T-1 gün:   Tüm ekibe duyuru, owner atanır
T+0:       Bridge açılır, observability dashboard'lar görünür
T+5dk:     Pre-flight check (sistem sağlıklı mı?)
T+10dk:    Fault inject
T+10-30dk: Gözlem + müdahale (gerekirse abort)
T+30dk:    Fault'u temizle
T+30-60dk: Hot wash retrospective
T+1gün:    Postmortem doküman yazılır
T+1hafta:  Action item'lar tamamlandı mı kontrol
```

### Game Day check-list
```
Önce:
[ ] Senaryo yazılı + hipotez
[ ] Bridge URL paylaşıldı
[ ] On-call ekibi haberdar (pager false alarm değil)
[ ] Müşteri etki risk değerlendirmesi
[ ] Abort kriteri (eğer X olursa durdur)
[ ] Cleanup script hazır

Sırasında:
[ ] Timeline scribe (timestamp her event)
[ ] Hipotez doğrulandı mı yanlışlandı mı?
[ ] Beklenmedik etki var mı?
[ ] Müşteri/operasyonel etki kabul edilebilir mi?

Sonra:
[ ] Cleanup tamamlandı (no lingering chaos)
[ ] Hot wash retrospective
[ ] Postmortem (gap'ler)
[ ] Action items (sahipli + due date)
```

---

## 🎯 Hipotez Yazımı

### Kötü hipotez
> "Sistemimiz çökmesin."

### İyi hipotez
> "Payment-api pod'larından 1 tanesi kill edildiğinde:
>  - p99 latency < 1s kalır
>  - 5xx hata oranı < %0.5
>  - HPA 30s içinde yeni pod scheduler eder
>  - Müşteri tarafına etki yok"

→ **Ölçülebilir**, **falsifiable**, **net kontrol**.

---

## 🏭 Production Chaos (Continuous)

> ⚠️ **Sadece olgun ekip için**. Staging'de pratik kazandıktan sonra.

### Blast radius kontrolü
```yaml
# Chaos Mesh — sadece %5 pod
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
spec:
  mode: percentage
  value: '5'   # %5 pod
  selector:
    labelSelectors: {tier: non-critical}   # Critical servisler hariç
```

### Auto-abort (panic button)
```yaml
spec:
  duration: '5m'
  # Eğer error rate > %5 → abort
  abort:
    metricSelector: 'http_5xx_rate > 0.05'
```

### Communication
- #chaos-events Slack channel
- Status page'de "Engineering exercise" notu
- Müşteri-facing değil (internal only)

---

## 📊 Reliability Metrics

| Metrik | Hedef |
|---|---|
| **Game day frequency** | Aylık |
| **Senaryo coverage** | Top 20 risk için en az 1 |
| **Hipotez başarı oranı** | > %70 (ekip iyileşiyor) |
| **Action item completion** | > %90 within 30 days |
| **MTTR trend** | Yıl yıla iyileşiyor |
| **Production incident rate** | Game day adoption sonrası düşüş |

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Hipotez yok, "şuna basalım" | Öğrenme yok | Yazılı falsifiable hipotez |
| Production'da ilk gün chaos | Müşteri etki | Önce dev/staging |
| Game day sonrası action item yok | Aynı gap tekrar | Sahipli + tarihli action |
| Observability yetersiz, "sonuç bilinmiyor" | Sonuç çıkaramazsın | Önce dashboard, sonra chaos |
| Tek kişi sahipleniyor | Bus factor | Rotasyon: her sprint farklı kişi |
| Senaryo eskidi, rastgele tekrar | Yeni risk öğrenilmez | Quarterly senaryo refresh |
| Cleanup unutuldu, prod'da chaos kaldı | Müşteri etki | Cleanup script + verify |
| Müşteri etki kontrol edilmedi | Game day = real outage | Blast radius + abort |
| Sadece teknik, business etki yok | Risk değerlendirmesi eksik | $ etki + kullanıcı sayısı |
| Manuel her şey, otomasyon yok | Reaktive, tekrarlanmaz | Litmus / Chaos Mesh CRD |
| Game day korkuyla, "test ortamı bozulur" | Adoption düşük | Yöneticiler "test ortamı zaten kırılgan, fix et" |

---

## 📋 Chaos Engineering Adoption Checklist

```
[ ] Chaos Mesh / Litmus / FIS kurulu (staging)
[ ] İlk 5 senaryo yazılı (tier 1)
[ ] Quarterly game day (her ekipten 1+ kişi)
[ ] Hipotez şablonu (falsifiable, ölçülebilir)
[ ] Observability: chaos sırasında metric / log görünür
[ ] Game day playbook (öncesi / sırasında / sonrası)
[ ] Postmortem her game day sonrası
[ ] Action item tracking
[ ] Senaryo katalogu git'te (versioned)
[ ] Production chaos: blast radius < %5, auto-abort
[ ] Müşteri etki risk değerlendirmesi
[ ] Status page communication
[ ] Yeni mühendis on-boarding: shadow game day
[ ] MTTR trend dashboard
[ ] Annual: chaos engineering ROI rapor
```

---

## 📚 Referanslar

- **Chaos Engineering** — Casey Rosenthal, Nora Jones (kitap)
- **Principles of Chaos** — principlesofchaos.org
- **Netflix Chaos Monkey** — github.com/Netflix/chaosmonkey
- **Chaos Mesh** — chaos-mesh.org
- **Litmus** — litmuschaos.io
- **AWS Fault Injection Simulator** — aws.amazon.com/fis
- **Gremlin** — gremlin.com
- [`Incident-Response.md`](Incident-Response.md)
- [`Postmortem-Practice.md`](Postmortem-Practice.md)
- [`Runbook-Template.md`](Runbook-Template.md)
- [`SLI-SLO-Error-Budget.md`](SLI-SLO-Error-Budget.md)

---

> *"Chaos engineering 'risk yaratmak' değil — **risk öğrenmek**.
> Yangın çıkmadan yangın söndürme tatbikatı yapan ekip, **gerçek
> yangında** sakin durur."*
