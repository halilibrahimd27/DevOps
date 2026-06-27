---
description: "Kubernetes cluster servis parolalarını secret'lardan toplayan bash script'i: Jenkins, Grafana, Elasticsearch kimlikleri ve servis erişim URL'leri."
---
# Kubernetes Cluster Parolaları (Toplama Script'i)

> 🗒️ **Saha notu** — ham komut/konfigürasyon dökümü. Olduğu gibi korunmuştur; kendi ortamına uyarla.

```bash
echo "=== 🔐 KUBERNETES CLUSTER PAROLALARİ ==="
echo ""
echo "📊 JENKINS:"
echo "Kullanıcı: $(kubectl get secret jenkins -n jenkins -o jsonpath="{.data.jenkins-admin-user}" | base64 --decode 2>/dev/null || echo 'admin')"
echo "Parola: $(kubectl get secret jenkins -n jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode 2>/dev/null || echo 'Bulunamadı')"
echo ""
echo "📈 GRAFANA:"
echo "Kullanıcı: $(kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-user}" | base64 --decode 2>/dev/null || echo 'admin')"
echo "Parola: $(kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode 2>/dev/null || echo 'Bulunamadı')"
echo ""
echo "🔍 ELASTICSEARCH:"
echo "Parola: $(kubectl get secret elasticsearch-master-credentials -n logging -o jsonpath="{.data.password}" | base64 --decode 2>/dev/null || echo 'Security disabled')"
echo ""
echo "=== 🌐 SERVİS ERİŞİM BİLGİLERİ ==="
echo ""
echo "📊 Jenkins: http://$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '<INGRESS-IP>')/"
echo "📈 Grafana: http://$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.spec.clusterIP}'):3000"
echo "📊 Kibana: http://$(kubectl get svc kibana -n logging -o jsonpath='{.spec.clusterIP}'):5601"
echo "🔍 Elasticsearch: http://$(kubectl get svc elasticsearch -n logging -o jsonpath='{.spec.clusterIP}'):9200"
echo ""
```
