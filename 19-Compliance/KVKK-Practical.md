---
description: "6698 sayılı KVKK'nın DevSecOps açısından pratik rehberi: data inventory, DPIA, encryption, retention ve incident notification için somut tool ve pipeline gate'leri."
---
# KVKK Pratik Rehberi — Mühendislik Açısından

> *"KVKK 'hukuk metni' olarak kalsın istemiyorsan, **kontrol** olarak
> kodlanır. Aksi halde her audit ertesi 'şimdi mühendislik nasıl
> hizalanacak' tartışması başlar."*

Bu rehber 6698 sayılı Kişisel Verilerin Korunması Kanunu'nu **DevSecOps
açısından** ele alır: data inventory, DPIA, encryption, retention,
incident notification — somut tool ve pipeline gate'leriyle.

> ⚠️ **Yasal danışmanlık değildir.** Mühendislik perspektifinden
> kontrol önerisi sunar; spesifik durumlar için hukuk ekibinizle çalışın.

---

## 🎯 KVKK 5 Temel Yükümlülük (Mühendislik Bakışı)

| Yükümlülük | Mühendislik karşılığı |
|---|---|
| **Hukuka uygun işleme** (Madde 4) | Data minimization, purpose limitation kodla enforce |
| **Açık rıza / hukuki sebep** (Madde 5-6) | Consent management platform, audit log |
| **Aydınlatma yükümlülüğü** (Madde 10) | Privacy notice, data flow disclosure |
| **Veri güvenliği** (Madde 12) | Encryption, access control, audit, incident response |
| **VERBİS kayıt** | Veri kategori envanteri, periyodik update |

---

## 📋 Adım 1: Data Inventory — "Nerede Hangi Veri?"

KVKK'nın temeli: **kişisel veri envanterini** bil. Bilmiyorsan koruyamazsın.

### Ne sayılır?
| Veri tipi | KVKK kapsamı |
|---|---|
| Ad-soyad, T.C. kimlik | ✅ Kişisel |
| E-mail, telefon | ✅ Kişisel |
| IP adres | ✅ Kişisel |
| Çerez kimliği | ✅ Kişisel (cihaz tanımlayıcı) |
| Konum verisi | ✅ Kişisel |
| Sağlık, biyometri, ceza, etnik | ✅ **Özel nitelikli** (extra koruma) |
| Anonimleştirilmiş istatistik | ❌ (ama re-identification riski varsa ✅) |

### Inventory schema
```yaml
# data-inventory.yaml (Git'te, owner per service)
service: payments-api
owner: payments-team
data_categories:
  - name: customer_pii
    fields:
      - {name: email, type: identifier, retention: "until-deletion-request"}
      - {name: phone, type: identifier, retention: "until-deletion-request"}
      - {name: full_name, type: identifier, retention: "until-deletion-request"}
    storage:
      - postgres: app.users
      - elasticsearch: logs-*  # ⚠️ log'da PII olmamalı!
    encryption:
      at_rest: true
      in_transit: true
    legal_basis: contract  # KVKK Madde 5(2)(c)
    third_parties: []

  - name: payment_data
    fields:
      - {name: card_token, type: tokenized, retention: "365d"}
    storage:
      - postgres: app.payments
    legal_basis: contract
    third_parties: ["Iyzico"]  # processor
    sensitivity: financial   # ⚠️ ek kontrol
```

### Otomatik discover
```bash
# Trivy ile DB schema'da PII pattern'leri
trivy fs --scanners secret,config db-schemas/

# AWS Macie (S3 bucket'larda PII tarama)
aws macie2 create-classification-job ...
```

---

## 📋 Adım 2: DPIA (Veri Koruma Etki Değerlendirmesi)

> KVKK Madde 28: yüksek risk taşıyan işlemeler için **DPIA zorunlu**.

### Ne zaman DPIA?
- Sistematik + yaygın değerlendirme (örn: kredi skorlama)
- Özel nitelikli verilerin yaygın işlenmesi
- Genel halk yerleri sistematik gözetim
- Yeni teknoloji (AI/ML, biyometri)
- Profile çıkarma + otomatik karar

### DPIA şablonu
```markdown
# DPIA: <PROJECT_NAME>
**Date:** 2026-05-04  
**Owner:** @<TEAM>  
**Hukuk review:** @legal  

## 1. İşleme açıklaması
<Ne veri, kimden, ne amaçla, kim erişiyor>

## 2. Necessity & Proportionality
- Hukuki sebep: <KVKK Madde 5/6 hangi bent>
- Daha az veri ile aynı sonuç mümkün mü?
- Saklama süresi: <X gün/ay/yıl>, niye?

## 3. Risk değerlendirmesi (LINDDUN)
| Risk | Likelihood | Impact | Mitigation |

## 4. Kontroller
| Risk | Kontrol | Status |

## 5. Veri sahibinin hakları
- Erişim, düzeltme, silme talep akışı: <link>
- Yanıt süresi: 30 gün
- Otomatik kanal: <portal URL>

## 6. Kalan riskler
<Mitigate edilemeyen, kabul edilmiş riskler>

## 7. Onay
- Sahip: ___________  Date: _______
- Hukuk: ___________  Date: _______
- DPO/CISO: ________  Date: _______
```

> 🔑 LINDDUN için bkz [`08-Security/Threat-Modeling.md`](../08-Security/Threat-Modeling.md).

---

## 🔐 Adım 3: Veri Güvenliği — KVKK Madde 12

### Encryption-at-rest
```sql
-- DB sütun bazında (özel nitelikli için)
CREATE EXTENSION pgcrypto;

-- TC kimlik no encrypted store
INSERT INTO citizens (id, tc_no_encrypted)
VALUES (1, pgp_sym_encrypt('11111111111', '<KEY>'));

-- Read
SELECT pgp_sym_decrypt(tc_no_encrypted::bytea, '<KEY>') FROM citizens;
```

```yaml
# K8s etcd encryption-at-rest (cluster-wide)
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources: ["secrets"]
    providers:
      - kms:
          name: <KMS_NAME>
```

### Encryption-in-transit
- TLS 1.2+ enforce
- mTLS service-to-service
- Bkz [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md)

### Access control + audit
- OIDC + MFA + RBAC
- Audit log → SIEM
- Bkz [`08-Security/Kubernetes-Hardening.md`](../08-Security/Kubernetes-Hardening.md)

### Pseudonymization / anonymization
```sql
-- Pseudonymization: mapping table'da gerçek değer
CREATE TABLE user_mapping (
  pseudo_id UUID PRIMARY KEY,
  real_email_hash TEXT  -- SHA-256
);

-- Çalışan tabloda sadece pseudo
SELECT pseudo_id, action FROM events;
```

> ⚠️ **Pseudonymization ≠ anonymization.** Pseudonymized data hâlâ
> KVKK kapsamında. Tam anonymize için k-anonymity / differential privacy.

---

## ⏱️ Adım 4: Retention & Right-to-Erasure

### Retention policy kodla
```yaml
# retention-policy.yaml
policies:
  - data: customer_pii
    retention: 1095d  # 3 yıl
    deletion_method: hard
    legal_hold_check: true

  - data: log_with_ip
    retention: 90d
    deletion_method: hard
```

### CronJob: süresi geçmiş veriyi sil
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: kvkk-retention-cleaner
spec:
  schedule: "0 3 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: cleaner
              image: <APP>/retention-cleaner:<VERSION>
              command:
                - python
                - -m
                - retention.run
                - --policy=/policies/retention.yaml
                - --dry-run=false
```

### Right-to-erasure (Madde 11)
Kullanıcı silme talebi → 30 gün içinde tüm sistemlerden:
1. Production DB
2. Backup'lar (anonymize / mark for delete)
3. Log archive
4. Analytics warehouse
5. ML training dataset (re-train gerekebilir)
6. Third-party processor'lara forward

```python
# Tek API endpoint, fan-out
async def erase_user(user_id):
    await asyncio.gather(
        db.delete_user(user_id),
        warehouse.scrub_user(user_id),
        log_archive.scrub_user(user_id),
        ml_pipeline.mark_for_retrain(user_id),
        *[
            processor.forward_erasure(user_id)
            for processor in third_parties
        ]
    )
    audit_log.write({"event": "erasure", "user": user_id, "at": now()})
```

> 🔑 **Backup'lardan silmek pratik değil.** İki yaklaşım:
> 1. Backup encryption key'ini sil → veri okunamaz
> 2. Backup retention < 90 gün → sıradaki cycle'da gider

---

## 🚨 Adım 5: Incident Notification — 72 Saat Kuralı

> KVKK Madde 12(5): "Veri ihlali öğrenildiği andan itibaren **en kısa
> sürede** ve **72 saat** içinde KVK Kurumu'na bildirim."

### Mühendislik akışı
```
[Detection]                                            
   ↓ Falco / WAF / IDS / Wazuh                         
                                                       
[Triage] (15 dakika)                                   
   - Kişisel veri var mı?                              
   - Etkilenen kişi sayısı?                            
   - Zaman penceresi?                                  
   ↓ EVET ise...                                       
                                                       
[Notify Internal]                                      
   - DPO + Hukuk + Yönetim                             
   - PagerDuty SEV1                                    
   ↓                                                   
                                                       
[Mitigate]                                             
   - IC sürecini başlat                                
   - Kanama durdur                                     
   ↓                                                   
                                                       
[Document]                                             
   - Olay timeline (Scribe)                            
   - Etkilenen veri kategori                           
   - Etkilenen kişi sayısı                             
   - Mitigation                                        
   ↓                                                   
                                                       
[KVK Kurumu Bildirimi] (72 saat)                       
   - kvkk.gov.tr/Veri İhlal Bildirim Formu             
   - Hukuk ekibi gönderir                              
   ↓                                                   
                                                       
[Affected Users] (en kısa sürede)                      
   - E-mail / SMS                                      
   - Içerik: ne oldu, ne etkileniyorsun, ne yapmalısın 
   ↓                                                   
                                                       
[Postmortem]                                           
   - Blameless                                         
   - Action items + due date                           
   - 5 iş günü içinde yayınlama                        
```

### KVK ihlal bildirim formu içeriği
- Olay açıklaması (kısa)
- Etkilenen kişisel veri kategorileri
- Etkilenen kişi sayısı (yaklaşık olabilir)
- Olası sonuçları
- Alınan ya da alınması önerilen önlemler
- DPO iletişim

> ⚠️ **72 saat hızlı geçer.** Pre-prepared template + decision tree
> hazır olmalı. Bkz [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md).

---

## 📦 Adım 6: Veri İhracı — Yurt Dışı Aktarım

KVKK Madde 9: yurt dışı aktarım için **yeterli korumaya sahip ülke** veya
**taahhüt** veya **açık rıza**.

### Cloud servisleri sorunu
- AWS eu-west-1 (Dublin) — AB ülkesi, yeterli koruma
- AWS us-east-1 (Virginia) — **yetersiz**, Schrems II sonrası ek mekanizma
- GCP europe-west3 (Frankfurt) — AB
- Azure North Europe (Dublin) — AB

> 🔑 **Pratik:** Türkiye + AB region'ları primary, US region'ları için
> processor kontratı + SCC + technical safeguard.

### SCC (Standard Contractual Clauses)
- AB SCC 2021 modeli + KVKK uyarlaması
- Şifreli + erişim kontrol + audit
- Hukuk ekibi sözleşme tarafı, mühendis **technical safeguard** sahibi

---

## 📋 Mühendislik Compliance Checklist

```
[ ] Data inventory: her servis kendi data-inventory.yaml'i
[ ] DPIA: yeni feature'da PII/sensitive varsa zorunlu
[ ] LINDDUN tehdit modeli (privacy odaklı)
[ ] Encryption-at-rest: DB + etcd + S3 + backup
[ ] Encryption-in-transit: TLS 1.2+ + mTLS service-to-service
[ ] Access: OIDC + MFA + RBAC + audit log → SIEM
[ ] Audit log retention: 1+ yıl (KVKK denetim için)
[ ] Retention policy yazılı + cron'la enforce
[ ] Right-to-erasure: tek API endpoint, fan-out
[ ] Right-to-access: portal'dan veri export indir
[ ] Right-to-rectification: portal/destek kanalı
[ ] Backup: retention < 90 gün veya encryption-key-delete strategy
[ ] Veri ihracı: region seçimi karar matrisinde "data residency"
[ ] Third-party processor sözleşmeleri DPA içerir
[ ] Çerez bildirimi: opt-in (analytics, marketing için)
[ ] Aydınlatma metni: her veri toplama noktasında
[ ] Incident response: 72-saat playbook + decision tree
[ ] Quarterly: VERBİS kaydı güncel mi review
[ ] Annual: data inventory audit (yeni alan eklendiyse?)
[ ] Annual: DPIA review eskiyenler için
[ ] Mühendis on-boarding: KVKK temel eğitim
[ ] DPO + Hukuk + Mühendislik üçlüsü 3 ayda bir koordinasyon
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Log'a PII düşmesi | İhlal anında log archive de scope'a girer | PII filter, structured log |
| Slack DM ile müşteri bilgisi paylaşma | Sızıntı vektörü | Ticketing system, audit |
| Test environment'ta gerçek müşteri verisi | Test DB compromise = prod ihlal | Synthetic data / anonymized |
| Backup forever | Retention politikası ihlali | Lifecycle policy + delete |
| Erasure manuel — DB'den `DELETE` | Backup, log, analytics'te kalır | Fan-out API + audit trail |
| Veri envanteri Confluence'ta | Eskir, kimse update'lemez | Git'te + CI gate (servis review'inde update zorunlu) |
| Audit gününe hazırlık | Stres + kanıt eksik | Continuous compliance, otomatik kanıt |
| Encryption sadece "compliance için" | Defansif değer kaybı | Tüm sensitive flow'da encryption |
| KVK ihlal bildirimi 5 günde | Yasal ihlal (72 saat) | IR playbook + 24h notification SLA |
| Data Subject Request (silme/erişim) e-mail ile | Track imkansız | Portal + ticketing + 30-gün timer |

---

## 📚 Referanslar

- **KVK Kurumu** — kvkk.gov.tr (ve Rehber dokümanlar)
- **6698 sayılı Kanun** — mevzuat.gov.tr
- **VERBİS** — verbis.kvkk.gov.tr
- **Veri İhlal Bildirim Formu** — kvkk.gov.tr/SitePages/veri-ihlali-bildirimi
- **GDPR & KVKK Karşılaştırma** — KVK Kurumu Rehber
- **LINDDUN** — linddun.org (privacy threat modeling)
- [`GDPR-Engineering.md`](GDPR-Engineering.md)
- [`08-Security/Threat-Modeling.md`](../08-Security/Threat-Modeling.md)
- [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md)
- [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md)

---

> *"KVKK'yı 'PDF dokümanı' olarak okuyan ekip, audit'te 'biz öyle
> yapıyoruz' der. **Pipeline gate** olarak okuyan ekip, kanıtı her
> deploy'da otomatik üretir. İkisinin de aynı kanunu okuduğunu kimse
> tahmin etmez."*
