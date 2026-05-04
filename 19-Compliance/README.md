# 19 · Compliance & Legal

> *"Compliance bir 'sertifika asma duvarı' değildir; **mühendislik
> kontrolüdür**. Audit gününe sıkıştıran ekip, her audit ertesinde
> 6 ay yorgun gezer."*

DevSecOps'un yasal-uyum boyutu. KVKK, GDPR, ISO 27001, SOC 2, EU AI
Act, NIS2, PCI DSS — bunların kodla, pipeline'la, K8s policy ile
nasıl **continuous compliance**'a dönüştüğünü anlatır.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`KVKK-Practical.md`](KVKK-Practical.md) | KVKK için mühendislik kontrolleri (data inventory, DPIA, incident notification) |
| [`GDPR-Engineering.md`](GDPR-Engineering.md) | GDPR ile mühendislik temasının olduğu yerler (right-to-erasure, DPA) |
| _`ISO-27001-Controls.md`_ *(yakında)* | Annex A kontrolleri ve hangi tool/policy karşılar |
| _`SOC2-Type2-Prep.md`_ *(yakında)* | Trust Service Criteria, observation period, evidence collection |
| [`EU-AI-Act.md`](EU-AI-Act.md) | AI sistemi sınıfları, high-risk uyumluluk yükümlülükleri |
| _`NIS2-Directive.md`_ *(yakında)* | EU NIS2 — kritik altyapı güvenlik gereklilikleri |
| _`PCI-DSS-4.md`_ *(yakında)* | Kart verisi işleyen sistemler için PCI DSS v4 değişiklikleri |
| _`Audit-Evidence-Automation.md`_ *(yakında)* | "Audit gününe hazırlık" değil, otomatik kanıt toplama |

## Felsefe

> Compliance = **mühendislik kontrolü** + **kanıt**. Kontrol kodda
> yaşar (Kyverno policy, audit log, SBOM, SLSA provenance). Kanıt
> CI/CD'den otomatik üretilir. **Audit günü** sadece toplanır.

## Türkiye spesifik notlar

- **KVKK**: KVK Kurumu denetimleri, 72 saat ihlal bildirimi,
  Veri Sorumluları Sicil Bilgi Sistemi (VERBİS) kayıt
- **BDDK / SPK**: Finansal sektör spesifik
- **TC Cumhurbaşkanlığı Dijital Dönüşüm Ofisi** (CBDDO) standartları
- **Veri ihracı**: Bulut servisleri için yasal gereklilikler

## Compliance ↔ Diğer bölümler

| Compliance ihtiyacı | Hangi mühendislik kontrol karşılar | Repo'da nerede |
|---|---|---|
| Audit log | Cluster + cloud + app audit | [`08-Security/Kubernetes-Hardening.md`](../08-Security/Kubernetes-Hardening.md) |
| Encryption at rest | etcd KMS, DB TDE, S3 SSE | [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md) |
| Encryption in transit | mTLS, TLS 1.2+ | [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md) |
| Access control | OIDC + RBAC + MFA | [`08-Security/Zero-Trust-Networking.md`](../08-Security/Zero-Trust-Networking.md) |
| Vulnerability mgmt | Trivy + Renovate + Dependency-Track | [`08-Security/Container-Image-Scanning.md`](../08-Security/Container-Image-Scanning.md) |
| Change control | Git + ArgoCD + signed commits | [`06-GitOps/ArgoCD-Setup.md`](../06-GitOps/ArgoCD-Setup.md) |
| Incident response | Runbook + IC role + postmortem | [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md) |
| Backup + DR | WAL-G + restore drill | [`10-Databases-Production/Postgres-Production-Guide.md`](../10-Databases-Production/Postgres-Production-Guide.md) |
| Threat modeling | STRIDE + LINDDUN | [`08-Security/Threat-Modeling.md`](../08-Security/Threat-Modeling.md) |

## Anti-pattern'ler

- ❌ Audit gününe sıkıştırma — 3 ay öncesi başla, kanıtı otomasyona devret
- ❌ "Compliance security ekibinin işi" — mühendis kontrolleri kod'a koyar
- ❌ "Sertifikamız var" → continuous değilse 6 ay sonra drift
- ❌ Compliance dokümantasyon Confluence'ta, kod ayrı yerde — Markdown koddaki yerinde
- ❌ Auditor'a "biz yapıyoruz" diyebilmek için süslü sunumlar — kanıt = log + policy + pipeline
