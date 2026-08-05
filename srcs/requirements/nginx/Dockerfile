# Penultimate stable version of Debian, as required by the subject.
# Debian 13 "Trixie" is the current stable release (since Aug 2025).
# Debian 12 "Bookworm" is therefore the penultimate stable version
# (oldstable since July 2026, now in LTS support until June 2028).
FROM debian:12.15-slim AS nginx

# Install NGNINX and cleanup the apt cache to reduce image size.
# apt-get update is used to update the package lists for the apt package manager.
# apt-get install -y --no-install-recommends is used to avoid installing unnecessary packages.
# nginx and openssl are installed to provide a web server and SSL/TLS support.
# apt-get clean is used to remove the local repository of retrieved package files.
# rm -rf /var/lib/apt/lists/* is used to remove the package lists to reduce image size.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Generate a self-signed TLS certificate for HTTPS support.
# The certificate is valid for 365 days and uses a 2048-bit RSA key.
# nodes option means "no DES", which means the private key will not be encrypted.
# newkey rsa:2048 specifies the key size and type.
# keyout specifies the output file for the private key.
# out specifies the output file for the certificate.
# subj specifies the subject of the certificate, including country (C), state (ST), locality
RUN mkdir -p /etc/nginx/ssl &&\
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=doberes/CN=doberes.42.fr"

# Copy the custom NGINX configuration file into the container.
# ./conf/nginx.conf is the path to the custom NGINX configuration file on the host machine.
# /etc/nginx/sites-available/default is the destination path inside the container where the configuration file will be placed.
COPY ./conf/nginx.conf /etc/nginx/sites-available/default

# Expose port 443 for HTTPS traffic.
EXPOSE 443

# Start NGINX in the foreground to keep the container running.
# PID 1 best practice: In Docker, the main process of a container should run in the foreground (PID 1)
# to ensure proper signal handling and termination. If NGINX were to run in the background,
# the container would exit immediately after starting, as there would be no foreground process to keep it alive.
# The -g "daemon off;" option tells NGINX to run in the foreground instead
ENTRYPOINT ["nginx", "-g", "daemon off;"]