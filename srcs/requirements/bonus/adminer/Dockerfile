# Debian 12 "Bookworm" is the penultimate stable version (see README for details)
FROM debian:12.15-slim

# Install Adminer and cleanup the apt cache to reduce image size.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        php-cli \
        php-mysqli \
        curl \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create the web root and give ownership to www-data, the user php-fpm runs as. Without this, php-fpm cannot write to Adminer files (uploads, etc.).
RUN mkdir -p /var/www/adminer

# Download Adminer and place it in the web root.
RUN curl -L fsSL https://www.adminer.org/latest-mysql-en.php -o /var/www/adminer/index.php

# Expose port 8080 for the web server.
EXPOSE 8080

# Start php-fpm in the foreground to keep the container running.
ENTRYPOINT ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/adminer"]