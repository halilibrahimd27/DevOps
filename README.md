# DevOps Notebook

> Pratiğe dökülmüş DevOps notları, runbook'ları, IaC örnekleri ve
> production'da öğrenilmiş dersler. Türkçe.

Bu repo, sıfırdan bir DevOps platformu kurarken karşılaşacağınız her katmanın
çalışan örneklerini ve referans materyallerini bir arada tutar: ağ
segmentasyonundan SIEM entegrasyonuna, Terraform IaC'den Kubernetes
upgrade'ine, Ansible playbook'larından PostgreSQL backup stratejisine kadar.

> **Yeni başlıyorsanız:** [`RoadMap/Modern-DevOps-2026.md`](RoadMap/Modern-DevOps-2026.md) — 2026 itibarıyla
> güncel metodolojiler, kültür ve toolchain özeti.
> Sonra [`RoadMap/RoadMap.md`](RoadMap/RoadMap.md) ile uygulama yol haritasını takip edin.

---

## İçerik Haritası

| Klasör | Ne içerir? |
|---|---|
| [`RoadMap/`](RoadMap/) | DevOps yol haritaları + **modern metodoloji & kültür rehberi**. Sıfırdan production'a doğru ilerlerken hangi sırayla ne yapılır. |
| [`System/`](System/) | Sistem-seviyesi rehberler: Kubernetes cluster kurulumu, GitHub Actions pipeline, repo layout, envanter yönetimi, sertifikasyon notları. |
| [`Ansible/`](Ansible/) | Sistem hazırlığı, paket kurulumu, kullanıcı yönetimi, secret yönetimi için Ansible playbook'ları. |
| [`Kubectl/`](Kubectl/) | Kubernetes kullanım notları: Jenkins entegrasyonu, logging stack, secret/credential yönetimi. |
| [`Terrafrom/`](Terrafrom/) | Terraform IaC örnekleri (Proxmox provider, manuel VM kurulumları). |
| [`Network/`](Network/) | Ağ segmentasyonu + Wazuh SIEM entegrasyon rehberi. |
| [`monitoring/`](monitoring/) | Prometheus + Grafana + Uptime Kuma stack'i, alert kuralları, exporter'lar. |
| [`databases/`](databases/) | PostgreSQL · MariaDB · MongoDB · Redis · Cassandra için backup, health check, security setup ve Google Drive'a sync örnekleri. |
| [`nginx/`](nginx/) | Üretim NGINX konfigürasyonları (test-api, test-front örnekleri). |
| [`infra-devops/`](infra-devops/) | Azure üzerinde Kubespray ile multi-master Kubernetes cluster kurulumu (Terraform + Ansible + HAProxy + NFS + Vault + ArgoCD). |
| [`haproxy-openmanager/`](haproxy-openmanager/) | HAProxy konfigürasyon yöneticisi — yapılandırma, test, upgrade ve operasyon rehberleri. |
| [`crypter/`](crypter/) | Configuration & secret şifreleme yardımcıları. |
| [`Testing/`](Testing/) | Aynı materyalin test/draft kopyaları. |

---

## Hızlı Yönlendirme

| Soruya cevap istiyorum | Şuraya bakın |
|---|---|
| "DevOps kültürü ve modern metodolojiler nedir?" | [`RoadMap/Modern-DevOps-2026.md`](RoadMap/Modern-DevOps-2026.md) |
| "Sıfırdan altyapı nasıl kurulur?" | [`RoadMap/Advanced RoadMap.md`](RoadMap/Advanced%20RoadMap.md) |
| "Kapsamlı production yol haritası" | [`RoadMap/Planning.md`](RoadMap/Planning.md) |
| "GitOps adım sırası" | [`RoadMap/RoadMap.md`](RoadMap/RoadMap.md) |
| "Kubernetes cluster nasıl kurulur?" | [`System/Kubernetes Cluster Installation Guide.md`](System/Kubernetes%20Cluster%20Installation%20Guide.md) |
| "GitHub Actions pipeline" | [`System/GitHub Actions Pipeline Setup Guide.md`](System/GitHub%20Actions%20Pipeline%20Setup%20Guide.md) |
| "Wazuh SIEM + ağ segmentasyonu" | [`Network/Network Segmentation and Wazuh SIEM Integration Guide.md`](Network/Network%20Segmentation%20and%20Wazuh%20SIEM%20Integration%20Guide.md) |
| "DB backup & restore" | [`databases/`](databases/) |
| "Azure Kubernetes Kubespray ile" | [`infra-devops/README.md`](infra-devops/README.md) |
| "HAProxy yöneticisi" | [`haproxy-openmanager/README.md`](haproxy-openmanager/README.md) |

---

## Felsefe

> *"Kod yazmak işin %20'si. Kalan %80'i, bir başkasının (yarınki sen
> dahil) o kodu güvenle çalıştırabilmesi için yapılan iştir."*

Bu repo o **%80**'in not defteri.

- ✅ Her örnek **çalışan**, prod'da denenmiş bir şeyin damıtılmış halidir
- ✅ Türkçe yazılır — okuyup anlamak için çeviri zorunluluğu yok
- ✅ Komutlar copy-paste'lenebilir — gerektiğinde yer tutucular `<UPPER_CASE>` ile işaretlenir
- ✅ Hata yapıldığı kısımlar **post-mortem** olarak not edilir
- ❌ Hiçbir secret commit'lenmez — `.gitignore` aktif tutulur

---

## Katkı

İçerik eklemek istiyorsanız:
1. İlgili klasör altında bir markdown dosyası oluşturun
2. Dosyanın başına başlık + bir cümlelik özet yazın
3. Komut bloklarında `<TARGET_IP>`, `<USERNAME>` gibi yer tutucu kullanın
4. Bu README'deki ilgili tabloya satır ekleyin
5. PR açın

---

## Lisans

Aksi belirtilmedikçe MIT.
