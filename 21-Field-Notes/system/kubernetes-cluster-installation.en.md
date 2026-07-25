---
description: "Kubernetes cluster installation guide with Ubuntu on Proxmox: machine requirements, IP plan, cleanup of old Docker/Kubernetes and step-by-step installation."
tags:
  - Field Notes
  - Kubernetes
  - Containers
  - Docker
  - Networking
---
# Kubernetes Cluster Installation Guide - Proxmox Ubuntu

## System Requirements and Preparation

### Machine Configurations
- **Master**: 2+ CPU, 4+ GB RAM, 20+ GB Disk
- **Worker1**: 2+ CPU, 2+ GB RAM, 20+ GB Disk  
- **Worker2**: 2+ CPU, 2+ GB RAM, 20+ GB Disk

### IP Addresses (Example - adjust to your own network)
- Master: 192.168.1.10
- Worker1: 192.168.1.11
- Worker2: 192.168.1.12

---

## STEP 1: Cleanup of Existing Docker and Kubernetes

### Run on all machines:

```bash
# Stop Kubernetes services
sudo systemctl stop kubelet kubeadm kubectl

# Stop Docker
sudo systemctl stop docker

# Remove Kubernetes packages
sudo apt-get purge -y kubeadm kubectl kubelet kubernetes-cni kube*

# Remove Docker packages
sudo apt-get purge -y docker.io docker-ce docker-ce-cli containerd.io

# Clean up configuration files
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/kubelet/
sudo rm -rf /var/lib/etcd/
sudo rm -rf /etc/docker/
sudo rm -rf /var/lib/docker/
sudo rm -rf /var/lib/containerd/
sudo rm -rf ~/.kube/

# Update system packages
sudo apt-get autoremove -y
sudo apt-get autoclean
sudo apt-get update
```

---

## STEP 2: System Settings and Preparation

### Run on all machines:

```bash
# Set hostname (different for each machine)
# For Master:
sudo hostnamectl set-hostname k8s-master

# For Worker1:
sudo hostnamectl set-hostname k8s-worker1

# For Worker2:
sudo hostnamectl set-hostname k8s-worker2

# Edit the hosts file
sudo nano /etc/hosts

# Add the following lines (adjust your IP addresses):
192.168.1.10    k8s-master
192.168.1.11    k8s-worker1
192.168.1.12    k8s-worker2

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set sysctl parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# System update
sudo apt-get update && sudo apt-get upgrade -y
```

---

## STEP 3: Docker Installation

### Run on all machines:

```bash
# Install required packages
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https

# Add the Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add the Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add the user to the docker group
sudo usermod -aG docker $USER

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Enable SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd
```

---

## STEP 4: Kubernetes Installation

### Run on all machines:

```bash
# Add the Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the Kubernetes repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update the package list
sudo apt-get update

# Install Kubernetes packages
sudo apt-get install -y kubelet kubeadm kubectl

# Hold the packages (prevent automatic updates)
sudo apt-mark hold kubelet kubeadm kubectl

# Start and enable kubelet
sudo systemctl enable kubelet
```

---

## STEP 5: Master Node Installation

### Run only on the Master machine:

```bash
# Initialize the cluster
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.1.10 \
  --control-plane-endpoint=k8s-master

# Save the join command from the output! Example:
# kubeadm join k8s-master:6443 --token abcd12.1234567890123456 \
#     --discovery-token-ca-cert-hash sha256:1234567890abcdef...

# kubectl configuration
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Set up for the root user as well
sudo mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config

# Check the cluster status
kubectl get nodes
kubectl get pods -A
```

---

## STEP 6: Pod Network (Flannel) Installation

### Run only on the Master machine:

```bash
# Install the Flannel network plugin
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Check the installation
kubectl get pods -n kube-flannel
kubectl get nodes

# Wait for all pods to be Running
watch kubectl get pods -A
```

---

## STEP 7: Joining Worker Nodes to the Cluster

### Run on the Worker1 and Worker2 machines:

```bash
# Run the join command you got from the Master
# Example (use your own token):
sudo kubeadm join k8s-master:6443 --token abcd12.1234567890123456 \
    --discovery-token-ca-cert-hash sha256:1234567890abcdef...

# If you forgot the token, create a new token on the Master:
# kubeadm token create --print-join-command
```

### Check on the Master:

```bash
# Check the nodes
kubectl get nodes

# Detailed info
kubectl get nodes -o wide

# Wait for all nodes to be Ready
watch kubectl get nodes
```

---

## STEP 8: Cluster Test and Verification

### Run a test application on the Master machine:

```bash
# Create a test deployment
kubectl create deployment nginx-test --image=nginx

# Create a service
kubectl expose deployment nginx-test --port=80 --type=NodePort

# Scale the deployment
kubectl scale deployment nginx-test --replicas=3

# Check the status
kubectl get deployments
kubectl get pods -o wide
kubectl get services

# Check that pods run on different nodes
kubectl get pods -o wide

# Test the service
kubectl get svc nginx-test
```

---

## STEP 9: Dashboard Installation (Optional)

### Run on the Master machine:

```bash
# Install the Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create an admin user
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Create a token
kubectl -n kubernetes-dashboard create token admin-user

# Start a proxy to access the Dashboard
kubectl proxy --address='0.0.0.0' --accept-hosts='^*$'

# Dashboard URL:
# http://192.168.1.10:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

---

## STEP 10: Monitoring and Logging (Optional)

### Metrics Server installation:

```bash
# Install the metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Edit the metrics server (for self-signed certificates)
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Check resource usage
kubectl top nodes
kubectl top pods -A
```

---

## Useful Commands and Troubleshooting

### Cluster Management:
```bash
# List all nodes
kubectl get nodes -o wide

# Cluster info
kubectl cluster-info

# List namespaces
kubectl get namespaces

# List all pods
kubectl get pods -A

# Node details
kubectl describe node k8s-master

# View events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Troubleshooting:
```bash
# Kubelet logs
sudo journalctl -u kubelet -f

# Container runtime logs
sudo journalctl -u containerd -f

# Cluster status
kubectl get componentstatuses

# Pod logs
kubectl logs <pod-name> -n <namespace>

# Drain the node (for maintenance)
kubectl drain <node-name> --ignore-daemonsets

# Reactivate the node
kubectl uncordon <node-name>
```

### Removing a worker node:
```bash
# On the Master:
kubectl drain <node-name> --delete-emptydir-data --force --ignore-daemonsets
kubectl delete node <node-name>

# On the worker node:
sudo kubeadm reset
sudo rm -rf /etc/kubernetes/
sudo rm -rf ~/.kube/
```

---

## Security and Optimization

### Security settings:
```bash
# Enable network policies
# (Flannel does not support them by default, you can use Calico)

# Check RBAC
kubectl get clusterrolebindings

# Pod security policies
kubectl get psp
```

### Performance optimization:
```bash
# Node resources
kubectl describe nodes

# Resource quotas
kubectl get resourcequotas -A

# CPU and Memory limits
kubectl get pods -A -o custom-columns=NAME:.metadata.name,CPU:.spec.containers[*].resources.requests.cpu,MEMORY:.spec.containers[*].resources.requests.memory
```

---

## Backup and Restore

### ETCD Backup:
```bash
# Take an ETCD snapshot
sudo ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify the snapshot
sudo ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db
```

---

## Conclusion

By following this guide, you have:
- ✅ Performed a clean Kubernetes cluster installation
- ✅ Created a 3-node (1 master, 2 worker) cluster
- ✅ Installed a network plugin (Flannel)
- ✅ Run a test application
- ✅ Installed the Dashboard (optional)
- ✅ Installed monitoring tools (optional)

Your cluster is now production-ready. You can start deploying applications!

### Connectivity Test:
```bash
# Test that all nodes communicate with each other
kubectl get nodes
kubectl get pods -A -o wide
```

---

## Guide to Possible Errors

### CD-ROM Repository Error
```bash
# Back up the existing file
sudo mv /etc/apt/sources.list /etc/apt/sources.list.old

# Create a new sources.list
sudo tee /etc/apt/sources.list > /dev/null <<EOF
# Ubuntu 22.04 LTS (Jammy) Repository List

deb http://archive.ubuntu.com/ubuntu/ jammy main restricted
deb-src http://archive.ubuntu.com/ubuntu/ jammy main restricted

deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted
deb-src http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted

deb http://archive.ubuntu.com/ubuntu/ jammy universe
deb-src http://archive.ubuntu.com/ubuntu/ jammy universe
deb http://archive.ubuntu.com/ubuntu/ jammy-updates universe
deb-src http://archive.ubuntu.com/ubuntu/ jammy-updates universe

deb http://archive.ubuntu.com/ubuntu/ jammy multiverse
deb-src http://archive.ubuntu.com/ubuntu/ jammy multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates multiverse
deb-src http://archive.ubuntu.com/ubuntu/ jammy-updates multiverse

deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted
deb-src http://security.ubuntu.com/ubuntu/ jammy-security main restricted
deb http://security.ubuntu.com/ubuntu/ jammy-security universe
deb-src http://security.ubuntu.com/ubuntu/ jammy-security universe
deb http://security.ubuntu.com/ubuntu/ jammy-security multiverse
deb-src http://security.ubuntu.com/ubuntu/ jammy-security multiverse
EOF

## Or

deb http://mirror.kku.ac.th/ubuntu jammy main restricted universe multiverse
deb http://mirror.kku.ac.th/ubuntu jammy-updates main restricted universe multiverse
deb http://mirror.kku.ac.th/ubuntu jammy-backports main restricted universe multiverse
deb http://mirror.kku.ac.th/ubuntu jammy-security main restricted universe multiverse
```

### Port Conflict Left Over from an Old System
```bash
# Stop all Kubernetes services
sudo systemctl stop kubelet
sudo systemctl stop docker
sudo systemctl stop containerd

# Reset the Kubernetes cluster
sudo kubeadm reset --force

# Stop and remove all containers
docker ps -a -q | xargs -r docker stop
docker ps -a -q | xargs -r docker rm

# Remove all images
docker images -q | xargs -r docker rmi -f

# Find processes using Kubernetes ports
sudo netstat -tulnp | grep -E ":(6443|10250|10259|10257|2379|2380)"
sudo lsof -i :10259
sudo lsof -i :10257  
sudo lsof -i :10250
sudo lsof -i :6443

# If there are processes, kill them
sudo pkill -f kube-apiserver
sudo pkill -f kube-controller-manager
sudo pkill -f kube-scheduler
sudo pkill -f kubelet
sudo pkill -f etcd

# Completely remove Kubernetes files
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/kubelet/
sudo rm -rf /var/lib/etcd/
sudo rm -rf /var/lib/dockershim/
sudo rm -rf /var/run/kubernetes/
sudo rm -rf /var/lib/cni/
sudo rm -rf /etc/cni/
sudo rm -rf ~/.kube/
sudo rm -rf /root/.kube/

# Clean up container runtime files
sudo rm -rf /var/lib/containerd/
sudo rm -rf /var/lib/docker/
sudo rm -rf /run/containerd/
sudo rm -rf /run/docker/

# Clean up network interfaces
sudo ip link delete cni0 2>/dev/null || true
sudo ip link delete flannel.1 2>/dev/null || true
sudo ip link delete docker0 2>/dev/null || true

# Clean up iptables rules
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X

# Reconfigure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart the services
sudo systemctl restart containerd
sudo systemctl restart docker
sudo systemctl daemon-reload

# Check the service statuses
sudo systemctl status containerd
sudo systemctl status docker

# Check that the ports are free
sudo netstat -tulnp | grep -E ":(6443|10250|10259|10257|2379|2380)"

# If there are still processes, a system restart may be needed
# sudo reboot

# Check whether the system is ready
sudo kubeadm init phase preflight

# Run kubeadm init
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=<K8S_MASTER_IP> \
  --control-plane-endpoint=master \
  --v=5

# Restart the system
sudo reboot

# Try again after the restart
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=<K8S_MASTER_IP> \
  --control-plane-endpoint=master
```


### HTTPS Error and Making the Token Persistent
 ```bash
# Get the token on the Master
kubectl -n kubernetes-dashboard create token admin-user

# Expose the Dashboard as NodePort
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"NodePort"}}'

# Find out the port number
kubectl get svc kubernetes-dashboard -n kubernetes-dashboard

# Use the HTTPS URL
# https://<K8S_MASTER_IP>:<nodeport-number>

# Create a long-lived token
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: admin-user-secret
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: admin-user
type: kubernetes.io/service-account-token
EOF

# Get the token
kubectl get secret admin-user-secret -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d
```
