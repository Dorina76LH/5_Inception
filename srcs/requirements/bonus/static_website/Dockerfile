# Debian 12 "Bookworm" is the penultimate stable version (see README for details)
FROM debian:12.15-slim

# Install a minimal HTTP server
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/static

# Copy the cv page into the container
COPY ./html/index.html .
COPY ./html/cv.pdf .

# Expose port 5000 for the web server.
EXPOSE 5000

# Python's built-in HTTP server will serve the static files in the current directory.
ENTRYPOINT ["python3", "-m", "http.server", "5000"]