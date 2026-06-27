---
description: "PCI DSS v4.0 rehberi: kart verisi işleyen sistemler için mühendislik gereksinimleri, tokenization stratejisi, scope reduction ve TR e-ticaret bağlamı."
---
# PCI DSS v4.0 — Kart Verisi İşleyenler İçin

> *"Kredi kartı verisi tutuyorsan **PCI DSS** zorunluluk. v4.0
> 2024'te yürürlükte, 2025 sonu **tam uyumluluk** dedline.
> Tokenization yapmayan ekip, **6 ay** içinde compliance migration
> yaşayacak."*

Bu rehber PCI DSS v4.0'ın mühendislik gereksinimlerini, tokenization
stratejisini, scope reduction'ı ve TR e-ticaret bağlamını anlatır.

> ⚠️ **Yasal danışmanlık değildir.** PCI DSS QSA (Qualified Security
> Assessor) ile kapsam belirlenir.

---

## 🎯 PCI DSS Nedir?

> **PCI DSS** (Payment Card Industry Data Security Standard): Kart
> verisi işleyen tüm şirketler için PCI Council tarafından zorunlu
> güvenlik standardı.

### Kapsam
- **Cardholder Data (CHD)**: PAN (kart no), expiry, isim
- **Sensitive Authentication Data (SAD)**: CVV, full magnetic stripe, PIN
- → **SAD asla saklanamaz** (auth sonrası)

### Tier'lar (yıllık transaction sayısına göre)
| Tier | Tx/yıl | Audit |
|---|---|---|
| Level 1 | 6M+ | On-site QSA audit, ROC |
| Level 2 | 1-6M | SAQ + scan |
| Level 3 | 20K-1M | SAQ + scan |
| Level 4 | < 20K | SAQ |

> 🔑 SaaS startup'ı **çoğunlukla Level 4**. Büyüdükçe Level 3-2'ye geçer.

---

## 🛡️ PCI DSS v4.0 — 12 Requirement

### Network Security
1. **Install and maintain firewall** → NetworkPolicy + cloud SG
2. **Secure system configurations** → CIS Benchmark + Kyverno

### Cardholder Data Protection
3. **Protect stored cardholder data** → encryption + tokenization
4. **Encrypt transmission** → TLS 1.2+ + mTLS

### Vulnerability Management
5. **Anti-malware** → Trivy + Falco
6. **Secure systems and apps** → SAST + SCA + patching

### Access Control
7. **Restrict access (need-to-know)** → RBAC least privilege
8. **Identify and authenticate** → OIDC + MFA
9. **Restrict physical access** → Datacenter (cloud provider'ın işi)

### Network Monitoring
10. **Track all access to cardholder data** → audit log + SIEM
11. **Test security regularly** → pentest + scan

### Policy
12. **Maintain policy + program** → ISMS, training, IR plan

---

## 🎯 Scope Reduction — En Önemli Strateji

> "PCI DSS ne kadar az scope, o kadar az iş."

### Strateji 1: Tokenization (önerilen)
```
[User] → [Payment Gateway: Stripe / Iyzico]
           │
           │ Real PAN gateway'de
           │ Token bizim DB'mizde
           ▼
[Bizim DB: tok_abc123, tok_def456...]
```

→ **Senin sistemin asla PAN görmez**. Iyzico/Stripe PCI compliance'ını sağlar; sen sadece token görürsün → **scope drastically küçülür**.

### Strateji 2: Hosted Payment Page
```
[User] → [Stripe Checkout / Iyzico Hosted]
           │ kart bilgisi direct gateway'e
           │ senin app görmez
           ▼
[Webhook: success/fail token]
```

→ Bizim domain'imizde iframe → kart input gateway'in domain'inde. Sen tokenize sonucu alırsın.

### Strateji 3: Direct Storage (kaçın)
```
[User] → [Bizim app] → [Encrypted DB: PAN]
```

→ Senin sistem PCI scope'unda **tam**. Yıllık on-site QSA audit gerekir. **Sadece zorunlu** kal.

> 🔑 **2026 önerisi**: Tokenization. PAN'ı asla DB'nde tutma. Scope %90 azalır.

---

## 🇹🇷 Türkiye Ödeme Pazarı

### Yerli Payment Gateway'ler
- **Iyzico** (Türk Telekom subsidiary) — TR e-ticaret en yaygın
- **PayU** — global
- **iPara** — yerli
- **Param** — yerli
- **Garanti BBVA Sanal POS** — bank-direct

### TR-spesifik düzenlemeler
- **BDDK** (Bankacılık Düzenleme ve Denetleme Kurumu): finansal yaptırımlar
- **TCMB**: ödeme sistemleri
- **KVKK**: kart verisi de kişisel veri (Madde 6 kapsamında özel nitelikli değil ama GDPR'da finansal data hassas)

### TR'de PCI DSS zorunluluğu
- Bankalar zorunlu (Visa/Mastercard kuralı)
- Sanal POS sağlayıcılar Level 1
- E-ticaret merchant'lar tier'a göre

---

## 🛠️ Mühendislik Kontrolleri

### 1. Network Segmentation (Req 1)
```
[Public Internet]
     │
     ▼
[DMZ: WAF + LB]
     │
     ▼
[App tier (NetworkPolicy default-deny)]
     │
     ▼
[Cardholder Data Environment (CDE)]
  - Ayrı namespace / cluster
  - Cross-talk yasak (NetworkPolicy)
  - Audit log yoğun
```

### 2. Tokenization Service
```python
# Tek API çağrısı, gateway'e proxy
async def charge_card(amount, card_token):
    # Token → Iyzico/Stripe API
    response = await payment_gateway.charge(
        amount=amount,
        token=card_token,  # bizim DB'de bu var, gerçek PAN değil
    )
    return response

# DB schema:
# CREATE TABLE payments (
#   id UUID,
#   user_id UUID,
#   card_token VARCHAR(255),  ← token, PAN değil
#   amount DECIMAL,
#   created_at TIMESTAMPTZ
# );
```

### 3. Encryption (Req 3, 4)
- **At rest**: KMS-backed disk encryption + per-column encryption (pgcrypto)
- **In transit**: TLS 1.2+, mTLS service-to-service
- **Key rotation**: yıllık + on-demand

### 4. Logging (Req 10) — Strict
```python
# Her CHD-related event log'a düşer
audit_log.write({
    "timestamp": now(),
    "user_id": user_id,
    "action": "view_payment_history",
    "ip": request.ip,
    "session_id": session_id,
    # PAN ASLA log'a düşmez!
    "card_last4": card.last4,   # sadece son 4 hane OK
    "result": "success"
})
```

> ⚠️ **Log'da PAN, CVV, full magnetic stripe ASLA**. `last4` veya BIN (ilk 6) OK.

### 5. Access (Req 7-8)
- OIDC + MFA enforce
- "Need-to-know" — kim CHD görebilir?
- Quarterly access review

### 6. Vulnerability Mgmt (Req 6)
- Quarterly external scan (ASV — Approved Scanning Vendor)
- Annual penetration test
- CVE response: CRITICAL < 7 gün, HIGH < 30 gün

### 7. Anti-malware (Req 5)
- File integrity monitoring (Falco / Aide)
- Trivy + cosign image verify
- Runtime: Falco / Tetragon

---

## 📋 PCI DSS Mühendislik Checklist

```
[ ] Scope tanımı: tokenization ile %90 reduce
[ ] Payment gateway entegrasyonu (Iyzico / Stripe / vb.)
[ ] PAN asla bizim DB'mizde değil
[ ] CDE (Cardholder Data Environment) ayrı namespace/cluster
[ ] NetworkPolicy default-deny + spesifik allowlist
[ ] WAF (Cloudflare / ModSecurity) prod'da
[ ] Encryption: KMS-backed + per-column (pgcrypto)
[ ] TLS 1.2+ + mTLS service-to-service
[ ] Quarterly key rotation
[ ] OIDC + MFA tüm CDE erişim
[ ] RBAC: need-to-know
[ ] Quarterly access review (audit log + raporla)
[ ] Audit log: 1+ yıl retention, immutable
[ ] PAN log'a düşmüyor (sadece last4 / BIN)
[ ] Trivy + cosign + Kyverno image verify
[ ] Quarterly external scan (ASV-approved)
[ ] Annual pentest (PCI-qualified vendor)
[ ] CVE response SLA (CRIT < 7 gün)
[ ] File integrity monitoring (Falco / Aide)
[ ] Runtime security (Falco / Tetragon)
[ ] Annual SAQ veya QSA audit
[ ] Customer-facing privacy: BDDK + KVKK uyumlu
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| PAN'ı kendi DB'nde tut | PCI scope dev | Tokenization (Stripe/Iyzico) |
| Log'da PAN | Audit fail | last4 / BIN sadece |
| CVV sakla | **Yasak** (SAD) | Auth sonrası sil |
| Tek-cluster prod + CDE birlikte | Scope geniş | Ayrı CDE namespace/cluster |
| Network segmentation yok | Lateral movement | NetworkPolicy + WAF |
| Quarterly scan ihmal | Compliance ihlal | ASV scan otomatik |
| Pentest 3 yılda bir | Annual zorunlu | Annual + delta scan |
| Encryption "Postgres TDE" yetiyor sanmak | Per-column yok | pgcrypto + app-side |
| MFA "bazı user'larda" | Compromise vektörü | Universal enforce |
| Audit log retention 30 gün | < 1 yıl ihlal | 1+ yıl, immutable |

---

## 📚 Referanslar

- **PCI DSS v4.0** — pcisecuritystandards.org
- **PCI Council Quick Reference Guide**
- **Stripe PCI Compliance Guide**
- **Iyzico Developer Docs** — TR pazar
- **BDDK** — bddk.org.tr (TR finansal düzenleme)
- [`KVKK-Practical.md`](KVKK-Practical.md)
- [`SOC2-Type2-Prep.md`](SOC2-Type2-Prep.md)
- [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md)
- [`08-Security/Kubernetes-Hardening.md`](../08-Security/Kubernetes-Hardening.md)
- [`08-Security/Threat-Modeling.md`](../08-Security/Threat-Modeling.md)

---

> *"PCI DSS'in en akıllı strateji'si **kapsam dışında kalmak**.
> Tokenization + hosted payment page = **PCI'a tam uyum** ile **scope
> %90 reduce**. Vendor compliance üzerinden, **bizim mühendislik** çok
> az iş."*
