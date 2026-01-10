#!/bin/bash

set -e
clear

# ==================================================
#        Cosmic Cloud Panel Installer
#                By Shadow_Slayer
#   Pterodactyl Panel & Wings Installer
#   Supports: Ubuntu / Debian
# ==================================================

sleep 2

# --------------------------------------------------
# Root Permission Check
# --------------------------------------------------
if [[ "$EUID" -ne 0 ]]; then
    echo "❌ Please run this installer as root."
    exit 1
fi

# --------------------------------------------------
# Operating System Check
# --------------------------------------------------
if ! grep -qiE "ubuntu|debian" /etc/os-release; then
    echo "❌ This installer supports Ubuntu and Debian only."
    exit 1
fi

# --------------------------------------------------
# Installation Menu
# --------------------------------------------------
echo ""
echo "=========== Cosmic Cloud Installer ==========="
echo "1) Install Pterodactyl Panel"
echo "2) Install Pterodactyl Wings"
echo "3) Install Panel + Wings"
echo "4) Exit"
echo "=============================================="
echo ""

read -rp "Select an option: " OPTION

case "$OPTION" in
    1)
        echo "▶ Installing Pterodactyl Panel..."
        ;;
    2)
        echo "▶ Installing Pterodactyl Wings..."
        ;;
    3)
        echo "▶ Installing Panel + Wings..."
        ;;
    4)
        echo "👋 Exiting installer."
        exit 0
        ;;
    *)
        echo "❌ Invalid option selected."
        exit 1
        ;;
esac

# --------------------------------------------------
# Required Packages
# --------------------------------------------------
echo "📦 Installing required packages..."
apt update -y
apt install -y curl wget sudo unzip tar software-properties-common

# --------------------------------------------------
# Docker Installation (Required for Wings)
# --------------------------------------------------
install_docker() {
    if ! command -v docker &>/dev/null; then
        echo "🐳 Installing Docker..."
        curl -fsSL https://get.docker.com | bash
        systemctl enable docker
        systemctl start docker
    else
        echo "✅ Docker is already installed."
    fi
}

# --------------------------------------------------
# Wings Installation
# --------------------------------------------------
install_wings() {
    install_docker
    echo "🛠 Installing Pterodactyl Wings..."

    mkdir -p /etc/pterodactyl

    curl -L -o /usr/local/bin/wings \
        https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64

    chmod +x /usr/local/bin/wings

cat <<EOF >/etc/systemd/system/wings.service
[Unit]
Description=Pterodactyl Wings
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
ExecStart=/usr/local/bin/wings
Restart=on-failure
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now wings

    echo "✅ Wings installed and started successfully."
}
