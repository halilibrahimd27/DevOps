# Golden Paths — "Yeni Servis 5 Dakikada"

> *"Geliştirici 'yeni servis nasıl açılır?' diye sorduğunda Confluence
> linki gönderiyorsan, **golden path'in yok** demektir. Cevap **tek
> form** olmalı; geri kalan otomatik."*

Bu rehber Internal Developer Platform'un kalbi olan **golden path**'leri
— "opinionated yol haritaları" — nasıl tasarlandığını, ne kapsadığını,
ve adoption'u ölçtüğünü anlatır.

---

## 🎯 Golden Path Nedir?

> **Golden Path**: Bir görevi (yeni servis aç, DB ekle, deploy et)
> **opinionated** + **otomatik** yapan, **ekibin standardize ettiği**
> yol.

```
[Geliştirici] → "Yeni Go REST API açacağım"
                     │
                     ▼
              [Backstage Form]
                     │
                     ▼ (5-10 dakika otomasyon)
                ┌────┴─────────────────────────────────────┐
                │                                          │
                │  ✓ GitHub repo (Dockerfile, CI, lint)    │
                │  ✓ Branch protection + CODEOWNERS        │
                │  ✓ Terraform PR (RDS, IAM, S3)           │
                │  ✓ ArgoCD Application                    │
                │  ✓ Datadog dashboard + alarms            │
                │  ✓ PagerDuty rotation atandı             │
                │  ✓ Slack channel açıldı                  │
                │  ✓ Backstage Catalog'a kaydedildi        │
                │  ✓ Vault path açıldı                     │
                │  ✓ Welcome PR: ilk endpoint              │
                └──────────────────────────────────────────┘
```

**Sonuç**: Geliştirici sadece **iş mantığını** yazar. Altyapı = self-service.

---

## 🚦 "Path" vs "Paved Path"

| **Path** (yol) | **Paved Path** (asfalt yol) |
|---|---|
| "Şunu yapabilirsin..." | Otomatik gerçekleştirilen yapılandırma |
| Doküman | Tıklamayla iş |
| Manuel adımlar | Tek form + scaffolding |
| Eskimeye yatkın | Kod = canlı, eskimez |

> 🔑 **Golden = "altın değer" + "asfaltlanmış"** = ekibin önerdiği & kolay olan.

---

## 🪜 Golden Path Olgunluk Modeli

| Level | Durum | Yeni servis süresi |
|---|---|---|
| **L0** | Manuel her şey, "şu kişiye sor" | 2 hafta |
| **L1** | Cookiecutter / template repo | 3 gün |
| **L2** | CLI tool: `mycli new-service` | 4 saat |
| **L3** | Backstage scaffolder + tek form | 30 dakika |
| **L4** | Form + tam otomasyon (Terraform, ArgoCD, Datadog, ...) | 5-10 dakika |
| **L5** | "Compose": kullanıcı componentleri seçer (DB tipi, queue, cache) | 5 dakika |

---

## 🛠️ Tipik Golden Path Kataloğu

Her şirket kendi koleksiyonunu kurar. Yaygın olanlar:

### 1. **Yeni Microservice**
- Go REST API + Postgres
- Python FastAPI + Postgres
- Node Express + MongoDB
- Java Spring Boot + Kafka

### 2. **Yeni Frontend**
- React + Next.js + Tailwind
- Vue + Nuxt
- Angular

### 3. **Yeni Worker / Job**
- Background worker (Celery, BullMQ, Sidekiq)
- Cron job (K8s CronJob)
- Stream processor (Kafka consumer)

### 4. **Yeni Infrastructure**
- DB instance ekle
- S3 bucket oluştur
- VPC peering kur

### 5. **Yeni Library / SDK**
- Internal Go module
- npm package
- Shared TypeScript types

### 6. **Production Onboarding**
- "Mevcut servis prod-ready" path: SLO + alert + dashboard + runbook + on-call atama

---

## 📋 Golden Path Template Anatomi

### Backstage scaffolder template (örnek)
```yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: golang-rest-api
  title: Go REST API
  description: Yeni Go REST API + Postgres + ArgoCD + monitoring
  tags: [recommended, go, rest, postgres]
spec:
  owner: platform-team
  type: service

  parameters:
    - title: Service Bilgileri
      required: [serviceName, ownerTeam, description]
      properties:
        serviceName:
          type: string
          pattern: '^[a-z][a-z0-9-]+$'
          ui:autofocus: true
          description: "Lowercase + dash, örn: payments-api"
        description:
          type: string
        ownerTeam:
          type: string
          enum: [platform-team, payments-team, catalog-team, growth-team]
        slackChannel:
          type: string
          pattern: '^[a-z][a-z0-9-]+$'

    - title: Cloud Resources
      properties:
        cloud:
          type: string
          enum: [aws, gcp]
          default: aws
        region:
          type: string
          enum: [eu-west-1, eu-central-1, us-east-1]
        databaseNeeded:
          type: boolean
          default: false
        cacheNeeded:
          type: boolean
          default: false
        queueNeeded:
          type: boolean
          default: false

    - title: SLO & On-Call
      properties:
        sloAvailability:
          type: string
          enum: ['99.9', '99.95', '99.99']
          default: '99.9'
        onCallRotation:
          type: string

  steps:
    - id: validate
      name: Validate inputs
      action: custom:validate-service-name

    - id: fetch-skeleton
      name: Fetch repo template
      action: fetch:template
      input:
        url: ./skeleton
        values:
          serviceName: ${{ parameters.serviceName }}
          ownerTeam: ${{ parameters.ownerTeam }}
          dbNeeded: ${{ parameters.databaseNeeded }}

    - id: create-repo
      name: Create GitHub repo
      action: publish:github
      input:
        repoUrl: github.com?owner=<ORG>&repo=${{ parameters.serviceName }}
        defaultBranch: main
        protectDefaultBranch: true
        requiredApprovingReviewCount: 1
        requireCodeOwnerReviews: true
        deleteBranchOnMerge: true
        gitCommitMessage: 'Initial scaffold from golden path'

    - id: register-catalog
      name: Register in Backstage Catalog
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps.create-repo.output.repoContentsUrl }}
        catalogInfoPath: '/catalog-info.yaml'

    - id: terraform-pr
      name: Open Terraform PR (cloud resources)
      action: github:create-pr
      input:
        repoUrl: github.com?owner=<ORG>&repo=infra-terraform
        branchName: 'add-${{ parameters.serviceName }}'
        title: 'Add resources for ${{ parameters.serviceName }}'
        body: |
          Auto-generated by Backstage scaffolder.

          - DB: ${{ parameters.databaseNeeded }}
          - Cache: ${{ parameters.cacheNeeded }}
          - Queue: ${{ parameters.queueNeeded }}

    - id: argocd-app
      name: Create ArgoCD Application
      action: github:create-pr
      input:
        repoUrl: github.com?owner=<ORG>&repo=k8s-config
        branchName: 'add-app-${{ parameters.serviceName }}'
        title: 'ArgoCD Application: ${{ parameters.serviceName }}'

    - id: pagerduty-rotation
      name: Create PagerDuty rotation
      action: pagerduty:create-rotation
      input:
        name: '${{ parameters.serviceName }}-oncall'
        team: '${{ parameters.ownerTeam }}'

    - id: slack-channel
      name: Create Slack channel
      action: slack:create-channel
      input:
        name: '${{ parameters.serviceName }}-alerts'

    - id: vault-path
      name: Provision Vault path
      action: vault:create-path
      input:
        path: 'kv/${{ parameters.serviceName }}'
        team: '${{ parameters.ownerTeam }}'

    - id: dashboard
      name: Create Datadog dashboard
      action: datadog:create-dashboard
      input:
        template: 'service-default'
        service: '${{ parameters.serviceName }}'

  output:
    links:
      - title: Repository
        url: ${{ steps.create-repo.output.remoteUrl }}
      - title: View in Catalog
        icon: catalog
        entityRef: ${{ steps.register-catalog.output.entityRef }}
      - title: Terraform PR
        url: ${{ steps.terraform-pr.output.prUrl }}
      - title: ArgoCD Application
        url: 'https://argocd.<DOMAIN>/applications/${{ parameters.serviceName }}'
      - title: PagerDuty Rotation
        url: ${{ steps.pagerduty-rotation.output.rotationUrl }}
      - title: Datadog Dashboard
        url: ${{ steps.dashboard.output.dashboardUrl }}
```

---

## 🏗️ Skeleton Repo İçeriği

```
templates/golang-rest-api/skeleton/
├── catalog-info.yaml          # Backstage Catalog kaydı
├── README.md                  # nasıl başlanır
├── Dockerfile                 # multi-stage, distroless
├── .dockerignore
├── .gitignore
├── go.mod
├── main.go                    # health check + örnek endpoint
├── Makefile                   # standart komutlar
├── .github/
│   ├── CODEOWNERS
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug.yml
│   │   └── feature.yml
│   └── workflows/
│       ├── ci.yml             # build + test + scan
│       └── release.yml        # cosign sign + image push
├── k8s/
│   ├── base/
│   │   ├── kustomization.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── networkpolicy.yaml
│   └── overlays/
│       ├── dev/
│       ├── staging/
│       └── prod/
├── docs/
│   ├── index.md
│   ├── architecture.md
│   ├── runbook.md
│   └── slo.md
├── mkdocs.yml                 # TechDocs
└── tests/
    └── e2e/
```

> 🔑 Skeleton **opinionated**. Test framework, CI, security scan, K8s
> manifest hepsi default. Geliştirici "neyi seçeyim?" soramaz — **standart bu**.

---

## 🎯 Tasarım Prensipleri

### 1. **Opinionated, Eskaping Hatch'li**
- "Sadece şu DB'yi kullanırız" denir → ama **istisna PR ile** mümkün
- Hard-block yerine **convention by default**

### 2. **Hidden Complexity**
- Geliştirici Helm/Kustomize/Terraform bilmek zorunda değil
- Mühendisin görmediği şey: scaffolder bütün PR'ları, secret'ları, alarm'ları kuruyor

### 3. **Quarterly Review**
- Yeni teknoloji çıktığında template güncellenir
- Eskiyen feature flag, deprecated lib temizlenir

### 4. **NPS Ölçümü**
- Her path kullanımı sonrasında "Bu kolay mıydı?" survey
- Sürekli iyileştirme

---

## 📊 Adoption Ölçümleri

| Metrik | Hedef |
|---|---|
| **Path kullanım sayısı** (3 ay) | > 80% yeni servis path'le açılmış |
| **Average onboard süresi** | < 30 dakika |
| **NPS** (path başına) | > 30 |
| **Path bypass oranı** | < 10% (kabul edilen istisna) |
| **Eskiyen path** (60+ gün güncellenmemiş) | 0 |
| **Standardize servis %** | > 90% (catalog-info.yaml var) |

---

## 🔄 Path Lifecycle

```
PROPOSE → BUILD → BETA → GA → MAINTAIN → DEPRECATE
```

### Propose (1-2 hafta)
- RFC: niye yeni path lazım?
- Mevcut benzer path var mı?
- Hangi 3+ servis bunu kullanacak?

### Build (2-4 hafta)
- Skeleton + scaffolder template
- Documentation
- 1-2 pilot servis

### Beta (4-8 hafta)
- 5-10 ekip kullanır
- Feedback toplanır, iyileştirilir
- "Beta" tag'i ile UI'da

### GA (sürekli)
- Path "recommended" tag'i alır
- Adoption ölçülür
- Eski yöntem **deprecated** edilir

### Maintain
- Quarterly review
- Bağımlılık güncellemeleri (otomatik Renovate)
- NPS takibi

### Deprecate
- Path artık önerilmiyor
- Yeni sürüme migration path
- 6 ay sunset

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Path "tek doğru yol" | Bypass'lar başlar | Escape hatch + istisna PR |
| Çok sayıda path (20+) | Karmaşa, seçim paradox | 5-10 well-curated |
| Path eskidi, kimse fark etmedi | Yeni servis eskiyle gelir | Quarterly review + NPS |
| Skeleton'da hardcoded sürüm | Renovate dışı, drift | Variable + auto-bump |
| "Şu an manuel sonra otomatize" | Hiç otomatize edilmez | Path = otomatik veya yok |
| Path olmadan yeni servis prod'a | Standardize değil | Path kullanmadan deploy yasak (warn → block) |
| Adoption ölçülmez | "Path var" kanıt yok | Dashboard + NPS |
| Skeleton'da feature flag yok | Yarım feature merge edilemez | Default flag stack |
| Skeleton'da test yok | Junior copy-paste, test'siz | Default test setup |
| Path'i platform team **tek başına** yazar | Geliştirici ihtiyaçları kaçar | Co-design with first user |

---

## 📋 Golden Path Production Checklist

```
[ ] Backstage scaffolder kurulu
[ ] En az 1 production-grade path (örn: REST API)
[ ] Skeleton: Dockerfile, CI, K8s manifest, test, docs
[ ] Scaffolder template: GitHub + Terraform + ArgoCD + alerts
[ ] CODEOWNERS otomatik atanır
[ ] Branch protection otomatik kurulur
[ ] Catalog-info.yaml otomatik
[ ] TechDocs etkin
[ ] PagerDuty rotation otomatik
[ ] Slack channel otomatik
[ ] Vault path otomatik
[ ] Dashboard otomatik
[ ] Welcome PR (ilk endpoint hazır)
[ ] NPS survey path başına
[ ] Adoption metric dashboard
[ ] Quarterly path review
[ ] Renovate ile dependency auto-update (skeleton'a)
[ ] Documentation: nasıl yeni path eklenir
[ ] Pilot servis ile beta dönemi
[ ] Lifecycle policy (propose → GA → deprecate)
```

---

## 📚 Referanslar

- **Spotify Backstage Scaffolder** — backstage.io/docs/features/software-templates/
- **Roadie Skill Exchange** — roadie.io
- **Platform Engineering Maturity** — platformengineering.org/maturity-model
- [`Internal-Developer-Platform.md`](Internal-Developer-Platform.md)
- [`Backstage-Setup.md`](Backstage-Setup.md)
- [`Service-Catalog.md`](Service-Catalog.md)
- [`Platform-as-Product.md`](Platform-as-Product.md)
- [`02-CI-CD/Pipeline-Patterns.md`](../02-CI-CD/Pipeline-Patterns.md) — CI standardı

---

> *"Golden path 'doc kısayolu' değil — **mühendislik kararının
> kristalleşmesi**. 'En iyi yol' yerine **'kolay olan yol'** olunca,
> herkes kolay olanı seçer; standart **kendiliğinden** yayılır."*
