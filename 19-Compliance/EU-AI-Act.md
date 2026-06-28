---
description: "EU AI Act'in mühendislik açısından pratik rehberi: risk kategorileri, high-risk AI sistem yükümlülükleri ve 2025-2027 kademeli uygulama takvimi özeti."
tags:
  - Compliance
  - AI/LLMOps
  - Security
  - Threat Modeling
---
# EU AI Act — Mühendislik Açısından Pratik Rehber

> *"AI sistemini production'a almadan önce 'high-risk mi?' diye sormayan
> ekip, 2027'de **yüksek-risk** kategorisinin altındaki tüm
> yükümlülükleri retrospektif gözlerken bulacak."*

EU AI Act 2024'te yürürlüğe girdi, kademeli uygulama 2025-2027'de
yoğunlaşıyor. Bu rehber AI sistem geliştiren ekipler için **mühendislik
kontrolü** odağında özet sunar.

> ⚠️ **Yasal danışmanlık değildir.** Hukuk ekibi + AI ekibi ile
> spesifik durumları değerlendirin.

---

## 🎯 Risk Kategorileri

```
        ┌─────────────────────────────────────┐
        │  UNACCEPTABLE RISK (yasaklı)         │
        │  Social scoring, manipulative AI,    │
        │  real-time biometric ID (kamuda)     │
        └─────────────────────────────────────┘
                       ↑ yasak
        ┌─────────────────────────────────────┐
        │  HIGH-RISK                           │
        │  Recruitment, credit scoring,        │
        │  critical infra, law enforcement     │
        │  ⇒ Strict compliance                 │
        └─────────────────────────────────────┘
                       ↑ regülasyon
        ┌─────────────────────────────────────┐
        │  LIMITED RISK                        │
        │  Chatbot, deepfake, emotion det.     │
        │  ⇒ Transparency obligations          │
        └─────────────────────────────────────┘
                       ↑ açıklama
        ┌─────────────────────────────────────┐
        │  MINIMAL RISK                        │
        │  Spam filter, video game AI          │
        │  ⇒ No specific obligation            │
        └─────────────────────────────────────┘
```

### General Purpose AI (GPAI / Foundation Models)
Ayrı kategori. **Systemic risk** taşıyanlar (~10²⁵ FLOPS training) ek yükümlülüklü:
- GPT-4 ölçeği ve üzeri
- Anthropic Claude, Google Gemini, Meta Llama Large

---

## 🔍 "Sistem hangi kategoride?" — Karar Ağacı

```
1. AI sistem mi?
   - Otonomi + makine öğrenmesi/mantıksal karar = EVET
   - Kural bazlı script = HAYIR
   ↓ EVET

2. Yasaklı kullanım mı?
   - Social scoring (kamu)?
   - Real-time biometric ID (kamu, sınırlı)?
   - Manipulative subliminal?
   - Worker emotion detection?
   ↓ HAYIR

3. Annex III'te listelenen high-risk alan mı?
   - Critical infra (su, elektrik, ulaşım kontrol)
   - Eğitim (sınav, öğrenci değerlendirme)
   - İstihdam (CV screening, performance eval)
   - Essential services (kredi, sigorta)
   - Law enforcement
   - Migration / border control
   - Justice / democratic process
   - Biometric ID
   ↓ HAYIR

4. Limited risk mi?
   - Chatbot kullanıcıyla konuşuyor → transparency
   - Deepfake / synthetic media → labeling
   - Emotion recognition → notice
   ↓ HAYIR

5. Minimal risk → standart mühendislik
```

---

## 🛡️ High-Risk AI — Mühendislik Yükümlülükleri

Yüksek-risk AI sistemine **9 zorunluluk**:

### 1. Risk Management System
Ürün lifecycle boyunca risk değerlendirmesi.
```yaml
# risk-register.yaml (Git'te yaşar)
risks:
  - id: R-001
    description: "Bias against gender in hiring scores"
    likelihood: M
    impact: H
    mitigation:
      - Quarterly fairness audit
      - Demographic parity gate in CI
    owner: ml-team
    status: mitigated
    last_review: 2026-04-15
```

### 2. Data Governance
Training data'nın **kalite, representativeness, bias**'ı dokümante.
```yaml
# data-card.yaml
dataset: hiring-2024
size: 150000 samples
sources: ["internal-applications", "external-vendors-X"]
representativeness:
  geography: ["TR", "EU"]
  age: "18-65, distribution table"
  gender: "44% F / 55% M / 1% other"
known_biases:
  - "Underrepresented: applicants over 50 (3%)"
  - "Imbalanced: tech roles M-skewed (75%)"
preprocessing:
  - PII removal
  - duplicate dedup
  - outlier removal (IQR)
quality_checks:
  - Schema validation
  - Drift detection vs baseline
```

### 3. Technical Documentation (Annex IV)
- Sistem tanımı, mimari
- Training methodology
- Performance metrics + limitations
- Risk management system summary

### 4. Record Keeping (Logging)
> Sistemin tüm "decision trace"i kaydedilmeli, **6 ay+** saklı.

```python
# Decision log
audit_log.write({
    "timestamp": now(),
    "model_id": "hiring-classifier-v3",
    "model_hash": "<DIGEST>",
    "input_id": request_id,
    "input_hash": sha256(input),
    "output": prediction,
    "confidence": confidence,
    "feature_importance": top_features,
    "human_review_required": confidence < 0.8
})
```

### 5. Transparency to Users
Kullanıcıya AI sistemi olduğu söylenir, açıklama hakkı:
```
Bu karar otomatik bir AI sistemi tarafından verildi.
Karara itiraz veya açıklama için: <CONTACT>
Sistem son güncelleme: 2026-04-15
```

### 6. Human Oversight
Sistemin çıktısı **otomatik aksiyon** alıyorsa:
- Human-in-the-loop (her karar onay)
- Human-on-the-loop (örnekleme review)
- Override mekanizması zorunlu

### 7. Accuracy + Robustness + Cybersecurity
- Performance metrics monitör (drift, bias)
- Adversarial robustness test
- Model security: input validation, prompt injection
- Bkz [`15-AI-LLMOps/LLM-in-Production.md`](../15-AI-LLMOps/LLM-in-Production.md)

### 8. Conformity Assessment
Pazara sürmeden önce:
- Self-assessment (çoğu durumda)
- Notified body assessment (biyometrik vb.)

### 9. Post-Market Monitoring
Production'da:
- Performance drift alarmı
- Incident reporting (yasal)
- Model retraining + revalidation

---

## 🤖 GPAI / Foundation Model Yükümlülükleri

Sistem geliştiren **provider** (model üreticisi):
- Technical documentation
- Training data summary (telif uyumlu özet)
- Copyright compliance (EU directive)
- Energy consumption disclosure

**Systemic risk** GPAI için ek:
- Model evaluation (red teaming, adversarial)
- Risk mitigation
- Incident reporting
- Cybersecurity protections

> 🔑 **Pratik:** OpenAI, Anthropic, Google, Meta gibi büyük model
> üreticilerin işi. GPAI **kullanıyorsanız** (deployer rolü), high-risk
> kullanım yapıyorsanız 9 yükümlülük size düşer.

---

## 📅 Zaman Çizelgesi

| Tarih | Yürürlük |
|---|---|
| Ağu 2024 | AI Act yasalaştı |
| Şub 2025 | Yasaklı uygulamalar yürürlüğe |
| Ağu 2025 | GPAI obligations + governance |
| Ağu 2026 | High-risk AI (Annex III) compliance zorunlu |
| Ağu 2027 | High-risk AI (Annex I) compliance zorunlu |

> 🚨 **2026-2027 zaman çok kısa.** High-risk kategoride bir sistem
> üretiyorsanız 2025'te başlamamış olmak teknik borç riski.

---

## 💰 Cezalar

| İhlal | Ceza |
|---|---|
| Yasaklı uygulama | Yıllık global ciro %7'si veya €35M |
| Compliance ihlali (high-risk) | %3 / €15M |
| Yanlış bilgi vermek | %1 / €7.5M |

GDPR'dan **daha sert** ceza yapısı.

---

## 🔧 Pratik DevSecOps Pipeline'ı

### CI gate'leri (high-risk model için)
```yaml
on: [pull_request]

jobs:
  ai-act-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>

      - name: Data card present?
        run: test -f data-card.yaml || exit 1

      - name: Model card updated?
        run: |
          if git diff main...HEAD --name-only | grep -q "model.pkl"; then
            git diff main...HEAD --name-only | grep -q "model-card.yaml" || \
              { echo "Model değişti, model-card.yaml güncellenmedi"; exit 1; }
          fi

      - name: Bias / fairness gate
        run: |
          python -m fairness_check --threshold 0.05 \
            --metric demographic_parity \
            --groups gender,age

      - name: Adversarial robustness
        run: pytest tests/adversarial/

      - name: Decision log schema check
        run: python -m audit_schema_validator
```

### Production observability
- Performance drift (accuracy / loss baseline'dan ne kadar uzak?)
- Demographic parity alert
- Data drift (PSI, KL-divergence)
- Decision log retention (6 ay+)

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "AI Act bizim için ne der bilmiyorum" | 2026-2027 yasal risk | Risk classification şimdi yap |
| Model card yok | Teknik dok eksik | Model card her training cycle'da otomatik |
| Training data origin belirsiz | Copyright + bias risk | Data lineage tracking |
| Decision log yok | Audit imkansız, "ben yapmadım" diyemez | Per-prediction structured log |
| Human-in-the-loop yok (high-risk'te) | Madde 14 ihlali | Override + escalation API |
| Bias check release'te | Üretimde fark edilir, geç | CI gate |
| Drift monitoring yok | Model 3 ay sonra çürür | Prometheus drift metric + alert |
| GPAI vendor seçimi compliance kontrol etmemiş | Tedarik zinciri risk | Vendor due diligence |
| "Sadece eğitim için" deyip prod'a alma | "Research" exemption sıkı | Net "purpose" tanımı |

---

## 📋 EU AI Act Mühendislik Checklist (High-Risk Sistem)

```
[ ] Risk classification yapıldı (yasaklı / high-risk / limited / minimal)
[ ] High-risk ise: ürün roadmap'inde "AI Act compliance" aşaması
[ ] Risk register Git'te, quarterly review
[ ] Data card her dataset için
[ ] Model card her model versiyonu için
[ ] Training data lineage (S3 versioning + manifest)
[ ] Bias / fairness audit: CI gate + quarterly manuel
[ ] Demographic parity / equal opportunity metric
[ ] Adversarial robustness test
[ ] Decision log (per-prediction, 6+ ay)
[ ] Human oversight: HITL veya HOTL
[ ] User notification: "AI sistemi" disclosure
[ ] Override / appeal mekanizması
[ ] Drift monitoring + alert
[ ] Post-market monitoring playbook
[ ] Incident reporting prosedürü (AI ihlali)
[ ] Conformity assessment (gerekiyorsa) hukuk ile
[ ] Vendor / GPAI: due diligence + DPA
[ ] Annual: AI Act compliance review
```

---

## 📚 Referanslar

- **EU AI Act metni** — eur-lex.europa.eu/eli/reg/2024/1689
- **EU AI Office** — digital-strategy.ec.europa.eu/en/policies/ai-office
- **NIST AI RMF** — nist.gov/itl/ai-risk-management-framework
- **ISO/IEC 42001** — AI management system standardı
- **EU AI Act Compliance Checker** — artificialintelligenceact.eu
- [`15-AI-LLMOps/LLM-in-Production.md`](../15-AI-LLMOps/LLM-in-Production.md)
- [`08-Security/Threat-Modeling.md`](../08-Security/Threat-Modeling.md) — LINDDUN

---

> *"AI Act 'GDPR'ın AI versiyonu' değildir; **mühendislik disiplini**.
> 'Etik AI' soyut konuşması yerine **CI gate'i + audit log + drift
> alarmı**'na dönüşür. Yasanın amacı bu — uygulamayı kodla."*
