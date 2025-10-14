#!/bin/bash

# Database Backup Script V2 - Docker CP Alternative Solution
# Usage: ./backup.sh [database_type] [backup_name]

BACKUP_DIR="/opt/databases/backups"
LOG_DIR="/opt/databases/logs"
DATE=$(date +%Y%m%d_%H%M%S)
DB_PASSWORD="Na9528692"
LOG_FILE="$LOG_DIR/backup_$(date +%Y%m%d).log"

# Create necessary directories
mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to backup MariaDB
backup_mariadb() {
    local backup_name=${1:-"mariadb_backup_$DATE"}
    log "Creating MariaDB backup: $backup_name"
    
    docker exec mariadb mariadb-dump -u root -p$DB_PASSWORD --all-databases > "$BACKUP_DIR/${backup_name}.sql" 2>&1
    
    if [ $? -eq 0 ] && [ -s "$BACKUP_DIR/${backup_name}.sql" ]; then
        gzip "$BACKUP_DIR/${backup_name}.sql"
        local size=$(du -h "$BACKUP_DIR/${backup_name}.sql.gz" | cut -f1)
        log "✓ MariaDB backup completed successfully - Size: $size"
        log "  Location: $BACKUP_DIR/${backup_name}.sql.gz"
        return 0
    else
        log "✗ MariaDB backup failed"
        rm -f "$BACKUP_DIR/${backup_name}.sql"
        return 1
    fi
}

# Function to backup PostgreSQL
backup_postgresql() {
    local backup_name=${1:-"postgresql_backup_$DATE"}
    log "Creating PostgreSQL backup: $backup_name"
    
    docker exec postgresql pg_dumpall -U root > "$BACKUP_DIR/${backup_name}.sql" 2>&1
    
    if [ $? -eq 0 ] && [ -s "$BACKUP_DIR/${backup_name}.sql" ]; then
        gzip "$BACKUP_DIR/${backup_name}.sql"
        local size=$(du -h "$BACKUP_DIR/${backup_name}.sql.gz" | cut -f1)
        log "✓ PostgreSQL backup completed successfully - Size: $size"
        log "  Location: $BACKUP_DIR/${backup_name}.sql.gz"
        return 0
    else
        log "✗ PostgreSQL backup failed"
        rm -f "$BACKUP_DIR/${backup_name}.sql"
        return 1
    fi
}

# Function to backup MongoDB - ALTERNATIVE METHOD
backup_mongodb() {
    local backup_name=${1:-"mongodb_backup_$DATE"}
    log "Creating MongoDB backup: $backup_name"
    
    # Container içinde backup dizinini temizle
    docker exec mongodb rm -rf /tmp/backup 2>/dev/null
    
    # Backup'ı al
    docker exec mongodb mongodump --username root --password $DB_PASSWORD \
        --authenticationDatabase admin --out /tmp/backup >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        # Container içinde tar.gz oluştur ve stdout'a gönder
        docker exec mongodb tar -czf - -C /tmp backup > "$BACKUP_DIR/${backup_name}.tar.gz" 2>&1
        
        if [ $? -eq 0 ] && [ -s "$BACKUP_DIR/${backup_name}.tar.gz" ]; then
            # Geçici dosyaları temizle
            docker exec mongodb rm -rf /tmp/backup 2>/dev/null
            
            local size=$(du -h "$BACKUP_DIR/${backup_name}.tar.gz" | cut -f1)
            log "✓ MongoDB backup completed successfully - Size: $size"
            log "  Location: $BACKUP_DIR/${backup_name}.tar.gz"
            return 0
        else
            log "✗ MongoDB backup failed - tar export error"
            rm -f "$BACKUP_DIR/${backup_name}.tar.gz"
            docker exec mongodb rm -rf /tmp/backup 2>/dev/null
            return 1
        fi
    else
        log "✗ MongoDB backup failed - mongodump error"
        docker exec mongodb rm -rf /tmp/backup 2>/dev/null
        return 1
    fi
}

# Function to backup Redis - ALTERNATIVE METHOD
backup_redis() {
    local backup_name=${1:-"redis_backup_$DATE"}
    log "Creating Redis backup: $backup_name"
    
    # BGSAVE komutunu çalıştır (uyarıyı gizle)
    docker exec redis redis-cli -a $DB_PASSWORD --no-auth-warning BGSAVE >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        # BGSAVE'in tamamlanmasını bekle
        sleep 5
        
        # dump.rdb dosyasını cat ile stdout'a gönder
        docker exec redis cat /data/dump.rdb > "$BACKUP_DIR/${backup_name}.rdb" 2>&1
        
        if [ $? -eq 0 ] && [ -s "$BACKUP_DIR/${backup_name}.rdb" ]; then
            gzip "$BACKUP_DIR/${backup_name}.rdb"
            local size=$(du -h "$BACKUP_DIR/${backup_name}.rdb.gz" | cut -f1)
            log "✓ Redis backup completed successfully - Size: $size"
            log "  Location: $BACKUP_DIR/${backup_name}.rdb.gz"
            return 0
        else
            log "✗ Redis backup failed - cat export error"
            rm -f "$BACKUP_DIR/${backup_name}.rdb"
            return 1
        fi
    else
        log "✗ Redis backup failed - BGSAVE error"
        return 1
    fi
}

# Function to backup all databases
backup_all() {
    log "========================================="
    log "Starting full backup of all databases..."
    log "========================================="
    
    local success_count=0
    local fail_count=0
    
    backup_mariadb "mariadb_full_$DATE" && ((success_count++)) || ((fail_count++))
    backup_postgresql "postgresql_full_$DATE" && ((success_count++)) || ((fail_count++))
    backup_mongodb "mongodb_full_$DATE" && ((success_count++)) || ((fail_count++))
    backup_redis "redis_full_$DATE" && ((success_count++)) || ((fail_count++))
    
    log "========================================="
    log "Full backup completed"
    log "Success: $success_count | Failed: $fail_count"
    log "========================================="
    
    return $fail_count
}

# Function to restore MariaDB
restore_mariadb() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        echo "Usage: restore_mariadb <backup_file.sql.gz>"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        log "✗ Backup file not found: $backup_file"
        return 1
    fi
    
    log "Restoring MariaDB from: $backup_file"
    
    if [[ $backup_file == *.gz ]]; then
        gunzip -c "$backup_file" | docker exec -i mariadb mariadb -u root -p$DB_PASSWORD
    else
        docker exec -i mariadb mariadb -u root -p$DB_PASSWORD < "$backup_file"
    fi
    
    if [ $? -eq 0 ]; then
        log "✓ MariaDB restore completed successfully"
        return 0
    else
        log "✗ MariaDB restore failed"
        return 1
    fi
}

# Function to restore PostgreSQL
restore_postgresql() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        echo "Usage: restore_postgresql <backup_file.sql.gz>"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        log "✗ Backup file not found: $backup_file"
        return 1
    fi
    
    log "Restoring PostgreSQL from: $backup_file"
    
    if [[ $backup_file == *.gz ]]; then
        gunzip -c "$backup_file" | docker exec -i postgresql psql -U root
    else
        docker exec -i postgresql psql -U root < "$backup_file"
    fi
    
    if [ $? -eq 0 ]; then
        log "✓ PostgreSQL restore completed successfully"
        return 0
    else
        log "✗ PostgreSQL restore failed"
        return 1
    fi
}

# Function to restore MongoDB
restore_mongodb() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        echo "Usage: restore_mongodb <backup_file.tar.gz>"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        log "✗ Backup file not found: $backup_file"
        return 1
    fi
    
    log "Restoring MongoDB from: $backup_file"
    
    # Tar dosyasını container'a gönder ve extract et
    cat "$backup_file" | docker exec -i mongodb tar -xzf - -C /tmp
    
    if [ $? -eq 0 ]; then
        # mongorestore ile geri yükle
        docker exec mongodb mongorestore --username root --password $DB_PASSWORD \
            --authenticationDatabase admin /tmp/backup
        
        if [ $? -eq 0 ]; then
            docker exec mongodb rm -rf /tmp/backup
            log "✓ MongoDB restore completed successfully"
            return 0
        else
            log "✗ MongoDB restore failed - mongorestore error"
            docker exec mongodb rm -rf /tmp/backup
            return 1
        fi
    else
        log "✗ MongoDB restore failed - tar extract error"
        return 1
    fi
}

# Function to restore Redis
restore_redis() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        echo "Usage: restore_redis <backup_file.rdb.gz>"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        log "✗ Backup file not found: $backup_file"
        return 1
    fi
    
    log "Restoring Redis from: $backup_file"
    
    # Redis'i durdur
    docker exec redis redis-cli -a $DB_PASSWORD --no-auth-warning SHUTDOWN NOSAVE 2>/dev/null
    sleep 2
    
    # Eski dump.rdb'yi yedekle
    docker exec redis mv /data/dump.rdb /data/dump.rdb.old 2>/dev/null
    
    # Yeni dump.rdb'yi container'a gönder
    if [[ $backup_file == *.gz ]]; then
        gunzip -c "$backup_file" | docker exec -i redis sh -c 'cat > /data/dump.rdb'
    else
        cat "$backup_file" | docker exec -i redis sh -c 'cat > /data/dump.rdb'
    fi
    
    if [ $? -eq 0 ]; then
        # Redis container'ını restart et
        docker restart redis
        sleep 5
        log "✓ Redis restore completed successfully"
        return 0
    else
        log "✗ Redis restore failed"
        return 1
    fi
}

# Function to clean old backups
clean_old_backups() {
    local days=${1:-7}
    log "Cleaning backups older than $days days..."
    
    local count=$(find "$BACKUP_DIR" \( -name "*backup*" -o -name "*full*" \) -type f -mtime +$days 2>/dev/null | wc -l)
    
    if [ $count -gt 0 ]; then
        find "$BACKUP_DIR" \( -name "*backup*" -o -name "*full*" \) -type f -mtime +$days -delete 2>/dev/null
        log "✓ Cleaned $count old backup file(s)"
    else
        log "No old backups found to clean"
    fi
}

# Function to list backups
list_backups() {
    log "Available backups in $BACKUP_DIR:"
    echo ""
    echo "Recent backups (last 20):"
    ls -lht "$BACKUP_DIR" | grep -E "(mariadb|postgresql|mongodb|redis)" | head -20 | awk '{print $9, "-", $5, "-", $6, $7, $8}'
}

# Function to verify backup integrity
verify_backup() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        echo "Usage: verify_backup <backup_file>"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        log "✗ Backup file not found: $backup_file"
        return 1
    fi
    
    log "Verifying backup: $backup_file"
    
    if [[ $backup_file == *.gz ]]; then
        gzip -t "$backup_file" 2>&1
        if [ $? -eq 0 ]; then
            log "✓ Backup file is valid"
            return 0
        else
            log "✗ Backup file is corrupted"
            return 1
        fi
    elif [[ $backup_file == *.tar.gz ]]; then
        tar -tzf "$backup_file" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            log "✓ Backup file is valid"
            return 0
        else
            log "✗ Backup file is corrupted"
            return 1
        fi
    else
        log "✓ Backup file exists"
        return 0
    fi
}

# Function to show backup info
backup_info() {
    log "Backup System Information"
    log "========================="
    log "Backup Directory: $BACKUP_DIR"
    log "Log Directory: $LOG_DIR"
    log ""
    
    # Disk usage
    local disk_usage=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    log "Total Backup Size: $disk_usage"
    
    # Count backups by type
    local mariadb_count=$(ls -1 "$BACKUP_DIR"/mariadb*.gz 2>/dev/null | wc -l)
    local postgresql_count=$(ls -1 "$BACKUP_DIR"/postgresql*.gz 2>/dev/null | wc -l)
    local mongodb_count=$(ls -1 "$BACKUP_DIR"/mongodb*.tar.gz 2>/dev/null | wc -l)
    local redis_count=$(ls -1 "$BACKUP_DIR"/redis*.gz 2>/dev/null | wc -l)
    
    log "MariaDB backups: $mariadb_count"
    log "PostgreSQL backups: $postgresql_count"
    log "MongoDB backups: $mongodb_count"
    log "Redis backups: $redis_count"
}

# Main script logic
case "$1" in
    "mariadb")
        backup_mariadb "$2"
        ;;
    "postgresql")
        backup_postgresql "$2"
        ;;
    "mongodb")
        backup_mongodb "$2"
        ;;
    "redis")
        backup_redis "$2"
        ;;
    "all")
        backup_all
        ;;
    "restore-mariadb")
        restore_mariadb "$2"
        ;;
    "restore-postgresql")
        restore_postgresql "$2"
        ;;
    "restore-mongodb")
        restore_mongodb "$2"
        ;;
    "restore-redis")
        restore_redis "$2"
        ;;
    "clean")
        clean_old_backups "$2"
        ;;
    "list")
        list_backups
        ;;
    "verify")
        verify_backup "$2"
        ;;
    "info")
        backup_info
        ;;
    *)
        echo "Database Backup Script V2 - Docker CP Alternative Solution"
        echo ""
        echo "Usage: $0 {command} [options]"
        echo ""
        echo "Backup Commands:"
        echo "  $0 mariadb [backup_name]       - Backup MariaDB"
        echo "  $0 postgresql [backup_name]    - Backup PostgreSQL"
        echo "  $0 mongodb [backup_name]       - Backup MongoDB (uses tar method)"
        echo "  $0 redis [backup_name]         - Backup Redis (uses cat method)"
        echo "  $0 all                         - Backup all databases"
        echo ""
        echo "Restore Commands:"
        echo "  $0 restore-mariadb <file>      - Restore MariaDB"
        echo "  $0 restore-postgresql <file>   - Restore PostgreSQL"
        echo "  $0 restore-mongodb <file>      - Restore MongoDB"
        echo "  $0 restore-redis <file>        - Restore Redis"
        echo ""
        echo "Maintenance Commands:"
        echo "  $0 clean [days]                - Clean old backups (default: 7 days)"
        echo "  $0 list                        - List recent backups"
        echo "  $0 verify <file>               - Verify backup integrity"
        echo "  $0 info                        - Show backup system info"
        echo ""
        echo "Examples:"
        echo "  $0 all"
        echo "  $0 mongodb test_backup"
        echo "  $0 restore-mariadb /opt/databases/backups/mariadb_full_20251008_020001.sql.gz"
        echo "  $0 clean 14"
        echo "  $0 info"
        exit 1
        ;;
esac

exit $?
