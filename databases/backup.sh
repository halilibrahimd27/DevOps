#!/bin/bash

# Database Backup Script
# Usage: ./backup.sh [database_type] [backup_name]

BACKUP_DIR="/opt/databases/backups"
DATE=$(date +%Y%m%d_%H%M%S)
DB_PASSWORD="Na9528692"

# Create backup directory if not exists
mkdir -p $BACKUP_DIR

# Function to backup MariaDB
backup_mariadb() {
    local backup_name=${1:-"mariadb_backup_$DATE"}
    echo "Creating MariaDB backup: $backup_name"
    docker exec mariadb mysqldump -u root -p$DB_PASSWORD --all-databases > "$BACKUP_DIR/${backup_name}.sql"
    if [ $? -eq 0 ]; then
        echo "MariaDB backup completed successfully"
        gzip "$BACKUP_DIR/${backup_name}.sql"
    else
        echo "MariaDB backup failed"
    fi
}

# Function to backup PostgreSQL
backup_postgresql() {
    local backup_name=${1:-"postgresql_backup_$DATE"}
    echo "Creating PostgreSQL backup: $backup_name"
    docker exec postgresql pg_dumpall -U root > "$BACKUP_DIR/${backup_name}.sql"
    if [ $? -eq 0 ]; then
        echo "PostgreSQL backup completed successfully"
        gzip "$BACKUP_DIR/${backup_name}.sql"
    else
        echo "PostgreSQL backup failed"
    fi
}

# Function to backup MongoDB
backup_mongodb() {
    local backup_name=${1:-"mongodb_backup_$DATE"}
    echo "Creating MongoDB backup: $backup_name"
    docker exec mongodb mongodump --username root --password $DB_PASSWORD --authenticationDatabase admin --out /tmp/backup
    docker cp mongodb:/tmp/backup "$BACKUP_DIR/$backup_name"
    if [ $? -eq 0 ]; then
        echo "MongoDB backup completed successfully"
        tar -czf "$BACKUP_DIR/${backup_name}.tar.gz" -C "$BACKUP_DIR" "$backup_name"
        rm -rf "$BACKUP_DIR/$backup_name"
    else
        echo "MongoDB backup failed"
    fi
}

# Function to backup Redis
backup_redis() {
    local backup_name=${1:-"redis_backup_$DATE"}
    echo "Creating Redis backup: $backup_name"
    docker exec redis redis-cli -a $DB_PASSWORD BGSAVE
    sleep 5
    docker cp redis:/data/dump.rdb "$BACKUP_DIR/${backup_name}.rdb"
    if [ $? -eq 0 ]; then
        echo "Redis backup completed successfully"
        gzip "$BACKUP_DIR/${backup_name}.rdb"
    else
        echo "Redis backup failed"
    fi
}

# Function to backup all databases
backup_all() {
    echo "Starting full backup of all databases..."
    backup_mariadb "mariadb_full_$DATE"
    backup_postgresql "postgresql_full_$DATE"
    backup_mongodb "mongodb_full_$DATE"
    backup_redis "redis_full_$DATE"
    echo "Full backup completed"
}

# Function to restore MariaDB
restore_mariadb() {
    local backup_file=$1
    if [ -z "$backup_file" ]; then
        echo "Usage: restore_mariadb <backup_file.sql.gz>"
        return 1
    fi
    
    echo "Restoring MariaDB from: $backup_file"
    if [[ $backup_file == *.gz ]]; then
        gunzip -c "$backup_file" | docker exec -i mariadb mysql -u root -p$DB_PASSWORD
    else
        docker exec -i mariadb mysql -u root -p$DB_PASSWORD < "$backup_file"
    fi
}

# Function to clean old backups
clean_old_backups() {
    local days=${1:-7}
    echo "Cleaning backups older than $days days..."
    find $BACKUP_DIR -name "*backup*" -type f -mtime +$days -delete
    echo "Old backups cleaned"
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
    "clean")
        clean_old_backups "$2"
        ;;
    *)
        echo "Usage: $0 {mariadb|postgresql|mongodb|redis|all|restore-mariadb|clean} [backup_name|backup_file|days]"
        echo ""
        echo "Examples:"
        echo "  $0 mariadb my_backup"
        echo "  $0 all"
        echo "  $0 restore-mariadb /path/to/backup.sql.gz"
        echo "  $0 clean 7"
        exit 1
        ;;
esac
