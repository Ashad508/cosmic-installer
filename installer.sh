#!/usr/bin/env bash
# Cosmic Cloud – Pterodactyl Installer
# CRLF + EOF safe version

# ---- Force bash ----
if [ -z "$BASH_VERSION" ]; then
  echo "Please run with bash"
  exit 1
fi

# ---- Auto-fix CRLF if present ----
if grep -q $'\r' "$0" 2>/dev/null; then
  sed -i 's/\r$//' "$0"
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
cat <<'EOF'
 ██████╗ ██████╗ ███████╗███╗   ███╗██╗ ██████╗
██╔════╝██╔═══██╗██╔════╝████╗ ████║██║██╔════╝
██║     ██║   ██║███████╗██╔████╔██║██║██║     
██║     ██║   ██║╚════██║██║╚██╔╝██║██║██║     
╚██████╗╚██████╔╝███████║██║ ╚═╝ ██║██║╚██████╗
 ╚═════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝ ╚═════╝
EOF
echo -e "${RESET}"
echo -e "${YELLOW}Cosmic Cloud – Pterodactyl Installer${RESET}"
echo

# ---- Menu ----
echo -e "${BOLD}1) Install Pterodactyl Panel${RESET}"
echo -e "${BOLD}2) Install Wings${RESET}"
echo -e "${BOLD}3) Install Blueprint${RESET}"
echo
read -rp "Type the number you want to run: " choice
echo

# ---------------- PANEL ----------------
panel_install() {
  echo -e "${GREEN}Installing Pterodactyl Panel...${RESET}"

  read -rp "Panel domain (panel.cosmic-cloud.fun): " PANEL_DOMAIN
  read -rp "Admin email: " ADMIN_EMAIL
  read -rp "Admin username: " ADMIN_USER
  read -rsp "Admin password: " ADMIN_PASS
  echo

  apt update -y
  apt install -y curl git unzip nginx mariadb-server \
    php-cli php-fpm php-mysql php-mbstring php-bcmath php-xml php-curl \
    certbot python3-certbot-nginx composer

  cd /var/www
  rm -rf pterodactyl
  git clone https://github.com/pterodactyl/panel.git pterodactyl
  cd pterodactyl

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

  echo -e "${GREEN}Panel installed successfully!${RESET}"
  echo -e "Visit: https://${PANEL_DOMAIN}"
}

# ---------------- WINGS ----------------
wings_install() {
  echo -e "${GREEN}Installing Wings...${RESET}"

  apt install -y docker.io curl
  systemctl enable --now docker

  mkdir -p /etc/pterodactyl
  cd /etc/pterodactyl

  curl -Lo wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
  chmod +x wings

  echo
  echo -e "${YELLOW}Paste your Wings config into:${RESET}"
  echo "/etc/pterodactyl/config.yml"
  echo
  echo "Run Wings with:"
  echo "./wings --config /etc/pterodactyl/config.yml"
}

# ---------------- BLUEPRINT ----------------
blueprint_install() {
  echo -e "${GREEN}Installing Blueprint...${RESET}"

  apt install -y ca-certificates curl gnupg zip unzip wget
  mkdir -p /etc/apt/keyrings

  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list

  apt update -y
  apt install -y nodejs
  npm i -g yarn

  cd /var/www/pterodactyl
  yarn

  wget "$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest \
    | grep browser_download_url | cut -d '"' -f 4)" -O blueprint.zip

  unzip blueprint.zip
  touch .blueprintrc
  chmod +x blueprint.sh
  bash blueprint.sh

  echo -e "${GREEN}Blueprint installed successfully!${RESET}"
}

# ---- Execute ----
case "$choice" in
  1) panel_install ;;
  2) wings_install ;;
  3) blueprint_install ;;
  *) echo -e "${RED}Invalid option${RESET}" ;;
esac

exit 0
