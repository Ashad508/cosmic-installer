#!/usr/bin/env bash

# ---- Safety ----
if [ -z "$BASH_VERSION" ]; then
  echo "❌ Please run using bash"
  exit 1
fi

set -eu

# ---- Colors ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
BOLD='\033[1m'
RESET='\033[0m'

clear

# ---- Banner ----
echo -e "${BOLD}${BLUE}"
echo " ██████╗ ██████╗ ███████╗███╗   ███╗██╗ ██████╗"
echo "██╔════╝██╔═══██╗██╔════╝████╗ ████║██║██╔════╝"
echo "██║     ██║   ██║███████╗██╔████╔██║██║██║     "
echo "██║     ██║   ██║╚════██║██║╚██╔╝██║██║██║     "
echo "╚██████╗╚██████╔╝███████║██║ ╚═╝ ██║██║╚██████╗"
echo " ╚═════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝ ╚═════╝"
echo -e "${RESET}"
echo -e "${YELLOW}Cosmic Cloud – Pterodactyl Installer${RESET}"
echo

# ---- Menu ----
echo -e "${BOLD}1) Install Pterodactyl Panel${RESET}"
echo -e "${BOLD}2) Install Wings${RESET}"
echo -e "${BOLD}3) Install Blueprint${RESET}"
echo
read -rp "Type the number you want to run: " choice

# ---- PANEL ----
panel_install() {
  echo -e "${GREEN}Installing Pterodactyl Panel...${RESET}"

  read -rp "Panel domain (example: panel.cosmic-cloud.fun): " PANEL_DOMAIN
  read -rp "Admin email: " ADMIN_EMAIL
  read -rp "Admin username: " ADMIN_USER
  read -rsp "Admin password: " ADMIN_PASS
  echo

  apt update && apt upgrade -y
  apt install -y curl git unzip nginx mariadb-server \
    php-cli php-fpm php-mbstring php-xml php-bcmath composer \
    certbot python3-certbot-nginx

  mkdir -p /var/www/pterodactyl
  cd /var/www/pterodactyl

  git clone https://github.com/pterodactyl/panel.git . || true
  cp .env.example .env

  composer install --no-dev --optimize-autoloader
  php artisan key:generate --force

  php artisan p:user:make \
    --email="$ADMIN_EMAIL" \
    --username="$ADMIN_USER" \
    --password="$ADMIN_PASS" \
    --admin

  chown -R www-data:www-data /var/www/pterodactyl
  chmod -R 755 /var/www/pterodactyl

  certbot --nginx -d "$PANEL_DOMAIN"

  echo -e "${GREEN}Panel installed at https://${PANEL_DOMAIN}${RESET}"
}

# ---- WINGS ----
wings_install() {
  echo -e "${GREEN}Installing Wings...${RESET}"

  apt install -y docker.io
  systemctl enable --now docker

  mkdir -p /etc/pterodactyl
  cd /etc/pterodactyl

  curl -Lo wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
  chmod +x wings

  echo
  echo -e "${YELLOW}Now paste config.yml and run:${RESET}"
  echo "./wings --config /etc/pterodactyl/config.yml"
}

# ---- BLUEPRINT ----
blueprint_install() {
  echo -e "${GREEN}Installing Blueprint...${RESET}"

  apt install -y ca-certificates gnupg curl zip unzip wget
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list

  apt update
  apt install -y nodejs
  npm i -g yarn

  cd /var/www/pterodactyl
  yarn

  wget "$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest \
    | grep browser_download_url | cut -d '"' -f 4)" -O blueprint.zip

  unzip blueprint.zip
  chmod +x blueprin
