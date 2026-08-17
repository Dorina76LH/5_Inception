# ---------------------------------------------------------
# Variables
# ---------------------------------------------------------
PROJECT_NAME		= inception
COMPOSE_FILE		= srcs/docker-compose.yml
COMPOSE				= docker compose -f $(COMPOSE_FILE) --project-name $(PROJECT_NAME)
DATA_DIR			= home/doberes/data

#---------------------------------------------------------
# Volumes
#---------------------------------------------------------
data_dirs:
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress

# ---------------------------------------------------------
# Build and start containers
# ---------------------------------------------------------
up:
	@echo "Starting Inception ..."
	$(COMPOSE) up --build -d

all: data_dirs up

start:
	@echo "Starting Inception ..."
	$(COMPOSE) start

restart: down up

re: fclean up

# ---------------------------------------------------------
# Stop containers
# ---------------------------------------------------------
stop: 
	@echo "Stopping Inception ..."
	$(COMPOSE) down

# ---------------------------------------------------------
# Clean containers and volumes
# ---------------------------------------------------------
clean: down
	@echo "Cleaning Inception ..."
	docker system prune -af
	docker volume rm -f $(PROJECT_NAME)_mariadb_data
	docker volume rm -f $(PROJECT_NAME)_wordpress_data
	sudo rm -rf $(DATA_DIR)

# ---------------------------------------------------------
# Logs / ps
# ---------------------------------------------------------
logs:
	$(COMPOSE) logs -f

ps :
	$(COMPOSE) ps

# ---------------------------------------------------------
# Rules
# ---------------------------------------------------------
.PHONY all up down stop start restart clean fclean re data_dirs logs ps
