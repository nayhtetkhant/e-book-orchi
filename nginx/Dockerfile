FROM nginx:alpine

# Install openssl for dummy certificate generation and curl for health checks
RUN apk add --no-cache openssl bash curl

# Copy startup script into docker-entrypoint.d so it runs before nginx starts
COPY docker-entrypoint.sh /docker-entrypoint.d/40-init-certs.sh
RUN chmod +x /docker-entrypoint.d/40-init-certs.sh
