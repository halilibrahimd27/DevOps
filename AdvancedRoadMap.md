# 🏗️ **DevOps Altyapısı Sıfırdan Implementation Guide**
*Hiçbir şeyin kurulu olmadığını varsayarak adım adım DevOps altyapısı kuracağız.*

---

## 📋 **ÖN KOŞULLAR VE HAZIRLIK**

### 🖥️ **1. Geliştirici Makine Kurulumu**

```bash
# 1.1 WSL2 kurulumu (Windows kullanıcıları için)
wsl --install
wsl --set-default-version 2

# 1.2 Essential tools kurulumu
# Ubuntu/Debian
sudo apt update && sudo apt install -y \
    curl wget git vim nano unzip \
    build-essential software-properties-common \
    apt-transport-https ca-certificates gnupg lsb-release

# macOS
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install curl wget git vim nano unzip
```

### 🔧 **1.2 Development Tools Kurulumu**

```bash
# Docker kurulumu (Ubuntu)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
newgrp docker

# Docker kurulumu (macOS)
brew install --cask docker

# Docker test
docker --version
docker run hello-world

# kubectl kurulumu
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

# Helm kurulumu
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

# Terraform kurulumu
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
terraform --version

# AWS CLI kurulumu
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### 🎯 **1.3 IDE ve Editör Kurulumu**

```bash
# VS Code kurulumu
# Ubuntu
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update && sudo apt install code

# macOS
brew install --cask visual-studio-code

# Essential VS Code extensions
code --install-extension ms-vscode-remote.remote-wsl
code --install-extension ms-vscode.vscode-docker
code --install-extension hashicorp.terraform
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
code --install-extension redhat.vscode-yaml
code --install-extension ms-vscode.azure-account
```

---

## 🏢 **PHASE 1: AWS HESAP VE İLK KURULUMLAR** (Gün 1-2)

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

## 🛠️ **PHASE 2: TERRAFORM VE INFRASTRUCTURE AS CODE** (Gün 3-5)

### 🏗️ **3.1 Terraform Backend Setup**

```bash
# 3.1.1 Terraform backend için S3 bucket ve DynamoDB table oluştur
cd ~/devops-infrastructure/terraform

# 3.1.2 Backend setup script
cat > setup-backend.sh << 'EOF'
#!/bin/bash

# Variables
BUCKET_NAME="devops-terraform-state-$(openssl rand -hex 8)"
REGION="eu-west-1"
DYNAMODB_TABLE="terraform-state-lock"

# S3 bucket oluştur
aws s3 mb s3://$BUCKET_NAME --region $REGION

# S3 bucket versioning aktifleştir
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# S3 bucket encryption aktifleştir
aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# DynamoDB table oluştur
aws dynamodb create-table \
    --table-name $DYNAMODB_TABLE \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $REGION

echo "Backend setup completed!"
echo "S3 Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo "Region: $REGION"

# .env dosyasına kaydet
cat > ../.env << EOF
export TF_VAR_backend_bucket=$BUCKET_NAME
export TF_VAR_backend_region=$REGION
export TF_VAR_backend_dynamodb_table=$DYNAMODB_TABLE
EOF
EOF

chmod +x setup-backend.sh
./setup-backend.sh
source ../.env
```

### 🗂️ **3.2 Terraform Module Structure**

```bash
# 3.2.1 Terraform modules dizin yapısı
cd ~/devops-infrastructure/terraform/modules

# 3.2.2 VPC module
mkdir -p vpc
cat > vpc/main.tf << 'EOF'
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    Type        = "public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    Type        = "private"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = length(var.availability_zones)

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "${var.project_name}-${var.environment}-eip-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [aws_internet_gateway.main]
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Route table associations for public subnets
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route tables for private subnets
resource "aws_route_table" "private" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Route table associations for private subnets
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# VPC Flow Logs
resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flow-logs"
  retention_in_days = 7
}

resource "aws_iam_role" "flow_log" {
  name = "${var.project_name}-${var.environment}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_log" {
  name = "${var.project_name}-${var.environment}-flow-log-policy"
  role = aws_iam_role.flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
EOF

cat > vpc/outputs.tf << 'EOF'
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}
EOF

cat > vpc/versions.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF
```

### 🔒 **3.3 Security Groups Module**

```bash
# 3.3.1 Security Groups module
mkdir -p security-groups
cat > security-groups/main.tf << 'EOF'
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.project_name}-${var.environment}-eks-cluster-"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-eks-cluster-sg"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EKS Node Group Security Group
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.project_name}-${var.environment}-eks-nodes-"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow nodes to communicate with each other"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  ingress {
    description = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-eks-nodes-sg"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-"
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL/Aurora"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-sg"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ElastiCache Security Group
resource "aws_security_group" "elasticache" {
  name_prefix = "${var.project_name}-${var.environment}-elasticache-"
  vpc_id      = var.vpc_id

  ingress {
    description = "Redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-elasticache-sg"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}
EOF

cat > security-groups/outputs.tf << 'EOF'
output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "eks_cluster_security_group_id" {
  description = "EKS Cluster Security Group ID"
  value       = aws_security_group.eks_cluster.id
}

output "eks_nodes_security_group_id" {
  description = "EKS Nodes Security Group ID"
  value       = aws_security_group.eks_nodes.id
}

output "rds_security_group_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

output "elasticache_security_group_id" {
  description = "ElastiCache Security Group ID"
  value       = aws_security_group.elasticache.id
}
EOF
```

### 🔧 **3.4 EKS Module**

```bash
# 3.4.1 EKS module
mkdir -p eks
cat > eks/main.tf << 'EOF'
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS cluster"
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Subnet IDs for EKS node groups"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group ID for EKS cluster"
  type        = string
}

variable "node_security_group_id" {
  description = "Security group ID for EKS nodes"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# EKS Node Group IAM Role
resource "aws_iam_role" "node_group" {
  name = "${var.project_name}-${var.environment}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [var.cluster_security_group_id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_cloudwatch_log_group.eks
  ]

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group for EKS
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
}

# KMS Key for EKS encryption
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-eks-kms"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.project_name}-${var.environment}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.node_subnet_ids

  capacity_type        = "ON_DEMAND"
  ami_type            = "AL2_x86_64"
  instance_types      = ["t3.medium"]
  disk_size           = 20

  scaling_config {
    desired_size = 2
    max_size     = 10
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Remote access configuration
  remote_access {
    ec2_ssh_key               = aws_key_pair.eks_nodes.key_name
    source_security_group_ids = [var.node_security_group_id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Name        = "${var.cluster_name}-node-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

# SSH Key Pair for EKS nodes
resource "aws_key_pair" "eks_nodes" {
  key_name   = "${var.cluster_name}-eks-nodes"
  public_key = file("~/.ssh/id_rsa.pub")

  tags = {
    Name        = "${var.cluster_name}-eks-nodes"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EKS Add-ons
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
  addon_version = "v1.10.1-eksbuild.5"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
  addon_version = "v1.28.2-eksbuild.2"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
  addon_version = "v1.15.1-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"
  addon_version = "v1.25.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
}
EOF

cat > eks/outputs.tf << 'EOF'
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = aws_eks_cluster.main.version
}

output "node_group_arn" {
  description = "EKS node group ARN"
  value       = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "EKS node group status"
  value       = aws_eks_node_group.main.status
}
EOF
```

### 🗃️ **3.5 RDS Module**

```bash
# 3.5.1 RDS module
mkdir -p rds
cat > rds/main.tf << 'EOF'
variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "Subnet IDs for RDS"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for RDS"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.4"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "RDS allocated storage"
  type        = number
  default     = 20
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "${var.engine}15"
  name   = "${var.project_name}-${var.environment}-db-params"

  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [
      {
        name  = "log_statement"
        value = "all"
      },
      {
        name  = "log_duration"
        value = "1"
      },
      {
        name  = "log_min_duration_statement"
        value = "1000"
      }
    ] : []

    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-params"
    Environment = var.environment
    Project     = var.project_name
  }
}

# KMS Key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "RDS encryption key"
  deletion_window_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-kms"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-${var.environment}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"

  # Engine options
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id           = aws_kms_key.rds.arn

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network & Security
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false

  # Backup
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn

  # Parameters
  parameter_group_name = aws_db_parameter_group.main.name

  # Deletion protection
  deletion_protection = var.environment == "prod" ? true : false
  skip_final_snapshot = var.environment == "prod" ? false : true
  final_snapshot_identifier = var.environment == "prod" ? "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  tags = {
    Name        = "${var.project_name}-${var.environment}-db"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Read Replica (for production)
resource "aws_db_instance" "read_replica" {
  count = var.environment == "prod" ? 1 : 0

  identifier = "${var.project_name}-${var.environment}-db-read-replica"

  replicate_source_db = aws_db_instance.main.identifier
  instance_class      = var.instance_class

  # Network & Security
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn

  skip_final_snapshot = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-read-replica"
    Environment = var.environment
    Project     = var.project_name
  }
}
EOF

cat > rds/outputs.tf << 'EOF'
output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_subnet_group_id" {
  description = "DB subnet group ID"
  value       = aws_db_subnet_group.main.id
}

output "db_parameter_group_id" {
  description = "DB parameter group ID"
  value       = aws_db_parameter_group.main.id
}

output "read_replica_endpoint" {
  description = "Read replica endpoint"
  value       = var.environment == "prod" ? aws_db_instance.read_replica[0].endpoint : null
}
EOF
```

### 🎯 **3.6 Environment-Specific Configurations**

```bash
# 3.6.1 Development environment
cd ~/devops-infrastructure/terraform/environments/dev

# SSH key pair oluştur
ssh-keygen -t rsa -b 4096 -C "devops@company.com" -f ~/.ssh/id_rsa -N ""

cat > main.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Backend configuration will be provided via backend config file
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# Local values
locals {
  cluster_name = "${var.project_name}-${var.environment}-eks"
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
  project_name       = var.project_name
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id       = module.vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  cluster_name              = local.cluster_name
  cluster_version          = var.kubernetes_version
  subnet_ids               = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  node_subnet_ids          = module.vpc.private_subnet_ids
  cluster_security_group_id = module.security_groups.eks_cluster_security_group_id
  node_security_group_id   = module.security_groups.eks_nodes_security_group_id
  environment              = var.environment
  project_name             = var.project_name
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security_groups.rds_security_group_id
  environment       = var.environment
  project_name      = var.project_name
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
}
EOF

cat > variables.tf << 'EOF'
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "mycompany"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "mycompanydb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
EOF

cat > terraform.tfvars << 'EOF'
aws_region      = "eu-west-1"
environment     = "dev"
project_name    = "mycompany"
vpc_cidr        = "10.0.0.0/16"
availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
kubernetes_version = "1.28"
db_name         = "mycompanydb"
db_username     = "admin"
db_password     = "SuperSecurePassword123!"
EOF

cat > outputs.tf << 'EOF'
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_id
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_instance_endpoint
}

output "configure_kubectl" {
  description = "Configure kubectl command"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_id}"
}
EOF

# Backend configuration
cat > backend.conf << EOF
bucket         = "$TF_VAR_backend_bucket"
key            = "dev/terraform.tfstate"
region         = "$TF_VAR_backend_region"
dynamodb_table = "$TF_VAR_backend_dynamodb_table"
encrypt        = true
EOF
```

### 🚀 **3.7 Terraform Initialize ve Deploy**

```bash
# 3.7.1 Terraform initialize
cd ~/devops-infrastructure/terraform/environments/dev
terraform init -backend-config=backend.conf

# 3.7.2 Terraform plan
terraform plan -out=tfplan

# 3.7.3 Terraform apply
terraform apply tfplan

# 3.7.4 kubectl konfigürasyonu
aws eks update-kubeconfig --region eu-west-1 --name $(terraform output -raw eks_cluster_name)

# 3.7.5 Cluster bağlantısını test et
kubectl get nodes
kubectl get pods --all-namespaces

# 3.7.6 Terraform outputs
terraform output
```

---

## 🐳 **PHASE 3: CONTAINERIZATION VE REGISTRY** (Gün 6-7)

### 📦 **4.1 GitHub Container Registry Setup**

```bash
# 4.1.1 GitHub Personal Access Token oluştur
# GitHub -> Settings -> Developer settings -> Personal access tokens -> Tokens (classic)
# Permissions: write:packages, read:packages, delete:packages

# 4.1.2 GitHub Container Registry'ye login
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 4.1.3 Test image push
docker pull hello-world
docker tag hello-world ghcr.io/yourusername/hello-world:latest
docker push ghcr.io/yourusername/hello-world:latest
```

### 🏗️ **4.2 Docker Multi-Stage Build Templates**

```bash
# 4.2.1 Docker templates dizini
cd ~/devops-infrastructure/docker
mkdir -p {nodejs,python,golang,java,nginx}

# 4.2.2 Node.js Dockerfile template
cat > nodejs/Dockerfile << 'EOF'
# Multi-stage build for Node.js applications
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Build application
RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy built application from builder stage
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start application
CMD ["node", "dist/index.js"]
EOF

# 4.2.3 Python Dockerfile template
cat > python/Dockerfile << 'EOF'
# Multi-stage build for Python applications
FROM python:3.11-slim AS builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.11-slim AS production

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    dumb-init \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# Set working directory
WORKDIR /app

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python healthcheck.py

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start application
CMD ["python", "app.py"]
EOF

# 4.2.4 Golang Dockerfile template
cat > golang/Dockerfile << 'EOF'
# Multi-stage build for Go applications
FROM golang:1.21-alpine AS builder

# Install git for go modules
RUN apk add --no-cache git

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build application with optimizations
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o main .

# Production stage
FROM scratch AS production

# Add ca-certificates for HTTPS
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binary from builder
COPY --from=builder /app/main /main

# Expose port
EXPOSE 8080

# Health check (for scratch images, implement in Go)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/main", "-health"]

# Start application
ENTRYPOINT ["/main"]
EOF

# 4.2.5 Docker Compose template
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d myapp"]
      interval: 30s
      timeout: 5s
      retries: 3

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 5s
      retries: 3

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
EOF

# 4.2.6 .dockerignore
cat > .dockerignore << 'EOF'
# Git
.git
.gitignore

# Documentation
README.md
CHANGELOG.md
docs/

# Dependencies
node_modules/
vendor/
__pycache__/
*.pyc
target/

# Build artifacts
dist/
build/
*.log

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local
.env.*.local

# Testing
coverage/
.nyc_output/
test-results/

# Terraform
*.tfstate
*.tfstate.*
.terraform/

# Docker
Dockerfile*
docker-compose*
EOF
```

### 🔒 **4.3 Container Security Scanning Setup**

```bash
# 4.3.1 Trivy kurulumu (vulnerability scanner)
# Ubuntu/Debian
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install trivy

# macOS
brew install trivy

# 4.3.2 Hadolint kurulumu (Dockerfile linter)
# Ubuntu/Debian
wget -O hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
chmod +x hadolint
sudo mv hadolint /usr/local/bin/

# macOS
brew install hadolint

# 4.3.3 Container security scanning script
cat > ~/devops-infrastructure/scripts/container-security-scan.sh << 'EOF'
#!/bin/bash

# Container Security Scanning Script
set -e

IMAGE_NAME=$1
if [ -z "$IMAGE_NAME" ]; then
    echo "Usage: $0 <image-name>"
    exit 1
fi

echo "🔍 Starting security scan for $IMAGE_NAME..."

# 1. Dockerfile linting
echo "📋 Running Dockerfile lint..."
if [ -f "Dockerfile" ]; then
    hadolint Dockerfile || echo "⚠️  Dockerfile linting issues found"
else
    echo "❌ Dockerfile not found"
fi

# 2. Image vulnerability scanning
echo "🛡️  Running vulnerability scan..."
trivy image --exit-code 1 --severity HIGH,CRITICAL $IMAGE_NAME

# 3. Configuration scanning
echo "⚙️  Running configuration scan..."
trivy config --exit-code 1 .

# 4. Secret scanning
echo "🔐 Running secret scan..."
trivy fs --exit-code 1 --scanners secret .

echo "✅ Security scan completed for $IMAGE_NAME"
EOF

chmod +x ~/devops-infrastructure/scripts/container-security-scan.sh

# 4.3.4 Pre-commit hooks için security scanning
cat > ~/devops-infrastructure/.pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/hadolint/hadolint
    rev: v2.12.0
    hooks:
      - id: hadolint-docker
        args: [--config, .hadolint.yaml]

  - repo: https://github.com/aquasecurity/trivy
    rev: v0.48.0
    hooks:
      - id: trivy-docker
        args: [--exit-code, "1", --severity, "HIGH,CRITICAL"]

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict
EOF

# Hadolint config
cat > ~/devops-infrastructure/.hadolint.yaml << 'EOF'
ignored:
  - DL3008  # Pin versions in apt get install
  - DL3009  # Delete the apt-get lists after installing something
  - DL3015  # Avoid additional packages by specifying --no-install-recommends

trusted-registries:
  - docker.io
  - ghcr.io
  - quay.io
EOF
```

---

## 🔄 **PHASE 4: CI/CD PIPELINE KURULUMU** (Gün 8-10)

### 🛠️ **5.1 Jenkins on Kubernetes Setup**

```bash
# 5.1.1 Jenkins namespace ve RBAC oluştur
cd ~/devops-infrastructure/kubernetes/base
mkdir -p jenkins

cat > jenkins/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: jenkins
  labels:
    name: jenkins
EOF

cat > jenkins/serviceaccount.yaml << 'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: jenkins
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: jenkins
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["create","delete","get","list","patch","update","watch"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create","delete","get","list","patch","update","watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get","list","watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get","list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: jenkins
subjects:
- kind: ServiceAccount
  name: jenkins
  namespace: jenkins
EOF

cat > jenkins/pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pvc
  namespace: jenkins
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 10Gi
EOF

cat > jenkins/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      serviceAccountName: jenkins
      containers:
      - name: jenkins
        image: jenkins/jenkins:2.414.1-lts-jdk11
        ports:
        - containerPort: 8080
        - containerPort: 50000
        env:
        - name: JAVA_OPTS
          value: "-Xmx2048m -Dhudson.slaves.NodeProvisioner.MARGIN=50 -Dhudson.slaves.NodeProvisioner.MARGIN0=0.85"
        - name: JENKINS_OPTS
          value: "--httpPort=8080"
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        - name: docker-sock
          mountPath: /var/run/docker.sock
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 5
        readinessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
      volumes:
      - name: jenkins-home
        persistentVolumeClaim:
          claimName: jenkins-pvc
      - name: docker-sock
        hostPath:
          path: /var/run/docker.sock
      securityContext:
        fsGroup: 1000
        runAsUser: 1000
EOF

cat > jenkins/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: jenkins
  namespace: jenkins
spec:
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  - name: jnlp
    port: 50000
    targetPort: 50000
  selector:
    app: jenkins
  type: ClusterIP
EOF

cat > jenkins/ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jenkins
  namespace: jenkins
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - jenkins.yourdomain.com
    secretName: jenkins-tls
  rules:
  - host: jenkins.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: jenkins
            port:
              number: 8080
EOF

# 5.1.2 Jenkins deploy
kubectl apply -f jenkins/
kubectl get pods -n jenkins
kubectl logs -f deployment/jenkins -n jenkins
```

### 🌐 **5.2 NGINX Ingress Controller Setup**

```bash
# 5.2.1 NGINX Ingress Controller kurulumu
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-cross-zone-load-balancing-enabled"="true"

# 5.2.2 Ingress controller durumunu kontrol et
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# 5.2.3 External IP'yi al
EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "External LoadBalancer: $EXTERNAL_IP"
```

### 🔐 **5.3 Cert-Manager Setup (SSL/TLS)**

```bash
# 5.3.1 Cert-Manager kurulumu
helm repo add jetstack https://charts.jetstack.io
helm repo update

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0

# 5.3.2 Let's Encrypt ClusterIssuer
cat > ~/devops-infrastructure/kubernetes/base/cert-manager-issuer.yaml << 'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@yourdomain.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@yourdomain.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

kubectl apply -f ~/devops-infrastructure/kubernetes/base/cert-manager-issuer.yaml

# 5.3.3 Cert-manager durumunu kontrol et
kubectl get pods -n cert-manager
kubectl get clusterissuers
```

### 🔧 **5.4 Jenkins Initial Setup**

```bash
# 5.4.1 Jenkins admin password'unu al
kubectl exec -n jenkins -it deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword

# 5.4.2 Jenkins URL'sine eriş (port-forward ile)
kubectl port-forward -n jenkins svc/jenkins 8080:8080

# 5.4.3 Jenkins Initial Setup (Browser üzerinden)
# http://localhost:8080
# - Initial password gir
# - Suggested plugins install et
# - Admin user oluştur
# - Jenkins URL'yi ayarla

# 5.4.4 Essential Jenkins plugins kurulumu (Browser üzerinden)
# Manage Jenkins -> Manage Plugins -> Available
# - Blue Ocean
# - Pipeline
# - Git Pipeline for Blue Ocean
# - Docker Pipeline
# - Kubernetes CLI
# - GitHub Integration
# - Slack Notification
# - Build Timestamp
# - AnsiColor
# - Workspace Cleanup
```

### 📝 **5.5 Jenkins Pipeline as Code**

```bash
# 5.5.1 Shared Pipeline Library oluştur
mkdir -p ~/devops-infrastructure/jenkins/shared-library/{vars,src,resources}

cat > ~/devops-infrastructure/jenkins/shared-library/vars/buildAndPush.groovy << 'EOF'
def call(Map config) {
    pipeline {
        agent {
            kubernetes {
                yaml """
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: docker
                    image: docker:latest
                    command:
                    - cat
                    tty: true
                    volumeMounts:
                    - mountPath: /var/run/docker.sock
                      name: docker-sock
                  - name: kubectl
                    image: bitnami/kubectl:latest
                    command:
                    - cat
                    tty: true
                  - name: helm
                    image: alpine/helm:latest
                    command:
                    - cat
                    tty: true
                  volumes:
                  - name: docker-sock
                    hostPath:
                      path: /var/run/docker.sock
                """
            }
        }
        
        environment {
            DOCKER_REGISTRY = 'ghcr.io'
            IMAGE_NAME = "${config.imageName}"
            GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
            BUILD_VERSION = "${env.BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
        }
        
        stages {
            stage('Checkout') {
                steps {
                    checkout scm
                }
            }
            
            stage('Build Info') {
                steps {
                    script {
                        currentBuild.displayName = "#${env.BUILD_NUMBER} - ${BUILD_VERSION}"
                        currentBuild.description = "Branch: ${env.BRANCH_NAME}"
                    }
                }
            }
            
            stage('Lint Dockerfile') {
                steps {
                    container('docker') {
                        sh '''
                            echo "🔍 Linting Dockerfile..."
                            # Dockerfile linting would go here
                        '''
                    }
                }
            }
            
            stage('Build Docker Image') {
                steps {
                    container('docker') {
                        script {
                            def image = docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION}")
                            docker.withRegistry("https://${DOCKER_REGISTRY}", 'github-registry-credentials') {
                                image.push()
                                image.push("latest")
                            }
                        }
                    }
                }
            }
            
            stage('Security Scan') {
                steps {
                    container('docker') {
                        sh '''
                            echo "🛡️ Running security scan..."
                            # Trivy scanning would go here
                        '''
                    }
                }
            }
            
            stage('Deploy to Dev') {
                when {
                    branch 'develop'
                }
                steps {
                    container('kubectl') {
                        sh '''
                            echo "🚀 Deploying to development..."
                            kubectl set image deployment/${IMAGE_NAME} ${IMAGE_NAME}=${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION} -n dev
                            kubectl rollout status deployment/${IMAGE_NAME} -n dev
                        '''
                    }
                }
            }
            
            stage('Deploy to Staging') {
                when {
                    branch 'main'
                }
                steps {
                    container('kubectl') {
                        sh '''
                            echo "🚀 Deploying to staging..."
                            kubectl set image deployment/${IMAGE_NAME} ${IMAGE_NAME}=${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION} -n staging
                            kubectl rollout status deployment/${IMAGE_NAME} -n staging
                        '''
                    }
                }
            }
            
            stage('Deploy to Production') {
                when {
                    buildingTag()
                }
                steps {
                    script {
                        timeout(time: 5, unit: 'MINUTES') {
                            input message: 'Deploy to production?', ok: 'Deploy'
                        }
                    }
                    container('kubectl') {
                        sh '''
                            echo "🚀 Deploying to production..."
                            kubectl set image deployment/${IMAGE_NAME} ${IMAGE_NAME}=${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION} -n production
                            kubectl rollout status deployment/${IMAGE_NAME} -n production
                        '''
                    }
                }
            }
        }
        
        post {
            success {
                slackSend(
                    channel: '#deployments',
                    color: 'good',
                    message: "✅ ${IMAGE_NAME} v${BUILD_VERSION} deployed successfully to ${env.BRANCH_NAME}"
                )
            }
            failure {
                slackSend(
                    channel: '#deployments',
                    color: 'danger',
                    message: "❌ ${IMAGE_NAME} v${BUILD_VERSION} deployment failed on ${env.BRANCH_NAME}"
                )
            }
        }
    }
}
EOF

# 5.5.2 Sample application Jenkinsfile
cat > ~/devops-infrastructure/jenkins/sample-Jenkinsfile << 'EOF'
@Library('shared-library') _

buildAndPush([
    imageName: 'mycompany/sample-app'
])
EOF
```

### 🔐 **5.6 Jenkins Credentials Setup**

```bash
# 5.6.1 GitHub credentials secret oluştur
kubectl create secret generic github-registry-credentials \
  --from-literal=username=YOUR_GITHUB_USERNAME \
  --from-literal=password=YOUR_GITHUB_TOKEN \
  --namespace=jenkins

# 5.6.2 AWS credentials secret oluştur
kubectl create secret generic aws-credentials \
  --from-literal=access-key-id=YOUR_AWS_ACCESS_KEY \
  --from-literal=secret-access-key=YOUR_AWS_SECRET_KEY \
  --namespace=jenkins

# 5.6.3 Jenkins'te credentials ekle (Browser üzerinden)
# Manage Jenkins -> Manage Credentials -> Global -> Add Credentials
# - GitHub Token: Kind=Username with password, ID=github-registry-credentials
# - AWS Credentials: Kind=AWS Credentials, ID=aws-credentials
# - Kubeconfig: Kind=Secret file, ID=kubeconfig
```

---

## ☸️ **PHASE 5: KUBERNETES ADVANCED SETUP** (Gün 11-13)

### 🏷️ **6.1 Namespace ve RBAC Setup**

```bash
# 6.1.1 Environment namespaces oluştur
cd ~/devops-infrastructure/kubernetes/base

cat > namespaces.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    environment: dev
    istio-injection: enabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    environment: staging
    istio-injection: enabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
    istio-injection: enabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
  labels:
    environment: monitoring
    istio-injection: disabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: logging
  labels:
    environment: logging
    istio-injection: disabled
EOF

kubectl apply -f namespaces.yaml

# 6.1.2 RBAC setup
cat > rbac.yaml << 'EOF'
# Developer Role - dev namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev
  name: developer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
---
# Staging Role - staging namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: staging
  name: staging-deployer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "update", "patch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
---
# Production Role - production namespace (read-only + deploy)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: production-deployer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "update", "patch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
---
# ServiceAccount for developers
apiVersion: v1
kind: ServiceAccount
metadata:
  name: developer
  namespace: dev
---
# ServiceAccount for staging
apiVersion: v1
kind: ServiceAccount
metadata:
  name: staging-deployer
  namespace: staging
---
# ServiceAccount for production
apiVersion: v1
kind: ServiceAccount
metadata:
  name: production-deployer
  namespace: production
---
# RoleBinding for developers
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: dev
subjects:
- kind: ServiceAccount
  name: developer
  namespace: dev
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
---
# RoleBinding for staging
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: staging-deployer-binding
  namespace: staging
subjects:
- kind: ServiceAccount
  name: staging-deployer
  namespace: staging
roleRef:
  kind: Role
  name: staging-deployer
  apiGroup: rbac.authorization.k8s.io
---
# RoleBinding for production
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: production-deployer-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: production-deployer
  namespace: production
roleRef:
  kind: Role
  name: production-deployer
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f rbac.yaml
```

### 📦 **6.2 StorageClass ve Persistent Volumes**

```bash
# 6.2.1 StorageClass definitions
cat > storage-classes.yaml << 'EOF'
# GP3 StorageClass (default)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
---
# GP3 Fast StorageClass
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-fast
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
  encrypted: "true"
  iops: "4000"
  throughput: "250"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
---
# IO1 StorageClass (high performance)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: io1
provisioner: ebs.csi.aws.com
parameters:
  type: io1
  fsType: ext4
  encrypted: "true"
  iops: "1000"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF

kubectl apply -f storage-classes.yaml
kubectl get storageclass
```

### 🔧 **6.3 Horizontal Pod Autoscaler (HPA) Setup**

```bash
# 6.3.1 Metrics Server kurulumu
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Metrics server düzeltmesi (EKS için)
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]'

# 6.3.2 HPA template
cat > hpa-template.yaml << 'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: sample-app-hpa
  namespace: dev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sample-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
EOF
```

### 🔄 **6.4 Cluster Autoscaler Setup**

```bash
# 6.4.1 Cluster Autoscaler kurulumu
cat > cluster-autoscaler.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    app: cluster-autoscaler
spec:
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
      annotations:
        prometheus.io/scrape: 'true'
        prometheus.io/port: '8085'
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
      - image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.28.0
        name: cluster-autoscaler
        resources:
          limits:
            cpu: 100m
            memory: 300Mi
          requests:
            cpu: 100m
            memory: 300Mi
        command:
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=aws
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/CLUSTER_NAME
        env:
        - name: AWS_REGION
          value: eu-west-1
        volumeMounts:
        - name: ssl-certs
          mountPath: /etc/ssl/certs/ca-certificates.crt
          readOnly: true
        imagePullPolicy: "Always"
      volumes:
      - name: ssl-certs
        hostPath:
          path: "/etc/ssl/certs/ca-bundle.crt"
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
  name: cluster-autoscaler
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/cluster-autoscaler
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-autoscaler
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
rules:
- apiGroups: [""]
  resources: ["events", "endpoints"]
  verbs: ["create", "patch"]
- apiGroups: [""]
  resources: ["pods/eviction"]
  verbs: ["create"]
- apiGroups: [""]
  resources: ["pods/status"]
  verbs: ["update"]
- apiGroups: [""]
  resources: ["endpoints"]
  resourceNames: ["cluster-autoscaler"]
  verbs: ["get", "update"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["watch", "list", "get", "update"]
- apiGroups: [""]
  resources: ["pods", "services", "replicationcontrollers", "persistentvolumeclaims", "persistentvolumes"]
  verbs: ["watch", "list", "get"]
- apiGroups: ["extensions"]
  resources: ["replicasets", "daemonsets"]
  verbs: ["watch", "list", "get"]
- apiGroups: ["policy"]
  resources: ["poddisruptionbudgets"]
  verbs: ["watch", "list"]
- apiGroups: ["apps"]
  resources: ["statefulsets", "replicasets", "daemonsets"]
  verbs: ["watch", "list", "get"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"]
  verbs: ["watch", "list", "get"]
- apiGroups: ["batch", "extensions"]
  resources: ["jobs"]
  verbs: ["get", "list", "watch", "patch"]
- apiGroups: ["coordination.k8s.io"]
  resources: ["leases"]
  verbs: ["create"]
- apiGroups: ["coordination.k8s.io"]
  resourceNames: ["cluster-autoscaler"]
  resources: ["leases"]
  verbs: ["get", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-autoscaler
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-autoscaler
subjects:
- kind: ServiceAccount
  name: cluster-autoscaler
  namespace: kube-system
EOF

# CLUSTER_NAME'i gerçek cluster ismiyle değiştir
sed -i 's/CLUSTER_NAME/mycompany-dev-eks/g' cluster-autoscaler.yaml
kubectl apply -f cluster-autoscaler.yaml
```

### 🔒 **6.5 Network Policies**

```bash
# 6.5.1 Calico CNI kurulumu (Network Policies için)
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

# Calico configuration
cat > calico-config.yaml << 'EOF'
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 192.168.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
EOF

kubectl apply -f calico-config.yaml

# 6.5.2 Network Policy templates
cat > network-policies.yaml << 'EOF'
# Default deny all ingress traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: dev
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
# Allow ingress from same namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: dev
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: dev
---
# Allow ingress from ingress-nginx
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-nginx
  namespace: dev
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
---
# Allow database access only from backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-access
  namespace: dev
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 5432
---
# Allow monitoring namespace access
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring
  namespace: dev
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 8080
    - protocol: TCP
      port: 9090
EOF

kubectl apply -f network-policies.yaml
```

---

## 📊 **PHASE 6: OBSERVABILITY STACK** (Gün 14-16)

### 📈 **7.1 Prometheus & Grafana Setup**

```bash
# 7.1.1 kube-prometheus-stack kurulumu
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Custom values.yaml oluştur
cat > monitoring-values.yaml << 'EOF'
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 20Gi
    retention: 15d
    resources:
      requests:
        memory: 2Gi
        cpu: 1000m
      limits:
        memory: 4Gi
        cpu: 2000m
    additionalScrapeConfigs: |
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
          action: keep
          regex: true
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
          action: replace
          target_label: __metrics_path__
          regex: (.+)
        - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
          action: replace
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: $1:$2
          target_label: __address__

alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 5Gi
    resources:
      requests:
        memory: 256Mi
        cpu: 100m
      limits:
        memory: 512Mi
        cpu: 200m
  config:
    global:
      slack_api_url: 'YOUR_SLACK_WEBHOOK_URL'
    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'web.hook'
      routes:
      - match:
          alertname: DeadMansSwitch
        receiver: 'null'
      - match_re:
          severity: critical|warning
        receiver: 'slack-notifications'
    receivers:
    - name: 'null'
    - name: 'web.hook'
      webhook_configs:
      - url: 'http://127.0.0.1:5001/'
    - name: 'slack-notifications'
      slack_configs:
      - channel: '#alerts'
        title: 'Cluster Alert - {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
        send_resolved: true

grafana:
  adminPassword: 'AdminPassword123!'
  persistence:
    enabled: true
    storageClassName: gp3
    size: 10Gi
  resources:
    requests:
      memory: 256Mi
      cpu: 100m
    limits:
      memory: 512Mi
      cpu: 200m
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default
  dashboards:
    default:
      kubernetes-cluster-overview:
        gnetId: 7249
        revision: 1
        datasource: Prometheus
      kubernetes-pod-overview:
        gnetId: 6417
        revision: 1
        datasource: Prometheus
      nginx-ingress-controller:
        gnetId: 9614
        revision: 1
        datasource: Prometheus
      node-exporter:
        gnetId: 1860
        revision: 31
        datasource: Prometheus

nodeExporter:
  enabled: true

kubeStateMetrics:
  enabled: true

defaultRules:
  create: true
  rules:
    alertmanager: true
    etcd: true
    configReloaders: true
    general: true
    k8s: true
    kubeApiserverAvailability: true
    kubeApiserverBurnrate: true
    kubeApiserverHistogram: true
    kubeApiserverSlos: true
    kubelet: true
    kubeProxy: true
    kubePrometheusGeneral: true
    kubePrometheusNodeRecording: true
    kubernetesApps: true
    kubernetesResources: true
    kubernetesStorage: true
    kubernetesSystem: true
    network: true
    node: true
    nodeExporterAlerting: true
    nodeExporterRecording: true
    prometheus: true
    prometheusOperator: true
EOF

# Monitoring namespace'i oluştur ve kube-prometheus-stack'i kur
kubectl create namespace monitoring
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring-values.yaml

# 7.1.2 Monitoring durumunu kontrol et
kubectl get pods -n monitoring
kubectl get svc -n monitoring

# 7.1.3 Grafana ingress
cat > grafana-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - grafana.yourdomain.com
    secretName: grafana-tls
  rules:
  - host: grafana.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kube-prometheus-stack-grafana
            port:
              number: 80
EOF

kubectl apply -f grafana-ingress.yaml
```

### 📝 **7.2 Centralized Logging Setup**

```bash
# 7.2.1 OpenSearch (Elasticsearch alternative) kurulumu
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update

cat > opensearch-values.yaml << 'EOF'
clusterName: "opensearch-cluster"
nodeGroup: "master"

roles:
  - master
  - ingest
  - data

replicas: 3

opensearchJavaOpts: "-Xmx1g -Xms1g"

resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "1000m"
    memory: "2Gi"

persistence:
  enabled: true
  size: 30Gi
  storageClass: gp3

config:
  opensearch.yml: |
    cluster.name: opensearch-cluster
    network.host: 0.0.0.0
    plugins:
      security:
        ssl:
          transport:
            pemcert_filepath: esnode.pem
            pemkey_filepath: esnode-key.pem
            pemtrustedcas_filepath: root-ca.pem
            enforce_hostname_verification: false
          http:
            enabled: false
        allow_unsafe_democertificates: true
        allow_default_init_securityindex: true
        authcz:
          admin_dn:
            - CN=kirk,OU=client,O=client,L=test,C=de
        audit.type: internal_opensearch
        enable_snapshot_restore_privilege: true
        check_snapshot_restore_write_privileges: true
        restapi:
          roles_enabled: ["all_access", "security_rest_api_access"]
        system_indices:
          enabled: true
          indices:
            [
              ".opendistro-alerting-config",
              ".opendistro-alerting-alert*",
              ".opendistro-anomaly-results*",
              ".opendistro-anomaly-detector*",
              ".opendistro-anomaly-checkpoints",
              ".opendistro-anomaly-detection-state",
              ".opendistro-reports-*",
              ".opendistro-notifications-*",
              ".opendistro-notebooks",
              ".opendistro-asynchronous-search-response*",
            ]
EOF

kubectl create namespace logging
helm install opensearch opensearch/opensearch \
  --namespace logging \
  --values opensearch-values.yaml

# 7.2.2 OpenSearch Dashboards kurulumu
cat > opensearch-dashboards-values.yaml << 'EOF'
replicaCount: 1

opensearchHosts: "https://opensearch-cluster-master:9200"

resources:
  requests:
    cpu: "250m"
    memory: "512Mi"
  limits:
    cpu: "500m"
    memory: "1Gi"

config:
  opensearch_dashboards.yml: |
    server.name: opensearch-dashboards
    server.host: 0.0.0.0
    opensearch.hosts: [https://opensearch-cluster-master:9200]
    opensearch.ssl.verificationMode: none
    opensearch.username: admin
    opensearch.password: admin
    opensearch.requestHeadersAllowlist: [authorization, securitytenant]
    opensearch_security.multitenancy.enabled: true
    opensearch_security.multitenancy.tenants.preferred: [Private, Global]
    opensearch_security.readonly_mode.roles: [kibana_read_only]
    opensearch_security.cookie.secure: false
EOF

helm install opensearch-dashboards opensearch/opensearch-dashboards \
  --namespace logging \
  --values opensearch-dashboards-values.yaml

# 7.2.3 Fluent Bit kurulumu
cat > fluent-bit-values.yaml << 'EOF'
daemonSetVolumes:
  - name: varlog
    hostPath:
      path: /var/log
  - name: varlibdockercontainers
    hostPath:
      path: /var/lib/docker/containers
  - name: etcmachineid
    hostPath:
      path: /etc/machine-id
      type: File

daemonSetVolumeMounts:
  - name: varlog
    mountPath: /var/log
    readOnly: true
  - name: varlibdockercontainers
    mountPath: /var/lib/docker/containers
    readOnly: true
  - name: etcmachineid
    mountPath: /etc/machine-id
    readOnly: true

config:
  service: |
    [SERVICE]
        Daemon Off
        Flush {{ .Values.flush }}
        Log_Level {{ .Values.logLevel }}
        Parsers_File parsers.conf
        Parsers_File custom_parsers.conf
        HTTP_Server On
        HTTP_Listen 0.0.0.0
        HTTP_Port {{ .Values.metricsPort }}
        Health_Check On

  inputs: |
    [INPUT]
        Name tail
        Path /var/log/containers/*.log
        multiline.parser docker, cri
        Tag kube.*
        Mem_Buf_Limit 50MB
        Skip_Long_Lines On

    [INPUT]
        Name systemd
        Tag host.*
        Systemd_Filter _SYSTEMD_UNIT=kubelet.service
        Read_From_Tail On

  filters: |
    [FILTER]
        Name kubernetes
        Match kube.*
        Kube_URL https://kubernetes.default.svc:443
        Kube_CA_File /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File /var/run/secrets/kubernetes.io/serviceaccount/token
        Kube_Tag_Prefix kube.var.log.containers.
        Merge_Log On
        Keep_Log Off
        K8S-Logging.Parser On
        K8S-Logging.Exclude On
        Annotations Off
        Labels On

    [FILTER]
        Name nest
        Match kube.*
        Operation lift
        Nested_under kubernetes
        Add_prefix kubernetes_

    [FILTER]
        Name modify
        Match kube.*
        Remove kubernetes_pod_id
        Remove kubernetes_docker_id
        Remove kubernetes_container_hash

  outputs: |
    [OUTPUT]
        Name opensearch
        Match kube.*
        Host opensearch-cluster-master.logging.svc.cluster.local
        Port 9200
        Index fluentbit
        Type _doc
        HTTP_User admin
        HTTP_Passwd admin
        tls On
        tls.verify Off
        Suppress_Type_Name On
        Replace_Dots On

    [OUTPUT]
        Name opensearch
        Match host.*
        Host opensearch-cluster-master.logging.svc.cluster.local
        Port 9200
        Index fluentbit-systemd
        Type _doc
        HTTP_User admin
        HTTP_Passwd admin
        tls On
        tls.verify Off
        Suppress_Type_Name On
        Replace_Dots On
EOF

helm repo add fluent https://fluent.github.io/helm-charts
helm install fluent-bit fluent/fluent-bit \
  --namespace logging \
  --values fluent-bit-values.yaml

# 7.2.4 OpenSearch Dashboards ingress
cat > opensearch-dashboards-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: opensearch-dashboards
  namespace: logging
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - logs.yourdomain.com
    secretName: opensearch-dashboards-tls
  rules:
  - host: logs.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: opensearch-dashboards
            port:
              number: 5601
EOF

kubectl apply -f opensearch-dashboards-ingress.yaml
```

### 🔍 **7.3 Distributed Tracing with Jaeger**

```bash
# 7.3.1 Jaeger Operator kurulumu
kubectl create namespace observability
kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.47.0/jaeger-operator.yaml -n observability

# 7.3.2 Jaeger instance
cat > jaeger.yaml << 'EOF'
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
  namespace: observability
spec:
  strategy: production
  storage:
    type: opensearch
    opensearch:
      serverUrls: https://opensearch-cluster-master.logging.svc.cluster.local:9200
      username: admin
      password: admin
      tls:
        insecureSkipVerify: true
  collector:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
  query:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
    ingress:
      enabled: true
      annotations:
        kubernetes.io/ingress.class: nginx
        nginx.ingress.kubernetes.io/ssl-redirect: "true"
        cert-manager.io/cluster-issuer: "letsencrypt-prod"
      hosts:
        - jaeger.yourdomain.com
      tls:
        - secretName: jaeger-tls
          hosts:
            - jaeger.yourdomain.com
EOF

kubectl apply -f jaeger.yaml

# 7.3.3 OpenTelemetry Collector kurulumu
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

cat > otel-collector-values.yaml << 'EOF'
mode: daemonset

presets:
  logsCollection:
    enabled: true
  hostMetrics:
    enabled: true
  kubernetesAttributes:
    enabled: true

config:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318
    jaeger:
      protocols:
        grpc:
          endpoint: 0.0.0.0:14250
        thrift_http:
          endpoint: 0.0.0.0:14268
        thrift_compact:
          endpoint: 0.0.0.0:6831
    zipkin:
      endpoint: 0.0.0.0:9411

  processors:
    batch: {}
    memory_limiter:
      limit_mib: 400
    resource:
      attributes:
        - key: cluster.name
          value: mycompany-dev-eks
          action: insert

  exporters:
    jaeger:
      endpoint: jaeger-collector.observability.svc.cluster.local:14250
      tls:
        insecure: true
    prometheus:
      endpoint: "0.0.0.0:8889"
      const_labels:
        cluster: mycompany-dev-eks

  service:
    pipelines:
      traces:
        receivers: [otlp, jaeger, zipkin]
        processors: [memory_limiter, resource, batch]
        exporters: [jaeger]
      metrics:
        receivers: [otlp]
        processors: [memory_limiter, resource, batch]
        exporters: [prometheus]
      logs:
        receivers: [otlp]
        processors: [memory_limiter, resource, batch]
        exporters: []

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 256m
    memory: 512Mi
EOF

helm install opentelemetry-collector open-telemetry/opentelemetry-collector \
  --namespace observability \
  --values otel-collector-values.yaml
```

---

## 🔒 **PHASE 7: SECRETS MANAGEMENT & SECURITY** (Gün 17-18)

### 🔐 **8.1 HashiCorp Vault Setup**

```bash
# 8.1.1 Vault Helm kurulumu
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

cat > vault-values.yaml << 'EOF'
global:
  enabled: true
  tlsDisable: false

injector:
  enabled: true
  replicas: 1
  resources:
    requests:
      memory: 256Mi
      cpu: 250m
    limits:
      memory: 256Mi
      cpu: 250m

server:
  image:
    repository: "vault"
    tag: "1.15.0"

  resources:
    requests:
      memory: 256Mi
      cpu: 250m
    limits:
      memory: 256Mi
      cpu: 250m

  readinessProbe:
    enabled: true
    path: "/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"
  livenessProbe:
    enabled: true
    path: "/v1/sys/health?standbyok=true"
    initialDelaySeconds: 60

  extraEnvironmentVars:
    VAULT_CACERT: /vault/userconfig/vault-ha-tls/vault.ca
    VAULT_TLSCERT: /vault/userconfig/vault-ha-tls/vault.crt
    VAULT_TLSKEY: /vault/userconfig/vault-ha-tls/vault.key

  extraVolumes:
    - type: secret
      name: vault-ha-tls
      path: /vault/userconfig

  standalone:
    enabled: false

  ha:
    enabled: true
    replicas: 3
    raft:
      enabled: true
      setNodeId: true
      config: |
        ui = true
        
        listener "tcp" {
          tls_disable = 0
          address = "[::]:8200"
          cluster_address = "[::]:8201"
          tls_cert_file = "/vault/userconfig/vault-ha-tls/vault.crt"
          tls_key_file  = "/vault/userconfig/vault-ha-tls/vault.key"
          tls_client_ca_file = "/vault/userconfig/vault-ha-tls/vault.ca"
        }

        storage "raft" {
          path = "/vault/data"
          
          retry_join {
            leader_api_addr = "https://vault-0.vault-internal:8200"
            leader_ca_cert_file = "/vault/userconfig/vault-ha-tls/vault.ca"
            leader_client_cert_file = "/vault/userconfig/vault-ha-tls/vault.crt"
            leader_client_key_file = "/vault/userconfig/vault-ha-tls/vault.key"
          }
          
          retry_join {
            leader_api_addr = "https://vault-1.vault-internal:8200"
            leader_ca_cert_file = "/vault/userconfig/vault-ha-tls/vault.ca"
            leader_client_cert_file = "/vault/userconfig/vault-ha-tls/vault.crt"
            leader_client_key_file = "/vault/userconfig/vault-ha-tls/vault.key"
          }
          
          retry_join {
            leader_api_addr = "https://vault-2.vault-internal:8200"
            leader_ca_cert_file = "/vault/userconfig/vault-ha-tls/vault.ca"
            leader_client_cert_file = "/vault/userconfig/vault-ha-tls/vault.crt"
            leader_client_key_file = "/vault/userconfig/vault-ha-tls/vault.key"
          }
        }

        service_registration "kubernetes" {}

  service:
    enabled: true
    type: ClusterIP
    port: 8200
    targetPort: 8200

  dataStorage:
    enabled: true
    size: 10Gi
    storageClass: gp3

  auditStorage:
    enabled: true
    size: 10Gi
    storageClass: gp3

ui:
  enabled: true
  serviceType: ClusterIP
EOF

# 8.1.2 TLS sertifikaları oluştur
mkdir -p vault-tls
cd vault-tls

# CA private key
openssl genrsa -out vault-ca.key 2048

# CA certificate
openssl req -new -x509 -key vault-ca.key -out vault-ca.crt -days 365 \
  -subj "/C=US/ST=CA/L=San Francisco/O=HashiCorp/CN=Vault CA"

# Vault private key
openssl genrsa -out vault.key 2048

# Vault certificate signing request
cat > vault.conf << 'EOF'
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = CA
L = San Francisco
O = HashiCorp
CN = vault

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = vault
DNS.2 = vault.vault
DNS.3 = vault.vault.svc
DNS.4 = vault.vault.svc.cluster.local
DNS.5 = vault-0.vault-internal
DNS.6 = vault-1.vault-internal
DNS.7 = vault-2.vault-internal
DNS.8 = vault-0.vault-internal.vault.svc.cluster.local
DNS.9 = vault-1.vault-internal.vault.svc.cluster.local
DNS.10 = vault-2.vault-internal.vault.svc.cluster.local
DNS.11 = vault.yourdomain.com
IP.1 = 127.0.0.1
EOF

openssl req -new -key vault.key -out vault.csr -config vault.conf

# Vault certificate
openssl x509 -req -in vault.csr -CA vault-ca.crt -CAkey vault-ca.key \
  -CAcreateserial -out vault.crt -days 365 -extensions v3_req -extfile vault.conf

# 8.1.3 Vault namespace ve TLS secret oluştur
kubectl create namespace vault

kubectl create secret generic vault-ha-tls \
  --from-file=vault.key=vault.key \
  --from-file=vault.crt=vault.crt \
  --from-file=vault.ca=vault-ca.crt \
  --namespace vault

cd ..

# 8.1.4 Vault kurulumu
helm install vault hashicorp/vault \
  --namespace vault \
  --values vault-values.yaml

# 8.1.5 Vault'u initialize et ve unseal et
kubectl exec vault-0 -n vault -- vault operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json > cluster-keys.json

# Root token ve unseal key'leri çıkar
VAULT_UNSEAL_KEY_1=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[0]")
VAULT_UNSEAL_KEY_2=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[1]")
VAULT_UNSEAL_KEY_3=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[2]")
CLUSTER_ROOT_TOKEN=$(cat cluster-keys.json | jq -r ".root_token")

# Vault unseal
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_1
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_2
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_3

# Diğer node'ları join et
kubectl exec vault-1 -n vault -- vault operator raft join https://vault-0.vault-internal:8200
kubectl exec vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_1
kubectl exec vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_2
kubectl exec vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_3

kubectl exec vault-2 -n vault -- vault operator raft join https://vault-0.vault-internal:8200
kubectl exec vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_1
kubectl exec vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_2
kubectl exec vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_3

echo "Root Token: $CLUSTER_ROOT_TOKEN"
```

### 🔧 **8.2 External Secrets Operator**

```bash
# 8.2.1 External Secrets Operator kurulumu
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace

# 8.2.2 Vault'ta Kubernetes auth method aktifleştir
kubectl exec vault-0 -n vault -- env VAULT_TOKEN=$CLUSTER_ROOT_TOKEN vault auth enable kubernetes

# Service account token path'ini al
TOKEN_REVIEW_JWT=$(kubectl get secret \
  $(kubectl get serviceaccount vault -n vault -o jsonpath='{.secrets[0].name}') \
  -n vault -o jsonpath='{.data.token}' | base64 --decode)

KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode)

KUBE_HOST=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.server}')

# Kubernetes auth method konfigüre et
kubectl exec vault-0 -n vault -- env VAULT_TOKEN=$CLUSTER_ROOT_TOKEN vault write auth/kubernetes/config \
  token_reviewer_jwt="$TOKEN_REVIEW_JWT" \
  kubernetes_host="$KUBE_HOST" \
  kubernetes_ca_cert="$KUBE_CA_CERT"

# 8.2.3 Vault policy ve role oluştur
kubectl exec vault-0 -n vault -- env VAULT_TOKEN=$CLUSTER_ROOT_TOKEN vault policy write mycompany-dev - <<EOF
path "secret/data/dev/*" {
  capabilities = ["read"]
}
EOF

kubectl exec vault-0 -n vault -- env VAULT_TOKEN=$CLUSTER_ROOT_TOKEN vault write auth/kubernetes/role/mycompany-dev \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=dev \
  policies=mycompany-dev \
  ttl=24h

# 8.2.4 Vault'ta secret engine aktifleştir
kubectl exec vault-0 -n vault -- env VAULT_TOKEN=$CLUSTER_ROOT_TOKEN vault secrets enable -path=secret kv-v2

# Test secrets ekle
kubectl exec vault-0 -n vault -- env VAULT_TOKEN=$CLUSTER_ROOT_TOKEN vault kv put secret/dev/database \
  username=myapp \
  password=SuperSecretPassword123!

kubectl exec vault-0 -n vault -- env VAULT_TOKEN=$CLUSTER_ROOT_TOKEN vault kv put secret/dev/api-keys \
  github-token=ghp_xxxxxxxxxxxx \
  slack-webhook=https://hooks.slack.com/services/xxx

# 8.2.5 SecretStore oluştur
cat > vault-secret-store.yaml << 'EOF'
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: dev
spec:
  provider:
    vault:
      server: "https://vault.vault.svc.cluster.local:8200"
      path: "secret"
      version: "v2"
      caBundle: "LS0tLS1CRUdJTi..."  # Base64 encoded CA cert
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "mycompany-dev"
          serviceAccountRef:
            name: "external-secrets"
EOF

# CA cert'i base64 encode et
CA_BUNDLE=$(cat vault-tls/vault-ca.crt | base64 -w 0)
sed -i "s/LS0tLS1CRUdJTi.../$CA_BUNDLE/g" vault-secret-store.yaml

kubectl apply -f vault-secret-store.yaml

# 8.2.6 ExternalSecret oluştur
cat > external-secret-database.yaml << 'EOF'
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: dev
spec:
  refreshInterval: 1m
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: database-secret
    creationPolicy: Owner
  data:
  - secretKey: username
    remoteRef:
      key: secret/dev/database
      property: username
  - secretKey: password
    remoteRef:
      key: secret/dev/database
      property: password
EOF

kubectl apply -f external-secret-database.yaml

# Secret'in oluştuğunu kontrol et
kubectl get secrets -n dev
kubectl describe externalsecret database-credentials -n dev
```

### 🛡️ **8.3 Pod Security Standards**

```bash
# 8.3.1 Pod Security Standards uygula
kubectl label --overwrite namespace dev pod-security.kubernetes.io/enforce=restricted
kubectl label --overwrite namespace dev pod-security.kubernetes.io/audit=restricted
kubectl label --overwrite namespace dev pod-security.kubernetes.io/warn=restricted

kubectl label --overwrite namespace staging pod-security.kubernetes.io/enforce=restricted
kubectl label --overwrite namespace staging pod-security.kubernetes.io/audit=restricted
kubectl label --overwrite namespace staging pod-security.kubernetes.io/warn=restricted

kubectl label --overwrite namespace production pod-security.kubernetes.io/enforce=restricted
kubectl label --overwrite namespace production pod-security.kubernetes.io/audit=restricted
kubectl label --overwrite namespace production pod-security.kubernetes.io/warn=restricted

# 8.3.2 Security context template
cat > security-context-template.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        runAsGroup: 10001
        fsGroup: 10001
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 8080
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 10001
          runAsGroup: 10001
          capabilities:
            drop:
            - ALL
            add:
            - NET_BIND_SERVICE
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: var-cache-nginx
          mountPath: /var/cache/nginx
        - name: var-run
          mountPath: /var/run
      volumes:
      - name: tmp
        emptyDir: {}
      - name: var-cache-nginx
        emptyDir: {}
      - name: var-run
        emptyDir: {}
EOF
```

### 🔍 **8.4 Falco Runtime Security**

```bash
# 8.4.1 Falco kurulumu
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

cat > falco-values.yaml << 'EOF'
falco:
  rules_file:
    - /etc/falco/falco_rules.yaml
    - /etc/falco/falco_rules.local.yaml
    - /etc/falco/k8s_audit_rules.yaml
    - /etc/falco/rules.d
  
  time_format_iso_8601: true
  json_output: true
  json_include_output_property: true
  json_include_tags_property: true
  
  log_stderr: true
  log_syslog: true
  log_level: info
  
  priority: debug
  
  buffered_outputs: false
  
  syscall_event_drops:
    actions:
      - log
      - alert
    rate: 0.03333
    max_burst: 1000

  outputs:
    rate: 1
    max_burst: 1000

  syslog_output:
    enabled: true

  file_output:
    enabled: false

  stdout_output:
    enabled: true

  webserver:
    enabled: true
    listen_port: 8765
    k8s_healthz_endpoint: /healthz
    ssl_enabled: false
    ssl_certificate: /etc/ssl/falco/falco.pem

  grpc:
    enabled: false

  grpc_output:
    enabled: false

customRules:
  custom-rules.yaml: |-
    - rule: Unexpected outbound connection destination
      desc: Detect outbound connections to unexpected destinations
      condition: >
        outbound and not
        (fd.sip in (internal_networks))
      output: Outbound connection to unexpected destination (command=%proc.cmdline dest=%fd.rip)
      priority: WARNING
      tags: [network, mitre_exfiltration]
    
    - rule: Suspicious process in container
      desc: Detect suspicious processes running in containers
      condition: >
        spawned_process and container and
        (proc.name in (nc, ncat, netcat, nmap, dig, nslookup, tcpdump))
      output: Suspicious process in container (command=%proc.cmdline container=%container.name)
      priority: WARNING
      tags: [process, container]

driver:
  enabled: true
  kind: ebpf

collectors:
  enabled: true
  docker:
    enabled: true
  containerd:
    enabled: true
  crio:
    enabled: false

resources:
  requests:
    cpu: 100m
    memory: 512Mi
  limits:
    cpu: 200m
    memory: 1024Mi

tolerations:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
  - effect: NoSchedule
    key: node-role.kubernetes.io/control-plane

falcosidekick:
  enabled: true
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
  
  config:
    slack:
      webhookurl: "YOUR_SLACK_WEBHOOK_URL"
      channel: "#security-alerts"
      username: "Falco"
      minimumpriority: "warning"
      messageformat: "long"
    
    alertmanager:
      hostport: "http://kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local:9093"
      minimumpriority: "warning"
EOF

kubectl create namespace falco
helm install falco falcosecurity/falco \
  --namespace falco \
  --values falco-values.yaml

# 8.4.2 Falco durumunu kontrol et
kubectl get pods -n falco
kubectl logs -l app.kubernetes.io/name=falco -n falco
```

---

## 🗄️ **PHASE 8: BACKUP & DISASTER RECOVERY** (Gün 19-20)

### 💾 **9.1 Velero Backup Setup**

```bash
# 9.1.1 AWS S3 bucket oluştur
BACKUP_BUCKET="mycompany-k8s-backups-$(openssl rand -hex 4)"
aws s3 mb s3://$BACKUP_BUCKET --region eu-west-1

# S3 bucket policy
cat > backup-bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VeleroBackupAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/velero-role"
            },
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": "arn:aws:s3:::$BACKUP_BUCKET/*"
        },
        {
            "Sid": "VeleroBackupList",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/velero-role"
            },
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::$BACKUP_BUCKET"
        }
    ]
}
EOF

# IAM policy için Velero permissions
cat > velero-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:aws:s3:::BUCKET-NAME/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::BUCKET-NAME"
            ]
        }
    ]
}
EOF

sed -i "s/BUCKET-NAME/$BACKUP_BUCKET/g" velero-policy.json

# IAM policy oluştur
aws iam create-policy \
    --policy-name VeleroBackupPolicy \
    --policy-document file://velero-policy.json

# Service account için trust policy
cat > velero-trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::ACCOUNT-ID:oidc-provider/OIDC-URL"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "OIDC-URL:sub": "system:serviceaccount:velero:velero",
                    "OIDC-URL:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
EOF

# OIDC provider URL'ini al
OIDC_URL=$(aws eks describe-cluster --name mycompany-dev-eks --query "cluster.identity.oidc.issuer" --output text | sed 's|https://||')
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

sed -i "s/ACCOUNT-ID/$ACCOUNT_ID/g" velero-trust-policy.json
sed -i "s/OIDC-URL/$OIDC_URL/g" velero-trust-policy.json

# IAM role oluştur
aws iam create-role \
    --role-name velero-role \
    --assume-role-policy-document file://velero-trust-policy.json

# Policy'yi role'e attach et
aws iam attach-role-policy \
    --role-arn arn:aws:iam::$ACCOUNT_ID:role/velero-role \
    --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/VeleroBackupPolicy

# 9.1.2 Velero CLI kurulumu
wget https://github.com/vmware-tanzu/velero/releases/download/v1.12.0/velero-v1.12.0-linux-amd64.tar.gz
tar -xzf velero-v1.12.0-linux-amd64.tar.gz
sudo mv velero-v1.12.0-linux-amd64/velero /usr/local/bin/
rm -rf velero-v1.12.0-linux-amd64*

# 9.1.3 Velero kurulumu
cat > velero-values.yaml << EOF
configuration:
  backupStorageLocation:
  - name: aws
    provider: aws
    bucket: $BACKUP_BUCKET
    config:
      region: eu-west-1
  volumeSnapshotLocation:
  - name: aws
    provider: aws
    config:
      region: eu-west-1

credentials:
  useSecret: false

serviceAccount:
  server:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::$ACCOUNT_ID:role/velero-role

initContainers:
- name: velero-plugin-for-aws
  image: velero/velero-plugin-for-aws:v1.8.0
  volumeMounts:
  - mountPath: /target
    name: plugins

resources:
  requests:
    cpu: 500m
    memory: 128Mi
  limits:
    cpu: 1000m
    memory: 512Mi

nodeAgent:
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1024Mi

schedules:
  daily-backup:
    disabled: false
    schedule: "0 2 * * *"
    template:
      includedNamespaces:
      - dev
      - staging
      - production
      - monitoring
      - vault
      excludedResources:
      - events
      - events.events.k8s.io
      storageLocation: aws
      ttl: 720h0m0s
      snapshotVolumes: true

  weekly-backup:
    disabled: false
    schedule: "0 3 * * 0"
    template:
      includedNamespaces:
      - dev
      - staging
      - production
      - monitoring
      - vault
      excludedResources:
      - events
      - events.events.k8s.io
      storageLocation: aws
      ttl: 2160h0m0s
      snapshotVolumes: true
EOF

helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update

kubectl create namespace velero
helm install velero vmware-tanzu/velero \
  --namespace velero \
  --values velero-values.yaml

# 9.1.4 Manual backup test
velero backup create test-backup --include-namespaces dev
velero backup describe test-backup
velero backup logs test-backup

echo "Backup bucket: $BACKUP_BUCKET"
```

### 🔄 **9.2 Database Backup Strategy**

```bash
# 9.2.1 RDS automated backup script
cat > ~/devops-infrastructure/scripts/rds-backup.sh << 'EOF'
#!/bin/bash

# RDS Backup Script
set -e

DB_IDENTIFIER="mycompany-dev-db"
BACKUP_PREFIX="manual-backup"
REGION="eu-west-1"

# Create manual snapshot
SNAPSHOT_ID="${BACKUP_PREFIX}-$(date +%Y%m%d%H%M%S)"

echo "Creating RDS snapshot: $SNAPSHOT_ID"
aws rds create-db-snapshot \
    --db-instance-identifier $DB_IDENTIFIER \
    --db-snapshot-identifier $SNAPSHOT_ID \
    --region $REGION

# Wait for snapshot completion
echo "Waiting for snapshot completion..."
aws rds wait db-snapshot-completed \
    --db-snapshot-identifier $SNAPSHOT_ID \
    --region $REGION

echo "Snapshot created successfully: $SNAPSHOT_ID"

# List recent snapshots
echo "Recent snapshots:"
aws rds describe-db-snapshots \
    --db-instance-identifier $DB_IDENTIFIER \
    --snapshot-type manual \
    --region $REGION \
    --query 'DBSnapshots[0:5].[DBSnapshotIdentifier,Status,SnapshotCreateTime]' \
    --output table

# Cleanup old manual snapshots (keep last 7)
OLD_SNAPSHOTS=$(aws rds describe-db-snapshots \
    --db-instance-identifier $DB_IDENTIFIER \
    --snapshot-type manual \
    --region $REGION \
    --query 'DBSnapshots[7:].DBSnapshotIdentifier' \
    --output text)

if [ ! -z "$OLD_SNAPSHOTS" ]; then
    echo "Cleaning up old snapshots..."
    for snapshot in $OLD_SNAPSHOTS; do
        echo "Deleting snapshot: $snapshot"
        aws rds delete-db-snapshot \
            --db-snapshot-identifier $snapshot \
            --region $REGION
    done
fi

echo "Backup completed successfully!"
EOF

chmod +x ~/devops-infrastructure/scripts/rds-backup.sh

# 9.2.2 PostgreSQL logical backup (for application data)
cat > ~/devops-infrastructure/scripts/postgres-logical-backup.sh << 'EOF'
#!/bin/bash

# PostgreSQL Logical Backup Script
set -e

# Configuration
DB_HOST="your-rds-endpoint"
DB_NAME="mycompanydb"
DB_USER="admin"
BACKUP_DIR="/tmp/pg-backups"
S3_BUCKET="mycompany-db-logical-backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Get password from Kubernetes secret
DB_PASSWORD=$(kubectl get secret database-secret -n dev -o jsonpath='{.data.password}' | base64 -d)

export PGPASSWORD=$DB_PASSWORD

# Create backup
echo "Creating logical backup..."
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME \
    --verbose \
    --no-password \
    --format=custom \
    --compress=9 \
    --file=$BACKUP_DIR/logical-backup-$DATE.dump

# Upload to S3
echo "Uploading to S3..."
aws s3 cp $BACKUP_DIR/logical-backup-$DATE.dump \
    s3://$S3_BUCKET/logical-backups/logical-backup-$DATE.dump

# Cleanup local file
rm $BACKUP_DIR/logical-backup-$DATE.dump

# Cleanup old S3 backups (keep last 30 days)
echo "Cleaning up old backups..."
aws s3 ls s3://$S3_BUCKET/logical-backups/ \
    --recursive \
    --query "Contents[?LastModified<='$(date -d '30 days ago' --iso-8601)'].Key" \
    --output text | \
    xargs -I {} aws s3 rm s3://$S3_BUCKET/{}

echo "Logical backup completed successfully!"
EOF

chmod +x ~/devops-infrastructure/scripts/postgres-logical-backup.sh

# 9.2.3 CronJob for automated database backups
cat > database-backup-cronjob.yaml << 'EOF'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-logical-backup
  namespace: dev
spec:
  schedule: "0 1 * * *"  # Daily at 1 AM
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: backup-sa
          containers:
          - name: backup
            image: postgres:15-alpine
            env:
            - name: DB_HOST
              value: "your-rds-endpoint"
            - name: DB_NAME
              value: "mycompanydb"
            - name: DB_USER
              value: "admin"
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: database-secret
                  key: password
            - name: S3_BUCKET
              value: "mycompany-db-logical-backups"
            command:
            - /bin/bash
            - -c
            - |
              set -e
              apk add --no-cache aws-cli
              
              DATE=$(date +%Y%m%d_%H%M%S)
              BACKUP_FILE="/tmp/logical-backup-$DATE.dump"
              
              export PGPASSWORD=$DB_PASSWORD
              
              echo "Creating logical backup..."
              pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME \
                  --verbose \
                  --no-password \
                  --format=custom \
                  --compress=9 \
                  --file=$BACKUP_FILE
              
              echo "Uploading to S3..."
              aws s3 cp $BACKUP_FILE s3://$S3_BUCKET/logical-backups/
              
              echo "Backup completed successfully!"
            resources:
              requests:
                memory: "256Mi"
                cpu: "100m"
              limits:
                memory: "512Mi"
                cpu: "200m"
          restartPolicy: OnFailure
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backup-sa
  namespace: dev
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/backup-role
EOF

kubectl apply -f database-backup-cronjob.yaml
```

### 📋 **9.3 Disaster Recovery Runbook**

```bash
# 9.3.1 DR runbook oluştur
cat > ~/devops-infrastructure/docs/disaster-recovery-runbook.md << 'EOF'
# Disaster Recovery Runbook

## Overview
Bu doküman Kubernetes cluster ve RDS veritabanı için disaster recovery prosedürlerini içerir.

## RTO/RPO Targets
- **RTO (Recovery Time Objective)**: 4 saat
- **RPO (Recovery Point Objective)**: 1 saat

## Disaster Scenarios

### 1. Complete Cluster Loss

#### Assessment
```bash
# Cluster durumunu kontrol et
kubectl get nodes
kubectl get pods --all-namespaces

# AWS EKS cluster durumu
aws eks describe-cluster --name mycompany-dev-eks
```

#### Recovery Steps

1. **Yeni cluster oluştur**
```bash
cd ~/devops-infrastructure/terraform/environments/dev
terraform plan -target=module.eks
terraform apply -target=module.eks
```

2. **Velero restore**
```bash
# En son backup'ı listele
velero backup get

# Restore işlemi
velero restore create restore-$(date +%Y%m%d) \
    --from-backup daily-backup-YYYYMMDD
```

3. **Database connectivity kontrol**
```bash
kubectl get secrets database-secret -n dev
kubectl run test-db-connection --rm -i --tty \
    --image=postgres:15-alpine -- \
    psql -h RDS_ENDPOINT -U admin -d mycompanydb
```

### 2. Database Disaster

#### Assessment
```bash
# RDS status kontrol
aws rds describe-db-instances \
    --db-instance-identifier mycompany-dev-db

# Connection test
kubectl run db-test --rm -i --tty \
    --image=postgres:15-alpine -- \
    psql -h RDS_ENDPOINT -U admin -d mycompanydb -c "SELECT 1;"
```

#### Recovery Steps

1. **Point-in-time recovery**
```bash
# Son valid backup time'ı bul
aws rds describe-db-instances \
    --db-instance-identifier mycompany-dev-db \
    --query 'DBInstances[0].LatestRestorableTime'

# Point-in-time restore
aws rds restore-db-instance-to-point-in-time \
    --source-db-instance-identifier mycompany-dev-db \
    --target-db-instance-identifier mycompany-dev-db-recovered \
    --restore-time 2024-XX-XXTXX:XX:XX.000Z
```

2. **Manual snapshot restore**
```bash
# Available snapshots
aws rds describe-db-snapshots \
    --db-instance-identifier mycompany-dev-db

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier mycompany-dev-db-recovered \
    --db-snapshot-identifier manual-backup-YYYYMMDDHHMMSS
```

3. **Application reconnection**
```bash
# Update database endpoint in secrets
kubectl patch secret database-secret -n dev \
    --type='json' \
    -p='[{"op": "replace", "path": "/data/host", "value":"'$(echo NEW_RDS_ENDPOINT | base64 -w 0)'"}]'

# Restart applications
kubectl rollout restart deployment -n dev
```

### 3. Data Corruption

#### Assessment
```bash
# Check for data inconsistencies
kubectl exec -it deployment/backend -n dev -- \
    python manage.py check_data_integrity

# Check database logs
aws rds describe-db-log-files \
    --db-instance-identifier mycompany-dev-db
```

#### Recovery Steps

1. **Identify corruption scope**
```bash
# Analyze affected data
kubectl exec -it deployment/backend -n dev -- \
    python manage.py analyze_corruption
```

2. **Restore from logical backup**
```bash
# Download latest logical backup
aws s3 cp s3://mycompany-db-logical-backups/logical-backups/latest.dump /tmp/

# Restore specific tables
pg_restore -h RDS_ENDPOINT -U admin -d mycompanydb \
    --table=affected_table \
    --clean \
    /tmp/latest.dump
```

## Testing Procedures

### Monthly DR Drill
1. Create test restore in separate namespace
2. Verify data integrity
3. Test application functionality
4. Document lessons learned

### Quarterly Full DR Test
1. Complete environment recreation
2. Full data restore
3. End-to-end testing
4. Performance validation

## Emergency Contacts

- **DevOps Team**: +90-XXX-XXX-XXXX
- **Database Team**: +90-XXX-XXX-XXXX
- **On-call Engineer**: +90-XXX-XXX-XXXX

## Post-Incident Actions

1. **Root Cause Analysis**
   - Document incident timeline
   - Identify failure points
   - Implement preventive measures

2. **Update Procedures**
   - Update runbooks
   - Improve monitoring
   - Enhance alerting

3. **Team Communication**
   - Share lessons learned
   - Update training materials
   - Schedule review meeting
EOF

# 9.3.2 DR test script
cat > ~/devops-infrastructure/scripts/dr-test.sh << 'EOF'
#!/bin/bash

# Disaster Recovery Test Script
set -e

NAMESPACE="dr-test"
BACKUP_NAME="$1"

if [ -z "$BACKUP_NAME" ]; then
    echo "Usage: $0 <backup-name>"
    echo "Available backups:"
    velero backup get
    exit 1
fi

echo "Starting DR test with backup: $BACKUP_NAME"

# Create test namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Restore from backup to test namespace
velero restore create dr-test-$(date +%Y%m%d%H%M%S) \
    --from-backup $BACKUP_NAME \
    --namespace-mappings dev:$NAMESPACE,staging:$NAMESPACE

# Wait for restore completion
echo "Waiting for restore completion..."
sleep 60

# Check restored resources
echo "Checking restored resources..."
kubectl get all -n $NAMESPACE

# Test database connectivity
echo "Testing database connectivity..."
kubectl run db-test -n $NAMESPACE --rm -i --tty \
    --image=postgres:15-alpine -- \
    psql -h $(kubectl get secret database-secret -n $NAMESPACE -o jsonpath='{.data.host}' | base64 -d) \
    -U $(kubectl get secret database-secret -n $NAMESPACE -o jsonpath='{.data.username}' | base64 -d) \
    -d mycompanydb \
    -c "SELECT COUNT(*) FROM information_schema.tables;"

echo "DR test completed successfully!"
echo "Cleanup: kubectl delete namespace $NAMESPACE"
EOF

chmod +x ~/devops-infrastructure/scripts/dr-test.sh
```

---

## 🎯 **PHASE 9: GITOPS & DEPLOYMENT AUTOMATION** (Gün 21-22)

### 🔄 **10.1 ArgoCD Setup**

```bash
# 10.1.1 ArgoCD kurulumu
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 10.1.2 ArgoCD CLI kurulumu
wget https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# 10.1.3 ArgoCD initial password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD admin password: $ARGOCD_PASSWORD"

# 10.1.4 ArgoCD ingress
cat > argocd-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - argocd.yourdomain.com
    secretName: argocd-tls
  rules:
  - host: argocd.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
EOF

kubectl apply -f argocd-ingress.yaml

# 10.1.5 ArgoCD server configuration
kubectl patch configmap argocd-cmd-params-cm -n argocd --patch '{"data":{"server.insecure":"true"}}'
kubectl rollout restart deployment argocd-server -n argocd

# 10.1.6 ArgoCD login
argocd login argocd.yourdomain.com --username admin --password $ARGOCD_PASSWORD --insecure
```

### 📁 **10.2 GitOps Repository Structure**

```bash
# 10.2.1 GitOps repository oluştur
cd ~/
git clone https://github.com/yourusername/gitops-config.git
cd gitops-config

# Repository structure
mkdir -p {applications/{dev,staging,production},infrastructure/{monitoring,logging,security},bootstrap}

# 10.2.2 Application of Applications pattern
cat > bootstrap/root-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/gitops-config.git
    targetRevision: main
    path: bootstrap
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# 10.2.3 Infrastructure applications
cat > bootstrap/infrastructure-apps.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring-stack
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/gitops-config.git
    targetRevision: main
    path: infrastructure/monitoring
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: logging-stack
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/gitops-config.git
    targetRevision: main
    path: infrastructure/logging
  destination:
    server: https://kubernetes.default.svc
    namespace: logging
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: security-stack
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/gitops-config.git
    targetRevision: main
    path: infrastructure/security
  destination:
    server: https://kubernetes.default.svc
    namespace: security
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# 10.2.4 Environment-specific applications
cat > bootstrap/dev-apps.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dev-applications
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/gitops-config.git
    targetRevision: main
    path: applications/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# 10.2.5 Sample application manifest
cat > applications/dev/sample-app.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: dev
  labels:
    app: sample-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        runAsGroup: 10001
        fsGroup: 10001
      containers:
      - name: app
        image: ghcr.io/yourusername/sample-app:v1.0.0
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: url
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 10001
          runAsGroup: 10001
          capabilities:
            drop:
            - ALL
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: tmp
          mountPath: /tmp
      volumes:
      - name: tmp
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app
  namespace: dev
  labels:
    app: sample-app
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 8080
    name: http
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sample-app
  namespace: dev
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - app-dev.yourdomain.com
    secretName: sample-app-tls
  rules:
  - host: app-dev.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: sample-app
            port:
              number: 80
EOF

# Git'e commit
git add .
git commit -m "Initial GitOps repository structure"
git push origin main
```

### 🚀 **10.3 Progressive Delivery with Argo Rollouts**

```bash
# 10.3.1 Argo Rollouts kurulumu
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# 10.3.2 Argo Rollouts CLI
wget https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
sudo install -m 555 kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
rm kubectl-argo-rollouts-linux-amd64

# 10.3.3 Canary deployment example
cat > applications/dev/sample-app-rollout.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: sample-app-rollout
  namespace: dev
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {}
      - setWeight: 40
      - pause: {duration: 10}
      - setWeight: 60
      - pause: {duration: 10}
      - setWeight: 80
      - pause: {duration: 10}
      canaryService: sample-app-canary
      stableService: sample-app-stable
      trafficRouting:
        nginx:
          stableIngress: sample-app-stable
          annotationPrefix: nginx.ingress.kubernetes.io
          additionalIngressAnnotations:
            canary-by-header: X-Canary
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 2
        args:
        - name: service-name
          value: sample-app-canary.dev.svc.cluster.local
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: app
        image: ghcr.io/yourusername/sample-app:v1.0.0
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: url
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app-stable
  namespace: dev
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 8080
    name: http
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app-canary
  namespace: dev
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 8080
    name: http
---
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
  namespace: dev
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 30s
    successCondition: result[0] >= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090
        query: |
          sum(irate(
            http_requests_total{job="{{args.service-name}}",status!~"5.*"}[5m]
          )) /
          sum(irate(
            http_requests_total{job="{{args.service-name}}"}[5m]
          ))
EOF

# 10.3.4 Blue-Green deployment example
cat > applications/staging/sample-app-bluegreen.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: sample-app-bluegreen
  namespace: staging
spec:
  replicas: 3
  strategy:
    blueGreen:
      activeService: sample-app-active
      previewService: sample-app-preview
      autoPromotionEnabled: false
      scaleDownDelaySeconds: 30
      prePromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: sample-app-preview.staging.svc.cluster.local
      postPromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: sample-app-active.staging.svc.cluster.local
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: app
        image: ghcr.io/yourusername/sample-app:v1.0.0
        ports:
        - containerPort: 8080
          name: http
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app-active
  namespace: staging
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 8080
    name: http
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app-preview
  namespace: staging
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 8080
    name: http
EOF

# Changes'ları commit et
git add .
git commit -m "Add progressive delivery configurations"
git push origin main
```

### 🔧 **10.4 CI/CD Integration with GitOps**

```bash
# 10.4.1 Image updater için ArgoCD configuration
cat > argocd-image-updater.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-image-updater-config
  namespace: argocd
data:
  registries.conf: |
    registries:
    - name: GitHub Container Registry
      prefix: ghcr.io
      api_url: https://ghcr.io
      credentials: ext:/scripts/auth1.sh
      credsexpire: 10h
  ssh_config: |
    Host github.com
        User git
        IdentitiesOnly yes
        IdentityFile ~/.ssh/id_rsa
        StrictHostKeyChecking no
---
apiVersion: v1
kind: Secret
metadata:
  name: argocd-image-updater-secret
  namespace: argocd
type: Opaque
stringData:
  auth1.sh: |
    #!/bin/sh
    echo "username:$GITHUB_TOKEN"
EOF

kubectl apply -f argocd-image-updater.yaml

# 10.4.2 Application annotation for image updates
cat > applications/dev/sample-app-with-image-updater.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-app
  namespace: argocd
  annotations:
    argocd-image-updater.argoproj.io/image-list: myapp=ghcr.io/yourusername/sample-app
    argocd-image-updater.argoproj.io/write-back-method: git
    argocd-image-updater.argoproj.io/git-branch: main
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/gitops-config.git
    targetRevision: main
    path: applications/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# 10.4.3 Updated Jenkins pipeline with GitOps
cat > ~/devops-infrastructure/jenkins/gitops-pipeline.groovy << 'EOF'
@Library('shared-library') _

pipeline {
    agent {
        kubernetes {
            yaml """
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: docker
                image: docker:latest
                command:
                - cat
                tty: true
                volumeMounts:
                - mountPath: /var/run/docker.sock
                  name: docker-sock
              - name: git
                image: alpine/git:latest
                command:
                - cat
                tty: true
              volumes:
              - name: docker-sock
                hostPath:
                  path: /var/run/docker.sock
            """
        }
    }
    
    environment {
        DOCKER_REGISTRY = 'ghcr.io'
        IMAGE_NAME = 'yourusername/sample-app'
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
        BUILD_VERSION = "v1.0.${env.BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
        GITOPS_REPO = 'https://github.com/yourusername/gitops-config.git'
    }
    
    stages {
        stage('Build & Push') {
            steps {
                container('docker') {
                    script {
                        def image = docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION}")
                        docker.withRegistry("https://${DOCKER_REGISTRY}", 'github-registry-credentials') {
                            image.push()
                            image.push("latest")
                        }
                    }
                }
            }
        }
        
        stage('Update GitOps Repo') {
            steps {
                container('git') {
                    withCredentials([usernamePassword(credentialsId: 'github-credentials', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_TOKEN')]) {
                        sh '''
                            git config --global user.email "jenkins@company.com"
                            git config --global user.name "Jenkins CI"
                            
                            # Clone GitOps repository
                            git clone https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/yourusername/gitops-config.git
                            cd gitops-config
                            
                            # Update image tag in deployment manifest
                            sed -i "s|image: ${DOCKER_REGISTRY}/${IMAGE_NAME}:.*|image: ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION}|g" applications/dev/sample-app.yaml
                            
                            # Commit and push changes
                            git add .
                            git commit -m "Update ${IMAGE_NAME} to ${BUILD_VERSION}"
                            git push origin main
                        '''
                    }
                }
            }
        }
    }
    
    post {
        success {
            slackSend(
                channel: '#deployments',
                color: 'good',
                message: "✅ ${IMAGE_NAME}:${BUILD_VERSION} built and GitOps updated successfully"
            )
        }
        failure {
            slackSend(
                channel: '#deployments',
                color: 'danger',
                message: "❌ Pipeline failed for ${IMAGE_NAME}:${BUILD_VERSION}"
            )
        }
    }
}
EOF

# 10.4.4 ArgoCD'ye root application'ı deploy et
kubectl apply -f ~/gitops-config/bootstrap/root-app.yaml

echo "GitOps setup completed!"
echo "ArgoCD UI: https://argocd.yourdomain.com"
echo "Login: admin / $ARGOCD_PASSWORD"
```

---

## 📈 **PHASE 10: COST OPTIMIZATION & PERFORMANCE** (Gün 23-24)

### 💰 **11.1 Cost Monitoring Setup**

```bash
# 11.1.1 AWS Cost and Usage Report setup
cat > ~/devops-infrastructure/scripts/setup-cost-monitoring.sh << 'EOF'
#!/bin/bash

# AWS Cost Monitoring Setup Script
set -e

BUCKET_NAME="mycompany-cost-reports-$(openssl rand -hex 4)"
REGION="eu-west-1"

# Create S3 bucket for cost reports
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Bucket policy for AWS Cost and Usage Reports
cat > cost-bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "billingreports.amazonaws.com"
            },
            "Action": [
                "s3:GetBucketAcl",
                "s3:GetBucketPolicy"
            ],
            "Resource": "arn:aws:s3:::$BUCKET_NAME"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "billingreports.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://cost-bucket-policy.json

echo "Cost monitoring S3 bucket created: $BUCKET_NAME"
echo "Configure Cost and Usage Report in AWS Console:"
echo "https://console.aws.amazon.com/billing/home#/reports"
rm cost-bucket-policy.json
EOF

chmod +x ~/devops-infrastructure/scripts/setup-cost-monitoring.sh
./~/devops-infrastructure/scripts/setup-cost-monitoring.sh

# 11.1.2 Kubecost kurulumu
helm repo add kubecost https://kubecost.github.io/cost-analyzer/
helm repo update

cat > kubecost-values.yaml << 'EOF'
global:
  prometheus:
    fqdn: http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090
    enabled: false
  grafana:
    fqdn: http://kube-prometheus-stack-grafana.monitoring.svc.cluster.local:80
    enabled: false

kubecostFrontend:
  image: "kubecost/frontend"
  resources:
    requests:
      cpu: "10m"
      memory: "55Mi"
    limits:
      cpu: "100m"
      memory: "256Mi"

kubecost:
  image: "kubecost/server"
  resources:
    requests:
      cpu: "100m"
      memory: "55Mi"
    limits:
      cpu: "200m"
      memory: "256Mi"

kubecostModel:
  image: "kubecost/cost-model"
  resources:
    requests:
      cpu: "200m"
      memory: "55Mi"
    limits:
      cpu: "800m"
      memory: "256Mi"

ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: kubecost.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: kubecost-tls
      hosts:
        - kubecost.yourdomain.com

persistentVolume:
  enabled: true
  storageClass: gp3
  size: 32Gi

nodeSelector: {}
tolerations: []
affinity: {}

service:
  type: ClusterIP
  port: 9090
  targetPort: 9090
EOF

kubectl create namespace kubecost
helm install kubecost kubecost/cost-analyzer \
  --namespace kubecost \
  --values kubecost-values.yaml

# 11.1.3 Resource recommendation script
cat > ~/devops-infrastructure/scripts/resource-recommendations.sh << 'EOF'
#!/bin/bash

# Resource Recommendations Script
set -e

echo "📊 Generating resource recommendations..."

# VPA recommendations
echo "=== VPA Recommendations ==="
kubectl get vpa --all-namespaces -o custom-columns=\
NAMESPACE:.metadata.namespace,\
NAME:.metadata.name,\
MODE:.spec.updatePolicy.updateMode,\
CPU_TARGET:.status.recommendation.containerRecommendations[0].target.cpu,\
MEMORY_TARGET:.status.recommendation.containerRecommendations[0].target.memory

# Top resource consuming pods
echo "=== Top CPU Consuming Pods ==="
kubectl top pods --all-namespaces --sort-by=cpu | head -10

echo "=== Top Memory Consuming Pods ==="
kubectl top pods --all-namespaces --sort-by=memory | head -10

# Unused resources
echo "=== Pods with Low Resource Utilization ==="
kubectl get pods --all-namespaces -o json | \
jq -r '.items[] | select(.status.phase=="Running") | 
    .metadata.namespace + "/" + .metadata.name + " - " + 
    (.spec.containers[0].resources.requests.cpu // "no-limit") + " CPU, " +
    (.spec.containers[0].resources.requests.memory // "no-limit") + " Memory"'

# HPA status
echo "=== HPA Status ==="
kubectl get hpa --all-namespaces

echo "📋 Recommendations:"
echo "1. Check VPA recommendations for right-sizing"
echo "2. Set resource requests/limits for pods without them"
echo "3. Consider HPA for variable workloads"
echo "4. Use VPA in recommendation mode first"
EOF

chmod +x ~/devops-infrastructure/scripts/resource-recommendations.sh
```

### ⚡ **11.2 Performance Optimization**

```bash
# 11.2.1 Vertical Pod Autoscaler setup
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler/
./hack/vpa-install.sh
cd ~/devops-infrastructure

# 11.2.2 VPA example configurations
cat > vpa-examples.yaml << 'EOF'
# VPA for sample app (recommendation mode)
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: sample-app-vpa
  namespace: dev
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sample-app
  updatePolicy:
    updateMode: "Off"  # Recommendation only
  resourcePolicy:
    containerPolicies:
    - containerName: app
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 1000m
        memory: 1Gi
      controlledResources: ["cpu", "memory"]
---
# VPA for monitoring stack (auto mode)
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
      name: kube-prometheus-stack-prometheus
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: prometheus
      minAllowed:
        cpu: 500m
        memory: 1Gi
      maxAllowed:
        cpu: 4000m
        memory: 8Gi
      controlledResources: ["cpu", "memory"]
EOF

kubectl apply -f vpa-examples.yaml

# 11.2.3 KEDA (Event-driven autoscaling) setup
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

helm install keda kedacore/keda \
  --namespace keda \
  --create-namespace

# 11.2.4 KEDA ScaledObject example (Redis queue)
cat > keda-redis-scaler.yaml << 'EOF'
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: redis-scaledobject
  namespace: dev
spec:
  scaleTargetRef:
    name: worker-deployment
  minReplicaCount: 1
  maxReplicaCount: 10
  triggers:
  - type: redis
    metadata:
      address: redis.dev.svc.cluster.local:6379
      listName: job_queue
      listLength: '5'
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: prometheus-scaledobject
  namespace: dev
spec:
  scaleTargetRef:
    name: sample-app
  minReplicaCount: 2
  maxReplicaCount: 20
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090
      metricName: http_requests_per_second
      threshold: '100'
      query: sum(rate(http_requests_total{job="sample-app"}[1m]))
EOF

kubectl apply -f keda-redis-scaler.yaml

# 11.2.5 Performance monitoring dashboard
cat > performance-monitoring.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: performance-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  performance-dashboard.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Application Performance Monitoring",
        "tags": ["performance", "apm"],
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Request Rate",
            "type": "graph",
            "targets": [
              {
                "expr": "sum(rate(http_requests_total[5m])) by (service)",
                "legendFormat": "{{service}}"
              }
            ]
          },
          {
            "id": 2,
            "title": "Response Time",
            "type": "graph",
            "targets": [
              {
                "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))",
                "legendFormat": "95th percentile - {{service}}"
              }
            ]
          },
          {
            "id": 3,
            "title": "Error Rate",
            "type": "graph",
            "targets": [
              {
                "expr": "sum(rate(http_requests_total{status=~'5..'}[5m])) by (service) / sum(rate(http_requests_total[5m])) by (service)",
                "legendFormat": "Error rate - {{service}}"
              }
            ]
          }
        ],
        "time": {
          "from": "now-1h",
          "to": "now"
        },
        "refresh": "30s"
      }
    }
EOF

kubectl apply -f performance-monitoring.yaml
```

### 🧪 **11.3 Load Testing & Performance Validation**

```bash
# 11.3.1 K6 load testing setup
cat > load-testing/k6-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: k6-scripts
  namespace: dev
data:
  load-test.js: |
    import http from 'k6/http';
    import { check, sleep } from 'k6';
    import { Rate } from 'k6/metrics';

    export let errorRate = new Rate('errors');

    export let options = {
      stages: [
        { duration: '2m', target: 10 }, // Ramp up
        { duration: '5m', target: 100 }, // Stay at 100 users
        { duration: '2m', target: 200 }, // Ramp up to 200 users
        { duration: '5m', target: 200 }, // Stay at 200 users
        { duration: '2m', target: 0 }, // Ramp down
      ],
      thresholds: {
        http_req_duration: ['p(95)<500'], // 95% of requests under 500ms
        http_req_failed: ['rate<0.05'], // Error rate under 5%
        errors: ['rate<0.1'], // Custom error rate under 10%
      },
    };

    export default function() {
      let response = http.get('https://app-dev.yourdomain.com/api/health');
      
      check(response, {
        'status is 200': (r) => r.status === 200,
        'response time < 500ms': (r) => r.timings.duration < 500,
      }) || errorRate.add(1);
      
      sleep(1);
    }

  stress-test.js: |
    import http from 'k6/http';
    import { check } from 'k6';

    export let options = {
      stages: [
        { duration: '1m', target: 50 },
        { duration: '1m', target: 100 },
        { duration: '1m', target: 200 },
        { duration: '1m', target: 500 },
        { duration: '2m', target: 1000 }, // Stress level
        { duration: '2m', target: 0 },
      ],
    };

    export default function() {
      let response = http.get('https://app-dev.yourdomain.com/api/users');
      check(response, {
        'status is 200': (r) => r.status === 200,
      });
    }
EOF

kubectl apply -f load-testing/

# 11.3.2 K6 operator kurulumu
kubectl apply -f https://github.com/grafana/k6-operator/releases/latest/download/bundle.yaml

# 11.3.3 Load test job
cat > load-test-job.yaml << 'EOF'
apiVersion: k6.io/v1alpha1
kind: K6
metadata:
  name: load-test
  namespace: dev
spec:
  parallelism: 4
  script:
    configMap:
      name: k6-scripts
      file: load-test.js
  separate: true
  runner:
    image: grafana/k6:latest
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 256Mi
    env:
    - name: K6_PROMETHEUS_RW_SERVER_URL
      value: http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090/api/v1/write
    - name: K6_PROMETHEUS_RW_TREND_AS_NATIVE_HISTOGRAM
      value: "true"
EOF

# Load test çalıştır
kubectl apply -f load-test-job.yaml
kubectl logs -f job/load-test-1 -n dev

# 11.3.4 Automated performance test pipeline
cat > ~/devops-infrastructure/jenkins/performance-test-pipeline.groovy << 'EOF'
pipeline {
    agent {
        kubernetes {
            yaml """
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: kubectl
                image: bitnami/kubectl:latest
                command:
                - cat
                tty: true
              - name: k6
                image: grafana/k6:latest
                command:
                - cat
                tty: true
            """
        }
    }
    
    parameters {
        choice(
            name: 'TEST_TYPE',
            choices: ['load-test', 'stress-test', 'spike-test'],
            description: 'Type of performance test to run'
        )
        string(
            name: 'TARGET_URL',
            defaultValue: 'https://app-staging.yourdomain.com',
            description: 'Target URL for testing'
        )
        string(
            name: 'DURATION',
            defaultValue: '5m',
            description: 'Test duration'
        )
    }
    
    stages {
        stage('Deploy Test Config') {
            steps {
                container('kubectl') {
                    sh '''
                        cat > k6-test-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: k6-test-config-${BUILD_NUMBER}
  namespace: dev
data:
  test.js: |
    import http from 'k6/http';
    import { check, sleep } from 'k6';
    
    export let options = {
      duration: '${DURATION}',
      vus: 50,
      thresholds: {
        http_req_duration: ['p(95)<1000'],
        http_req_failed: ['rate<0.05'],
      },
    };
    
    export default function() {
      let response = http.get('${TARGET_URL}/health');
      check(response, {
        'status is 200': (r) => r.status === 200,
      });
      sleep(1);
    }
EOF
                        kubectl apply -f k6-test-config.yaml
                    '''
                }
            }
        }
        
        stage('Run Performance Test') {
            steps {
                container('kubectl') {
                    sh '''
                        cat > k6-job.yaml << EOF
apiVersion: k6.io/v1alpha1
kind: K6
metadata:
  name: perf-test-${BUILD_NUMBER}
  namespace: dev
spec:
  parallelism: 2
  script:
    configMap:
      name: k6-test-config-${BUILD_NUMBER}
      file: test.js
  separate: true
EOF
                        kubectl apply -f k6-job.yaml
                        
                        # Wait for test completion
                        kubectl wait --for=condition=complete job/perf-test-${BUILD_NUMBER}-1 -n dev --timeout=600s
                        
                        # Get test results
                        kubectl logs job/perf-test-${BUILD_NUMBER}-1 -n dev
                    '''
                }
            }
        }
        
        stage('Analyze Results') {
            steps {
                container('kubectl') {
                    sh '''
                        # Extract test metrics and validate against thresholds
                        TEST_RESULTS=$(kubectl logs job/perf-test-${BUILD_NUMBER}-1 -n dev | grep -E "(http_req_duration|http_req_failed)")
                        echo "Test Results: $TEST_RESULTS"
                        
                        # Check if test passed thresholds
                        if kubectl logs job/perf-test-${BUILD_NUMBER}-1 -n dev | grep -q "✓"; then
                            echo "Performance test PASSED"
                        else
                            echo "Performance test FAILED"
                            exit 1
                        fi
                    '''
                }
            }
        }
    }
    
    post {
        always {
            container('kubectl') {
                sh '''
                    # Cleanup test resources
                    kubectl delete configmap k6-test-config-${BUILD_NUMBER} -n dev || true
                    kubectl delete k6 perf-test-${BUILD_NUMBER} -n dev || true
                '''
            }
        }
        success {
            slackSend(
                channel: '#performance',
                color: 'good',
                message: "✅ Performance test passed for ${params.TARGET_URL}"
            )
        }
        failure {
            slackSend(
                channel: '#performance',
                color: 'danger',
                message: "❌ Performance test failed for ${params.TARGET_URL}"
            )
        }
    }
}
EOF
```

### 📊 **11.4 Cost Optimization Scripts**

```bash
# 11.4.1 Resource rightsizing script
cat > ~/devops-infrastructure/scripts/cost-optimization.sh << 'EOF'
#!/bin/bash

# Cost Optimization Analysis Script
set -e

echo "💰 AWS Cost Optimization Analysis"
echo "=================================="

# 1. Unused EBS volumes
echo "🔍 Checking for unused EBS volumes..."
aws ec2 describe-volumes \
    --filters Name=status,Values=available \
    --query 'Volumes[*].[VolumeId,Size,VolumeType,CreateTime]' \
    --output table

# 2. Unattached Elastic IPs
echo "🔍 Checking for unattached Elastic IPs..."
aws ec2 describe-addresses \
    --query 'Addresses[?AssociationId==null].[PublicIp,AllocationId]' \
    --output table

# 3. Old snapshots (older than 30 days)
echo "🔍 Checking for old snapshots..."
CUTOFF_DATE=$(date -d '30 days ago' --iso-8601)
aws ec2 describe-snapshots \
    --owner-ids self \
    --query "Snapshots[?StartTime<='$CUTOFF_DATE'].[SnapshotId,StartTime,VolumeSize]" \
    --output table

# 4. Right-sizing recommendations
echo "🔍 Generating right-sizing recommendations..."
aws ce get-rightsizing-recommendation \
    --service "EC2-Instance" \
    --query 'RightsizingRecommendations[*].[CurrentInstance.InstanceName,CurrentInstance.InstanceType,RightsizingType,TargetInstances[0].EstimatedMonthlySavings.Amount]' \
    --output table

# 5. Reserved Instance recommendations
echo "🔍 Checking Reserved Instance opportunities..."
aws ce get-reservation-purchase-recommendation \
    --service "EC2-Instance" \
    --query 'Recommendations[*].[InstanceDetails.EC2InstanceDetails.InstanceType,InstanceDetails.EC2InstanceDetails.Region,RecommendationDetails.EstimatedMonthlySavingsAmount]' \
    --output table

echo "💡 Cost Optimization Recommendations:"
echo "1. Delete unused EBS volumes"
echo "2. Release unattached Elastic IPs"
echo "3. Delete old snapshots"
echo "4. Implement right-sizing recommendations"
echo "5. Consider Reserved Instances for stable workloads"
EOF

chmod +x ~/devops-infrastructure/scripts/cost-optimization.sh

# 11.4.2 Spot instance integration
cat > spot-instances.yaml << 'EOF'
# Karpenter for spot instances
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: spot-provisioner
spec:
  # Requirements that constrain which nodes will be created
  requirements:
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["spot"]
    - key: kubernetes.io/arch
      operator: In
      values: ["amd64"]
    - key: node.kubernetes.io/instance-type
      operator: In
      values: ["t3.medium", "t3.large", "m5.large", "m5.xlarge"]
  
  # Provisioned nodes will have these taints
  taints:
    - key: spot
      value: "true"
      effect: NoSchedule
  
  # Resource limits constrain the total size of the cluster
  limits:
    resources:
      cpu: 1000
      memory: 1000Gi
  
  # Deprovisioning configuration
  ttlSecondsAfterEmpty: 30
  
  # Provider-specific configuration
  providerRef:
    name: spot-nodepool
---
apiVersion: karpenter.k8s.aws/v1alpha1
kind: AWSNodePool
metadata:
  name: spot-nodepool
spec:
  amiFamily: AL2
  subnetSelector:
    karpenter.sh/discovery: "mycompany-dev-eks"
  securityGroupSelector:
    karpenter.sh/discovery: "mycompany-dev-eks"
  instanceProfile: "KarpenterNodeInstanceProfile"
  
  # Spot instance configuration
  requirements:
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["spot"]
    - key: node.kubernetes.io/instance-type
      operator: In
      values: ["t3.medium", "t3.large", "m5.large"]
  
  userData: |
    #!/bin/bash
    /etc/eks/bootstrap.sh mycompany-dev-eks
    echo "spot=true" >> /etc/kubernetes/kubelet/kubelet-config.json
EOF

# 11.4.3 Resource quota ve limits
cat > resource-quotas.yaml << 'EOF'
# Development namespace quotas
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    persistentvolumeclaims: "10"
    pods: "20"
    services: "10"
    secrets: "20"
    configmaps: "20"
---
# Staging namespace quotas
apiVersion: v1
kind: ResourceQuota
metadata:
  name: staging-quota
  namespace: staging
spec:
  hard:
    requests.cpu: "8"
    requests.memory: 16Gi
    limits.cpu: "16"
    limits.memory: 32Gi
    persistentvolumeclaims: "15"
    pods: "30"
    services: "15"
---
# Production namespace quotas
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
  namespace: production
spec:
  hard:
    requests.cpu: "20"
    requests.memory: 40Gi
    limits.cpu: "40"
    limits.memory: 80Gi
    persistentvolumeclaims: "25"
    pods: "50"
    services: "25"
---
# Limit ranges for all namespaces
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: dev
spec:
  limits:
  - default:
      cpu: "200m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    type: Container
  - max:
      cpu: "2"
      memory: "4Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
    type: Container
EOF

kubectl apply -f resource-quotas.yaml
```

---

## 📚 **PHASE 11: DOCUMENTATION & TEAM PROCESSES** (Gün 25-26)

### 📖 **12.1 Comprehensive Documentation**

```bash
# 12.1.1 Architecture documentation
cat > ~/devops-infrastructure/docs/architecture-overview.md << 'EOF'
# DevOps Infrastructure Architecture

## Overview
Bu doküman şirketimizin Kubernetes-based DevOps altyapısının mimari yapısını detaylandırır.

## High-Level Architecture

```mermaid
graph TB
    Developer[Developer] --> GitHub[GitHub Repository]
    GitHub --> Jenkins[Jenkins CI/CD]
    Jenkins --> Registry[GitHub Container Registry]
    Jenkins --> ArgoCD[ArgoCD GitOps]
    
    ArgoCD --> EKS[Amazon EKS]
    EKS --> Apps[Applications]
    
    subgraph "AWS Infrastructure"
        VPC[VPC]
        EKS --> VPC
        RDS[RDS PostgreSQL]
        ElastiCache[ElastiCache Redis]
        S3[S3 Buckets]
        ALB[Application Load Balancer]
    end
    
    subgraph "Monitoring Stack"
        Prometheus[Prometheus]
        Grafana[Grafana]
        AlertManager[AlertManager]
        Jaeger[Jaeger Tracing]
    end
    
    subgraph "Logging Stack"
        FluentBit[Fluent Bit]
        OpenSearch[OpenSearch]
        OpenSearchDashboards[OpenSearch Dashboards]
    end
    
    subgraph "Security"
        Vault[HashiCorp Vault]
        Falco[Falco Runtime Security]
        OPA[OPA Gatekeeper]
    end
    
    Apps --> Monitoring Stack
    Apps --> Logging Stack
    Apps --> Security
```

## Component Details

### Infrastructure Layer

#### AWS Services
- **VPC**: Multi-AZ setup with public/private subnets
- **EKS**: Managed Kubernetes cluster (v1.28)
- **RDS**: PostgreSQL with Multi-AZ and read replicas
- **ElastiCache**: Redis for caching and session storage
- **ALB**: Application Load Balancer with SSL termination
- **S3**: Object storage for backups, logs, and artifacts

#### Kubernetes Components
- **Namespaces**: dev, staging, production, monitoring, logging, security
- **RBAC**: Role-based access control for different teams
- **Network Policies**: Micro-segmentation with Calico
- **Pod Security Standards**: Enforced security contexts
- **Storage Classes**: GP3, IO1 for different performance needs

### Application Layer

#### Deployment Strategy
- **GitOps**: ArgoCD-based continuous deployment
- **Progressive Delivery**: Canary and Blue-Green deployments
- **Auto-scaling**: HPA, VPA, and KEDA for event-driven scaling
- **Service Mesh**: Istio for traffic management (optional)

#### Security
- **Secrets Management**: HashiCorp Vault with External Secrets Operator
- **Runtime Security**: Falco for threat detection
- **Policy Enforcement**: OPA Gatekeeper for admission control
- **Image Security**: Trivy scanning in CI/CD pipeline

### Observability

#### Monitoring
- **Metrics**: Prometheus with custom and pre-built dashboards
- **Visualization**: Grafana with role-based dashboards
- **Alerting**: AlertManager with Slack/PagerDuty integration
- **Distributed Tracing**: Jaeger for request tracing

#### Logging
- **Collection**: Fluent Bit daemonset
- **Storage**: OpenSearch cluster
- **Analysis**: OpenSearch Dashboards
- **Retention**: 30-day retention with automated cleanup

## Security Architecture

### Access Control
1. **AWS IAM**: Service accounts with IRSA
2. **Kubernetes RBAC**: Namespace-level permissions
3. **Vault**: Centralized secrets management
4. **Network Policies**: Pod-to-pod communication rules

### Security Scanning
1. **Container Images**: Trivy in CI/CD
2. **Infrastructure**: Checkov for Terraform
3. **Runtime**: Falco for anomaly detection
4. **Policy**: OPA for compliance enforcement

## Disaster Recovery

### Backup Strategy
- **Kubernetes**: Velero daily/weekly backups
- **Database**: RDS automated backups + manual snapshots
- **Storage**: EBS snapshots
- **Cross-region**: S3 replication for critical data

### Recovery Objectives
- **RTO**: 4 hours for complete infrastructure
- **RPO**: 1 hour for data loss
- **Testing**: Monthly DR drills

## Cost Optimization

### Strategies
1. **Resource Right-sizing**: VPA recommendations
2. **Spot Instances**: Karpenter for non-critical workloads
3. **Storage Optimization**: GP3 for better price/performance
4. **Reserved Instances**: For predictable workloads

### Monitoring
- **Kubecost**: Kubernetes cost visibility
- **AWS Cost Explorer**: Infrastructure cost analysis
- **Automated Cleanup**: Unused resources identification

## Performance Optimization

### Auto-scaling
- **HPA**: CPU/Memory-based pod scaling
- **VPA**: Resource recommendation and adjustment
- **KEDA**: Event-driven scaling (queue length, metrics)
- **Cluster Autoscaler**: Node-level scaling

### Load Testing
- **K6**: Automated performance testing
- **Chaos Engineering**: Failure injection testing
- **SLI/SLO**: Service level monitoring

## Operational Procedures

### Deployment Process
1. Developer pushes code to GitHub
2. Jenkins builds and tests application
3. Jenkins pushes image to GHCR
4. Jenkins updates GitOps repository
5. ArgoCD syncs changes to Kubernetes
6. Progressive delivery monitors health

### Incident Response
1. **Detection**: Automated alerting via AlertManager
2. **Notification**: Slack/PagerDuty escalation
3. **Response**: Runbook-driven remediation
4. **Recovery**: Automated rollback if needed
5. **Post-mortem**: Root cause analysis

## Team Responsibilities

### DevOps Team
- Infrastructure maintenance
- CI/CD pipeline management
- Security compliance
- Performance optimization

### Development Teams
- Application deployment
- Resource requirements definition
- Application monitoring setup
- Performance testing

### Operations Team
- Incident response
- Backup verification
- Capacity planning
- Change management
EOF

# 12.1.2 Operational runbooks
cat > ~/devops-infrastructure/docs/operational-runbooks.md << 'EOF'
# Operational Runbooks

## Incident Response Procedures

### High CPU Usage Alert

#### Symptoms
- AlertManager fires "High CPU Usage" alert
- Application response times increase
- Users report slowness

#### Investigation Steps
```bash
# 1. Check current CPU usage
kubectl top pods -n <namespace> --sort-by=cpu

# 2. Check HPA status
kubectl get hpa -n <namespace>

# 3. Check pod resource limits
kubectl describe pod <pod-name> -n <namespace>

# 4. Review metrics in Grafana
# Go to CPU Usage dashboard: https://grafana.yourdomain.com/d/cpu-usage
```

#### Resolution Steps
```bash
# 1. Immediate: Scale up manually if HPA not working
kubectl scale deployment <deployment-name> --replicas=<new-count> -n <namespace>

# 2. Check for resource limits
kubectl patch deployment <deployment-name> -n <namespace> --patch '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "<container-name>",
            "resources": {
              "limits": {
                "cpu": "1000m",
                "memory": "1Gi"
              }
            }
          }
        ]
      }
    }
  }
}'

# 3. Restart problematic pods
kubectl rollout restart deployment <deployment-name> -n <namespace>
```

#### Prevention
- Implement proper resource requests/limits
- Set up HPA with appropriate thresholds
- Regular load testing

### Database Connection Issues

#### Symptoms
- Applications cannot connect to database
- Connection timeout errors
- Database-related alerts

#### Investigation Steps
```bash
# 1. Check database connectivity from pod
kubectl run db-test --rm -i --tty --image=postgres:15-alpine -- \
  psql -h <db-host> -U <username> -d <database> -c "SELECT 1;"

# 2. Check database secret
kubectl get secret database-secret -n <namespace> -o yaml

# 3. Check RDS status
aws rds describe-db-instances --db-instance-identifier <db-identifier>

# 4. Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

#### Resolution Steps
```bash
# 1. Restart application pods
kubectl rollout restart deployment -n <namespace>

# 2. Check and update database credentials
kubectl patch secret database-secret -n <namespace> --patch '
{
  "data": {
    "password": "<base64-encoded-new-password>"
  }
}'

# 3. If RDS issue, check AWS console and restart if needed
aws rds reboot-db-instance --db-instance-identifier <db-identifier>
```

### Pod Stuck in Pending State

#### Investigation Steps
```bash
# 1. Describe the pod
kubectl describe pod <pod-name> -n <namespace>

# 2. Check node resources
kubectl describe nodes

# 3. Check PVC status if using persistent storage
kubectl get pvc -n <namespace>

# 4. Check for resource quotas
kubectl describe quota -n <namespace>
```

#### Resolution Steps
```bash
# 1. If insufficient resources, scale cluster
aws eks update-nodegroup-config \
  --cluster-name <cluster-name> \
  --nodegroup-name <nodegroup-name> \
  --scaling-config minSize=<min>,maxSize=<max>,desiredSize=<desired>

# 2. If PVC issue, check storage class
kubectl get storageclass

# 3. If quota exceeded, increase or clean up resources
kubectl delete deployment <unused-deployment> -n <namespace>
```

## Maintenance Procedures

### Kubernetes Cluster Upgrade

#### Pre-upgrade Checklist
- [ ] Backup cluster state with Velero
- [ ] Review breaking changes in new version
- [ ] Test upgrade in staging environment
- [ ] Notify team about maintenance window
- [ ] Prepare rollback plan

#### Upgrade Steps
```bash
# 1. Update control plane
aws eks update-cluster-version \
  --name <cluster-name> \
  --version <new-version>

# 2. Wait for update completion
aws eks wait cluster-active --name <cluster-name>

# 3. Update node groups
aws eks update-nodegroup-version \
  --cluster-name <cluster-name> \
  --nodegroup-name <nodegroup-name> \
  --version <new-version>

# 4. Update addons
aws eks update-addon \
  --cluster-name <cluster-name> \
  --addon-name vpc-cni \
  --addon-version <new-version>

# 5. Verify cluster health
kubectl get nodes
kubectl get pods --all-namespaces
```

### Database Maintenance

#### Monthly Tasks
```bash
# 1. Review database performance
aws rds describe-db-instances \
  --db-instance-identifier <db-identifier> \
  --query 'DBInstances[0].PerformanceInsights'

# 2. Cleanup old snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier <db-identifier> \
  --snapshot-type manual \
  --query 'DBSnapshots[30:].[DBSnapshotIdentifier]' \
  --output text | \
  xargs -I {} aws rds delete-db-snapshot --db-snapshot-identifier {}

# 3. Analyze slow queries
# Access RDS Performance Insights dashboard
```

### Certificate Renewal

#### Let's Encrypt Certificates
```bash
# 1. Check certificate expiry
kubectl get certificates -A

# 2. Force renewal if needed
kubectl annotate certificate <cert-name> -n <namespace> \
  cert-manager.io/issue-temporary-certificate="true"

# 3. Verify renewal
kubectl describe certificate <cert-name> -n <namespace>
```

## Monitoring and Alerting

### Key Metrics to Monitor

#### Infrastructure
- Node CPU/Memory usage > 80%
- Disk usage > 85%
- Network connectivity issues
- Pod restart frequency

#### Application
- Response time > 2s (95th percentile)
- Error rate > 5%
- Request rate anomalies
- Database connection pool exhaustion

#### Security
- Failed authentication attempts
- Privilege escalation attempts
- Unusual network traffic
- Policy violations

### Alert Escalation

#### Severity Levels
1. **P1 (Critical)**: Immediate response (5 min)
   - Production down
   - Data breach
   - Security incident

2. **P2 (High)**: 30 min response
   - Performance degradation
   - Service partially down
   - High error rates

3. **P3 (Medium)**: 2 hour response
   - Non-critical service issues
   - Capacity warnings
   - Configuration issues

4. **P4 (Low)**: Next business day
   - Informational alerts
   - Optimization opportunities
   - Compliance warnings

## Change Management

### Deployment Approval Process

#### Development Environment
- Automatic deployment on merge to `develop` branch
- No approval required
- Immediate rollback available

#### Staging Environment
- Automatic deployment on merge to `main` branch
- Automated testing required
- Manual approval for production promotion

#### Production Environment
- Manual approval required
- Deployment during maintenance window
- Canary deployment strategy
- Automated rollback on failure

### Emergency Change Process
1. Incident commander approval
2. Minimal viable fix
3. Fast-track testing
4. Immediate deployment
5. Post-incident review
EOF

# 12.1.3 Team onboarding guide
cat > ~/devops-infrastructure/docs/team-onboarding.md << 'EOF'
# Team Onboarding Guide

## Prerequisites

### Required Tools
1. **kubectl** - Kubernetes CLI
2. **helm** - Kubernetes package manager
3. **terraform** - Infrastructure as Code
4. **docker** - Container runtime
5. **aws-cli** - AWS command line interface
6. **argocd** - GitOps CLI
7. **git** - Version control

### Installation Script
```bash
# Run the automated setup script
curl -fsSL https://raw.githubusercontent.com/yourusername/devops-infrastructure/main/scripts/setup-dev-environment.sh | bash
```

## Access Setup

### 1. AWS Access
```bash
# Configure AWS CLI
aws configure
# Use provided access key and secret key

# Test access
aws sts get-caller-identity
```

### 2. Kubernetes Access
```bash
# Configure kubectl
aws eks update-kubeconfig --region eu-west-1 --name mycompany-dev-eks

# Test cluster access
kubectl get nodes
```

### 3. ArgoCD Access
```bash
# Login to ArgoCD
argocd login argocd.yourdomain.com

# List applications
argocd app list
```

### 4. Vault Access
```bash
# Set Vault address
export VAULT_ADDR="https://vault.yourdomain.com"

# Login with provided token
vault auth -method=userpass username=<your-username>
```

## Development Workflow

### 1. Application Development
```bash
# 1. Clone application repository
git clone https://github.com/yourusername/sample-app.git
cd sample-app

# 2. Create feature branch
git checkout -b feature/new-feature

# 3. Make changes and test locally
docker build -t sample-app:local .
docker run -p 8080:8080 sample-app:local

# 4. Commit and push
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature

# 5. Create pull request
# Pipeline will automatically build and deploy to dev environment
```

### 2. Infrastructure Changes
```bash
# 1. Clone infrastructure repository
git clone https://github.com/yourusername/devops-infrastructure.git
cd devops-infrastructure

# 2. Make changes to Terraform
cd terraform/environments/dev
terraform plan

# 3. Apply changes
terraform apply

# 4. Update GitOps repository if needed
cd ../../..
git clone https://github.com/yourusername/gitops-config.git
# Make necessary Kubernetes manifest changes
```

## Common Tasks

### Deploy New Application

#### 1. Create Kubernetes Manifests
```yaml
# applications/dev/new-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-app
  namespace: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: new-app
  template:
    metadata:
      labels:
        app: new-app
    spec:
      containers:
      - name: app
        image: ghcr.io/yourusername/new-app:v1.0.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
```

#### 2. Create Service and Ingress
```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: new-app
  namespace: dev
spec:
  selector:
    app: new-app
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: new-app
  namespace: dev
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: new-app-dev.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: new-app
            port:
              number: 80
```

### Debug Application Issues

#### 1. Check Pod Status
```bash
# List pods
kubectl get pods -n dev

# Describe problematic pod
kubectl describe pod <pod-name> -n dev

# Check logs
kubectl logs <pod-name> -n dev --tail=100
```

#### 2. Access Pod for Debugging
```bash
# Execute commands in pod
kubectl exec -it <pod-name> -n dev -- /bin/bash

# Port forward for local access
kubectl port-forward <pod-name> 8080:8080 -n dev
```

#### 3. Check Resource Usage
```bash
# Top pods by resource usage
kubectl top pods -n dev

# Check HPA status
kubectl get hpa -n dev
```

### Scale Applications

#### Manual Scaling
```bash
# Scale deployment
kubectl scale deployment <app-name> --replicas=5 -n dev

# Check scaling status
kubectl get deployment <app-name> -n dev
```

#### Configure Auto-scaling
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
  namespace: dev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app-name
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Monitoring and Troubleshooting

### Access Monitoring Tools

#### Grafana Dashboards
- **URL**: https://grafana.yourdomain.com
- **Default Dashboards**:
  - Kubernetes Cluster Overview
  - Application Performance
  - Infrastructure Metrics
  - Cost Analysis

#### Log Analysis
- **URL**: https://logs.yourdomain.com
- **Common Queries**:
  ```
  # Application logs
  kubernetes.namespace_name:"dev" AND kubernetes.labels.app:"sample-app"
  
  # Error logs
  level:"error" AND kubernetes.namespace_name:"dev"
  
  # Specific time range
  @timestamp:[now-1h TO now] AND kubernetes.pod_name:"pod-name"
  ```

#### Distributed Tracing
- **URL**: https://jaeger.yourdomain.com
- **Usage**: Search by service name, operation, or trace ID

### Performance Testing

#### Run Load Test
```bash
# Apply load test configuration
kubectl apply -f - <<EOF
apiVersion: k6.io/v1alpha1
kind: K6
metadata:
  name: load-test
  namespace: dev
spec:
  parallelism: 2
  script:
    configMap:
      name: k6-scripts
      file: load-test.js
EOF

# Monitor test progress
kubectl logs -f job/load-test-1 -n dev
```

## Security Best Practices

### Container Security
1. **Use minimal base images** (distroless, alpine)
2. **Run as non-root user**
3. **Set resource limits**
4. **Scan images for vulnerabilities**

### Kubernetes Security
1. **Use namespaces for isolation**
2. **Implement RBAC properly**
3. **Set Pod Security Standards**
4. **Use Network Policies**

### Secrets Management
```bash
# Create secret in Vault
vault kv put secret/dev/app-config \
  database_password="super-secret" \
  api_key="api-key-value"

# Create ExternalSecret to sync
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-config
  namespace: dev
spec:
  refreshInterval: 1m
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: app-config-secret
  data:
  - secretKey: database_password
    remoteRef:
      key: secret/dev/app-config
      property: database_password
EOF
```

## Getting Help

### Internal Resources
- **DevOps Team Slack**: #devops-team
- **Documentation**: https://docs.company.com/devops
- **Runbooks**: ~/devops-infrastructure/docs/
- **Architecture Diagrams**: ~/devops-infrastructure/docs/architecture/

### Emergency Contacts
- **On-call Engineer**: +90-XXX-XXX-XXXX
- **DevOps Team Lead**: +90-XXX-XXX-XXXX
- **Security Team**: security@company.com

### External Resources
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **AWS EKS Guide**: https://docs.aws.amazon.com/eks/
- **ArgoCD Documentation**: https://argo-cd.readthedocs.io/
- **Prometheus Documentation**: https://prometheus.io/docs/
EOF
```

### 📊 **12.2 Automated Reporting**

```bash
# 12.2.1 Infrastructure health report script
cat > ~/devops-infrastructure/scripts/health-report.sh << 'EOF'
#!/bin/bash

# Infrastructure Health Report Generator
set -e

REPORT_DATE=$(date +"%Y-%m-%d")
REPORT_FILE="/tmp/infrastructure-health-report-$REPORT_DATE.md"

cat > $REPORT_FILE << EOF
# Infrastructure Health Report - $REPORT_DATE

## Executive Summary
Generated at: $(date)
Report Period: Last 24 hours

## Cluster Health

### Node Status
\`\`\`
$(kubectl get nodes -o wide)
\`\`\`

### Resource Utilization
\`\`\`
$(kubectl top nodes)
\`\`\`

### Pod Status Summary
\`\`\`
$(kubectl get pods --all-namespaces | grep -E "(Running|Pending|Failed|Error)" | awk '{print $4}' | sort | uniq -c)
\`\`\`

## Application Health

### Deployment Status
\`\`\`
$(kubectl get deployments --all-namespaces)
\`\`\`

### Failed Pods (if any)
\`\`\`
$(kubectl get pods --all-namespaces --field-selector=status.phase=Failed)
\`\`\`

### HPA Status
\`\`\`
$(kubectl get hpa --all-namespaces)
\`\`\`

## Security Status

### Pod Security Policy Violations
\`\`\`
$(kubectl get events --all-namespaces | grep -i "security\|policy" | head -10)
\`\`\`

### Certificate Status
\`\`\`
$(kubectl get certificates --all-namespaces)
\`\`\`

## Cost Summary

### Resource Requests vs Limits
\`\`\`
$(kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.status.phase=="Running") | "\(.metadata.namespace)/\(.metadata.name): CPU Req: \(.spec.containers[0].resources.requests.cpu // "none"), Mem Req: \(.spec.containers[0].resources.requests.memory // "none")"')
\`\`\`

## Backup Status

### Velero Backup Status
\`\`\`
$(velero backup get | head -10)
\`\`\`

### Latest Backup Results
\`\`\`
$(velero backup describe $(velero backup get -o name | head -1 | cut -d'/' -f2) | grep -E "(Status|Started|Completed)")
\`\`\`

## Alerts Summary

### Active Alerts (Last 24h)
\`\`\`
$(curl -s "http://kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local:9093/api/v1/alerts" | jq -r '.data[] | select(.status.state=="firing") | "\(.labels.alertname): \(.labels.severity)"' | sort | uniq -c)
\`\`\`

## Performance Metrics

### Top Resource Consuming Pods
\`\`\`
$(kubectl top pods --all-namespaces --sort-by=cpu | head -10)
\`\`\`

## Recommendations

EOF

# Add recommendations based on findings
echo "### Current Issues" >> $REPORT_FILE

# Check for pods without resource limits
NO_LIMITS=$(kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.status.phase=="Running") | select(.spec.containers[0].resources.limits == null) | "\(.metadata.namespace)/\(.metadata.name)"' | wc -l)
if [ $NO_LIMITS -gt 0 ]; then
    echo "- $NO_LIMITS pods running without resource limits" >> $REPORT_FILE
fi

# Check for high CPU usage
HIGH_CPU_NODES=$(kubectl top nodes --no-headers | awk '$3 > 80 {count++} END {print count+0}')
if [ $HIGH_CPU_NODES -gt 0 ]; then
    echo "- $HIGH_CPU_NODES nodes with high CPU usage (>80%)" >> $REPORT_FILE
fi

# Check for failed pods
FAILED_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase=Failed --no-headers | wc -l)
if [ $FAILED_PODS -gt 0 ]; then
    echo "- $FAILED_PODS failed pods need investigation" >> $REPORT_FILE
fi

echo "" >> $REPORT_FILE
echo "### Optimization Opportunities" >> $REPORT_FILE
echo "- Review VPA recommendations for resource optimization" >> $REPORT_FILE
echo "- Consider implementing HPA for variable workloads" >> $REPORT_FILE
echo "- Evaluate spot instance usage for cost savings" >> $REPORT_FILE

echo "Report generated: $REPORT_FILE"

# Send to Slack if webhook configured
if [ ! -z "$SLACK_WEBHOOK_URL" ]; then
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"📊 Daily Infrastructure Health Report generated for $REPORT_DATE\"}" \
        $SLACK_WEBHOOK_URL
fi
EOF

chmod +x ~/devops-infrastructure/scripts/health-report.sh

# 12.2.2 Automated health report CronJob
cat > health-report-cronjob.yaml << 'EOF'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: infrastructure-health-report
  namespace: monitoring
spec:
  schedule: "0 8 * * *"  # Daily at 8 AM
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: health-reporter
          containers:
          - name: reporter
            image: bitnami/kubectl:latest
            command:
            - /bin/bash
            - -c
            - |
              # Install required tools
              apt-get update && apt-get install -y curl jq
              
              # Generate report
              /scripts/health-report.sh
              
              # Upload to S3 if configured
              if [ ! -z "$S3_BUCKET" ]; then
                  aws s3 cp /tmp/infrastructure-health-report-*.md s3://$S3_BUCKET/reports/
              fi
            env:
            - name: S3_BUCKET
              value: "mycompany-reports"
            - name: SLACK_WEBHOOK_URL
              valueFrom:
                secretKeyRef:
                  name: slack-webhook
                  key: url
            volumeMounts:
            - name: scripts
              mountPath: /scripts
            resources:
              requests:
                memory: "128Mi"
                cpu: "100m"
              limits:
                memory: "256Mi"
                cpu: "200m"
          volumes:
          - name: scripts
            configMap:
              name: health-report-scripts
              defaultMode: 0755
          restartPolicy: OnFailure
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: health-reporter
  namespace: monitoring
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/health-reporter-role
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: health-reporter
rules:
- apiGroups: [""]
  resources: ["nodes", "pods", "services", "events"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list"]
- apiGroups: ["autoscaling"]
  resources: ["horizontalpodautoscalers"]
  verbs: ["get", "list"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["nodes", "pods"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: health-reporter
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: health-reporter
subjects:
- kind: ServiceAccount
  name: health-reporter
  namespace: monitoring
EOF

# ConfigMap for scripts
kubectl create configmap health-report-scripts \
  --from-file=health-report.sh=~/devops-infrastructure/scripts/health-report.sh \
  -n monitoring

kubectl apply -f health-report-cronjob.yaml
```

### 🎓 **12.3 Training and Knowledge Transfer**

```bash
# 12.3.1 Training curriculum
cat > ~/devops-infrastructure/docs/training-curriculum.md << 'EOF'
# DevOps Team Training Curriculum

## Week 1: Fundamentals

### Day 1-2: Kubernetes Basics
- **Topics**: Pods, Services, Deployments, ConfigMaps, Secrets
- **Hands-on**: Deploy sample application
- **Assessment**: Create multi-tier application deployment

### Day 3-4: Infrastructure as Code
- **Topics**: Terraform basics, AWS resources, State management
- **Hands-on**: Create VPC and EKS cluster
- **Assessment**: Deploy complete infrastructure

### Day 5: CI/CD Fundamentals
- **Topics**: Jenkins, Pipeline as Code, Docker
- **Hands-on**: Create build pipeline
- **Assessment**: End-to-end deployment pipeline

## Week 2: Advanced Topics

### Day 1-2: GitOps and Progressive Delivery
- **Topics**: ArgoCD, Argo Rollouts, Canary deployments
- **Hands-on**: Setup GitOps workflow
- **Assessment**: Implement progressive delivery

### Day 3: Monitoring and Observability
- **Topics**: Prometheus, Grafana, Jaeger, Log analysis
- **Hands-on**: Create custom dashboards
- **Assessment**: End-to-end observability setup

### Day 4: Security Best Practices
- **Topics**: Vault, RBAC, Network Policies, Image scanning
- **Hands-on**: Implement security controls
- **Assessment**: Security audit and remediation

### Day 5: Troubleshooting and Operations
- **Topics**: Debugging techniques, Performance tuning, Incident response
- **Hands-on**: Simulate and resolve incidents
- **Assessment**: Handle real-world scenarios

## Ongoing Learning

### Monthly Topics
- **Month 1**: Cost optimization and resource management
- **Month 2**: Advanced networking and service mesh
- **Month 3**: Disaster recovery and backup strategies
- **Month 4**: Chaos engineering and reliability
- **Month 5**: Multi-cluster and multi-cloud strategies
- **Month 6**: Advanced security and compliance

### Certification Paths
1. **AWS Certified DevOps Engineer**
2. **Certified Kubernetes Administrator (CKA)**
3. **Certified Kubernetes Security Specialist (CKS)**
4. **HashiCorp Certified: Terraform Associate**

## Lab Exercises

### Exercise 1: Application Deployment
```bash
# Deploy sample application with monitoring
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: training-app
  namespace: training
spec:
  replicas: 3
  selector:
    matchLabels:
      app: training-app
  template:
    metadata:
      labels:
        app: training-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
EOF
```

### Exercise 2: Troubleshooting Scenarios
1. **Pod CrashLoopBackOff**
2. **Service discovery issues**
3. **Resource exhaustion**
4. **Network connectivity problems**
5. **Storage mounting failures**

### Exercise 3: Performance Testing
```bash
# Setup load testing
kubectl apply -f - <<EOF
apiVersion: k6.io/v1alpha1
kind: K6
metadata:
  name: training-load-test
  namespace: training
spec:
  parallelism: 2
  script:
    configMap:
      name: training-scripts
      file: basic-test.js
EOF
```

## Knowledge Check Questions

### Kubernetes
1. Explain the difference between Deployment and StatefulSet
2. How do you troubleshoot a pod stuck in Pending state?
3. What are the different types of Services in Kubernetes?
4. How do resource requests and limits work?

### Infrastructure
1. Explain Terraform state management
2. How do you handle secrets in infrastructure code?
3. What are the best practices for AWS resource tagging?
4. How do you implement blue-green deployments?

### Monitoring
1. What are the four golden signals of monitoring?
2. How do you set up custom metrics in Prometheus?
3. Explain the difference between metrics, logs, and traces
4. How do you create effective alerting rules?

### Security
1. What is the principle of least privilege?
2. How do you implement network segmentation in Kubernetes?
3. Explain the role of service accounts and RBAC
4. What are the security best practices for container images?

## Practical Assessments

### Assessment 1: Deploy Production-Ready Application
- Set up complete infrastructure with Terraform
- Deploy application with proper security context
- Implement monitoring and alerting
- Set up automated backups
- Document deployment process

### Assessment 2: Incident Response Simulation
- Scenario: Database connectivity issues
- Task: Diagnose and resolve the problem
- Evaluation: Time to resolution, troubleshooting approach
- Documentation: Post-incident report

### Assessment 3: Performance Optimization
- Given: Application with performance issues
- Task: Identify bottlenecks and optimize
- Tools: Use monitoring data and profiling
- Deliverable: Performance improvement plan

## Resources

### Documentation
- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)

### Training Platforms
- [A Cloud Guru](https://acloud.guru/)
- [Linux Academy](https://linuxacademy.com/)
- [Katacoda](https://katacoda.com/)
- [Play with Kubernetes](https://labs.play-with-k8s.com/)

### Books
- "Kubernetes in Action" by Marko Lukša
- "Terraform: Up & Running" by Yevgeniy Brikman
- "Site Reliability Engineering" by Google
- "The DevOps Handbook" by Gene Kim
EOF

# 12.3.2 Knowledge base setup
cat > ~/devops-infrastructure/scripts/setup-knowledge-base.sh << 'EOF'
#!/bin/bash

# Knowledge Base Setup Script
set -e

echo "📚 Setting up team knowledge base..."

# Create knowledge base structure
mkdir -p ~/devops-infrastructure/docs/{architecture,runbooks,tutorials,troubleshooting,best-practices}

# Architecture documentation
echo "Creating architecture documentation..."
cat > ~/devops-infrastructure/docs/architecture/README.md << 'ARCH_EOF'
# Architecture Documentation

## Overview
This directory contains all architecture-related documentation.

## Contents
- `system-overview.md` - High-level system architecture
- `data-flow.md` - Data flow diagrams and explanations
- `security-architecture.md` - Security design and controls
- `networking.md` - Network architecture and routing
- `disaster-recovery.md` - DR architecture and procedures

## Diagrams
All diagrams are created using Mermaid and can be viewed in GitHub or VS Code with the Mermaid extension.
ARCH_EOF

# Runbooks directory
echo "Creating runbooks..."
cat > ~/devops-infrastructure/docs/runbooks/README.md << 'RUN_EOF'
# Operational Runbooks

## Purpose
Step-by-step procedures for common operational tasks and incident response.

## Runbook Categories
- `incident-response/` - Emergency response procedures
- `maintenance/` - Scheduled maintenance procedures
- `deployment/` - Deployment and rollback procedures
- `monitoring/` - Monitoring and alerting procedures

## Runbook Template
Each runbook should include:
1. Purpose and scope
2. Prerequisites
3. Step-by-step procedures
4. Verification steps
5. Rollback procedures
6. Post-completion tasks
RUN_EOF

# Create searchable index
echo "Creating searchable documentation index..."
cat > ~/devops-infrastructure/scripts/generate-docs-index.sh << 'INDEX_EOF'
#!/bin/bash

# Generate searchable documentation index
echo "# Documentation Index" > ~/devops-infrastructure/docs/INDEX.md
echo "Generated on: $(date)" >> ~/devops-infrastructure/docs/INDEX.md
echo "" >> ~/devops-infrastructure/docs/INDEX.md

find ~/devops-infrastructure/docs -name "*.md" -not -name "INDEX.md" | while read file; do
    echo "## $(basename "$file" .md)" >> ~/devops-infrastructure/docs/INDEX.md
    echo "**Path:** $file" >> ~/devops-infrastructure/docs/INDEX.md
    echo "" >> ~/devops-infrastructure/docs/INDEX.md
    # Extract first paragraph as summary
    head -10 "$file" | grep -E "^[A-Za-z]" | head -1 >> ~/devops-infrastructure/docs/INDEX.md
    echo "" >> ~/devops-infrastructure/docs/INDEX.md
done

echo "Documentation index generated!"
INDEX_EOF

chmod +x ~/devops-infrastructure/scripts/generate-docs-index.sh

echo "✅ Knowledge base structure created!"
echo "Run ~/devops-infrastructure/scripts/generate-docs-index.sh to create searchable index"
EOF

chmod +x ~/devops-infrastructure/scripts/setup-knowledge-base.sh
./~/devops-infrastructure/scripts/setup-knowledge-base.sh
```

---

## 🎉 **FINAL SETUP AND VALIDATION** (Gün 27-28)

### ✅ **13.1 End-to-End Testing**

```bash
# 13.1.1 Complete system validation script
cat > ~/devops-infrastructure/scripts/system-validation.sh << 'EOF'
#!/bin/bash

# Complete System Validation Script
set -e

echo "🧪 Starting End-to-End System Validation..."
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SUCCESS_COUNT=0
TOTAL_TESTS=0

check_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "Testing $test_name... "
    
    if eval "$test_command" &>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        return 1
    fi
}

echo "🔧 Infrastructure Tests"
echo "----------------------"

# AWS connectivity
check_test "AWS CLI access" "aws sts get-caller-identity"

# Terraform state
check_test "Terraform state accessible" "terraform show -json > /dev/null" || true

# EKS cluster
check_test "EKS cluster connectivity" "kubectl get nodes"

# Core system pods
check_test "CoreDNS running" "kubectl get pods -n kube-system -l k8s-app=kube-dns | grep Running"
check_test "AWS Load Balancer Controller" "kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller | grep Running"

echo ""
echo "📊 Monitoring Stack Tests"
echo "-------------------------"

# Prometheus
check_test "Prometheus accessible" "kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus | grep Running"

# Grafana
check_test "Grafana accessible" "kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana | grep Running"

# AlertManager
check_test "AlertManager accessible" "kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager | grep Running"

echo ""
echo "📝 Logging Stack Tests"
echo "----------------------"

# Fluent Bit
check_test "Fluent Bit running" "kubectl get pods -n logging -l app.kubernetes.io/name=fluent-bit | grep Running"

# OpenSearch
check_test "OpenSearch cluster healthy" "kubectl get pods -n logging -l app=opensearch | grep Running"

echo ""
echo "🔒 Security Tests"
echo "----------------"

# Vault
check_test "Vault cluster running" "kubectl get pods -n vault -l app.kubernetes.io/name=vault | grep Running"

# External Secrets Operator
check_test "External Secrets Operator" "kubectl get pods -n external-secrets | grep Running"

# Falco
check_test "Falco security monitoring" "kubectl get pods -n falco -l app.kubernetes.io/name=falco | grep Running"

echo ""
echo "🔄 GitOps Tests"
echo "---------------"

# ArgoCD
check_test "ArgoCD server running" "kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server | grep Running"

# ArgoCD applications
check_test "ArgoCD applications synced" "argocd app list | grep -E 'Synced.*Healthy'"

echo ""
echo "💾 Backup Tests"
echo "---------------"

# Velero
check_test "Velero backup controller" "kubectl get pods -n velero -l app.kubernetes.io/name=velero | grep Running"

# Recent backup
check_test "Recent backup exists" "velero backup get | grep Completed | head -1"

echo ""
echo "🚀 Application Tests"
echo "--------------------"

# Sample application
check_test "Sample application running" "kubectl get pods -n dev -l app=sample-app | grep Running" || true

# Ingress connectivity
check_test "Ingress controller responsive" "kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx | grep Running"

echo ""
echo "📈 Performance Tests"
echo "-------------------"

# HPA
check_test "HPA controllers active" "kubectl get hpa --all-namespaces | grep -v TARGETS" || true

# VPA
check_test "VPA recommendations available" "kubectl get vpa --all-namespaces" || true

# Resource usage
check_test "Node resource usage healthy" "kubectl top nodes --no-headers | awk '\$3+0 < 90 && \$5+0 < 90' | wc -l | grep -v '^0-vpa
  namespace: monitoring
spec:
  targetRef:
    apiVersion: apps/v1
    kind: StatefulSet"

echo ""
echo "🌐 Network Tests"
echo "---------------"

# CoreDNS resolution
check_test "DNS resolution working" "kubectl exec -n kube-system deployments/coredns -- nslookup kubernetes.default.svc.cluster.local"

# Pod-to-pod communication
check_test "Inter-pod communication" "kubectl run network-test --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default" || true

echo ""
echo "🔐 Certificate Tests"
echo "-------------------"

# Cert-manager
check_test "Cert-manager running" "kubectl get pods -n cert-manager | grep Running"

# Certificate issuers
check_test "Certificate issuers ready" "kubectl get clusterissuers | grep True"

# Valid certificates
check_test "TLS certificates valid" "kubectl get certificates --all-namespaces | grep True" || true

echo ""
echo "📊 Cost Monitoring Tests"
echo "------------------------"

# Kubecost
check_test "Kubecost running" "kubectl get pods -n kubecost | grep Running" || true

echo ""
echo "🔍 Observability Tests"
echo "----------------------"

# Jaeger
check_test "Jaeger tracing available" "kubectl get pods -n observability -l app.kubernetes.io/name=jaeger | grep Running" || true

# OpenTelemetry
check_test "OpenTelemetry collector" "kubectl get pods -n observability -l app.kubernetes.io/name=opentelemetry-collector | grep Running" || true

echo ""
echo "================================================"
echo "🎯 VALIDATION SUMMARY"
echo "================================================"
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $SUCCESS_COUNT"
echo "Failed: $((TOTAL_TESTS - SUCCESS_COUNT))"

if [ $SUCCESS_COUNT -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! System is fully operational.${NC}"
    exit 0
elif [ $SUCCESS_COUNT -gt $((TOTAL_TESTS * 80 / 100)) ]; then
    echo -e "${YELLOW}⚠️  Most tests passed. Minor issues detected.${NC}"
    exit 0
else
    echo -e "${RED}❌ Critical issues detected. System requires attention.${NC}"
    exit 1
fi
EOF

chmod +x ~/devops-infrastructure/scripts/system-validation.sh

# 13.1.2 Automated testing pipeline
cat > ~/devops-infrastructure/jenkins/system-validation-pipeline.groovy << 'EOF'
pipeline {
    agent {
        kubernetes {
            yaml """
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: kubectl
                image: bitnami/kubectl:latest
                command:
                - cat
                tty: true
              - name: argocd
                image: argoproj/argocd:latest
                command:
                - cat
                tty: true
              - name: velero
                image: velero/velero:latest
                command:
                - cat
                tty: true
            """
        }
    }
    
    triggers {
        cron('0 6 * * *') // Daily at 6 AM
    }
    
    stages {
        stage('System Validation') {
            steps {
                container('kubectl') {
                    script {
                        sh '''
                            # Copy validation script
                            curl -fsSL https://raw.githubusercontent.com/yourusername/devops-infrastructure/main/scripts/system-validation.sh -o validation.sh
                            chmod +x validation.sh
                            
                            # Run validation
                            ./validation.sh
                        '''
                    }
                }
            }
        }
        
        stage('Generate Report') {
            steps {
                container('kubectl') {
                    sh '''
                        # Generate detailed report
                        echo "# System Health Report - $(date)" > system-report.md
                        echo "" >> system-report.md
                        
                        echo "## Cluster Overview" >> system-report.md
                        echo "\`\`\`" >> system-report.md
                        kubectl get nodes -o wide >> system-report.md
                        echo "\`\`\`" >> system-report.md
                        
                        echo "## Pod Status" >> system-report.md
                        echo "\`\`\`" >> system-report.md
                        kubectl get pods --all-namespaces | grep -v Running | head -20 >> system-report.md
                        echo "\`\`\`" >> system-report.md
                        
                        echo "## Resource Usage" >> system-report.md
                        echo "\`\`\`" >> system-report.md
                        kubectl top nodes >> system-report.md
                        echo "\`\`\`" >> system-report.md
                        
                        # Archive report
                        cat system-report.md
                    '''
                }
            }
        }
    }
    
    post {
        success {
            slackSend(
                channel: '#infrastructure',
                color: 'good',
                message: "✅ Daily system validation completed successfully"
            )
        }
        failure {
            slackSend(
                channel: '#infrastructure',
                color: 'danger',
                message: "❌ Daily system validation failed. Immediate attention required!"
            )
        }
        always {
            archiveArtifacts artifacts: '*.md', allowEmptyArchive: true
        }
    }
}
EOF

# 13.1.3 Çalıştır
~/devops-infrastructure/scripts/system-validation.sh
```

### 📚 **13.2 Final Documentation**

```bash
# 13.2.1 Complete setup summary
cat > ~/devops-infrastructure/README.md << 'EOF'
# DevOps Infrastructure - Complete Setup

🎉 **Congratulations!** You have successfully deployed a production-ready DevOps infrastructure.

## 🏗️ What We've Built

### Infrastructure Components
- ✅ **AWS EKS Cluster** - Managed Kubernetes with auto-scaling
- ✅ **VPC & Networking** - Multi-AZ setup with security groups
- ✅ **RDS PostgreSQL** - Managed database with backups
- ✅ **ElastiCache Redis** - In-memory caching
- ✅ **Application Load Balancer** - SSL termination and routing

### CI/CD Pipeline
- ✅ **Jenkins** - Automated build and deployment
- ✅ **ArgoCD** - GitOps continuous deployment
- ✅ **GitHub Container Registry** - Container image storage
- ✅ **Progressive Delivery** - Canary and blue-green deployments

### Monitoring & Observability
- ✅ **Prometheus** - Metrics collection and storage
- ✅ **Grafana** - Visualization and dashboards
- ✅ **AlertManager** - Intelligent alerting
- ✅ **Jaeger** - Distributed tracing
- ✅ **OpenSearch** - Log aggregation and search
- ✅ **Fluent Bit** - Log collection

### Security
- ✅ **HashiCorp Vault** - Secrets management
- ✅ **External Secrets Operator** - Kubernetes-Vault integration
- ✅ **Falco** - Runtime security monitoring
- ✅ **OPA Gatekeeper** - Policy enforcement
- ✅ **Network Policies** - Micro-segmentation
- ✅ **Pod Security Standards** - Container security

### Backup & DR
- ✅ **Velero** - Kubernetes backup and restore
- ✅ **RDS Automated Backups** - Database recovery
- ✅ **Cross-region Replication** - Disaster recovery
- ✅ **Automated Testing** - DR drill automation

### Cost Optimization
- ✅ **Kubecost** - Kubernetes cost visibility
- ✅ **VPA/HPA** - Resource optimization
- ✅ **Spot Instances** - Cost-effective compute
- ✅ **Resource Quotas** - Spend control

## 🚀 Access URLs

| Service | URL | Purpose |
|---------|-----|---------|
| ArgoCD | https://argocd.yourdomain.com | GitOps Management |
| Grafana | https://grafana.yourdomain.com | Monitoring Dashboards |
| Jaeger | https://jaeger.yourdomain.com | Distributed Tracing |
| OpenSearch | https://logs.yourdomain.com | Log Analysis |
| Vault | https://vault.yourdomain.com | Secrets Management |
| Jenkins | https://jenkins.yourdomain.com | CI/CD Pipelines |
| Kubecost | https://kubecost.yourdomain.com | Cost Analytics |

## 🔑 Default Credentials

```bash
# ArgoCD
Username: admin
Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Grafana
Username: admin
Password: AdminPassword123!

# Vault Root Token
Token: $(cat cluster-keys.json | jq -r ".root_token")
```

## 📊 System Overview

```bash
# Check overall system health
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running

# Monitor resource usage
kubectl top nodes
kubectl top pods --all-namespaces --sort-by=cpu

# Check applications
argocd app list
helm list --all-namespaces
```

## 🛠️ Common Operations

### Deploy New Application
```bash
# 1. Add application manifests to GitOps repo
cd gitops-config/applications/dev
# Create your application YAML files

# 2. Commit and push
git add .
git commit -m "Add new application"
git push origin main

# 3. ArgoCD will automatically sync
argocd app sync <app-name>
```

### Scale Applications
```bash
# Manual scaling
kubectl scale deployment <app-name> --replicas=5 -n <namespace>

# Auto-scaling with HPA
kubectl autoscale deployment <app-name> --cpu-percent=70 --min=2 --max=10 -n <namespace>
```

### Check Logs
```bash
# Pod logs
kubectl logs <pod-name> -n <namespace> --tail=100

# Application logs in OpenSearch
# Visit: https://logs.yourdomain.com
# Query: kubernetes.namespace_name:"dev" AND kubernetes.labels.app:"your-app"
```

### Monitor Performance
```bash
# Real-time metrics
kubectl top pods -n <namespace>

# Grafana dashboards
# Visit: https://grafana.yourdomain.com
# Check: Kubernetes Cluster Overview dashboard
```

### Backup and Restore
```bash
# Create backup
velero backup create <backup-name> --include-namespaces <namespace>

# Restore from backup
velero restore create <restore-name> --from-backup <backup-name>

# Check backup status
velero backup describe <backup-name>
```

## 🚨 Troubleshooting

### Pod Issues
```bash
# Pod not starting
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>

# Resource issues
kubectl top pods -n <namespace>
kubectl describe node <node-name>
```

### Network Issues
```bash
# DNS resolution
kubectl exec -it <pod-name> -n <namespace> -- nslookup kubernetes.default

# Service connectivity
kubectl exec -it <pod-name> -n <namespace> -- curl <service-name>.<namespace>.svc.cluster.local
```

### Storage Issues
```bash
# PVC status
kubectl get pvc -n <namespace>
kubectl describe pvc <pvc-name> -n <namespace>

# Storage classes
kubectl get storageclass
```

## 📈 Performance Optimization

### Resource Right-sizing
```bash
# Check VPA recommendations
kubectl get vpa --all-namespaces

# Apply VPA recommendations
kubectl patch deployment <app-name> -n <namespace> --patch '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "<container-name>",
            "resources": {
              "requests": {
                "cpu": "<recommended-cpu>",
                "memory": "<recommended-memory>"
              }
            }
          }
        ]
      }
    }
  }
}'
```

### Cost Optimization
```bash
# Check cost recommendations
# Visit: https://kubecost.yourdomain.com

# Use spot instances for development
kubectl taint node <node-name> spot=true:NoSchedule

# Implement resource quotas
kubectl apply -f resource-quotas.yaml
```

## 🔒 Security Best Practices

### Regular Security Tasks
```bash
# Update base images regularly
docker pull nginx:alpine
docker tag nginx:alpine ghcr.io/yourusername/nginx:latest
docker push ghcr.io/yourusername/nginx:latest

# Scan for vulnerabilities
trivy image <image-name>

# Check for policy violations
kubectl get events --all-namespaces | grep -i policy

# Review Falco alerts
kubectl logs -l app.kubernetes.io/name=falco -n falco
```

### Certificate Management
```bash
# Check certificate status
kubectl get certificates --all-namespaces

# Force certificate renewal
kubectl annotate certificate <cert-name> -n <namespace> \
  cert-manager.io/issue-temporary-certificate="true"
```

## 📚 Additional Resources

### Documentation
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS User Guide](https://docs.aws.amazon.com/eks/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

### Monitoring
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [SRE Workbook](https://sre.google/workbook/table-of-contents/)

### Security
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [OWASP Container Security](https://owasp.org/www-project-container-security/)

## 🆘 Support and Contacts

### Internal Support
- **DevOps Team**: #devops-team (Slack)
- **On-call Engineer**: +90-XXX-XXX-XXXX
- **Documentation**: `~/devops-infrastructure/docs/`

### Emergency Procedures
1. **Production Down**: Follow incident response runbook
2. **Security Incident**: Contact security team immediately
3. **Data Loss**: Initiate disaster recovery procedures

---

## 🎉 Congratulations!

You now have a **production-ready, enterprise-grade DevOps infrastructure** that includes:

✅ **Automated Infrastructure** - Everything as code  
✅ **Continuous Deployment** - GitOps workflow  
✅ **Comprehensive Monitoring** - Full observability stack  
✅ **Enterprise Security** - Multi-layer security controls  
✅ **Disaster Recovery** - Automated backup and restore  
✅ **Cost Optimization** - Resource efficiency and cost visibility  
✅ **Performance Management** - Auto-scaling and optimization  
✅ **Team Processes** - Documentation and runbooks  

**Your infrastructure is ready to support modern application development and deployment at scale!** 🚀

---

*Generated on: $(date)*  
*Infrastructure Version: v1.0.0*  
*Last Updated: $(date '+%Y-%m-%d %H:%M:%S')*
EOF

# 13.2.2 Quick start guide
cat > ~/devops-infrastructure/QUICKSTART.md << 'EOF'
# 🚀 Quick Start Guide

## Prerequisites Checklist

- [ ] AWS Account with administrative access
- [ ] Domain name for services (yourdomain.com)
- [ ] GitHub account for repositories
- [ ] Slack workspace for notifications
- [ ] Local development environment setup

## 30-Minute Setup

### Step 1: Initial Setup (5 minutes)
```bash
# Clone repository
git clone https://github.com/yourusername/devops-infrastructure.git
cd devops-infrastructure

# Run automated setup
./scripts/quick-setup.sh
```

### Step 2: Infrastructure Deployment (15 minutes)
```bash
# Deploy AWS infrastructure
cd terraform/environments/dev
terraform init -backend-config=backend.conf
terraform plan
terraform apply -auto-approve

# Configure kubectl
aws eks update-kubeconfig --region eu-west-1 --name mycompany-dev-eks
```

### Step 3: Application Deployment (10 minutes)
```bash
# Deploy monitoring stack
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace --values monitoring-values.yaml

# Deploy ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Deploy root application
kubectl apply -f bootstrap/root-app.yaml
```

## Verification

```bash
# Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Access services
echo "ArgoCD: https://argocd.yourdomain.com"
echo "Grafana: https://grafana.yourdomain.com"
echo "Applications ready! 🎉"
```

## Next Steps

1. **Configure DNS** - Point your domain to the load balancer
2. **Setup Certificates** - Configure SSL/TLS certificates
3. **Deploy Applications** - Add your applications to GitOps
4. **Configure Monitoring** - Set up dashboards and alerts
5. **Train Team** - Share access and documentation

## Need Help?

- 📖 **Full Documentation**: [README.md](README.md)
- 🔧 **Troubleshooting**: [docs/troubleshooting.md](docs/troubleshooting.md)
- 💬 **Support**: Contact DevOps team

**Happy deploying!** 🚀
EOF

echo ""
echo "🎉 ============================================"
echo "🎉  DEVOPS INFRASTRUCTURE SETUP COMPLETE!"
echo "🎉 ============================================"
echo ""
echo "📊 Summary:"
echo "✅ Infrastructure as Code (Terraform)"
echo "✅ Kubernetes Cluster (EKS)"
echo "✅ CI/CD Pipeline (Jenkins + ArgoCD)"
echo "✅ Monitoring Stack (Prometheus + Grafana)"
echo "✅ Logging Stack (OpenSearch + Fluent Bit)"
echo "✅ Security Layer (Vault + Falco + OPA)"
echo "✅ Backup & DR (Velero + RDS Backups)"
echo "✅ Cost Optimization (Kubecost + VPA/HPA)"
echo "✅ Documentation & Runbooks"
echo ""
echo "🔗 Access URLs:"
echo "• ArgoCD: https://argocd.yourdomain.com"
echo "• Grafana: https://grafana.yourdomain.com"
echo "• Jenkins: https://jenkins.yourdomain.com"
echo "• Vault: https://vault.yourdomain.com"
echo ""
echo "📚 Next Steps:"
echo "1. Run system validation: ./scripts/system-validation.sh"
echo "2. Configure your domain DNS"
echo "3. Deploy your first application"
echo "4. Train your team with provided documentation"
echo ""
echo "🎯 Your enterprise-grade DevOps infrastructure is ready!"
echo "   Happy DevOps! 🚀"
```

Bu kapsamlı implementation guide ile sıfırdan başlayarak **28 gün içinde** tam işlevsel, production-ready bir DevOps altyapısı kurabilirsiniz. Her adım detaylı komutlar, konfigürasyonlar ve best practice'ler içerir.
