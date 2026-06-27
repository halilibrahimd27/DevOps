---
description: "A'dan Z'ye DevOps GitOps yol haritası: her adımda ne yapılacak, hangi araçla ve neden sorularını planlama, IaC ve containerization başlıklarıyla yanıtlar."
---
## 🗺️ **DevOps GitOps Uygulama Yol Haritası** (A'dan Z'ye)

---
Her adım:

* **Ne yapılacak?**
* **Hangi araçla?**
* **Amaç ne?**
* Ve gerekirse: *Bu adım neden önce yapılmalı?*


---
### 🟥 A. PLANLAMA & ENVANTER (Hazırlık)

| Adım | Konu                       | Araç         | Açıklama                                                   |
| ---- | -------------------------- | ------------ | ---------------------------------------------------------- |
| A1   | Envanter çıkar             | —            | Tüm servisler, ortamlar, portlar, bağımlılıklar listelenir |
| A2   | Git stratejisi belirle     | GitHub       | Branch modeli: `main`, `develop`, `feature/*`              |
| A3   | Repo & erişim politikaları | GitHub / IAM | Kim neye erişir? GitHub repo yetkileri ayarlanır           |

---

### 🟧 B. ALTYAPI OTOMASYONU (IaC - Terraform)

| Adım | Konu                     | Araç            | Açıklama                                    |
| ---- | ------------------------ | --------------- | ------------------------------------------- |
| B1   | Terraform yapılandırması | Terraform       | `provider.tf`, `main.tf`, `outputs.tf`      |
| B2   | AWS kaynakları kurulumu  | Terraform       | EC2, EKS, VPC, IAM rolleri                  |
| B3   | Terraform state yönetimi | S3 + DynamoDB   | Remote state + versioning + locking         |
| B4   | SSH erişimi yapılandır   | AWS + Terraform | EC2'lere bastion ya da jump host ile erişim |

---

### 🟨 C. CONTAINERIZATION & REGISTRY

| Adım | Konu                          | Araç    | Açıklama                                     |
| ---- | ----------------------------- | ------- | -------------------------------------------- |
| C1   | Dockerfile’ları yaz           | Docker  | Multistage build, `.dockerignore`            |
| C2   | Image versiyonlama stratejisi | GHCR    | `ghcr.io/org/service:tag`                    |
| C3   | Jenkins’in GHCR erişimi       | Jenkins | Personal Access Token ile push hakkı tanımla |

---

### 🟦 D. CI/CD PIPELINE KURULUMU

| Adım | Konu                             | Araç        | Açıklama                            |
| ---- | -------------------------------- | ----------- | ----------------------------------- |
| D1   | Jenkins kurulumu                 | Jenkins     | Docker ya da EC2 üstünde            |
| D2   | Plugin'leri yükle                | Jenkins UI  | Git, Docker, Prometheus plugin'leri |
| D3   | İlk pipeline (build-push-deploy) | Jenkinsfile | GHCR’ye image push → k8s deploy     |

---

### 🟪 E. KUBERNETES YAPILANDIRMASI

| Adım | Konu                        | Araç            | Açıklama                                   |
| ---- | --------------------------- | --------------- | ------------------------------------------ |
| E1   | Kubernetes cluster kurulumu | EKS / kubeadm   | Master + Worker node'lar                   |
| E2   | Namespace organizasyonu     | Kubernetes      | `dev`, `staging`, `prod` namespace oluştur |
| E3   | Helm & Kustomize altyapısı  | Helm, Kustomize | Ortam bazlı deploy yönetimi                |
| E4   | Ingress controller kurulumu | NGINX Ingress   | TLS destekli, multi-host                   |
| E5   | Şirket SSL’inin yüklenmesi  | TLS Secret      | Cert/key dosyaları ile secret oluştur      |

---

### 🟫 F. OBSERVABILITY (MONITORING + LOGGING)

| Adım | Konu                                     | Araç                              | Açıklama                    |
| ---- | ---------------------------------------- | --------------------------------- | --------------------------- |
| F1   | Prometheus + Grafana kurulumu            | Helm                              | `kube-prometheus-stack`     |
| F2   | Exporter’lar                             | node-exporter, kube-state-metrics | Kaynak & pod gözlemi        |
| F3   | Alertmanager konfigürasyonu              | Alertmanager                      | Slack/Mail entegrasyonu     |
| F4   | Fluent Bit kurulumu                      | Fluent Bit                        | Tüm pod logları toplanır    |
| F5   | Elasticsearch + Logstash + Kibana        | Wazuh                             | Log arama ve görselleştirme |

---

### 🟨 G. GÜVENLİK & YÖNETİM

| Adım | Konu                 | Araç                         | Açıklama                                         |
| ---- | -------------------- | ---------------------------- | ------------------------------------------------ |
| G1   | RBAC rolleri         | Kubernetes                   | Jenkins, dev, prod erişim rolleri                |
| G2   | Secrets yönetimi     | Vault / Sealed Secrets       | Vault önerildi; kube-secrets destekli alternatif |
| G3   | Audit policy oluştur | Kubernetes / Jenkins / Vault | API, login, deploy gibi hareketler loglanır      |

---

### 🟩 H. YEDEKLEME & FELAKET KURTARMA

| Adım | Konu                   | Araç            | Açıklama                             |
| ---- | ---------------------- | --------------- | ------------------------------------ |
| H1   | RDS snapshot planı     | AWS Backup      | Günlük/haftalık snapshot             |
| H2   | Jenkins config backup  | Cronjob + S3    | `jenkins_home` klasörü arşivlenir    |
| H3   | Terraform state backup | S3 + versioning | Otomatik olarak zaten koruma altında |

---

### 🟦 I. GİTOPS ENTEGRASYONU

| Adım | Konu                                | Araç              | Açıklama                                   |
| ---- | ----------------------------------- | ----------------- | ------------------------------------------ |
| I1   | Deployment manifest'lerini Git'e al | GitHub            | `k8s/base`, `k8s/staging` gibi klasörler   |
| I2   | Jenkins pull & deploy               | Jenkins + kubectl | Koddan çıkan yapı doğrudan uygulanır       |
| I3   | Git üzerinden rollback              | Git revert + push | Versiyon kontrol ile geri dönüş kolaylaşır |

---

### 🟪 J. DOKÜMANTASYON & OTOMATİK BİLDİRİM

| Adım | Konu                           | Araç                   | Açıklama                                |
| ---- | ------------------------------ | ---------------------- | --------------------------------------- |
| J1   | Proje wiki veya Notion sayfası | Notion / Markdown      | Sistem diyagramı, kullanılan araçlar    |
| J2   | Slack entegrasyonu             | Alertmanager + Jenkins | Pipeline bildirimleri + uyarı mesajları |
| J3   | Dashboard linkleri paylaşımı   | Grafana / Kibana       | Takım içinde görünürlük sağlar          |

---

## ✅ **Yol Haritası Özet Akışı (Kronolojik)**

```
Planlama → Terraform ile altyapı → Jenkins + GHCR → Docker + CI/CD → Kubernetes kurulumu → Helm deploy → Monitoring → Logging → Alerting → Secrets + RBAC → Backup → GitOps yönetimi → Otomasyon + Bildirim
```


