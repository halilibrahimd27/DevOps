# Docker compose dosyasından version satırını kaldır (eğer varsa)
sed -i '/^version:/d' docker-compose.yml

# PostgreSQL admin izinleri
chown -R 5050:5050 /opt/databases/pgadmin

# Log ve backup dizini izinleri
mkdir -p /opt/databases/logs /opt/databases/backups
chmod 755 /opt/databases/logs
chmod 755 /opt/databases/backups

# Script izinleri
chmod +x /opt/databases/backup.sh 2>/dev/null || true
chmod +x /opt/databases/health_check.sh 2>/dev/null || true
chmod +x /opt/databases/setup_security.sh 2>/dev/null || true

# Nginx dosya izinleri
chmod 644 /opt/databases/nginx/.htpasswd 2>/dev/null || true
chmod 644 /opt/databases/nginx/nginx.conf
chmod 644 /opt/databases/nginx/html/index.html


# Stop any running containers
docker-compose down --remove-orphans

# Move to home directory or /var/snap area
sudo mkdir -p /var/snap/docker/common/databases
sudo cp -r /opt/databases/* /var/snap/docker/common/databases/
cd /var/snap/docker/common/databases

# Fix ownership
sudo chown -R ays:ays /var/snap/docker/common/databases/

# pgadmin klasörü oluştur ve izinleri düzelt
sudo mkdir -p ./pgadmin
sudo chown -R 5050:5050 ./pgadmin
sudo chmod -R 755 ./pgadmin

# Start containers
docker-compose up -d
