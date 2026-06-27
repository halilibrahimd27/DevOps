---
description: "Surdurulebilir muhendislik ve Green IT bolum indeksi: GSF 8 prensibi, carbon-aware computing, SCI olcumu, dusuk-karbon region secimi ve verimlilik pratikleri rehberleri."
---
# 14 · Sustainable Engineering / Green IT

> *"Software is **never** carbon-neutral; it's just CO₂ that you decided
> not to measure."* — Green Software Foundation

2026'da yasal zorunluluk: AB CSRD, ABD SEC iklim kuralı emisyon raporlatıyor.
Cloud kullanımı = Scope 2/3 emisyon.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`Green-Software-Principles.md`](Green-Software-Principles.md) | GSF 8 prensibi, mühendislik kararlarına nasıl yansır |
| [`Carbon-Aware-Computing.md`](Carbon-Aware-Computing.md) | "Düşük-karbon saatlerde batch çalıştır" pattern'i |
| [`Measuring-Software-Carbon.md`](Measuring-Software-Carbon.md) | SCI formula, Cloud Carbon Footprint, Kepler |
| [`Region-Selection.md`](Region-Selection.md) | Yenilenebilir enerji yoğun region'lar (cloud-spesifik) |
| [`Efficiency-Practices.md`](Efficiency-Practices.md) | ARM/Graviton, idle cleanup, caching, compression |

## Green Software Foundation 8 prensibi

1. **Carbon Efficiency** — daha az emisyonla aynı işi yap
2. **Energy Efficiency** — daha az watt kullan
3. **Carbon Awareness** — düşük-karbon zaman/yerde çalıştır
4. **Hardware Efficiency** — eski hardware'i daha verimli kullan
5. **Measurement** — ölçmediğini iyileştiremezsin
6. **Climate Commitments** — çekiştirici şirket commitments'ı destekle
7. **Networking** — data movement = enerji; minimize et
8. **Demand Shaping** — uygulamayı yüke karşı esnek tasarla

## SCI (Software Carbon Intensity) formula

```
SCI = ((E × I) + M) / R

E = Energy (kWh)              uygulamanın tükettiği elektrik
I = Carbon Intensity (gCO₂/kWh) elektriğin karbon yoğunluğu (region+saat)
M = Embodied carbon (gCO₂)    hardware'in üretimden gelen karbonu
R = functional unit           1000 request, 1 user, 1 transaction...

→ Birim: gCO₂eq / functional unit
→ Hedef: SCI'ı minimize et (artırmadan, sadece azaltabilirsin)
```

## Pratik uygulama

### Region seçimi (örnek — emisyon yoğunluğuna göre)

| Cloud | Düşük karbon region'ları (~ 2026) |
|---|---|
| AWS | `eu-north-1` (Stockholm), `eu-west-3` (Paris), `us-west-2` (Oregon) |
| Azure | `Sweden Central`, `North Europe`, `France Central` |
| GCP | `europe-north1` (Finland), `europe-west1` (Belgium), `us-west1` (Oregon) |

> ⚠️ Emisyon yoğunluğu **anlık** değişir (rüzgar/güneş üretimi). Cloud
> sağlayıcının "Customer Carbon Footprint Tool" çıktısı ile region'ları doğrula.

### Carbon-aware scheduling örneği

```yaml
# CI'da idle batch job — carbon-aware, low-emission saatte çalıştır
jobs:
  carbon-aware-rebuild:
    runs-on: ubuntu-latest
    if: ${{ steps.carbon.outputs.intensity == 'low' }}
    steps:
      - id: carbon
        uses: green-software-foundation/carbon-aware-action@v1
        with:
          location: 'eu-north-1'
          window: '6h'
      - run: ./expensive-rebuild.sh
```

### Quick wins

- ✅ **ARM/Graviton instance**'lara geç — per-watt 2-4x daha verimli
- ✅ **Spot instance** — idle kapasiteyi kullan, yeni hardware üretmez
- ✅ Idle resource cleanup — kullanılmayan watt kapatılan watt
- ✅ **Compression** — daha az network bytes = daha az enerji
- ✅ **CDN** — origin'den uzaklaştırma = path tasarrufu
- ✅ Dev cluster'larını **gece kapat** (cron scaler)

## Anti-pattern'ler

- ❌ "Carbon offset alıyoruz" → measurement yok, sadece pazarlama
- ❌ Sürekli `vCPU=4` allocate ama %5 kullanım
- ❌ "Always-on" dev env'leri haftasonu açık
- ❌ Region seçimi sadece latency'e göre (karbon ihmal edilir)
- ❌ Logging her şeyi "ihtiyacımız olur belki" diye saklamak
