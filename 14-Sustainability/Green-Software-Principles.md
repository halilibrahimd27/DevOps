# Green Software Principles — Karbonu Mühendislik Disiplinine Çevirmek

> *"Software is **never** carbon-neutral; it's just CO₂ that you decided
> not to measure."* — Green Software Foundation

Bu rehber Green Software Foundation'un 8 prensibini somut mühendislik
kararlarına çevirir, SCI metric'i ile ölçüm yapmayı, ve "yeşil yazılım"ı
buzzword'den **CI'da pass/fail metric'e** dönüştürmeyi anlatır.

---

## 🎯 Niye 2026'da Önemli?

### Yasal zorunluluklar
- **EU CSRD** (Corporate Sustainability Reporting Directive) — büyük şirket
  emisyon raporlamak **zorunda** (2024 yürürlük, kademeli kapsama)
- **US SEC Climate Rule** — public şirketler Scope 1/2/3 raporlamak
- **EU Cyber Resilience Act + Sustainability** — yazılımın karbon impact'i
- **ISO 14001** ve benzeri standartlar yazılım gözlemine girdi

### İş etki
- **Müşteri talebi** — RFP'lerde "carbon disclosure" sorusu standart
- **Yatırımcı baskısı** — ESG metrikleri funding kararlarında
- **Maliyet** — yeşil = genelde verimli = ucuz (cost ↔ carbon dual optimize)
- **Yetenek çekme** — Gen-Z mühendislerin %70'i sürdürülebilirliği iş seçiminde sayar

> 🔑 **2026'da "biz yeşili önemsemiyoruz" demek**, "biz GDPR uyumu
> yapmıyoruz" demek gibi imkansızlaşıyor.

---

## 🌳 Green Software Foundation — 8 Prensip

### 1. Carbon Efficiency
> Daha az karbon emisyonu ile aynı işi yap.

**Pratik:** Kod düzeyinde optimize et — daha az CPU, daha az IO.

```
Kötü:  500 satır pandas → tüm CSV RAM'e
İyi:   stream processing chunks → daha az memory + CPU
```

### 2. Energy Efficiency
> Daha az watt ile aynı işi yap.

**Pratik:**
- ARM/Graviton CPUs (per-watt 2-4x verimli)
- Compiled languages (Go, Rust) interpreted'a göre verimli
- Lazy evaluation, vectorization

### 3. Carbon Awareness
> Düşük-karbon zaman/yerde çalış.

**Pratik:**
- Batch job'ları gece (rüzgar fazla, talep az) çalıştır
- Trainging job'u carbon-low region'da yap

### 4. Hardware Efficiency
> Eski hardware'i daha verimli kullan; gereksiz yenilemekten kaçın.

**Pratik:**
- "Embodied carbon" hardware üretiminden = uzun ömürlü server
- Refurbished hardware on-prem
- Cloud'da utilization artır → daha az fiziksel server

### 5. Measurement
> Ölçmediğini iyileştiremezsin.

**Pratik:**
- SCI metric (aşağıda)
- Cloud Carbon Footprint
- Kepler (eBPF tabanlı pod-level energy)

### 6. Climate Commitments
> Şirketinin commitment'larını anla, destekle.

**Pratik:** ISO 14064, GHG Protocol, SBTi (Science Based Targets initiative).

### 7. Networking
> Data movement = enerji. Minimize et.

**Pratik:**
- CDN (origin'den uzaklaştır)
- Compression
- Smaller payload (Protobuf vs JSON, gRPC)
- Cache aggressive

### 8. Demand Shaping
> Uygulamayı yüke karşı esnek tasarla.

**Pratik:**
- "Eco mode": düşük öncelik istek arka planda
- Adaptive video quality
- Gece batch yerine real-time

---

## 📊 SCI — Software Carbon Intensity

```
SCI = ((E × I) + M) / R

E = Energy (kWh)              uygulamanın tükettiği elektrik
I = Carbon Intensity (gCO₂eq/kWh)  region+saat bazında elektriğin karbonu
M = Embodied carbon (gCO₂eq)  hardware'in üretiminden gelen karbon (amorti)
R = functional unit           1000 request, 1 user, 1 transaction…

Birim: gCO₂eq / functional unit

Hedef: SCI'ı **azalt**. ASLA "compensate" / offset değil — sadece azaltma sayar.
```

### Örnek hesap
| Aşama | Değer |
|---|---|
| E (kWh) | 100 |
| I (gCO₂/kWh, eu-west-1 ortalama) | 250 |
| M (kg CO₂, server lifecycle) | 1500 |
| R (request) | 10,000,000 |
| **SCI** | (100 × 250 + 1500) / 10,000,000 = **2.65 gCO₂/req** |

> 🔑 **Hedef trend olarak düşürmek**, mutlak rakam değil. Year-over-year %20 azalma "iyi".

---

## 🔧 SCI'ı Mühendisliğe Bağlamak

### Kim ölçer?
| Tool | Ne ölçer | Lisans |
|---|---|---|
| **Cloud Carbon Footprint** | Cloud (AWS, GCP, Azure) — bill bazlı | Apache 2 |
| **Kepler** | K8s pod energy (eBPF) | Apache 2 |
| **Scaphandre** | VM/server energy (RAPL) | Apache 2 |
| **AWS Customer Carbon Footprint Tool** | AWS native | Free, AWS only |
| **GCP Carbon Footprint** | GCP native | Free, GCP only |
| **Azure Emissions Impact Dashboard** | Azure native | Free, Azure only |
| **Boavizta API** | Hardware embodied carbon | OSS |

### Kepler kurulum
```bash
helm install kepler kepler/kepler \
  -n kepler --create-namespace \
  --set serviceMonitor.enabled=true
```

Prometheus metrikleri:
```promql
# Pod başına joule
kepler_container_joules_total{pod_name="<POD>"}

# Namespace başına watt-saat (1 saat penceresinde)
sum by (namespace) (
  rate(kepler_container_joules_total[1h])
) / 3600
```

### Grafana Sustainability Dashboard
- Cluster total carbon (gCO₂/saat)
- Per-namespace breakdown
- Top 10 carbon-heavy pod
- Trend (haftalık)

---

## 🌍 Region Seçimi — Karbon Yoğunluğu

Cloud region'ları **anlık** karbon yoğunluğu farkı **5-10x** olabilir.

### 2026 düşük-karbon region önerileri

| Cloud | Region | Notlar |
|---|---|---|
| AWS | `eu-north-1` (Stockholm) | Hidroelektrik + nükleer |
| AWS | `us-west-2` (Oregon) | Hidroelektrik |
| AWS | `eu-west-3` (Paris) | Nükleer ağırlıklı |
| GCP | `europe-north1` (Finland) | Rüzgar + nükleer |
| GCP | `europe-west1` (Belgium) | Mix, %85+ yenilenebilir |
| Azure | `Sweden Central` | Hidroelektrik |
| Azure | `North Europe` (Ireland) | Rüzgar |

### Anti-örnek (yüksek karbon)
- AWS `ap-southeast-3` (Jakarta) — kömür ağırlıklı
- AWS `cn-north-1` (Beijing) — kömür ağırlıklı

> ⚠️ **Latency vs carbon tradeoff:** Müşteri Türkiye'deyse `eu-central-1`
> (Frankfurt) latency için iyi ama karbon olarak `eu-north-1`'den fazla.
> Karar matrisine ekle.

### Cloud Carbon Footprint kullanımı
```bash
# Cloud Carbon Footprint AWS billing'i tarar
docker run --rm \
  -e AWS_ACCESS_KEY_ID=... -e AWS_SECRET_ACCESS_KEY=... \
  cloudcarbonfootprint/cloud-carbon-footprint:latest

# Web UI: localhost:4000
```

---

## ⚡ Carbon-Aware Computing

### Pattern: "düşük karbon saatlerde batch çalıştır"

```yaml
# CronJob: rüzgar yoğun saatlerde çalış (gece)
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly-rebuild
spec:
  schedule: "0 2 * * *"  # 02:00 — düşük talep, fazla rüzgar
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: rebuild
              image: <APP>
```

### Daha akıllı: dinamik scheduler
**Carbon Aware SDK** (Microsoft, GSF) — ElectricityMaps API ile real-time karbon yoğunluğunu okur:

```yaml
# GitHub Actions
jobs:
  carbon-aware-rebuild:
    runs-on: ubuntu-latest
    if: ${{ steps.carbon.outputs.intensity == 'low' }}
    steps:
      - id: carbon
        uses: green-software-foundation/carbon-aware-action@<VERSION>
        with:
          location: 'eu-north-1'
          window: '6h'
      - run: ./expensive-rebuild.sh
```

### KEDA carbon scaler
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: carbon-aware-batch
spec:
  scaleTargetRef:
    name: batch-worker
  triggers:
    - type: external
      metadata:
        scalerAddress: carbon-aware-scaler:8080
        location: "eu-west-1"
        intensity-threshold: "200"   # gCO₂/kWh altıysa scale up
```

---

## 🔧 Quick Wins (Hızlı Etki)

| Aksiyon | Tasarruf (kabaca) | Süre |
|---|---|---|
| **Idle resource cleanup** (kullanılmayan EC2, EBS, RDS) | %10-30 | 1 hafta |
| **ARM/Graviton'a geçiş** (uygun workload) | %20-40 watt | 2-4 hafta |
| **Spot instance** (idle kapasite) | %70 maliyet, ekstra hardware üretmiyor | 1-2 hafta |
| **Right-sizing** (over-provisioned'ı küçült) | %20 | 2 hafta |
| **Cron scaler dev/staging** (gece kapalı) | %60 dev maliyeti | 3 gün |
| **Compression** (HTTP gzip/brotli) | %5-15 network | 1 gün |
| **Image tag immutable + cache** | Build re-run azalır | 1 gün |
| **CDN** (static asset edge'e) | %20-40 origin trafik | 1-2 hafta |
| **Cold tier** (eski log → S3 Glacier) | %80 storage maliyeti | 1 hafta |
| **Database autovacuum + bloat cleanup** | %15 disk + IO | 1 gün |

> 🔑 **Quick win listesi cost ↔ carbon dual'i.** FinOps + Sustainability
> aynı eylemleri çoğu zaman önerir.

---

## 🧪 CI'da Carbon Gate

```yaml
# .github/workflows/sustainability-check.yml
name: Sustainability Check

on: [pull_request]

jobs:
  bundle-size:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>
      - run: npm ci && npm run build
      - uses: andresz1/size-limit-action@<VERSION>
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}

  image-size:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>
      - run: docker build -t <APP>:test .
      - id: size
        run: |
          SIZE=$(docker image inspect <APP>:test --format '{{.Size}}')
          echo "size=$SIZE" >> $GITHUB_OUTPUT
          if [ $SIZE -gt 100000000 ]; then
            echo "::error::Image > 100 MB, sustainability budget aşıldı"
            exit 1
          fi
```

> 🔑 Bundle size, image size, dependency count — proxy metrikler. SCI tam
> ölçemiyorsan bunlar **iyi başlangıç**.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "Carbon offset alıyoruz" | Pazarlama, gerçek azalma yok | Önce **azalt**, sonra residual'i offset (niye offset >> azalma kabul edilmiyor) |
| 4 vCPU allocate, %5 kullanım | Gereksiz embodied carbon + idle | Right-sizing, HPA, VPA |
| Always-on dev env | Hafta sonu boşa watt | Cron scaler |
| Region seçimi sadece latency | Karbon ihmal edilir | Karar matrisine carbon ekle |
| Logging her şeyi "olur belki" | Storage = enerji | Severity filter, retention policy |
| `:latest` tag → CI cache miss | Aynı build N kez | Digest pin + cache |
| 4 GB Docker image | Pull başına bandwidth + storage | Distroless, multi-stage |
| Test her şeyi her PR'da | CPU israf | Selective testing, change-based |
| Synchronous I/O hot path'te | CPU bekler | Async / batched |
| Cache'siz database query | Aynı sonuç N kez compute | Redis cache, materialized view |
| HDD on-prem, %10 kullanım | Embodied carbon yüksek, watt yüksek | Konsolide → daha az server, daha çok kullanım |

---

## 📋 Sustainability Engineering Checklist

```
[ ] Cloud Carbon Footprint kurulu, dashboard görünür
[ ] Kepler veya equivalent K8s pod-level energy
[ ] SCI metric tanımlı, baseline ölçülmüş
[ ] Quarterly: SCI trend report (yöneticilere)
[ ] Region seçim matrisi: latency + carbon + cost
[ ] ARM/Graviton (Java, Go, Python uygun) migration tamamlandı
[ ] Spot instance: %30+ workload
[ ] Idle resource cleaner cron (haftalık)
[ ] Right-sizing: VPA + manuel review
[ ] Dev cluster gece kapanır (cron scaler)
[ ] CDN: static asset edge'e
[ ] Cold tier: 90+ gün log S3 Glacier
[ ] Bundle size budget CI'da gate
[ ] Image size budget CI'da gate
[ ] Carbon-aware batch (rüzgar saatlerinde)
[ ] Hardware lifecycle policy (4-5 yıl, sonra refurbish)
[ ] Carbon report müşteri tarafına (B2B müşteri talebi)
[ ] CSRD raporlama hazırlığı (büyük şirket ise)
[ ] Quarterly: yeşil yazılım eğitimi (mühendis on-boarding)
```

---

## 📚 Referanslar

- **Green Software Foundation** — greensoftware.foundation
- **Principles** — principles.green
- **SCI Spec** — sci.greensoftware.foundation
- **Cloud Carbon Footprint** — cloudcarbonfootprint.org
- **Kepler** — sustainable-computing.io
- **Climate Action Tech** — climateaction.tech
- **Boavizta** — boavizta.org
- **ElectricityMaps API** — electricitymaps.com
- **AWS Customer Carbon Footprint Tool**
- **GCP Carbon Footprint**
- **Azure Emissions Impact Dashboard**
- [`Carbon-Aware-Computing.md`](Carbon-Aware-Computing.md)
- [`Measuring-Software-Carbon.md`](Measuring-Software-Carbon.md)
- [`Region-Selection.md`](Region-Selection.md)
- [`12-FinOps/Cloud-Cost-Allocation.md`](../12-FinOps/Cloud-Cost-Allocation.md) — cost ↔ carbon dual

---

> *"Yeşil yazılım 'opsiyonel iyilik' değil, **mühendislik disiplini**.
> Bir kararın 'cost', 'latency', 'security' boyutunu sorduğun gibi
> 'carbon' boyutunu sorulmaz hale getirme."*
