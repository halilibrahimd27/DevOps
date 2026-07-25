---
description: "Bash script that collects Kubernetes cluster service passwords from secrets: Jenkins, Grafana, Elasticsearch credentials and service access URLs."
tags:
  - Field Notes
  - Kubernetes
  - Secrets
  - Security
  - Cheatsheet
---
# Kubernetes Cluster Passwords (Collection Script)

> 🗒️ **Field note** — raw command/config dump. Preserved as-is; adapt it to your own environment.

```bash
echo "=== 🔐 KUBERNETES CLUSTER PASSWORDS ==="
echo ""
echo "📊 JENKINS:"
echo "User: $(kubectl get secret jenkins -n jenkins -o jsonpath="{.data.jenkins-admin-user}" | base64 --decode 2>/dev/null || echo 'admin')"
echo "Password: $(kubectl get secret jenkins -n jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode 2>/dev/null || echo 'Not found')"
echo ""
echo "📈 GRAFANA:"
echo "User: $(kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-user}" | base64 --decode 2>/dev/null || echo 'admin')"
echo "Password: $(kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode 2>/dev/null || echo 'Not found')"
echo ""
echo "🔍 ELASTICSEARCH:"
echo "Password: $(kubectl get secret elasticsearch-master-credentials -n logging -o jsonpath="{.data.password}" | base64 --decode 2>/dev/null || echo 'Security disabled')"
echo ""
echo "=== 🌐 SERVICE ACCESS INFORMATION ==="
echo ""
echo "📊 Jenkins: http://$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '<INGRESS-IP>')/"
echo "📈 Grafana: http://$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.spec.clusterIP}'):3000"
echo "📊 Kibana: http://$(kubectl get svc kibana -n logging -o jsonpath='{.spec.clusterIP}'):5601"
echo "🔍 Elasticsearch: http://$(kubectl get svc elasticsearch -n logging -o jsonpath='{.spec.clusterIP}'):9200"
echo ""
```
