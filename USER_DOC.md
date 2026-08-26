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

Since the TLS certificate is self-signed, the browser will show a security warning on first visit — this is expected, click through to proceed (e.g.
"Advanced" → "Proceed to doberes.42.fr").

Port 80 (HTTP) is intentionally unreachable: NGINX only accepts connections on port 443 (HTTPS).

## Logging in — where to find each credential

| To log into... | Username | Password |
|---|---|---|
| **WordPress admin** (`/wp-admin`) | `WP_ADMIN_USER` in `srcs/.env` | `secrets/wp_admin_password.txt` |
| **WordPress regular user** | `WP_USER` in `srcs/.env` | `secrets/wp_user_password.txt` |
| **Adminer** (`/adminer/`) | `SQL_USER` in `srcs/.env` | `secrets/db_password.txt` |
| **MariaDB root** (CLI only) | `root` | `secrets/db_root_password.txt` |

For Adminer specifically, also fill in on the login form:
- **System**: MySQL / MariaDB
- **Server**: `mariadb` (the Docker service name — not `localhost`)
- **Database**: `SQL_DATABASE` in `srcs/.env`

## Locate and manage credentials

Credentials are never stored in the Git repository. They live in two places, both excluded from version control:

- **`srcs/.env`** — non-sensitive configuration (domain name, database name, WordPress usernames/emails). A template without real values is available at
`srcs/.env_example`.
- **`secrets/`** — sensitive values, one file per credential:
  - `secrets/db_password.txt` — MariaDB application user password
  - `secrets/db_root_password.txt` — MariaDB root password
  - `secrets/wp_admin_password.txt` — WordPress admin password
  - `secrets/wp_user_password.txt` — WordPress regular user password

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

### 2. WordPress — site and admin panel

Open `https://doberes.42.fr` in a browser: the site must display actual WordPress content (e.g. the default "Hello world!" post with the configured site
title), **not** the WordPress installation wizard.

Log in to the admin panel at `https://doberes.42.fr/wp-admin` with the administrator account (see "Logging in" above for credentials).

From the dashboard:
- Edit an existing page or post, save it, and confirm the change appears on the live site.
- Log out and browse the site as a visitor: using the regular (non-admin) account, add a comment on a post and confirm it appears.

### 3. Adminer — database admin interface (bonus)

Open `https://doberes.42.fr/adminer/` in a browser and log in (see "Logging in" above for credentials). After logging in, the `wordpress` database and its
tables (e.g. `wp_users`) should be browsable — a visual confirmation that the whole stack (NGINX → Adminer → MariaDB) is working end to end.

### 4. Static website / CV (bonus)

Open `https://doberes.42.fr/cv/` in a browser: a simple page should be displayed with a link to download the CV as a PDF. This service runs independently of
WordPress, in its own container.