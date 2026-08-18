#!/bin/bash
set -e

# Lecture des secrets Docker (montés comme fichiers, pas comme variables d'env)
# SQL_PASSWORD=$(cat /run/secrets/db_password)
# SQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# Vérifier si la base de données existe déjà dans le volume
if [ -d "/var/lib/mysql/${SQL_DATABASE}" ]; then
    echo "INFO: La base de données existe déjà. Démarrage direct..."
else
    echo "INFO: Première installation de MariaDB. Configuration en cours..."

    # Initialisation des tables système MariaDB
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Démarrage temporaire en arrière-plan
    mysqld_safe --datadir=/var/lib/mysql --user=mysql &

    # Attente active du démarrage du service
    until mysqladmin ping --silent; do
        echo "En attente de MariaDB..."
        sleep 1
    done

    # Exécution des configurations SQL de sécurité et de création
    mariadb -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo "SUCCESS: Configuration initiale terminée."

    # Arrêt propre de l'instance temporaire
    mysqladmin -u root -p"${SQL_ROOT_PASSWORD}" shutdown
    wait
fi

# Démarrage au premier plan (PID 1)
echo "Démarrage de MariaDB en premier plan..."
exec mysqld_safe --datadir=/var/lib/mysql --user=mysql