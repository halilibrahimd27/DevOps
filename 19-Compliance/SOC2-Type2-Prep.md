---
description: "SOC 2 Type II'nin mühendislik hazırlığı: Trust Service Criteria, observation period, audit evidence automation ve continuous compliance disiplini ile audit günü hazırlığı."
tags:
  - Compliance
  - Security
  - Policy as Code
  - Observability
---
# SOC 2 Type II — Mühendislik Hazırlığı

> *"SOC 2 Type II 'sertifika asma duvarı' değil — **6 ay süreyle
> kontrol işliyor mu** denetimi. Audit gününe sıkıştırılan
> hazırlık başarısız olur. **Continuous compliance** = yıllık
> stres yerine **otomatik kanıt**."*

Bu rehber SOC 2 Type II'yi mühendislik açısından **continuous
compliance** disiplini olarak ele alır: Trust Service Criteria, audit
evidence automation, observation period, ve "audit günü" hazırlığı.

> ⚠️ **Yasal danışmanlık değildir.** SOC 2 audit firma seçimi + scope
> tanımlama hukuk + compliance ekipleriyle yapılır.

---

## 🎯 SOC 2 Nedir?

> **SOC 2 (Service Organization Control 2)**: AICPA tarafından tanımlanan,
> hizmet sağlayıcılarının **müşteri verisini nasıl koruduğunu** doğrulayan
> denetim çerçevesi.

| Tip | Süre | Açıklama |
|---|---|---|
| **Type I** | Snapshot (1 gün) | "Bu kontroller var mı?" — hızlı |
| **Type II** | Observation period (3-12 ay, genelde 6) | "Kontroller **sürekli işliyor mu**?" — gerçek değer |

> 🔑 B2B SaaS müşterileri **Type II** ister. Type I sadece başlangıç.

---

## 📊 Trust Service Criteria (TSC)

| TSC | Açıklama | Mühendislik kapsamı |
|---|---|---|
| **Security** (zorunlu) | Yetkisiz erişim engellenir | RBAC, audit log, MFA, encryption |
| **Availability** | Servis SLA'ya uyar | Uptime, DR, monitoring |
| **Processing Integrity** | İşlemler doğru, tam, zamanında | Data validation, idempotency |
| **Confidentiality** | Hassas data ifşa edilmez | Encryption, access control |
| **Privacy** | PII düzgün yönetilir | KVKK/GDPR uyumu |

> 🔑 **Çoğu ekip**: Security + Availability + Confidentiality. Privacy ayrıca KVKK/GDPR ile çakışır.

---

## 🪜 Olgunluk Yolu

### L0: Hiç bir şey
- Audit yok, müşteri talep ediyor
- 6+ ay hazırlık gerekir

### L1: Doküman var, kontrol yok
- Politikalar yazılı
- Uygulama tutarsız

### L2: Kontroller var, kanıt manuel
- "İhtiyaç olunca toplarız"
- Audit gününde stres

### L3: Continuous compliance
- Kontroller koda dökülmüş
- Kanıt otomatik üretiliyor
- Audit'e gün-bazında hazır

> 🎯 **Hedef**: L3. SOC 2 Type II + ISO 27001 + KVKK/GDPR aynı kontrol setinden besleniyor.

---

## 🛠️ Common Controls + Mühendislik Karşılığı

### CC1: Control Environment
- **CC1.1** Etik kod, code of conduct
- **CC1.4** Yetki gözden geçirme
  - Mühendislik: Quarterly RBAC review

### CC6: Logical Access
- **CC6.1** User authentication
  - Mühendislik: OIDC + MFA enforced
- **CC6.2** User registration / authorization
  - Mühendislik: SCIM provisioning, JIRA ticket trail
- **CC6.3** User access review
  - Mühendislik: Quarterly access audit (AWS IAM, K8s RBAC, Vault)
- **CC6.6** Encryption in transit
  - Mühendislik: TLS 1.2+, mTLS service-to-service
- **CC6.7** Encryption at rest
  - Mühendislik: KMS-backed (AWS / GCP), etcd encryption

### CC7: System Operations
- **CC7.1** Threat detection
  - Mühendislik: Falco / SIEM, anomaly alert
- **CC7.2** Monitoring + incident response
  - Mühendislik: Prometheus + alerts, IR playbook
- **CC7.3** Incident management
  - Mühendislik: Postmortem, action item tracking
- **CC7.4** Disaster recovery
  - Mühendislik: Backup + restore drill, RTO/RPO yazılı

### CC8: Change Management
- **CC8.1** Change documentation
  - Mühendislik: PR + CI + ArgoCD audit trail
- **CC8.2** Change approval
  - Mühendislik: CODEOWNERS + required review

### CC9: Risk Mitigation
- **CC9.1** Risk identification
  - Mühendislik: Threat model per service
- **CC9.2** Vendor risk
  - Mühendislik: Vendor due diligence, DPA imza

---

## 🔧 Continuous Compliance — Otomatik Kanıt

### Idea: Her kontrol için **automated evidence**
```
Kontrol: "Tüm prod erişim MFA korumalı"
   │
   ▼
Kanıt: AWS IAM API → MFA-enabled user listesi
   │
   ▼
Periyot: Her hafta otomatik scan
   │
   ▼
Storage: S3 bucket (immutable, audit-only)
   │
   ▼
Audit: Sırasında auditor S3'ten okur, dashboard görür
```

### Otomatik kanıt toplayıcı (örnek)
```yaml
# .github/workflows/compliance-evidence.yml
name: Compliance Evidence Collection

on:
  schedule:
    - cron: '0 2 * * 1'   # Her pazartesi 02:00

jobs:
  collect:
    runs-on: ubuntu-latest
    steps:
      - name: AWS IAM users + MFA
        run: |
          aws iam list-users --query 'Users[*].[UserName, CreateDate]' \
            --output json > evidence/iam-users-$(date +%F).json
          aws iam list-mfa-devices > evidence/mfa-$(date +%F).json

      - name: K8s RBAC dump
        run: |
          kubectl auth can-i --list --as=<USER> > evidence/rbac-$(date +%F).txt
          kubectl get clusterrolebindings -o yaml > evidence/crb-$(date +%F).yaml

      - name: Backup status
        run: |
          aws backup list-backup-jobs --by-state COMPLETED \
            --output json > evidence/backups-$(date +%F).json

      - name: Upload to immutable S3
        run: |
          aws s3 cp evidence/ s3://<COMPLIANCE_BUCKET>/$(date +%Y/%m/%d)/ \
            --recursive --acl bucket-owner-full-control
```

### Compliance-as-Code tool'lar
| Tool | Niche |
|---|---|
| **Drata** | SaaS, otomatik kanıt collection |
| **Vanta** | SaaS, hızlı SOC 2 başlangıç |
| **Secureframe** | SaaS, multi-framework |
| **Sprinto** | SaaS, ucuz |
| **Strike Graph** | Hybrid |
| **Trustpage** | TPM otomasyonu |

> 🔑 **Drata / Vanta / Sprinto** — startup'ta SOC 2 Type II hazırlığı 12 ay → 4 ay'a düşer. Bütçen varsa kullan.

---

## 📋 Audit Hazırlık Roadmap (12 ay)

### Ay 1-2: Scope + Gap Analysis
- Hangi TSC'ler? (genelde Security + Availability + Confidentiality)
- Mevcut kontroller hangileri?
- Gap listesi

### Ay 3-6: Kontrol Implementasyonu
- Eksik kontrolleri ekle (RBAC, MFA, encryption, audit log)
- Politikaları yaz (security, IR, BCP)
- Tooling: SIEM, MFA enforcement, backup

### Ay 7: Type I Audit
- Snapshot audit (kontroller var mı?)
- Daha hızlı + ucuz
- Customer'a "süreç başladı" sinyal

### Ay 7-12: Observation Period (Type II)
- Tüm kontroller işliyor mu?
- Audit firma quarterly sample alır
- Issue çıkarsa fix + dokümante

### Ay 13: Type II Audit Report
- 6 aylık observation rapor
- Customer'a paylaş

> 🔑 **Drata / Vanta** ile bu süreç **8 ay**'a iner.

---

## 🔍 Audit Day Hazırlık

### Auditor ne ister?
- **Population**: "Tüm prod user listesi" (örn: 47 kişi)
- **Sample**: %10-20 sample (örn: 10 kişi)
- **Evidence**: her sample için kontrol kanıtı
  - "Kullanıcı X için MFA aktif mi?" → screenshot + IAM dump
  - "Kullanıcı X erişimi gerekli mi?" → JIRA ticket + manager onay

### Hızlı evidence dosyası
```
evidence/
├── 2026-Q4-soc2/
│   ├── CC6.1-mfa-screenshots/
│   ├── CC6.2-access-tickets/
│   ├── CC6.3-quarterly-review.pdf
│   ├── CC7.2-incident-log.csv
│   ├── CC7.4-backup-restore-drill.md
│   ├── CC8.1-pr-merges-sample.csv
│   └── CC9.1-threat-models/
```

### Sample question'lara hazırlık
- "Bu PR'ın approver'ı kim, niye bu kişi yetkili?"
- "Bu incident'ın postmortem'i nerede?"
- "Bu cron job'un başarısız olursa kim haberdar olur?"

> 🔑 Auditor **kanıt + tutarlılık** ister. Ad-hoc cevap değil, **dokümantasyon** + log.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Audit gününe 1 ay kala başlamak | Kalitesiz kontroller | 6-12 ay önceden plan |
| Manuel evidence toplama | Audit haftası 80 saat | Continuous + automated |
| Politika dokümanı yok | Auditor "yazılı kontrol yok" | Security policy / IR / BCP |
| Tek kişi tüm kanıtı toplar | Bus factor + burnout | Tool + paylaşımlı sahiplik |
| Tooling kurulu, kullanılmıyor | "Drata var ama gerçek değil" | Onboarding + adoption |
| Sample senin seçeceğin | Cheating, audit invalid | Auditor random sample seçer |
| Continuous compliance ihmal | Yıllık reset | Pipeline gate + automated |
| Customer'a "SOC 2'miz var" iddiası, Type I sadece | Müşteri Type II bekler | Type II için 6+ ay observation |
| Vendor management eksik | Sub-processor compliance kayıp | Vendor due diligence |
| Postmortem yok | CC7.3 ihlal | Blameless postmortem zorunlu |

---

## 📋 SOC 2 Type II Mühendislik Checklist

```
[ ] Scope: Security + Availability + Confidentiality (TSC)
[ ] Audit firma seçildi (Big 4 veya Tier 2)
[ ] Drata / Vanta / equivalent kuruldu
[ ] Politikalar yazılı (security, IR, BCP, change management)
[ ] OIDC + MFA tüm prod erişim
[ ] RBAC: per-team, quarterly review
[ ] Encryption-at-rest (KMS) + in-transit (TLS 1.2+)
[ ] Audit log: cluster + cloud + app → SIEM, 1+ yıl retention
[ ] Vulnerability mgmt: Trivy, Renovate, CVE response policy
[ ] Backup: tested restore drill (quarterly)
[ ] DR plan: RTO/RPO yazılı, tatbikat
[ ] Incident response: blameless postmortem, action tracking
[ ] Threat model: per-service (CC9)
[ ] Vendor due diligence: DPA + sub-processor list
[ ] Change management: CODEOWNERS + required PR review + ArgoCD trail
[ ] Continuous evidence collection (otomatik script)
[ ] Compliance dashboard (Drata / Vanta UI)
[ ] Yeni mühendis on-boarding: SOC 2 farkındalık
[ ] Annual: gap analysis + Type II refresh
```

---

## 📚 Referanslar

- **AICPA SOC 2** — aicpa-cima.com
- **Drata** — drata.com
- **Vanta** — vanta.com
- **OWASP ASVS** (Application Security Verification Standard)
- **CIS Benchmarks**
- **NIST SP 800-53**
- [`KVKK-Practical.md`](KVKK-Practical.md)
- [`GDPR-Engineering.md`](GDPR-Engineering.md)
- [`ISO-27001-Controls.md`](ISO-27001-Controls.md)
- [`Audit-Evidence-Automation.md`](Audit-Evidence-Automation.md)
- [`08-Security/Kubernetes-Hardening.md`](../08-Security/Kubernetes-Hardening.md)
- [`08-Security/SLSA-and-SBOM.md`](../08-Security/SLSA-and-SBOM.md)
- [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md)

---

> *"SOC 2 Type II 'sertifika' değil, **continuous compliance**
> kanıtıdır. Audit gününe sıkıştıran ekip yorulur ve bug'lar
> birikir; **continuous** yapan ekip günde 5 dakika ayırır,
> audit gününde ise 'rapor zaten orada' der."*
