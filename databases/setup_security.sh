#!/bin/bash

# Database Security Setup Script for CRM DB
WORK_DIR="/opt/databases"
NGINX_DIR="$WORK_DIR/nginx"
USERNAME="root"
PASSWORD="Na9528692"
DOMAIN="crm-db.local"
SERVER_IP="172.168.20.159"

echo "🔐 Setting up CRM database security..."

# Create nginx directories (already exists)
mkdir -p $NGINX_DIR/ssl
mkdir -p $NGINX_DIR/conf.d

# Install apache2-utils for htpasswd (if not installed)
apt update
apt install -y apache2-utils openssl

# SSL certificate already created above

# Set proper permissions
chmod 600 $NGINX_DIR/ssl/key.pem
chmod 644 $NGINX_DIR/ssl/cert.pem
chmod 644 $NGINX_DIR/.htpasswd

# Create firewall rules
echo "🔥 Updating firewall rules..."
ufw delete allow 8081/tcp 2>/dev/null || true
ufw delete allow 8082/tcp 2>/dev/null || true  
ufw delete allow 8083/tcp 2>/dev/null || true
ufw delete allow 8084/tcp 2>/dev/null || true
ufw delete allow 8085/tcp 2>/dev/null || true

# Only allow access through nginx
ufw allow 80/tcp
ufw allow 443/tcp

echo "✅ CRM DB Security setup completed!"
echo ""
echo "📋 Access Information:"
echo "  Main Panel: https://$SERVER_IP"
echo "  Username: $USERNAME"
echo "  Password: $PASSWORD"
echo ""
echo "🔐 Individual Admin Panels:"
echo "  phpMyAdmin: https://$SERVER_IP/phpmyadmin/"
echo "  pgAdmin: https://$SERVER_IP/pgadmin/"
echo "  Mongo Express: https://$SERVER_IP/mongo/"
echo "  Redis Commander: https://$SERVER_IP/redis/"
echo "  Adminer: https://$SERVER_IP/adminer/"
