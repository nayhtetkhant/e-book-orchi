#!/bin/sh
set -e

DOMAINS="e-book-fe.tintaungkhant.com e-book-be.tintaungkhant.com"

# Create dummy self-signed certificates if none exist to allow Nginx to start
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

# Wait briefly for upstream containers to become resolvable in Docker internal DNS
for host in e-book-api e-book-web; do
    echo "[Nginx Init] Checking DNS resolution of $host..."
    retries=0
    max_retries=3
    until getent hosts "$host" >/dev/null 2>&1 || [ $retries -ge $max_retries ]; do
        sleep 1
        retries=$((retries + 1))
    done
    if [ $retries -ge $max_retries ]; then
        echo "[Nginx Init] Note: $host not yet reachable after ${max_retries}s, proceeding with dynamic proxy..."
    else
        echo "[Nginx Init] Successfully resolved $host."
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
