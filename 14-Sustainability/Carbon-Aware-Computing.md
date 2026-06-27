---
description: "Carbon-aware workload scheduling rehberi: isin ne zaman ve nerede calisacagini sebekenin anlik karbon yogunluguna gore secme, gercek zamanli API'lar, K8s ve CI ornekleri."
---
# Carbon-Aware Computing — Düşük-Karbon Saatte Çalış

> *"Aynı işi rüzgârlı bir gece çalıştırmak ile fosil yakıt yüklü
> bir öğleden sonra çalıştırmak — **CO₂ açısından 5x fark**.
> Workload'un zamanını + yerini seçebilen mühendis, **emisyon
> azaltmasının kontrolünü** elinde tutar."*

Bu rehber **carbon-aware** workload scheduling pattern'lerini, gerçek
zamanlı karbon yoğunluğu API'larını, ve K8s/CI'da nasıl uygulayacağını
somut örneklerle anlatır.

---

## 🎯 Carbon-Aware Computing Nedir?

> **Carbon-Aware**: Bir işin **ne zaman** ve **nerede** çalışacağını
> elektrik şebekesinin **anlık karbon yoğunluğuna** göre seçmek.

```
[Workload]
    │
    ├── Time-shift: "şimdi karbon yoğun, 3 saat sonra çalış"
    │   (batch işler, gece rüzgârı, gündüz güneşi)
    │
    └── Location-shift: "Frankfurt yerine Stockholm'de çalış"
        (region başına farklı karbon yoğunluğu)
```

---

## 📊 Karbon Yoğunluğu Nedir?

> **Carbon Intensity**: 1 kWh elektrik üretmek için **kaç gram CO₂**
> yayıldı? (g CO₂eq/kWh)

| Kaynak | Yaklaşık intensity |
|---|---|
| Hidroelektrik | 5-50 |
| Nükleer | 5-20 |
| Rüzgâr | 10-15 |
| Güneş | 50-90 |
| Doğalgaz | 400-500 |
| Kömür | 800-1000+ |

### Region anlık değişir
- **Almanya**: günün saatine göre 200-600 g/kWh
- **Stockholm**: 20-50 g/kWh (hidro+nükleer ağırlıklı)
- **Polonya**: 600-800 g/kWh (kömür ağırlıklı)
- **Texas**: 300-500 g/kWh (rüzgâr/gaz mixed)

---

## 🛠️ Karbon Yoğunluğu API'ları

| API | Coverage | Ücret |
|---|---|---|
| **ElectricityMaps** | Global | Free tier + ticari |
| **WattTime** | US ağırlıklı | Free + paid |
| **Carbon Aware SDK** (Microsoft/GSF) | Multi-source aggregator | Free, OSS |
| **AWS Customer Carbon Footprint Tool** | AWS | Free, AWS only |
| **GCP Carbon Footprint** | GCP | Free, GCP only |

### ElectricityMaps API
```bash
curl "https://api.electricitymap.org/v3/carbon-intensity/latest?zone=DE" \
  -H "auth-token: <TOKEN>"
```

```json
{
  "zone": "DE",
  "carbonIntensity": 425,
  "datetime": "2026-05-04T14:00:00.000Z",
  "updatedAt": "2026-05-04T14:05:00.000Z",
  "emissionFactorType": "lifecycle",
  "isEstimated": false,
  "estimationMethod": null
}
```

```bash
# Forecast (gelecek 24 saat)
curl "https://api.electricitymap.org/v3/carbon-intensity/forecast?zone=DE" \
  -H "auth-token: <TOKEN>"
```

---

## 🕐 Pattern 1: Time-Shifting (Batch Job)

> "İdeal cron 02:00, ama elektrik o saatte daha temiz".

### GitHub Actions ile
```yaml
name: Carbon-Aware ML Training

on:
  schedule:
    - cron: '0 1 * * *'   # ilk denemesi 01:00
  workflow_dispatch:

jobs:
  check-carbon:
    runs-on: ubuntu-latest
    outputs:
      should_run: ${{ steps.check.outputs.should_run }}
    steps:
      - id: check
        run: |
          INTENSITY=$(curl -s "https://api.electricitymap.org/v3/carbon-intensity/latest?zone=DE" \
            -H "auth-token: ${{ secrets.EMAPS_TOKEN }}" \
            | jq '.carbonIntensity')

          if [ "$INTENSITY" -lt 200 ]; then
            echo "should_run=true" >> $GITHUB_OUTPUT
          else
            echo "should_run=false" >> $GITHUB_OUTPUT
            echo "Karbon yoğunluğu $INTENSITY > 200, ertelendi"
          fi

  ml-training:
    needs: check-carbon
    if: needs.check-carbon.outputs.should_run == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>
      - run: ./train.sh
```

### Carbon Aware SDK
```yaml
# GitHub Actions
- uses: green-software-foundation/carbon-aware-sdk-action@<VERSION>
  with:
    location: 'eu-north-1'
    duration: '60'   # 60 dakikalık iş
    window: '6h'     # 6 saat içinde uygun zamanı bul
  id: carbon

- name: Wait until best time
  run: sleep ${{ steps.carbon.outputs.wait_seconds }}

- name: Run job
  run: ./expensive-task.sh
```

---

## 🌍 Pattern 2: Location-Shifting

### Multi-region replicas
Workload **birden fazla region**'da hazır → karbon yoğunluğu en düşüğüne yönlendir.

```yaml
# Örnek: ML training EKS cluster'larında
# eu-north-1 (Stockholm) ↔ eu-central-1 (Frankfurt) ↔ us-west-2 (Oregon)

# Her region'ın karbon yoğunluğunu çek
INTENSITIES=$(for region in eu-north-1 eu-central-1 us-west-2; do
  ZONE=$(map_region_to_zone "$region")
  INTENSITY=$(curl -s ".../carbon-intensity/latest?zone=$ZONE" -H "auth-token: $TOKEN" | jq '.carbonIntensity')
  echo "$region $INTENSITY"
done)

# En düşüğünü seç
BEST=$(echo "$INTENSITIES" | sort -k2 -n | head -1 | awk '{print $1}')

# Job'u oraya gönder
kubectl --context $BEST apply -f training-job.yaml
```

> 🔑 **Latency-critical değilse** location-shift büyük kazanç — özellikle batch.

---

## ⚡ Pattern 3: Demand Shaping

> Trafik **rıza ile** ertelenebilir mi?

### "Eco mode" feature
```python
# Kullanıcıya iki seçenek
@app.route('/api/render-video', methods=['POST'])
def render_video():
    if request.json.get('eco_mode'):
        # Düşük öncelik queue'ya at, gece çalıştır
        eco_queue.enqueue(render_task, request.json)
        return jsonify({"status": "queued", "estimated": "tomorrow morning"})
    else:
        # Hemen yap (yüksek karbon olabilir)
        return render_task(request.json)
```

### Adaptive video quality (Netflix-tarzı)
- Rüzgâr yoğun → 4K
- Karbon yoğun → 1080p (transcode + bandwidth tasarrufu)
- Kullanıcı kontrol edebilir ("eco-stream" toggle)

---

## 🔧 Pattern 4: KEDA Carbon Scaler

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: carbon-aware-batch-worker
  namespace: ml
spec:
  scaleTargetRef:
    name: ml-batch-worker
  minReplicaCount: 0
  maxReplicaCount: 10
  triggers:
    - type: external
      metadata:
        scalerAddress: carbon-aware-scaler:8080
        location: 'eu-north-1'
        intensityThreshold: '150'   # < 150 g/kWh ise scale up
        # Scale down trigger: > 400 g/kWh
        intensityThresholdHigh: '400'
```

→ Karbon düşükken çalış, yüksekken bekle.

> Cilium ekosisteminde **KEDA carbon scaler** community projesi var.

---

## 📊 Workload Sınıflandırması

Tüm workload carbon-aware olamaz. Karar matrisi:

| Workload tipi | Latency hassasiyeti | Carbon-aware uygunluğu |
|---|---|---|
| User-facing API | Yüksek | ❌ Hayır (location-shift olabilir) |
| Background queue (saatlik) | Düşük | ✅ Evet (time-shift ideal) |
| ML training | Çok düşük | ✅✅ Çok uygun |
| Batch ETL | Düşük | ✅ Evet |
| Cron job (gecelik) | Orta | ✅ Evet |
| Build CI | Orta | ⚠️ Sınırlı (dev'leri bekletme) |
| Backup | Düşük | ✅ Evet |
| Real-time streaming | Yüksek | ❌ Hayır |
| Data analytics dashboard refresh | Düşük | ✅ Evet |

> 🔑 **Hedef**: Latency-tolerant workload'ları carbon-aware yap. Critical path'i etkileme.

---

## 📉 Ölçüm — Tasarruf Ne Kadar?

### Baseline + Carbon-aware karşılaştırma
```python
# Aynı workload 1 hafta non-aware, 1 hafta aware
non_aware_emissions = sum([
    energy_kwh[hour] * intensity_at_hour[hour]
    for hour in non_aware_run_hours
])

aware_emissions = sum([
    energy_kwh[hour] * intensity_at_hour[hour]
    for hour in aware_run_hours  # düşük-karbon saatler
])

reduction_pct = (non_aware_emissions - aware_emissions) / non_aware_emissions * 100
# Tipik: %20-50 reduction
```

### Grafana panel
```promql
# Carbon-aware tasarruf (cumulative)
sum(increase(workload_co2_grams_saved_total[7d]))
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tüm workload'u carbon-aware sanmak | Latency-critical user-facing düşer | Workload sınıflandır |
| Time-shift sadece "gece" sabit | Hava değişir, esnek değil | Real-time API + window |
| Location-shift veri ihracı yok düşünmek | KVKK/GDPR ihlali | Veri residency check |
| Manuel cron, "umarım o saatte düşüktür" | Forecast yok | API-driven scheduling |
| Carbon API rate limit unutuldu | Çağrı limiti aşılır | Cache + minutely poll |
| Tasarruf ölçülmüyor | "Yeşil yapıyoruz" iddia | Baseline + raporlama |
| User'a transparency yok | "Eco mode" kapalı bile karar | Opt-in, görünür |
| Forecast'a güven, gerçek poll yok | Sürpriz değişim | Hourly re-check |
| Carbon API tek kaynak (ElectricityMaps) | API down → fallback yok | Multi-source aggregator |

---

## 📋 Carbon-Aware Adoption Checklist

```
[ ] Workload sınıflandırması: latency-tolerant olanlar belirlendi
[ ] Carbon-aware uygun ilk 3 workload seçildi (öncelik)
[ ] ElectricityMaps / WattTime / Carbon Aware SDK token
[ ] Time-shift: GitHub Actions / Cron + intensity check
[ ] Location-shift: multi-region failover ya da batch routing
[ ] KEDA carbon scaler (K8s batch için)
[ ] User-facing "eco mode" opt-in (uygunsa)
[ ] Demand shaping: video quality, batch defer
[ ] Ölçüm: baseline + carbon-aware tasarruf reporting
[ ] Veri residency: location-shift KVKK uyumlu
[ ] Multi-source carbon API (fallback)
[ ] Quarterly: tasarruf raporu yöneticilere
[ ] Documentation: developer'lar carbon-aware bilinçli
```

---

## 📚 Referanslar

- **Green Software Foundation — Carbon Aware** — greensoftware.foundation/articles/carbon-aware
- **ElectricityMaps API** — electricitymaps.com
- **WattTime API** — watttime.org
- **Carbon Aware SDK (Microsoft)** — github.com/Green-Software-Foundation/carbon-aware-sdk
- **CNCF Sustainability TAG** — github.com/cncf/tag-environmental-sustainability
- [`Green-Software-Principles.md`](Green-Software-Principles.md)
- [`Measuring-Software-Carbon.md`](Measuring-Software-Carbon.md)
- [`Region-Selection.md`](Region-Selection.md)
- [`12-FinOps/Cloud-Cost-Allocation.md`](../12-FinOps/Cloud-Cost-Allocation.md) — cost ↔ carbon dual

---

> *"Carbon-aware computing 'her şeyi geç çalıştır' değil — **akıllı
> erteleme**. Latency-tolerant workload'ları rüzgâr saatlerine
> shift etmek, **20-50% emisyon azaltır** — kullanıcının hiç fark
> etmeyeceği bir kazanç."*
