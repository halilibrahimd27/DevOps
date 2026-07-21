# GAP-MAP — Müfredat Konusu → Mevcut Dosya Eşlemesi

**Amaç:** Her müfredat konusunun kaynağını netleştir — ya mevcut deep-dive'a
**link**, ya **"EKSİK — yazılacak"**. Çıktı kapısı (§Faz 0): kaynaksız modül yok.

**Kaynak durumu kodları:**
- `🟢 VAR` — repoda güçlü deep-dive(ler) var; modül **saracak** (yeni içerik minimum).
- `🟡 KISMİ` — repoda ilgili ileri materyal var ama **giriş seviyesi köprü** yazılacak (5–15 satır ya da kısa modül gövdesi).
- `🔴 EKSİK` — repoda hiç yok; modül gövdesi **sıfırdan** yazılacak (Blok A/B'nin büyük kısmı).

> ⚠️ **Kritik gözlem (§2 "Temeller repoda yok").** `bash`, `python`, `tcp`,
> `http`, `tls`, `vpc`, `iam`, `systemd` başlığı/dosya adı taşıyan **tek dosya
> yok**. Reponun networking'i tamamen K8s-içi (service mesh, eBPF, Gateway API);
> git'i ileri (trunk-based, stacked diffs); observability'si production-grade.
> Yani **Blok A ve B'nin çekirdeği 🔴 EKSİK** — asıl yazım işi orada.
> Blok C–F ise büyük oranda 🟢 VAR — modüller mevcut deep-dive'ları sıralar.

---

## BLOK A — Sezgi

| Modül | Konu | Durum | Mevcut kaynak / not |
|---|---|---|---|
| A1 | Linux: process, filesystem, permission, user/group | 🔴 EKSİK | Gövde sıfırdan. Referans (ileri, sonraya): [`16-Cheatsheets/linux-troubleshooting.md`](../../16-Cheatsheets/linux-troubleshooting.md) (USE method — B3/ileri), [`16-Cheatsheets/vim-survival.md`](../../16-Cheatsheets/vim-survival.md) (köprü: sunucuda dosya düzenleme) |
| A2 | Ağ I: TCP/IP, port, routing | 🔴 EKSİK | Gövde sıfırdan. Referans: [`16-Cheatsheets/networking-tools.md`](../../16-Cheatsheets/networking-tools.md), [`09-Networking/Network-Troubleshooting.md`](../../09-Networking/Network-Troubleshooting.md) (ikisi de ileri — A2'de değil, ileride) |
| A3 | Ağ II: DNS → HTTP → TLS/sertifika | 🔴 EKSİK | Gövde sıfırdan. Referans: `networking-tools.md` (dig bölümü). TLS/sertifika reposunun hiçbir yerinde giriş seviyesinde yok |
| A4 | Git | 🟡 KISMİ | Giriş (init/add/commit/branch/merge/rebase/conflict) 🔴 yazılacak. Sonra "ileri okuma": [`01-Git-Workflow/Trunk-Based-Development.md`](../../01-Git-Workflow/Trunk-Based-Development.md), [`Conventional-Commits.md`](../../01-Git-Workflow/Conventional-Commits.md), [`16-Cheatsheets/git.md`](../../16-Cheatsheets/git.md) |
| A5 | Bash + ops için Python | 🔴 EKSİK | Gövde sıfırdan. Repoda bash/python öğreten dosya yok |
| A6 | Bir uygulamayı elle ayağa kaldır (VM+nginx+DB+systemd+log, container YOK) | 🔴 EKSİK | Gövde sıfırdan; kasıtlı zahmetli. Kıvam referansı (Proxmox/Ansible install notları): [`21-Field-Notes/system/`](../../21-Field-Notes/system/), [`21-Field-Notes/ansible/system-preparation.md`](../../21-Field-Notes/ansible/system-preparation.md) |

## BLOK B — Görebilmek

| Modül | Konu | Durum | Mevcut kaynak / not |
|---|---|---|---|
| B1 | Log okuma: journalctl, structured logging, ne loglanır | 🔴 EKSİK | journalctl temeli sıfırdan. "İleri okuma" (log stack, container öncesi değil sonrası): [`07-Observability/Logs-Loki-vs-ELK.md`](../../07-Observability/Logs-Loki-vs-ELK.md) |
| B2 | Metrik: Prometheus temeli, "neyi ölçersin", cardinality | 🟡 KISMİ | Giriş (metrik nedir, node_exporter'ı VM'de çalıştır, ilk PromQL) 🔴 yazılacak. Cardinality/naming için güçlü kaynak: [`07-Observability/Prometheus-Best-Practices.md`](../../07-Observability/Prometheus-Best-Practices.md). Not: [`Prometheus-Grafana-K8s-Setup.md`](../../07-Observability/Prometheus-Grafana-K8s-Setup.md) K8s tabanlı → B2'de değil, D bloğunda |
| B3 | İlk kırık lab (kırık, container-öncesi VM sistemi) | 🔴 EKSİK | Kırık lab (K01) sıfırdan. Teşhis metodu referansı: [`16-Cheatsheets/linux-troubleshooting.md`](../../16-Cheatsheets/linux-troubleshooting.md) (USE method burada devreye girer), [`09-Networking/Network-Troubleshooting.md`](../../09-Networking/Network-Troubleshooting.md) |

## BLOK C — Tekrarlanabilirlik

| Modül | Konu | Durum | Mevcut kaynak (Önce oku) |
|---|---|---|---|
| C1 | Container: image, katman, multi-stage, docker compose | 🟢 VAR | [`04-Containers/Dockerfile-Best-Practices.md`](../../04-Containers/Dockerfile-Best-Practices.md), [`Multi-Stage-Builds.md`](../../04-Containers/Multi-Stage-Builds.md), [`Distroless-and-Chainguard.md`](../../04-Containers/Distroless-and-Chainguard.md), [`BuildKit-Tips.md`](../../04-Containers/BuildKit-Tips.md), [`16-Cheatsheets/docker.md`](../../16-Cheatsheets/docker.md), [`17-Templates/dockerfiles/`](../../17-Templates/dockerfiles/README.md). Köprü: "A6'daki VM'i şimdi container'a al" |
| C2 | CI: test → build → artifact → registry | 🟢 VAR | [`02-CI-CD/Pipeline-Patterns.md`](../../02-CI-CD/Pipeline-Patterns.md), [`GitHub-Actions-Recipes.md`](../../02-CI-CD/GitHub-Actions-Recipes.md), [`Caching-Strategies.md`](../../02-CI-CD/Caching-Strategies.md), [`Reusable-Workflows.md`](../../02-CI-CD/Reusable-Workflows.md), [`21-Field-Notes/system/github-actions-pipeline-setup.md`](../../21-Field-Notes/system/github-actions-pipeline-setup.md), [`17-Templates/github-actions/`](../../17-Templates/github-actions/README.md) |
| C3 | Terraform (A6'yı otomatikleştir) | 🟢 VAR | [`03-IaC/Terraform-Best-Practices.md`](../../03-IaC/Terraform-Best-Practices.md), [`Terraform-Module-Layout.md`](../../03-IaC/Terraform-Module-Layout.md), [`16-Cheatsheets/terraform.md`](../../16-Cheatsheets/terraform.md), [`21-Field-Notes/terraform/`](../../21-Field-Notes/terraform/modules-create-vm.md), [`17-Templates/terraform/`](../../17-Templates/terraform/README.md). Köprü: A6'ya geri referans (soyutlanan acı) |
| C4 | Bulut temelleri + **bütçe alarmı** (ilk bulut modülü) | 🟡 KISMİ | Bulut giriş (VPC/IAM/EC2 kavramı) + **bütçe alarmı lab'ı** 🔴 yazılacak. Kaynak: [`16-Cheatsheets/aws-cli.md`](../../16-Cheatsheets/aws-cli.md). FinOps derinliği Blok F (C4'te değil). §3.6: zorunlu bütçe alarmı |

## BLOK D — Orkestrasyon *(güvenlik iplik olarak içinde)*

| Modül | Konu | Durum | Mevcut kaynak (Önce oku) |
|---|---|---|---|
| D1 | K8s temel: Pod/Deployment/Service/Ingress — **RBAC + NetworkPolicy ilk günden** | 🟡 KISMİ | K8s kavram girişi (Pod/Deployment/Service) köprüsü 🔴 (repo K8s bildiğini varsayar). Güvenlik iplik kaynağı 🟢: [`08-Security/Kubernetes-Hardening.md`](../../08-Security/Kubernetes-Hardening.md) (RBAC, NetworkPolicy, PSS), [`Policy-as-Code-OPA-Kyverno.md`](../../08-Security/Policy-as-Code-OPA-Kyverno.md), [`05-Kubernetes/Debugging-Pods.md`](../../05-Kubernetes/Debugging-Pods.md), [`09-Networking/Ingress-NGINX-Patterns.md`](../../09-Networking/Ingress-NGINX-Patterns.md), [`17-Templates/kubernetes/`](../../17-Templates/kubernetes/README.md) (deployment/service/ingress/networkpolicy/serviceaccount-rbac), [`21-Field-Notes/system/kubernetes-cluster-installation.md`](../../21-Field-Notes/system/kubernetes-cluster-installation.md) |
| D2 | K8s production: request/limit, probe, PDB, HPA | 🟢 VAR | [`05-Kubernetes/Production-Checklist.md`](../../05-Kubernetes/Production-Checklist.md), [`Resource-Limits-Guide.md`](../../05-Kubernetes/Resource-Limits-Guide.md), [`HPA-VPA-KEDA.md`](../../05-Kubernetes/HPA-VPA-KEDA.md), [`17-Templates/kubernetes/hpa.yaml`](../../17-Templates/kubernetes/README.md) |
| D3 | Secret yönetimi | 🟢 VAR | [`08-Security/Secrets-Management.md`](../../08-Security/Secrets-Management.md), [`06-GitOps/Secrets-in-GitOps.md`](../../06-GitOps/Secrets-in-GitOps.md) |
| D4 | Supply chain: image tarama + imzalama — **C2 pipeline'ının devamı** | 🟢 VAR | [`08-Security/Container-Image-Scanning.md`](../../08-Security/Container-Image-Scanning.md), [`SLSA-and-SBOM.md`](../../08-Security/SLSA-and-SBOM.md), [`04-Containers/Image-Signing-Cosign.md`](../../04-Containers/Image-Signing-Cosign.md), [`08-Security/DevSecOps-Pipeline.md`](../../08-Security/DevSecOps-Pipeline.md), [`17-Templates/kyverno-policies/require-image-signature.yaml`](../../17-Templates/kyverno-policies/README.md). **Ayrı ders değil, C2'nin devamı** |
| D5 | GitOps (ArgoCD) — tek uygulama, basit kurulum | 🟢 VAR | [`06-GitOps/ArgoCD-Setup.md`](../../06-GitOps/ArgoCD-Setup.md), [`Helm-vs-Kustomize-vs-Raw.md`](../../06-GitOps/Helm-vs-Kustomize-vs-Raw.md), [`Flux-vs-ArgoCD.md`](../../06-GitOps/Flux-vs-ArgoCD.md). App-of-Apps/ApplicationSet → **NOT-YET** |

## BLOK E — Sahiplik *(L1 kapısı)*

| Modül | Konu | Durum | Mevcut kaynak (Önce oku) |
|---|---|---|---|
| E1 | SLI / SLO / error budget | 🟢 VAR | [`11-SRE/SLI-SLO-Error-Budget.md`](../../11-SRE/SLI-SLO-Error-Budget.md), [`07-Observability/SLO-Engineering.md`](../../07-Observability/SLO-Engineering.md), [`17-Templates/prometheus-rules/slo-recording-rules.yaml`](../../17-Templates/prometheus-rules/README.md) |
| E2 | Alerting + on-call disiplini | 🟢 VAR | [`07-Observability/Alerting-Done-Right.md`](../../07-Observability/Alerting-Done-Right.md), [`00-Culture/On-Call-Playbook.md`](../../00-Culture/On-Call-Playbook.md), [`11-SRE/Runbook-Template.md`](../../11-SRE/Runbook-Template.md), [`20-Soft-Skills/Oncall-Sustainability.md`](../../20-Soft-Skills/Oncall-Sustainability.md) |
| E3 | Incident response + blameless postmortem | 🟢 VAR | [`11-SRE/Incident-Response.md`](../../11-SRE/Incident-Response.md), [`Postmortem-Practice.md`](../../11-SRE/Postmortem-Practice.md), [`00-Culture/Blameless-Postmortem-Template.md`](../../00-Culture/Blameless-Postmortem-Template.md), [`20-Soft-Skills/Postmortem-Conversation.md`](../../20-Soft-Skills/Postmortem-Conversation.md), [`17-Templates/runbooks/postmortem-template.md`](../../17-Templates/runbooks/postmortem-template.md) |
| E4 | Veritabanı production — özellikle **restore** | 🟢 VAR | [`10-Databases-Production/Backup-Restore-Patterns.md`](../../10-Databases-Production/Backup-Restore-Patterns.md), [`Postgres-Production-Guide.md`](../../10-Databases-Production/Postgres-Production-Guide.md), [`Zero-Downtime-Migrations.md`](../../10-Databases-Production/Zero-Downtime-Migrations.md), [`Monitoring-Postgres.md`](../../10-Databases-Production/Monitoring-Postgres.md) |
| E5 | İleri kırık lab / chaos | 🟢 VAR | [`11-SRE/Chaos-Engineering.md`](../../11-SRE/Chaos-Engineering.md), [`Capacity-Planning.md`](../../11-SRE/Capacity-Planning.md), [`Toil-Reduction.md`](../../11-SRE/Toil-Reduction.md) |

## BLOK F — Karar *(L1 → L2, üçüncü bakış)*

| Modül | Konu | Durum | Mevcut kaynak (Önce oku) |
|---|---|---|---|
| F1 | Maliyet ve trade-off (FinOps) | 🟢 VAR | [`12-FinOps/`](../../12-FinOps/README.md) tümü: Cost-Allocation, Right-Sizing, Spot, Reserved, Storage, Egress, Kubecost, PR-Cost-Diff |
| F2 | Tehdit modelleme + uyum (KVKK/GDPR/SOC 2) | 🟢 VAR | [`08-Security/Threat-Modeling.md`](../../08-Security/Threat-Modeling.md), [`Zero-Trust-Networking.md`](../../08-Security/Zero-Trust-Networking.md), [`19-Compliance/`](../../19-Compliance/README.md) tümü (KVKK, GDPR, SOC2, ISO27001, PCI-DSS, NIS2, EU-AI-Act, Audit-Evidence) |
| F3 | Platform, IDP, Team Topologies | 🟢 VAR | [`13-Platform-Engineering/`](../../13-Platform-Engineering/README.md) tümü, [`00-Culture/Team-Topologies.md`](../../00-Culture/Team-Topologies.md) |
| F4 | Yazma: ADR, RFC, postmortem | 🟢 VAR | [`20-Soft-Skills/Documentation-as-Communication.md`](../../20-Soft-Skills/Documentation-as-Communication.md), [`00-Culture/Documentation-Culture.md`](../../00-Culture/Documentation-Culture.md), [`11-SRE/Postmortem-Practice.md`](../../11-SRE/Postmortem-Practice.md) |
| F5 | Stakeholder yönetimi, "hayır" demek, vendor | 🟢 VAR | [`20-Soft-Skills/Saying-No.md`](../../20-Soft-Skills/Saying-No.md), [`Stakeholder-Management.md`](../../20-Soft-Skills/Stakeholder-Management.md), [`Vendor-Management.md`](../../20-Soft-Skills/Vendor-Management.md), [`Working-with-Security-Team.md`](../../20-Soft-Skills/Working-with-Security-Team.md) |

---

## Sertifika kapıları (§8)

| Kapı | Konum | Sertifika | Kaynak / not |
|---|---|---|---|
| G1 | Blok C sonu | KCNA **veya** Terraform Associate | Yeni yazılacak (`certifications/G1-*.md`). Domain eşlemesi: C1–C4 |
| G2 | Blok D sonu | CKA | Yeni. Domain eşlemesi: D1–D5 |
| G3 | Blok E sonu | CKS **veya** AWS SAA (dal seçimi) | Yeni. Domain eşlemesi: D4, E4, F2 (CKS) / C4, F1 (SAA) |

**Taşınacak dosya (§8.1):** [`21-Field-Notes/system/devops-certification-roadmap.md`](../../21-Field-Notes/system/devops-certification-roadmap.md)
→ `certifications/` altına. Düzeltilecek: 10 sertifika/48 ay koleksiyon planı, pazarlama tonu,
kaynaksız istatistikler (doğrulanamayan yüzde/pazar-büyüklüğü sayıları), USD ücret bantları,
"Teknical Prerequisites"/"Praktik Deneyim" typo'ları, Docker DCA önerisi (legacy notuyla kenara).
`21-Field-Notes/` altında yönlendirme satırı kalır.

---

## Çözülecek çelişkiler (repo genelinde)

| Çelişki | Konum | Faz |
|---|---|---|
| Sertifika: "10 sertifika/48 ay" ↔ "koleksiyon = anti-pattern" | `21-Field-Notes/system/devops-certification-roadmap.md` ↔ [`RoadMap/README.md:179`](../../RoadMap/README.md) | 6.5 |
| Kırık ön-koşul zinciri: "Hafta 1 Linux" → ileri USE-method cheatsheet | [`RoadMap/README.md:77-79`](../../RoadMap/README.md) | 8 (patikaya yönlendir) |
| Senior müfredatı "Modern Trend" rafında (FinOps/Platform/Compliance) | `RoadMap/README.md` C bölümü | 7 (F bloğu çerçevesi) |

---

## Kaynak yeterlilik özeti

| Blok | 🟢 VAR | 🟡 KISMİ | 🔴 EKSİK | Yorum |
|---|---|---|---|---|
| A | 0 | 1 (A4) | 5 | En büyük yazım işi — temeller repoda yok |
| B | 0 | 1 (B2) | 2 | journalctl + kırık lab sıfırdan |
| C | 3 | 1 (C4) | 0 | Mevcut deep-dive güçlü; bulut girişi + bütçe lab'ı yazılacak |
| D | 3 | 1 (D1) | 0 | Güvenlik ipliği zaten `08-Security/`'de; D1 K8s giriş köprüsü gerek |
| E | 5 | 0 | 0 | Tamamı mevcut deep-dive |
| F | 5 | 0 | 0 | Tamamı mevcut deep-dive (üçüncü bakış çerçevesiyle) |

**Sonuç:** Kaynaksız modül **yok**. Her modülün kaynağı ya mevcut dosya (🟢/🟡)
ya da "Blok A/B'de yazılacak" (🔴). Faz 0 çıktı kapısı **geçildi**.
