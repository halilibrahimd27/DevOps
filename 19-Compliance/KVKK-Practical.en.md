---
description: "A practical, DevSecOps-oriented guide to KVKK (Turkey's Personal Data Protection Law, No. 6698): concrete tools and pipeline gates for data inventory, DPIA, encryption, retention and incident notification."
tags:
  - Compliance
  - KVKK
  - Security
  - Policy as Code
  - Incident Response
---
# KVKK in Practice — From an Engineering Perspective

> *"If you don't want KVKK to stay a 'legal text,' you encode it as
> **controls**. Otherwise every post-audit meeting reopens the same
> 'now how does engineering align' debate."*

This guide treats KVKK (Turkey's Personal Data Protection Law, No. 6698)
**from a DevSecOps angle**: data inventory, DPIA, encryption, retention,
incident notification — with concrete tools and pipeline gates. Read it as
a worked example of how a non-EU data-protection regime is translated into
engineering controls.

> ⚠️ **Not legal advice.** It offers control recommendations from an
> engineering perspective; work with your legal team for specific situations.

---

## 🎯 KVKK's 5 Core Obligations (Engineering View)

| Obligation | Engineering equivalent |
|---|---|
| **Lawful processing** (Article 4) | Enforce data minimization, purpose limitation in code |
| **Explicit consent / legal basis** (Articles 5-6) | Consent management platform, audit log |
| **Duty to inform** (Article 10) | Privacy notice, data flow disclosure |
| **Data security** (Article 12) | Encryption, access control, audit, incident response |
| **VERBİS registration** (national data-controllers' registry) | Data-category inventory, periodic update |

---

## 📋 Step 1: Data Inventory — "Which Data, Where?"

The foundation of KVKK: know your **personal-data inventory**. You can't protect what you don't know.

### What counts?
| Data type | KVKK scope |
|---|---|
| Name-surname, national ID (T.C. kimlik) | ✅ Personal |
| Email, phone | ✅ Personal |
| IP address | ✅ Personal |
| Cookie ID | ✅ Personal (device identifier) |
| Location data | ✅ Personal |
| Health, biometrics, criminal, ethnic | ✅ **Special-category** (extra protection) |
| Anonymized statistics | ❌ (but ✅ if a re-identification risk exists) |

### Inventory schema
```yaml
# data-inventory.yaml (in Git, owner per service)
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
      - elasticsearch: logs-*  # ⚠️ logs must not contain PII!
    encryption:
      at_rest: true
      in_transit: true
    legal_basis: contract  # KVKK Article 5(2)(c)
    third_parties: []

  - name: payment_data
    fields:
      - {name: card_token, type: tokenized, retention: "365d"}
    storage:
      - postgres: app.payments
    legal_basis: contract
    third_parties: ["Iyzico"]  # processor
    sensitivity: financial   # ⚠️ extra control
```

### Automatic discovery
```bash
# PII patterns in DB schemas, via Trivy
trivy fs --scanners secret,config db-schemas/

# AWS Macie (scan S3 buckets for PII)
aws macie2 create-classification-job ...
```

---

## 📋 Step 2: DPIA (Data Protection Impact Assessment)

> KVKK Article 28: for high-risk processing, a **DPIA is mandatory**.

### When a DPIA?
- Systematic + large-scale evaluation (e.g. credit scoring)
- Large-scale processing of special-category data
- Systematic monitoring of public spaces
- New technology (AI/ML, biometrics)
- Profiling + automated decision-making

### DPIA template
```markdown
# DPIA: <PROJECT_NAME>
**Date:** 2026-05-04  
**Owner:** @<TEAM>  
**Legal review:** @legal  

## 1. Processing description
<What data, from whom, for what purpose, who accesses it>

## 2. Necessity & Proportionality
- Legal basis: <which KVKK Article 5/6 clause>
- Can the same outcome be achieved with less data?
- Retention period: <X days/months/years>, why?

## 3. Risk assessment (LINDDUN)
| Risk | Likelihood | Impact | Mitigation |

## 4. Controls
| Risk | Control | Status |

## 5. Data subject rights
- Access, rectification, erasure request flow: <link>
- Response time: 30 days
- Automated channel: <portal URL>

## 6. Residual risks
<Risks that can't be mitigated, accepted>

## 7. Approval
- Owner: ___________  Date: _______
- Legal: ___________  Date: _______
- DPO/CISO: ________  Date: _______
```

> 🔑 For LINDDUN, see [`08-Security/Threat-Modeling.md`](../08-Security/Threat-Modeling.md).

---

## 🔐 Step 3: Data Security — KVKK Article 12

### Encryption-at-rest
```sql
-- Per DB column (for special-category data)
CREATE EXTENSION pgcrypto;

-- Store national ID (TC) encrypted
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
- Enforce TLS 1.2+
- mTLS service-to-service
- See [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md)

### Access control + audit
- OIDC + MFA + RBAC
- Audit log → SIEM
- See [`08-Security/Kubernetes-Hardening.md`](../08-Security/Kubernetes-Hardening.md)

### Pseudonymization / anonymization
```sql
-- Pseudonymization: real value in the mapping table
CREATE TABLE user_mapping (
  pseudo_id UUID PRIMARY KEY,
  real_email_hash TEXT  -- SHA-256
);

-- Only pseudo in the working table
SELECT pseudo_id, action FROM events;
```

> ⚠️ **Pseudonymization ≠ anonymization.** Pseudonymized data is still
> in KVKK scope. For full anonymization, use k-anonymity / differential privacy.

---

## ⏱️ Step 4: Retention & Right-to-Erasure

### Retention policy as code
```yaml
# retention-policy.yaml
policies:
  - data: customer_pii
    retention: 1095d  # 3 years
    deletion_method: hard
    legal_hold_check: true

  - data: log_with_ip
    retention: 90d
    deletion_method: hard
```

### CronJob: delete expired data
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

### Right-to-erasure (Article 11)
User erasure request → within 30 days, from all systems:
1. Production DB
2. Backups (anonymize / mark for delete)
3. Log archive
4. Analytics warehouse
5. ML training dataset (may require re-train)
6. Forward to third-party processors

```python
# Single API endpoint, fan-out
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

> 🔑 **Deleting from backups isn't practical.** Two approaches:
> 1. Delete the backup encryption key → the data becomes unreadable
> 2. Backup retention < 90 days → it's gone on the next cycle

---

## 🚨 Step 5: Incident Notification — The 72-Hour Rule

> KVKK Article 12(5): "Notify the Data Protection Authority (KVK Kurumu)
> **as soon as possible** and within **72 hours** of becoming aware of a data breach."

### Engineering flow
```
[Detection]

   ↓ Falco / WAF / IDS / Wazuh

[Triage] (15 minutes)
   - Any personal data?
   - Number of affected people?
   - Time window?
   ↓ If YES...

[Notify Internal]
   - DPO + Legal + Management
   - PagerDuty SEV1
   ↓

[Mitigate]
   - Start the IC process
   - Stop the bleeding
   ↓

[Document]
   - Incident timeline (Scribe)
   - Affected data categories
   - Number of affected people
   - Mitigation
   ↓

[DPA Notification (KVK Kurumu)] (72 hours)
   - kvkk.gov.tr / Data Breach Notification Form
   - Legal team submits
   ↓

[Affected Users] (as soon as possible)
   - Email / SMS
   - Content: what happened, how it affects you, what to do
   ↓

[Postmortem]
   - Blameless
   - Action items + due date
   - Publish within 5 business days
```

### Contents of the DPA (KVK Kurumu) breach notification form
- Incident description (brief)
- Affected personal-data categories
- Number of affected people (may be approximate)
- Likely consequences
- Measures taken or recommended
- DPO contact

> ⚠️ **72 hours goes fast.** A pre-prepared template + decision tree
> must be ready. See [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md).

---

## 📦 Step 6: Data Export — Cross-Border Transfer

KVKK Article 9: cross-border transfer requires **a country with adequate protection**, or
**a written undertaking**, or **explicit consent**.

### The cloud-services problem
- AWS eu-west-1 (Dublin) — EU country, adequate protection
- AWS us-east-1 (Virginia) — **inadequate**, extra mechanism needed post-Schrems II
- GCP europe-west3 (Frankfurt) — EU
- Azure North Europe (Dublin) — EU

> 🔑 **In practice:** Turkey + EU regions as primary; for US regions,
> a processor contract + SCC + technical safeguard.

### SCC (Standard Contractual Clauses)
- EU SCC 2021 model + KVKK adaptation
- Encrypted + access control + audit
- Legal team owns the contract side; the engineer owns the **technical safeguards**

---

## 📋 Engineering Compliance Checklist

```
[ ] Data inventory: each service owns its data-inventory.yaml
[ ] DPIA: mandatory when a new feature involves PII/sensitive data
[ ] LINDDUN threat model (privacy-focused)
[ ] Encryption-at-rest: DB + etcd + S3 + backup
[ ] Encryption-in-transit: TLS 1.2+ + mTLS service-to-service
[ ] Access: OIDC + MFA + RBAC + audit log → SIEM
[ ] Audit log retention: 1+ year (for KVKK audits)
[ ] Retention policy written + enforced via cron
[ ] Right-to-erasure: single API endpoint, fan-out
[ ] Right-to-access: download a data export from the portal
[ ] Right-to-rectification: portal/support channel
[ ] Backup: retention < 90 days or an encryption-key-delete strategy
[ ] Data export: "data residency" in the region-selection decision matrix
[ ] Third-party processor contracts include a DPA
[ ] Cookie notice: opt-in (for analytics, marketing)
[ ] Privacy notice: at every data-collection point
[ ] Incident response: 72-hour playbook + decision tree
[ ] Quarterly: review whether the VERBİS registration is current
[ ] Annual: data inventory audit (any new fields added?)
[ ] Annual: DPIA review for stale ones
[ ] Engineer onboarding: basic KVKK training
[ ] DPO + Legal + Engineering trio coordinate every 3 months
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Right way |
|---|---|---|
| PII leaking into logs | On a breach, the log archive also falls in scope | PII filter, structured log |
| Sharing customer data over Slack DM | Leak vector | Ticketing system, audit |
| Real customer data in test environments | Test DB compromise = prod breach | Synthetic data / anonymized |
| Backup forever | Retention-policy violation | Lifecycle policy + delete |
| Manual erasure — `DELETE` from the DB | Remains in backups, logs, analytics | Fan-out API + audit trail |
| Data inventory in Confluence | Goes stale, nobody updates it | In Git + CI gate (update required in service review) |
| Prepping on audit day | Stress + missing evidence | Continuous compliance, automated evidence |
| Encryption only "for compliance" | Loses defensive value | Encryption on every sensitive flow |
| DPA breach notification in 5 days | Legal violation (72 hours) | IR playbook + 24h notification SLA |
| Data Subject Request (erasure/access) via email | Impossible to track | Portal + ticketing + 30-day timer |

---

## 📚 References

- **KVK Kurumu (Turkey's Data Protection Authority)** — kvkk.gov.tr (and guidance documents)
- **Law No. 6698** — mevzuat.gov.tr
- **VERBİS (data-controllers' registry)** — verbis.kvkk.gov.tr
- **Data Breach Notification Form** — kvkk.gov.tr/SitePages/veri-ihlali-bildirimi
- **GDPR & KVKK comparison** — KVK Kurumu guidance
- **LINDDUN** — linddun.org (privacy threat modeling)
- [`GDPR-Engineering.md`](GDPR-Engineering.md)
- [`08-Security/Threat-Modeling.md`](../08-Security/Threat-Modeling.md)
- [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md)
- [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md)

---

> *"A team that reads KVKK as a 'PDF document' tells the auditor 'that's
> how we do it.' A team that reads it as a **pipeline gate** produces the
> evidence automatically on every deploy. Nobody would guess the two read
> the same law."*

---

> 🎓 **Learning Path:** This document is used as a "read first" resource in the [`F2`](../22-Learning-Path/block-f-judgment/F2-tehdit-uyum.md) module.
