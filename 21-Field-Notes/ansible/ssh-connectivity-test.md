# SSH Bağlantı Testi

> 🗒️ **Saha notu** — ham komut/konfigürasyon dökümü. Olduğu gibi korunmuştur; kendi ortamına uyarla.

```bash
# SSH bağlantısını test et
echo "🔍 Testing SSH connectivity..."

# Master nodes
ssh -i ~/.ssh/k8s-cluster -o ConnectTimeout=5 ubuntu@<K8S_MASTER_1_IP> 'echo "✅ k8s-master-1: $(hostname)"'
ssh -i ~/.ssh/k8s-cluster -o ConnectTimeout=5 ubuntu@<K8S_MASTER_2_IP> 'echo "✅ k8s-master-2: $(hostname)"'
ssh -i ~/.ssh/k8s-cluster -o ConnectTimeout=5 ubuntu@<K8S_MASTER_3_IP> 'echo "✅ k8s-master-3: $(hostname)"'

# Worker nodes
ssh -i ~/.ssh/k8s-cluster -o ConnectTimeout=5 ubuntu@<K8S_WORKER_1_IP> 'echo "✅ k8s-worker-1: $(hostname)"'
ssh -i ~/.ssh/k8s-cluster -o ConnectTimeout=5 ubuntu@<K8S_WORKER_2_IP> 'echo "✅ k8s-worker-2: $(hostname)"'
ssh -i ~/.ssh/k8s-cluster -o ConnectTimeout=5 ubuntu@<K8S_WORKER_3_IP> 'echo "✅ k8s-worker-3: $(hostname)"'

# Storage node
ssh -i ~/.ssh/k8s-cluster -o ConnectTimeout=5 ubuntu@<K8S_STORAGE_IP> 'echo "✅ k8s-storage: $(hostname)"'

# Infrastructure nodes
ssh -i ~/.ssh/k8s-cluster -o ConnectTimeout=5 ubuntu@<K8S_INFRA_1_IP> 'echo "✅ k8s-infra-1: $(hostname)"'
ssh -i ~/.ssh/k8s-cluster -o ConnectTimeout=5 ubuntu@<K8S_INFRA_2_IP> 'echo "✅ k8s-infra-2: $(hostname)"'
ssh -i ~/.ssh/k8s-cluster -o ConnectTimeout=5 ubuntu@<K8S_INFRA_3_IP> 'echo "✅ k8s-infra-3: $(hostname)"'
ssh -i ~/.ssh/k8s-cluster -o ConnectTimeout=5 ubuntu@<K8S_INFRA_4_IP> 'echo "✅ k8s-infra-4: $(hostname)"'

# Load balancer nodes
ssh -i ~/.ssh/k8s-cluster -o ConnectTimeout=5 ubuntu@<K8S_LB_VIP> 'echo "✅ k8s-lb-1: $(hostname)"'
ssh -i ~/.ssh/k8s-cluster -o ConnectTimeout=5 ubuntu@<K8S_LB_BACKUP_IP> 'echo "✅ k8s-lb-2: $(hostname)"'
```
