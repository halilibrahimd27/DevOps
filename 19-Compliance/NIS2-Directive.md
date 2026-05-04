# NIS2 Directive — EU Kritik Altyapı Güvenliği

> *"NIS2 'AB yasası' diye atlanan ekipler, 2024-2025'te **bir
> müşteri** EU'da kritik altyapı operatörü olunca **kapsam**'a
> girdiklerini öğrendiler. KVKK gibi: 'beni etkilemiyor' diyenler,
> ihlal sonrası **etkilendiklerini** öğrenir."*

Bu rehber EU NIS2 (Network and Information Security Directive 2)
kapsamını, mühendislik gereksinimlerini, ve TR şirketlerin AB
müşterileriyle nasıl etkilendiğini anlatır.

> ⚠️ **Yasal danışmanlık değildir.** NIS2 AB üye ülkelerin local
> mevzuatına uyarlanır; spesifik durumlar için hukuk ekibi.

---

## 🎯 NIS2 Nedir?

> **NIS2** (Directive (EU) 2022/2555): AB'nin kritik altyapı +
> önemli sektör operatörleri için **siber güvenlik zorunluluk**
> direktifi. **NIS1**'in (2016) genişletilmiş hali.

### Yürürlük
- **Ekim 2024**: AB üye ülkelerin yerel transposition'u
- **2025-2026**: Aktif uygulama
- **Ceza**: Yıllık global ciro **%2'si** veya **€10M** (essential entities)

---

## 📊 Kapsam — Kim Etkilenir?

### Essential Entities (yüksek kritik)
- Energy (electricity, gas, oil)
- Transport (havayolu, demiryolu, denizyolu)
- Banking + Finansal Pazar
- Sağlık (hastane, ilaç üreticisi)
- İçme suyu, atık su
- **Digital infrastructure** (DNS sağlayıcı, TLD registry, cloud, datacenter, CDN, **trust service** sağlayıcı, ENISA)
- ICT service management
- **Public administration** (devlet)
- Uzay sektörü

### Important Entities (orta kritik)
- Posta + kurye
- Atık yönetimi
- Kimya
- Gıda üretimi
- Manufacturing (medical device, automotive, machinery)
- **Digital provider** (online marketplace, search engine, social network)
- Research

### Boyut sınırı
- Medium (50+ çalışan) ve large enterprise
- Küçük şirket genelde **kapsam dışı** (kritik altyapı dışında)

> 🔑 **TR şirketin etkisi**: AB'de ofis varsa veya AB müşteriye SaaS sağlıyorsa, müşteri NIS2 kapsamındaysa **sub-processor** olarak gereksinimleri taşır.

---

## 🛡️ Mühendislik Gereksinimleri (Article 21)

NIS2 tüm kapsamdaki şirketlere **10 minimum güvenlik önlemi**:

### 1. Risk Analysis + Information Security Policies
- **Mühendislik**: Threat model her servis için, risk register

### 2. Incident Handling
- **Mühendislik**: IR playbook, blameless postmortem, SIEM

### 3. Business Continuity (BCP) + Backup
- **Mühendislik**: DR plan, RTO/RPO yazılı, restore drill quarterly

### 4. Supply Chain Security
- **Mühendislik**: Vendor due diligence, SBOM, SLSA

### 5. Security in Acquisition / Development / Maintenance
- **Mühendislik**: SSDLC, SAST/SCA gate

### 6. Effectiveness Assessment
- **Mühendislik**: Continuous compliance, periodic pen test

### 7. Cyber Hygiene + Training
- **Mühendislik**: Annual security training, phishing test

### 8. Cryptography + Encryption
- **Mühendislik**: TLS 1.2+, KMS-backed, mTLS

### 9. Human Resources + Access Control
- **Mühendislik**: OIDC + MFA, RBAC, periyodik review

### 10. Multi-Factor Authentication / Secure Communications / Emergency Communication
- **Mühendislik**: MFA enforce, encrypted comms, oncall + incident bridge

---

## 🚨 Incident Reporting — Sıkı Süreler

| Süre | Neyi yap |
|---|---|
| **24 saat** | Early warning (ön bildirim) yetkili otoriteye |
| **72 saat** | Detaylı incident notification |
| **1 ay** | Final report (kök neden + mitigation) |

> ⚠️ **24 saat çok kısa**. Detection → IR → notification akışı **otomatik trigger** olmalı. Manuel yapılırsa kaçırılır.

### Mühendislik akışı
```
[Detection: Falco / SIEM / WAF]
     │
     ▼
[Triage 15 dk: kritik incident mi?]
     │
     ▼ (EVET)
[NIS2-impacting? data exfiltration / availability]
     │
     ▼ (EVET)
[Hukuk + DPO + CTO automatic page]
     │
     ▼
[24h timer başladı]
     │
     ▼
Pre-prepared template + auto-fill detail
     │
     ▼
[Hukuk gönderim onayı] → yetkili otorite
```

### Authority listesi (üye ülke bazında)
- Almanya: BSI
- Fransa: ANSSI
- Belçika: CCB
- İrlanda: NCSC
- TR: NIS2 doğrudan kapsam dışı ama **AB müşteriye hizmet edenler dolaylı**

---

## 🔗 KVKK + GDPR + NIS2 Çakışması

### Birden fazla framework altında ihlal
Bir incident'a hem KVKK + GDPR + NIS2 yansır:

```
[Veri ihlali — kişisel veri sızıntısı, AB customer]
     │
     ├── 24h → NIS2 early warning (eğer kritik altyapı etkisi)
     ├── 72h → GDPR notification (EU DPA'ya)
     ├── 72h → KVKK notification (TR müşteri)
     └── 1ay → NIS2 final report
```

### Pre-prepared templates
3 farklı template hazır olmalı (KVKK, GDPR, NIS2). Ortak detail (timeline, etki) paylaşılır, format farklı.

---

## 📋 Mühendislik Compliance Checklist (NIS2)

```
[ ] Kapsam değerlendirmesi: NIS2 size nasıl yansıyor?
[ ] Threat model: tüm prod servis için
[ ] IR playbook: 24h + 72h + 1ay timer
[ ] SIEM + audit log → 1+ yıl retention
[ ] Backup: tested, off-site, immutable (S3 Object Lock)
[ ] DR plan: RTO/RPO yazılı, tatbikat
[ ] Supply chain: SBOM + SLSA + vendor due diligence
[ ] SSDLC: SAST + SCA + image scan + signing
[ ] Encryption: TLS 1.2+ + AES-256 + KMS
[ ] MFA enforced (tüm prod erişim)
[ ] OIDC + RBAC + quarterly review
[ ] Cyber hygiene training (annual)
[ ] Pen test (annual external + internal)
[ ] Vendor incident clause (sub-processor 24h notify yapsın)
[ ] CISO / DPO + Hukuk + CTO incident escalation chain
[ ] Pre-prepared notification templates (KVKK + GDPR + NIS2)
[ ] Continuous compliance + quarterly evidence
[ ] Customer DPA: NIS2 sub-processor clause
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "NIS2 bizi etkilemez" | AB müşteri olunca sub-processor | Customer base review |
| 24h timer manuel | Süre kaçar | Otomatik IR trigger |
| Tek incident report (KVKK only) | NIS2 + GDPR ihmal | 3 framework template |
| Vendor risk yok | Sub-processor compromise = senin compromise | Due diligence + DPA clause |
| Backup off-site yok | Region down → recovery yok | Cross-region + immutable |
| Pen test sadece "compliance için" | Yüzeysel | Quarterly internal + annual external |
| MFA bazı user'larda yok | Compromise vektörü | Universal enforce |
| Incident escalation chain belirsiz | Hukuk geç haberdar | Pre-defined chain |

---

## 📊 NIS2 Olgunluk Yolu

| Level | Durum |
|---|---|
| **L0** | Kapsamı bilmiyor |
| **L1** | Politikalar var, uygulama tutarsız |
| **L2** | Kontroller işliyor, manuel evidence |
| **L3** | Continuous compliance, otomatik bildirim trigger |
| **L4** | Multi-framework (KVKK + GDPR + NIS2 + ISO 27001) entegre |

> 🎯 **2026 hedefi**: L3+. Multi-framework olunca aynı kontrolden N farklı sertifika beslenir.

---

## 📚 Referanslar

- **NIS2 Directive (EU 2022/2555)** — eur-lex.europa.eu
- **ENISA NIS2 Implementation** — enisa.europa.eu
- **National transposition laws** (her AB üye ülke local)
- **EU Cyber Resilience Act** (CRA, ek düzenleme)
- [`KVKK-Practical.md`](KVKK-Practical.md)
- [`GDPR-Engineering.md`](GDPR-Engineering.md)
- [`SOC2-Type2-Prep.md`](SOC2-Type2-Prep.md)
- [`ISO-27001-Controls.md`](ISO-27001-Controls.md)
- [`08-Security/SLSA-and-SBOM.md`](../08-Security/SLSA-and-SBOM.md) — supply chain
- [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md) — IR akışı

---

> *"NIS2 'EU yasası, beni etkilemez' demek 2024-2025'te yaygındı.
> 2026'da müşterin AB'de kritik altyapı operatörüyse, **sen
> sub-processor** olarak yükümlüsün. **Bilmemek savunma değil**."*
