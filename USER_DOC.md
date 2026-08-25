# User Documentation
 
## Services provided
 
This project runs a small WordPress infrastructure made of several containers, all connected through a single Docker network:
 
- **NGINX** — the single entry point of the whole infrastructure, reachable over HTTPS (port 443 only), with a self-signed TLS certificate.
- **WordPress + php-fpm** — the website itself. WordPress is pre-installed and pre-configured with an administrator account and a regular author account.
- **MariaDB** — the database storing all WordPress content (posts, pages, users).
- **Adminer** (bonus) — a lightweight web interface to browse and manage the MariaDB database directly.
- **Static website** (bonus) — a simple standalone page presenting a CV, served independently of WordPress.
## Start and stop the project
 
From the root of the repository:
 
```bash
make init   # creates data directories, .env and secret files (first time only)
make up     # builds the images and starts all containers
```
 
To stop the containers without removing them:
```bash
make stop
```
 
To restart previously stopped containers:
```bash
make start
```
 
To stop and remove containers (volumes/data are kept):
```bash
make down
```
 
To fully reset everything, including persistent data:
```bash
make fclean
```
 
## Access the website and the administration panel
 
| Service | URL |
|---|---|
| WordPress website | https://doberes.42.fr |
| WordPress admin panel | https://doberes.42.fr/wp-admin |
| Adminer (database admin) | https://doberes.42.fr/adminer/ |
| CV / static website | https://doberes.42.fr/cv/ |
 
Since the TLS certificate is self-signed, the browser will show a security warning on first visit — this is expected, click through to proceed (e.g. "Advanced" → "Proceed to doberes.42.fr").
 
Port 80 (HTTP) is intentionally unreachable: NGINX only accepts connections on port 443 (HTTPS).
 
## Locate and manage credentials
 
Credentials are never stored in the Git repository. They live in two places, both excluded from version control:
 
- **`srcs/.env`** — non-sensitive configuration (domain name, database name, WordPress usernames/emails). A template without real values is available at `srcs/.env_example`.
- **`secrets/`** — sensitive values, one file per credential:
  - `secrets/db_password.txt` — MariaDB application user password
  - `secrets/db_root_password.txt` — MariaDB root password
  - `secrets/wp_admin_passsword.txt` — WordPress admin
  - `secrets/wp_user_password.txt` - WordPress regular user passwords
These files are created empty by `make init` and must be filled in manually before the first `make up`.
 
## Check that the services are running correctly
 
### 1. Container status
 
```bash
make ps
```
All services should show status `Up`, with no restart loop:
```
NAME                        STATUS
inception-nginx             Up
inception-wordpress         Up
inception-mariadb           Up
inception-adminer           Up
inception-static-website    Up
```
 
### 2. Docker network
 
```bash
docker network ls
docker network inspect inception_inception_network
```
The `Containers` section should list all five containers, confirming they can communicate with each other.
 
### 3. Volumes — existence and correct host path
 
```bash
docker volume ls
docker volume inspect inception_mariadb_data
docker volume inspect inception_wordpress_data
```
The `Options.device` field must point to `/home/doberes/data/mariadb` and `/home/doberes/data/wordpress` on the host.
 
```bash
sudo ls -la /home/doberes/data/mariadb
sudo ls -la /home/doberes/data/wordpress
```
Both directories should contain real data (MariaDB system files / WordPress core files).
 
### 4. NGINX — HTTPS access and TLS version
 
```bash
curl -kv https://doberes.42.fr | head -5
```
Check for `SSL connection using TLSv1.3` (or `TLSv1.2`) and `HTTP/1.1 200 OK`.
 
Port 80 must be unreachable:
```bash
curl -v http://doberes.42.fr
```
This must fail with `Connection refused`.
 
### 5. WordPress — site and admin panel
 
Open `https://doberes.42.fr` in a browser: the site must display actual WordPress content (e.g. the default "Hello world!" post with the configured site title), **not** the WordPress installation wizard.
 
Log in to the admin panel at `https://doberes.42.fr/wp-admin` with the administrator account (see `secrets/wp_admin_password.txt` for the password, `WP_ADMIN_USER` in `.env` for the username).
 
From the dashboard:
- Edit an existing page or post, save it, and confirm the change appears on the live site.
- Log out and browse the site as a visitor: using the regular (non-admin) account, add a comment on a post and confirm it appears.
### 6. MariaDB — database connectivity
 
Via the command line:
```bash
docker exec -it inception-mariadb mariadb -u wp_user -p wordpress
```
Enter the database password when prompted, then:
```sql
SHOW DATABASES;
SHOW TABLES;
```
The `wordpress` database must be listed, and `SHOW TABLES` should now show WordPress's tables (`wp_posts`, `wp_users`, `wp_options`, etc.) — populated after the WordPress installation.
 
### 7. Adminer — database admin interface (bonus)
 
Open `https://doberes.42.fr/adminer/` in a browser. On the login form, enter:
- **System**: MySQL / MariaDB (default)
- **Server**: `mariadb` (the Docker service name — not `localhost`, which is only a placeholder)
- **Username**: the value of `SQL_USER` in `.env`
- **Password**: the value in `secrets/db_password.txt`
- **Database**: the value of `SQL_DATABASE` in `.env`
After logging in, the `wordpress` database and its tables (e.g. `wp_users`) should be browsable — a visual confirmation that the whole stack (NGINX → Adminer → MariaDB) is working end to end.
 
### 8. Static website / CV (bonus)
 
Open `https://doberes.42.fr/cv/` in a browser: a simple page should be displayed with a link to download the CV as a PDF. This service runs independently of WordPress, in its own container.
 
### 9. Persistence after a reboot
 
```bash
sudo shutdown -r now
```
After the VM restarts:
```bash
make up
```
Verify that:
- The WordPress site still displays the same content as before (no fresh install wizard).
- `docker exec -it inception-mariadb mariadb -u wp_user -p wordpress -e "SHOW DATABASES;"` still lists `wordpress`, without triggering a new database initialization.
- Any previous edits made through `wp-admin` are still visible on the live site.