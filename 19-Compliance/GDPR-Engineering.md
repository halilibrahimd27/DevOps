# GDPR — Mühendislik Açısından Pratik Rehber

> *"GDPR'ı 'AB yasası' diye atlayıp Türkiye'den hizmet veren ekip,
> AB müşterisi geldiğinde **sıfırdan** uyumluluk yapar — 2 yıllık
> geç kalma. Mühendislik açısından KVKK ile **%90 örtüşür**."*

Bu rehber GDPR (General Data Protection Regulation) için mühendislik
kontrolünü, KVKK ile farklarını, ve Türkiye'den AB pazarına hizmet
verirken yapılması gereken pratik adımları anlatır.

> ⚠️ **Yasal danışmanlık değildir.** Mühendislik bakışıdır. Spesifik
> durumlar için DPO + hukuk ekibi ile çalışın.

---

## 🎯 GDPR'ın Mühendislik Boyutu (Madde Eşlemesi)

| GDPR Madde | Konu | Mühendislik karşılığı |
|---|---|---|
| **Madde 5** | İşleme prensipleri | Data minimization, purpose limitation, accuracy |
| **Madde 6-9** | Hukuki sebep | Consent + processing flag DB'de |
| **Madde 12-14** | Şeffaflık | Privacy notice, data flow disclosure |
| **Madde 15** | Right to access | Self-service data export |
| **Madde 16** | Right to rectification | Profile edit + audit |
| **Madde 17** | Right to erasure | Cascade delete API |
| **Madde 18** | Right to restrict | Soft-delete flag |
| **Madde 20** | Data portability | JSON/CSV export |
| **Madde 25** | Privacy by Design | Default opt-out, encryption |
| **Madde 32** | Security | TLS, encryption-at-rest, audit |
| **Madde 33** | Breach notification | 72h to authority |
| **Madde 35** | DPIA | High-risk processing assessment |
| **Madde 44-49** | International transfer | SCC, adequacy decision |

---

## 🆚 GDPR vs KVKK — Mühendislik Karşılaştırması

| Boyut | GDPR | KVKK |
|---|---|---|
| **Yetki** | EU residents | TR residents |
| **Bildirim süresi** | 72 saat | 72 saat (en kısa süre) |
| **Erişim hakkı yanıt** | 1 ay | 30 gün |
| **DPO zorunluluğu** | Belirli durumlarda | DPO yerine "Veri Sorumlusu" + VERBİS kayıt |
| **Ceza** | %4 ciro / €20M | Şart bağlı (yasal pazarlık) |
| **Veri ihracı** | SCC + adequacy decision | Yeterli koruma + taahhüt |
| **Çocuk verisi** | < 16 yaş ek consent | < 18 yaş velâyet |
| **Açık rıza** | Granular, opt-in | Açık rıza (specific) |

> 🔑 **Pratik:** GDPR ve KVKK'nın **mühendislik kontrolleri %90 ortak**.
> Bir tanesini doğru yapan diğerine 10% ek emek.

---

## 📋 Mühendislik Kontrolleri (KVKK ile birlikte ortak)

### 1. Data Inventory
```yaml
# data-inventory.yaml — GDPR + KVKK ortak
service: <SERVICE>
data_categories:
  - name: customer_pii
    fields: [email, phone, ip_address]
    legal_basis_gdpr: contract       # GDPR Article 6(1)(b)
    legal_basis_kvkk: contract       # KVKK Madde 5(2)(c)
    retention: 1095d
    encryption: {at_rest: true, in_transit: true}
    third_parties: ["Stripe (payment processor)"]
    transfer_outside_eu: ["US: SCC + DPA"]
```

### 2. DPIA (Data Protection Impact Assessment)
GDPR Madde 35 + KVKK Madde 28 — yüksek risk işlemelerde **zorunlu**:
- Sistematik + yaygın değerlendirme (ML scoring, recommendation)
- Özel kategoriler (sağlık, biyometri, etnik)
- Yeni teknoloji (AI, IoT)

DPIA şablonu için bkz [`KVKK-Practical.md`](KVKK-Practical.md).

### 3. Privacy by Design (Madde 25)
- **Default**: en az veri toplama
- **Opt-in**: yeni feature açılırken consent
- **Pseudonymization**: kullanılabilir analytics, kişi tespit edilemez
- **Access control**: least privilege

### 4. Right to Erasure (Madde 17)
```python
# Tek API endpoint, fan-out
async def gdpr_erasure(user_id, reason="user_request"):
    audit_log.write({
        "event": "gdpr_erasure_requested",
        "user_id": user_id,
        "reason": reason,
        "at": now()
    })

    # Production sistemler
    await db.delete_user(user_id)
    await elasticsearch.scrub_user(user_id)

    # Analytics warehouse
    await warehouse.scrub_user(user_id)

    # Log archives (anonymize, can't fully delete)
    await log_archive.anonymize_user(user_id)

    # ML training data
    await ml_pipeline.mark_for_retraining(user_id)

    # Third-party processors
    for processor in third_parties:
        await processor.forward_erasure(user_id)

    audit_log.write({
        "event": "gdpr_erasure_completed",
        "user_id": user_id,
        "at": now()
    })
```

### 5. Right to Access (Madde 15) + Portability (Madde 20)
```python
# Portal'dan tıklayıp indir
async def gdpr_export(user_id):
    data = {
        "profile": await db.get_user(user_id),
        "orders": await db.get_orders(user_id),
        "events": await events_db.scan_user(user_id, redacted=False),
        "consent_history": await consent_db.history(user_id),
    }
    return data   # JSON; portability için makine-okunabilir
```

> 🔑 30 gün içinde teslim. Geç kalırsanız fine + güven kaybı.

### 6. Consent Management
```sql
-- consent kayıt
CREATE TABLE user_consent (
  user_id UUID,
  purpose VARCHAR(100),    -- 'marketing', 'analytics', 'product'
  granted BOOLEAN,
  granted_at TIMESTAMP,
  ip_address INET,         -- audit için (silinene kadar)
  user_agent TEXT,
  withdrawn_at TIMESTAMP,
  PRIMARY KEY (user_id, purpose)
);
```

```python
# Pipeline'a girmeden önce check
def can_process(user_id, purpose):
    consent = consent_db.get(user_id, purpose)
    if not consent or not consent.granted or consent.withdrawn_at:
        return False
    return True

# Marketing event gönderilmeden önce
if not can_process(user_id, "marketing"):
    return  # skip
```

> 🔑 **Granular consent**: tek "ben her şeyi kabul ediyorum" yetmez.
> Her purpose ayrı tracking + ayrı opt-out.

---

## 🌍 Uluslararası Veri Aktarımı (Madde 44-49)

### Adequacy Decision — "yeterli koruma sağlayan ülkeler"
| Bölge | Status (2026) |
|---|---|
| AB ülkeleri | ✅ Free flow |
| UK | ✅ Adequacy decision |
| İsviçre | ✅ |
| Türkiye | ❌ Adequacy yok (henüz) |
| US | ⚠️ Data Privacy Framework (Schrems II sonrası) |
| Brezilya, Japonya | ✅ Bazı durumlar |

### SCC (Standard Contractual Clauses)
Adequacy yoksa sözleşmesel koruma:
- AB SCC 2021 modulleri (controller-controller, controller-processor)
- Technical safeguards (encryption, access control)
- Periyodik review

### Pratik akış (Türkiye'den AB müşterisine hizmet)
```
[AB müşteri] → [App: AWS eu-west-1 (Dublin)]
                    │
                    ├── Database: AWS Dublin (AB içi, OK)
                    ├── Backup: AWS Frankfurt (AB içi, OK)
                    ├── Logging: SaaS Datadog (US) ⚠️
                    │   → DPA + SCC + EU data residency option
                    └── ML training: Türkiye'deki cluster ⚠️
                        → DPA + SCC + technical safeguard
```

> 🔑 **Pratik**: AB müşteri verisi AB region'larında durur. Ek processor'lar
> SCC ile + technical safeguard.

---

## 🚨 Breach Notification (Madde 33-34)

### Süre
- Authority: **72 saat** (öğrenme anından)
- Affected users: "haksız risk varsa, en kısa süre"

### Authority listesi (her AB ülkesi için ayrı)
- Almanya: BfDI + state DPAs
- Fransa: CNIL
- İtalya: Garante
- Türkiye'den AB'ye hizmet → genelde **lead supervisory authority** seçilir (one-stop-shop)

### Notification içeriği
```markdown
1. İhlal niteliği (ne tür veri, kaç kişi yaklaşık)
2. DPO iletişim
3. Olası sonuçlar
4. Alınan / alınması gereken önlemler
5. Etkilenen kişilere yapılan/yapılacak bildirim
```

### Pratik akış
```
T+0:    Detection (Falco / WAF / customer report)
T+0:15  IC açar, severity SEV1
T+0:30  DPO + Hukuk + CTO bilgilendirilir
T+1:    Mitigation başlar, blast radius ölçülür
T+4:    Etkilenen veri kategori + kişi sayısı tahmin
T+24:   Internal incident report
T+48:   Authority notification draft (hukuk)
T+72:   Authority bildirim gönderildi
T+72-?: Kullanıcı bildirim (riskli ise)
T+5gün: Postmortem yayınlanır
```

> Bkz [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md) ve [`KVKK-Practical.md`](KVKK-Practical.md).

---

## 🧪 GDPR Compliance CI Gate'leri

```yaml
# .github/workflows/gdpr-checks.yml
name: GDPR Engineering Checks

on: [pull_request]

jobs:
  data-inventory:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>

      - name: Validate data-inventory.yaml exists
        run: test -f data-inventory.yaml

      - name: Lint inventory schema
        run: yamllint data-inventory.yaml

      - name: PII fields registered?
        run: python -m gdpr_check.pii_fields_in_inventory

      - name: Secrets scanning
        uses: gitleaks/gitleaks-action@<VERSION>

      - name: New PII collection?
        run: |
          # Eğer yeni PII alanı eklenmiş ama DPIA güncellenmemişse warn
          python -m gdpr_check.dpia_freshness
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "Türkiye'den hizmet veriyoruz, GDPR umurumda değil" | AB müşteri = scope | Baştan dual-compliance (KVKK + GDPR) |
| Consent: "Tüm cookies'i kabul ediyorum" tek kutu | Granular consent ihlali | Purpose başına opt-in |
| Right-to-erasure → manuel `DELETE` query | Backup, log, analytics'te kalır | Fan-out API + audit |
| Privacy notice 4000 kelime hukuk dili | "Şeffaflık" gerçekçi değil | Layered notice + summary |
| US region'da AB müşteri verisi | Madde 44 ihlali | EU data residency + SCC |
| Vendor seçimi sadece fiyat/feature | DPA yoksa risk | Vendor due diligence: DPA + SOC2 + GDPR-uyum |
| Breach response 5 günde | 72 saat kuralı ihlal | Pre-prepared playbook + 24h SLA |
| DPIA "ihtiyaç yok" — high-risk feature | Article 35 ihlali | DPIA workflow zorunlu |
| Veri export Excel formatında, hand-off | Portability ihlali | API + JSON otomatik |
| Audit log retention < 1 yıl | Forensic + compliance gap | 1+ yıl retention |
| Üçüncü taraf processor'lar listesi yok | Sub-processor kontrolü yok | Public listed sub-processors + DPA |

---

## 📋 GDPR Engineering Checklist

```
[ ] Data inventory: her servis kendi
[ ] DPIA: yeni feature'da PII varsa zorunlu
[ ] Privacy by Design: yeni feature checklist
[ ] Encryption-at-rest + in-transit (KMS / TLS 1.2+)
[ ] Access: OIDC + MFA + RBAC + audit log → SIEM
[ ] Audit log retention: 1+ yıl
[ ] Right-to-erasure API (fan-out)
[ ] Right-to-access API (data export)
[ ] Consent management: granular + history
[ ] Cookie banner: opt-in (analytics, marketing)
[ ] Privacy notice: layered (TL;DR + detail)
[ ] EU data residency: AB region'lar primary
[ ] SCC + DPA: tüm sub-processor'larla
[ ] Vendor due diligence: SOC2/ISO27001 sertifika kontrol
[ ] Breach playbook: 72h SLA
[ ] Annual: data inventory audit
[ ] Annual: DPIA refresh (eskiyen)
[ ] Mühendis on-boarding: GDPR + KVKK 1 saat eğitim
[ ] DPO + Hukuk + Mühendislik üçlüsü 3 ayda bir
[ ] Public sub-processor listesi (transparency)
```

---

## 📚 Referanslar

- **GDPR metni** — eur-lex.europa.eu/eli/reg/2016/679
- **EDPB Guidelines** — edpb.europa.eu
- **ICO (UK) GDPR Guide** — ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources
- **Schrems II Decision** — court of justice 2020
- **EU SCCs 2021** — adımlanmış prosedür
- **Data Privacy Framework (US)** — dataprivacyframework.gov
- [`KVKK-Practical.md`](KVKK-Practical.md) — TR paralel rehber
- [`08-Security/Threat-Modeling.md`](../08-Security/Threat-Modeling.md) — LINDDUN
- [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md) — 72h breach playbook

---

> *"GDPR ve KVKK 'iki ayrı yasa' değil, **aynı disiplinin iki yansıması**.
> Bir sistem KVKK uyumlu kurarsan, GDPR'a 10% ek iş ile ulaşırsın.
> Sıfırdan kurmak ise her iki tarafa da en başında dahil etmek."*
