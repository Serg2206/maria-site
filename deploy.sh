#!/bin/bash
set -e

echo "=== MARIA Site Deployment ==="

# Update DuckDNS IP (replace YOUR_TOKEN with actual token)
if [ -n "$DUCKDNS_TOKEN" ]; then
  curl -s "https://www.duckdns.org/update/maria-site/$DUCKDNS_TOKEN/$(curl -s ifconfig.me)"
  echo "DuckDNS IP updated"
fi

# Deploy
docker compose up -d

echo "=== Deployed ==="
echo "Website: https://maria-site.duckdns.org"
echo "Grafana: https://grafana.maria-site.duckdns.org"
echo "Traefik: https://traefik.maria-site.duckdns.org"
