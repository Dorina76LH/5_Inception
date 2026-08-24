# Debian 12 "Bookworm" is the penultimate stable version (see README for details)
FROM debian:12.15-slim

# Install NGNINX and cleanup the apt cache to reduce image size.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Generate a self-signed TLS certificate.
# Self-signed is expected here: doberes.42.fr is not a real public domain,
# so there is no legitimate CA to issue a certificate for it.
RUN mkdir -p /etc/nginx/ssl &&\
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=doberes/CN=doberes.42.fr"

# Replace the default site config with our own (TLS 1.2/1.3 only,
# reverse proxy to the WordPress container on port 9000).
COPY ./conf/nginx.conf /etc/nginx/sites-available/default

# Copy the index.html file to the default web root.
#COPY ./html/index.html /var/www/html/index.html

# Expose port 443 for HTTPS traffic.
EXPOSE 443

# nginx uses SIGQUIT (not the Docker default SIGTERM) for a graceful
# shutdown that finishes in-flight requests before exiting.
STOPSIGNAL SIGQUIT

# PID 1 best practice: nginx normally daemonizes (forks to background),
# which would make Docker think the container's job is done and stop it.
# "daemon off;" keeps nginx in the foreground as PID 1, so it receives
# signals directly and the container stays alive as long as nginx runs.
ENTRYPOINT ["nginx", "-g", "daemon off;"]