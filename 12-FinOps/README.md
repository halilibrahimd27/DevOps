---
description: "FinOps Foundation cercevesi (Inform-Optimize-Operate) rehberleri: cost allocation, right-sizing, spot, reserved plan, storage, egress, Kubecost ve PR cost diff."
tags:
  - FinOps
  - Cost Optimization
  - Roadmap
  - Cost
---
# 12 · FinOps

> *"AWS faturası ay başında geldi: $42,318. Geçen ay $19,200'dü. Kim,
> ne, nerede? Bilen yok."* — Cost ekibi olmayan her startup

FinOps Foundation çerçevesi: **Inform → Optimize → Operate** döngüsü.
Maliyeti finans değil, mühendislik problemi olarak ele alır.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`Cloud-Cost-Allocation.md`](Cloud-Cost-Allocation.md) | Tagging policy, showback/chargeback, OpenCost/Kubecost setup |
| [`Right-Sizing.md`](Right-Sizing.md) | Compute Optimizer, VPA recommendations, "fat pod" tespiti |
| [`Spot-Instance-Strategy.md`](Spot-Instance-Strategy.md) | Spot interruption handling, Karpenter ile mixed pool |
| [`Reserved-and-Savings-Plans.md`](Reserved-and-Savings-Plans.md) | RI vs SP, commit stratejileri, expiration planlama |
| [`Storage-Cost-Optimization.md`](Storage-Cost-Optimization.md) | S3 Intelligent-Tiering, EBS gp2→gp3, snapshot lifecycle |
| [`Egress-Cost-Reduction.md`](Egress-Cost-Reduction.md) | "Hidden killer" — VPC endpoint, Cloudflare R2, region locality |
| [`Kubecost-Setup.md`](Kubecost-Setup.md) | Kubernetes maliyet attribution: namespace/workload/team |
| [`PR-Cost-Diff.md`](PR-Cost-Diff.md) | Infracost ile pre-merge maliyet review |

## FinOps Foundation döngüsü

```
   ┌─── INFORM ───┐         ┌── OPTIMIZE ──┐         ┌── OPERATE ──┐
   │ Tagging      │         │ Right-size   │         │ Anomaly det │
   │ Cost dash    │ ─────▶ │ Spot/RI/SP   │ ─────▶ │ FinOps champ│
   │ Allocation   │         │ Idle cleanup │         │ KPI track   │
   │ Showback     │         │ Lifecycle    │         │ Forecast    │
   └──────────────┘         └──────────────┘         └─────────────┘
           ▲                                                   │
           │                                                   │
           └─────────────────── continuous ────────────────────┘
```

## Tagging policy (zorunlu, enforce edilen)

| Tag | Örnek değer | Niçin zorunlu |
|---|---|---|
| `Environment` | `prod`, `staging`, `dev` | Maliyet ayrımı |
| `Team` | `payments`, `growth`, `platform` | Showback |
| `Service` | `api`, `worker`, `db` | Workload-level breakdown |
| `CostCenter` | `eng-1234` | Finans entegrasyonu |
| `ManagedBy` | `terraform`, `manual` | IaC drift takibi |
| `Owner` | `team-handle` | Sorumluluk |

> Tagging eksikse:
> - ✅ AWS Config / Service Control Policy ile **deploy edilemez** yap
> - ✅ Terraform validation: `required_tags` modülü
> - ✅ Kyverno (K8s) annotation enforcement

## "Quick wins" — bu hafta yapılabilecekler

1. **Idle resource cleanup** — `aws ec2 describe-instances --filters Name=instance-state-name,Values=stopped` (30 günden eski → terminate)
2. **EBS gp2 → gp3** — aynı performans, %20 ucuz, online migration
3. **Old snapshot purge** — 90 günden eski + asla restore edilmemiş
4. **Idle Load Balancer** — `RequestCount=0` 7 gün boyunca → sil
5. **Unattached EIP** — Elastic IP boşta dururken faturalanır
6. **Empty namespace deployments** — replica=0 ama running secret/configmap
7. **Old AMI'ler** — kullanılmayanları dergeregister
8. **Public S3 + Internet egress** — CDN'in arkasına al

> ⏱️ Tipik tasarruf: %15-30 ilk ay, ekstra mühendislik gücü olmadan.

## Anti-pattern'ler

- ❌ "Maliyet finansın işi" — her ekip kendi cost'unu görmeli
- ❌ Aylık fatura geldikten sonra şaşırmak — günlük anomaly alert
- ❌ Tagging'i opsiyonel yapmak — sonradan eklemek imkansız
- ❌ "Reserved alıp unutmak" — expiry planı yok, cliff'e çarpıyor
- ❌ Kubernetes overcommit'i göz ardı etmek — "biraz fazla request olsun" → cluster hep büyür
- ❌ Egress'i göz ardı etmek — gizli en büyük gider kalemi
