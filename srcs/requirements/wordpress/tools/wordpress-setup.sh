#!/bin/bash
set -e

echo "INFO: Starting WordPress setup..."

# --- STEP 1 : Read Docker secrets (mounted as files, not env vars) ---
echo "INFO: Reading Docker secrets..."
SQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(grep WP_ADMIN_PASSWORD /run/secrets/credentials | cut -d '=' -f2)
WP_USER_PASSWORD=$(grep WP_USER_PASSWORD /run/secrets/credentials | cut -d '=' -f2)

# --- STEP 2 : Wait for MariaDB to be ready ---
# Wordpress will fail to install if the database is not ready,
# so we wait for it to be ready before proceeding.
echo "INFO: Waiting for MariaDB to be ready..."
TIMEOUT=60
ELLAPSED=0
until mariadb -h mariadb -u "${SQL_USER}" -p"${SQL_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; do
    if [ $ELLAPSED -ge $TIMEOUT ]; then
        echo "ERROR: MariaDB is not ready after ${TIMEOUT} seconds. Exiting."
        exit 1
    fi
    echo "INFO: MariaDB is not ready yet. Waiting..."
    sleep 2
    ELLAPSED=$((ELLAPSED + 2))
done
echo "INFO: MariaDB is ready."


# --- STEP 3 : Install WordPress ---

# Move to var/www/html
cd /var/www/html

echo "INFO: Installing WordPress..."

if [ -f "/var/www/html/wp-config.php" ]; then
    echo "INFO: WordPress is already installed."
else
    # Download WordPress core files
    wp core download --allow-root
    
    # Create wp-config.php with DB connection info
    wp config create \
        --dbname="${SQL_DATABASE}" \
        --dbuser="${SQL_USER}" \
        --dbpass="${SQL_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root

    # Install WordPress (creates tables, admin user) without the web installer
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root

    # Create the second non-admin user (required by the subject)
    wp user create \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    echo "INFO: WordPress installation completed."
fi

# STEP 4 : Ensure php-fpm (running as www-data) has write permissions to the WordPress files
echo "INFO: Setting permissions for WordPress files..."
chown -R www-data:www-data /var/www/html

# STEP 5 : Start php-fpm in the foreground (so the container doesn't exit)
echo "INFO: Starting php-fpm..."
exec php-fpm8.2 -F
