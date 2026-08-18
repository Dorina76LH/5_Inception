# =========================================================
# Inception - Makefile
# =========================================================


# ---------------------------------------------------------
# Variables
# ---------------------------------------------------------
LOGIN				= doberes
PROJECT_NAME		= inception
COMPOSE_FILE		= srcs/docker-compose.yml
COMPOSE				= docker compose -f $(COMPOSE_FILE) --project-name $(PROJECT_NAME)

# Path required by the subject: /home/login/data
DATA_DIR			= /home/$(LOGIN)/data

#---------------------------------------------------------
# Volumes
#---------------------------------------------------------

# Create the host directories for MariaDB and WordPress persistent data
data_dirs:
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress

# ---------------------------------------------------------
# Build and start containers
# ---------------------------------------------------------

# Default target : create data directories and start all containers in detached mode
all: data_dirs up

# Build images (if needed) and start containers in the background
# Containers keep running after the command ends.
up:
	@echo "Starting Inception ..."
	$(COMPOSE) up --build -d

# Restart containers that were stopped with "make stop"
# Does not rebuild nor images, nor containers 
start:
	@echo "Starting Inception ..."
	$(COMPOSE) start

# ---------------------------------------------------------
# Stop and remove containers
# ---------------------------------------------------------

# Stop and remove containers + network
# Volumes (persistent data) are kept
down:
	@echo "Stopping and removing containers..."
	$(COMPOSE) down

# Stop containers without removing them
# Use "make start" afterwards to restart services
stop: 
	@echo "Stopping Inception ..."
	$(COMPOSE) stop

# Remove containers, then rebuild and restart everything
# Volumes are kept, so persistent data survives (e.g. DB)
restart: down up

# ---------------------------------------------------------
# Clean containers and volumes
# ---------------------------------------------------------

# Remove containers, network AND volumes (-v), then prune
# unused Docker images/cache.
# Data inside volumes is lost, but DATA_DIR itself is kept.
clean:
	@echo "Cleaning Inception (containers, volumes, unused images) ..."
	$(COMPOSE) down --volumes
	docker system prune -af

# Full clean: everything from "clean", plus the host data
# directories are deleted from disk.
fclean: clean
	@echo "Removing local data directories ..."
	rm -rf $(DATA_DIR)

# Full reset: fclean than rebuild everything from scratch
re: fclean all

# ---------------------------------------------------------
# Utilities
# ---------------------------------------------------------

# Show logs of all services in real time
logs:
	$(COMPOSE) logs -f

# Show the status of all containers (running/stopped)
ps :
	$(COMPOSE) ps

# ---------------------------------------------------------
# Rules
# ---------------------------------------------------------
.PHONY: all up down stop start restart clean fclean re data_dirs logs ps
