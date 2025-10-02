# Monitoring Sistem Yönetim Komutları

# 1. Prometheus konfigürasyonunu reload etmek
curl -X POST http://172.168.30.96:9090/-/reload

# 2. AlertManager konfigürasyonunu reload etmek  
curl -X POST http://172.168.30.96:9093/-/reload

# 3. Tüm VM'lerdeki node-exporter durumunu kontrol etmek
for ip in 172.168.30.{51..56} 172.168.30.{96,97,99}; do
  echo "=== $ip ==="
  timeout 5 curl -s http://$ip:9100/metrics | head -1 && echo "✅ Node Exporter OK" || echo "❌ Node Exporter Problem"
  timeout 5 curl -s http://$ip:8080/metrics | head -1 && echo "✅ cAdvisor OK" || echo "❌ cAdvisor Problem"
  echo
done

# 4. Prometheus targets durumunu JSON olarak görmek
curl -s http://172.168.30.96:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health}'

# 5. Aktif alert'leri görmek
curl -s http://172.168.30.96:9090/api/v1/alerts | jq '.data.alerts[] | {alertname: .labels.alertname, state: .state, instance: .labels.instance}'

# 6. VM resource kullanımını hızlıca görmek
curl -s "http://172.168.30.96:9090/api/v1/query?query=100-(avg by(instance)(rate(node_cpu_seconds_total{mode=\"idle\"}[5m]))*100)" | \
jq '.data.result[] | {instance: .metric.instance, cpu_usage: (.value[1]|tonumber|floor|tostring + "%")}'

# 7. Memory kullanımını görmek
curl -s "http://172.168.30.96:9090/api/v1/query?query=(1-(node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes))*100" | \
jq '.data.result[] | {instance: .metric.instance, memory_usage: (.value[1]|tonumber|floor|tostring + "%")}'

# 8. Disk kullanımını görmek
curl -s "http://172.168.30.96:9090/api/v1/query?query=(1-node_filesystem_avail_bytes{fstype!~\"tmpfs|fuse.lxcfs\"}/node_filesystem_size_bytes{fstype!~\"tmpfs|fuse.lxcfs\"})*100" | \
jq '.data.result[] | {instance: .metric.instance, mountpoint: .metric.mountpoint, disk_usage: (.value[1]|tonumber|floor|tostring + "%")}'

# 9. Container durumlarını görmek
curl -s "http://172.168.30.96:9090/api/v1/query?query=container_last_seen" | \
jq '.data.result[] | {instance: .metric.instance, container: .metric.name, last_seen: .value[1]}'

# 10. Uptime bilgilerini görmek
curl -s "http://172.168.30.96:9090/api/v1/query?query=node_time_seconds-node_boot_time_seconds" | \
jq '.data.result[] | {instance: .metric.instance, uptime_days: ((.value[1]|tonumber/86400)|floor|tostring)}'
