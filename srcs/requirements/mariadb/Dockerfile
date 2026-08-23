# Debian 12 "Bookworm" is the penultimate stable version (see README for details)
FROM debian:12.15-slim

# Install MariaDB and cleanup the apt cache to reduce image size.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        mariadb-server \
        mariadb-client \
        procps &&\
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create the necessary directories for MariaDB and set permissions.
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld    

# Copy the MariaDB configuration file to the appropriate location.
COPY ./conf/mariadb.cnf /etc/mysql/mariadb.conf.d/60-custom.cnf

# Copy the startup script to the container and set execute permissions.
COPY ./tools/mariadb-script.sh /usr/local/bin/mariadb-script.sh
RUN chmod +x /usr/local/bin/mariadb-script.sh

# Expose default port to MariaDB server for external access.
EXPOSE 3306

# Execute startup script to initialize the database and start the MariaDB server.
#USER mysql
ENTRYPOINT ["/usr/local/bin/mariadb-setup.sh"]