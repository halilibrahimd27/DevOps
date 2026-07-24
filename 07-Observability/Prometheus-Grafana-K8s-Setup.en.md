---
description: "Documentation for installing Prometheus and Grafana on Kubernetes: system requirements, prerequisites, Helm installation steps, service configuration, access, and troubleshooting."
tags:
  - Observability
  - Prometheus
  - Kubernetes
  - Helm
  - Monitoring
---
# Prometheus + Grafana Kubernetes Installation Documentation

> *"Setting up the monitoring stack isn't the point — making it secure, durable, and alert-generating is the real work; the default Helm install is not production-ready."*

## 📋 Table of Contents
- [System Requirements](#system-requirements)
- [Prerequisites](#prerequisites)
- [Installation Steps](#installation-steps)
- [Existing Installation Check](#existing-installation-check)
- [Service Configuration](#service-configuration)
- [Access and Usage](#access-and-usage)
- [Troubleshooting](#troubleshooting)
- [Useful Commands](#useful-commands)

---

## 🔧 System Requirements

### Minimum System Requirements
- **Kubernetes Cluster**: v1.28+
- **Helm**: v3.18+
- **Storage Class**: Supports dynamic provisioning
- **Minimum RAM**: 4GB (cluster-wide)
- **Minimum CPU**: 2 vCPU (cluster-wide)
- **Disk**: 50GB+ (for monitoring data)

### Tested Environment
```
- Kubernetes: v1.33.1 (master), v1.28.15 (worker)
- Helm: v3.18.3
- Storage Class: local-path
- Node Count: 3 (1 master, 2 worker)
- Operating System: Ubuntu 22.04.5 LTS
```

---

## ✅ Prerequisites

### 1. Kubernetes Cluster Check
```bash
# Cluster status
kubectl cluster-info

# Node status
kubectl get nodes -o wide

# Storage class check
kubectl get storageclass
```

### 2. Helm Installation Check
```bash
# Helm version
helm version

# Helm repos
helm repo list
```

### 3. Required Namespace
```bash
# Create monitoring namespace (if it doesn't exist)
kubectl create namespace monitoring
```

---

## 🚀 Installation Steps

### Option 1: Quick Install (Recommended)

#### 1.1 Preparing the Helm Repository
```bash
# Add the Prometheus community repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

#### 1.2 Automated Installation Script
```bash
#!/bin/bash
# prometheus-install.sh

echo "🚀 Starting Prometheus Stack Installation..."

# Update Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install Prometheus stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=local-path \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=10Gi \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.storageClassName=local-path \
  --set grafana.persistence.size=5Gi \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=32000 \
  --set prometheus.service.type=NodePort \
  --set prometheus.service.nodePort=32001 \
  --set alertmanager.service.type=NodePort \
  --set alertmanager.service.nodePort=32002

echo "✅ Installation complete!"
```

### Option 2: Customized Install

#### 2.1 Custom Values File
```yaml
# prometheus-values.yaml

# Grafana Configuration
grafana:
  adminPassword: "<GRAFANA_ADMIN_PASSWORD>"   # prod: use admin.existingSecret (see Anti-Pattern)
  
  persistence:
    enabled: true
    storageClassName: local-path
    size: 5Gi
    
  service:
    type: NodePort
    nodePort: 32000
    
  grafana.ini:
    server:
      root_url: "http://localhost:32000"
    security:
      allow_embedding: true
      
  defaultDashboardsEnabled: true
  
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"

# Prometheus Configuration
prometheus:
  prometheusSpec:
    retention: 15d
    retentionSize: "50GiB"
    
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: local-path
          resources:
            requests:
              storage: 10Gi
              
    resources:
      requests:
        memory: "512Mi"
        cpu: "200m"
      limits:
        memory: "1Gi"
        cpu: "500m"
        
    scrapeInterval: 30s
    evaluationInterval: 30s
    
    externalLabels:
      cluster: "my-k8s-cluster"
      
  service:
    type: NodePort
    nodePort: 32001

# AlertManager Configuration
alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: local-path
          resources:
            requests:
              storage: 2Gi
              
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "128Mi"
        cpu: "100m"
        
  service:
    type: NodePort
    nodePort: 32002

# Other Settings
nodeExporter:
  enabled: true
  
kubeStateMetrics:
  enabled: true

defaultRules:
  create: true
  rules:
    alertmanager: true
    etcd: false
    configReloaders: true
    general: true
    k8s: true
    kubeApiserverAvailability: true
    kubeApiserverSlos: true
    kubeControllerManager: false
    kubeSchedulerAlerting: false
    kubeSchedulerRecording: false
    kubeStateMetrics: true
    network: true
    node: true
    nodeExporterAlerting: true
    nodeExporterRecording: true
    prometheus: true
    prometheusOperator: true
```

#### 2.2 Custom Install
```bash
# Install with custom values
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml
```

---

## 🔍 Existing Installation Check

### Status Check Script
```bash
#!/bin/bash
# prometheus-status.sh

echo "🔍 PROMETHEUS STACK STATUS REPORT"
echo "================================="

# Helm release status
echo ""
echo "📦 Helm Release Status:"
helm list -n monitoring

# Pod statuses
echo ""
echo "🚀 Pod Statuses:"
kubectl get pods -n monitoring -o wide

# Service and port info
echo ""
echo "🌐 Services and Ports:"
kubectl get svc -n monitoring

# Storage status
echo ""
echo "💾 Storage Status:"
kubectl get pvc -n monitoring

# Access info
echo ""
echo "🔗 Access Info:"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Master Node IP: $NODE_IP"

# Port check
GRAFANA_PORT=$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
PROMETHEUS_SVC_TYPE=$(kubectl get svc prometheus-kube-prometheus-prometheus -n monitoring -o jsonpath='{.spec.type}' 2>/dev/null)
ALERTMANAGER_SVC_TYPE=$(kubectl get svc prometheus-kube-prometheus-alertmanager -n monitoring -o jsonpath='{.spec.type}' 2>/dev/null)

echo ""
echo "🌍 Web Interfaces:"
if [ ! -z "$GRAFANA_PORT" ]; then
    echo "   📊 Grafana:      http://$NODE_IP:$GRAFANA_PORT ✅"
else
    echo "   📊 Grafana:      ClusterIP (no external access) ❌"
fi

if [ "$PROMETHEUS_SVC_TYPE" = "NodePort" ]; then
    PROMETHEUS_PORT=$(kubectl get svc prometheus-kube-prometheus-prometheus -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')
    echo "   📈 Prometheus:   http://$NODE_IP:$PROMETHEUS_PORT ✅"
else
    echo "   📈 Prometheus:   ClusterIP (no external access) ❌"
fi

if [ "$ALERTMANAGER_SVC_TYPE" = "NodePort" ]; then
    ALERTMANAGER_PORT=$(kubectl get svc prometheus-kube-prometheus-alertmanager -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')
    echo "   🚨 AlertManager: http://$NODE_IP:$ALERTMANAGER_PORT ✅"
else
    echo "   🚨 AlertManager: ClusterIP (no external access) ❌"
fi

# Grafana login info
echo ""
echo "🔐 Grafana Login Info:"
echo "   👤 User: admin"
echo -n "   🔑 Password: "
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode 2>/dev/null || echo "Could not retrieve password"
echo ""

# System resource usage
echo ""
echo "📊 Resource Usage:"
kubectl top pods -n monitoring 2>/dev/null || echo "Metrics server not installed"

# Last restart times
echo ""
echo "🔄 Pod Restart Info:"
kubectl get pods -n monitoring -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount,AGE:.metadata.creationTimestamp

echo ""
echo "✅ Status check complete!"
```

---

## ⚙️ Service Configuration

### Script to Convert to NodePort
```bash
#!/bin/bash
# service-nodeport.sh

echo "🔧 CONVERTING SERVICES TO NODEPORT"
echo "===================================="

# Current status
echo ""
echo "📋 Current Service Status:"
kubectl get svc -n monitoring | grep -E "(grafana|prometheus|alertmanager)" | grep -v operated

echo ""
echo "🔄 Converting services to NodePort..."

# Convert Prometheus to NodePort
echo ""
echo "📈 Updating Prometheus Service..."
kubectl patch svc prometheus-kube-prometheus-prometheus -n monitoring -p '{
  "spec": {
    "type": "NodePort",
    "ports": [
      {
        "name": "http-web",
        "port": 9090,
        "targetPort": 9090,
        "nodePort": 32001,
        "protocol": "TCP"
      }
    ]
  }
}'

# Convert AlertManager to NodePort
echo ""
echo "🚨 Updating AlertManager Service..."
kubectl patch svc prometheus-kube-prometheus-alertmanager -n monitoring -p '{
  "spec": {
    "type": "NodePort", 
    "ports": [
      {
        "name": "http-web",
        "port": 9093,
        "targetPort": 9093,
        "nodePort": 32002,
        "protocol": "TCP"
      }
    ]
  }
}'

# Update Grafana port
echo ""
echo "📊 Updating Grafana Service port..."
kubectl patch svc prometheus-grafana -n monitoring -p '{
  "spec": {
    "ports": [
      {
        "name": "http",
        "port": 80,
        "targetPort": 3000,
        "nodePort": 32000,
        "protocol": "TCP"
      }
    ]
  }
}'

# Check updated status
echo ""
echo "✅ Service updates complete!"
echo ""
echo "📋 Updated Service Status:"
kubectl get svc -n monitoring | grep -E "(grafana|prometheus|alertmanager)" | grep -v operated

# Access info
echo ""
echo "🌐 Updated Access Info:"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo "   Master Node IP: $NODE_IP"
echo ""
echo "   📊 Grafana:      http://$NODE_IP:32000"
echo "   📈 Prometheus:   http://$NODE_IP:32001" 
echo "   🚨 AlertManager: http://$NODE_IP:32002"
echo ""
echo "🔐 Grafana Login:"
echo "   👤 User: admin"
echo -n "   🔑 Password: "
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
echo ""
echo ""
echo "✨ All services are now open to external access!"
```

---

## 🌐 Access and Usage

### Web Interfaces
```
📊 Grafana:      http://<NODE-IP>:32000
📈 Prometheus:   http://<NODE-IP>:32001
🚨 AlertManager: http://<NODE-IP>:32002
```

### Grafana Login Info
```
👤 User: admin
🔑 Password: kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

### Post-Installation Tasks

#### 1. Grafana Dashboards
- **Kubernetes Cluster Monitoring Dashboard**: Overall cluster status
- **Node Exporter Full**: Node detail metrics
- **Kubernetes Pods**: Pod monitoring
- **Prometheus Stats**: Prometheus's own metrics

#### 2. Prometheus Targets Check
```
http://<NODE-IP>:32001/targets
```
Check that all targets are in "UP" status.

#### 3. AlertManager Configuration
```yaml
# To add custom alert rules
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: custom-alerts
  namespace: monitoring
spec:
  groups:
  - name: custom.rules
    rules:
    - alert: HighCPUUsage
      expr: cpu_usage_percent > 80
      for: 5m
      annotations:
        summary: "High CPU usage detected"
```

---

## 🔧 Troubleshooting

### Common Issues and Fixes

#### 1. Pods Stuck in Pending
```bash
# Storage class check
kubectl get storageclass

# PVC status
kubectl get pvc -n monitoring

# Pod events
kubectl describe pod <pod-name> -n monitoring
```

#### 2. Service External Access Issue
```bash
# Service type check
kubectl get svc -n monitoring

# Is NodePort open?
netstat -tulpn | grep :32000
```

#### 3. Grafana Password Issue
```bash
# Reset the password
kubectl delete secret prometheus-grafana -n monitoring
kubectl patch deployment prometheus-grafana -n monitoring -p '{"spec":{"template":{"spec":{"containers":[{"name":"grafana","env":[{"name":"GF_SECURITY_ADMIN_PASSWORD","value":"new-password"}]}]}}}}'
```

#### 4. Prometheus Storage Issue
```bash
# Increase the PVC size
kubectl patch pvc prometheus-prometheus-kube-prometheus-prometheus-db-prometheus-prometheus-kube-prometheus-prometheus-0 -n monitoring -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'
```

#### 5. Helm Upgrade Issue
```bash
# Get the current values
helm get values prometheus -n monitoring > current-values.yaml

# Safe upgrade
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring --values current-values.yaml
```

---

## 📚 Useful Commands

### Installation Management
```bash
# Helm releases
helm list -n monitoring

# Update the stack
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring

# Delete the stack
helm uninstall prometheus -n monitoring

# Clean up the namespace
kubectl delete namespace monitoring
```

### Monitoring and Debugging
```bash
# Pod logs
kubectl logs -f <pod-name> -n monitoring

# Service endpoints
kubectl get endpoints -n monitoring

# Resource usage
kubectl top pods -n monitoring
kubectl top nodes

# Events
kubectl get events -n monitoring --sort-by='.lastTimestamp'
```

### Backup and Restore
```bash
# Prometheus data backup
kubectl exec -it prometheus-prometheus-kube-prometheus-prometheus-0 -n monitoring -- tar -czf /tmp/prometheus-backup.tar.gz /prometheus

# Grafana config backup
kubectl get secret prometheus-grafana -n monitoring -o yaml > grafana-secret-backup.yaml
```

### Port Forwarding (Alternative Access)
```bash
# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Prometheus  
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# AlertManager
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
```

---

## 🚫 Anti-Pattern

| Anti-pattern | Why it's bad | Correct approach |
|--------------|-----------|-------|
| Writing the Grafana admin password as plain text in `values.yaml` (`adminPassword: "admin123!"`) | The password leaks into git and the Helm release secret, anyone can read it | Create the password as a K8s Secret and reference it with `admin.existingSecret` |
| Exposing all services to the internet via NodePort | Prometheus/AlertManager have no authentication, cluster metrics and config leak out | Keep internal access on ClusterIP, put external access behind Ingress + auth (OAuth2/basic) |
| Running Prometheus without setting `retention` | The TSDB disk grows unbounded, the PVC fills up, Prometheus crashes | Set a limit with `retention: 15d` and `retentionSize`, keep it consistent with the PVC size |
| Not setting resource `requests`/`limits` on pods | Prometheus gets OOM-killed or chokes the node, scraping stops | Give every component a memory/cpu request+limit (e.g. 1Gi limit for Prometheus) |
| Running with `emptyDir` or persistence disabled | All metric and dashboard history is wiped on pod restart | Use `persistence.enabled: true` + a durable StorageClass |
| Running `helm upgrade` without first getting the current values | Previous customizations revert to defaults, NodePort/password/retention reset | First run `helm get values ... > current.yaml`, then upgrade with `--values current.yaml` |
| Just watching dashboards without writing alert rules | Problems go unnoticed whenever nobody is staring at the screen | Define alerts for critical metrics with `PrometheusRule`, hook AlertManager up to a channel |
| Going to prod with a single AlertManager replica | No alert gets delivered when the pod goes down — a silent failure | Set up AlertManager HA (at least 2 replicas) with a real receiver (Slack/email/PagerDuty) |
| Editing services by hand with `kubectl patch` and not writing it back to values | The next Helm upgrade overwrites the change, causing drift | Write changes into `values.yaml`, keep a single source of truth (GitOps) |
| Doing capacity planning without metrics server / `kubectl top` | Resource usage stays invisible, limit settings are guesswork | Install metrics server, monitor real usage with `kubectl top` and Grafana |

---

## 📋 Checklist

Before going to production:

- [ ] Grafana admin password is in a K8s Secret (`existingSecret`), not plain text in values
- [ ] Prometheus `retention` + `retentionSize` are set and consistent with the PVC size
- [ ] Resource `requests` and `limits` are defined on every component
- [ ] Persistence is enabled and a durable StorageClass is used (Prometheus, Grafana, AlertManager)
- [ ] External access sits behind Ingress + TLS + auth; Prometheus/AlertManager are not directly exposed via NodePort
- [ ] AlertManager is HA (>=2 replicas) and connected to a real receiver (Slack/email/PagerDuty)
- [ ] `PrometheusRule` alert rules are written and tested for critical metrics
- [ ] All targets are `UP` on the Prometheus `/targets` page
- [ ] Metrics server is installed, `kubectl top pods/nodes` works
- [ ] `externalLabels` (cluster name) is set — for multi-cluster federation
- [ ] A backup plan exists: Prometheus data + Grafana config/dashboards are backed up regularly
- [ ] The monitoring namespace is isolated with RBAC and NetworkPolicy
- [ ] All configuration is versioned in `values.yaml`; no manual `kubectl patch` drift

---

## 📖 Additional Resources

### Official Documentation
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Grafana Docs](https://grafana.com/docs/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

### Useful Dashboards
- [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)
- ID: 315 (Kubernetes cluster monitoring)
- ID: 1860 (Node Exporter Full)
- ID: 6417 (Kubernetes Pods)

### Monitoring Best Practices
1. **Retention Policy**: Retain data for 15+ days
2. **Resource Limits**: Set pod resource limits
3. **Alerting**: Write alert rules for critical metrics
4. **Backup**: Back up Prometheus data and Grafana configs
5. **Security**: Use RBAC and network policies

---

## ✅ Installation Complete!

With this documentation, you can set up and manage a production-ready Prometheus + Grafana monitoring stack on your Kubernetes cluster. 

If you run into any issues, check the troubleshooting section above or get support from the community forums.

**Happy Monitoring!** 🚀📊

> *"Installing kube-prometheus-stack with Helm is an hour's work; the real job is setting retention, resource limits, RBAC, and alert rules on day one so the stack doesn't become its own blind spot."*
