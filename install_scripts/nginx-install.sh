#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get update
$STD apt-get -y install \
  sudo \
  mc \
  nginx
msg_ok "Installed Dependencies"

msg_info "Installing Python Dependencies"
$STD apt-get install -y \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv \
  python3-certbot \
  python3-certbot-dns-cloudflare
$STD pip3 install certbot-dns-multi
$STD python3 -m venv /opt/certbot/
msg_ok "Installed Python Dependencies"

VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"

msg_info "Setting up Enviroment"
ln -sf /usr/bin/python3 /usr/bin/python
ln -sf /usr/bin/certbot /opt/certbot/bin/certbot

mkdir -p /var/www/html /etc/nginx/logs
mkdir -p /tmp/nginx/body \
  /run/nginx \
  /var/lib/nginx/cache/public \
  /var/lib/nginx/cache/private \
  /var/cache/nginx/proxy_temp

chmod -R 777 /var/cache/nginx
chown root /tmp/nginx

# Unlink the default configuration file
unlink /etc/nginx/sites-enabled/default

# Create a new configuration file for the reverse proxy
cat <<EOL | sudo tee /etc/nginx/sites-available/reverse-proxy > /dev/null
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL
# Link the new configuration file to sites-enabled
sudo ln -s /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/


echo resolver "$(awk 'BEGIN{ORS=" "} $1=="nameserver" {print ($2 ~ ":")? "["$2"]": $2}' /etc/resolv.conf);" >/etc/nginx/conf.d/include/resolvers.conf
sudo nginx -t
msg_ok "Set up Enviroment"

motd_ssh
customize

msg_info "Starting Services"
systemctl enable -q --now nginx
msg_ok "Started Services"

msg_info "Enabling NGINX to start on boot..."
sudo systemctl enable nginx
msg_ok "enabled Services"

msg_info "Cleaning up"
systemctl restart nginx
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"