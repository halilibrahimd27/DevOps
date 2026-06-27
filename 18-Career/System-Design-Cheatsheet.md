---
description: "DevOps/SRE mülakatlarına özgü system design cheatsheet: infra, deploy, observability, disaster recovery ve maliyet sorularını çözmek için sıralı framework."
---
# DevOps/SRE System Design — Cheatsheet

> Geleneksel "Design Twitter" sorularından farklı olarak, DevOps/SRE
> mülakatlarında **infra**, **deploy**, **observability** odaklı sorular gelir.

---

## 🎯 Tipik soru kategorileri

1. **Infrastructure design** — "X için cluster tasarla"
2. **Deployment design** — "Zero-downtime deploy nasıl"
3. **Observability design** — "100 servis için monitoring"
4. **Disaster recovery** — "Multi-region failover"
5. **Cost optimization** — "Bütçeyi nasıl yarıya indirirsin"

---

## 📐 Genel framework (sıralı)

### 1. Clarify requirements (5 dk)

- Functional: Ne yapması bekleniyor?
- Non-functional: Scale (RPS, kullanıcı, veri), SLO (availability, latency), maliyet bütçesi
- Constraints: Cloud vendor, region, compliance (GDPR/HIPAA), team size

### 2. High-level architecture (10 dk)

Çiz: kullanıcı → CDN → LB → API → DB → cache → ...

### 3. Component deep-dive (15 dk)

Bir veya iki bileşeni detaylandır (bottleneck olabilecek).

### 4. Trade-offs (10 dk)

Her kararın "niye bu, niye o değil" — alternatives'i göster.

### 5. Scale & evolution (5 dk)

Bugün 1K RPS, yarın 100K → ne değişir?

---

## 🏗️ Sample 1: "K8s production cluster tasarla — multi-tenant SaaS, 10K kullanıcı, %99.9 SLO"

### Requirements
- 10K kullanıcı, ~5K RPS peak
- Multi-tenant (her tenant izole)
- %99.9 availability → max 43 dk down/ay
- p99 latency < 500ms

### High-level
```
                          ┌──────────────┐
                          │   CDN/WAF    │
                          │  Cloudflare  │
                          └──────┬───────┘
                                 │
                          ┌──────▼───────┐
                          │  API Gateway │
                          │  (Envoy)     │
                          └──────┬───────┘
                                 │
                  ┌──────────────┴──────────────┐
                  │                             │
            ┌─────▼─────┐                ┌──────▼─────┐
            │ EKS Prod  │                │ EKS Prod   │
            │ Region A  │                │ Region B   │
            │ (active)  │                │ (warm DR)  │
            └─────┬─────┘                └────────────┘
                  │
       ┌──────────┼──────────┐
       │          │          │
   ┌───▼──┐  ┌────▼───┐  ┌───▼──────┐
   │ Tenant│  │ Tenant│  │ Platform │
   │  NS   │  │  NS   │  │  NS      │
   │ A,B,C │  │ D,E,F │  │ (shared) │
   └───────┘  └───────┘  └──────────┘
```

### Multi-tenancy
- **Soft:** namespace-per-tenant + ResourceQuota + NetworkPolicy
- **Hard:** vCluster per tenant ya da farklı cluster (compliance gerekirse)
- 10K kullanıcı için soft yeterli; bazı premium tenant için hard

### Cluster topology
- 3 control plane (managed → EKS / GKE / AKS)
- 3 zone, her zone'da 1 node group
- Karpenter ile spot+on-demand mixed
- Min 6 worker, max 60 (HPA driven)

### Key components
- **Ingress:** NGINX Ingress / Gateway API
- **Service Mesh:** Linkerd (basit, hızlı) — istio gerekiyorsa Ambient mode
- **Observability:** kube-prometheus-stack + Grafana + Loki + Tempo
- **GitOps:** ArgoCD ApplicationSet
- **Secret:** External Secrets Operator + AWS Secrets Manager
- **Backup:** Velero
- **Policy:** Kyverno

### DR
- Region B "warm" — k8s-config repo aynı, ArgoCD sync
- DB: Aurora Global (cross-region replication)
- DNS: Route 53 health-check + latency-based routing
- RTO: 15 dk, RPO: 1 dk

### Cost
- Spot %70, on-demand %30 baseline
- 1-year SP for compute baseline
- Reserved EKS control plane (managed, çok değişmez)
- Tagging zorunlu, Kubecost ile per-tenant cost

---

## 🚀 Sample 2: "Zero-downtime deploy strategy — 100 servisli mikroservis"

### Requirements
- Hız: günde 50+ deploy
- Risk: customer-impacting outage olmasın
- Rollback: 5 dk içinde

### Strateji
- **Trunk-based** + feature flag
- **GitOps** (ArgoCD)
- **Argo Rollouts canary:**
  - 5% → pause 5dk → analyze → 25% → pause 10dk → analyze → 100%
- **Analysis template:**
  - error_rate < %0.1
  - p99_latency < threshold
  - SLO burn rate < 1x

### Pre-deploy checks (CI)
- Lint + test + SAST + SCA
- Image build + Trivy scan + cosign sign
- E2E smoke (preview env)

### Post-deploy
- Auto-rollback eğer analysis fail
- Slack notification (deploy + status)
- Datadog deployment marker

### Database migrations
- Expand/contract pattern
- Migration job hook (post-install)
- Backward-compatible mandate
- Asla deploy ortasında `DROP COLUMN`

---

## 🔭 Sample 3: "100 servis için observability stack"

### Pillars + 1
- Metrics: Prometheus (Mimir backend, multi-tenant)
- Logs: Loki (cheap, K8s-native)
- Traces: Tempo (TraceQL, sampling at collector)
- Profiles: Pyroscope (continuous profiling)

### Instrumentation
- **OpenTelemetry SDK** her servis (vendor-neutral)
- OTel Collector cluster-level (sampling, enrichment, routing)

### Sampling strategy
- Head-based sampling: %10 baseline
- Tail-based: error veya slow span %100
- Cost vs detail trade-off

### Alerting
- Alertmanager + PagerDuty
- SLO-based (multi-burn-rate)
- Severity tier: page (SEV-1) / ticket (SEV-2) / log (SEV-3)

### Storage
- Metrics: Mimir, 30 gün hot, 1 yıl cold (S3)
- Logs: Loki, 7 gün hot, 90 gün cold
- Traces: Tempo, 14 gün
- Maliyet: cardinality kontrolü + retention policy

### Visualization
- Grafana, multi-tenant
- Per-team dashboard ownership
- Auto-generated dashboards (per-service template)

---

## 💰 Sample 4: "AWS faturasını %50 düşür"

### Step 1: Visibility
- Tagging policy enforce (her resource taglı)
- Cost Explorer + per-team dashboard
- Anomaly detection

### Step 2: Quick wins
- Idle resource cleanup ($)
- gp2 → gp3 (%20 ucuz)
- Snapshot lifecycle
- Boşta EIP, ELB, NAT GW
- Right-sizing (Compute Optimizer)

### Step 3: Compute strategy
- Karpenter + spot %70
- 1-year SP baseline
- Graviton (ARM) — %20-40 ucuz, performans aynı

### Step 4: Storage
- S3 Intelligent-Tiering
- Lifecycle: 30g IA → 90g Glacier IR → 365g sil
- Logs aggressive retention
- Old AMI deregister

### Step 5: Egress
- VPC Endpoint (S3, DynamoDB)
- CDN front of S3
- Cross-region traffic minimize
- Cloudflare R2 alternative

### Step 6: K8s specific
- Kubecost per-namespace cost
- HPA min replica audit (3 yerine 2 mı yeter?)
- Idle PVC cleanup
- Spot for stateless

### Beklenen: ay 1 = %20 quick wins, ay 6 = %35 toplam, ay 12 = %50

---

## 🌍 Sample 5: "Multi-region active-active setup"

### Trade-off'u söyle (önemli)
> "Active-active gerekli mi? Active-passive (warm DR) genelde yeterli ve
> %50 daha ucuz, çok daha basit. Customer requirement net mi?"

Eğer gerçekten gerekli:

### Data layer
- **Stateless servis:** kolay, her region'da deployment
- **Stateful (DB):** zor
  - Aurora Global (multi-region read, single-write)
  - Spanner / CockroachDB / YugabyteDB (multi-write)
  - DynamoDB Global Tables
  - **CAP theorem** — consistency vs availability trade-off
- **Cache (Redis):** her region'da independent (eventual consistency OK)

### Network
- DNS-based: Route 53 latency-based + health check
- Anycast: Cloudflare / AWS Global Accelerator

### Application layer
- Idempotency (her request retry-safe)
- Distributed transaction → saga pattern
- Conflict resolution (LWW, CRDT)

### Failover
- Automated DNS failover
- Test ayda bir (game day)

### Cost
- 2x compute, 2x DB, cross-region transfer
- Genelde %80-100 maliyet artışı

---

## 🎓 Yaklaşım tüyoları

1. **"Niye?" sorusunu sor** — özellikle multi-region, microservices gibi karmaşıklığa atlama
2. **Trade-off göster** — "X yapardım çünkü Y, ama Z trade-off'u var"
3. **Numbers** — "yüksek scale" değil "10K RPS, 50M users"
4. **Failure mode düşün** — sadece happy path değil
5. **Operability** — "deploy nasıl, observability nasıl, on-call nasıl"
6. **Cost** — gerçek mühendis maliyeti düşünür
7. **Evolutionary** — bugün başlangıç, yarın scale ne olur

---

## 🚫 Anti-pattern'ler (yapma)

- ❌ Tüm buzzword'leri saç ("Kubernetes + service mesh + Kafka + Cassandra + ML pipeline")
- ❌ Tek doğru cevap varmış gibi davran
- ❌ Trade-off söylemeden seç
- ❌ Sayı vermeden "high availability"
- ❌ Vendor lock-in görmezden gel
- ❌ Failure mode'u skip
- ❌ Operations / on-call'u skip
- ❌ Cost'u skip

---

## 📋 Checklist

Mülakatta tasarımı sunmadan önce/sunarken işaretle — her madde sorulmadan kendin kapat:

- [ ] **Requirements netleştirildi** — functional + non-functional (RPS, kullanıcı, SLO, bütçe) yazıldı; varsayım yapma, sor.
- [ ] **Somut sayı verildi** — "high scale" değil "10K RPS, 50M user, p99 < 500ms"; sayısız iddia zayıf görünür.
- [ ] **Her karar trade-off'lu** — "X çünkü Y, ama Z bedeli var"; alternatifsiz seçim olgunluk eksikliği sinyali.
- [ ] **Failure mode konuşuldu** — node/zone/region down, DB failover, cascade; sadece happy path tasarım eksiktir.
- [ ] **Availability hedefi tanımlı** — SLO + error budget; "%99.9 → 43 dk/ay down" gibi bütçeye çevir.
- [ ] **Veri katmanı düşünüldü** — replication, consistency (CAP), backup/restore, RTO/RPO; stateful en zor kısım.
- [ ] **Deploy stratejisi var** — canary/blue-green + rollback yolu; tasarım deploy edilemiyorsa eksik.
- [ ] **Observability planlandı** — metrics/logs/traces + alerting; gözlemlenemeyen sistem operasyonda kördür.
- [ ] **Güvenlik ele alındı** — secret yönetimi, network policy, least-privilege, image scan; sonradan eklenmez.
- [ ] **Maliyet tartışıldı** — compute/storage/egress kalemleri; mühendis maliyeti de tasarlar.
- [ ] **Operability söylendi** — on-call, runbook, game day; sistemi kim, nasıl işletecek?
- [ ] **Vendor lock-in görüldü** — kritik bağımlılık ve çıkış maliyeti açıkça not edildi.
- [ ] **Evolution çizildi** — bugün 1K RPS, yarın 100K → hangi bileşen önce kırılır, ne değişir?
- [ ] **Gizli değer placeholder** — gerçek IP/domain/credential yok; `<PLACEHOLDER>` kullanıldı.

---

## 📚 Devamı

- [System Design Interview — Alex Xu]
- [Designing Data-Intensive Applications — Martin Kleppmann]
- [The Site Reliability Workbook — Google]
- [`05-Kubernetes/Production-Checklist.md`](../05-Kubernetes/Production-Checklist.md)
- [`11-SRE/SLI-SLO-Error-Budget.md`](../11-SRE/SLI-SLO-Error-Budget.md)
