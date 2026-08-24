
User doc · MD
# User Documentation
 
## Services provided
 
The infrastructure runs as a set of isolated Docker containers orchestrated via Docker Compose:
- **NGINX:** Reverse proxy enforcing HTTPS/TLS (v1.2 or v1.3 only) on port 443. Serves static content and forwards PHP requests.
- **WordPress + PHP-FPM:** Web application processing dynamic requests and interacting with the database.
- **MariaDB:** Relational database management system storing all WordPress data (tables, posts, configurations, users).
 
## Start and stop the project
 
- make / make up
- make down
- make re
- make clean / make fclean
 
## Access the website and the administration panel
 
- **Main site:** [https://doberes.42.fr](https://doberes.42.fr)
- **WordPress Admin Panel:** [https://doberes.42.fr/wp-login.php](https://doberes.42.fr/wp-login.php)
- **Adminer Panel (Bonus):** [https://doberes.42.fr/adminer](https://doberes.42.fr/adminer)
 
## Locate and manage credentials
 
Sensible data and environment variables are split into two locations:
- **Environment variables (srcs/.env)** : Defines domain names, database names, non-sensitive username variables (WP_ADMIN_USER, WP_USER), and volume mount paths.

```bash
.env_example
# DOMAIN NAME
# ---------------------------
DOMAIN_NAME=login.42.fr

# MYSQL SETUP
# ---------------------------
SQL_DATABASE=xxxx
SQL_USER=xxxx

# WORDPRESS SETUP
# ---------------------------
WP_TITLE=xxxx
WP_ADMIN_USER=xxxx
WP_ADMIN_EMAIL=xxxx
WP_USER=xxxx
WP_USER_EMAIL=xxxx
```

- **Docker Secrets (secrets/ directory)**: Contains plain text files reading sensitive passwords mounted directly into containers at runtime:
1. secrets/db_password.txt: Database user password.
2. secrets/db_root_password.txt: MariaDB root password.
3. secrets/credentials.txt: WordPress administrative users credentials.
```bash
credentials
WP_ADMIN_PASSWORD=xxx
WP_USER_PASSWORD=xxx
```
 
## Check that the services are running correctly
 
### 1. Container status
 
```bash
make ps
```
All services should show status `Up` with no restart loop. Example expected output:
```
NAME                IMAGE     SERVICE   STATUS
inception-mariadb   mariadb   mariadb   Up
inception-nginx     nginx     nginx     Up
```
 
### 2. Docker network
 
```bash
docker network ls
docker network inspect inception_inception_network
```
The `Containers` section of the inspect output should list both `inception-mariadb` and `inception-nginx`, confirming they can communicate with each other.
 
### 3. Volumes — existence and correct host path
 
```bash
docker volume ls
```
Should list `inception_mariadb_data` and `inception_wordpress_data`.
 
```bash
docker volume inspect inception_mariadb_data
docker volume inspect inception_wordpress_data
```
Check the `Mountpoint`/`Options.device` field: it must point to `/home/doberes/data/mariadb` and `/home/doberes/data/wordpress` on the host.
 
Confirm actual data is present on the host:
```bash
sudo ls -la /home/doberes/data/mariadb
```
 
### 4. Database connectivity
 
```bash
docker exec -it inception-mariadb mariadb -u wp_user -p wordpress
```
Enter the database user password when prompted. Once connected:
```sql
SHOW DATABASES;
```
The `wordpress` database should be listed.
 
### 5. NGINX — HTTPS access and TLS version
 
```bash
curl -kv https://doberes.42.fr
```
Check the output for:
- `SSL connection using TLSv1.3` (or `TLSv1.2`) — confirms the enforced TLS version.
- `HTTP/1.1 200 OK` — confirms the site responds correctly.
### 6. NGINX — port 80 must be unreachable
 
```bash
curl -v http://doberes.42.fr
```
This request must fail (`Connection refused`). NGINX must only listen on port 443, as required by the subject.
 
### 7. Persistence after a reboot
 
```bash
sudo shutdown -r now
```
After the VM restarts:
```bash
make up
docker exec -it inception-mariadb mariadb -u wp_user -p wordpress -e "SHOW DATABASES;"
```
The `wordpress` database must still be present, without triggering a new initialization (check the mariadb container logs: it should log that the database already exists, not run the first-setup routine again).

make init
fill e.nv and secret files
.env_exemple content
secrets content

make up

Go to : https://doberes.42.fr/wp-login.php
connection : wp_admin_user / wp_admin_mp
w -> users -> check if the users BossQuiDechire(admin) & AgentSmith(author) are int DB

check the data persitance : add a comment / a new site ...etc make down make up check if the modification is always there

check ssl/http certificate
lock -> certificate ->  autosigne -> affiche les infos CN=doberes O=42 TLSv1.2 ou TLSv1.3
