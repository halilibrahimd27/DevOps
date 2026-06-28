---
description: "Production kurulumlardan kalan ham DevOps saha notları: Ansible, Terraform, Kubernetes, kubectl ve sistem rehberlerinin olduğu gibi korunmuş komut dökümleri."
tags:
  - Field Notes
  - Kubernetes
  - Terraform
  - IaC
  - Cheatsheet
---
# 21 · Saha Notları — Field Notes

> *"Cilalı deep-dive değil; production'da yaşanıp not düşülmüş ham gerçeklik."*

Bu bölüm, numaralı deep-dive'lardan farklı bir içerik sınıfıdır: gerçek
kurulumlardan kalan **ham komut, konfigürasyon ve kurulum rehberleri**.
Bilinçli olarak deep-dive anatomisine (epigraf → kavram tablosu →
anti-pattern → checklist) zorlanmadılar — değerleri "olduğu gibi
çalışan/çalışmış" olmalarında. Kendi ortamına uyarlayarak kullan.

> ⚠️ Buradaki IP/parola/domain değerleri **örnektir**, placeholder mantığıyla
> okunmalı. Kendi gizli bilgilerini asla doğrudan kopyalama.

---

## 🎯 İçindekiler

### Ansible
| Dosya | Ne anlatır |
|---|---|
| [Sistem Hazırlığı](ansible/system-preparation.md) | k8s öncesi inventory + node hazırlık komutları |
| [SSH Bağlantı Testi](ansible/ssh-connectivity-test.md) | Node'lara toplu SSH erişim doğrulama |

### Terraform
| Dosya | Ne anlatır |
|---|---|
| [Proxmox Tam Konfigürasyon](terraform/proxmox-configuration.md) | Proxmox üzerinde uçtan uca VM provisioning |
| [Modüllerle VM Oluşturma](terraform/modules-create-vm.md) | Elle Terraform modülü + VM oluşturma script'i |

### System Setup
| Dosya | Ne anlatır |
|---|---|
| [Kubernetes Cluster Kurulumu](system/kubernetes-cluster-installation.md) | Proxmox/Ubuntu üzerinde cluster kurulumu |
| [Production-Ready Repo Layout](system/production-ready-repo-layout.md) | Laravel + TS + Flutter + K8s monorepo iskeleti |
| [GitHub Actions Pipeline Kurulumu](system/github-actions-pipeline-setup.md) | CI/CD pipeline adım adım |
| [Envanter Yönetimi Örneği](system/inventory-management-example.md) | DevOps envanter master template |
| [Dış Erişim Çözümleri](system/external-access-solutions.md) | External access / port-forward / ingress çözümleri |
| [DevOps Sertifika Roadmap](system/devops-certification-roadmap.md) | Senior seviye sertifika kariyer rehberi |

### kubectl
| Dosya | Ne anlatır |
|---|---|
| [Logging (ElasticSearch)](kubectl/logging-elasticsearch.md) | Cluster log toplama notları |
| [Cluster Parolaları](kubectl/cluster-passwords.md) | Servis parolalarını toplama script'i |

### Network / SIEM
| Dosya | Ne anlatır |
|---|---|
| [Ağ Segmentasyonu + Wazuh SIEM](network/network-segmentation-wazuh-siem.md) | VLAN segmentasyonu + Wazuh entegrasyonu |

---

> *"Saha notu, steril dokümanın söylemediğini söyler: gerçekte ne kırıldı, ne işe yaradı."*
