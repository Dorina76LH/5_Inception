# Debian 12 "Bookworm" is the penultimate stable version (see README for details)
FROM debian:12.15-slim

# Install php-fpm, required PHP extensions for WordPress, and tools to fetch
# WordPress/WP-CLI and test the DB connection from the entrypoint script.
# php8.2-fpm is available directly from Debian's official repositories
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        php8.2-fpm \
        php8.2-mysqli \
        php8.2-gd \
        php8.2-curl \
        php8.2-mbstring \
        php8.2-xml \
        php8.2-zip \
        curl \
        ca-certificates \
        mariadb-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Fetch WP-CLI (WordPress Command Line Interface) to script the whole
# WordPress lifecycle (download, config, install, user creation) —
# no manual setup through the web installer, as required by the subject.
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Create the web root and give ownership to www-data, the user php-fpm
# runs as. Without this, php-fpm cannot write to WordPress files
# (uploads, plugin installs, etc.).
RUN mkdir -p /var/www/html && \
    mkdir -p /run/php && \
    chown -R www-data:www-data /var/www/html && \
    chown -R www-data:www-data /run/php

# Adjust php-fpm's pool configuration:
# - listen = 9000 (instead of a local Unix socket) so the nginx
#   container, on another host over the Docker network, can reach it
#   (see fastcgi_pass wordpress:9000 in nginx.conf).
# - clear_env = no: by default php-fpm strips environment variables
#   before running PHP. We need them to stay available (DB credentials
#   passed via the .env/secrets) for wp-config.php and our setup script.
RUN sed -i \
    -e 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|' \
    -e 's|;clear_env = no|clear_env = no|' \
    /etc/php/8.2/fpm/pool.d/www.conf

# Copy the wordpress setup script to the container and set execute permissions.
COPY ./tools/wordpress-setup.sh /usr/local/bin/wordpress-setup.sh
RUN chmod +x /usr/local/bin/wordpress-setup.sh

# Expose port 9000 for php-fpm to listen on, so the nginx container can
# reach it (see fastcgi_pass wordpress:9000 in nginx.conf).
EXPOSE 9000

# PID1 best practice: php-fpm normally daemonizes like nginx does.
# Our entrypoint script ends with "exec php-fpm8.2 -F" to keep it in the
# foreground, so it becomes PID 1 and the container stays alive
# as long as php-fpm runs.
ENTRYPOINT ["/usr/local/bin/wordpress-setup.sh"]