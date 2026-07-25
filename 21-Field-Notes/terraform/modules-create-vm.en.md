---
description: "Bash script that manually creates Kubernetes master and worker VMs with qm clone on Proxmox: cores, memory, disk, cloud-init IP and SSH key settings."
tags:
  - Field Notes
  - Terraform
  - IaC
  - Kubernetes
  - Containers
---
# Terraform — Creating VMs with Modules

> 🗒️ **Field note** — raw command/config dump. Preserved as-is; adapt it to your own environment.

```bash
cat > create_vms_fixed.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 Creating Kubernetes Cluster VMs manually..."

# Master Nodes
echo "📊 Creating Master Nodes..."
qm clone 999 100 --name k8s-master-1 --full
qm set 100 --cores 8 --memory 16384
qm resize 100 scsi0 100G
qm set 100 --ipconfig0 ip=<K8S_MASTER_1_IP>/24,gw=<GATEWAY_IP>
qm set 100 --nameserver 8.8.8.8
qm set 100 --sshkeys ~/.ssh/k8s-cluster.pub
qm set 100 --ciuser ubuntu --cipassword '<CI_PASSWORD>'
qm start 100

qm clone 999 101 --name k8s-master-2 --full
qm set 101 --cores 8 --memory 16384
qm resize 101 scsi0 100G
qm set 101 --ipconfig0 ip=<K8S_MASTER_2_IP>/24,gw=<GATEWAY_IP>
qm set 101 --nameserver 8.8.8.8
qm set 101 --sshkeys ~/.ssh/k8s-cluster.pub
qm set 101 --ciuser ubuntu --cipassword '<CI_PASSWORD>'
qm start 101

qm clone 999 102 --name k8s-master-3 --full
qm set 102 --cores 8 --memory 16384
qm resize 102 scsi0 100G
qm set 102 --ipconfig0 ip=<K8S_MASTER_3_IP>/24,gw=<GATEWAY_IP>
qm set 102 --nameserver 8.8.8.8
qm set 102 --sshkeys ~/.ssh/k8s-cluster.pub
qm set 102 --ciuser ubuntu --cipassword '<CI_PASSWORD>'
qm start 102

echo "✅ Master nodes created, waiting..."
sleep 20

# Worker Nodes  
echo "📊 Creating Worker Nodes..."
qm clone 999 110 --name k8s-worker-1 --full
qm set 110 --cores 16 --memory 65536
qm resize 110 scsi0 500G
qm set 110 --ipconfig0 ip=<K8S_WORKER_1_IP>/24,gw=<GATEWAY_IP>
qm set 110 --nameserver 8.8.8.8
qm set 110 --sshkeys ~/.ssh/k8s-cluster.pub
qm set 110 --ciuser ubuntu --cipassword '<CI_PASSWORD>'
qm start 110

qm clone 999 111 --name k8s-worker-2 --full
qm set 111 --cores 16 --memory 65536
qm resize 111 scsi0 500G
qm set 111 --ipconfig0 ip=<K8S_WORKER_2_IP>/24,gw=<GATEWAY_IP>
qm set 111 --nameserver 8.8.8.8
qm set 111 --sshkeys ~/.ssh/k8s-cluster.pub
qm set 111 --ciuser ubuntu --cipassword '<CI_PASSWORD>'
qm start 111

qm clone 999 112 --name k8s-worker-3 --full
qm set 112 --cores 16 --memory 65536
qm resize 112 scsi0 500G
qm set 112 --ipconfig0 ip=<K8S_WORKER_3_IP>/24,gw=<GATEWAY_IP>
qm set 112 --nameserver 8.8.8.8
qm set 112 --sshkeys ~/.ssh/k8s-cluster.pub
qm set 112 --ciuser ubuntu --cipassword '<CI_PASSWORD>'
qm start 112

echo "✅ Worker nodes created, waiting..."
sleep 20

# Infrastructure Nodes
echo "📊 Creating Infrastructure Nodes..."
qm clone 999 120 --name k8s-infra-1 --full
qm set 120 --cores 12 --memory 49152
qm resize 120 scsi0 300G
qm set 120 --ipconfig0 ip=<K8S_INFRA_1_IP>/24,gw=<GATEWAY_IP>
qm set 120 --nameserver 8.8.8.8
qm set 120 --sshkeys ~/.ssh/k8s-cluster.pub
qm set 120 --ciuser ubuntu --cipassword '<CI_PASSWORD>'
qm start 120

qm clone 999 121 --name k8s-infra-2 --full
qm set 121 --cores 12 --memory 49152
qm resize 121 scsi0 300G
qm set 121 --ipconfig0 ip=<K8S_INFRA_2_IP>/24,gw=<GATEWAY_IP>
qm set 121 --nameserver 8.8.8.8
qm set 121 --sshkeys ~/.ssh/k8s-cluster.pub
qm set 121 --ciuser ubuntu --cipassword '<CI_PASSWORD>'
qm start 121

qm clone 999 122 --name k8s-infra-3 --full
qm set 122 --cores 12 --memory 49152
qm resize 122 scsi0 300G
qm set 122 --ipconfig0 ip=<K8S_INFRA_3_IP>/24,gw=<GATEWAY_IP>
qm set 122 --nameserver 8.8.8.8
qm set 122 --sshkeys ~/.ssh/k8s-cluster.pub
qm set 122 --ciuser ubuntu --cipassword '<CI_PASSWORD>'
qm start 122

qm clone 999 123 --name k8s-infra-4 --full
qm set 123 --cores 12 --memory 49152
qm resize 123 scsi0 300G
qm set 123 --ipconfig0 ip=<K8S_INFRA_4_IP>/24,gw=<GATEWAY_IP>
qm set 123 --nameserver 8.8.8.8
qm set 123 --sshkeys ~/.ssh/k8s-cluster.pub
qm set 123 --ciuser ubuntu --cipassword '<CI_PASSWORD>'
qm start 123

echo "✅ Infrastructure nodes created, waiting..."
sleep 20

# Load Balancer Nodes
echo "📊 Creating Load Balancer Nodes..."
qm clone 999 130 --name k8s-lb-1 --full
qm set 130 --cores 4 --memory 8192
qm resize 130 scsi0 50G
qm set 130 --ipconfig0 ip=<K8S_LB_VIP>/24,gw=<GATEWAY_IP>
qm set 130 --nameserver 8.8.8.8
qm set 130 --sshkeys ~/.ssh/k8s-cluster.pub
qm set 130 --ciuser ubuntu --cipassword '<CI_PASSWORD>'
qm start 130

qm clone 999 131 --name k8s-lb-2 --full
qm set 131 --cores 4 --memory 8192
qm resize 131 scsi0 50G
qm set 131 --ipconfig0 ip=<K8S_LB_BACKUP_IP>/24,gw=<GATEWAY_IP>
qm set 131 --nameserver 8.8.8.8
qm set 131 --sshkeys ~/.ssh/k8s-cluster.pub
qm set 131 --ciuser ubuntu --cipassword '<CI_PASSWORD>'
qm start 131

echo "✅ Load balancer nodes created, waiting..."
sleep 20

# Storage Node
echo "📊 Creating Storage Node..."
qm clone 999 140 --name k8s-storage --full
qm set 140 --cores 8 --memory 32768
qm resize 140 scsi0 1000G
qm set 140 --ipconfig0 ip=<K8S_STORAGE_IP>/24,gw=<GATEWAY_IP>
qm set 140 --nameserver 8.8.8.8
qm set 140 --sshkeys ~/.ssh/k8s-cluster.pub
qm set 140 --ciuser ubuntu --cipassword '<CI_PASSWORD>'
qm start 140

echo "✅ Storage node created"

echo ""
echo "🎉 All 13 VMs created successfully!"
echo "⏱️  Waiting 2 minutes for cloud-init..."
sleep 120

echo "✅ Ready for SSH access!"
echo "Test: ssh -i ~/.ssh/k8s-cluster ubuntu@<K8S_MASTER_1_IP>"
EOF

chmod +x create_vms_fixed.sh
```
