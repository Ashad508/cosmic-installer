#!/usr/bin/env bash
# Ensure we are using bash
if [ -z "$BASH_VERSION" ]; then
  echo "Error: This script must be run with bash." >&2
  exit 1
fi

set -euo

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Banner ---
clear
echo -e "${BOLD}${BLUE}"
echo "  ██████╗ ██████╗ ███████╗███████╗ ██████╗██╗     ███████╗"
echo " ██╔════╝██╔═══██╗██╔════╝██╔════╝██╔════╝██║     ██╔════╝"
echo " ██║     ██║   ██║█████╗  █████╗  ██║     ██║     █████╗  "
echo " ██║     ██║   ██║██╔══╝  ██╔══╝  ██║     ██║     ██╔══╝  "
echo " ╚██████╗╚██████╔╝███████╗███████╗╚██████╗███████╗███████╗"
echo "  ╚═════╝ ╚═════╝ ╚══════╝╚══════╝ ╚═════╝╚══════╝╚══════╝"
echo -e "${RESET}"
echo -e "${YELLOW}Welcome to the Cosmic Cloud Installer!${RESET}"
echo

# --- Menu ---
echo -e "${BOLD}1) Panel Installation${RESET}"
echo -e "${BOLD}2) Wings Installation${RESET}"
echo -e "${BOLD}3) Blueprint Installation${RESET}"
echo
read -p "Type the number you want to run: " choice

# --- Functions ---
panel_install() {
    echo -e "${GREEN}Installing Pterodactyl Panel...${RESET}"
    read -p "Enter your panel domain (example: panel.cosmic-cloud.fun): " PANEL_DOMAIN
    read -p "Enter admin email: " ADMIN_EMAIL
    read -p "Enter admin username: " ADMIN_USER
    read -sp "Enter admin password: " ADMIN_PASS
    echo

    PANEL_PATH="/var/www/pterodactyl"

    echo -e "${BLUE}Installing dependencies...${RESET}"
    apt update && apt upgrade -y
    apt install -y php-cli php-mbstring php-bcmath php-xml unzip git curl composer nginx mariadb-server php-fpm certbot python3-certbot-nginx

    echo -e "${BLUE}Cloning Pterodactyl panel...${RESET}"
    git clone https://github.com/pterodactyl/panel.git "$PANEL_PATH" || true
    cd "$PANEL_PATH"
    cp .env.example .env
    composer install --no-dev --optimize-autoloader
    php artisan key:generate --force

    # Create admin user
    php artisan p:user:make --email="$ADMIN_EMAIL" --username="$ADMIN_USER" --password="$ADMIN_PASS" --admin

    chown -R www-data:www-data "$PANEL_PATH"
    chmod -R 755 "$PANEL_PATH"

    echo -e "${GREEN}Panel installed! Visit https://${PANEL_DOMAIN}${RESET}"
}

wings_install() {
    echo -e "${GREEN}Installing Wings...${RESET}"
    mkdir -p /etc/pterodactyl
    cd /etc/pterodactyl
    curl -Lo wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
    chmod +x wings
    echo -e "${YELLOW}Paste your wings config in /etc/pterodactyl/config.yml and run it with:${RESET}"
    echo "./wings --config /etc/pterodactyl/config.yml"
    echo -e "${GREEN}Wings installation completed!${RESET}"
}

blueprint_install() {
    echo -e "${GREEN}Installing Blueprint...${RESET}"
    apt-get install -y ca-certificates curl gnupg
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
    apt-get update
    apt-get install -y nodejs zip unzip git curl wget
    npm i -g yarn

    cd /var/www/pterodactyl
    yarn
    wget "$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url' | cut -d '"' -f 4)" -O release.zip
    unzip release.zip
    touch /var/www/pterodactyl/.blueprintrc
    chmod +x blueprint.sh
    bash blueprint.sh
    echo -e "${GREEN}Blueprint installed!${RESET}"
}

# --- Run selected option ---
case $choice in
    1) panel_install ;;
    2) wings_install ;;
    3) blueprint_install ;;
    *) echo -e "${RED}Invalid choice! Exiting.${RESET}" ;;
esac
