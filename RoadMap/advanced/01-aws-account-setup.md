---
description: "Faz 1 (Gün 1-2): AWS hesap açma, AWS CLI konfigürasyonu, kimlik doğrulama, Organization kurulumu ve Organizational Unit oluşturma adımları."
tags:
  - Roadmap
  - AWS
  - Security
  - Compliance
---
# 🏢 **PHASE 1: AWS HESAP VE İLK KURULUMLAR** (Gün 1-2)

### ☁️ **2.1 AWS Hesap Kurulumu ve Organization Setup**

```bash
# 2.1.1 AWS hesabı oluştur (manuel - web üzerinden)
# https://aws.amazon.com/free/ üzerinden hesap oluştur

# 2.1.2 AWS CLI konfigürasyonu
aws configure
# AWS Access Key ID [None]: YOUR_ACCESS_KEY
# AWS Secret Access Key [None]: YOUR_SECRET_KEY
# Default region name [None]: eu-west-1
# Default output format [None]: json

# 2.1.3 AWS hesap doğrulama
aws sts get-caller-identity
aws ec2 describe-regions

# 2.1.4 AWS Organization setup (Root hesap için)
aws organizations create-organization --feature-set ALL

# 2.1.5 Organizational Units oluştur
aws organizations create-organizational-unit \
    --parent-id r-xxxx \
    --name "Production"

aws organizations create-organizational-unit \
    --parent-id r-xxxx \
    --name "Development"

aws organizations create-organizational-unit \
    --parent-id r-xxxx \
    --name "Security"
```

### 🔐 **2.2 IAM Setup ve Security Hardening**

```bash
# 2.2.1 Admin user oluştur (root user kullanmamak için)
aws iam create-user --user-name devops-admin

# 2.2.2 Admin user'a AdministratorAccess policy ekle
aws iam attach-user-policy \
    --user-name devops-admin \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# 2.2.3 Admin user için programmatic access
aws iam create-access-key --user-name devops-admin
# Output'taki access key ve secret key'i kaydet

# 2.2.4 Password policy oluştur
cat > password-policy.json << 'EOF'
{
    "MinimumPasswordLength": 12,
    "RequireSymbols": true,
    "RequireNumbers": true,
    "RequireUppercaseCharacters": true,
    "RequireLowercaseCharacters": true,
    "AllowUsersToChangePassword": true,
    "MaxPasswordAge": 90,
    "PasswordReusePrevention": 5,
    "HardExpiry": false
}
EOF

aws iam update-account-password-policy --cli-input-json file://password-policy.json

# 2.2.5 MFA activation (console üzerinden yapılacak)
# https://console.aws.amazon.com/iam/home#/security_credentials
```

### 🏗️ **2.3 Project Directory Structure Oluşturma**

```bash
# 2.3.1 Ana proje dizini oluştur
mkdir -p ~/devops-infrastructure
cd ~/devops-infrastructure

# 2.3.2 Directory structure oluştur
mkdir -p {terraform/{modules,environments/{dev,staging,prod}},kubernetes/{base,overlays/{dev,staging,prod}},docker,scripts,docs,monitoring,backup}

# 2.3.3 Git repository initialize
git init
git config user.name "Your Name"
git config user.email "your.email@company.com"

# 2.3.4 .gitignore oluştur
cat > .gitignore << 'EOF'
# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
terraform.tfvars
*.tfplan

# Docker
.dockerignore

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# Secrets
secrets/
*.pem
*.key
!public.key

# Backup
backup/
EOF

# 2.3.5 README.md oluştur
cat > README.md << 'EOF'
# DevOps Infrastructure

Bu repository şirketimizin DevOps altyapısını içerir.

## Struktur
- `terraform/` - Infrastructure as Code
- `kubernetes/` - K8s manifests
- `docker/` - Dockerfile'lar
- `scripts/` - Automation scripts
- `docs/` - Dokümantasyon
- `monitoring/` - Monitoring configs
- `backup/` - Backup scripts

## Kurulum
[Kurulum talimatları buraya]
EOF

git add .
git commit -m "Initial project structure"
```

---
