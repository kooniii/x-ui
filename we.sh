#!/bin/bash
# WireGuard Easy Setup Script
# This script installs Docker and sets up WireGuard Easy container with web UI

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Update system
echo "Updating system packages..."
apt update || { echo "apt update failed"; exit 1; }
apt upgrade -y || { echo "apt upgrade failed"; exit 1; }

# 1. Install Docker
echo "Installing Docker..."
curl -sSL https://get.docker.com | sh || { echo "Docker installation failed"; exit 1; }
systemctl restart docker

# 2. Add current user to Docker group
echo "Adding user to Docker group..."
usermod -aG docker "$(whoami)"

# 3. Get public IPv4 address
echo "Fetching public IPv4..."
PUBLIC_IP=$(curl -4 -s --max-time 10 ifconfig.me)
if [ -z "$PUBLIC_IP" ]; then
  PUBLIC_IP=$(curl -4 -s --max-time 10 https://api.ipify.org)
fi
if [ -z "$PUBLIC_IP" ]; then
  echo "Failed to fetch public IP. Exiting..."
  exit 1
fi
echo "Public IPv4: $PUBLIC_IP"

# 4. Run wg-easy container
echo "Starting wg-easy container..."
mkdir -p ~/.wg-easy
docker run -d \
  --name=wg-easy \
  -e WG_HOST="$PUBLIC_IP" \
  -e PASSWORD=1234 \
  -e WG_DEFAULT_DNS=1.1.1.1 \
  -v ~/.wg-easy:/etc/wireguard \
  -p 51820:51820/udp \
  -p 51821:51821/tcp \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv4.ip_forward=1" \
  --restart unless-stopped \
  weejewel/wg-easy || { echo "Failed to start wg-easy container"; exit 1; }

echo "Setup completed successfully."
echo "WireGuard web interface is available at: https://$PUBLIC_IP:51821"
echo "Default password: 1234"
echo "Please change the default password for security."
