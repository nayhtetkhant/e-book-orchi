# Docker Deployment Guide for E-Book Project

This guide covers deploying the entire application stack (`e-book-web`, `e-book-api`, `mysql`, `nginx`, and `certbot`) using Docker Compose.

---

## Architecture Overview

| Service | Technology | Port (Internal) | Port (Host) | Domain / URL |
| :--- | :--- | :--- | :--- | :--- |
| **`nginx`** | Nginx Alpine (Reverse Proxy & SSL termination) | `80`, `443` | `80`, `443` | `https://e-book-fe.tintaungkhant.com`<br>`https://e-book-be.tintaungkhant.com` |
| **`e-book-web`** | Next.js 16 (Standalone SSR Runner) | `3000` | - | Proxied via Nginx |
| **`e-book-api`** | Laravel (PHP 8.4-FPM) | `9000` | - | FastCGI via Nginx |
| **`mysql`** | MySQL 8.4 Server | `3306` | - | Internal container network (`mysql:3306`) |
| **`certbot`** | EFF Certbot (Automated Let's Encrypt renewal) | - | - | Auto-renews every 12 hours |

---

## Prerequisites

1. **DNS Records**: Verify that both domains point to your server's public IP:
   - `e-book-fe.tintaungkhant.com` &rarr; `<SERVER_IP>`
   - `e-book-be.tintaungkhant.com` &rarr; `<SERVER_IP>`
2. **Ports 80 & 443**: Ensure ports 80 and 443 are open on your host firewall (e.g. `ufw allow 80/tcp && ufw allow 443/tcp`).

---

## Quick Start

### 1. Configure Environment Files

Check and update the environment files:
- Root `.env`: controls MySQL password and database name:
  ```bash
  cp .env.example .env
  ```
- Backend `.env`: located at `e-book-api/.env` (contains your App Key, database credentials, AWS/R2 keys, Stripe keys).
- Frontend `.env`: located at `e-book-web/.env`.

### 2. Start the Stack

```bash
docker compose up -d
```

> **Note on SSL**: On the very first launch, Nginx automatically generates temporary self-signed certificates so Nginx starts smoothly without crashing, allowing the ACME challenge on port 80 to succeed immediately.

### 3. Provision Let's Encrypt SSL Certificates

Run the automated SSL script with your email address:

```bash
./init-ssl.sh admin@tintaungkhant.com
```

This will:
1. Verify Nginx is serving `/.well-known/acme-challenge/`.
2. Issue genuine Let's Encrypt certificates for `e-book-fe.tintaungkhant.com` and `e-book-be.tintaungkhant.com`.
3. Reload Nginx to activate HTTP/2 and HTTPS.

---

## Helpful Commands

### View Logs
```bash
# All logs
docker compose logs -f

# Specific service logs
docker compose logs -f nginx
docker compose logs -f e-book-web
docker compose logs -f e-book-api
docker compose logs -f mysql
docker compose logs -f certbot
```

### Run Laravel Artisan Commands
```bash
# Run database migrations
docker compose exec e-book-api php artisan migrate

# Seed database
docker compose exec e-book-api php artisan db:seed

# Clear / optimize cache
docker compose exec e-book-api php artisan optimize:clear
docker compose exec e-book-api php artisan optimize
```

### Restart Services
```bash
# Restart everything
docker compose restart

# Restart Nginx
docker compose restart nginx
```

### Stop Services
```bash
# Stop containers (keeps volumes and database intact)
docker compose down

# Stop and rebuild after code updates
docker compose up -d --build
```
