#!/bin/bash

# === First user input prompt ===
read -p "Enter a name for the NGINX reverse proxy config file (no spaces e.g MYAPP): " FILENAME
read -p "Enter one or more server domains without protocol (space-separated, e.g., domain.com myapp.domain.com): " SERVER_DOMAINS
read -p "Enter the protocol to the local host (http or https): " PROTOCOL
read -p "Enter the local IP (e.g., 192.168.100.125): " LOCAL_IP
read -p "Enter the local port (e.g., 8096): " LOCAL_PORT

# === Create proxy target with the user inputs for the proxy_pass ===
PROXY_TARGET="${PROTOCOL}://${LOCAL_IP}:${LOCAL_PORT}"

# === Create log directory and per-run log file ===
LOG_NAME="${FILENAME}_proxy"
LOG_DIR="/var/log/nginx_proxy_setup"
TIMESTAMP=$(date +"%d-%m-%Y_%H:%M:%S")
LOG_FILE="${LOG_DIR}/${LOG_NAME}_${TIMESTAMP}.log"

sudo mkdir -p "$LOG_DIR"
sudo touch "$LOG_FILE"
sudo chmod 644 "$LOG_FILE"

# === Logging function ===
log() {
    local LEVEL=$1
    local MESSAGE=$2
    TS=$(date +"%d-%m-%Y %H:%M:%S")
    echo -e "[$LEVEL] $TS: $MESSAGE" | tee -a "$LOG_FILE"
}

# === Build config paths ===
CONFIG_NAME="${FILENAME}_proxy"
CONFIG_FILE="/etc/nginx/sites-available/${CONFIG_NAME}"
ENABLED_LINK="/etc/nginx/sites-enabled/${CONFIG_NAME}"

log "INFO" "Creating NGINX reverse proxy config file: $CONFIG_FILE"
log "INFO" "The domains [${SERVER_DOMAINS}] will proxy to $PROXY_TARGET"

# === Create Nginx config ===
sudo tee "$CONFIG_FILE" > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name ${SERVER_DOMAINS};

    location / {
        proxy_pass ${PROXY_TARGET};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        client_max_body_size 0;
    }
}
EOF

log "SUCCESS" "NGINX reverse proxy config file created at: $CONFIG_FILE"

# === Enable site via symlink ===
if [ ! -e "$ENABLED_LINK" ]; then
    sudo ln -s "$CONFIG_FILE" "$ENABLED_LINK"
    log "SUCCESS" "Symlink created to sites-enabled: $ENABLED_LINK"
else
    log "WARNING" "Symlink already exists: $ENABLED_LINK"
fi

# === Test and reload Nginx ===
log "INFO" "Testing NGINX reverse proxy configuration..."
if sudo nginx -t; then
    sudo systemctl reload nginx
    log "SUCCESS" "NGINX reverse proxy configuration is valid and reloaded."
else
    log "ERROR" "NGINX reverse proxy config test failed. Fix the config before continuing."
	log "ERROR" "NGINX reverse proxy config file can be found at $CONFIG_FILE"
    exit 1
fi

# === Ask if Certbot should be run ===
log "INFO" "To enable HTTPS for this domain with a valid SSL certificate from LetsEncrypt, port 80 & 443 must be open and pointed to this server and a valid domain must be pointed to this servers public IP."
read -p "Would you like to enable HTTPS for these domains? (Yy/Nn): " RUN_CERTBOT

if [[ "$RUN_CERTBOT" =~ ^[Yy]$ ]]; then
    # Convert space-separated list into -d args
    DOMAIN_ARGS=""
    for DOMAIN in $SERVER_DOMAINS; do
        DOMAIN_ARGS+=" -d $DOMAIN"
    done

    log "INFO" "Running Certbot for domains:$DOMAIN_ARGS"
    sudo certbot --nginx $DOMAIN_ARGS
    log "DONE" "HTTPS enabled for: $SERVER_DOMAINS"
else
    log "INFO" "Skipping Certbot. HTTPS not enabled."
fi

log "INFO" "Log file saved to: $LOG_FILE"