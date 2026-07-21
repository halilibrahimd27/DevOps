---
description: "2026'da ekiplerin gerçekten kullandığı DevOps çerçeveleri: CALMS, DORA, platform engineering, GitOps, SRE, DevSecOps, FinOps ve operasyonel pratikler."
tags:
  - Roadmap
  - Platform Engineering
  - GitOps
  - SRE
  - DORA
  - FinOps
---
# Modern DevOps 2026 — Metodolojiler, Stratejiler & Kültür

> 2026 itibarıyla *yapan ekiplerin* gerçekten kullandığı çerçeveler,
> pratikler ve toolchain'ler. Buzzword listesi değil — **ne zaman, hangi
> sorunu çözmek için** kullanılır odaklı.

---

## İçindekiler

1. [Felsefe — Niye DevOps Hâlâ Önemli?](#1-felsefe--niye-devops-hâlâ-önemli)
2. [CALMS Çerçevesi — Kültürün Omurgası](#2-calms-çerçevesi--kültürün-omurgası)
3. [DORA Metrikleri & SPACE — Ne Ölçeriz?](#3-dora-metrikleri--space--ne-ölçeriz)
4. [Modern Metodolojiler](#4-modern-metodolojiler)
   - 4.1 [Platform Engineering & IDP](#41-platform-engineering--internal-developer-platform-idp)
   - 4.2 [GitOps](#42-gitops)
   - 4.3 [Site Reliability Engineering (SRE)](#43-site-reliability-engineering-sre)
   - 4.4 [DevSecOps](#44-devsecops--shift-left-security)
   - 4.5 [FinOps](#45-finops)
   - 4.6 [MLOps & LLMOps](#46-mlops--llmops)
   - 4.7 [Sustainability / Green IT](#47-sustainability--green-it)
5. [Cloud-Native Reference Architecture](#5-cloud-native-reference-architecture)
6. [Modern Toolchain Haritası](#6-modern-toolchain-haritası)
7. [Operasyonel Pratikler](#7-operasyonel-pratikler)
   - 7.1 [Blameless Postmortem](#71-blameless-postmortem)
   - 7.2 [Progressive Delivery](#72-progressive-delivery)
   - 7.3 [Chaos Engineering](#73-chaos-engineering)
   - 7.4 [Policy-as-Code](#74-policy-as-code)
   - 7.5 [Supply Chain Security](#75-supply-chain-security--slsa)
8. [Anti-Pattern'ler](#8-anti-patternler)
9. [60–90 Günlük Adoption Planı](#9-6090-günlük-adoption-planı)
10. [Ek Kaynaklar](#10-ek-kaynaklar)

---

## 1. Felsefe — Niye DevOps Hâlâ Önemli?

DevOps, *araç* değil *operasyon modeli*. Aynı şirkette aynı GitHub
Actions, aynı ArgoCD, aynı Prometheus kurulu olabilir; bir ekip haftada
50 kez prod'a çıkar, diğeri ayda 1. Fark kültür ve süreçtedir.

**2026'da değişen ne?**
- Bulut maliyetleri patladı → **FinOps** mainstream.
- Geliştiriciler "platform" bekliyor, "ops ticket" değil → **Platform Engineering** patlaması.
- LLM'ler kod yazıyor → review, test, gözlem yükü artıyor → **AI-assisted ops**.
- Tedarik zinciri saldırıları arttı (xz utils, npm worm'ları) → **SLSA / SBOM** zorunlu.
- AB CSRD, ABD SEC — emisyon raporlama yasal → **sustainable engineering** ölçülüyor.

**Değişmeyen ne?**
- *Yavaş feedback öldürür*. Kısa loop = sağlam sistem.
- *Monitoring olmadan production yok.*
- *Ortak sorumluluk*: "deploy yaptım, kalanı SRE'nin sorunu" diyen ekipler hâlâ batıyor.

---

## 2. CALMS Çerçevesi — Kültürün Omurgası

DevOps'u "kültür" olarak ölçmek için en yaygın çerçeve.

| Harf | Anlam | Pratik karşılık |
|------|---|---|
| **C** ulture | Paylaşılan sorumluluk, blame'siz öğrenme | Postmortem'lar herkese açık, "kim yaptı" yerine "neden mümkün oldu" |
| **A** utomation | El değmez işler | CI/CD, IaC, automated rollback, golden-path templates |
| **L** ean | Akış optimizasyonu, küçük batch | Trunk-based development, feature flag, kısa-ömürlü branch |
| **M** easurement | Veriye dayalı iyileştirme | DORA, SPACE, SLO, error budget tracking |
| **S** haring | Bilgi silosu kırma | Dahili wiki, runbook'lar, "tribe of practice" / community of practice |

> ⚠️ Çoğu şirket **A** ve **M** ile başlar, **C** ve **S**'i ihmal eder.
> Otomasyonun nedenini ve sonucunu paylaşmazsanız, otomasyon "büyücülük"
> olur — yenisi gelinceye kadar bozulmaz, bozulduğunda kimse anlamaz.

---

## 3. DORA Metrikleri & SPACE — Ne Ölçeriz?

### DORA (Google) — Teslimat Performansı

| Metrik | Elite | High | Medium | Low |
|---|---|---|---|---|
| **Deployment Frequency** | On-demand (gün içinde N kez) | Günde–haftada | Haftada–ayda | Ayda–yılda |
| **Lead Time for Changes** | < 1 saat | 1 gün – 1 hafta | 1 hafta – 1 ay | 1 – 6 ay |
| **Change Failure Rate** | 0–15% | 16–30% | 16–30% | 46–60% |
| **Mean Time to Restore (MTTR)** | < 1 saat | < 1 gün | 1 gün – 1 hafta | 1 hafta – 1 ay |

> Yıllık [Accelerate State of DevOps Report](https://dora.dev) bu eşikleri günceller. Hedef: bir sonraki katmana çıkmak, "elite" olmak değil.

### SPACE Çerçevesi — Geliştirici Verimliliği

DORA "delivery" odaklı, SPACE bütünsel:

- **S**atisfaction & well-being
- **P**erformance (kalite, müşteri memnuniyeti)
- **A**ctivity (commit, deploy, PR sayısı)
- **C**ommunication & collaboration
- **E**fficiency & flow (kesintisiz iş)

> 🚫 **Tek metrikle ekibi ölçmeyin.** "Daha çok commit at" desteklenirse, küçük-anlamsız commit'ler çoğalır. SPACE'in tamamı bir arada anlamlıdır.

---

## 4. Modern Metodolojiler

### 4.1 Platform Engineering & Internal Developer Platform (IDP)

**Sorun:** Geliştirici "yeni mikroservis aç"mak için 14 ticket açıyor; her biri 2 gün bekliyor; bilgi 3 ekip arasında dağılmış.

**Çözüm:** Bir **platform ekibi**, geliştiricinin self-service kullanabileceği, opinionated bir "altın yol" (golden path) sunar. Geliştirici platformu *müşteri* olarak kullanır, ops biletleri açmaz.

**Gerçek hayat parçası:**
```
Geliştirici şunu yapar:
  $ idp service create payments --template fastapi-postgres

Arka planda:
  - GitHub repo açılır (template'den)
  - Terraform: RDS, S3, IAM rolleri
  - ArgoCD: yeni Application
  - Prometheus + Grafana: dashboard otomatik
  - PagerDuty: oncall rotation atanır
  - Slack: #payments-alerts kanalı açılır
  - Backstage Catalog'a kaydedilir
```

**Toolchain (2026 popüler):**
- **Backstage** (Spotify) — service catalog ve developer portal
- **Crossplane** — Kubernetes-native cloud control plane
- **Kratix / Score / Humanitec** — platform abstraction
- **Port** — no-code IDP builder

> 📚 *"Team Topologies"* (Skelton & Pais) — platform ekibinin iletişim modeli (`stream-aligned`, `enabling`, `complicated subsystem`, `platform`).

### 4.2 GitOps

**Tanım:** Sistemin arzu edilen durumu Git'te declarative olarak tutulur; bir agent (ArgoCD/Flux) Git'i izleyerek cluster'ı sürekli senkronize eder.

**Dört prensibi (OpenGitOps):**
1. Declarative — sistem **ne** olmalı, **nasıl** değil
2. Versioned & Immutable — Git tek doğruluk kaynağı
3. Pulled Automatically — agent değişiklikleri çeker (push değil)
4. Continuously Reconciled — drift sürekli düzeltilir

**Avantaj:** rollback = `git revert`. Audit log = `git log`. Erişim = GitHub team.

**Toolchain:**
- **ArgoCD** — uygulama deploy
- **Flux** — uygulama deploy (CNCF graduated)
- **Crossplane** — IaC bile GitOps ile
- **Renovate / Dependabot** — bağımlılık güncelleme PR'ları
- **Argo Rollouts / Flagger** — progressive delivery

```yaml
# Tipik ArgoCD Application — uygulama Git'te neyse cluster da o
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: payments-prod
spec:
  source:
    repoURL: https://github.com/acme/k8s
    path: apps/payments/overlays/prod
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: payments
  syncPolicy:
    automated:
      prune: true
      selfHeal: true     # drift düzelt
```

### 4.3 Site Reliability Engineering (SRE)

Google'ın icadı. Ana fikir: *güvenilirliği bir özellik gibi mühendislik et*.

**Anahtar kavramlar:**

- **SLI** (Service Level Indicator) — ölçülen şey: `% successful requests`, `p99 latency`
- **SLO** (Service Level Objective) — hedef: `%99.9 successful in 30d`
- **SLA** (Service Level Agreement) — müşteriyle yasal söz
- **Error Budget** — `100% - SLO` = ne kadar arıza tolere ederiz. **Bu bir pazarlık aracıdır:**
  - Bütçe kalmadıysa → yeni feature deploy DUR, reliability'ye odaklan
  - Bütçe taze → risk al, agresif deploy

```
SLO: %99.9 / 30 gün → Error budget = 43 dakika down/ay
Bu ay 35 dk down olduysa: 8 dk kaldı → riskli deploy yapma.
50 dk down olduysa: bütçe -7 dk → feature freeze, root cause'lara odaklan.
```

**SRE'nin Toil tanımı:** *manuel, tekrarlanan, otomatize edilebilir, value yaratmayan iş*. Hedef: takımın < %50'si toil. Üzerine çıkıyorsa platform yatırımı yap.

> 📚 Google SRE Book + SRE Workbook — ücretsiz online.

### 4.4 DevSecOps — Shift-Left Security

**Eski model:** geliştirme → test → "security review" → patladı, geri başa dön.

**Yeni model:** güvenlik **her aşamada**, otomatik.

```
┌─────── DEV ────────┬───── BUILD ────┬──── DEPLOY ────┬──── RUNTIME ────┐
│ IDE plugins        │ SAST           │ Image scan     │ Runtime         │
│ pre-commit hooks   │ Dependency scan│ IaC scan       │ Detection       │
│ secret detection   │ License scan   │ Policy gate    │ eBPF tracing    │
│                    │ SBOM generate  │ Sigstore verify│ Falco / Tetragon│
└────────────────────┴────────────────┴────────────────┴─────────────────┘
```

**Toolchain:**

| Aşama | Açık kaynak | SaaS |
|---|---|---|
| Secret detection | gitleaks, trufflehog | GitGuardian |
| SAST | Semgrep, CodeQL | Snyk, Veracode |
| SCA / Dep scan | OSV-Scanner, Trivy | Snyk, Mend |
| Container scan | Trivy, Grype | Snyk Container, Wiz |
| IaC scan | Checkov, Trivy (config), KICS | Bridgecrew, Wiz |
| Policy | OPA/Rego, Kyverno | Styra |
| Runtime | Falco, Tetragon, Cilium | Sysdig, Wiz Runtime |
| Supply chain | Sigstore (cosign), in-toto | Chainguard |

> 🔐 **Asgari hijyen 2026:** SBOM üret, image'ı imzala (cosign), prod'da signature doğrula (Kyverno verifyImages), her PR'da `gitleaks` + `trivy fs`.

### 4.5 FinOps

**Sorun:** AWS faturası ay başında patladı; kimse kimin neyi açtığını bilmiyor.

**Çözüm:** **FinOps Foundation** çerçevesi — finans + mühendislik + iş ekipleri ortak dilde maliyet konuşur.

**Üç döngü:**
1. **Inform** — tagging, allocation, dashboard. "Hangi servis ne kadar harcıyor?"
2. **Optimize** — rightsizing, reserved/savings plan, spot, idle resource cleanup
3. **Operate** — anomaly detection, FinOps champion'lar, KPI takibi

**Pratik adımlar:**
- Mandatory tagging policy: `team`, `service`, `env`, `cost-center`
- Showback dashboard (her ekip kendi maliyetini görür)
- Daily anomaly alert (yesterday vs 7-day avg, > %20 sapma)
- Resource right-sizing: VPA recommendations, AWS Compute Optimizer
- Storage lifecycle: S3 Intelligent-Tiering, EBS gp3, snapshot expiration
- Pre-merge cost diff: PR'da Infracost yorumu

**Toolchain:** OpenCost, Kubecost, AWS Cost Explorer, Vantage, CloudHealth, Infracost.

### 4.6 MLOps & LLMOps

**MLOps:** ML modellerinin lifecycle yönetimi (data → train → serve → monitor → retrain).

**LLMOps:** GenAI uygulamalarının operasyonu — RAG pipeline, prompt versiyonlama, eval harness, hallucination/safety monitoring, token cost tracking.

**2026'da LLMOps özgün tarafları:**
- **Prompt'lar kod gibi**: versiyonlu, test'li, A/B'li
- **Eval harness**: model çıktılarını otomatik puanla (LLM-as-judge, golden datasets)
- **RAG observability**: hangi chunk getirildi, hangi soruya kim cevap veremedi
- **Token & latency tracking**: per-tenant cost, p99 < 5s SLO
- **Safety guardrails**: PII redaction, prompt injection detection
- **Model registry**: hangi model versiyonu prod'da, rollback path?

**Toolchain:** LangSmith, Langfuse, Helicone, Phoenix (Arize), MLflow, BentoML, Weights & Biases, Vellum, Promptfoo.

### 4.7 Sustainability / Green IT

**Yasal baskı:** AB CSRD (2024+), ABD SEC iklim kuralı → şirketler emisyonu raporlamak zorunda. Cloud kullanımı **Scope 2/3** emisyona girer.

**Ölçü:**
- **PUE** (Power Usage Effectiveness) — DC seviyesi
- **CUE** (Carbon Usage Effectiveness)
- **SCI** (Software Carbon Intensity, Green Software Foundation) — uygulama seviyesi: gCO₂eq / functional unit

**Pratik:**
- Spot instance (idle kapasite kullanımı)
- ARM/Graviton (per-watt 2-4x performance)
- Region seçimi: yenilenebilir enerji yoğun bölge (us-west-2, eu-north-1)
- Carbon-aware scheduling: idle batch job'ları düşük-karbon saatlerde çalıştır
- Idle cleanup: dev cluster'ları gece kapat
- Compression, caching, CDN — daha az network

**Toolchain:** Cloud Carbon Footprint, Kepler (eBPF), AWS Customer Carbon Footprint Tool, Azure Sustainability, GCP Carbon Footprint.

---

## 5. Cloud-Native Reference Architecture

```
                            ┌──────────────────────────┐
                            │   Edge / CDN / WAF       │
                            │ (Cloudflare, CF Workers, │
                            │  Fastly, AWS WAF)        │
                            └────────────┬─────────────┘
                                         │
                            ┌────────────▼─────────────┐
                            │   API Gateway            │
                            │ (Envoy, Kong, Apollo,    │
                            │  AWS API GW)             │
                            └────────────┬─────────────┘
                                         │
        ┌────────────────────────────────┼────────────────────────────────┐
        │                Service Mesh (Istio / Linkerd / Cilium)          │
        │  mTLS · traffic split · retry · circuit breaker · authZ         │
        ├──────────────┬──────────────┬──────────────┬───────────────────┤
        │ payments     │  catalog     │   auth       │   ml-inference    │
        │ (Go)         │  (TS)        │   (Rust)     │   (Python)        │
        └──────┬───────┴──────┬───────┴──────┬───────┴──────────┬────────┘
               │              │              │                  │
        ┌──────▼──────┐ ┌─────▼──────┐ ┌─────▼─────┐ ┌──────────▼──────┐
        │ Postgres HA │ │ Redis      │ │ Keycloak  │ │ vLLM / Triton   │
        │ + PgBouncer │ │ (cache)    │ │ + OAuth2  │ │ + GPU node pool │
        └─────────────┘ └────────────┘ └───────────┘ └─────────────────┘

         ───── Cross-cutting ─────
         IaC: Terraform + Crossplane (in-cluster)
         GitOps: ArgoCD (multi-cluster, ApplicationSet)
         Secrets: External Secrets Operator + Vault
         Observability: OpenTelemetry → Tempo/Loki/Mimir + Grafana
                         OR Datadog / New Relic / Honeycomb (SaaS)
         Policy: Kyverno + OPA Gatekeeper
         Runtime sec: Falco + Tetragon (eBPF)
         Backup: Velero + cross-region S3
         CI: GitHub Actions / GitLab CI / Buildkite
```

---

## 6. Modern Toolchain Haritası

### 6.1 Versiyon Kontrol & Code Review
GitHub, GitLab, Bitbucket. Trend: **Graphite / Stacked diffs** (büyük PR yerine küçük, sıralı stack).

### 6.2 CI/CD
| Yerleşik | Yeni nesil |
|---|---|
| Jenkins, GitLab CI | GitHub Actions, Buildkite |
| CircleCI, TravisCI | Dagger (CI as code, programmable) |
| TeamCity | Earthly (Make + Docker hibrit) |
|  | Mise (project tool versions) |

### 6.3 IaC
- **Terraform / OpenTofu** — fork sonrası OpenTofu CNCF'e girdi, neutral governance
- **Pulumi** — gerçek programlama dilleri (TS/Python/Go)
- **Crossplane** — Kubernetes API'si üzerinden cloud resource yönetimi
- **AWS CDK / CDK8s / CDKTF** — kod-yazarcasına resource

### 6.4 Container & Orkestrasyon
- **Docker / Podman / nerdctl**
- **Kubernetes** (EKS, GKE, AKS, kubeadm, k3s, talos)
- **Nomad** — daha basit alternatif
- **Wasm / Spin / wasmCloud** — yükselen serverless çalışma zamanı

### 6.5 Observability — "Three Pillars + 1"
| Pillar | OSS | SaaS |
|---|---|---|
| Metrics | Prometheus, Mimir, VictoriaMetrics | Datadog, New Relic |
| Logs | Loki, OpenSearch, ClickHouse | Datadog, Splunk |
| Traces | Tempo, Jaeger | Honeycomb, Lightstep |
| **Profiles** (4. pillar) | Pyroscope, Parca | Polar Signals, Datadog |

> 🌐 **OpenTelemetry**: hepsinin önündeki ortak instrumentation standardı.
> Yeni proje? Doğrudan OTel SDK ile yaz, vendor-lock yok.

### 6.6 Service Mesh
- **Istio** — feature-rich ama heavy
- **Linkerd** — minimal, Rust data plane
- **Cilium Service Mesh** — eBPF, sidecar-less, hızlı

### 6.7 Secret Management
- **HashiCorp Vault** — endüstri standardı
- **External Secrets Operator** — cloud KMS → K8s Secret bridge
- **SOPS + age/PGP** — Git'te şifreli secret
- **Sealed Secrets** (Bitnami)
- **AWS Secrets Manager / GCP Secret Manager / Azure Key Vault**

### 6.8 Database & Data Platform
- **PostgreSQL** — hâlâ %1 sektör default. Patroni / Stolon / Crunchy Postgres for K8s
- **CloudNativePG** operator — K8s-native HA postgres
- **ClickHouse** — analytical, OSS columnar, popülerleşti
- **Kafka / Redpanda** — event streaming
- **DuckDB** — embedded analytics (data engineering'de patlama)

---

## 7. Operasyonel Pratikler

### 7.1 Blameless Postmortem

**Format:**
```markdown
# Postmortem — payment-service outage 2026-04-30

## Özet
3 dakika içinde ne yazılır kullanıcı görür.

## Etki
- 14 dk total downtime
- 3,200 başarısız ödeme
- ~22k EUR revenue impact (estimate)

## Zaman çizelgesi (UTC)
- 14:02  Deploy v3.4.1 (PR #4521)
- 14:05  p99 latency 200ms → 8s sıçradı, alert firing
- 14:07  Oncall page'lendi (PagerDuty rotation)
- 14:11  Rollback başladı
- 14:16  Rollback tamamlandı, latency normalleşti
- 14:30  All-clear

## Root Cause
N+1 sorgu yeni endpoint'te accidentally introduce edildi.
ORM lazy-load aktive olunca her ödeme için 50 ekstra query.

## Niye yakalanmadı?
- Load test sadece 100 RPS'de yapılıyor — N+1 patlamıyor
- Staging'de fixture data 10 satır, prod'da 50

## Aksiyonlar
- [ ] @ali       Load test 1000 RPS'e çıkar     (due 2026-05-15)
- [ ] @ayse      ORM N+1 detector PR pipeline'a ekle (due 2026-05-22)
- [ ] @platform  Staging fixture data hacmini prod 1%'e ölçekle (due 2026-06-01)

## Ne iyiydi?
- Otomatik rollback 4 dakikada gerçekleşti — manuel müdahale yok
- Oncall'un MTTR'i hedef altında

## Ne zor değildi ama olabilirdi?
- Slack'te paralel iletişim runbook'u izlendi
```

**Altın kural:** *"who" yerine "what" ve "why"*. "Ali yanlış kod yazdı" değil, "review sürecimizde N+1 detector yoktu". Sistem hatasıdır, insan hatası değil.

### 7.2 Progressive Delivery

Tek seferde %100 değil, kademeli.

| Strateji | Kullanım |
|---|---|
| **Blue/Green** | Anlık geri dönüş gerekiyor — instant cutover, eski sürüm hot bekler |
| **Canary** | Yeni sürüm %1 → %5 → %25 → %100, metrik gözlerken |
| **Rolling** | K8s default. Pod'lar tek tek değişir. Risk: uzun sürer |
| **Shadow** | Yeni sürüme **kopya** trafik gönder, response'u tutma. Latency'yi gerçek yükle test et |
| **Feature flag** | Kod prod'da ama kapalı. Per-user / per-cohort açma |

**Otomatik canary** araçları (Argo Rollouts, Flagger):
```yaml
# Flagger Canary — metric'e bakarak otomatik ilerle veya geri dön
spec:
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      thresholdRange: { min: 99 }
    - name: request-duration-p99
      thresholdRange: { max: 500 }
```

### 7.3 Chaos Engineering

**Felsefe:** Production'a güvenmek için **kasten** kırın.

**Aşamalar:**
1. **Steady state** tanımla (normal ne demek?)
2. **Hipotez kur**: "Postgres replica düşerse cluster ayakta kalır"
3. **Deney**: replica'yı durdur (önce stage, sonra prod, kontrollü blast radius)
4. **Gözle**: hipotez doğrulandı mı?
5. **Otomatize et** (GameDay → continuous chaos)

**Toolchain:** Chaos Mesh, LitmusChaos, Chaos Monkey, AWS Fault Injection Simulator.

### 7.4 Policy-as-Code

"Allowed mı?" sorusuna kod cevap verir, insan değil.

```rego
# OPA / Rego — sadece imzalı image kabul et
package kubernetes.admission

deny[msg] {
  input.request.kind.kind == "Pod"
  container := input.request.object.spec.containers[_]
  not startswith(container.image, "registry.acme.com/")
  msg := sprintf("image %v allowed registry'de değil", [container.image])
}
```

**Toolchain:** OPA (Gatekeeper), Kyverno, Conftest, Polaris.

### 7.5 Supply Chain Security — SLSA

Build artifact'ının nasıl üretildiğine dair **doğrulanabilir** köken (provenance).

**SLSA Levels:**
- **L1**: build script var
- **L2**: hosted build, imzalı provenance
- **L3**: izole build, kaynaktan kaynağa zincir
- **L4**: iki-kişi review, hermetic + reproducible build

**Pratik:**
- **SBOM** üret (CycloneDX / SPDX) — her image içinde
- **Sigstore (cosign)** ile imzala — keyless OIDC ile
- **in-toto attestation** — build provenance
- Cluster'da **Kyverno verifyImages** ile imza kontrolü

```bash
# Image imzala (keyless, OIDC ile)
cosign sign ghcr.io/acme/payments:v1.2.3

# SBOM üret
syft ghcr.io/acme/payments:v1.2.3 -o cyclonedx-json > sbom.json

# Vulnerability scan SBOM üzerinden
grype sbom:./sbom.json --fail-on high
```

---

## 8. Anti-Pattern'ler

> *"Bu bende olmaz" deyip kontrol edin — büyük ihtimalle bir tane var.*

| Anti-pattern | Ne demek? | Sağlıklısı |
|---|---|---|
| **DevOps Department** | "DevOps takımı" diye bir silo açmak | Kültür yatay, platform takımı + stream-aligned takımlar |
| **Snowflake servers** | El ile kurulmuş, doku biriktiren makine | IaC + immutable infrastructure |
| **Pet pipelines** | Tek-kullanımlık, her servis için ayrı CI yaml'ı | Reusable workflow'lar, golden path |
| **God dashboards** | 80 panel, kimse bakmıyor | SLO-driven dashboard, < 10 panel |
| **Alert fatigue** | Slack #alerts'te saatte 50 alert | SLO-based alerting, "actionable & urgent" filtresi |
| **Secrets in env** | `DB_PASSWORD=...` Git'te | Vault / ESO + Sealed Secrets |
| **Brittle bash glue** | 1500 satır deploy.sh | Terraform + Helm + Argo |
| **Manual approvals everywhere** | Her PR 3 onay | Policy-as-code + automated review |
| **No staging** | Prod = test | Ephemeral preview env'leri (PR başına) |
| **Quarterly releases** | "Build-up edip 3 ayda bir bırak" | Trunk-based + feature flag, günde N kez |
| **Tribal knowledge** | "Ali bilir, sor" | Runbook + on-call training + game day |

---

## 9. 60–90 Günlük Adoption Planı

Hiçbir şey yokken başlayan ekip için. Sırasıyla:

### Hafta 1–2: Görünürlük
- [ ] Tüm prod servislerini envantere geç
- [ ] DORA metriklerini ölç (önce şu anki durum, sonra hedef)
- [ ] On-call rotation kur, basit runbook
- [ ] Slack `#incidents` kanalı + `/incident` komutu (incident.io / FireHydrant)

### Hafta 3–4: Otomasyon Temeli
- [ ] Tüm prod CI'da: SAST, SCA, secret scan
- [ ] IaC: en az 1 servisin altyapısını Terraform'a taşı
- [ ] Golden Dockerfile şablonu (non-root, multi-stage, distroless veya chainguard)

### Hafta 5–6: Observability
- [ ] OpenTelemetry SDK 1 servise entegre
- [ ] SLO tanımla (en az 3 servis için)
- [ ] Error budget burn-rate alert kur
- [ ] Postmortem template + paylaşım kanalı

### Hafta 7–8: Delivery
- [ ] Trunk-based development'a geç (uzun-ömürlü branch'leri öldür)
- [ ] Feature flag servisi (LaunchDarkly / OpenFeature self-host)
- [ ] PR preview env (her PR'a kısa-ömürlü staging)
- [ ] Otomatik canary (Argo Rollouts veya Flagger)

### Hafta 9–10: Güvenlik & Compliance
- [ ] SBOM her build
- [ ] Image imzalama (cosign)
- [ ] Cluster'da Kyverno policy: imzasız image yasak
- [ ] Secret scanning her PR (block on hit)

### Hafta 11–12: FinOps & Sürdürülebilirlik
- [ ] Cost dashboard (Kubecost / OpenCost)
- [ ] Tagging policy enforce
- [ ] Rightsize quick-wins (idle resource cleanup)
- [ ] Ay sonu retro: ne ölçüldü, ne değişti?

> 🎯 **Anti-hedef:** "12 hafta sonra her şey perfect." Asıl hedef:
> ekibin hangi metriği görerek karar verdiği değişmiş olsun.

---

## 10. Ek Kaynaklar

### Kitap
- *The Phoenix Project* — Gene Kim (DevOps roman)
- *The DevOps Handbook* — Kim, Humble, Debois, Willis
- *Accelerate* — Forsgren, Humble, Kim (DORA arkasındaki bilim)
- *Site Reliability Engineering* (Google SRE book) — ücretsiz online
- *The SRE Workbook* — pratik tarafı
- *Team Topologies* — Skelton & Pais
- *Building Secure & Reliable Systems* — Google SRE+Sec
- *Database Reliability Engineering* — Campbell & Majors

### Makale & Blog
- [DORA — State of DevOps Report](https://dora.dev) — yıllık
- [InfoQ DevOps Trends](https://www.infoq.com/devops/) — trend analizi
- [Google SRE Resources](https://sre.google/) — book + workbook + articles
- [Increment](https://increment.com/) — Stripe'ın SRE/Ops dergisi (arşiv)
- [Bytes by Cloudflare / Netflix Tech Blog / Uber Eng / Stripe Eng]

### Topluluk
- **CNCF TAG App-Delivery / TAG Observability** — meeting notes açık
- **DevOps Days** — şehir bazlı konferans (İstanbul DevOpsDays var)
- **SRE Weekly / DevOps Weekly** — newsletter
- **r/devops, r/sre, r/kubernetes**

### Sertifikasyon (sıralı zorluk)
1. **AWS Certified DevOps Engineer Pro** / **GCP Professional Cloud DevOps**
2. **CKA**, **CKAD**, **CKS** (Kubernetes — Linux Foundation)
3. **HashiCorp Terraform Associate / Vault Associate**
4. **Argo Project Certified Associate**
5. **FinOps Certified Practitioner**

> ✏️ **Akıl yürütme:** sertifika ≠ yeteneklik kanıtı. *Kendinize bir
> "production-like lab" kurun, kasten kırın, debug'layın*. Çoğu mülakat
> hikayenizi sorar — sertifika değil.

---

## Kapanış

DevOps "olmuş bir hedef" değil; **bir yön**dür. Bu rehber bugünkü iyi
pratikleri özetler; 2027'de yarısı değişmiş olacak (büyük ihtimalle AI tarafı).

Önemli olan **ölçen, paylaşan, kasten öğrenen** ekipler kurmak.
Toolchain ondan sonra gelir.

> *"You build it, you run it."* — Werner Vogels (CTO, Amazon), 2006
