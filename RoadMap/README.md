---
description: "DevOps öğrenme yol haritası index'i: yeni başlayan, junior/mid ve senior/staff için dört ayrı patika önerir; seviyene göre nereden başlayacağını gösterir."
tags:
  - Roadmap
  - Career
  - Culture
  - Soft Skills
---
# 🗺️ Yol Haritası — Hangi Seviyedeysen Oradan Başla

> *"Yol haritası, herkese aynı yolu önermek değil — sana göre hangi yola
> sapacağını söylemektir."*

DevOps öğrenmek **lineer değildir**. Junior'sın diye 90 günde her şeyi
öğrenmen gerekmiyor; staff'sın diye platform engineering'in tüm
detaylarını bilmen şart değil. Bu klasör **dört ayrı patika** önerir:
seçtiğin seviyeden başla.

---

## 🚦 Sen Kim Hissediyorsun?

<div class="grid cards" markdown>

-   :material-account-school:{ .lg .middle } __🆕 0'dan başlıyorum__

    ---

    Linux, Git, Docker yeni kavramlar. Bilgisayar mühendisliği veya bootcamp'ten geliyorum. "DevOps nedir, nereden başlayayım?"

    [:octicons-arrow-right-24: 90 günlük temel patika](#a-yeni-baslayan)

-   :material-account-tie:{ .lg .middle } __⚙️ Junior/Mid mühendisim__

    ---

    Bir sene CI/CD ve container yazmışım. K8s, Terraform, monitoring derinleşmek istiyorum. "Production'a nasıl çıkarım?"

    [:octicons-arrow-right-24: Mid-level derinleşme](#b-junior-mid)

-   :material-account-cog:{ .lg .middle } __🏗️ Senior+ / Tech Lead__

    ---

    Birden fazla servis production'da. Platform engineering, multi-cluster, FinOps, compliance gündemde.

    [:octicons-arrow-right-24: Senior/Staff yolu](#c-senior-staff)

-   :material-domain:{ .lg .middle } __🏢 Şirket sıfırdan altyapı kuruyor__

    ---

    Greenfield bir AWS hesabında EKS + GitOps + observability stack kuracağım. "End-to-end implementation"

    [:octicons-arrow-right-24: Implementation guide](advanced-roadmap.md)

</div>

---

## 📂 Bu Klasördeki Dosyalar

| Dosya | Kim için? | İçerik |
|---|---|---|
| **[Modern-DevOps-2026.md](Modern-DevOps-2026.md)** | **Herkes** — felsefe + 2026 stack | CALMS, DORA, modern tool haritası, 60-90 günlük adoption planı. **Buradan başla.** |
| **[RoadMap.md](RoadMap.md)** | Mid+ — GitOps yapanlar | A→Z GitOps uygulama haritası: planlama, IaC, K8s, CI/CD, observability sırası |
| **[advanced-roadmap.md](advanced-roadmap.md)** | Senior — sıfırdan AWS implementation | Geliştirici makinesi → AWS → Terraform → EKS → ArgoCD → monitoring uçtan uca |
| **[Planning.md](Planning.md)** | Tech Lead'ler | Proje planlama şablonu — yeni bir altyapı projesi için checklist |

---

## A — Yeni Başlayan { #a-yeni-baslayan }

> 🎯 **Hedef**: 90 günde "production'a çıkmaya hazır junior DevOps".

### Hafta 1-2 — Temel Bilgisayar Bilgisi
- **Linux komut satırı**: file, process, permission, systemd → [16 · Cheatsheets / linux-troubleshooting.md](../16-Cheatsheets/linux-troubleshooting.md)
- **Network temelleri**: TCP/IP, DNS, HTTP, TLS → [09 · Networking](../09-Networking/)
- **Git**: branch, merge, rebase, conflict → [01 · Git Workflow](../01-Git-Workflow/)

### Hafta 3-4 — Container ve Image
- Docker'ın ne olduğu, niye var → [04 · Containers / Dockerfile-Best-Practices.md](../04-Containers/Dockerfile-Best-Practices.md)
- Multi-stage build, image boyutu, distroless
- `docker compose` ile lokal stack
- **Hedef**: Bir Python/Node uygulamasını Docker'a alıp `docker compose up` yapmak

### Hafta 5-6 — CI/CD ile Tanış
- GitHub Actions ile ilk pipeline → [02 · CI/CD / Pipeline-Patterns.md](../02-CI-CD/Pipeline-Patterns.md)
- Test → build → push (image registry) akışı
- **Hedef**: Her commit'te image build edip GitHub Container Registry'ye push

### Hafta 7-9 — Kubernetes Temelleri
- Pod, Deployment, Service, Ingress kavramları → [05 · Kubernetes](../05-Kubernetes/)
- `kubectl` cheatsheet → [16 · Cheatsheets / kubectl.md](../16-Cheatsheets/kubectl.md)
- Lokal: minikube veya kind ile bir cluster
- **Hedef**: Docker'a aldığın uygulamayı K8s'e deploy et

### Hafta 10-12 — IaC ve Cloud
- Terraform temelleri → [03 · IaC / Terraform-Best-Practices.md](../03-IaC/Terraform-Best-Practices.md)
- AWS/GCP/Azure free-tier ile bir VPC + EC2 oluştur
- Remote state (S3 + DynamoDB)
- **Hedef**: Terraform ile cloud'da küçük bir lab kurmak

### 90. Gün Checklist
- [ ] Bir uygulamayı Docker'a alıp K8s'e deploy edebilirim
- [ ] GitHub Actions pipeline'ı yazabilirim
- [ ] Terraform ile basit altyapı kurabilirim
- [ ] `kubectl` komutlarını rahat kullanırım
- [ ] Linux'ta troubleshooting yapabilirim (top, journalctl, netstat)

> ⏭️ **Sırada**: B patikasına geç (mid-level).

---

## B — Junior/Mid { #b-junior-mid }

> 🎯 **Hedef**: Production'a güvenle gönderebilecek seviye.

### Derinleşme alanları (paralel öğren, 3-6 ay):

| Alan | Öncelik | Ana okuma |
|---|---|---|
| **Kubernetes Production** | ⭐⭐⭐ | [05 · Kubernetes / Production-Checklist.md](../05-Kubernetes/Production-Checklist.md) |
| **GitOps** | ⭐⭐⭐ | [06 · GitOps / ArgoCD-Setup.md](../06-GitOps/ArgoCD-Setup.md) |
| **Observability** | ⭐⭐⭐ | [07 · Observability / OpenTelemetry-Adoption.md](../07-Observability/OpenTelemetry-Adoption.md) |
| **Security (DevSecOps)** | ⭐⭐ | [08 · Security / DevSecOps-Pipeline.md](../08-Security/DevSecOps-Pipeline.md) |
| **Database Production** | ⭐⭐ | [10 · Databases / Postgres-Production-Guide.md](../10-Databases-Production/Postgres-Production-Guide.md) |
| **SRE Pratikleri** | ⭐⭐ | [11 · SRE / SLI-SLO-Error-Budget.md](../11-SRE/SLI-SLO-Error-Budget.md) |
| **Networking ileri** | ⭐ | [09 · Networking / Service-Mesh-Comparison.md](../09-Networking/Service-Mesh-Comparison.md) |
| **FinOps temelleri** | ⭐ | [12 · FinOps / Cloud-Cost-Allocation.md](../12-FinOps/Cloud-Cost-Allocation.md) |

### 6 Ay Checklist
- [ ] HPA/VPA/PDB kullanarak resilient deployment yazabilirim
- [ ] ArgoCD ile GitOps akışı kurabilirim
- [ ] Prometheus + alert + Grafana dashboard kurarım
- [ ] Bir incident'te log/metric/trace ile root cause bulurum
- [ ] Image scanning (Trivy) + cosign image signing yapabilirim
- [ ] Postgres backup/restore + zero-downtime migration yapabilirim
- [ ] SLO/SLI tanımlayıp error budget hesaplayabilirim

> ⏭️ **Sırada**: C patikasına geç (senior/staff).

---

## C — Senior / Staff { #c-senior-staff }

> 🎯 **Hedef**: Ekip kuruyor, platform sahipliği taşıyor, organizasyon-wide karar veriyor.

### Stratejik konular

| Alan | Niye senior'a? | Ana okuma |
|---|---|---|
| **Platform Engineering** | Developer experience'ı sahiplenmek | [13 · Platform / Internal-Developer-Platform.md](../13-Platform-Engineering/Internal-Developer-Platform.md) |
| **Multi-tenancy** | Birden fazla ekip aynı cluster | [05 · K8s / Multi-Tenancy-Patterns.md](../05-Kubernetes/Multi-Tenancy-Patterns.md) |
| **Compliance** | KVKK, GDPR, SOC 2 audit | [19 · Compliance](../19-Compliance/) |
| **FinOps** | Bütçe sahipliği, savings plan kararları | [12 · FinOps](../12-FinOps/) |
| **Sustainability** | Karbon farkındalığı, region seçimi | [14 · Sustainability](../14-Sustainability/) |
| **LLMOps** | AI feature'larını production'a almak | [15 · AI-LLMOps](../15-AI-LLMOps/) |
| **Threat Modeling** | Mimari güvenliği | [08 · Security / Threat-Modeling.md](../08-Security/Threat-Modeling.md) |
| **Soft skills** | Stakeholder, mentor, "hayır" demek | [20 · Soft-Skills](../20-Soft-Skills/) |

### Staff seviyesi sorular (kendine sor)
- [ ] Ekibimin DORA metriklerini ay ay görebiliyor muyum?
- [ ] Yeni katılan junior 1 haftada ilk PR'ı atabiliyor mu?
- [ ] Maliyetimizin %X'i hangi servisten geliyor, biliyor muyum?
- [ ] Bir compliance audit'i 2 haftada hazırlayabilir miyim?
- [ ] Ekibimin oncall yükü kişi başına haftada kaç saat?
- [ ] "Bu projeyi yapmıyoruz" dediğim son ne zamandı?

---

## 🚫 Anti-Pattern: "Hepsini Bir Kerede Öğreneceğim"

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| 90 günde 21 bölümü bitirmeye çalışmak | Yüzeysel kalır, 6 ayda unutulur | Patikana sadık kal, derinleş |
| Sadece tool öğrenmek (Terraform/K8s) | "Niye" eksik, kararları yapamazsın | Kavram + tool beraber |
| Junior'ken Platform Engineering | Developer pain'i bilmeden çözüm tasarlanmaz | Önce uygulama yaz, sonra platform |
| Sertifika koleksiyonu | CKA + CKAD + CKS + AWS SAA peş peşe → CV süsü | Blok başına 1 kapı — 3 kapı, 10 değil: [`certifications/`](../22-Learning-Path/certifications/README.md) |
| Production deneyimi olmadan FinOps | Maliyet senaryolarını yaşamamışsın | Önce bütçe sahipliği al |

---

## 📋 Bütünsel Checklist

Bu repo'da hangi noktada olduğunu görmek için:

```
[A] Junior temel
[ ] 16-Cheatsheets/linux-troubleshooting.md
[ ] 01-Git-Workflow/
[ ] 04-Containers/Dockerfile-Best-Practices.md
[ ] 02-CI-CD/Pipeline-Patterns.md
[ ] 05-Kubernetes/ (en az 3 doküman)
[ ] 03-IaC/Terraform-Best-Practices.md

[B] Mid derinleşme
[ ] 05-Kubernetes/Production-Checklist.md
[ ] 06-GitOps/ArgoCD-Setup.md
[ ] 07-Observability/OpenTelemetry-Adoption.md
[ ] 08-Security/DevSecOps-Pipeline.md
[ ] 10-Databases-Production/Postgres-Production-Guide.md
[ ] 11-SRE/SLI-SLO-Error-Budget.md

[C] Senior stratejik
[ ] 13-Platform-Engineering/Internal-Developer-Platform.md
[ ] 19-Compliance/ (en az 2 doküman)
[ ] 12-FinOps/Cloud-Cost-Allocation.md
[ ] 20-Soft-Skills/Oncall-Sustainability.md
[ ] 08-Security/Threat-Modeling.md
[ ] 15-AI-LLMOps/LLM-in-Production.md
```

---

## 📚 Detaylı Okumalar

- **[Modern-DevOps-2026.md](Modern-DevOps-2026.md)** — DevOps felsefesi, CALMS, DORA, 2026 modern stack haritası, 60-90 günlük adoption planı
- **[RoadMap.md](RoadMap.md)** — A'dan Z'ye GitOps uygulama yol haritası (mid+ için)
- **[advanced-roadmap.md](advanced-roadmap.md)** — Sıfırdan AWS + EKS + Terraform implementation (senior için)
- **[Planning.md](Planning.md)** — Yeni proje planlama şablonu (tech lead için)

---

> *"Yol haritası eline aldığında ilk yapacağın şey, bulunduğun yeri
> işaretlemek. Sonra istediğin yere bakmak. Aradaki en kısa yol nadir
> doğru yoldur — ama hangi yolda olduğunu bilmek **her zaman** doğrudur."*
