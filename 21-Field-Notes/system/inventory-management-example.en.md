---
description: "DevOps inventory management master template: server/instance inventory and user access inventory tables; hostname, IP, role, OS, and SSH key records."
tags:
  - Field Notes
  - Template
  - Security
  - AWS
  - Compliance
---
# Inventory Management — Example (Master Template)

## 📂 DEVOPS INVENTORY ANALYSIS — MASTER TEMPLATE

---

### 🌐 1. **SERVER / INSTANCE INVENTORY**

| Hostname       | IP        | Role           | Location       | OS           | Description                |
| -------------- | --------- | -------------- | -------------- | ------------ | ------------------------- |
| jenkins-master | 10.0.1.10 | Jenkins Server | AWS EC2        | Ubuntu 22.04 | CI/CD management          |
| bastion-host   | 10.0.1.5  | SSH Proxy      | AWS EC2        | Ubuntu 22.04 | Single externally-facing server |
| wazuh-server   | 10.0.2.30 | SIEM / Log     | AWS EC2        | Ubuntu 22.04 | Wazuh dashboard running   |
| eks-node-1     | 10.0.3.11 | K8s Worker     | EKS            | Amazon Linux | Worker node               |
| eks-node-2     | 10.0.3.12 | K8s Worker     | EKS            | Amazon Linux | Worker node               |
| db-backend     | 10.0.4.21 | MongoDB        | Private Subnet | Ubuntu 22.04 | Prod DB server            |

---

### 🔐 2. **USER ACCESS INVENTORY (PER SERVER)**

| User                | Server(s) Accessed                        | Access Type          | SSH Key Name         | Description              |
| ------------------- | ----------------------------------------- | -------------------- | -------------------- | ----------------------- |
| devops\_ahmet       | bastion-host, jenkins-master, eks-node-\* | SSH (Key)            | `id_rsa_ahmet`       | Full access             |
| backend\_elif       | eks-node-1, eks-node-2                    | SSH (Key)            | `id_rsa_elif`        | Application updates     |
| sec\_ops\_tuna      | wazuh-server, db-backend                  | SSH (Key)            | `id_rsa_tuna`        | Security log monitoring |
| automation\_jenkins | eks-node-\*                               | ServiceAccount + SSH | `jenkins_deploy_key` | CI/CD deploy operations |

> **Note:** All keys are accessible via bastion-host. There is no direct external access to prod servers. 🛡️

---

### 📁 3. **SSH KEY / CREDENTIAL INVENTORY**

| Key Name              | User         | Source      | Encrypted?         | Where Stored?               |
| -------------------- | ------------ | ----------- | ----------------- | --------------------------- |
| `id_rsa_ahmet`       | Ahmet        | local       | Yes                | Vault (or ansible-vault)    |
| `jenkins_deploy_key` | Jenkins CI   | GHCR deploy | No (read-only)     | Jenkins credential store    |
| `db_password_prod`   | MongoDB Root | .env.secret | Yes                | Kubernetes SealedSecret     |

---

### 🛡️ 4. **AUTHORIZATION MATRIX**

| Role              | Jenkins      | Kubernetes         | Vault | AWS                         |
| ---------------- | ------------ | ------------------ | ----- | --------------------------- |
| DevOps (Ahmet)   | Full         | Full               | Admin | Full                        |
| Developer (Elif) | Trigger only | Read/Write (dev)   | ❌     | IAM: limited                |
| SecOps (Tuna)    | Logs view    | Logs view          | Read  | IAM: log-reader             |
| Jenkins SA       | ✖️           | Deploy (dev/stage) | ✖️    | IAM Role: JenkinsDeployRole |

---

### 🌍 5. **INFRASTRUCTURE & NETWORK INVENTORY**

| Component                       | Description                                    |
| ------------------------------- | ---------------------------------------------- |
| VPC                             | `vpc-prod-001` (10.0.0.0/16)                   |
| Subnet-public                   | 10.0.1.0/24 (bastion, jenkins)                 |
| Subnet-private-app              | 10.0.3.0/24 (eks worker)                       |
| Subnet-private-db               | 10.0.4.0/24 (mongodb)                          |
| Security Group: `bastion-sg`    | Only port 22 exposed externally                |
| Security Group: `eks-worker-sg` | Opened for NodePort and kubelet access         |
| Route Table                     | Internet Gateway + NAT Gateway configured      |

---

### 🧯 6. **BACKUP & RECOVERY INVENTORY**

| Component       | Backup Type            | Frequency        | Where Stored?                    |
| --------------- | --------------------- | ---------------- | -------------------------------- |
| MongoDB Prod    | Snapshot (mongodump)  | Daily             | S3 bucket (`prod-db-backups`)    |
| Terraform State | Versioned S3          | On every change   | `company-tf-state/prod`          |
| Jenkins Home    | Tar + cron            | Daily             | `s3://jenkins-backups/`          |
| Logs (Wazuh)    | Archive + Elasticsearch | Continuous      | Wazuh indexer + S3 cold archive  |

---

### 📋 7. **LEGAL / CRITICAL DATA POLICY**

| Data Type    | Retention Period | Access Authorization   | Encryption |
| ------------ | -------------- | --------------------- | --------- |
| SSH Key      | Indefinite      | Personal + Vault admin | ✅         |
| Prod DB Dump | 30 days         | DBA/SecOps only        | ✅         |
| Jenkins Log  | 90 days         | DevOps + Security      | ✅         |
| Wazuh Alerts | 6 months        | SecOps                 | ✅         |

---

### 📦 8. **APPLICATION INVENTORY**

| Service Name | Type           | Technology         | Environment              | Status |
| ------------ | -------------- | ----------------- | ------------------------ | ----- |
| auth-service | Backend API    | Node.js (Express) | `prod`, `staging`        | Active |
| frontend     | Web UI         | React.js          | `prod`, `staging`, `dev` | Active |
| worker       | Background Job | Python (Celery)   | `prod`, `staging`        | Active |
| report-gen   | CLI Tool       | Go                | `manual trigger`         | Beta  |

---

### 🧰 9. **DEVELOPMENT & VERSION CONTROL**

| Field              | Info                              |
| ------------------ | -------------------------------- |
| Git System          | GitHub (Private)                 |
| Number of Repos     | 4 separate repos                 |
| Branch Model        | `main`, `develop`, `feature/*`   |
| Tagging Policy      | `vX.Y.Z` (Semantic Versioning)   |
| CI/CD Trigger       | Jenkins Webhook (push, PR merge) |

---

### 🛠️ 10. **CI/CD FLOW**

| Stage    | Tool               | Description                       |
| -------- | ------------------ | -------------------------------- |
| Build    | Jenkins            | Docker build                     |
| Test     | Jenkins            | Unit test + Lint                 |
| Push     | Jenkins            | GHCR (GitHub Container Registry) |
| Deploy   | Jenkins            | Helm via kubectl                 |
| Environments | dev, staging, prod | Namespace-based               |

#### 📄 Example Pipeline:

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

### 🐳 11. **CONTAINER AND REGISTRY**

| Service      | Registry | Image Name                    | Tagging Policy        |
| ------------ | -------- | ---------------------------- | -------------------- |
| auth-service | GHCR     | `ghcr.io/myorg/auth-service` | `:latest`, `:v1.2.3` |
| frontend     | GHCR     | `ghcr.io/myorg/frontend`     | `:vX.Y.Z-dev`        |

---

### ☸️ 12. **KUBERNETES ARCHITECTURE**

| Cluster Name | Type | Location  | Nodes              | Environments        |
| ------------ | --- | --------- | ------------------ | ------------------ |
| main-cluster | EKS | Frankfurt | 1 master, 2 worker | dev, staging, prod |

| Namespace | Description                |
| --------- | ------------------------- |
| `dev`     | Development               |
| `staging` | QA/Test                   |
| `prod`    | Production (live traffic) |

---

### 🧭 13. **DEPLOYMENT MANAGEMENT**

| Management Tool | Usage                                                  |
| ------------- | ----------------------------------------------------- |
| Helm          | In use (`helm install`, `helm upgrade`)                |
| Kustomize     | Planned for overlay environments                       |
| Ingress       | NGINX + TLS (company certificate)                      |
| Certificates  | Company's private TLS certificate, loaded as a secret  |

---

### 🔒 14. **SECRETS & CONFIG MANAGEMENT**

| Tool                       | Type                      | Description                      |
| -------------------------- | ------------------------ | -------------------------------- |
| Kubernetes Secrets         | config.json, db password | base64 encoded as `Opaque`       |
| Sealed Secrets (optional)  | For GitOps                | Can be committed to Git          |
| Vault (optional)           | Long-term strategy       | HashiCorp Vault under evaluation |

---

### 🛡️ 15. **RBAC & ACCESS POLICIES**

| Role       | Access             | Namespace    |
| ---------- | ----------------- | ------------ |
| Jenkins SA | `edit + deploy`   | dev, staging |
| Dev team   | `read-only`       | prod         |
| Prometheus | `metrics` access  | all          |
| Admin      | `cluster-admin`   | all          |

---

### 📈 16. **MONITORING**

| Tool         | Component                          | Description                        |
| ------------ | --------------------------------- | ---------------------------------- |
| Prometheus   | node-exporter, kube-state-metrics | Comprehensive metrics              |
| Grafana      | Dashboards                        | Set up with ready-made JSON        |
| Alertmanager | Slack                             | CPU, Memory, Pod Crash alerts      |

---

### 📜 17. **LOGGING AND SECURITY ANALYSIS**

| Tool          | Installation             | Description                  |
| ------------- | ----------------------- | --------------------------- |
| **Wazuh**     | Installed via Helm      | SIEM system with agents      |
| Agent Status  | Active on worker nodes  | Collects Docker logs         |
| Alert System  | Wazuh Dashboard         | CVE, FIM, rootkit alerts     |

---

### 🧯 18. **BACKUP AND DISASTER RECOVERY MANAGEMENT**

| Component       | Strategy                               |
| --------------- | -------------------------------------- |
| RDS             | AWS Backup policy: Daily + weekly      |
| Terraform State | S3 bucket + versioning + DynamoDB lock |
| Jenkins         | `/var/jenkins_home` backup (cron + S3) |
| Logs            | Centralized + archived via Wazuh       |

---

### 📤 19. **COMMUNICATION AND NOTIFICATION CHANNELS**

| Event               | Notification Path      |
| ------------------ | ---------------------- |
| CI/CD build result | Slack: #devops         |
| Alertmanager       | Slack: #alerts         |
| Wazuh Alert        | Mail + Dashboard       |
| Uptime monitoring  | StatusCake (optional)  |

---

### 📚 20. **DOCUMENTATION & INFORMATION FLOW**

| Field                  | Description                            |
| ---------------------- | -------------------------------------- |
| README.md              | Mandatory for every microservice       |
| Wiki / Notion          | DevOps processes and architecture      |
| Dashboard access       | Grafana, Wazuh links are on record     |
| Onboarding documents   | Jenkins, kubectl access documentation  |

