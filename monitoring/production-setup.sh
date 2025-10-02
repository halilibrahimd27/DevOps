#!/bin/bash

# Production Monitoring Setup Script
# Run this script on the monitoring server (172.168.20.153)

set -e

echo "🚀 Starting Production Monitoring Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Update system
echo -e "${YELLOW}📦 Updating system packages...${NC}"
apt update && apt upgrade -y

# Install required packages
echo -e "${YELLOW}📦 Installing required packages...${NC}"
apt install -y \
    docker.io \
    docker-compose \
    curl \
    wget \
    jq \
    htop \
    unzip \
    git \
    ufw \
    fail2ban

# Start and enable Docker
echo -e "${YELLOW}🐳 Setting up Docker...${NC}"
systemctl start docker
systemctl enable docker
usermod -aG docker $USER

# Create monitoring user
echo -e "${YELLOW}👤 Creating monitoring user...${NC}"
if ! id "monitoring" &>/dev/null; then
    useradd -m -s /bin/bash monitoring
    usermod -aG docker monitoring
    echo "monitoring:MonitoringUser2024!" | chpasswd
fi

# Set up directory permissions
echo -e "${YELLOW}📁 Setting up directories...${NC}"
mkdir -p /opt/monitoring
cp -r . /opt/monitoring/
chown -R monitoring:monitoring /opt/monitoring
chmod -R 755 /opt/monitoring

# Create .env file
echo -e "${YELLOW}⚙️ Creating environment configuration...${NC}"
if [ ! -f /opt/monitoring/.env ]; then
    cp /opt/monitoring/.env.example /opt/monitoring/.env
    echo -e "${BLUE}📝 Please edit /opt/monitoring/.env with your actual credentials${NC}"
fi

# Set up firewall
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
ufw --force enable
ufw allow ssh
ufw allow 9090/tcp comment "Prometheus"
ufw allow 3000/tcp comment "Grafana"
ufw allow 9093/tcp comment "AlertManager"
ufw allow 3001/tcp comment "Uptime Kuma"
ufw allow 3100/tcp comment "Loki"

# Configure fail2ban
echo -e "${YELLOW}🛡️ Setting up fail2ban...${NC}"
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true

[grafana]
enabled = true
port = 3000
filter = grafana
logpath = /var/log/grafana/grafana.log
maxretry = 3

[prometheus]
enabled = true
port = 9090
filter = prometheus
logpath = /var/log/prometheus.log
maxretry = 3
EOF

systemctl restart fail2ban

# Create systemd service for monitoring stack
echo -e "${YELLOW}⚙️ Creating systemd service...${NC}"
cat > /etc/systemd/system/monitoring-stack.service <<EOF
[Unit]
Description=Production Monitoring Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/monitoring
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
User=monitoring
Group=monitoring

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable monitoring-stack.service

# Create backup script
echo -e "${YELLOW}💾 Setting up backup automation...${NC}"
cat > /opt/monitoring/backup.sh <<'EOF'
#!/bin/bash

BACKUP_DIR="/backup/monitoring"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup Prometheus data
docker-compose exec -T prometheus tar czf - /prometheus | gzip > $BACKUP_DIR/prometheus_$DATE.tar.gz

# Backup Grafana data
docker-compose exec -T grafana tar czf - /var/lib/grafana | gzip > $BACKUP_DIR/grafana_$DATE.tar.gz

# Backup configurations
tar czf $BACKUP_DIR/configs_$DATE.tar.gz \
    prometheus/config/ \
    grafana/provisioning/ \
    alertmanager/config/ \
    loki-config.yml \
    promtail-config.yml

# Cleanup old backups (keep 7 days)
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /opt/monitoring/backup.sh

# Add backup to crontab
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/monitoring/backup.sh >> /var/log/monitoring-backup.log 2>&1") | crontab -

# Create log rotation
cat > /etc/logrotate.d/monitoring <<EOF
/var/log/monitoring-backup.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
EOF

# Set up monitoring scripts
echo -e "${YELLOW}📜 Installing monitoring scripts...${NC}"
cp vm.sh /usr/local/bin/monitoring-status
cp monitoring-prod.sh /usr/local/bin/monitoring-prod
chmod +x /usr/local/bin/monitoring-*

# Create aliases
cat >> /home/monitoring/.bashrc <<EOF

# Monitoring aliases
alias mon='monitoring-status'
alias mon-prod='monitoring-prod'
alias mon-logs='docker-compose -f /opt/monitoring/docker-compose.yml logs -f'
alias mon-restart='sudo systemctl restart monitoring-stack'
alias mon-status='sudo systemctl status monitoring-stack'
EOF

echo -e "${GREEN}✅ Production monitoring setup completed!${NC}"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Edit /opt/monitoring/.env with your credentials"
echo "2. Start the monitoring stack: cd /opt/monitoring && docker-compose up -d"
echo "3. Access Grafana: http://172.168.20.153:3000"
echo "4. Access Prometheus: http://172.168.20.153:9090"
echo "5. Access AlertManager: http://172.168.20.153:9093"
echo ""
echo -e "${YELLOW}🔧 Useful Commands:${NC}"
echo "- mon: Quick system status"
echo "- mon-prod: Production monitoring commands"
echo "- mon-logs: View container logs"
echo "- mon-restart: Restart monitoring stack"
echo ""
echo -e "${GREEN}🎉 Happy Monitoring!${NC}"