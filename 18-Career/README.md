# 18 · Career

> *"DevOps mühendisi ne yapar?" sorusu **mülakatçıya** göre değişir;
> ne kadar para istemeli sorusu **size** göre değişir.*

## İçindekiler

| Dosya | Konu |
|---|---|
| [`DevOps-Interview-Questions.md`](DevOps-Interview-Questions.md) | Junior → Staff seviyeye 50+ soru, kategorize, cevap ipuçlu |
| [`SRE-Interview-Prep.md`](SRE-Interview-Prep.md) | SRE'ye özel: SLO design, incident response simulation, capacity |
| [`System-Design-Cheatsheet.md`](System-Design-Cheatsheet.md) | DevOps/SRE'ye özgü system design soruları (cluster tasarla, multi-region, vb) |
| [`CV-Tips.md`](CV-Tips.md) | DevOps CV'si nasıl yazılır; "tool listesi" ile "impact" arasındaki fark |

## Seviye haritası (rough)

| Seviye | Yıl | Ne bekleniyor |
|---|---|---|
| **Junior** | 0-2 | Tek bir tool zinciri akıcı; runbook takip; on-call shadow |
| **Mid** | 2-5 | Stack genişler; bağımsız incident handling; PR review yapar |
| **Senior** | 5-8 | Cross-cutting tasarımlar; cluster/pipeline owner; junior mentor |
| **Staff** | 8-12 | Org-wide standartlar; multi-team etkisi; trade-off arkitektürü |
| **Principal** | 12+ | Şirket stratejisi; tech radar; uzun-vadeli platform vizyonu |

> Seviye yıl değil **etki** ile ölçülür. Ama hiring matrix yıl ile başlıyor —
> deneyiminizi etki ile ifade edin (sadece "5 yıl Kubernetes" değil "5 yıl
> içinde 3 cluster migration yönettim, downtime <1dk").

## Maaş tartışması notları

- Levels.fyi, Glassdoor, Build From Outside (TR) ile pazara bak
- Total comp = base + bonus + equity + benefits — hepsini sor
- "Beklenti aralığı" değil **rakam** ver — sayı söyleyen kazanır
- Counter-offer ekiple konuşmadan kabul etme

## Bilinmesi şart konular (2026 baseline)

```
Linux                 → process, file, network, perm — root level rahatlık
Networking            → TCP/IP, DNS, TLS, HTTP, load balancing
Containers            → Docker, OCI, container runtime
Kubernetes            → en az 6 ay hands-on bir cluster yönetmiş
IaC                   → Terraform OR Pulumi (en az biri prod'a çıkartmış)
CI/CD                 → GitHub Actions / GitLab / Jenkins
Observability         → Prometheus + Grafana, log/trace mantığı
Cloud                 → AWS / GCP / Azure (en az birinde Solutions Architect-Associate eşdeğeri)
Scripting             → Bash + Python (her gün kullanır seviye)
Database basics       → SQL, transactions, basic backup/restore
```

> Bilinmesi gereken ≠ uzman olunması gereken. Mid seviye için bunlardan
> **en az 7'sini** comfortable; senior için **hepsini** + 2-3 derinleşmiş
> uzmanlık.
