---
description: "Kubernetes uzerinde Prometheus ve Grafana kurulum dokumantasyonu: sistem gereksinimleri, on kosullar, Helm kurulum adimlari, service konfigurasyonu, erisim ve sorun giderme."
---
# Prometheus + Grafana Kubernetes Kurulum Dokümantasyonu

## 📋 İçindekiler
- [Sistem Gereksinimleri](#sistem-gereksinimleri)
- [Ön Koşullar](#ön-koşullar)
- [Kurulum Adımları](#kurulum-adımları)
- [Mevcut Kurulum Kontrolü](#mevcut-kurulum-kontrolü)
- [Service Konfigürasyonu](#service-konfigürasyonu)
- [Erişim ve Kullanım](#erişim-ve-kullanım)
- [Sorun Giderme](#sorun-giderme)
- [Yararlı Komutlar](#yararlı-komutlar)

---

## 🔧 Sistem Gereksinimleri

### Minimum Sistem Gereksinimleri
- **Kubernetes Cluster**: v1.28+
- **Helm**: v3.18+
- **Storage Class**: Dynamic provisioning destekleyen
- **Minimum RAM**: 4GB (cluster genelinde)
- **Minimum CPU**: 2 vCPU (cluster genelinde)
- **Disk**: 50GB+ (monitoring data için)

### Test Edilmiş Ortam
```
- Kubernetes: v1.33.1 (master), v1.28.15 (worker)
- Helm: v3.18.3
- Storage Class: local-path
- Node Sayısı: 3 (1 master, 2 worker)
- İşletim Sistemi: Ubuntu 22.04.5 LTS
```

---

## ✅ Ön Koşullar

### 1. Kubernetes Cluster Kontrolü
```bash
# Cluster durumu
kubectl cluster-info

# Node durumu
kubectl get nodes -o wide

# Storage class kontrolü
kubectl get storageclass
```

### 2. Helm Kurulum Kontrolü
```bash
# Helm version
helm version

# Helm repo'lar
helm repo list
```

### 3. Gerekli Namespace
```bash
# Monitoring namespace oluştur (yoksa)
kubectl create namespace monitoring
```

---

## 🚀 Kurulum Adımları

### Seçenek 1: Hızlı Kurulum (Önerilen)

#### 1.1 Helm Repository Hazırlama
```bash
# Prometheus community repo ekle
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

#### 1.2 Otomatik Kurulum Script
```bash
#!/bin/bash
# prometheus-install.sh

echo "🚀 Prometheus Stack Kurulumu Başlıyor..."

# Helm repository güncelle
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Namespace oluştur
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Prometheus stack kur
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

echo "✅ Kurulum tamamlandı!"
```

### Seçenek 2: Özelleştirilmiş Kurulum

#### 2.1 Custom Values Dosyası
```yaml
# prometheus-values.yaml

# Grafana Konfigürasyonu
grafana:
  adminPassword: "admin123!"
  
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

# Prometheus Konfigürasyonu
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

# AlertManager Konfigürasyonu  
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

# Diğer Ayarlar
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

#### 2.2 Custom Kurulum
```bash
# Custom values ile kurulum
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml
```

---

## 🔍 Mevcut Kurulum Kontrolü

### Durum Kontrol Script
```bash
#!/bin/bash
# prometheus-status.sh

echo "🔍 PROMETHEUS STACK DURUM RAPORU"
echo "================================="

# Helm release durumu
echo ""
echo "📦 Helm Release Durumu:"
helm list -n monitoring

# Pod durumları
echo ""
echo "🚀 Pod Durumları:"
kubectl get pods -n monitoring -o wide

# Service ve Port bilgileri
echo ""
echo "🌐 Service'ler ve Portlar:"
kubectl get svc -n monitoring

# Storage durumu
echo ""
echo "💾 Storage Durumu:"
kubectl get pvc -n monitoring

# Erişim bilgileri
echo ""
echo "🔗 Erişim Bilgileri:"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Master Node IP: $NODE_IP"

# Port kontrolü
GRAFANA_PORT=$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
PROMETHEUS_SVC_TYPE=$(kubectl get svc prometheus-kube-prometheus-prometheus -n monitoring -o jsonpath='{.spec.type}' 2>/dev/null)
ALERTMANAGER_SVC_TYPE=$(kubectl get svc prometheus-kube-prometheus-alertmanager -n monitoring -o jsonpath='{.spec.type}' 2>/dev/null)

echo ""
echo "🌍 Web Arayüzleri:"
if [ ! -z "$GRAFANA_PORT" ]; then
    echo "   📊 Grafana:      http://$NODE_IP:$GRAFANA_PORT ✅"
else
    echo "   📊 Grafana:      ClusterIP (External erişim yok) ❌"
fi

if [ "$PROMETHEUS_SVC_TYPE" = "NodePort" ]; then
    PROMETHEUS_PORT=$(kubectl get svc prometheus-kube-prometheus-prometheus -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')
    echo "   📈 Prometheus:   http://$NODE_IP:$PROMETHEUS_PORT ✅"
else
    echo "   📈 Prometheus:   ClusterIP (External erişim yok) ❌"
fi

if [ "$ALERTMANAGER_SVC_TYPE" = "NodePort" ]; then
    ALERTMANAGER_PORT=$(kubectl get svc prometheus-kube-prometheus-alertmanager -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')
    echo "   🚨 AlertManager: http://$NODE_IP:$ALERTMANAGER_PORT ✅"
else
    echo "   🚨 AlertManager: ClusterIP (External erişim yok) ❌"
fi

# Grafana login bilgileri
echo ""
echo "🔐 Grafana Giriş Bilgileri:"
echo "   👤 Kullanıcı: admin"
echo -n "   🔑 Şifre: "
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode 2>/dev/null || echo "Şifre alınamadı"
echo ""

# Sistem kaynak kullanımı
echo ""
echo "📊 Kaynak Kullanımı:"
kubectl top pods -n monitoring 2>/dev/null || echo "Metrics server kurulu değil"

# Son restart zamanları
echo ""
echo "🔄 Pod Restart Bilgileri:"
kubectl get pods -n monitoring -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount,AGE:.metadata.creationTimestamp

echo ""
echo "✅ Durum kontrolü tamamlandı!"
```

---

## ⚙️ Service Konfigürasyonu

### NodePort'a Çevirme Script
```bash
#!/bin/bash
# service-nodeport.sh

echo "🔧 SERVİSLERİ NODEPORT'A ÇEVİRİYORUZ"
echo "===================================="

# Mevcut durum
echo ""
echo "📋 Mevcut Service Durumu:"
kubectl get svc -n monitoring | grep -E "(grafana|prometheus|alertmanager)" | grep -v operated

echo ""
echo "🔄 Service'leri NodePort'a çeviriyoruz..."

# Prometheus'u NodePort'a çevir
echo ""
echo "📈 Prometheus Service güncelleniyor..."
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

# AlertManager'ı NodePort'a çevir  
echo ""
echo "🚨 AlertManager Service güncelleniyor..."
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

# Grafana port güncelle
echo ""
echo "📊 Grafana Service port güncelleniyor..."
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

# Güncellenen durumu kontrol et
echo ""
echo "✅ Service güncellemeleri tamamlandı!"
echo ""
echo "📋 Güncellenmiş Service Durumu:"
kubectl get svc -n monitoring | grep -E "(grafana|prometheus|alertmanager)" | grep -v operated

# Erişim bilgileri
echo ""
echo "🌐 Güncellenmiş Erişim Bilgileri:"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo "   Master Node IP: $NODE_IP"
echo ""
echo "   📊 Grafana:      http://$NODE_IP:32000"
echo "   📈 Prometheus:   http://$NODE_IP:32001" 
echo "   🚨 AlertManager: http://$NODE_IP:32002"
echo ""
echo "🔐 Grafana Giriş:"
echo "   👤 Kullanıcı: admin"
echo -n "   🔑 Şifre: "
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
echo ""
echo ""
echo "✨ Tüm servisler artık external erişime açık!"
```

---

## 🌐 Erişim ve Kullanım

### Web Arayüzleri
```
📊 Grafana:      http://<NODE-IP>:32000
📈 Prometheus:   http://<NODE-IP>:32001
🚨 AlertManager: http://<NODE-IP>:32002
```

### Grafana Giriş Bilgileri
```
👤 Kullanıcı: admin
🔑 Şifre: kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

### İlk Kurulum Sonrası Yapılacaklar

#### 1. Grafana Dashboard'ları
- **Kubernetes Cluster Monitoring Dashboard**: Cluster genel durumu
- **Node Exporter Full**: Node detay metrikleri  
- **Kubernetes Pods**: Pod monitoring
- **Prometheus Stats**: Prometheus kendi metrikleri

#### 2. Prometheus Targets Kontrolü
```
http://<NODE-IP>:32001/targets
```
Tüm target'ların "UP" durumunda olduğunu kontrol edin.

#### 3. AlertManager Konfigürasyonu
```yaml
# Custom alert rules eklemek için
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

## 🔧 Sorun Giderme

### Yaygın Sorunlar ve Çözümleri

#### 1. Pod'lar Pending Durumunda
```bash
# Storage class kontrolü
kubectl get storageclass

# PVC durumu
kubectl get pvc -n monitoring

# Pod events
kubectl describe pod <pod-name> -n monitoring
```

#### 2. Service External Erişim Sorunu
```bash
# Service type kontrolü
kubectl get svc -n monitoring

# NodePort açık mı?
netstat -tulpn | grep :32000
```

#### 3. Grafana Şifre Sorunu
```bash
# Şifreyi sıfırla
kubectl delete secret prometheus-grafana -n monitoring
kubectl patch deployment prometheus-grafana -n monitoring -p '{"spec":{"template":{"spec":{"containers":[{"name":"grafana","env":[{"name":"GF_SECURITY_ADMIN_PASSWORD","value":"yeni-sifre"}]}]}}}}'
```

#### 4. Prometheus Storage Sorunu
```bash
# PVC boyutunu artır
kubectl patch pvc prometheus-prometheus-kube-prometheus-prometheus-db-prometheus-prometheus-kube-prometheus-prometheus-0 -n monitoring -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'
```

#### 5. Helm Upgrade Sorunu
```bash
# Mevcut values'ları al
helm get values prometheus -n monitoring > current-values.yaml

# Güvenli upgrade
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring --values current-values.yaml
```

---

## 📚 Yararlı Komutlar

### Kurulum Yönetimi
```bash
# Helm releases
helm list -n monitoring

# Stack'i güncelle
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring

# Stack'i sil
helm uninstall prometheus -n monitoring

# Namespace'i temizle
kubectl delete namespace monitoring
```

### Monitoring ve Debug
```bash
# Pod logları
kubectl logs -f <pod-name> -n monitoring

# Service endpoints
kubectl get endpoints -n monitoring

# Resource kullanımı
kubectl top pods -n monitoring
kubectl top nodes

# Events
kubectl get events -n monitoring --sort-by='.lastTimestamp'
```

### Backup ve Restore
```bash
# Prometheus data backup
kubectl exec -it prometheus-prometheus-kube-prometheus-prometheus-0 -n monitoring -- tar -czf /tmp/prometheus-backup.tar.gz /prometheus

# Grafana config backup
kubectl get secret prometheus-grafana -n monitoring -o yaml > grafana-secret-backup.yaml
```

### Port Forwarding (Alternatif Erişim)
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

| Anti-pattern | Niye kötü | Doğru |
|--------------|-----------|-------|
| Grafana admin şifresini `values.yaml`'a düz metin yazmak (`adminPassword: "admin123!"`) | Şifre git'e ve Helm release secret'ına sızar, herkes okur | Şifreyi K8s Secret olarak oluştur, `admin.existingSecret` ile referansla |
| Tüm servisleri NodePort ile internete açmak | Prometheus/AlertManager kimlik doğrulamasız, cluster metrikleri ve config dışarı sızar | İç erişimi ClusterIP'te tut, dış erişimi Ingress + auth (OAuth2/basic) arkasına al |
| `retention` ayarlamadan Prometheus çalıştırmak | TSDB disk'i sınırsız büyür, PVC dolar, Prometheus crash olur | `retention: 15d` ve `retentionSize` ile sınır koy, PVC boyutuyla uyumlu tut |
| Pod'lara resource `requests`/`limits` koymamak | Prometheus OOM-kill yer veya node'u boğar, scrape kesilir | Her bileşene memory/cpu request+limit ver (örn. Prometheus 1Gi limit) |
| `emptyDir` veya persistence kapalı çalıştırmak | Pod restart'ında tüm metrik ve dashboard geçmişi silinir | `persistence.enabled: true` + kalıcı StorageClass kullan |
| `helm upgrade`'i mevcut values almadan çalıştırmak | Önceki özelleştirmeler default'a döner, NodePort/şifre/retention sıfırlanır | Önce `helm get values ... > current.yaml`, sonra `--values current.yaml` ile upgrade et |
| Alert kuralı yazmadan sadece dashboard'a bakmak | Sorunlar ekrana bakan biri olmadığında fark edilmez | Kritik metrikler için `PrometheusRule` ile alert tanımla, AlertManager'ı bir kanala bağla |
| Tek replica AlertManager ile prod'a çıkmak | Pod düşünce hiçbir alarm iletilmez, sessiz arıza | AlertManager'ı HA (en az 2 replica) ve gerçek receiver (Slack/e-posta/PagerDuty) ile kur |
| `kubectl patch` ile servisleri elle düzenleyip values'a yazmamak | Bir sonraki Helm upgrade değişikliği ezer, drift oluşur | Değişiklikleri `values.yaml`'a yaz, kaynak-doğru (GitOps) tut |
| Metrics server / `kubectl top` olmadan kapasite planlamak | Kaynak kullanımı görünmez, limit ayarları tahmine dayanır | Metrics server kur, `kubectl top` ve Grafana ile gerçek kullanımı izle |

---

## 📋 Checklist

Production'a çıkmadan önce:

- [ ] Grafana admin şifresi K8s Secret'ta (`existingSecret`), values'da düz metin yok
- [ ] Prometheus `retention` + `retentionSize` ayarlandı ve PVC boyutuyla uyumlu
- [ ] Tüm bileşenlerde resource `requests` ve `limits` tanımlı
- [ ] Persistence açık ve kalıcı StorageClass kullanılıyor (Prometheus, Grafana, AlertManager)
- [ ] Dış erişim Ingress + TLS + auth arkasında; Prometheus/AlertManager doğrudan NodePort ile açık değil
- [ ] AlertManager HA (>=2 replica) ve gerçek receiver'a (Slack/e-posta/PagerDuty) bağlı
- [ ] Kritik metrikler için `PrometheusRule` alert kuralları yazıldı ve test edildi
- [ ] Prometheus `/targets` sayfasında tüm hedefler `UP`
- [ ] Metrics server kurulu, `kubectl top pods/nodes` çalışıyor
- [ ] `externalLabels` (cluster adı) ayarlandı — çok-cluster federasyon için
- [ ] Backup planı var: Prometheus data + Grafana config/dashboard'lar düzenli alınıyor
- [ ] RBAC ve NetworkPolicy ile monitoring namespace izole edildi
- [ ] Tüm konfigürasyon `values.yaml`'da versiyonlanıyor; manuel `kubectl patch` drift'i yok

---

## 📖 Ek Kaynaklar

### Resmi Dokümantasyon
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Grafana Docs](https://grafana.com/docs/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

### Faydalı Dashboard'lar
- [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)
- ID: 315 (Kubernetes cluster monitoring)
- ID: 1860 (Node Exporter Full)
- ID: 6417 (Kubernetes Pods)

### Monitoring Best Practices
1. **Retention Policy**: 15+ gün veri saklayın
2. **Resource Limits**: Pod resource limitlerini ayarlayın
3. **Alerting**: Kritik metrikleri için alert kuralları yazın
4. **Backup**: Prometheus data ve Grafana config'lerini backup alın
5. **Security**: RBAC ve network policies kullanın

---

## ✅ Kurulum Tamamlandı!

Bu dokümantasyon ile Kubernetes cluster'ınızda production-ready Prometheus + Grafana monitoring stack'i kurabilir ve yönetebilirsiniz. 

Herhangi bir sorun yaşarsanız, yukarıdaki troubleshooting bölümünü kontrol edin veya community forumlarından destek alın.

**Happy Monitoring!** 🚀📊
