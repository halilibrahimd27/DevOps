# Region Selection — Cloud Region Karbon Karar Matrisi

> *"Aynı workload'u Frankfurt yerine Stockholm'de çalıştırmak %60
> emisyon azaltır — **bedava**. Latency 10ms artar, müşteri fark etmez,
> şirketin Scope 2 raporu **dramatik düşer**."*

Bu rehber AWS, GCP, Azure region'larını **karbon yoğunluğuna** göre
karşılaştırır, latency/maliyet/data-residency trade-off'unu nasıl
değerlendireceğini, ve karar matrisi nasıl kuracağını anlatır.

---

## 🎯 Bir Cloud Region "Ne Kadar Yeşil"?

```
[Region]
   │
   ├── Elektrik şebekesi (kömür/gaz/rüzgâr/güneş/nükleer/hidro mix)
   ├── Cloud sağlayıcının PPA (Power Purchase Agreement) — yenilenebilir kontratları
   ├── PUE (Power Usage Effectiveness) — datacenter verimliliği
   └── Cooling kaynağı (su / hava / serbest soğutma)
```

> 🔑 **Karbon yoğunluğu region'a göre 5-10x değişir.** Yıllık ortalama
> 20-800 g CO₂/kWh aralığında.

---

## 📊 2026 Düşük-Karbon Region'lar

### AWS
| Region | Şehir | Yaklaşık intensity (g/kWh) | Notlar |
|---|---|---|---|
| `eu-north-1` | Stockholm | 20-40 | Hidro + nükleer |
| `eu-west-3` | Paris | 50-90 | Nükleer ağırlıklı |
| `us-west-2` | Oregon | 100-200 | Hidro + bazı gaz |
| `ca-central-1` | Montreal | 30-60 | Hidro |
| `eu-west-1` | Ireland | 200-350 | Rüzgâr ama gaz da var |
| `eu-central-1` | Frankfurt | 350-500 | Mixed, gaz/kömür var |
| `ap-southeast-3` | Jakarta | 700-900 | Kömür ağırlıklı ❌ |
| `cn-north-1` | Beijing | 600-800 | Kömür ❌ |

### GCP
| Region | Şehir | Yaklaşık intensity |
|---|---|---|
| `europe-north1` | Hamina, FI | 30-60 |
| `europe-west1` | Belgium | 100-200 |
| `europe-west4` | Netherlands | 200-300 |
| `us-west1` | Oregon | 100-200 |
| `us-central1` | Iowa | 400-500 |

### Azure
| Region | Şehir | Yaklaşık intensity |
|---|---|---|
| `swedencentral` | Sandviken | 20-40 |
| `northeurope` | Dublin | 200-350 |
| `francecentral` | Paris | 50-100 |
| `westus2` | Washington | 100-200 |

> ⚠️ Bu rakamlar **dönemsel ortalama**. Real-time için ElectricityMaps API.

---

## ⚖️ Karar Matrisi — 4 Boyut

| Boyut | Soru |
|---|---|
| **Latency** | Müşterilere yakın mı? |
| **Cost** | Region başına fiyat farkı? |
| **Data Residency** | Hukuki gereklilik (KVKK/GDPR)? |
| **Carbon** | Karbon yoğunluğu? |

### Karar matrisi tablosu (örnek: TR müşteri)
| Region | Latency (ms) | Cost ($/CPU-h) | Residency | Carbon (g/kWh) |
|---|---|---|---|---|
| eu-central-1 (Frankfurt) | 50 | 0.045 | EU ✅ | 400 |
| eu-west-1 (Ireland) | 70 | 0.040 | EU ✅ | 280 |
| eu-north-1 (Stockholm) | 90 | 0.039 | EU ✅ | **30** |
| eu-west-3 (Paris) | 70 | 0.043 | EU ✅ | 80 |

> 🎯 **Karar**: Türkiye'den eu-north-1 (Stockholm) — latency 90ms, müşteri
> tolere eder, **karbon 13x daha düşük**. Maliyet de %15 ucuz.

---

## 🌳 Karar Akışı

```
1. Hangi müşteri segment'i? Latency hassasiyeti?
   - < 100ms gerekli → yakın region
   - 100-300ms tolere → uzak region OK

2. Data residency yasal gereklilik var mı?
   - KVKK/GDPR → EU
   - Sağlık verisi → ek kısıtlar (ülke içi)

3. Carbon-aware seçenek?
   - Aynı residency içinde en düşük karbon

4. Cost karşılaştır
   - Genelde yeşil region daha ucuz (subsidized renewable)

5. Multi-region ihtiyaç?
   - DR için ikinci region da yeşil seç
```

---

## 🛠️ Mevcut Workload'ı Migrate Etmek

### Aşamalı plan
```
1. Hafta — Audit
   - Hangi workload'lar mevcut region'da?
   - Latency-sensitive vs tolerant?
   - Data residency zorunlu mu?

2-4. Hafta — Plan
   - Hedef region seç (karar matrisi ile)
   - Migration plan: state, secret, data
   - Maliyet modellemesi

5-12. Hafta — Migrate
   - Stateless workload'lar önce (kolay)
   - DB son (replica → switchover)
   - DNS / CDN routing
   - Aşamalı: %10 → %50 → %100

13. Hafta — Sunset
   - Eski region kapanış
   - Cost saving + carbon saving rapor
```

### Uygulanabilir göç adayları
| Workload | Migration zorluğu |
|---|---|
| CI runner | Düşük (stateless) |
| Backup storage | Düşük (object store) |
| ML training | Düşük (batch) |
| Stateless API | Orta (DNS, app config) |
| Database | Yüksek (state, downtime) |
| User-facing primary | Yüksek (latency etkisi) |

> 🔑 **İlk hedef**: ML training + batch + backup. **En son**: user-facing DB.

---

## 📊 Real-Time Region Seçimi (Carbon-Aware)

### Multi-region replica + dinamik routing
```python
# Pseudocode: ML training scheduler
import requests

def select_best_region(zones=['DE', 'SE', 'FR', 'IE']):
    intensities = {}
    for zone in zones:
        r = requests.get(
            f'https://api.electricitymap.org/v3/carbon-intensity/latest?zone={zone}',
            headers={'auth-token': TOKEN}
        ).json()
        intensities[zone] = r['carbonIntensity']
    
    return min(intensities, key=intensities.get)

# Job submit
zone = select_best_region()
region = ZONE_TO_REGION[zone]   # SE → eu-north-1
submit_training_job(region=region)
```

### KEDA + carbon scaler (yukarıdaki Carbon-Aware-Computing rehberi)
- Region başına replica
- Düşük karbon olanı scale up
- Yüksek karbon olanı scale to zero

---

## 🌍 Türkiye Özel — "Yerli Bulut" Tartışması

### TR'de bulut bölgeleri (2026)
- **AWS Türkiye**: yok (lobby var, yakında olabilir)
- **Azure Türkiye**: yakında (announced)
- **GCP Türkiye**: yok
- **Yerel cloud sağlayıcılar**: Turkcell, Türk Telekom, Vodafone

### KVKK + data residency
- Public sector: TR içinde data zorunluluğu olabilir
- Private B2B: KVKK'ya göre genelde EU'da OK (yeterli koruma değerlendirilir)

### Yerel sağlayıcı vs hyperscale
| Boyut | Yerel | Hyperscale (AWS/GCP/Azure) |
|---|---|---|
| Latency | Düşük | Orta-yüksek (Frankfurt 50ms) |
| Maliyet | Genelde daha düşük | Spot fiyatlar var |
| Servis çeşitliliği | Sınırlı | Geniş |
| Carbon transparency | Düşük | Yüksek |
| Renewable PPA | Belirsiz | Açıklamalı |
| KVKK uyumu | ✅ İçeride | ⚠️ Yeterli koruma + SCC |

> 🔑 Pratik: çoğu workload AB region'larda OK. Public sector veya
> hassas TR-only veri için yerel cloud + EU DR.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Region seçimi sadece latency | Carbon ihmal | 4-boyut karar matrisi |
| "Default region" otomatik | İlk gün eu-central, sonsuza kadar | Bilinçli seçim |
| Carbon transparency yok vendor'da | Ölçemezsin | Vendor sertifikalarını sor |
| US region + EU müşteri | Schrems II / GDPR ihlali | EU residency |
| TR-only veri AB region'da | KVKK yorumu | Hukuk + SCC + technical safeguard |
| Migration big-bang | Production'da kırılma | Aşamalı + canary |
| Multi-region failover yapılmamış | DR eksik | Per-cloud, per-residency 2 region |
| Carbon-aware sadece batch | Stateless API'de de mümkün | Multi-region routing |
| Yerel cloud "milli" diye seç | Carbon transparency yok | Aynı disipline tabi tut |
| Maliyet sadece compute | Network egress ihmal | TCO: compute + network + storage |

---

## 📋 Region Selection Checklist

```
[ ] 4-boyut karar matrisi (latency + cost + residency + carbon)
[ ] Real-time karbon intensity (ElectricityMaps token)
[ ] Cloud Carbon Footprint dashboard
[ ] Vendor PPA / renewable transparency belgeleri
[ ] Data residency: KVKK + GDPR uyum check
[ ] Multi-region: en az 2 yeşil region (DR + carbon-aware)
[ ] Migration plan: aşamalı (stateless → stateful)
[ ] Latency baseline: müşteri segment'leri için
[ ] Cost karşılaştırması: aynı workload farklı region'da
[ ] Annual: region review (yeni yeşil region'lar?)
[ ] Quarterly: carbon report (region başına emisyon)
[ ] CI/CD: region değişikliği policy gate (yanlışlıkla kömür region seçilmesin)
```

---

## 📚 Referanslar

- **AWS Sustainability** — sustainability.aboutamazon.com
- **GCP Carbon-Free Energy %** — cloud.google.com/sustainability
- **Azure Sustainability** — azure.microsoft.com/en-us/global-infrastructure/sustainability
- **ElectricityMaps** — electricitymaps.com
- **The Green Web Foundation — Carbon.txt** — thegreenwebfoundation.org
- [`Green-Software-Principles.md`](Green-Software-Principles.md)
- [`Carbon-Aware-Computing.md`](Carbon-Aware-Computing.md)
- [`Measuring-Software-Carbon.md`](Measuring-Software-Carbon.md)
- [`19-Compliance/KVKK-Practical.md`](../19-Compliance/KVKK-Practical.md) — data residency
- [`12-FinOps/Cloud-Cost-Allocation.md`](../12-FinOps/Cloud-Cost-Allocation.md) — TCO

---

> *"Region seçimi 'altyapı tercihi' değil — **karbon strateji
> kararı**. Yeşil region seçimi tek tıkla, **20-50% emisyon
> kazanç**: hiçbir kod değişikliği gerektirmeyen, **anında**
> uygulanan yeşil pratik."*
