
User doc · MD
# User Documentation
 
## Services provided
 
<!-- Understand what services are provided by the stack: NGINX, WordPress + php-fpm, MariaDB, bonus services -->
 
## Start and stop the project
 
<!-- How to start and stop the project (make, make down, docker compose commands) -->
 
## Access the website and the administration panel
 
<!-- URL of the website, URL of the WordPress admin panel -->
 
## Locate and manage credentials
 
<!-- Where credentials live (secrets/, .env), how to find/change them -->
 
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