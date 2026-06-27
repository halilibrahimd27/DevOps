# 📋 **ÖN KOŞULLAR VE HAZIRLIK**

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
