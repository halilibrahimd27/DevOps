---
description: "DMZ, application ve management zone'larına ayrılmış ağ segmentasyonu mimarisi ve Wazuh SIEM entegrasyonu rehberi; VLAN/subnet planı ve güvenlik şeması."
---
# 🔒 Ağ Segmentasyonu ve Wazuh SIEM Entegrasyon Rehberi

> ℹ️ **Placeholder notu:** Bu rehberdeki tüm IP/subnet değerleri (`192.168.x.x` vb.)
> **RFC 1918 örnek adresleridir** — gerçek altyapı değildir. Segmentasyon şemasını
> anlatmak için somut tutulmuştur; kendi VLAN/subnet planına uyarla.

## 📋 Mevcut Durum ve Hedef Mimari

### 🎯 Hedef Ağ Segmentasyonu
```
┌────────────────────────────────────────────────────────────┐
│                    DMZ ZONE (Public)                       │
│  ┌──────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │Load Balancer │    │   Reverse   │    │   Bastion   │    │
│  │  HAProxy     │    │    Proxy    │    │    Host     │    │
│  │192.168.10.0/24│   │             │    │             │    │
│  └──────────────┘    └─────────────┘    └─────────────┘    │
└────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                 APPLICATION ZONE                            │
│  ┌───────────────┐   ┌───────────────┐   ┌───────────────┐  │
│  │   K8s Test    │   │ K8s Prod-A    │   │ K8s Prod-B    │  │
│  │   Cluster     │   │  Cluster      │   │  Cluster      │  │
│  │192.168.20.0/24│   │192.168.21.0/24│   │192.168.22.0/24│  │
│  └───────────────┘   └───────────────┘   └───────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                 MANAGEMENT ZONE                             │
│  ┌───────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │   Wazuh       │    │ Monitoring  │    │   Backup    │    │
│  │   SIEM        │    │ Prometheus  │    │   Server    │    │
│  │192.168.30.0/24│    │   Grafana   │    │             │    │
│  └───────────────┘    └─────────────┘    └─────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                  DATABASE ZONE                              │
│  ┌───────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │ PostgreSQL    │    │   Redis     │    │   MinIO     │    │
│  │  Cluster      │    │   Cache     │    │  Storage    │    │
│  │192.168.40.0/24│    │             │    │             │    │
│  └───────────────┘    └─────────────┘    └─────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 🌐 **1. PROXMOX AĞ SEGMENTASYONi KURULUMU**

### Proxmox Network Bridges Oluşturma

#### 1.1 Proxmox Web UI'den Network Konfigürasyonu:
```bash
# Proxmox host'ta bridges oluştur
# DMZ Bridge
auto vmbr1
iface vmbr1 inet static
    address 192.168.10.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes

# Application Bridge  
auto vmbr2
iface vmbr2 inet static
    address 192.168.20.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes

# Management Bridge
auto vmbr3
iface vmbr3 inet static
    address 192.168.30.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes

# Database Bridge
auto vmbr4
iface vmbr4 inet static
    address 192.168.40.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
```

#### 1.2 VM Network Assignments:
```bash
# Mevcut K8s cluster'ınızı yeniden yapılandırın:

# Test Cluster (192.168.20.0/24)
- k8s-test-master: 192.168.20.10
- k8s-test-worker1: 192.168.20.11
- k8s-test-worker2: 192.168.20.12

# Production Cluster A (192.168.21.0/24) - Yeni oluşturulacak
- k8s-prod-a-master: 192.168.21.10
- k8s-prod-a-worker1: 192.168.21.11
- k8s-prod-a-worker2: 192.168.21.12

# Production Cluster B (192.168.22.0/24) - Yeni oluşturulacak  
- k8s-prod-b-master: 192.168.22.10
- k8s-prod-b-worker1: 192.168.22.11
- k8s-prod-b-worker2: 192.168.22.12

# Management Zone (192.168.30.0/24)
- wazuh-manager: 192.168.30.10
- wazuh-indexer: 192.168.30.11
- wazuh-dashboard: 192.168.30.12
- prometheus: 192.168.30.13
- grafana: 192.168.30.14
```

---

## 🛡️ **2. WAZUH SIEM KURULUMU**

### 2.1 Wazuh Cluster Kurulumu

#### Wazuh Manager VM (192.168.30.10):
```bash
# Ubuntu 22.04 kurulumu ve güncelleme
sudo apt update && sudo apt upgrade -y

# Wazuh repository ekle
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

sudo apt update

# Wazuh Manager kurulumu
sudo apt install wazuh-manager -y

# Wazuh Manager'ı başlat
sudo systemctl daemon-reload
sudo systemctl enable wazuh-manager
sudo systemctl start wazuh-manager

# Manager durumunu kontrol et
sudo systemctl status wazuh-manager

# Firewall kuralları
sudo ufw allow 1514/udp
sudo ufw allow 1515/tcp
sudo ufw allow 55000/tcp
```

#### Wazuh Indexer VM (192.168.30.11):
```bash
# Wazuh Indexer kurulumu
sudo apt update
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

sudo apt update

# Pre-configured indexer kurulumu
sudo apt install wazuh-indexer -y

# Indexer konfigürasyonu
sudo nano /etc/wazuh-indexer/opensearch.yml

# Konfigürasyon içeriği:
cluster.name: wazuh-cluster
node.name: wazuh-indexer
path.data: /var/lib/wazuh-indexer
path.logs: /var/log/wazuh-indexer
network.host: 192.168.30.11
http.port: 9200
discovery.seed_hosts: ["192.168.30.11"]
cluster.initial_master_nodes: ["wazuh-indexer"]
plugins.security.ssl.transport.pemcert_filepath: /etc/wazuh-indexer/certs/wazuh-indexer.pem
plugins.security.ssl.transport.pemkey_filepath: /etc/wazuh-indexer/certs/wazuh-indexer-key.pem
plugins.security.ssl.transport.pemtrustedcas_filepath: /etc/wazuh-indexer/certs/root-ca.pem
plugins.security.ssl.http.enabled: true
plugins.security.ssl.http.pemcert_filepath: /etc/wazuh-indexer/certs/wazuh-indexer.pem
plugins.security.ssl.http.pemkey_filepath: /etc/wazuh-indexer/certs/wazuh-indexer-key.pem
plugins.security.ssl.http.pemtrustedcas_filepath: /etc/wazuh-indexer/certs/root-ca.pem

# Indexer'ı başlat
sudo systemctl daemon-reload
sudo systemctl enable wazuh-indexer
sudo systemctl start wazuh-indexer

# Firewall
sudo ufw allow 9200/tcp
```

#### Wazuh Dashboard VM (192.168.30.12):
```bash
# Wazuh Dashboard kurulumu
sudo apt update
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

sudo apt update
sudo apt install wazuh-dashboard -y

# Dashboard konfigürasyonu
sudo nano /etc/wazuh-dashboard/opensearch_dashboards.yml

# Konfigürasyon içeriği:
server.host: 192.168.30.12
server.port: 443
opensearch.hosts: ["https://192.168.30.11:9200"]
opensearch.ssl.verificationMode: certificate
opensearch.ssl.certificateAuthorities: ["/etc/wazuh-dashboard/certs/root-ca.pem"]
opensearch.ssl.certificate: "/etc/wazuh-dashboard/certs/wazuh-dashboard.pem"
opensearch.ssl.key: "/etc/wazuh-dashboard/certs/wazuh-dashboard-key.pem"

# Dashboard'u başlat
sudo systemctl daemon-reload
sudo systemctl enable wazuh-dashboard
sudo systemctl start wazuh-dashboard

# Firewall
sudo ufw allow 443/tcp
```

### 2.2 Wazuh SSL Sertifikalarını Oluşturma

```bash
# Wazuh Manager'da sertifika oluşturma aracını çalıştır
sudo /usr/share/wazuh-indexer/plugins/opensearch-security/tools/install_demo_configuration.sh -y

# Sertifikaları diğer node'lara kopyala
# (Bu adımı her bir VM için tekrarla)
```

---

## 🔧 **3. KUBERNETES CLUSTER'LARDA WAZUH AGENT KURULUMU**

### 3.1 Her K8s Node'da Wazuh Agent Kurulumu

#### Tüm Kubernetes Node'larda (Test + Prod-A + Prod-B):
```bash
# Wazuh agent kurulumu
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

sudo apt update
sudo WAZUH_MANAGER="192.168.30.10" apt install wazuh-agent -y

# Agent konfigürasyonu
sudo nano /var/ossec/etc/ossec.conf

# Her node için farklı group assign et:
# Test cluster: <group>test-cluster</group>
# Prod-A cluster: <group>prod-a-cluster</group>  
# Prod-B cluster: <group>prod-b-cluster</group>

# Agent'ı başlat
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

# Agent durumunu kontrol et
sudo systemctl status wazuh-agent
```

### 3.2 Kubernetes Events için Wazuh Integration

#### K8s API Server Monitoring:
```yaml
# k8s-audit-policy.yaml (Her master node'da)
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  resources:
  - group: ""
    resources: ["pods", "services"]
  - group: "apps"
    resources: ["deployments", "replicasets"]
  - group: "networking.k8s.io"
    resources: ["networkpolicies"]
  namespaces: ["default", "kube-system", "production", "staging"]

- level: Request
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
  namespaces: ["production", "staging"]

- level: Request
  users: ["system:anonymous"]
  
- level: Request
  verbs: ["create", "update", "patch", "delete"]
```

#### API Server Audit Log Konfigürasyonu:
```bash
# Her master node'da /etc/kubernetes/manifests/kube-apiserver.yaml düzenle
sudo nano /etc/kubernetes/manifests/kube-apiserver.yaml

# Bu satırları ekle:
spec:
  containers:
  - command:
    - kube-apiserver
    - --audit-log-path=/var/log/kubernetes/audit.log
    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml
    - --audit-log-maxage=30
    - --audit-log-maxbackup=10
    - --audit-log-maxsize=100
    volumeMounts:
    - name: audit-policy
      mountPath: /etc/kubernetes/audit-policy.yaml
      readOnly: true
    - name: audit-logs
      mountPath: /var/log/kubernetes
  volumes:
  - name: audit-policy
    hostPath:
      path: /etc/kubernetes/audit-policy.yaml
  - name: audit-logs
    hostPath:
      path: /var/log/kubernetes
```

### 3.3 Container Runtime Monitoring

#### Wazuh Agent Konfigürasyonu (ossec.conf):
```xml
<!-- Her K8s node'da /var/ossec/etc/ossec.conf -->
<ossec_config>
  <!-- Kubernetes audit logs -->
  <localfile>
    <log_format>json</log_format>
    <location>/var/log/kubernetes/audit.log</location>
  </localfile>

  <!-- Container logs -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/containers/*.log</location>
  </localfile>

  <!-- Kubelet logs -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/syslog</location>
  </localfile>

  <!-- Docker/Containerd logs -->
  <localfile>
    <log_format>json</log_format>
    <location>/var/log/docker.log</location>
  </localfile>

  <!-- Kubernetes events monitoring -->
  <wodle name="command">
    <disabled>no</disabled>
    <tag>kubernetes</tag>
    <command>kubectl get events --all-namespaces -o json</command>
    <interval>60s</interval>
    <ignore_output>no</ignore_output>
    <run_on_start>yes</run_on_start>
    <timeout>30</timeout>
  </wodle>

  <!-- Container integrity monitoring -->
  <syscheck>
    <directories check_all="yes" realtime="yes">/etc/kubernetes</directories>
    <directories check_all="yes" realtime="yes">/var/lib/kubelet</directories>
    <directories check_all="yes">/etc/docker</directories>
  </syscheck>
</ossec_config>
```

---

## 🔥 **4. WAZUH RULES VE DETECTION CONFIGURATIONS**

### 4.1 Kubernetes-Specific Rules

#### Custom Kubernetes Rules (/var/ossec/ruleset/rules/kubernetes_rules.xml):
```xml
<group name="kubernetes,">

  <!-- Kubernetes API Authentication -->
  <rule id="100001" level="5">
    <decoded_as>json</decoded_as>
    <field name="verb">get|list|create|update|patch|delete</field>
    <field name="user.username">system:anonymous</field>
    <description>Kubernetes: Anonymous user access attempt</description>
    <group>authentication_failed,kubernetes,</group>
  </rule>

  <!-- Kubernetes Privileged Container -->
  <rule id="100002" level="7">
    <decoded_as>json</decoded_as>
    <field name="verb">create</field>
    <field name="objectRef.resource">pods</field>
    <field name="requestObject.spec.securityContext.privileged">true</field>
    <description>Kubernetes: Privileged container created</description>
    <group>kubernetes,privilege_escalation,</group>
  </rule>

  <!-- Kubernetes Secret Access -->
  <rule id="100003" level="8">
    <decoded_as>json</decoded_as>
    <field name="verb">get|list</field>
    <field name="objectRef.resource">secrets</field>
    <field name="user.username">!system:serviceaccount</field>
    <description>Kubernetes: Direct secret access by user</description>
    <group>kubernetes,data_loss,</group>
  </rule>

  <!-- Kubernetes Exec into Pod -->
  <rule id="100004" level="6">
    <decoded_as>json</decoded_as>
    <field name="verb">create</field>
    <field name="objectRef.subresource">exec</field>
    <description>Kubernetes: Pod exec access</description>
    <group>kubernetes,command_execution,</group>
  </rule>

  <!-- Failed Pod Creation -->
  <rule id="100005" level="4">
    <decoded_as>json</decoded_as>
    <field name="verb">create</field>
    <field name="objectRef.resource">pods</field>
    <field name="responseStatus.code">403|401</field>
    <description>Kubernetes: Failed pod creation attempt</description>
    <group>kubernetes,authentication_failed,</group>
  </rule>

</group>
```

### 4.2 Container Security Rules

#### Container Anomaly Detection Rules:
```xml
<group name="docker,container,">

  <!-- Container Breakout Attempt -->
  <rule id="100010" level="10">
    <if_sid>5301</if_sid>
    <match>docker|containerd</match>
    <field name="syscall">ptrace|mount|unshare</field>
    <description>Container: Potential breakout attempt detected</description>
    <group>container_security,privilege_escalation,</group>
  </rule>

  <!-- Suspicious Network Activity -->
  <rule id="100011" level="7">
    <if_sid>5300</if_sid>
    <match>/proc/net/tcp|/proc/net/udp</match>
    <description>Container: Suspicious network enumeration</description>
    <group>container_security,reconnaissance,</group>
  </rule>

  <!-- Cryptocurrency Mining Detection -->
  <rule id="100012" level="9">
    <if_sid>2501</if_sid>
    <match>xmrig|monero|ethereum|bitcoin|cryptonight</match>
    <description>Container: Cryptocurrency mining detected</description>
    <group>container_security,malware,</group>
  </rule>

</group>
```

### 4.3 Network Segmentation Monitoring

#### Network Policy Violation Detection:
```xml
<group name="network,segmentation,">

  <!-- Cross-Zone Communication -->
  <rule id="100020" level="6">
    <if_sid>5716</if_sid>
    <field name="src_ip">192.168.20</field>
    <field name="dst_ip">192.168.40</field>
    <description>Network: Application zone accessing database zone directly</description>
    <group>network_policy,policy_violation,</group>
  </rule>

  <!-- DMZ to Internal Communication -->
  <rule id="100021" level="8">
    <if_sid>5716</if_sid>
    <field name="src_ip">192.168.10</field>
    <field name="dst_ip">192.168.30|192.168.40</field>
    <description>Network: DMZ zone accessing internal networks</description>
    <group>network_policy,policy_violation,</group>
  </rule>

  <!-- Management Zone External Access -->
  <rule id="100022" level="9">
    <if_sid>5716</if_sid>
    <field name="src_ip">!192.168.30</field>
    <field name="dst_ip">192.168.30</field>
    <field name="dst_port">22|443|9200</field>
    <description>Network: External access to management zone</description>
    <group>network_policy,unauthorized_access,</group>
  </rule>

</group>
```

---

## 📊 **5. WAZUH DASHBOARDS VE MONITORING**

### 5.1 Custom Kubernetes Dashboard

#### Wazuh Dashboard'da Kubernetes Overview:
```json
{
  "version": "4.5.4",
  "objects": [
    {
      "id": "kubernetes-overview",
      "type": "dashboard",
      "attributes": {
        "title": "Kubernetes Security Overview",
        "description": "Kubernetes cluster security monitoring",
        "panelsJSON": "[{\"version\":\"4.5.4\",\"gridData\":{\"x\":0,\"y\":0,\"w\":24,\"h\":15},\"panelIndex\":\"1\",\"embeddableConfig\":{},\"panelRefName\":\"panel_1\"}]",
        "timeRestore": false,
        "kibanaSavedObjectMeta": {
          "searchSourceJSON": "{\"query\":{\"match_all\":{}},\"filter\":[]}"
        }
      }
    }
  ]
}
```

### 5.2 Alerting Configuration

#### Slack Integration (/var/ossec/etc/ossec.conf):
```xml
<ossec_config>
  <integration>
    <name>slack</name>
    <hook_url>YOUR_SLACK_WEBHOOK_URL</hook_url>
    <alert_format>json</alert_format>
    <level>7</level>
    <group>kubernetes,container_security,network_policy</group>
  </integration>

  <!-- Email alerts for critical events -->
  <global>
    <email_notification>yes</email_notification>
    <smtp_server>smtp.gmail.com</smtp_server>
    <email_from>wazuh@yourdomain.com</email_from>
    <email_to>admin@yourdomain.com</email_to>
  </global>

  <alerts>
    <log_alert_level>1</log_alert_level>
    <email_alert_level>7</email_alert_level>
  </alerts>
</ossec_config>
```

---

## 🔧 **6. NETWORK FIREWALL RULES VE ACCESS CONTROL**

### 6.1 UFW Firewall Rules (Her VM için)

#### DMZ Zone (192.168.10.0/24):
```bash
# Load Balancer VM
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing

# HTTP/HTTPS traffic
sudo ufw allow from any to any port 80
sudo ufw allow from any to any port 443

# Backend communication
sudo ufw allow from 192.168.20.0/24 to any port 8080
sudo ufw allow from 192.168.21.0/24 to any port 8080
sudo ufw allow from 192.168.22.0/24 to any port 8080

# Management access
sudo ufw allow from 192.168.30.0/24 to any port 22
```

#### Application Zones (192.168.20-22.0/24):
```bash
# Kubernetes cluster nodes
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Kubernetes API
sudo ufw allow from 192.168.20.0/24 to any port 6443
sudo ufw allow from 192.168.21.0/24 to any port 6443
sudo ufw allow from 192.168.22.0/24 to any port 6443

# Kubelet API
sudo ufw allow from 192.168.20.0/24 to any port 10250
sudo ufw allow from 192.168.21.0/24 to any port 10250
sudo ufw allow from 192.168.22.0/24 to any port 10250

# NodePort services
sudo ufw allow from 192.168.10.0/24 to any port 30000:32767

# Database access (only from app zones)
sudo ufw allow from 192.168.20.0/24 to 192.168.40.0/24 port 5432
sudo ufw allow from 192.168.21.0/24 to 192.168.40.0/24 port 5432
sudo ufw allow from 192.168.22.0/24 to 192.168.40.0/24 port 5432

# Wazuh agent communication
sudo ufw allow from any to 192.168.30.10 port 1514
sudo ufw allow from any to 192.168.30.10 port 1515

# Management SSH
sudo ufw allow from 192.168.30.0/24 to any port 22
```

#### Management Zone (192.168.30.0/24):
```bash
# Management services
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Wazuh Manager
sudo ufw allow from 192.168.20.0/24 to any port 1514
sudo ufw allow from 192.168.21.0/24 to any port 1514
sudo ufw allow from 192.168.22.0/24 to any port 1514
sudo ufw allow from 192.168.20.0/24 to any port 1515
sudo ufw allow from 192.168.21.0/24 to any port 1515
sudo ufw allow from 192.168.22.0/24 to any port 1515

# Wazuh Dashboard
sudo ufw allow from 192.168.10.0/24 to any port 443

# Prometheus/Grafana
sudo ufw allow from 192.168.10.0/24 to any port 3000
sudo ufw allow from 192.168.20.0/24 to any port 9090
sudo ufw allow from 192.168.21.0/24 to any port 9090
sudo ufw allow from 192.168.22.0/24 to any port 9090

# Internal SSH
sudo ufw allow from 192.168.30.0/24 to any port 22
```

#### Database Zone (192.168.40.0/24):
```bash
# Database servers
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing

# PostgreSQL access
sudo ufw allow from 192.168.20.0/24 to any port 5432
sudo ufw allow from 192.168.21.0/24 to any port 5432
sudo ufw allow from 192.168.22.0/24 to any port 5432

# Redis access
sudo ufw allow from 192.168.20.0/24 to any port 6379
sudo ufw allow from 192.168.21.0/24 to any port 6379
sudo ufw allow from 192.168.22.0/24 to any port 6379

# Backup access
sudo ufw allow from 192.168.30.0/24 to any port 22

# No external access allowed
sudo ufw deny from any to any port 5432
sudo ufw deny from any to any port 6379
```

### 6.2 Kubernetes Network Policies

#### Namespace Isolation:
```yaml
# namespace-isolation.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-nginx
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: my-app
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
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-database-access
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: my-app
  policyTypes:
  - Egress
  egress:
  # Database access
  - to: []
    ports:
    - protocol: TCP
      port: 5432
    - protocol: TCP
      port: 6379
  # DNS resolution
  - to: []
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
  # HTTPS for external APIs
  - to: []
    ports:
    - protocol: TCP
      port: 443
```

---

## 🚨 **7. INCIDENT RESPONSE VE AUTOMATED REMEDIATION**

### 7.1 Automated Response Scripts

#### Active Response (/var/ossec/active-response/bin/kubernetes-remediation.sh):
```bash
#!/bin/bash
# Kubernetes incident response script

ACTION=$1
USER=$2
IP=$3
ALERTID=$4
RULEID=$5

LOCAL=`dirname $0`;
cd $LOCAL
cd ../
PWD=`pwd`

case "$ACTION" in
    add)
        case "$RULEID" in
            # Suspicious pod creation
            "100002")
                echo "$(date) - Deleting privileged pod from $IP" >> /var/ossec/logs/active-responses.log
                kubectl delete pod --field-selector spec.nodeName=$IP --all-namespaces --selector=privileged=true
                ;;
            # Anonymous access attempt
            "100001")
                echo "$(date) - Blocking anonymous access from $IP" >> /var/ossec/logs/active-responses.log
                iptables -I INPUT -s $IP -j DROP
                ;;
            # Container breakout attempt
            "100010")
                echo "$(date) - Quarantining container on node $IP" >> /var/ossec/logs/active-responses.log
                kubectl cordon $IP
                kubectl drain $IP --delete-emptydir-data --force --ignore-daemonsets
                ;;
        esac
        ;;
    delete)
        case "$RULEID" in
            "100001")
                echo "$(date) - Removing IP block for $IP" >> /var/ossec/logs/active-responses.log
                iptables -D INPUT -s $IP -j DROP
                ;;
            "100010")
                echo "$(date) - Uncordoning node $IP" >> /var/ossec/logs/active-responses.log
                kubectl uncordon $IP
                ;;
        esac
        ;;
esac

exit 0
```

#### Active Response Configuration (/var/ossec/etc/ossec.conf):
```xml
<ossec_config>
  <command>
    <name>kubernetes-remediation</name>
    <executable>kubernetes-remediation.sh</executable>
    <expect>srcip</expect>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <active-response>
    <disabled>no</disabled>
    <command>kubernetes-remediation</command>
    <location>local</location>
    <rules_id>100001,100002,100010</rules_id>
    <timeout>300</timeout>
  </active-response>
</ossec_config>
```

### 7.2 Threat Intelligence Integration

#### MISP Integration (/var/ossec/etc/ossec.conf):
```xml
<ossec_config>
  <wodle name="vulnerability-detector">
    <disabled>no</disabled>
    <interval>5m</interval>
    <ignore_time>6h</ignore_time>
    <run_on_start>yes</run_on_start>
    
    <!-- CVE feeds -->
    <provider name="canonical">
      <enabled>yes</enabled>
      <os>trusty,xenial,bionic,focal,jammy</os>
      <update_interval>1h</update_interval>
    </provider>
    
    <provider name="debian">
      <enabled>yes</enabled>
      <os>buster,bullseye,bookworm</os>
      <update_interval>1h</update_interval>
    </provider>
    
    <provider name="redhat">
      <enabled>yes</enabled>
      <os>5,6,7,8,9</os>
      <update_interval>1h</update_interval>
    </provider>
  </wodle>

  <!-- Custom threat intelligence -->
  <wodle name="command">
    <disabled>no</disabled>
    <tag>threat-intel</tag>
    <command>/var/ossec/wodles/threat-intel.py</command>
    <interval>1h</interval>
    <ignore_output>no</ignore_output>
    <run_on_start>yes</run_on_start>
    <timeout>60</timeout>
  </wodle>
</ossec_config>
```

---

## 📊 **8. PERFORMANCE MONITORING VE OPTIMIZATION**

### 8.1 Wazuh Performance Tuning

#### Manager Performance Optimization (/var/ossec/etc/internal_options.conf):
```conf
# Logcollector
logcollector.remote_commands=1
logcollector.loop_timeout=2
logcollector.open_file_attempts=8
logcollector.vcheck_files=64

# Analysis
analysisd.event_threads=4
analysisd.syscheck_threads=2
analysisd.syscollector_threads=2
analysisd.rootcheck_threads=2
analysisd.sca_threads=2
analysisd.hostinfo_threads=2
analysisd.winevt_threads=2

# Remote daemon
remoted.worker_pool=8
remoted.request_pool=1024
remoted.request_timeout=10
remoted.response_timeout=10
remoted.max_attempts=3

# Database
wdb.worker_pool_size=8
wdb.commit_time=60
wdb.backup_time=86400
```

#### Indexer Performance Tuning (/etc/wazuh-indexer/opensearch.yml):
```yaml
# Memory settings
indices.memory.index_buffer_size: 30%
indices.memory.min_index_buffer_size: 96mb

# Search settings
search.max_buckets: 65536
search.max_open_scroll_context: 500

# Thread pools
thread_pool:
  write:
    size: 4
    queue_size: 1000
  search:
    size: 8
    queue_size: 1000
  get:
    size: 4
    queue_size: 1000

# Cache settings
indices.queries.cache.size: 15%
indices.fielddata.cache.size: 30%
```

### 8.2 Network Performance Monitoring

#### Bandwidth Monitoring Script (/usr/local/bin/network-monitor.sh):
```bash
#!/bin/bash

WAZUH_MANAGER="192.168.30.10"
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Network interface monitoring
for interface in $(ls /sys/class/net/ | grep -v lo); do
    RX_BYTES=$(cat /sys/class/net/$interface/statistics/rx_bytes)
    TX_BYTES=$(cat /sys/class/net/$interface/statistics/tx_bytes)
    RX_PACKETS=$(cat /sys/class/net/$interface/statistics/rx_packets)
    TX_PACKETS=$(cat /sys/class/net/$interface/statistics/tx_packets)
    RX_ERRORS=$(cat /sys/class/net/$interface/statistics/rx_errors)
    TX_ERRORS=$(cat /sys/class/net/$interface/statistics/tx_errors)
    
    # Send to Wazuh
    logger -t wazuh-network "[$TIMESTAMP] [$HOSTNAME] [$interface] RX_BYTES=$RX_BYTES TX_BYTES=$TX_BYTES RX_PACKETS=$RX_PACKETS TX_PACKETS=$TX_PACKETS RX_ERRORS=$RX_ERRORS TX_ERRORS=$TX_ERRORS"
done

# Connection tracking
ESTABLISHED=$(netstat -an | grep ESTABLISHED | wc -l)
LISTEN=$(netstat -an | grep LISTEN | wc -l)
TIME_WAIT=$(netstat -an | grep TIME_WAIT | wc -l)

logger -t wazuh-network "[$TIMESTAMP] [$HOSTNAME] [CONNECTIONS] ESTABLISHED=$ESTABLISHED LISTEN=$LISTEN TIME_WAIT=$TIME_WAIT"
```

---

## 🔒 **9. COMPLIANCE VE SECURITY BASELINES**

### 9.1 CIS Kubernetes Benchmark

#### CIS Compliance Check Script (/usr/local/bin/k8s-cis-check.sh):
```bash
#!/bin/bash

# CIS Kubernetes Benchmark automated checks
LOG_FILE="/var/log/kubernetes-cis-compliance.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TIMESTAMP] Starting CIS Kubernetes Benchmark checks" >> $LOG_FILE

# 1.1.1 Ensure that the API server pod specification file permissions are set to 644 or more restrictive
API_SERVER_PERM=$(stat -c %a /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null)
if [ "$API_SERVER_PERM" -le "644" ]; then
    echo "[$TIMESTAMP] PASS: API server permissions: $API_SERVER_PERM" >> $LOG_FILE
else
    echo "[$TIMESTAMP] FAIL: API server permissions: $API_SERVER_PERM (should be 644 or less)" >> $LOG_FILE
    logger -p auth.warning -t k8s-cis "CIS-1.1.1 FAIL: API server file permissions too permissive"
fi

# 1.2.1 Ensure that the --anonymous-auth argument is set to false
ANON_AUTH=$(ps aux | grep kube-apiserver | grep -o '\--anonymous-auth=[^[:space:]]*')
if [[ "$ANON_AUTH" == "--anonymous-auth=false" ]]; then
    echo "[$TIMESTAMP] PASS: Anonymous auth disabled" >> $LOG_FILE
else
    echo "[$TIMESTAMP] FAIL: Anonymous auth not properly disabled" >> $LOG_FILE
    logger -p auth.warning -t k8s-cis "CIS-1.2.1 FAIL: Anonymous authentication not disabled"
fi

# 1.2.2 Ensure that the --basic-auth-file argument is not set
BASIC_AUTH=$(ps aux | grep kube-apiserver | grep '\--basic-auth-file')
if [ -z "$BASIC_AUTH" ]; then
    echo "[$TIMESTAMP] PASS: Basic auth file not configured" >> $LOG_FILE
else
    echo "[$TIMESTAMP] FAIL: Basic auth file is configured" >> $LOG_FILE
    logger -p auth.warning -t k8s-cis "CIS-1.2.2 FAIL: Basic authentication file configured"
fi

# 4.2.1 Ensure that the kubelet service file permissions are set to 644 or more restrictive
KUBELET_PERM=$(stat -c %a /etc/systemd/system/kubelet.service 2>/dev/null)
if [ "$KUBELET_PERM" -le "644" ]; then
    echo "[$TIMESTAMP] PASS: Kubelet service permissions: $KUBELET_PERM" >> $LOG_FILE
else
    echo "[$TIMESTAMP] FAIL: Kubelet service permissions: $KUBELET_PERM (should be 644 or less)" >> $LOG_FILE
    logger -p auth.warning -t k8s-cis "CIS-4.2.1 FAIL: Kubelet service file permissions too permissive"
fi

echo "[$TIMESTAMP] CIS Kubernetes Benchmark checks completed" >> $LOG_FILE
```

### 9.2 PCI DSS Compliance (Eğer ödeme sistemi varsa)

#### PCI DSS Network Segmentation Validation:
```yaml
# pci-network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: pci-cardholder-data-isolation
  namespace: payment
spec:
  podSelector:
    matchLabels:
      app: payment-processor
      pci-scope: "true"
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Only allow connections from API gateway
  - from:
    - namespaceSelector:
        matchLabels:
          name: api-gateway
    - podSelector:
        matchLabels:
          app: api-gateway
    ports:
    - protocol: TCP
      port: 8443
  egress:
  # Only allow connections to payment database
  - to:
    - namespaceSelector:
        matchLabels:
          name: payment-db
    ports:
    - protocol: TCP
      port: 5432
  # DNS resolution
  - to: []
    ports:
    - protocol: UDP
      port: 53
```

---

## 📈 **10. MONITORING DASHBOARDS VE REPORTING**

### 10.1 Grafana Dashboard for Network Segmentation

#### Network Segmentation Monitoring Dashboard (JSON):
```json
{
  "dashboard": {
    "title": "Network Segmentation Security Dashboard",
    "panels": [
      {
        "title": "Cross-Zone Traffic",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(wazuh_events_total{rule_id=\"100020\"}[5m])",
            "legendFormat": "App→DB Direct Access"
          },
          {
            "expr": "rate(wazuh_events_total{rule_id=\"100021\"}[5m])",
            "legendFormat": "DMZ→Internal Access"
          }
        ]
      },
      {
        "title": "Kubernetes Security Events",
        "type": "table",
        "targets": [
          {
            "expr": "wazuh_events_total{group=~\"kubernetes.*\"}",
            "format": "table"
          }
        ]
      },
      {
        "title": "Network Zone Health",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=\"node-exporter\", instance=~\"192.168.20.*\"}",
            "legendFormat": "Application Zone"
          },
          {
            "expr": "up{job=\"node-exporter\", instance=~\"192.168.30.*\"}",
            "legendFormat": "Management Zone"
          }
        ]
      }
    ]
  }
}
```

### 10.2 Automated Security Reports

#### Daily Security Report Script (/usr/local/bin/security-report.sh):
```bash
#!/bin/bash

REPORT_DATE=$(date '+%Y-%m-%d')
REPORT_FILE="/var/log/security-reports/daily-report-$REPORT_DATE.html"
WAZUH_API="https://192.168.30.12/api"

# Create report directory
mkdir -p /var/log/security-reports

# Generate HTML report
cat > $REPORT_FILE << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Daily Security Report - $REPORT_DATE</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 10px; }
        .critical { color: red; font-weight: bold; }
        .warning { color: orange; }
        .info { color: blue; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Daily Security Report</h1>
        <p>Report Date: $REPORT_DATE</p>
        <p>Generated: $(date)</p>
    </div>

    <h2>Executive Summary</h2>
    <table>
        <tr><th>Metric</th><th>Count</th><th>Status</th></tr>
EOF

# Get security metrics from Wazuh
CRITICAL_EVENTS=$(grep -c "level.*1[0-5]" /var/ossec/logs/alerts/alerts.json | tail -1)
WARNING_EVENTS=$(grep -c "level.*[7-9]" /var/ossec/logs/alerts/alerts.json | tail -1)
TOTAL_EVENTS=$(wc -l < /var/ossec/logs/alerts/alerts.json)

echo "        <tr><td>Critical Events</td><td class='critical'>$CRITICAL_EVENTS</td><td>$([ $CRITICAL_EVENTS -eq 0 ] && echo "Good" || echo "Review Required")</td></tr>" >> $REPORT_FILE
echo "        <tr><td>Warning Events</td><td class='warning'>$WARNING_EVENTS</td><td>$([ $WARNING_EVENTS -lt 10 ] && echo "Normal" || echo "High Activity")</td></tr>" >> $REPORT_FILE
echo "        <tr><td>Total Events</td><td>$TOTAL_EVENTS</td><td>Active</td></tr>" >> $REPORT_FILE

cat >> $REPORT_FILE << EOF
    </table>

    <h2>Network Segmentation Status</h2>
    <table>
        <tr><th>Zone</th><th>Status</th><th>Violations</th></tr>
EOF

# Check network zones
for zone in "192.168.20" "192.168.21" "192.168.22" "192.168.30" "192.168.40"; do
    VIOLATIONS=$(grep -c "$zone" /var/ossec/logs/alerts/alerts.json | grep "network_policy" || echo "0")
    STATUS=$([ $VIOLATIONS -eq 0 ] && echo "Compliant" || echo "Violations Detected")
    echo "        <tr><td>$zone.0/24</td><td>$STATUS</td><td>$VIOLATIONS</td></tr>" >> $REPORT_FILE
done

cat >> $REPORT_FILE << EOF
    </table>

    <h2>Kubernetes Security Events</h2>
    <table>
        <tr><th>Event Type</th><th>Count</th><th>Last Occurrence</th></tr>
EOF

# Kubernetes-specific events
K8S_ANON=$(grep -c "100001" /var/ossec/logs/alerts/alerts.json || echo "0")
K8S_PRIV=$(grep -c "100002" /var/ossec/logs/alerts/alerts.json || echo "0")
K8S_SECRET=$(grep -c "100003" /var/ossec/logs/alerts/alerts.json || echo "0")

echo "        <tr><td>Anonymous Access Attempts</td><td>$K8S_ANON</td><td>$([ $K8S_ANON -gt 0 ] && grep "100001" /var/ossec/logs/alerts/alerts.json | tail -1 | jq -r '.timestamp' || echo "None")</td></tr>" >> $REPORT_FILE
echo "        <tr><td>Privileged Container Creation</td><td>$K8S_PRIV</td><td>$([ $K8S_PRIV -gt 0 ] && grep "100002" /var/ossec/logs/alerts/alerts.json | tail -1 | jq -r '.timestamp' || echo "None")</td></tr>" >> $REPORT_FILE
echo "        <tr><td>Secret Access Events</td><td>$K8S_SECRET</td><td>$([ $K8S_SECRET -gt 0 ] && grep "100003" /var/ossec/logs/alerts/alerts.json | tail -1 | jq -r '.timestamp' || echo "None")</td></tr>" >> $REPORT_FILE

cat >> $REPORT_FILE << EOF
    </table>

    <h2>Recommendations</h2>
    <ul>
EOF

# Generate recommendations
if [ $CRITICAL_EVENTS -gt 0 ]; then
    echo "        <li class='critical'>Immediate attention required: $CRITICAL_EVENTS critical security events detected</li>" >> $REPORT_FILE
fi

if [ $K8S_ANON -gt 5 ]; then
    echo "        <li class='warning'>High number of anonymous access attempts detected. Review API server configuration</li>" >> $REPORT_FILE
fi

if [ $K8S_PRIV -gt 0 ]; then
    echo "        <li class='warning'>Privileged containers detected. Review pod security policies</li>" >> $REPORT_FILE
fi

cat >> $REPORT_FILE << EOF
        <li class='info'>Regular security baseline scan recommended</li>
        <li class='info'>Review and update network policies quarterly</li>
    </ul>

    <p><em>This report was automatically generated by the Wazuh SIEM system.</em></p>
</body>
</html>
EOF

# Email the report
echo "Daily Security Report attached" | mail -s "Security Report - $REPORT_DATE" -A $REPORT_FILE admin@yourdomain.com

echo "Security report generated: $REPORT_FILE"
```
