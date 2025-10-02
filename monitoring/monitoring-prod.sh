# Production Monitoring Sistem Yönetim Komutları

# 1. Prometheus konfigürasyonunu reload etmek
curl -X POST http://172.168.20.153:9090/-/reload

# 2. AlertManager konfigürasyonunu reload etmek
curl -X POST http://172.168.20.153:9093/-/reload

# 3. Tüm Production VM'lerdeki exporters durumunu kontrol etmek
for ip in 172.168.20.{153..171}; do
  echo "=== $ip ==="
  timeout 5 curl -s http://$ip:9100/metrics | head -1 && echo "✅ Node Exporter OK" || echo "❌ Node Exporter Problem"
  timeout 5 curl -s http://$ip:8080/metrics | head -1 && echo "✅ cAdvisor OK" || echo "❌ cAdvisor Problem"
  # Database sunucuları için PostgreSQL exporter kontrolü
  if [[ $ip =~ ^172\.168\.20\.(156|159|162|165|168|171)$ ]]; then
    timeout 5 curl -s http://$ip:9187/metrics | head -1 && echo "✅ PostgreSQL Exporter OK" || echo "❌ PostgreSQL Exporter Problem"
  fi
  echo
done

# 4. Prometheus targets durumunu JSON olarak görmek (Production)
curl -s http://172.168.20.153:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health, service_type: .labels.service_type}'

# 5. Aktif alert'leri görmek (Production)
curl -s http://172.168.20.153:9090/api/v1/alerts | jq '.data.alerts[] | {alertname: .labels.alertname, state: .state, instance: .labels.instance, service_type: .labels.service_type}'

# 6. VM resource kullanımını service type ile görmek
curl -s "http://172.168.20.153:9090/api/v1/query?query=100-(avg by(instance,service_type)(rate(node_cpu_seconds_total{mode=\"idle\"}[5m]))*100)" | \
jq '.data.result[] | {instance: .metric.instance, service_type: .metric.service_type, cpu_usage: (.value[1]|tonumber|floor|tostring + "%")}'

# 7. Memory kullanımını service type ile görmek
curl -s "http://172.168.20.153:9090/api/v1/query?query=(1-(node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes))*100" | \
jq '.data.result[] | {instance: .metric.instance, service_type: .metric.service_type, memory_usage: (.value[1]|tonumber|floor|tostring + "%")}'

# 8. Disk kullanımını görmek (Production)
curl -s "http://172.168.20.153:9090/api/v1/query?query=(1-node_filesystem_avail_bytes{fstype!~\"tmpfs|fuse.lxcfs\"}/node_filesystem_size_bytes{fstype!~\"tmpfs|fuse.lxcfs\"})*100" | \
jq '.data.result[] | {instance: .metric.instance, service_type: .metric.service_type, mountpoint: .metric.mountpoint, disk_usage: (.value[1]|tonumber|floor|tostring + "%")}'

# 9. Container durumlarını application bazlı görmek
curl -s "http://172.168.20.153:9090/api/v1/query?query=container_last_seen" | \
jq '.data.result[] | {instance: .metric.instance, container: .metric.name, application: .metric.application, last_seen: .value[1]}'

# 10. Uptime bilgilerini service type ile görmek
curl -s "http://172.168.20.153:9090/api/v1/query?query=node_time_seconds-node_boot_time_seconds" | \
jq '.data.result[] | {instance: .metric.instance, service_type: .metric.service_type, uptime_days: ((.value[1]|tonumber/86400)|floor|tostring)}'

# 11. Database connection sayısını görmek (PostgreSQL)
curl -s "http://172.168.20.153:9090/api/v1/query?query=pg_stat_database_numbackends" | \
jq '.data.result[] | {database: .metric.datname, connections: .value[1], instance: .metric.instance}'

# 12. Application health check durumları
curl -s "http://172.168.20.153:9090/api/v1/query?query=probe_success" | \
jq '.data.result[] | {endpoint: .metric.instance, status: (.value[1] == "1" | if . then "UP" else "DOWN" end)}'

# 13. Application bazlı resource özeti
echo "=== E-COMMERCE APPLICATION ==="
curl -s "http://172.168.20.153:9090/api/v1/query?query=100-(avg by(instance)(rate(node_cpu_seconds_total{application=\"ecommerce\",mode=\"idle\"}[5m]))*100)" | \
jq '.data.result[] | {instance: .metric.instance, cpu_usage: (.value[1]|tonumber|floor|tostring + "%")}'

echo "=== CRM APPLICATION ==="
curl -s "http://172.168.20.153:9090/api/v1/query?query=100-(avg by(instance)(rate(node_cpu_seconds_total{application=\"crm\",mode=\"idle\"}[5m]))*100)" | \
jq '.data.result[] | {instance: .metric.instance, cpu_usage: (.value[1]|tonumber|floor|tostring + "%")}'

echo "=== ONMUHASEBE APPLICATION ==="
curl -s "http://172.168.20.153:9090/api/v1/query?query=100-(avg by(instance)(rate(node_cpu_seconds_total{application=\"onmuhasebe\",mode=\"idle\"}[5m]))*100)" | \
jq '.data.result[] | {instance: .metric.instance, cpu_usage: (.value[1]|tonumber|floor|tostring + "%")}'

# 14. Database performance metrics
echo "=== DATABASE PERFORMANCE ==="
curl -s "http://172.168.20.153:9090/api/v1/query?query=pg_stat_database_blks_read+pg_stat_database_blks_hit" | \
jq '.data.result[] | {database: .metric.datname, total_reads: .value[1], instance: .metric.instance}'

# 15. Top 5 en yüksek CPU kullanan sunucular
echo "=== TOP 5 HIGHEST CPU USAGE ==="
curl -s "http://172.168.20.153:9090/api/v1/query?query=topk(5, 100-(avg by(instance,service_type)(rate(node_cpu_seconds_total{mode=\"idle\"}[5m]))*100))" | \
jq '.data.result[] | {instance: .metric.instance, service_type: .metric.service_type, cpu_usage: (.value[1]|tonumber|floor|tostring + "%")}'

# 16. Critical services health summary
echo "=== CRITICAL SERVICES HEALTH ==="
api_count=$(curl -s "http://172.168.20.153:9090/api/v1/query?query=up{service_type=\"api\"}" | jq '.data.result | length')
api_up=$(curl -s "http://172.168.20.153:9090/api/v1/query?query=up{service_type=\"api\"}" | jq '.data.result[] | select(.value[1]=="1") | .value[1]' | wc -l)
echo "API Services: $api_up/$api_count UP"

db_count=$(curl -s "http://172.168.20.153:9090/api/v1/query?query=up{service_type=\"database\"}" | jq '.data.result | length')
db_up=$(curl -s "http://172.168.20.153:9090/api/v1/query?query=up{service_type=\"database\"}" | jq '.data.result[] | select(.value[1]=="1") | .value[1]' | wc -l)
echo "Database Services: $db_up/$db_count UP"

frontend_count=$(curl -s "http://172.168.20.153:9090/api/v1/query?query=up{service_type=\"frontend\"}" | jq '.data.result | length')
frontend_up=$(curl -s "http://172.168.20.153:9090/api/v1/query?query=up{service_type=\"frontend\"}" | jq '.data.result[] | select(.value[1]=="1") | .value[1]' | wc -l)
echo "Frontend Services: $frontend_up/$frontend_count UP"