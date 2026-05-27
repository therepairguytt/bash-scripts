#!/bin/bash
set -e

echo "Updating system packages..."
sudo apt update

echo "Installing wget and curl..."
sudo apt install -y wget curl

echo "Installing NGINX and extras..."
sudo apt install -y nginx nginx-extras

echo "Installing certbot with nginx plugin..."
sudo apt install certbot python3-certbot-nginx

echo "Starting and enabling NGINX..."
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl restart nginx

echo "NGINX installed and running."

read -p "Download reverse proxy script? (y/N): " DOWNLOAD_SCRIPT

if [[ "$DOWNLOAD_SCRIPT" =~ ^[Yy]$ ]]; then
    FILE_URL="https://raw.githubusercontent.com/therepairguytt/bash-scripts/refs/heads/NGINX-Scripts/reverse_proxy.sh"
    FILE_NAME="reverse_proxy.sh"

    echo "Downloading script..."
    wget -O $FILE_NAME $FILE_URL

    echo "Making script executable..."
    chmod +x $FILE_NAME

    echo "Downloaded: $FILE_NAME"

    read -p "Run the script now? (y/N): " RUN_SCRIPT

    if [[ "$RUN_SCRIPT" =~ ^[Yy]$ ]]; then
        echo "Running script..."
        bash $FILE_NAME
    fi
fi