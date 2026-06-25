#!/bin/bash
set -e

echo "=========================================="
echo "  MARIA Site Server Setup"
echo "=========================================="

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo "Docker installed. Please log out and back in."
fi

# Install Docker Compose plugin
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo apt install -y docker-compose-plugin
fi

# Install fail2ban
sudo apt install -y fail2ban

# Configure UFW firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp
sudo ufw --force enable

# Create app directory
mkdir -p ~/maria-site
cd ~/maria-site

# Clone repository
echo "Cloning maria-site repository..."
git clone https://github.com/Serg2206/maria-site.git . 2>/dev/null || git pull

# Set DuckDNS token (user should edit this)
if [ ! -f .env ]; then
    cat > .env << "ENVEOF"
DUCKDNS_TOKEN=YOUR_DUCKDNS_TOKEN_HERE
POSTGRES_PASSWORD=maria_secure_password
ENVEOF
    echo "Created .env file. Please edit it with your DuckDNS token."
fi

# Deploy
echo "Deploying MARIA site..."
docker compose up -d

echo ""
echo "=========================================="
echo "  Setup Complete!"
echo "=========================================="
echo ""
echo "IMPORTANT: Edit .env and add your DuckDNS token:"
echo "  nano ~/maria-site/.env"
echo ""
echo "Then run:"
echo "  cd ~/maria-site && ./deploy.sh"
echo ""
echo "URLs (after DuckDNS is configured):"
echo "  Website:  https://maria-site.duckdns.org"
echo "  Grafana:  https://grafana.maria-site.duckdns.org"
echo "  Traefik:  https://traefik.maria-site.duckdns.org"
echo ""
