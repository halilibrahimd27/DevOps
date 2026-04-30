# 11 · Site Reliability Engineering

> *"Hesabımıza güvenilirliği bir feature gibi mühendislik yapmazsak,
> guarantee veremez sadece umarız."* — Google SRE Book

SLI / SLO / Error Budget üzerine kurulu, *toil minimization* yaklaşımı.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`SLI-SLO-Error-Budget.md`](SLI-SLO-Error-Budget.md) | SLI seçimi, SLO matematiği, error budget policy |
| [`Incident-Response.md`](Incident-Response.md) | IC role, severity matrix, communication tree, comms runbook |
| [`Runbook-Template.md`](Runbook-Template.md) | "Bu alert düştüğünde ne yap" şablonu |
| [`Chaos-Engineering.md`](Chaos-Engineering.md) | GameDay → continuous chaos, Litmus/Chaos Mesh kullanımı |
| [`Capacity-Planning.md`](Capacity-Planning.md) | Demand forecasting, headroom, load test framework |
| [`Toil-Reduction.md`](Toil-Reduction.md) | Toil tanımı, ölçümü, %50 kuralı |
| [`Postmortem-Practice.md`](Postmortem-Practice.md) | Blameless postmortem'i nasıl rutine dönüştürürüz |

## SRE'nin "kutsal kitabı"

```
SLI:   Service Level Indicator      → ne ölçeriz
SLO:   Service Level Objective      → hangi hedef
SLA:   Service Level Agreement      → müşteriye söz
EB:    Error Budget = 1 - SLO       → ne kadar arıza kabul ederiz
Toil:  manuel + tekrarlayan + value yaratmayan iş, < %50 hedefli
```

## Error Budget Policy (örnek)

| Bütçe durumu | Politika |
|---|---|
| Bütçe > %50 | Risk al, agresif deploy, yeni feature push |
| Bütçe %20-%50 | Normal hız, standard guardrail'ler |
| Bütçe %0-%20 | Feature freeze; sadece reliability iyileştirmeleri |
| Bütçe < 0 (overspent) | Tüm prod deploy durur; arızanın root cause'una odaklan |

> Bu politika **otomatik enforce edilmeli** — manuel "biz tutarız" yok. Argo
> Rollouts + alertmanager + GitOps gating ile kodla zorlanır.

## Incident severity matrix (örnek)

| Sev | Tanım | Hedef MTTR | Page kim? |
|---|---|---|---|
| **SEV-1** | Customer-impacting outage, revenue down | < 1 saat | On-call IC + manager + leadership |
| **SEV-2** | Major feature broken, kullanıcı subset etkilenir | < 4 saat | On-call IC |
| **SEV-3** | Minor feature broken, workaround var | Sonraki business day | Ticket, on-call değil |
| **SEV-4** | Cosmetic, internal tool | Backlog | Yok |

## Anti-pattern'ler

- ❌ "100% uptime" SLO (matematiksel imkansız, %99.99 yeterli)
- ❌ Avg latency SLI (medyan/p99 kullan)
- ❌ Postmortem yapılmaz — aynı incident 3 ay sonra tekrar
- ❌ "Hero" mühendis incidentlerde her zaman aynı kişi (bus factor 1)
- ❌ Runbook'lar wiki'de kalmış, alert'te link yok
- ❌ Chaos engineering "ilerde yaparız" — production'a güven inşa etmenin tek yolu
