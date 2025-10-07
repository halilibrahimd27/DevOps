# Kubernetes Cluster Kurulum Rehberi - Proxmox Ubuntu

## Sistem Gereksinimleri ve Ön Hazırlık

### Makine Konfigürasyonları
- **Master**: 2+ CPU, 4+ GB RAM, 20+ GB Disk
- **Worker1**: 2+ CPU, 2+ GB RAM, 20+ GB Disk  
- **Worker2**: 2+ CPU, 2+ GB RAM, 20+ GB Disk

### IP Adresleri (Örnek - kendi ağınıza göre ayarlayın)
- Master: 192.168.1.10
- Worker1: 192.168.1.11
- Worker2: 192.168.1.12

---

## ADIM 1: Mevcut Docker ve Kubernetes Temizliği

### Tüm makinelerde çalıştırın:

```bash
# Kubernetes servislerini durdur
sudo systemctl stop kubelet kubeadm kubectl

# Docker'ı durdur
sudo systemctl stop docker

# Kubernetes paketlerini kaldır
sudo apt-get purge -y kubeadm kubectl kubelet kubernetes-cni kube*

# Docker paketlerini kaldır
sudo apt-get purge -y docker.io docker-ce docker-ce-cli containerd.io

# Konfigürasyon dosyalarını temizle
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/kubelet/
sudo rm -rf /var/lib/etcd/
sudo rm -rf /etc/docker/
sudo rm -rf /var/lib/docker/
sudo rm -rf /var/lib/containerd/
sudo rm -rf ~/.kube/

# Sistem paketlerini güncelle
sudo apt-get autoremove -y
sudo apt-get autoclean
sudo apt-get update
```

---

## ADIM 2: Sistem Ayarları ve Hazırlık

### Tüm makinelerde çalıştırın:

```bash
# Hostname ayarla (her makine için farklı)
# Master için:
sudo hostnamectl set-hostname k8s-master

# Worker1 için:
sudo hostnamectl set-hostname k8s-worker1

# Worker2 için:
sudo hostnamectl set-hostname k8s-worker2

# Hosts dosyasını düzenle
sudo nano /etc/hosts

# Aşağıdaki satırları ekleyin (IP adreslerinizi düzenleyin):
192.168.1.10    k8s-master
192.168.1.11    k8s-worker1
192.168.1.12    k8s-worker2

# Swap'ı devre dışı bırak
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Kernel modüllerini yükle
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Sysctl parametrelerini ayarla
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Sistem güncellemesi
sudo apt-get update && sudo apt-get upgrade -y
```

---

## ADIM 3: Docker Kurulumu

### Tüm makinelerde çalıştırın:

```bash
# Gerekli paketleri yükle
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https

# Docker GPG anahtarını ekle
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Docker repository'sini ekle
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker'ı yükle
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker'ı başlat ve enable et
sudo systemctl start docker
sudo systemctl enable docker

# Kullanıcıyı docker grubuna ekle
sudo usermod -aG docker $USER

# Containerd'yi yapılandır
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# SystemdCgroup'u etkinleştir
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Containerd'yi restart et
sudo systemctl restart containerd
sudo systemctl enable containerd
```

---

## ADIM 4: Kubernetes Kurulumu

### Tüm makinelerde çalıştırın:

```bash
# Kubernetes GPG anahtarını ekle
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Kubernetes repository'sini ekle
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Paket listesini güncelle
sudo apt-get update

# Kubernetes paketlerini yükle
sudo apt-get install -y kubelet kubeadm kubectl

# Paketleri hold et (otomatik güncellemeyi engelle)
sudo apt-mark hold kubelet kubeadm kubectl

# Kubelet'i başlat ve enable et
sudo systemctl enable kubelet
```

---

## ADIM 5: Master Node Kurulumu

### Sadece Master makinede çalıştırın:

```bash
# Cluster'ı başlat
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.1.10 \
  --control-plane-endpoint=k8s-master

# Çıktıdaki join komutunu kaydedin! Örnek:
# kubeadm join k8s-master:6443 --token abcd12.1234567890123456 \
#     --discovery-token-ca-cert-hash sha256:1234567890abcdef...

# kubectl konfigürasyonu
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Root kullanıcısı için de ayarla
sudo mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config

# Cluster durumunu kontrol et
kubectl get nodes
kubectl get pods -A
```

---

## ADIM 6: Pod Network (Flannel) Kurulumu

### Sadece Master makinede çalıştırın:

```bash
# Flannel network plugin'ini yükle
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Kurulumu kontrol et
kubectl get pods -n kube-flannel
kubectl get nodes

# Tüm podların Running olmasını bekleyin
watch kubectl get pods -A
```

---

## ADIM 7: Worker Node'ları Cluster'a Katma

### Worker1 ve Worker2 makinelerinde çalıştırın:

```bash
# Master'dan aldığınız join komutunu çalıştırın
# Örnek (kendi token'ınızı kullanın):
sudo kubeadm join k8s-master:6443 --token abcd12.1234567890123456 \
    --discovery-token-ca-cert-hash sha256:1234567890abcdef...

# Eğer token'ı unuttuysanız, Master'da yeni token oluşturun:
# kubeadm token create --print-join-command
```

### Master'da kontrol edin:

```bash
# Node'ları kontrol et
kubectl get nodes

# Detaylı bilgi
kubectl get nodes -o wide

# Tüm node'ların Ready olmasını bekleyin
watch kubectl get nodes
```

---

## ADIM 8: Cluster Test ve Doğrulama

### Master makinede test uygulaması çalıştırın:

```bash
# Test deployment oluştur
kubectl create deployment nginx-test --image=nginx

# Service oluştur
kubectl expose deployment nginx-test --port=80 --type=NodePort

# Deployment'ı scale et
kubectl scale deployment nginx-test --replicas=3

# Durumu kontrol et
kubectl get deployments
kubectl get pods -o wide
kubectl get services

# Pod'ların farklı node'larda çalıştığını kontrol edin
kubectl get pods -o wide

# Service'i test et
kubectl get svc nginx-test
```

---

## ADIM 9: Dashboard Kurulumu (Opsiyonel)

### Master makinede çalıştırın:

```bash
# Dashboard'u yükle
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Admin kullanıcısı oluştur
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

# Token oluştur
kubectl -n kubernetes-dashboard create token admin-user

# Dashboard'a erişim için proxy başlat
kubectl proxy --address='0.0.0.0' --accept-hosts='^*$'

# Dashboard URL:
# http://192.168.1.10:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

---

## ADIM 10: Monitoring ve Logging (Opsiyonel)

### Metrics Server kurulumu:

```bash
# Metrics server'ı yükle
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Metrics server'ı düzenle (self-signed sertifikalar için)
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Resource kullanımını kontrol et
kubectl top nodes
kubectl top pods -A
```

---

## Yararlı Komutlar ve Troubleshooting

### Cluster Yönetimi:
```bash
# Tüm node'ları listele
kubectl get nodes -o wide

# Cluster bilgisi
kubectl cluster-info

# Namespace'leri listele
kubectl get namespaces

# Tüm pod'ları listele
kubectl get pods -A

# Node detayları
kubectl describe node k8s-master

# Events'i görüntüle
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Troubleshooting:
```bash
# Kubelet logları
sudo journalctl -u kubelet -f

# Container runtime logları
sudo journalctl -u containerd -f

# Cluster durumu
kubectl get componentstatuses

# Pod logları
kubectl logs <pod-name> -n <namespace>

# Node'u drain et (bakım için)
kubectl drain <node-name> --ignore-daemonsets

# Node'u tekrar aktif et
kubectl uncordon <node-name>
```

### Worker node kaldırma:
```bash
# Master'da:
kubectl drain <node-name> --delete-emptydir-data --force --ignore-daemonsets
kubectl delete node <node-name>

# Worker node'da:
sudo kubeadm reset
sudo rm -rf /etc/kubernetes/
sudo rm -rf ~/.kube/
```

---

## Güvenlik ve Optimizasyon

### Güvenlik ayarları:
```bash
# Network policies enable et
# (Flannel default olarak desteklemez, Calico kullanabilirsiniz)

# RBAC kontrol et
kubectl get clusterrolebindings

# Pod security policies
kubectl get psp
```

### Performance optimizasyonu:
```bash
# Node resources
kubectl describe nodes

# Resource quotas
kubectl get resourcequotas -A

# CPU ve Memory limits
kubectl get pods -A -o custom-columns=NAME:.metadata.name,CPU:.spec.containers[*].resources.requests.cpu,MEMORY:.spec.containers[*].resources.requests.memory
```

---

## Backup ve Restore

### ETCD Backup:
```bash
# ETCD snapshot al
sudo ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Snapshot'ı doğrula
sudo ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db
```

---

## Sonuç

Bu rehberi takip ederek:
- ✅ Temiz bir Kubernetes cluster kurulumu yaptınız
- ✅ 3 node'lu (1 master, 2 worker) cluster oluşturdunuz
- ✅ Network plugin (Flannel) kurdunuz
- ✅ Test uygulaması çalıştırdınız
- ✅ Dashboard kurdunuz (opsiyonel)
- ✅ Monitoring araçları kurdunuz (opsiyonel)

Cluster'ınız artık production-ready durumda. Uygulama deploy etmeye başlayabilirsiniz!

### İletişim Test:
```bash
# Tüm node'ların birbirleriyle iletişim kurduğunu test edin
kubectl get nodes
kubectl get pods -A -o wide
```

---

## Alınabilecek Hatalar Rehberi

### CD-ROM Repository Hatası
```bash
# Mevcut dosyayı yedekle
sudo mv /etc/apt/sources.list /etc/apt/sources.list.old

# Yeni sources.list oluştur
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

## Veya

deb http://mirror.kku.ac.th/ubuntu jammy main restricted universe multiverse
deb http://mirror.kku.ac.th/ubuntu jammy-updates main restricted universe multiverse
deb http://mirror.kku.ac.th/ubuntu jammy-backports main restricted universe multiverse
deb http://mirror.kku.ac.th/ubuntu jammy-security main restricted universe multiverse
```

### Eski Sistemden Kalma Port Çakışması
```bash
# Tüm Kubernetes servislerini durdur
sudo systemctl stop kubelet
sudo systemctl stop docker
sudo systemctl stop containerd

# Kubernetes cluster'ını reset et
sudo kubeadm reset --force

# Tüm container'ları durdur ve sil
docker ps -a -q | xargs -r docker stop
docker ps -a -q | xargs -r docker rm

# Tüm image'leri sil
docker images -q | xargs -r docker rmi -f

# Kubernetes portlarını kullanan process'leri bul
sudo netstat -tulnp | grep -E ":(6443|10250|10259|10257|2379|2380)"
sudo lsof -i :10259
sudo lsof -i :10257  
sudo lsof -i :10250
sudo lsof -i :6443

# Eğer process varsa kill et
sudo pkill -f kube-apiserver
sudo pkill -f kube-controller-manager
sudo pkill -f kube-scheduler
sudo pkill -f kubelet
sudo pkill -f etcd

# Kubernetes dosyalarını tamamen sil
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/kubelet/
sudo rm -rf /var/lib/etcd/
sudo rm -rf /var/lib/dockershim/
sudo rm -rf /var/run/kubernetes/
sudo rm -rf /var/lib/cni/
sudo rm -rf /etc/cni/
sudo rm -rf ~/.kube/
sudo rm -rf /root/.kube/

# Container runtime dosyalarını temizle
sudo rm -rf /var/lib/containerd/
sudo rm -rf /var/lib/docker/
sudo rm -rf /run/containerd/
sudo rm -rf /run/docker/

# Network interface'leri temizle
sudo ip link delete cni0 2>/dev/null || true
sudo ip link delete flannel.1 2>/dev/null || true
sudo ip link delete docker0 2>/dev/null || true

# iptables kurallarını temizle
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X

# Containerd'yi yeniden yapılandır
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Servisleri restart et
sudo systemctl restart containerd
sudo systemctl restart docker
sudo systemctl daemon-reload

# Servis durumlarını kontrol et
sudo systemctl status containerd
sudo systemctl status docker

# Portların boş olduğunu kontrol et
sudo netstat -tulnp | grep -E ":(6443|10250|10259|10257|2379|2380)"

# Eğer hala process varsa sistem restart gerekebilir
# sudo reboot

# Sistem hazır mı kontrol et
sudo kubeadm init phase preflight

# Kubeadm init'i çalıştır
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=172.168.30.10 \
  --control-plane-endpoint=master \
  --v=5

# Sistem restart yap
sudo reboot

# Restart sonrası tekrar dene
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=172.168.30.10 \
  --control-plane-endpoint=master
```


### HTTPS Hatası ve Tokeni Kalıcı Hale Getirme
 ```bash
# Master'da token'ı al
kubectl -n kubernetes-dashboard create token admin-user

# Dashboard'u NodePort olarak expose et
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"NodePort"}}'

# Port numarasını öğren
kubectl get svc kubernetes-dashboard -n kubernetes-dashboard

# HTTPS URL'ini kullan
# https://172.168.30.10:<nodeport-number>

# Long-lived token oluştur
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

# Token'ı al
kubectl get secret admin-user-secret -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d
```
