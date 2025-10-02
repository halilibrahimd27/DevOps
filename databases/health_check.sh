#!/bin/bash

# Database Health Check Script
# This script checks the health of all database services

DB_PASSWORD="Na9528692"
LOG_FILE="/opt/databases/logs/health_check.log"

# Create log directory if not exists
mkdir -p /opt/databases/logs

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Function to check MariaDB
check_mariadb() {
    log_message "Checking MariaDB..."
    if docker exec mariadb mysqladmin -u root -p$DB_PASSWORD ping >/dev/null 2>&1; then
        log_message "✓ MariaDB is healthy"
        
        # Check connection count
        CONNECTIONS=$(docker exec mariadb mysql -u root -p$DB_PASSWORD -e "SHOW STATUS LIKE 'Threads_connected';" -s -N | awk '{print $2}')
        log_message "  - Active connections: $CONNECTIONS"
        
        # Check slow queries
        SLOW_QUERIES=$(docker exec mariadb mysql -u root -p$DB_PASSWORD -e "SHOW STATUS LIKE 'Slow_queries';" -s -N | awk '{print $2}')
        log_message "  - Slow queries: $SLOW_QUERIES"
        
        return 0
    else
        log_message "✗ MariaDB is not responding"
        return 1
    fi
}

# Function to check PostgreSQL
check_postgresql() {
    log_message "Checking PostgreSQL..."
    if docker exec postgresql pg_isready -U root >/dev/null 2>&1; then
        log_message "✓ PostgreSQL is healthy"
        
        # Check active connections
        CONNECTIONS=$(docker exec postgresql psql -U root -d defaultdb -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null | xargs)
        log_message "  - Active connections: $CONNECTIONS"
        
        return 0
    else
        log_message "✗ PostgreSQL is not responding"
        return 1
    fi
}

# Function to check MongoDB
check_mongodb() {
    log_message "Checking MongoDB..."
    if docker exec mongodb mongosh --username root --password $DB_PASSWORD --authenticationDatabase admin --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
        log_message "✓ MongoDB is healthy"
        
        # Check connection count
        CONNECTIONS=$(docker exec mongodb mongosh --username root --password $DB_PASSWORD --authenticationDatabase admin --eval "db.serverStatus().connections.current" --quiet 2>/dev/null)
        log_message "  - Active connections: $CONNECTIONS"
        
        return 0
    else
        log_message "✗ MongoDB is not responding"
        return 1
    fi
}

# Function to check Redis
check_redis() {
    log_message "Checking Redis..."
    if docker exec redis redis-cli -a $DB_PASSWORD ping >/dev/null 2>&1; then
        log_message "✓ Redis is healthy"
        
        # Check memory usage
        MEMORY=$(docker exec redis redis-cli -a $DB_PASSWORD info memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')
        log_message "  - Memory usage: $MEMORY"
        
        # Check connected clients
        CLIENTS=$(docker exec redis redis-cli -a $DB_PASSWORD info clients | grep connected_clients | cut -d: -f2 | tr -d '\r')
        log_message "  - Connected clients: $CLIENTS"
        
        return 0
    else
        log_message "✗ Redis is not responding"
        return 1
    fi
}

# Function to check disk space
check_disk_space() {
    log_message "Checking disk space..."
    DISK_USAGE=$(df -h /opt/databases | tail -1 | awk '{print $5}' | sed 's/%//')
    log_message "Disk usage: ${DISK_USAGE}%"
    
    if [ $DISK_USAGE -gt 85 ]; then
        log_message "⚠ Warning: Disk usage is above 85%"
        return 1
    elif [ $DISK_USAGE -gt 95 ]; then
        log_message "✗ Critical: Disk usage is above 95%"
        return 2
    else
        log_message "✓ Disk space is adequate"
        return 0
    fi
}

# Function to check container status
check_containers() {
    log_message "Checking container status..."
    
    containers=("mariadb" "postgresql" "mongodb" "redis" "phpmyadmin" "pgadmin" "mongo-express" "redis-commander")
    
    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
            log_message "✓ $container is running"
        else
            log_message "✗ $container is not running"
        fi
    done
}

# Function to generate summary report
generate_summary() {
    log_message "=== HEALTH CHECK SUMMARY ==="
    
    # Overall system health
    mariadb_status=0
    postgresql_status=0
    mongodb_status=0
    redis_status=0
    
    check_mariadb && mariadb_status=1
    check_postgresql && postgresql_status=1
    check_mongodb && mongodb_status=1
    check_redis && redis_status=1
    
    total_healthy=$((mariadb_status + postgresql_status + mongodb_status + redis_status))
    
    log_message "Database Services: $total_healthy/4 healthy"
    check_disk_space
    check_containers
    
    log_message "=== END SUMMARY ==="
}

# Function to send alert (you can integrate with your monitoring system)
send_alert() {
    local message="$1"
    log_message "ALERT: $message"
    
    # You can add webhook, email, or Slack notification here
    # Example webhook:
    # curl -X POST -H 'Content-type: application/json' \
    #   --data "{\"text\":\"Database Alert: $message\"}" \
    #   YOUR_WEBHOOK_URL
}

# Main execution
case "$1" in
    "mariadb")
        check_mariadb
        ;;
    "postgresql")
        check_postgresql
        ;;
    "mongodb")
        check_mongodb
        ;;
    "redis")
        check_redis
        ;;
    "disk")
        check_disk_space
        ;;
    "containers")
        check_containers
        ;;
    "summary"|"")
        generate_summary
        ;;
    *)
        echo "Usage: $0 {mariadb|postgresql|mongodb|redis|disk|containers|summary}"
        exit 1
        ;;
esac
