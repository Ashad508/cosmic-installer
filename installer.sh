#!/bin/bash

set -e
clear

echo "========================================="
echo "   Ryzo Cloud Pterodactyl Installer"
echo "   Panel + Wings | Ubuntu Only"
echo "   Made by Arnav Sharma"
echo "========================================="
sleep 2

# Root check
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

# OS check
if ! grep -qi ubuntu /etc/os-release; then
  echo "❌ This installer supports Ubuntu And Debain only"
  exit 1
fi

# Menu
echo ""
echo "1) Install Pterodactyl Panel"
echo "2) Install Pterodactyl Wings"
echo "3) Install Panel + Wings"
echo "4) Exit"
echo ""
read -p "Select option: " option

case $option in

1)
echo "▶ Installing Pterodactyl Panel"
;;

2)
echo "▶ Installing Pterodactyl Wings"
;;

3)
echo "▶ Installing Panel + Wings"
;;

4)
exit 0
;;

*)
echo "❌ Invalid option"
exit 1
;;
esac

# Common packages
apt update -y
apt install -y curl wget sudo unzip tar software-properties-common

# Docker install (for Wings)
install_docker() {
  if ! command -v docker &>/dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com | bash
    systemctl enable docker
    systemctl start docker
  fi
}

# Wings install
install_wings() {
  install_docker
  echo "🛠 Installing Wings..."
  mkdir -p /etc/pterodactyl
  curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
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
