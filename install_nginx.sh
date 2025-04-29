#!/bin/bash

# Update packages
echo "Updating system packages using apt"
sudo apt update

# Install wget and curl
echo "Installing wget and curl"
sudo apt install -y wget curl

# Install NGINX and NGINX extras
echo "Installing NGINX and the Extras"
sudo apt install -y nginx nginx-extras

# Start the NGINX service
echo "Starting the NGINX service"
sudo systemctl start nginx

# Ensure NGINX is enabled on system boot
echo "Enabling NGINX to start at boot"
sudo systemctl enable nginx

# Download the file (replace URL with actual file URL)
FILE_URL="https://github.com/therepairguytt/bash-scripts/raw/refs/heads/NGINX-Scripts/reverse_proxy.sh"
FILE_NAME="reverse_proxy.sh"

echo "Downloading file from $FILE_URL..."
wget $FILE_URL

# Make the file executable
echo "Changing file permissions to make it executable..."
chmod +x $FILE_NAME

# Output to confirm the script has completed
echo "Script completed successfully!"

# Ask if to run the script now
read -p "Do you want to run the $FILE_NAME script now? (Yy,Nn)" RUN_SCRIPT

if [[ "$RUN_SCRIPT" =~ ^[Yy]$ ]]; then
    # Run the downloaded script
    bash $FILE_NAME
fi