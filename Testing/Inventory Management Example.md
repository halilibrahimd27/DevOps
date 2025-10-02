## 📂 DEVOPS ENVANTER ANALİZİ — MASTER TEMPLATE

---

### 🌐 1. **SUNUCU / İNSTANCE ENVANTERİ**

| Hostname       | IP        | Rol            | Lokasyon       | OS           | Açıklama                  |
| -------------- | --------- | -------------- | -------------- | ------------ | ------------------------- |
| jenkins-master | 10.0.1.10 | Jenkins Server | AWS EC2        | Ubuntu 22.04 | CI/CD yönetimi            |
| bastion-host   | 10.0.1.5  | SSH Proxy      | AWS EC2        | Ubuntu 22.04 | Dışa açık tek sunucu      |
| wazuh-server   | 10.0.2.30 | SIEM / Log     | AWS EC2        | Ubuntu 22.04 | Wazuh dashboard çalışıyor |
| eks-node-1     | 10.0.3.11 | K8s Worker     | EKS            | Amazon Linux | Worker node               |
| eks-node-2     | 10.0.3.12 | K8s Worker     | EKS            | Amazon Linux | Worker node               |
| db-backend     | 10.0.4.21 | MongoDB        | Private Subnet | Ubuntu 22.04 | Prod DB sunucusu          |

---

### 🔐 2. **KULLANICI ERİŞİM ENVANTERİ (SUNUCU BAZLI)**

| Kullanıcı           | Erişim Sağladığı Sunucu(lar)              | Erişim Türü          | SSH Key Adı          | Açıklama                |
| ------------------- | ----------------------------------------- | -------------------- | -------------------- | ----------------------- |
| devops\_ahmet       | bastion-host, jenkins-master, eks-node-\* | SSH (Key)            | `id_rsa_ahmet`       | Full erişim             |
| backend\_elif       | eks-node-1, eks-node-2                    | SSH (Key)            | `id_rsa_elif`        | Uygulama güncelleme     |
| sec\_ops\_tuna      | wazuh-server, db-backend                  | SSH (Key)            | `id_rsa_tuna`        | Güvenlik logları izleme |
| automation\_jenkins | eks-node-\*                               | ServiceAccount + SSH | `jenkins_deploy_key` | CI/CD deploy işlemleri  |

> **Not:** Tüm anahtarlar bastion-host üzerinden erişime açık. Direkt prod sunuculara dış erişim yoktur. 🛡️

---

### 📁 3. **SSH KEY / CREDENTIAL ENVANTERİ**

| Key Adı              | Kullanıcı    | Kaynak      | Şifreli Mi?       | Nerede Saklanıyor?          |
| -------------------- | ------------ | ----------- | ----------------- | --------------------------- |
| `id_rsa_ahmet`       | Ahmet        | local       | Evet              | Vault (ya da ansible-vault) |
| `jenkins_deploy_key` | Jenkins CI   | GHCR deploy | Hayır (read-only) | Jenkins credential store    |
| `db_password_prod`   | MongoDB Root | .env.secret | Evet              | Kubernetes SealedSecret     |

---

### 🛡️ 4. **YETKİLENDİRME MATRİSİ**

| Rol              | Jenkins      | Kubernetes         | Vault | AWS                         |
| ---------------- | ------------ | ------------------ | ----- | --------------------------- |
| DevOps (Ahmet)   | Full         | Full               | Admin | Full                        |
| Developer (Elif) | Trigger only | Read/Write (dev)   | ❌     | IAM: limited                |
| SecOps (Tuna)    | Logs view    | Logs view          | Read  | IAM: log-reader             |
| Jenkins SA       | ✖️           | Deploy (dev/stage) | ✖️    | IAM Role: JenkinsDeployRole |

---

### 🌍 5. **ALTYAPI & AĞ ENVANTERİ**

| Ağaç                            | Açıklama                                       |
| ------------------------------- | ---------------------------------------------- |
| VPC                             | `vpc-prod-001` (10.0.0.0/16)                   |
| Subnet-public                   | 10.0.1.0/24 (bastion, jenkins)                 |
| Subnet-private-app              | 10.0.3.0/24 (eks worker)                       |
| Subnet-private-db               | 10.0.4.0/24 (mongodb)                          |
| Security Group: `bastion-sg`    | Sadece port 22 dışa açık                       |
| Security Group: `eks-worker-sg` | NodePort ve kubelet erişimi için açılmış       |
| Route Table                     | Internet Gateway + NAT Gateway yapılandırılmış |

---

### 🧯 6. **YEDEK & RECOVERY ENVANTERİ**

| Bileşen         | Yedekleme Türü        | Frekans          | Nerede Saklanıyor?              |
| --------------- | --------------------- | ---------------- | ------------------------------- |
| MongoDB Prod    | Snapshot (mongodump)  | Günlük           | S3 bucket (`prod-db-backups`)   |
| Terraform State | Versioned S3          | Her değişiklikte | `company-tf-state/prod`         |
| Jenkins Home    | Tar + cron            | Günlük           | `s3://jenkins-backups/`         |
| Logs (Wazuh)    | Arşiv + Elasticsearch | Sürekli          | Wazuh indexer + S3 cold archive |

---

### 📋 7. **YASAL / KRİTİK BİLGİ POLİTİKASI**

| Veri Türü    | Saklama Süresi | Erişim Yetkisi        | Şifreleme |
| ------------ | -------------- | --------------------- | --------- |
| SSH Key      | Süresiz        | Kişisel + Vault admin | ✅         |
| Prod DB Dump | 30 gün         | Sadece DBA/SecOps     | ✅         |
| Jenkins Log  | 90 gün         | DevOps + Security     | ✅         |
| Wazuh Alerts | 6 ay           | SecOps                | ✅         |

---

### 📦 8. **UYGULAMA ENVANTERİ**

| Servis Adı   | Türü           | Teknoloji         | Çalıştığı Ortam          | Durum |
| ------------ | -------------- | ----------------- | ------------------------ | ----- |
| auth-service | Backend API    | Node.js (Express) | `prod`, `staging`        | Aktif |
| frontend     | Web UI         | React.js          | `prod`, `staging`, `dev` | Aktif |
| worker       | Background Job | Python (Celery)   | `prod`, `staging`        | Aktif |
| report-gen   | CLI Tool       | Go                | `manual trigger`         | Beta  |

---

### 🧰 9. **GELİŞTİRME & VERSİYON KONTROL**

| Alan               | Bilgi                            |
| ------------------ | -------------------------------- |
| Git Sistemi        | GitHub (Private)                 |
| Repo Sayısı        | 4 ayrı repo                      |
| Branch Modeli      | `main`, `develop`, `feature/*`   |
| Tagleme Politikası | `vX.Y.Z` (Semantic Versioning)   |
| CI/CD Trigger      | Jenkins Webhook (push, PR merge) |

---

### 🛠️ 10. **CI/CD AKIŞI**

| Aşama    | Araç               | Açıklama                         |
| -------- | ------------------ | -------------------------------- |
| Build    | Jenkins            | Docker build                     |
| Test     | Jenkins            | Unit test + Lint                 |
| Push     | Jenkins            | GHCR (GitHub Container Registry) |
| Deploy   | Jenkins            | Helm via kubectl                 |
| Ortamlar | dev, staging, prod | Namespace bazlı                  |

#### 📄 Örnek Pipeline:

```groovy
pipeline {
  agent any
  stages {
    stage('Build') {
      steps { sh 'docker build -t ghcr.io/myorg/auth-service:latest .' }
    }
    stage('Push') {
      steps { sh 'docker push ghcr.io/myorg/auth-service:latest' }
    }
    stage('Deploy') {
      steps { sh 'helm upgrade --install auth helm/auth --namespace staging' }
    }
  }
}
```

---

### 🐳 11. **CONTAINER VE REGISTRY**

| Servis       | Registry | Image Adı                    | Tagleme Politikası   |
| ------------ | -------- | ---------------------------- | -------------------- |
| auth-service | GHCR     | `ghcr.io/myorg/auth-service` | `:latest`, `:v1.2.3` |
| frontend     | GHCR     | `ghcr.io/myorg/frontend`     | `:vX.Y.Z-dev`        |

---

### ☸️ 12. **KUBERNETES MİMARİSİ**

| Cluster Adı  | Tip | Lokasyon  | Nodes              | Ortamlar           |
| ------------ | --- | --------- | ------------------ | ------------------ |
| main-cluster | EKS | Frankfurt | 1 master, 2 worker | dev, staging, prod |

| Namespace | Açıklama                  |
| --------- | ------------------------- |
| `dev`     | Development               |
| `staging` | QA/Test                   |
| `prod`    | Production (live traffic) |

---

### 🧭 13. **DEPLOYMENT YÖNETİMİ**

| Yönetim Aracı | Kullanımı                                             |
| ------------- | ----------------------------------------------------- |
| Helm          | Kullanılıyor (`helm install`, `helm upgrade`)         |
| Kustomize     | Overlay ortamlar için planlandı                       |
| Ingress       | NGINX + TLS (şirket sertifikası)                      |
| Certifikalar  | Şirketin özel TLS sertifikası, secret olarak yüklendi |

---

### 🔒 14. **SECRETS & CONFIG YÖNETİMİ**

| Araç                       | Tür                      | Açıklama                        |
| -------------------------- | ------------------------ | ------------------------------- |
| Kubernetes Secrets         | config.json, db password | `Opaque` olarak base64 encoded  |
| Sealed Secrets (opsiyonel) | GitOps için              | Git'e commit edilebilir         |
| Vault (opsiyonel)          | Long-term strategy       | HashiCorp Vault değerlendirmede |

---

### 🛡️ 15. **RBAC & ERİŞİM POLİTİKALARI**

| Rol        | Erişim            | Namespace    |
| ---------- | ----------------- | ------------ |
| Jenkins SA | `edit + deploy`   | dev, staging |
| Dev ekibi  | `read-only`       | prod         |
| Prometheus | `metrics` erişimi | tümü         |
| Admin      | `cluster-admin`   | tümü         |

---

### 📈 16. **MONITORING**

| Araç         | Bileşen                           | Açıklama                          |
| ------------ | --------------------------------- | --------------------------------- |
| Prometheus   | node-exporter, kube-state-metrics | Kapsamlı metrik                   |
| Grafana      | Dashboard'lar                     | Hazır JSON ile kuruldu            |
| Alertmanager | Slack                             | CPU, Memory, Pod Crash alert’leri |

---

### 📜 17. **LOGGING VE GÜVENLİK ANALİZİ**

| Araç          | Kurulum                 | Açıklama                    |
| ------------- | ----------------------- | --------------------------- |
| **Wazuh**     | Helm ile kurulu         | Agent’lı SIEM sistemi       |
| Agent Durumu  | Worker node’larda aktif | Docker loglarını toplar     |
| Alert sistemi | Wazuh Dashboard         | CVE, FIM, rootkit uyarıları |

---

### 🧯 18. **BACKUP VE FELAKET YÖNETİMİ**

| Bileşen         | Strateji                               |
| --------------- | -------------------------------------- |
| RDS             | AWS Backup policy: Daily + weekly      |
| Terraform State | S3 bucket + versioning + DynamoDB lock |
| Jenkins         | `/var/jenkins_home` backup (cron + S3) |
| Logs            | Wazuh ile central + archive            |

---

### 📤 19. **İLETİŞİM VE BİLDİRİM KANALLARI**

| Olay               | Bildirim Yolu          |
| ------------------ | ---------------------- |
| CI/CD build sonucu | Slack: #devops         |
| Alertmanager       | Slack: #alerts         |
| Wazuh Alert        | Mail + Dashboard       |
| Uptime monitoring  | StatusCake (opsiyonel) |

---

### 📚 20. **DOKÜMANTASYON & BİLGİ AKIŞI**

| Alan                   | Açıklama                              |
| ---------------------- | ------------------------------------- |
| README.md              | Her microservice için zorunlu         |
| Wiki / Notion          | DevOps süreçleri ve mimari            |
| Dashboard erişimleri   | Grafana, Wazuh linkleri kayıt altında |
| Onboarding dökümanları | Jenkins, kubectl erişim dökümanı      |

