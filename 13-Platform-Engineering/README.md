---
description: "Platform Engineering bölümünün indeksi: Internal Developer Platform, Backstage kurulumu, golden paths, service catalog ve platform-as-product konularına genel bakış ve dosya rehberi."
tags:
  - Platform Engineering
  - Roadmap
  - Culture
---
# 13 · Platform Engineering

> *"DevOps takımı 14 ticket'a cevap veriyor; geliştirici beklerken sigara
> içiyor. Bu sürdürülebilir değil."* — Kurumsal DevOps'un acı gerçeği

Internal Developer Platform (IDP) = developer'ın self-service kullandığı,
opinionated bir "altın yol".

## İçindekiler

| Dosya | Konu |
|---|---|
| [`Internal-Developer-Platform.md`](Internal-Developer-Platform.md) | IDP nedir, niye Backstage'den başlar, build vs buy |
| [`Backstage-Setup.md`](Backstage-Setup.md) | Backstage kurulumu, plugin'ler, scaffolder template |
| [`Golden-Paths.md`](Golden-Paths.md) | "Yeni servis aç → 5 dk'da" şablonları |
| [`Service-Catalog.md`](Service-Catalog.md) | Service ownership, dependency graph, on-call mapping |
| [`Platform-as-Product.md`](Platform-as-Product.md) | Developer'ı müşteri gibi gör; NPS, SLA, roadmap |

## Felsefe

> Platform takımının ürünü **diğer mühendislere** sunulan iç bir
> üründür. Customer = developer. Müşteri memnuniyeti = developer
> productivity.

## Platform vs DevOps takımı

| DevOps takımı (anti-pattern) | Platform takımı (sağlıklı) |
|---|---|
| "Ticket'ı al, çalıştır" | Self-service tools sunar |
| Bilgiyi siler (gatekeeper) | Bilgiyi paylaşır (enabler) |
| Tek-kişi-bağımlı (bus factor 1) | Toollar dokümante, multi-owned |
| "Yangın söndürücü" | Yangın önleyici |
| Geliştirici düşman | Geliştirici müşteri |

## Backstage minimum kurulum

```
Backstage core
├── Catalog            ← service inventory + ownership
├── Scaffolder         ← golden path templates
├── TechDocs           ← markdown-as-docs
├── Search             ← global cross-resource search
├── Kubernetes plugin  ← cluster overview
└── Cost Insights      ← Kubecost/AWS integration
```

## "Golden Path" örneği — yeni microservice

```
$ backstage scaffold create

? Template:           [ Go REST API + Postgres ]
? Service name:       payments
? Owner team:         @payments-team
? Cloud:              AWS
? Region:             eu-west-1

[Backstage çalıştırırken arkada]
├── GitHub repo açılır       (template'den)
├── CODEOWNERS, README, CI   eklenir
├── Terraform PR             (RDS, IAM)
├── ArgoCD Application       k8s-config repo'da
├── Datadog dashboard        oluşturulur
├── PagerDuty rotation       atanır
├── Slack #payments-alerts   açılır
├── Backstage Catalog        kaydı yapılır
└── On-boarding doc          oluşturulur (TechDocs)

⏱️ Toplam süre: ~8 dakika
```

## Build vs buy decision tree

```
Şirket büyüklüğü?
├── < 50 mühendis → Vendor SaaS (Port, Cortex)
├── 50-500       → Backstage self-host + Crossplane
└── 500+         → Custom platform üzerine in-house build
```

## Anti-pattern'ler

- ❌ Platform'u "hizmet" değil "zorunlu" yapmak — herkes vendor lock-in
- ❌ NPS ölçmemek — geliştirici kullanmıyor sebebini bilmiyorsun
- ❌ "Bizden geçmeden production'a çıkamazsın" — bottleneck, demoralize edici
- ❌ Tüm guardrail'ler hard-block — escape hatch yoksa bypass'lar başlar
- ❌ Platform takımının kendi backlog'u yok, sadece ticket cevaplıyor
