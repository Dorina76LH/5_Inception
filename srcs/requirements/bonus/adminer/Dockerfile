# Debian 12 "Bookworm" is the penultimate stable version (see README for details)
FROM debian:12.15-slim

# Install Adminer and cleanup the apt cache to reduce image size.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        php8.2-fpm &&\
        php8.2-mysqli && \
        curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/

# Create the web root and give ownership to www-data, the user php-fpm runs as. Without this, php-fpm cannot write to Adminer files (uploads, etc.).
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html &&\
    curl -o 