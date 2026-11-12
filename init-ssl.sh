#!/bin/bash
set -e

EMAIL="${1}"

if [ -z "$EMAIL" ]; then
    echo "Usage: ./init-ssl.sh <your-email@example.com>"
    echo "Example: ./init-ssl.sh admin@tintaungkhant.com"
    exit 1
fi

DOMAINS=("e-book-fe.tintaungkhant.com" "e-book-be.tintaungkhant.com")

echo "=========================================================="
echo " Starting Let's Encrypt SSL certificate provisioning"
echo " Domains: ${DOMAINS[*]}"
echo " Notification Email: $EMAIL"
echo "=========================================================="

echo "Starting nginx container to serve ACME challenge..."
docker compose up -d nginx

# Wait for nginx to be ready
echo "Waiting for Nginx to become available..."
sleep 3

for DOMAIN in "${DOMAINS[@]}"; do
    echo "----------------------------------------------------------"
    echo "Requesting SSL certificate for: $DOMAIN"
    echo "----------------------------------------------------------"
    
    docker compose run --rm --entrypoint "\
        certbot certonly --webroot -w /var/www/certbot \
            --email $EMAIL \
            -d $DOMAIN \
            --rsa-key-size 4096 \
            --agree-tos \
            --force-renewal \
            --non-interactive" certbot
done

echo "----------------------------------------------------------"
echo "Reloading Nginx with real SSL certificates..."
docker compose exec nginx nginx -s reload

echo "=========================================================="
echo "SSL provisioning successfully completed!"
echo "Frontend: https://e-book-fe.tintaungkhant.com"
echo "Backend:  https://e-book-be.tintaungkhant.com"
echo "=========================================================="
