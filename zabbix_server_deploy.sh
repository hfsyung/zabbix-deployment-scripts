#!/bin/bash
# ========================================================================
# Script Name: deploy_zabbix.sh
# Purpose: Automate the deployment of Zabbix Server with PostgreSQL on Debian.
# Author: Hensly F.S. Yung
# Version: 1.1
# ========================================================================
# Description: 
# This script installs Zabbix Server with PostgreSQL as the backend database.
# It generates a strong username and password for the database and automates the setup.
# Prior to running, modify the USER variables section to set your preferences.
# ========================================================================

# ===================== USER VARIABLES ======================
DB_USER=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c 13) # Auto-generated strong username (13 chars)
DB_PASSWORD=$(openssl rand -base64 16)                               # Auto-generated strong password
ZABBIX_VERSION=$(curl -s https://repo.zabbix.com/zabbix/ | grep -oP '(?<=href=")[0-9]+\.[0-9]+(?=/")' | sort -V | tail -n 1)

# ===================== SCRIPT START =========================

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing required packages..."
sudo apt install -y wget gnupg2 lsb-release openssl

echo "Adding Zabbix repository..."
wget https://repo.zabbix.com/zabbix/$ZABBIX_VERSION/$(lsb_release -sc)/pool/main/z/zabbix-release/zabbix-release_$ZABBIX_VERSION-2+$(lsb_release -sc)_all.deb
sudo dpkg -i zabbix-release_$ZABBIX_VERSION-2+$(lsb_release -sc)_all.deb
sudo apt update

echo "Installing Zabbix Server, Frontend, and PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib zabbix-server-pgsql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts

echo "Configuring PostgreSQL for Zabbix..."
sudo -u postgres psql -c "CREATE DATABASE zabbix;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE zabbix TO $DB_USER;"

echo "Initializing Zabbix database schema..."
sudo -u postgres zcat /usr/share/doc/zabbix-sql-scripts/postgresql/server.sql.gz | psql -U $DB_USER -d zabbix

echo "Configuring Zabbix Server..."
sudo sed -i "s/^# DBPassword=.*/DBPassword=$DB_PASSWORD/" /etc/zabbix/zabbix_server.conf

echo "Restarting Zabbix and Apache..."
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2

# Capture external IP
EXTERNAL_IP=$(curl -s ifconfig.me)

echo "Zabbix Server deployment completed successfully."

# ===================== OUTPUT =========================
echo "------------------------------------------------------"
echo "Generated DB Username: $DB_USER"
echo "Generated DB Password: $DB_PASSWORD"
echo "Server External IP: $EXTERNAL_IP"
echo "------------------------------------------------------"

# ===================== NOTES =========================
# Ports to be opened:
# - 10051: Zabbix Server (receives data from proxies and agents)
# - 80 or 443: HTTP/HTTPS access for Zabbix frontend

# ============= Configure Zabbix Frontend =============
echo "Open Zabbix Web Interface:"
echo "Access the frontend via your server’s IP or domain: http://$EXTERNAL_IP/zabbix."
echo "Complete the initial configuration wizard by entering the PostgreSQL database credentials you created earlier."
