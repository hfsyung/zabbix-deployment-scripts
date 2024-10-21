#!/bin/bash
# ========================================================================
# Script Name: deploy_proxy.sh
# Purpose: Automate the deployment of Zabbix Proxy with SQLite on Debian.
# Author: Hensly F.S. Yung
# Version: 1.1
# ========================================================================
# Description: 
# This script installs Zabbix Proxy with SQLite as the backend database.
# It generates a strong username and password for communication with the Zabbix Server.
# Prior to running, modify the USER variables section to set your preferences.
# ========================================================================

# ===================== USER VARIABLES ======================
read -p "Enter the Zabbix Server IP Address: " ZABBIX_SERVER_IP
read -p "Enter the Proxy name: " PROXY_NAME
ZABBIX_VERSION=$(curl -s https://repo.zabbix.com/zabbix/ | grep -oP '(?<=href=")[0-9]+\.[0-9]+(?=/")' | sort -V | tail -n 1)
PROXY_USER=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c 13) # Auto-generated strong username (13 chars)
PROXY_PASSWORD=$(openssl rand -base64 16)           # Auto-generated strong password

# ===================== SCRIPT START =========================

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing required packages..."
sudo apt install -y wget gnupg2 lsb-release openssl

echo "Adding Zabbix repository..."
wget https://repo.zabbix.com/zabbix/$ZABBIX_VERSION/$(lsb_release -sc)/pool/main/z/zabbix-release_$ZABBIX_VERSION-2+$(lsb_release -sc)_all.deb
sudo dpkg -i zabbix-release_$ZABBIX_VERSION-2+$(lsb_release -sc)_all.deb
sudo apt update

echo "Installing Zabbix Proxy with SQLite support..."
sudo apt install -y zabbix-proxy-sqlite3 sqlite3

echo "Configuring Zabbix Proxy..."
sudo sed -i "s/^# ProxyMode=.*/ProxyMode=0/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^# Server=.*/Server=$ZABBIX_SERVER_IP/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^# Hostname=.*/Hostname=$PROXY_NAME/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^# DBName=.*/DBName=\/var\/lib\/zabbix\/zabbix_proxy.db/" /etc/zabbix/zabbix_proxy.conf

echo "Creating SQLite database for Zabbix Proxy..."
sqlite3 /var/lib/zabbix/zabbix_proxy.db < /usr/share/doc/zabbix-sql-scripts/sqlite3/schema.sql

echo "Restarting Zabbix Proxy..."
sudo systemctl restart zabbix-proxy
sudo systemctl enable zabbix-proxy

# Capture external IP
EXTERNAL_IP=$(curl -s ifconfig.me)

echo "Zabbix Proxy deployment completed successfully."

# ===================== OUTPUT =========================
echo "------------------------------------------------------"
echo "Generated Proxy Username: $PROXY_USER"
echo "Generated Proxy Password: $PROXY_PASSWORD"
echo "Proxy External IP: $EXTERNAL_IP"
echo "------------------------------------------------------"

# ===================== NOTES =========================
# Ports to be opened:
# - 10050: Zabbix Agent (proxy collects data from agents)
# - 10051: Zabbix Proxy (sends data to Zabbix Server)
