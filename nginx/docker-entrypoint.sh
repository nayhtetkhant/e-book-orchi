#!/bin/sh
set -e

DOMAINS="e-book-fe.tintaungkhant.com e-book-be.tintaungkhant.com"

for domain in $DOMAINS; do
    CERT_DIR="/etc/letsencrypt/live/$domain"
    if [ ! -f "$CERT_DIR/fullchain.pem" ] || [ ! -f "$CERT_DIR/privkey.pem" ]; then
        echo "[Nginx Init] Missing certificate for $domain. Creating dummy self-signed certificate..."
        mkdir -p "$CERT_DIR"
        openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
            -keyout "$CERT_DIR/privkey.pem" \
            -out "$CERT_DIR/fullchain.pem" \
            -subj "/CN=localhost" 2>/dev/null
        echo "[Nginx Init] Created dummy certificate for $domain."
    fi
done

# Start background reload loop every 12 hours so renewed certs are picked up
(
    while true; do
        sleep 12h
        echo "[Nginx Reload] Checking/Reloading Nginx configuration..."
        nginx -s reload 2>/dev/null || true
    done
) &
