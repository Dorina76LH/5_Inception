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
	@if [ ! -d $(DATA_DIR)/mariadb ] || [ ! -d $(DATA_DIR)/wordpress ]; then \
		mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress; \
		echo "Directories created for MariaDB and WordPress persistent data..."; \
	else \
		echo "Data directories already exist, skipping..."; \
	fi

# Create .env from .env_example if it does not exist
env_file:
	@if [ ! -f srcs/.env ]; then \
			cp srcs/.env_example srcs/.env; \
			chmod 600 srcs/.env ;\
			echo "Empty .env file created (chmod 600)..."; \
	else \
			echo ".env already exists, skipping..."; \
	fi

# Create secret files
secret_files:
	@mkdir -p secrets
	@chmod 700 secrets
	@if [ ! -f secrets/db_password.txt ] || [ ! -f secrets/db_root_password.txt ] || [ ! -f secrets/credentials.txt ]; then \
		touch secrets/db_password.txt; \
		touch secrets/db_root_password.txt; \
		touch secrets/credentials.txt; \
		chmod 600 secrets/db_password.txt; \
		chmod 600 secrets/db_root_password.txt; \
		chmod 600 secrets/credentials.txt; \
		echo "Empty secret files created (chmod 600)..."; \
	else \
		echo "Secret files already exist, skipping..."; \
	fi

# ---------------------------------------------------------
# Build and start containers
# ---------------------------------------------------------

# Default target : start all containers in detached mode
all: init up

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

# Create ddata dirs, .env and secret files
init : data_dirs env_file secret_files
	@echo "Initialization complete : fill in .env and secret files then launch 'make up'"


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
	sudo rm -rf $(DATA_DIR)

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
.PHONY: all up init down stop start restart clean fclean re data_dirs secret_files env_file logs ps
