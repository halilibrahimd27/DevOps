# Internal Developer Platform — Niye, Nasıl, Hangi Sırayla

> *"Geliştirici 14 ticket'a soruyor: 'Yeni servis nasıl açılır?' Cevap
> Confluence'ta 47 sayfa olduğunda, ya **doküman** ya **platform**
> yetersiz."*

Bu rehber Internal Developer Platform (IDP) kavramını teknolojiden
önce **kültürel + ürün** bakış açısıyla anlatır, ardından somut
bir yol haritası verir.

---

## 🎯 IDP Nedir? (Yalın Tanım)

> **IDP**: Geliştiricinin *self-service* kullandığı, *opinionated*
> bir "altın yol" sunan iç ürün.

```
┌────────────────────────────────────────────────────────┐
│                  Internal Developer Portal             │
│              (Backstage / Port / Cortex)               │
│                                                        │
│   "Yeni servis aç"  · "Cluster'ım nerede"  · "Loglar"  │
└──────────┬─────────────────────────────────────────────┘
           │
   ┌───────┼─────────────┬─────────────┬────────────┐
   ▼       ▼             ▼             ▼            ▼
[Kubernetes][CI/CD]    [Cloud]    [Monitoring]   [Secrets]
   ↑       ↑             ↑             ↑            ↑
   └───── Platform Engineering Team (kurar, sürdürür) ──┘
```

Geliştirici "altyapı bilmek" zorunda değil; **portal** üzerinden
servis açar, deploy eder, log'a bakar.

---

## 🚦 IDP Niye Lazım?

### Sorunun semptomları
- Her yeni servis 2 hafta DevOps ticket sırasında
- Tek bir kişi "kubectl context" yöneticisi
- Onboarding 1 ay sürüyor
- "Nasıl deploy ediliyor?" sorusunun cevabı şirket içinde değişken
- Production dokümanı 6 ayda bir update'leniyor (rotada eskiyor)

### IDP'nin sözü
- **Self-service** → DevOps ticket'ları %80 azalır
- **Opinionated** → herkes aynı şeyi aynı şekilde yapar
- **Audit + observability** → kim ne yapıyor, otomatik kayıt
- **Onboarding 1 hafta** → portal geliştiriciye "neye dokunabilirsin"i gösterir

---

## ⚖️ DevOps Takımı vs Platform Takımı

| **DevOps takımı** (anti-pattern) | **Platform takımı** (sağlıklı) |
|---|---|
| "Ticket'ı al, çalıştır" | Self-service tools sunar |
| Bilgiyi siler (gatekeeper) | Bilgiyi paylaşır (enabler) |
| Tek-kişi-bağımlı (bus factor 1) | Tools dokümante, multi-owned |
| "Yangın söndürücü" | Yangın önleyici |
| Geliştirici düşman | Geliştirici müşteri |
| Backlog'u yok, ticket cevaplıyor | Roadmap'i var, NPS ölçüyor |

> 🔑 **Felsefe değişimi:** Platform takımı **iç ürün** yapar; ürün
> mühendisleri = müşteriler. Müşteri memnuniyeti ölçülür ve iyileştirilir.

---

## 🌳 Platform Karar Ağacı

```
START
  │
  ├── Şirkette < 50 mühendis?
  │      │
  │      └── EVET → Vendor SaaS (Port, Cortex)
  │             "Build" maliyeti ekonomik değil
  │
  ├── 50 – 500 mühendis?
  │      │
  │      └── EVET → Backstage (self-host) + Crossplane / Terraform
  │             Açık kaynak, esneklik
  │
  └── > 500 mühendis?
         │
         └── EVET → Backstage + custom plugins, dedicated platform org
                In-house build, vendor-neutral
```

---

## 🪜 IDP Olgunluk Modeli

### Level 1: "Wiki + Slack"
- Confluence'ta dokumanlar
- "Slack'te @platform-team" sor
- Yeni servis: 2 hafta

### Level 2: "Scriptler + tooling"
- `cookiecutter` template'leri
- Bash scriptleri "yeni-servis-aç.sh"
- Yeni servis: 3 gün

### Level 3: "Self-service portal"
- Backstage Catalog + Scaffolder
- Standardize edilmiş golden path'ler
- Yeni servis: 30 dakika

### Level 4: "Platform-as-Product"
- NPS ölçümü, developer feedback loop
- Platform team'in roadmap'i, OKR'ları
- Cost transparency (Kubecost)
- Yeni servis: 5 dakika

### Level 5: "Compositional platform"
- Kullanıcı kendi blok'larını seçer (DB, queue, cache)
- Compliance otomatik (SLSA, SOC2 controls)
- Multi-tenant, multi-cloud
- Yeni servis: 2 dakika + "compose"

> 🎯 **Realist hedef (2026, orta-büyük şirket):** Level 3-4. Level 5 nadir.

---

## 🏗️ "Yeni Mikroservis Aç" — Golden Path Anatomi

```
$ portal.<ORG>.com → "New Service"
  │
  ▼
[Form]
  ? Service type:    [REST API ▼ | gRPC | Worker | Cron]
  ? Language:        [Go ▼ | Python | Node | Java]
  ? Database needed: [Postgres ▼ | MongoDB | None]
  ? Service name:    payments-api
  ? Owner team:      @payments-team
  ? Cloud:           AWS
  ? Region:          eu-west-1
  ? Environment:     [dev, staging, prod]

  [Create]
  │
  ▼
[Backend: 5-10 dakika boyunca arka planda yapılan]
  ✓ GitHub repo açılır (template'den)
    - Dockerfile, src/, README, CODEOWNERS, CI workflow
  ✓ Branch protection + required reviews
  ✓ Terraform PR (RDS, IAM role, S3 bucket)
  ✓ ArgoCD Application (k8s-config repo'da)
  ✓ Datadog dashboard (servis için template)
  ✓ PagerDuty rotation (owner team)
  ✓ Slack channel #payments-api-alerts
  ✓ Backstage Catalog kaydı
  ✓ TechDocs (auto-generated README)
  ✓ Vault path açılır (secret store)
  ✓ Welcome PR: "Servisinin ilk endpoint'i hazır, deploy edebilirsin"
  │
  ▼
[Sonuç]
  Geliştirici: "git clone <REPO> && deploy"
  Toplam süre: ~10 dakika
  Geliştirici platform bilgisi: 0
```

---

## 🛠️ Backstage — Pratik Başlangıç

### Kurulum (Helm)
```bash
helm install backstage backstage/backstage \
  -n backstage --create-namespace \
  --set ingress.enabled=true \
  --set ingress.host=portal.<DOMAIN>
```

### Catalog: servis envanteri
```yaml
# catalog-info.yaml (her repo'nun root'unda)
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: payments-api
  description: Payments REST API
  annotations:
    github.com/project-slug: <ORG>/payments-api
    backstage.io/techdocs-ref: dir:.
    pagerduty.com/integration-key: <KEY>
    grafana/dashboard-selector: "tag in (payments,api)"
spec:
  type: service
  lifecycle: production
  owner: payments-team
  system: payments
  providesApis:
    - payments-rest-api
  dependsOn:
    - resource:postgres-payments-db
```

### Scaffolder Template: yeni servis
```yaml
# templates/golang-rest-api/template.yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: golang-rest-api
  title: Go REST API
spec:
  parameters:
    - title: Service info
      properties:
        serviceName: {type: string, pattern: '^[a-z][a-z0-9-]+$'}
        ownerTeam: {type: string}
        databaseNeeded: {type: boolean, default: false}

  steps:
    - id: fetch
      name: Fetch template
      action: fetch:template
      input:
        url: ./skeleton
        values: {serviceName: '${{ parameters.serviceName }}'}

    - id: publish
      name: Create GitHub repo
      action: publish:github
      input:
        repoUrl: github.com?owner=<ORG>&repo=${{ parameters.serviceName }}
        defaultBranch: main
        gitCommitMessage: 'Initial commit from scaffolder'

    - id: register
      name: Register in catalog
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps.publish.output.repoContentsUrl }}
        catalogInfoPath: '/catalog-info.yaml'

  output:
    links:
      - title: Repository
        url: ${{ steps.publish.output.remoteUrl }}
      - title: View in Catalog
        icon: catalog
        entityRef: ${{ steps.register.output.entityRef }}
```

### TechDocs: markdown-as-docs
```yaml
# Repo'nun mkdocs.yml
site_name: 'Payments API'
plugins:
  - techdocs-core
nav:
  - Home: index.md
  - Architecture: arch.md
  - Runbook: runbook.md
```

Backstage repo'yu çekip markdown'ı render eder, search'le bulunur.

---

## 🎯 IDP'nin "Olmazsa olmaz" Bileşenleri

| Bileşen | Niye |
|---|---|
| **Service catalog** | Servisleri, ownership'i, dependency'i tek yerden gör |
| **Golden path / scaffolder** | "Yeni servis aç" 5 dakikada |
| **TechDocs** | Doküman koddaki yerinde, eskimemeli |
| **Search** | "Hangi servis Postgres kullanıyor?" cevabı 5 saniyede |
| **Dashboards** | Servis sahibi metrikleri, log'ları, deploy'ları görür |
| **Cost insights** | Kim ne kadar harcıyor (Kubecost, FinOps) |
| **On-call** | PagerDuty rotation portal'dan görünür |
| **Compliance** | "Hangi servis SOC2 kontrol altında?" otomatik |

---

## 📊 Platform-as-Product Metrikleri

| Metrik | Hedef | Nasıl ölçülür |
|---|---|---|
| **NPS** (developer satisfaction) | > 30 | Quarterly survey |
| **Lead time: idea → prod** | < 1 gün | Backstage'de tracking |
| **MTTR** (issue → resolved) | < 4 saat | PagerDuty + tracking |
| **Onboarding süresi** | < 1 hafta | Yeni mühendislere ölçüm |
| **Self-service oranı** | > %80 | DevOps ticket / total request |
| **Platform availability** | > 99.9% | Backstage uptime |
| **Adoption rate** | > %90 | Servisler portal'da kayıtlı / toplam |

> 🔑 **Kuralı:** Hedef koymayan platform, "ihtiyaç var mı yok mu" sorusuna
> cevap veremez.

---

## 🚧 Build vs Buy Tradeoff

### Build (Backstage)
- ✅ Esnek, custom plugin
- ✅ Açık kaynak, vendor lock-in yok
- ✅ İç ekosisteme tam entegre
- ❌ Bakım yükü (upgrade, security patch)
- ❌ Plugin yazımı/maintenance
- ❌ İlk değer 2-3 ay sonra

### Buy (Port, Cortex, OpsLevel)
- ✅ Kurulum: bir gün
- ✅ Vendor-managed, upgrade onlar
- ✅ İlk değer 1 hafta
- ❌ Aylık SaaS maliyeti ($X / dev / month)
- ❌ Custom feature için vendor'dan istek
- ❌ Vendor lock-in

> 🔑 **Pratik:** **Önce buy** ile başla, **sonra Backstage'a migrate**.
> Hipotezi düşük maliyetle test et.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Platform "zorunlu" — kullanmayan kovuluyor | Vendor lock-in iç ekipte | Self-service + escape hatch |
| NPS ölçmüyor | Geliştirici neden kullanmadığını bilmiyorsun | Quarterly survey |
| "Bizden geçmeden prod'a çıkamazsın" | Bottleneck, demoralize | Self-service + audit |
| Tüm guardrail hard-block | Bypass'lar başlar (gölge IT) | Soft warning + exception PR |
| Platform team'in kendi backlog'u yok | Sadece ticket → reactive | Roadmap, OKR, demo cycle |
| Backstage instance kurulmuş, kimse kullanmıyor | Adoption marketing yok | Onboarding zorunlu, demo, evangelism |
| Catalog auto-discover yok, manuel | Servis listesi 1 ay eski | GitHub crawler / pipeline-driven |
| Documentation Confluence'ta, kod ayrı yerde | Doküman eskir | TechDocs (markdown koddaki yerinde) |
| Single sign-on yok | Her tool için ayrı login | OIDC herkesin |
| Cost transparency yok | "Kim ne harcıyor" bilinmez | Kubecost, FinOps bölümü |
| Platform takımı 2 kişi, 500 mühendise hizmet | Tükenmişlik, kalite düşer | Min 1:50 ratio |
| 5 farklı portal (CI, CD, monitoring, secrets, ...) | Context switching | Tek portal, embedded plugin'ler |

---

## 📋 IDP Adoption Roadmap

```
[ ] Çeyrek 1 — Discovery
    [ ] Geliştirici survey: nedir 5 büyük friction?
    [ ] Top 10 servis için catalog manuel oluştur
    [ ] Baseline metrik: lead time, ticket count, NPS

[ ] Çeyrek 2 — MVP
    [ ] Backstage / Port kurulumu (HA, SSO)
    [ ] İlk golden path: en sık açılan servis tipi
    [ ] Top 10 servis catalog'a otomatik kayıt
    [ ] TechDocs ilk 5 servis için
    [ ] Dashboard: servis başına Datadog / Grafana embed

[ ] Çeyrek 3 — Adoption
    [ ] 2-3 golden path daha
    [ ] CI/CD entegrasyon (deploy butonu)
    [ ] PagerDuty rotation portal'dan görünür
    [ ] Onboarding: yeni dev için "portal turu"
    [ ] NPS measure (hedef: > 30)

[ ] Çeyrek 4 — Optimization
    [ ] Cost insights (Kubecost)
    [ ] Compliance dashboards (SOC2 controls görünür)
    [ ] Service mesh entegrasyonu
    [ ] Platform team OKR ölçümü
```

---

## 📚 Referanslar

- **Team Topologies** (Skelton, Pais) — Stream-aligned, Platform team örnekleri
- **Backstage** — backstage.io
- **Port** — getport.io
- **Cortex** — cortex.io
- **OpsLevel** — opslevel.com
- **Platform Engineering** — platformengineering.org
- **CNCF Platforms WG** — github.com/cncf/sig-app-delivery
- [`Backstage-Setup.md`](Backstage-Setup.md)
- _`Golden-Paths.md`_ *(yakında)*
- _`Platform-as-Product.md`_ *(yakında)*
- [`00-Culture/Team-Topologies.md`](../00-Culture/Team-Topologies.md)

---

> *"Platform mühendisliği, **diğer mühendislere** sunulan iç bir
> üründür. Yatırımı geri ödendiğinde geliştirici 'eski hayatı nasıl
> yaşıyorduk' diye sorar — bu, başarının en saf göstergesidir."*
