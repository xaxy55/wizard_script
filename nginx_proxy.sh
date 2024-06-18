#!/usr/bin/env bash
source <(cat ./misc/build.func.sh)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# Moded author: xaxy55
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"

███    ██  ██████  ██ ███    ██ ██   ██                                         
████   ██ ██       ██ ████   ██  ██ ██                                          
██ ██  ██ ██   ███ ██ ██ ██  ██   ███                                           
██  ██ ██ ██    ██ ██ ██  ██ ██  ██ ██                                          
██   ████  ██████  ██ ██   ████ ██   ██                                          

EOF
}
header_info
echo -e "Loading..."
APP="Nginx"
var_domain=""
var_mode="--dry-run"
CF_TOKEN_FILE="/etc/letsencrypt/cloudflare.ini"
variables
color
catch_errors

function default_settings() {
  VERB="yes"
  MODE="--dry-run"
  echo_default
}

function update_script() {
  header_info
  if [[ ! -d /var ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  msg_info "Updating ${APP}"
  apt-get update &>/dev/null
  apt-get -y upgrade &>/dev/null
  msg_ok "Updated ${APP}"
  exit
}

function app_new_config_script() {
  header_info
  msg_info "Adding ${APP} host config"
  
  # Example of a Yes/No dialog
  if ! whiptail --backtitle "Proxmox VE Helper Scripts" --title "ADD ${APP} PROXY HOST CONFIG" --yesno "Do you want to add a new proxy host?" 10 58; then
    clear
    msg_error -e "⚠  User exited script \n"
    exit 1
  fi

  # Input host name
  PROXYHOSTNAME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set proxy host name" --title "PROXY HOST NAME" 10 58 3>&1 1>&2 2>&3)
  if [ $? -ne 0 ]; then
    clear
    msg_error -e "⚠  User exited script \n"
    exit 1
  fi

  msg_ok "New proxy host ${PROXYHOSTNAME}.${var_domain}"
  check_cf_token_script

  msg_ok "Added ${APP} proxy host config"
  exit 0
}

function check_cf_token_script() {
  msg_info "Checking if cloudflare .ini file exsist"
  if test -f "$CF_TOKEN_FILE"; then
    msg_ok "Token file exsist"
    if whiptail --backtitle "Certbot" --title "Cloudflare api token" --yesno "Do you want to update exsisting cloudflare token?" 10 58; then
      app_new_token_script
    fi
  else
    app_new_token_script
  fi
}

function app_new_token_script() {
  msg_info "Configure Cloudflare api token"
  START_TOKEN_FILE="dns_cloudflare_api_token="
  touch $CF_TOKEN_FILE &>/dev/null
  sudo chmod 600 $CF_TOKEN_FILE &>/dev/null

  TOKEN=$(whiptail --backtitle "Certbot" --inputbox "Set cloudflare api token" --title "CLOUDFLARE TOKEN" 10 58 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      clear
      msg_error -e "⚠  User exited script \n"
      exit 1
    fi
  
  # Check if CF_TOKEN_FILE starts with START_TOKEN_FILE
  if [[ $(head -n 1 $CF_TOKEN_FILE) == $START_TOKEN_FILE* ]]; then
    msg_info "Cloudflare API token file is already configured correctly."
    #Replase everything after START_TOKEN_FILE string whit new token inputed
    sed -i "s|^${START_TOKEN_FILE}.*|${START_TOKEN_FILE}${TOKEN}|" $CF_TOKEN_FILE
    msg_ok "Updated the existing token in the file"
  else
    # Input cloudflare token
    echo "$START_TOKEN_FILE$TOKEN" >> $CF_TOKEN_FILE
    msg_ok "Created new token file"
  fi
}

start
msg_ok "Completed Successfully!\n"