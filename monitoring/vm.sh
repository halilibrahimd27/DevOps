#!/bin/bash

# VM Monitoring Yönetim Script'i
# Kullanım: ./monitoring.sh [status|restart|logs|alerts]

PROMETHEUS_HOST="172.168.20.153"
PROMETHEUS_PORT="9090"
GRAFANA_PORT="3000"

# Renkli output için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logo
show_logo() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════╗"
    echo "║         VM MONİTORİNG SİSTEMİ        ║"
    echo "║              v1.0                    ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

# Sistem durumunu kontrol et
check_status() {
    echo -e "${YELLOW}=== SİSTEM DURUMU ===${NC}\n"
    
    # Prometheus kontrol
    if curl -s http://$PROMETHEUS_HOST:$PROMETHEUS_PORT/-/healthy > /dev/null; then
        echo -e "📊 Prometheus: ${GREEN}✅ Çalışıyor${NC}"
    else
        echo -e "📊 Prometheus: ${RED}❌ Problem${NC}"
    fi
    
    # Grafana kontrol  
    if curl -s http://$PROMETHEUS_HOST:$GRAFANA_PORT/api/health > /dev/null; then
        echo -e "📈 Grafana: ${GREEN}✅ Çalışıyor${NC}"
    else
        echo -e "📈 Grafana: ${RED}❌ Problem${NC}"
    fi
    
    echo
    echo -e "${YELLOW}=== VM DURUMU ===${NC}\n"
    
    # Production VM'leri kontrol et
    declare -A VMS=(
        ["172.168.20.153"]="monitoring (PROD-MON)"
        ["172.168.20.154"]="ecommerce-api (PROD-API)"
        ["172.168.20.155"]="ecommerce-front (PROD-FE)"
        ["172.168.20.156"]="ecommerce-db (PROD-DB)"
        ["172.168.20.157"]="crm-api (PROD-API)"
        ["172.168.20.158"]="crm-front (PROD-FE)"
        ["172.168.20.159"]="crm-db (PROD-DB)"
        ["172.168.20.160"]="onmuhasebe-api (PROD-API)"
        ["172.168.20.161"]="onmuhasebe-front (PROD-FE)"
        ["172.168.20.162"]="onmuhasebe-db (PROD-DB)"
        ["172.168.20.163"]="ik-api (PROD-API)"
        ["172.168.20.164"]="ik-front (PROD-FE)"
        ["172.168.20.165"]="ik-db (PROD-DB)"
        ["172.168.20.166"]="platform-api (PROD-API)"
        ["172.168.20.167"]="platform-front (PROD-FE)"
        ["172.168.20.168"]="platform-db (PROD-DB)"
        ["172.168.20.169"]="earsiv-api (PROD-API)"
        ["172.168.20.170"]="earsiv-front (PROD-FE)"
        ["172.168.20.171"]="earsiv-db (PROD-DB)"
    )
    
    for ip in "${!VMS[@]}"; do
        vm_name="${VMS[$ip]}"
        
        # Node Exporter kontrol
        if timeout 3 curl -s http://$ip:9100/metrics >/dev/null 2>&1; then
            node_status="${GREEN}✅${NC}"
        else
            node_status="${RED}❌${NC}"
        fi
        
        # cAdvisor kontrol (port 8080 veya 8088)
        if timeout 3 curl -s http://$ip:8080/metrics >/dev/null 2>&1; then
            cadvisor_status="${GREEN}✅${NC}"
        elif timeout 3 curl -s http://$ip:8088/metrics >/dev/null 2>&1; then
            cadvisor_status="${GREEN}✅${NC}"
        else
            cadvisor_status="${RED}❌${NC}"
        fi
        
        printf "%-25s | Node: %s | cAdvisor: %s\n" "$vm_name" "$node_status" "$cadvisor_status"
    done
}

# Resource kullanımını göster
show_resources() {
    echo -e "\n${YELLOW}=== RESOURCE KULLANIMI ===${NC}\n"
    
    # CPU kullanımı
    echo "🔥 CPU Kullanımı:"
    curl -s "http://$PROMETHEUS_HOST:$PROMETHEUS_PORT/api/v1/query?query=100-(avg by(instance)(rate(node_cpu_seconds_total{mode=\"idle\"}[5m]))*100)" | \
    jq -r '.data.result[] | "\(.metric.instance): \((.value[1]|tonumber)|round)%"' | \
    while read line; do
        cpu=$(echo $line | cut -d: -f2 | cut -d% -f1)
        if [ "$cpu" -gt 80 ]; then
            echo -e "  ${RED}$line${NC}"
        elif [ "$cpu" -gt 60 ]; then
            echo -e "  ${YELLOW}$line${NC}"
        else
            echo -e "  ${GREEN}$line${NC}"
        fi
    done
    
    echo
    # Memory kullanımı
    echo "💾 Memory Kullanımı:"
    curl -s "http://$PROMETHEUS_HOST:$PROMETHEUS_PORT/api/v1/query?query=(1-(node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes))*100" | \
    jq -r '.data.result[] | "\(.metric.instance): \((.value[1]|tonumber)|round)%"' | \
    while read line; do
        mem=$(echo $line | cut -d: -f2 | cut -d% -f1)
        if [ "$mem" -gt 90 ]; then
            echo -e "  ${RED}$line${NC}"
        elif [ "$mem" -gt 70 ]; then
            echo -e "  ${YELLOW}$line${NC}"
        else
            echo -e "  ${GREEN}$line${NC}"
        fi
    done
}

# Alert'leri göster (Web UI bilgisiyle)
show_alerts() {
    echo -e "\n${YELLOW}=== AKTİF ALERT'LER ===${NC}\n"
    
    # Prometheus Alert'leri
    prometheus_alerts=$(curl -s http://$PROMETHEUS_HOST:$PROMETHEUS_PORT/api/v1/alerts | jq -r '.data.alerts[]? | "\(.labels.alertname)|\(.labels.instance)|\(.state)|\(.activeAt)"')
    
    # AlertManager Alert'leri
    alertmanager_alerts=$(curl -s http://$PROMETHEUS_HOST:9093/api/v1/alerts | jq -r '.[]? | "\(.labels.alertname)|\(.labels.instance)|\(.status.state)|\(.startsAt)"')
    
    if [ -z "$prometheus_alerts" ] && [ -z "$alertmanager_alerts" ]; then
        echo -e "${GREEN}🎉 Aktif alert bulunmuyor!${NC}"
        echo -e "\n${BLUE}📱 Web Dashboard'lardan kontrol edebilirsiniz:${NC}"
        echo -e "   • AlertManager: http://$PROMETHEUS_HOST:9093"
        echo -e "   • Grafana Alerts: http://$PROMETHEUS_HOST:3000/alerting/list"
        echo -e "   • Uptime Kuma: http://$PROMETHEUS_HOST:3001"
    else
        echo -e "${RED}🚨 PROMETHEUS ALERT'LERİ:${NC}"
        if [ ! -z "$prometheus_alerts" ]; then
            echo "$prometheus_alerts" | while IFS='|' read alertname instance state activeat; do
                if [ "$state" = "firing" ]; then
                    echo -e "  ${RED}● $alertname${NC} - $instance ${RED}(FIRING)${NC}"
                else
                    echo -e "  ${YELLOW}● $alertname${NC} - $instance ${YELLOW}($state)${NC}"
                fi
            done
        fi
        
        echo -e "\n${YELLOW}⚠️  ALERTMANAGER ALERT'LERİ:${NC}"
        if [ ! -z "$alertmanager_alerts" ]; then
            echo "$alertmanager_alerts" | while IFS='|' read alertname instance state startsat; do
                if [ "$state" = "active" ]; then
                    echo -e "  ${RED}● $alertname${NC} - $instance ${RED}(ACTIVE)${NC}"
                else
                    echo -e "  ${YELLOW}● $alertname${NC} - $instance ${YELLOW}($state)${NC}"
                fi
            done
        fi
        
        echo -e "\n${BLUE}🌐 Detaylar için web arayüzlerini kontrol edin:${NC}"
        echo -e "   • AlertManager: http://$PROMETHEUS_HOST:9093/#/alerts"
        echo -e "   • Grafana: http://$PROMETHEUS_HOST:3000/alerting/list"
    fi
}

# Log'ları göster
show_logs() {
    echo -e "${YELLOW}=== CONTAINER LOG'LARI ===${NC}\n"
    
    echo "📊 Prometheus son 20 log:"
    docker logs --tail 20 prometheus
    
    echo -e "\n📈 Grafana son 10 log:"
    docker logs --tail 10 grafana
    
    echo -e "\n🚨 AlertManager son 10 log:"
    docker logs --tail 10 alertmanager
}

# Servisleri yeniden başlat
restart_services() {
    echo -e "${YELLOW}=== SERVİSLERİ YENİDEN BAŞLATIYOR ===${NC}\n"
    
    cd /root/monitoring || exit 1
    
    echo "🔄 Docker Compose servisleri durduruluyor..."
    docker-compose down
    
    echo "🔄 Docker Compose servisleri başlatılıyor..."
    docker-compose up -d
    
    echo "⏱️  Servisler başlatılıyor, lütfen bekleyin..."
    sleep 15
    
    check_status
}

# Dashboard URL'lerini göster
show_urls() {
    echo -e "\n${YELLOW}=== WEB MONITORING DASHBOARD'LARI ===${NC}\n"
    
    echo -e "${BLUE}📊 ANA MONITORING SİSTEMLERİ:${NC}"
    echo -e "   • Prometheus: http://$PROMETHEUS_HOST:$PROMETHEUS_PORT"
    echo -e "   • Grafana: http://$PROMETHEUS_HOST:$GRAFANA_PORT (admin/admin123)"
    echo -e "   • AlertManager: http://$PROMETHEUS_HOST:9093"
    echo -e "   • Uptime Kuma: http://$PROMETHEUS_HOST:3001"
    
    echo -e "\n${YELLOW}🚨 ALERT KONTROL SAYFALARI:${NC}"
    echo -e "   • Prometheus Alerts: http://$PROMETHEUS_HOST:$PROMETHEUS_PORT/alerts"
    echo -e "   • AlertManager Alerts: http://$PROMETHEUS_HOST:9093/#/alerts"
    echo -e "   • Grafana Alerting: http://$PROMETHEUS_HOST:$GRAFANA_PORT/alerting/list"
    echo -e "   • Uptime Status: http://$PROMETHEUS_HOST:3001/status"
    
    echo -e "\n${GREEN}📈 METRIC SORGULAMA:${NC}"
    echo -e "   • Prometheus Query: http://$PROMETHEUS_HOST:$PROMETHEUS_PORT/graph"
    echo -e "   • Targets Status: http://$PROMETHEUS_HOST:$PROMETHEUS_PORT/targets"
    
    echo -e "\n${YELLOW}=== ÖNERİLEN GRAFANA DASHBOARD'LARI ===${NC}"
    echo "• Node Exporter Full (ID: 1860) - Sistem metrikleri"
    echo "• Docker Container & Host Metrics (ID: 10619) - Container izleme"
    echo "• System Overview (ID: 11074) - Genel sistem durumu"
    echo "• Prometheus 2.0 Stats (ID: 3662) - Prometheus kendi metrikleri"
    
    echo -e "\n${BLUE}💡 HIZLI ERİŞİM İPUCU:${NC}"
    echo "Bu URL'leri tarayıcı bookmark'larınıza ekleyerek hızlı erişim sağlayabilirsiniz!"
}

# Ana menü
main_menu() {
    show_logo
    
    case "$1" in
        "status"|"s")
            check_status
            show_resources  
            show_alerts
            show_urls
            ;;
        "restart"|"r")
            restart_services
            ;;
        "logs"|"l")
            show_logs
            ;;
        "alerts"|"a")
            show_alerts
            echo -e "\n${BLUE}💡 İPUCU: Alert'ları web arayüzünden de takip edebilirsiniz!${NC}"
            ;;
        "urls"|"u"|"web")
            show_urls
            ;;
        "web-open"|"wo")
            echo -e "${YELLOW}🌐 Ana dashboard'ları tarayıcıda açılıyor...${NC}"
            echo "Grafana: http://$PROMETHEUS_HOST:$GRAFANA_PORT"
            echo "AlertManager: http://$PROMETHEUS_HOST:9093"
            echo "Uptime Kuma: http://$PROMETHEUS_HOST:3001"
            ;;
        "quick"|"q")
            # Hızlı sistem özeti
            echo -e "${BLUE}⚡ HIZLI SİSTEM ÖZETİ${NC}"
            echo "==================="
            
            # Alert sayısı
            alert_count=$(curl -s http://$PROMETHEUS_HOST:$PROMETHEUS_PORT/api/v1/alerts | jq '.data.alerts | length')
            if [ "$alert_count" -gt 0 ]; then
                echo -e "🚨 Aktif Alert: ${RED}$alert_count${NC}"
            else
                echo -e "✅ Alert: ${GREEN}Yok${NC}"
            fi
            
            # Target durumu
            up_targets=$(curl -s http://$PROMETHEUS_HOST:$PROMETHEUS_PORT/api/v1/targets | jq '.data.activeTargets[] | select(.health=="up") | .labels.instance' | wc -l)
            total_targets=$(curl -s http://$PROMETHEUS_HOST:$PROMETHEUS_PORT/api/v1/targets | jq '.data.activeTargets[] | .labels.instance' | wc -l)
            echo -e "📊 Target Status: ${GREEN}$up_targets${NC}/${BLUE}$total_targets${NC} UP"
            
            # En yüksek CPU kullanımı
            max_cpu=$(curl -s "http://$PROMETHEUS_HOST:$PROMETHEUS_PORT/api/v1/query?query=100-(avg by(instance)(rate(node_cpu_seconds_total{mode=\"idle\"}[5m]))*100)" | jq -r '[.data.result[].value[1] | tonumber] | max | floor')
            if [ "$max_cpu" -gt 80 ]; then
                echo -e "🔥 Max CPU: ${RED}$max_cpu%${NC}"
            elif [ "$max_cpu" -gt 60 ]; then
                echo -e "🔥 Max CPU: ${YELLOW}$max_cpu%${NC}"
            else
                echo -e "🔥 Max CPU: ${GREEN}$max_cpu%${NC}"
            fi
            ;;
        *)
            echo "Kullanım: $0 [komut]"
            echo ""
            echo "📊 MONITORING KOMUTLARI:"
            echo "  status (s)    - Tam sistem durumunu kontrol et"
            echo "  quick (q)     - Hızlı sistem özeti"
            echo "  alerts (a)    - Sadece aktif alertleri göster"
            echo "  web (u)       - Web dashboard URL'lerini göster"
            echo ""
            echo "🔧 YÖNETİM KOMUTLARI:"
            echo "  restart (r)   - Servisleri yeniden başlat"  
            echo "  logs (l)      - Container loglarını göster"
            echo ""
            echo "🌐 WEB ERİŞİM:"
            echo "  web-open (wo) - Dashboard URL'lerini göster"
            echo ""
            echo "💡 Örnek: $0 quick  (hızlı durum kontrolü)"
            echo "💡 Örnek: $0 alerts (sadece alert'leri göster)"
            ;;
    esac
}

# Script'i çalıştır
main_menu "$1"
