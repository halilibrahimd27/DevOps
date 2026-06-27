---
description: "Skelton & Pais'in Team Topologies kitabından damıtılmış 4 takım türü (stream-aligned, enabling, complicated-subsystem, platform) ve etkileşim modları rehberi."
---

# Team Topologies — Ekip Yapısı Olarak Mühendislik

> *Conway's Law: "Sistemler, tasarlayan organizasyonların iletişim
> yapısını yansıtır."* — yani **ekip yapın = mimarinin kaderidir.**

Skelton & Pais'in *Team Topologies* (2019) kitabından damıtılmış; modern
DevOps & Platform Engineering ekiplerinin **yapı** referansı.

---

## 🎯 4 Takım Türü

### 1. Stream-Aligned Team

> Ürün/iş akışına hizalanmış. **Customer value** üretir.

- Bir end-to-end akışın sahibi (örn: "checkout flow")
- 5-9 kişi (Spotify "squad" boyutu)
- Bütün stack: frontend + backend + DB + observability
- "You build it, you run it" — kendi ürününü üretir, deploy eder, on-call'ı tutar

**Örnek:**
- Payments squad
- Search relevance team
- Mobile checkout team

### 2. Enabling Team

> Stream-aligned ekiplere **kısa süreli yardım** eden uzman ekip.
> Konsültan değil — birlikte çalışır, sonra bırakır.

- Genelde 3-5 kişi
- Bir konuda deep expertise (örn: "performance", "security", "test automation")
- Stream-aligned bir ekibin önündeki engeli kaldırmaya 2-4 hafta gelir
- Sonra ayrılır — ekip kendi başına devam eder

**Örnek:**
- SRE Enabling team — bir ekibin SLO kurmasına yardım eder
- Security Champions team — threat modeling pratiği yaymak

### 3. Complicated Subsystem Team

> Çok teknik bir alt-bileşen — özel uzmanlık gerektiren.
> "İdeal" değil, ama bazen kaçınılmaz.

- 3-5 kişi
- Compiler, ML model, real-time codec, kriptografi
- Kullanım API'si stream-aligned ekiplere

**Örnek:**
- Video transcoding team
- ML training infrastructure team
- Crypto/HSM team

### 4. Platform Team

> Stream-aligned ekiplere **self-service** araçlar sunar.
> "DevOps takımı"nın evrimleşmiş hali.

- 5-15 kişi
- Internal Developer Platform sahip
- Backstage, golden path, CI/CD reusable workflow, monitoring stack
- **Customer = developer** — ürün gibi yönetir (NPS ölçer, roadmap'i var)

> 📚 [`13-Platform-Engineering/`](../13-Platform-Engineering/)

---

## 🤝 3 Etkileşim Modu

İki ekip nasıl konuşur?

### Mode 1: Collaboration

> İki ekip yan yana, **ortak hedef** için kısa süre çalışır.

- Genelde 1-3 ay
- Birlikte tasarlar, birlikte uygular
- Yüksek iletişim yükü
- Sonunda: ya ayrılırlar (X-as-a-Service'e geçer) ya da yeni team kurulur

**Örnek:**
- Yeni bir mikroservis kurarken stream-aligned + platform team

### Mode 2: X-as-a-Service

> Bir ekibin sunduğu hizmet, diğer ekiplerin self-service tükettiği.
> Düşük iletişim yükü.

- Net API / SLA / dokümantasyon
- Tüketici: "ihtiyacım var" → "alın, kullanın"
- Sağlayıcı: backlog'unu yönetir, prioritize eder

**Örnek:**
- Platform team → stream-aligned (CI/CD as a service)
- Identity team → uygulamalar (auth as a service)

### Mode 3: Facilitating

> Enabling team'in karakteristik modu. **Öğretir, koçluk yapar, ayrılır.**

- 2-6 hafta
- "Bu pratik hayatına gir" demek için yan yana
- Bittikten sonra sürdürmek alıcı ekibin sorumluluğu

**Örnek:**
- Performance team → checkout team'e load test pratiği öğretir, sonra ayrılır

---

## 📊 Cognitive Load — Anahtar Kavram

> Bir takımın **akıllarını koruyabileceği** karmaşıklık miktarı sınırlı.
> Aşıldığında: yavaşlama, hata, burnout.

3 türü:

| Tür | Açıklama | Çözüm |
|---|---|---|
| **Intrinsic** | Problem'in özünden gelen (algoritma, domain) | Aza indiremezsin; sadece eğitimle kolaylaşır |
| **Extraneous** | Tooling/process karmaşası | **Platform team'in görevi:** azalt |
| **Germane** | Öğrenme/iyileştirme yükü | İyi yatırım — koru |

### Cognitive load nasıl ölçülür?

> "Şu üç soruyu cevaplamak için kaç farklı ekip / sistem'le konuşmalıyım?"

- Yeni servis aç → 14 ticket?
- Production'a deploy et → 3 sistem?
- Bir incident'i çöz → 5 dashboard?

> Sayı yüksekse: cognitive load **fazla**. Platform team'in mevcut olmadığı
> veya etkili olmadığı sinyal.

---

## ⚙️ Pratik organizasyon haritaları

### Antipattern: "DevOps Team"

```
[ Dev ekipleri ] → [ DevOps team ] → [ Production ]
     N tane         tek silo,         (gatekeeper)
                    bottleneck
```

**Sorun:**
- DevOps team bottleneck
- Dev ekipleri operations bilmiyor
- "Throw it over the wall" kültürü
- Akşam 2'de DevOps page'leniyor — ürün ekibi uyuyor

### Sağlıklı: Stream-aligned + Platform

```
[ Stream-aligned x N ] ──── [ Platform team ]
   her biri full-stack         self-service IDP
   own + run on-call           reusable workflow

           ↑
   [ Enabling teams (rare visits) ]
```

**Faydaları:**
- Stream-aligned ekipler hızlı, autonomous
- Platform tek noktadan standardize
- Cognitive load yönetilebilir
- "You build it, you run it" — sahiplik

---

## 📐 Hangi takım hangi alanı?

### Karar matrisi

| Soru | Cevap | Takım türü |
|---|---|---|
| Müşteriye değer üretiyor mu? | Evet | Stream-aligned |
| Diğer ekiplere altyapı/araç sunuyor mu? | Evet | Platform |
| Çok özel teknik uzmanlık? | Evet | Complicated subsystem |
| Bir pratiği yaymak istiyoruz? | Evet | Enabling |

### Kötü örnekler

- ❌ "Frontend team" + "Backend team" — Conway's law: monolitik backend / SPA
- ❌ "QA team" — quality stream-aligned'ın işi
- ❌ "Database team" — DB'ler stream-aligned tarafından yönetilir, complicated subsystem değil

---

## 🏗️ Org boyutuna göre evrim

### 5 mühendis
- **1 stream-aligned team** = herkes
- Platform yok (tools + scripts paylaşılır)

### 20 mühendis
- **3-4 stream-aligned**
- Henüz platform yok ama "inner circle" gönüllü olarak shared infrastructure'a bakar

### 50 mühendis
- **6-8 stream-aligned**
- **1 platform team (3-5 kişi)**
- Maybe 1 enabling team (özel ihtiyaç)

### 200+ mühendis
- **20+ stream-aligned**
- **Multiple platform teams** (network, observability, dev tools)
- **Enabling teams** (security, performance)
- **Complicated subsystem teams** (gerekirse)

---

## 🔄 Reorg ne zaman?

### Sinyaller (yeniden organize)

- 🚩 Yeni feature 6 ay sürüyor — koordinasyon yorgunluğu
- 🚩 "Şu ekiple konuş" 5 farklı ticket
- 🚩 Manager'lar koordinasyon toplantısında geçiyor
- 🚩 Architecture diagram'ı org chart'a benzemiyor

### Sinyaller (rahat bırak)

- 🟢 Ekipler autonomous, kendi backlog'larını yönetiyor
- 🟢 Platform team'in NPS yüksek
- 🟢 Yeni mühendis 1 hafta'da prod commit yapıyor

---

## ⚠️ Yaygın hatalar

| Hata | Doğru |
|---|---|
| "DevOps team" kuralım | Platform team kur, ürün gibi yönet |
| Manager'ı "bottleneck of decision" yap | Stream-aligned otonom karar alır |
| Enabling team kalıcı olur | Bittiğinde dağılır veya başka pratiğe geçer |
| Platform team ticket-driven | Backlog kendi yönetiminde, NPS ölçülür |
| "QA team" | Quality stream-aligned'ın sorumluluğu |
| 9 kişiyi aşan stream-aligned | İkiye böl |

---

## 📋 Checklist

Bir org yapısını "Team Topologies uyumlu" saymadan önce şunları doğrula:

- [ ] Her takım net bir tipe oturuyor (stream-aligned / enabling / complicated subsystem / platform) — "karma" takım yok
- [ ] Stream-aligned takımlar end-to-end bir akışın sahibi: build + deploy + on-call aynı ekipte ("you build it, you run it")
- [ ] Hiçbir stream-aligned takım 9 kişiyi aşmıyor (aşıyorsa böl)
- [ ] Platform team ürün gibi yönetiliyor: roadmap var, NPS ölçülüyor, ticket-driven değil
- [ ] Platform self-service: yeni servis açmak / prod'a deploy etmek tek ekiple, az adımda yapılıyor
- [ ] "DevOps team" / "QA team" / "Database team" gibi silo bottleneck'ler yok
- [ ] Enabling takımlar için çıkış kriteri tanımlı — kalıcı hale gelmiyor, iş bitince dağılıyor
- [ ] Her takım çifti için etkileşim modu açık (collaboration / X-as-a-Service / facilitating) ve süreli olanların bitiş tarihi var
- [ ] Cognitive load ölçülüyor: "yeni servis / deploy / incident için kaç ekiple konuşmalıyım?" sayısı takip ediliyor
- [ ] Extraneous cognitive load (tooling/process karmaşası) platform team backlog'unda azaltma hedefi olarak duruyor
- [ ] Mimari diyagramı org chart'ı yansıtıyor (Conway's Law) — uyumsuzluk reorg sinyali olarak izleniyor
- [ ] Reorg tetikleyicileri tanımlı: feature lead time'ı, koordinasyon toplantısı yükü, çapraz-ekip ticket sayısı

---

## 📚 Devamı

- *Team Topologies* — Skelton & Pais (kitap, **must read**)
- [TeamTopologies.com](https://teamtopologies.com) — örnekler ve workshop'lar
- *Topologies of Team* — InfoQ talk (free YouTube)
- [`13-Platform-Engineering/`](../13-Platform-Engineering/) — platform team detayları
