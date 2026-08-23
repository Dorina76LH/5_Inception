#!/bin/bash
set -e

# Read Doxker secrets (mounted as files, not env vars)
SQL_PASSWORD=$(cat /run/secrets/db_password)
SQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# Check whether the database already exists in the volume
if [ -d "/var/lib/mysql/${SQL_DATABASE}" ]; then
    echo "INFO: Database already exists. Starting..."
else
    echo "INFO: First Mariadb setup. Configuring..."

    # Initialize MariaDB data directory
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Start MariaDB in the background to perform initial configuration
    mysqld_safe --datadir=/var/lib/mysql --user=mysql &

    # Wait for MariaDB to be ready
    until mysqladmin ping --silent; do
        echo "Waiting for MariaDB..."
        sleep 1
    done

    # Run SQL commands to set up the database, user, and permissions
    mariadb -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo "SUCCESS: Initial setup complete."

    # Clean up: stop the background MariaDB process
    mysqladmin -u root -p"${SQL_ROOT_PASSWORD}" shutdown
    wait
fi

# Start in the foreground (PID 1)
echo "Starting MariaDB in the foreground..."
exec mysqld_safe --datadir=/var/lib/mysql --user=mysql