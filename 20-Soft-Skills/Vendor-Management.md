# Vendor Management — Lock-In, Müzakere, Escape Stratejisi

> *"Vendor 'müşteri başına maliyetler artıyor' dediğinde 6 ay
> tartışman vakti. **Migration** 12 ay sürer. Vendor'a bağımlılığını
> ölçmediysen — **müzakere edemezsin**."*

Bu rehber DevOps için vendor seçimi, kontrat müzakeresi, lock-in
ölçümü ve escape stratejisini somut tekniklerle anlatır.

---

## 🎯 Vendor Olgunluk Soruları

Yeni vendor seçerken önce şu soruları sor:

### Teknik
- Açık standartlara uyuyor mu? (OpenTelemetry, OCI, OAuth, OIDC)
- API gateway mı, lock-in mi (proprietary protocol)?
- Self-host alternatifi var mı?
- Data export tam mı? Hangi format?
- SLA / uptime garantisi?

### Operasyonel
- Multi-region destek?
- DR / backup vendor tarafında mı?
- Audit log erişimi var mı?
- SCIM / SSO destek?

### Yasal
- Data residency seçeneği var mı?
- DPA (Data Processing Agreement) imzaları?
- SOC 2 Type II / ISO 27001 sertifikası?
- KVKK uyumu (TR müşteri için)?
- Vendor compromise → bizi nasıl etkiler?

### Finansal
- Contract süresi (ne kadar bağlı kalıyoruz)?
- Cancel / scale-down terms?
- Müşteri başına / kullanım başına / sabit?
- Hidden fee'ler (egress, support tier)?

---

## 🔒 Lock-In Ölçümü

### "Migration süresi" testi
> Hayali olarak: bu vendor'dan **alternatif'e** geçmek **kaç hafta** sürer?

| Süre | Risk |
|---|---|
| < 1 hafta | Düşük lock-in (commodity) |
| 1-4 hafta | Kabul edilebilir |
| 1-3 ay | Yüksek lock-in |
| 6+ ay | **Critical lock-in** — müzakere imkansız |

### Lock-in örnekler
| Vendor | Lock-in seviyesi | Niye |
|---|---|---|
| AWS RDS PostgreSQL | Düşük | Postgres open-standard, dump/restore |
| AWS DynamoDB | Yüksek | Proprietary API, query patterns |
| AWS Lambda | Yüksek | Vendor-specific runtime, IAM |
| Datadog | Orta | OpenTelemetry export var ama dashboard'lar bağlı |
| Snowflake | Yüksek | Proprietary SQL extensions |
| GitHub | Orta | Git portable, ama Actions'lar GitHub-specific |
| Slack | Orta | Webhook'lar export edilir, history yarı kayıp |
| Auth0 | Orta | OIDC standard, ama user import/export biçimi |

---

## 🛡️ Lock-In'i Azaltma Pratikleri

### 1. **Soyutlama Katmanı (Repository Pattern)**
```python
# ❌ Direkt vendor SDK
from datadog import statsd
statsd.increment('checkout.completed')

# ✅ Soyut metric interface
class MetricsClient(Protocol):
    def increment(self, name: str, tags: dict): ...

class DatadogMetrics(MetricsClient):
    def increment(self, name, tags):
        statsd.increment(name, tags=tags)

class PrometheusMetrics(MetricsClient):
    def increment(self, name, tags):
        counter.labels(**tags).inc()

# App'te:
metrics: MetricsClient = get_metrics_client()
metrics.increment('checkout.completed', {'plan': 'premium'})
```

→ Vendor değişince sadece **adapter** değişir.

### 2. **Open Standards**
| İhtiyaç | Open standard |
|---|---|
| Container runtime | OCI |
| Auth | OAuth2 / OIDC / SAML |
| Observability | OpenTelemetry |
| Container orchestration | Kubernetes (CNCF) |
| Storage | S3 API (multi-vendor uyum) |
| Service mesh | SMI / Gateway API |
| IaC | OpenTofu (Terraform fork) |

### 3. **Data Export Practice**
- Quarterly: vendor'dan veri export al, parse et, rakam tut
- Export çalışmıyorsa → vendor'da gizli kilit var

### 4. **Multi-Vendor (kritik bağımlılıklar)**
- DNS: Cloudflare + Route53 (failover)
- Monitoring: Datadog + Prometheus (Datadog primary, Prom backup metric)
- Image registry: Harbor + GHCR

---

## 🤝 Müzakere — Pratik Taktikler

### Pre-müzakere hazırlık
1. **Lock-in seviyesi** belirle (yukarıda)
2. **Kullanım metrikleri** topla (vendor 6 ayda ne kadar büyüdü?)
3. **Alternatif vendor'lar listele** (gerçek değerlendirme)
4. **POC done** — alternatif gerçekten çalışıyor mu?

### Müzakere kartları
| Kart | Vendor'a etki |
|---|---|
| Multi-year commitment | %20-40 indirim genelde |
| Reference customer (logo paylaş) | %10-25 indirim |
| Case study yazma | %10-15 indirim |
| Genişletme (yeni team adoption) | İndirim + custom feature |
| Erteleme (Q4 yerine Q2 imza) | Quarter end push'unda %30+ |
| Alternative POC ile çıkış sinyali | Müzakere açılır |

### "Walk away" gücü
> "Alternatif yoksa, müzakere yok."

POC olmadan müzakereye girersen, vendor "ne yapacaksın?" tonunda
durur. **2-3 alternatif vendor + POC** = müzakere gücü.

---

## 📋 Vendor Due Diligence Checklist

```
[ ] Teknik:
    [ ] Open standard uyum
    [ ] API spec public
    [ ] Self-host alternatif
    [ ] Data export tam (verilerinin sahibisin)
    [ ] SLA yazılı (% uptime, credit policy)
    [ ] Multi-region destek
    [ ] Backup / DR yöntemi

[ ] Yasal / Compliance:
    [ ] SOC 2 Type II rapor (son 12 ay)
    [ ] ISO 27001 sertifikası
    [ ] DPA imzalanabilir
    [ ] KVKK / GDPR uyumu
    [ ] Data residency: EU içi seçenek
    [ ] Sub-processor listesi public
    [ ] Breach notification: < 72h

[ ] Operasyonel:
    [ ] Status page public
    [ ] Audit log erişimi
    [ ] SSO / SCIM
    [ ] Customer support tier (TR saat dilimi?)
    [ ] Slack/Discord community

[ ] Finansal:
    [ ] Contract süresi (max 1 yıl tercih)
    [ ] Otomatik renewal yok ya da 90 gün önce notify
    [ ] Cancel terms net
    [ ] Hidden fee'ler (egress, support, overage) açıklanmış
    [ ] Customer count başına vs flat fee
    [ ] Discount: multi-year, volume, multi-product
```

---

## 🚨 Vendor Risk Türleri

### 1. Compromise Risk
Vendor sızdırırsa → senin müşteri verisi sızdı.

**Mitigation**:
- Sub-processor sözleşmesi
- Encryption at vendor side (data sahibi sen)
- Periyodik vendor audit

### 2. Acquisition Risk
Vendor başka şirket aldı → roadmap değişti.

**Mitigation**:
- Multi-year contract
- "Acquisition triggers re-negotiation" clause

### 3. Sunset Risk
Vendor servisi kapatıyor.

**Mitigation**:
- 12 ay ihbar gerektiren clause
- Alternative POC hazır
- Quarterly migration drill (test export)

### 4. Pricing Risk
Vendor fiyat 3x'liyor.

**Mitigation**:
- Price-cap clause (yıllık < %X artış)
- Multi-vendor competition

### 5. Performance Risk
Vendor down, SLA breach.

**Mitigation**:
- SLA credit policy
- Multi-region or multi-vendor failover

---

## 🛠️ Vendor Stack Görünürlüğü

```
[Vendor Stack Inventory]
├── DevOps Tooling
│   ├── GitHub Enterprise        — annual $X
│   ├── ArgoCD (OSS, support: $Y)
│   └── PagerDuty                — per user
├── Cloud
│   ├── AWS                       — pay-as-you-go
│   └── Cloudflare                — flat fee
├── Observability
│   ├── Datadog                   — per host
│   ├── Sentry                    — per event
│   └── Loki (self-hosted)
├── Security
│   ├── HashiCorp Vault           — Enterprise
│   ├── Snyk                      — per repo
│   └── 1Password Business        — per user
├── Productivity
│   ├── Slack                     — per user
│   ├── Notion                    — per user
│   └── Linear                    — per user
└── Other
    ├── Stripe (payments)         — % per tx
    └── Auth0                     — per MAU
```

→ **Quarterly review**: yeni alternatif var mı, fiyat optimize edilebilir mi?

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Vendor seçimi sadece "feature richness" | Lock-in görünmez | 4-boyut: feature + lock-in + cost + ops |
| 1 yıllık contract auto-renewal | Müzakere fırsatı kayıp | Manuel renewal zorunlu |
| Lock-in ölçülmemiş | Migration imkansız belli olunca öğrenilir | Quarterly migration drill |
| Vendor-specific feature ile build | Soyutlama yok | Repository pattern, adapter |
| Multi-year + erken bağlanma | İndirim çok ama esneklik kayıp | İlk 1 yıl monthly, sonra multi-year |
| DPA imzasız vendor | KVKK ihlali | DPA zorunlu |
| Vendor'a tüm secret | Compromise = total | Min privilege principle |
| "Vendor support cevap vermiyor" → tek başına çöz | Maliyet ödenmedi | Support tier upgrade veya escalate |
| POC yok, sadece sales pitch | Surprise prod'da | 4-week POC zorunlu |
| Alternatif vendor takibi yok | Müzakere gücü kayıp | Yıllık alternatif review |
| Cost shock ile haberdar olma | Bütçe sürprizi | Monthly cost alert + threshold |

---

## 📋 Vendor Lifecycle Checklist

```
[ ] Yeni vendor seçimi:
    [ ] 4-week POC
    [ ] 2-3 alternatif değerlendirildi
    [ ] Lock-in ölçüldü
    [ ] DPA imzalandı
    [ ] SLA yazılı

[ ] Aktif vendor:
    [ ] Quarterly cost review
    [ ] Quarterly usage review (over-spending?)
    [ ] Annual contract review (renewal'dan 90 gün önce)
    [ ] Annual vendor satisfaction survey (ekipten)
    [ ] Audit log + access review

[ ] Migration / churn:
    [ ] 90-gün notice vendor'a
    [ ] Data export plan
    [ ] Alternative onboard
    [ ] Cleanup access
    [ ] Postmortem: niye değiştirdik?
```

---

## 📚 Referanslar

- **CNCF Vendor Neutrality** — cncf.io
- **OpenTofu** — opentofu.org (Terraform fork)
- **CIO Vendor Management Frameworks** — Gartner reports
- [`Stakeholder-Management.md`](Stakeholder-Management.md) — vendor ile iletişim
- [`Saying-No.md`](Saying-No.md) — vendor'a "hayır" demek
- [`19-Compliance/KVKK-Practical.md`](../19-Compliance/KVKK-Practical.md) — DPA gereği
- [`08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md) — vendor secret hijyeni
- [`12-FinOps/Cloud-Cost-Allocation.md`](../12-FinOps/Cloud-Cost-Allocation.md) — vendor cost

---

> *"Vendor seçimi 'kullanılabilir mi?' değil, **'kullanmaktan
> vazgeçebilir miyim?'** sorusudur. İkincisinin cevabı 'hayır'sa,
> **gerçek müşteri** sen değilsin — vendor'sın."*
