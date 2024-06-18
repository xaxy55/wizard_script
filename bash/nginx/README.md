# Nginx Helper Script

> :warning: **Warning:** This is under development

This script is designed to assist with configuring and updating Nginx, adding proxy host configurations, managing Cloudflare tokens, install dependent packages and order Certbot SSL certificates.
Below is a detailed guide on how to use the script and its various functions.

## Prerequisites

- Ensure you have the necessary permissions to run the script and modify system files.
- Make sure you have the required packages installed (`whiptail`).

## Optional Configuration

Before running the script, you can create a configuration file named `env.sh` in the same directory. This file can contain default parameters such as `DOMAIN` and `MAIL`.

### Example `env.sh` file
```bash
DOMAIN="example.com"
MAIL="admin@example.com"
CERTBOT_MODE="--dry-run"
```

#
> :bulb: **Tip:** Thanks tteck -
Inspierd by: proxmox VE Helper-Scripts (https://tteck.github.io/)