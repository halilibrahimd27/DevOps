---
description: "Backstage Catalog ile servis envanterini tutma, ownership atama, dependency graph görüntüleme ve on-call eşlemesi yapmanın pratik yollarını anlatan rehber."
tags:
  - Platform Engineering
  - SRE
  - Incident Response
---
# Service Catalog — Servis Envanteri, Ownership, Dependency Graph

> *"50 mikroservis var. 'X servisi kim sahipleniyor?' sorusuna 5 dakikada
> cevap veremiyorsan, **ortada servis yok — sahipsiz YAML'lar var**.
> Catalog ekibin **keşfedilebilirliği**dir."*

Bu rehber Backstage Catalog'unu (veya alternatif) servisi inventoride
tutmanın, ownership atamanın, dependency graph görüntülemenin pratik
yollarını anlatır.

---

## 🎯 Service Catalog Nedir?

> **Service Catalog**: Tüm servisleri, ownership'i, dependency'leri,
> dokumanı, lifecycle'ı **tek yerden** görmeyi sağlayan envanter.

```
[Catalog UI]
  │
  ├── Component (servis, library, website)
  │     ├── Owner: payments-team
  │     ├── Lifecycle: production
  │     ├── System: payments
  │     ├── DependsOn: postgres-payments, auth-svc
  │     ├── ProvidesAPIs: payments-rest-api
  │     └── ConsumesAPIs: notification-api
  │
  ├── Resource (DB, queue, cache)
  ├── API (OpenAPI / GraphQL spec)
  ├── System (servisler grubu)
  └── User / Group (ownership)
```

---

## 📋 Backstage Catalog Entity Türleri

| Kind | Ne |
|---|---|
| `Component` | Çalıştırılabilir kod (servis, web, library) |
| `Resource` | Tüketilen kaynak (DB, S3, Vault path) |
| `API` | Servisin sunduğu API spec |
| `System` | İlişkili component'lar (örn: "payments domain") |
| `Domain` | Birden çok system (örn: "Commerce") |
| `User` | Kişi |
| `Group` | Takım |
| `Location` | Catalog kaynağı (Git URL) |

---

## 📝 catalog-info.yaml Örneği

Her servis repo'sunun kökünde:
```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: payments-api
  description: "Payments REST API + Stripe integration"
  annotations:
    github.com/project-slug: <ORG>/payments-api
    backstage.io/techdocs-ref: dir:.
    pagerduty.com/integration-key: <KEY>
    grafana/dashboard-selector: "tag in (payments,api)"
    sentry.io/project-slug: payments-api
    sonarqube.org/project-key: <ORG>_payments-api
    datadoghq.com/dashboard-url: 'https://app.datadoghq.com/dash/integration/payments'
    backstage.io/kubernetes-id: payments-api
    backstage.io/kubernetes-namespace: payments
  tags:
    - go
    - rest
    - payments
  links:
    - url: https://payments.<DOMAIN>
      title: Production
      icon: web
    - url: https://staging-payments.<DOMAIN>
      title: Staging
      icon: web
spec:
  type: service
  lifecycle: production
  owner: group:payments-team
  system: payments
  providesApis:
    - payments-rest-api
  consumesApis:
    - auth-rest-api
    - notification-rest-api
  dependsOn:
    - resource:postgres-payments
    - resource:redis-payments
    - component:auth-service
---
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: payments-rest-api
  description: "Payments API (REST)"
spec:
  type: openapi
  lifecycle: production
  owner: group:payments-team
  system: payments
  definition: |
    openapi: 3.0.0
    info:
      title: Payments API
      version: 1.4.0
    paths:
      /v1/charges:
        post: ...
---
apiVersion: backstage.io/v1alpha1
kind: Resource
metadata:
  name: postgres-payments
  description: "Payments primary DB"
spec:
  type: database
  lifecycle: production
  owner: group:platform-team
  system: payments
```

---

## 👥 Ownership Modeli

### Tek owner kuralı
- Her servisin **bir** owner team'i olmalı
- "Co-owned" → karışıklık, kimse sahiplenmez
- Group entity Backstage'de tanımlı:

```yaml
apiVersion: backstage.io/v1alpha1
kind: Group
metadata:
  name: payments-team
  description: "Payments squad"
spec:
  type: team
  parent: commerce-domain
  children: []
  members:
    - alice
    - bob
    - carol
```

### Ownership değişimi
Bir servis takımdan takıma transfer:
1. RFC: niye + tarih
2. catalog-info.yaml `owner` field güncellenir
3. CODEOWNERS güncellenir
4. PagerDuty rotation transfer
5. Slack channel transfer / archive
6. Documentation update

---

## 🔗 Dependency Graph

### Görsel keşif
Backstage UI'da **System Diagram**:

```
          ┌─────────┐
          │ Frontend │
          └────┬────┘
               │
        ┌──────┼──────┐
        ▼      ▼      ▼
    ┌──────┐ ┌──────┐ ┌──────┐
    │ Auth │ │Payment│ │Catalog│
    └──┬───┘ └──┬───┘ └──┬───┘
       │        │        │
       ▼        ▼        ▼
    ┌──────┐ ┌──────┐ ┌──────┐
    │Users │ │ DB   │ │ DB   │
    │ DB   │ │ Redis│ │ ES   │
    └──────┘ └──────┘ └──────┘
```

### Dependency'leri belirleme
- **Static**: catalog-info.yaml'da `dependsOn`, `consumesApis`
- **Dynamic**: trace data (OTel) → otomatik graph
- **Verify**: PR'da değişen dep doğru mu (CI gate)

### Cross-team dependency uyarı
```yaml
# Auto-detect: bir takım başka takımın servisine dependency ekledi
- alert: NewCrossTeamDependency
  expr: backstage_dependencies_added{across_team="true"} > 0
  annotations:
    summary: "Cross-team dependency: {{ $labels.from }} → {{ $labels.to }}"
```

---

## 🚦 Lifecycle Yönetimi

| Lifecycle | Ne demek | Örnek |
|---|---|---|
| `experimental` | Beta, kullanıma hazır değil | Yeni AI feature |
| `production` | Aktif kullanılıyor | Çoğu servis |
| `deprecated` | Sunset planlanmış | Eski v1 API |
| `archived` | Artık çalışmıyor | Eski 2018 servis |

### Deprecate akışı
```yaml
spec:
  lifecycle: deprecated
  links:
    - url: <NEW_SERVICE_URL>
      title: "Replacement: payments-v2"
```

→ Catalog UI'da deprecated tag, kullanıcı yeni servise yönlendirilir.

---

## 🔍 Catalog Discovery

### Otomatik keşif (önerilen)
```yaml
# app-config.yaml
catalog:
  providers:
    github:
      providerId:
        organization: '<ORG>'
        catalogPath: '/catalog-info.yaml'
        filters:
          branch: 'main'
          repository: '.*'
        schedule:
          frequency: { minutes: 30 }
```

→ Org'taki her repo'da `catalog-info.yaml` varsa otomatik dahil olur.

### CI gate: catalog-info zorunlu
```yaml
# .github/workflows/catalog-validate.yml
- name: Validate catalog-info.yaml exists
  run: test -f catalog-info.yaml || (echo "::error::catalog-info.yaml eksik" && exit 1)

- name: Validate schema
  run: backstage-cli catalog:validate catalog-info.yaml

- name: Validate owner exists
  run: |
    OWNER=$(yq '.spec.owner' catalog-info.yaml)
    # Backstage API'ye git, owner var mı kontrol et
```

---

## 📊 Catalog Health Metrikleri

### Kalite KPI'ları
| Metrik | Hedef |
|---|---|
| **Servisler catalog'da kayıtlı** | %95+ |
| **catalog-info.yaml + ownership** | %100 |
| **TechDocs entegre** | %80+ |
| **Lifecycle field doldurulmuş** | %100 |
| **Dependencies tanımlı** | %70+ |
| **API spec sağlanmış (Component)** | %50+ |
| **Quarterly orphaned services** (sahipsiz) | < 5% |

### Gap raporu
```sql
-- Backstage'de eksik field'ları olan service'ler
SELECT name FROM components
WHERE owner IS NULL OR system IS NULL OR lifecycle IS NULL;
```

---

## 🛠️ Search

```typescript
// Backstage search plugin
const searchClient = useApi(searchApiRef);
const results = await searchClient.query({
  term: 'payments',
  filters: {
    kind: ['Component', 'API'],
    'spec.type': ['service'],
  },
});
```

→ Cross-resource search: "payments" → component, API, dashboard, doc.

---

## 🔄 Service Onboarding (Catalog Tarafı)

### Yeni servis akışı
```
1. Scaffolder template ile repo açılır
   → catalog-info.yaml otomatik dahil
2. Catalog provider 30 dk içinde keşfeder
3. Backstage UI'da görünür
4. PagerDuty / Datadog plugin'leri bağlı
```

### Mevcut servisi catalog'a alma
```bash
# Servis repo'suna catalog-info.yaml ekle
gh repo clone <ORG>/legacy-service
cd legacy-service
cat > catalog-info.yaml <<EOF
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: legacy-service
spec:
  type: service
  lifecycle: production
  owner: group:legacy-maintenance-team
EOF
git add catalog-info.yaml
git commit -m "chore: register in Backstage catalog"
gh pr create
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Catalog manuel YAML, repo dışında | Drift, eskir | Per-repo catalog-info.yaml |
| Owner yok / "co-owned" | Ortak sorumluluk = kimse | Tek team, açık |
| Lifecycle: production hep | Deprecated hâlâ "production" | Yıllık review, deprecate |
| Dependencies tanımlı değil | Graph eksik | dependsOn / consumesApis |
| Catalog'da sahipsiz servisler | Yetim, eskir | Quarterly orphan review |
| TechDocs bağlantısı yok | Doc Confluence'ta, eskir | TechDocs annotation |
| API spec yok | Consumer "endpoint nedir" sorar | OpenAPI / GraphQL spec |
| Custom annotation çok | UI karmaşık | Standardize annotation list |
| Discovery elle, otomatik değil | Yeni servis manuel ekleme | GitHub provider |
| Catalog adoption < %50 | Tool gerçek değer üretmiyor | Onboarding zorunlu |
| Search yok | "Hangi servis X yapıyor?" cevaplanamaz | Search plugin enable |

---

## 📋 Service Catalog Discipline Checklist

```
[ ] Backstage Catalog kurulu (ya da equivalent)
[ ] Otomatik discovery (GitHub provider)
[ ] Tüm prod servisler kayıtlı (>%95)
[ ] Her servis owner team'lı
[ ] Group entity'ler tanımlı
[ ] Lifecycle field her servis için
[ ] System / Domain hiyerarşisi
[ ] dependsOn / consumesApis tanımlı (>%70)
[ ] API spec entegre (OpenAPI / GraphQL)
[ ] TechDocs annotation
[ ] PagerDuty / Datadog / Sentry integration
[ ] CI gate: catalog-info.yaml zorunlu
[ ] Quarterly: orphan services review
[ ] Quarterly: deprecated services cleanup
[ ] Adoption metric dashboard (% kayıtlı)
[ ] Onboarding: yeni mühendis catalog turu
[ ] Search çalışıyor (cross-resource)
```

---

## 📚 Referanslar

- **Backstage Catalog Docs** — backstage.io/docs/features/software-catalog
- **Backstage System Model** — backstage.io/docs/features/software-catalog/system-model
- **Roadie** — roadie.io (Backstage SaaS)
- **Cortex** — cortex.io (Catalog-first IDP)
- [`Internal-Developer-Platform.md`](Internal-Developer-Platform.md)
- [`Backstage-Setup.md`](Backstage-Setup.md)
- [`Golden-Paths.md`](Golden-Paths.md)
- [`Platform-as-Product.md`](Platform-as-Product.md)
- [`00-Culture/Team-Topologies.md`](../00-Culture/Team-Topologies.md)

---

> *"Catalog 'fancy directory' değil — **organizasyonun servis
> haritası**. Bir mühendisin 6 ayda 'her şeyi biliyorum' diyebileceği
> tek yer; **harita olmadan büyüyen ekibin başvurusu**."*
