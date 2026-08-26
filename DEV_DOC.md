# Developer Documentation

## Table of contents

- [Environment setup — VM (UTM + Debian)](#environment-setup--vm-utm--debian)
- [Environment setup — School VM (VirtualBox + Debian)](#environment-setup--school-vm-virtualbox--debian)
- [SSH Authentication (GitHub & Vogsphere)](#ssh-authentication-github--vogsphere)
- [VSCode / Remote-SSH](#vscode--remote-ssh-microsoft)
- [Nginx Container](#nginx-container)
- [MariaDB Container](#mariadb-container)
- [Docker Compose — Architecture](#docker-compose--architecture)
- [WordPress Container](#wordpress-container)
- [Adminer Container (Bonus)](#adminer-container-bonus)
- [Static Website Container (Bonus)](#static-website-container-bonus)
- [Build and launch the project](#build-and-launch-the-project)
- [Managing containers and volumes](#managing-containers-and-volumes)
- [Data storage and persistence](#data-storage-and-persistence)
- [Ports and routing](#ports-and-routing)
- [PHP vs php-fpm](#php-vs-php-fpm)

---

# Environment setup — VM (UTM + Debian)

## 1. Creating the VM UTM

- **Hypervisor**: UTM (Apple Virtualization enabled, OpenGL acceleration disabled)
- **OS**: Debian arm64v8 (netinst), suited for Apple Silicon Macs
- **Resources**: enough RAM/disk for Docker (4 GB RAM / 2 CPU cores / dynamic disk
recommended)
- **Network**: **Bridged** mode → the VM gets its own IP on the local network
(simpler for SSH and for testing the domain name)
- **Partitioning**: automatic/guided, no custom partitioning needed
- **Desktop environment**: unchecked during installation → command-line system only
- **Packages to select during install**: `SSH server`, `standard system utilities`

## 2. Privilege management (sudo)

By leaving the root password empty during installation, Debian does not enable a
classic root account: `sudo` privileges are granted directly to the main user
created during setup (`doberes`).

If you need to add a user to the sudo group manually:
```bash
usermod -aG sudo your_user
```

## 3. Installing base tools

```bash
sudo apt update && sudo apt upgrade -y

# Git
sudo apt install -y git

# Build/automation tools
sudo apt install -y curl make

# Docker (official Docker repository, not Debian's docker.io package)
# Follow the official docs: https://docs.docker.com/engine/install/debian/
```

**Avoid typing `sudo` before every Docker command:**
```bash
sudo usermod -aG docker $USER
# log out/in (or reboot) for this to take effect
```
⚠️ Important: This modification only takes effect on the next session login.
Either disconnect and reconnect via SSH: exit then ssh doberes@<IP>
Or apply it immediately in the current terminal: newgrp docker (or reboot the VM)
Verify that docker appears in your group list:
```bash
groups
```

**Docker validation test:**
```bash
sudo docker run hello-world
```

## 4. SSH access to the VM from the Mac

Get the VM's IP (from inside the VM):
```bash
ip a
# look for the inet line of the main interface, e.g. 192.168.64.1
```

Connect from the Mac's terminal:
```bash
ssh doberes@192.168.64.1
```
→ Avoids having to use the UTM window (no convenient copy/paste in it).

## 5. Local DNS configuration (project domain name)

**Principle**: a DNS normally translates a domain name into an IP address over the
internet. Here, we simulate this **locally**, without going through the internet, so
we can test `login.42.fr` as if the site were actually online.

**Inside the VM** (`/etc/hosts`), for an internal test from within the VM itself:
```bash
sudo nano /etc/hosts
```
```
127.0.0.1       localhost
127.0.1.1       doberes
127.0.0.1       doberes.42.fr

# IPv6
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

Verification:
```bash
ping -c 2 doberes.42.fr
# should reply from 127.0.0.1 (the machine points to itself)
```

**On the Mac (host)**, to access the site from an actual browser, point instead to
the VM's IP (not 127.0.0.1):
```bash
sudo nano /etc/hosts
```
```
192.168.64.3    doberes.42.fr
```
(replace with the VM's actual IP and your 42 login)

## 6. Cloning the project inside the VM

```bash
git clone git@github.com:your_account/inception.git
cd inception
```

## 7. Current workflow

- Code is edited locally on the Mac (VS Code)
- `git add` / `commit` / `push` from the Mac to GitHub
- Inside the VM (connected via SSH), `git pull` to fetch the code and test it with
Docker
- Editing directly inside the VM without push/pull cycles is now handled via VS Code
Remote-SSH — see "VSCode / Remote-SSH" below.

⚠️ **Lesson learned**: keep `.gitignore` at the repository root, not in a subfolder
(e.g. `srcs/`) — a `.gitignore` placed in a subfolder only matches paths relative to
that subfolder, which silently breaks the ignore rules for files like `.env`.

## 8. VM shutdown / restart cycle

```bash
# Clean shutdown
sudo shutdown -h now
```
Then restart from UTM, log back in (intra42 credentials), and retrieve the IP if it
changed:
```bash
ip a
ssh doberes@VM_IP
```

## 9. Best practices

- [ ] Take a **UTM snapshot** once the base setup is clean (Debian + Docker + Git
configured) → quick rollback in case of issues
- [ ] Note the exact Debian version used (`cat /etc/debian_version`) for consistency
with the Dockerfiles
- [ ] Verify `docker --version` and `docker compose version` run without errors

## 10. Final checks before coding

```bash
cat /etc/debian_version
docker --version
docker compose version
docker run hello-world
```

---

# Environment setup — School VM (VirtualBox + Debian)

Used on the Linux school workstations, as a complement to the personal UTM VM (used
on the Mac). Same Debian base, different hypervisor since VirtualBox runs natively
on x86_64 school machines (no ARM compatibility issue like on Apple Silicon).

## 1. Resources

Started at the same specs as the UTM VM (4 GB RAM / 2 CPU cores), then revised
upward after adding a graphical environment (XFCE + browser), since a desktop
environment and a browser add noticeable overhead on top of Docker.

**Final configuration:**
- CPU: 4 cores (checked host capacity first — school workstation reports 4 cores
available via `nproc`, allocated all 4 to the VM after the reboot)
- RAM: to confirm with `free -h` inside the VM after the change
- Disk: 25 GB (unchanged, largely sufficient)

⚠️ Resource changes (CPU/RAM) made in VirtualBox settings require a **full VM shutdown** (not just an internal reboot) to be applied:
```bash
sudo shutdown -h now
```
Then adjust settings in VirtualBox (VM must be powered off) → Settings → System, and
restart the VM from VirtualBox.

## 2. Checking the current configuration (from inside the VM)

```bash
# CPU cores
nproc
# or, for more detail (physical cores vs threads, model name):
lscpu

# RAM (total / used / available)
free -h

# Disk space
df -h /
```

Quick one-liner for a summary:
```bash
echo "CPU cores: $(nproc)"
echo "RAM: $(free -h | awk '/^Mem:/ {print $2}')"
echo "Disk: $(df -h / | awk 'NR==2 {print $2}')"
```

## 3. Why a graphical environment on this VM

The school workstation session doesn't have sudo rights (rootless-like setup for the
student account itself, not just Docker), which makes editing `/etc/hosts` on the
host impossible to point `doberes.42.fr` to the VM's IP. Having a browser directly
inside the VM sidesteps this: `/etc/hosts` can be edited inside the VM (where sudo
*is* available), and the browser inside the VM tests the domain locally without
touching the host machine's configuration at all.

## 4. Installing the graphical environment

```bash
sudo apt update
sudo apt install -y xfce4 xfce4-goodies lightdm
sudo apt install -y firefox-esr
```

`lightdm` provides the graphical login screen and should start automatically after
install. If the VirtualBox window still shows a text console:
```bash
sudo reboot
```

**Validated**: after a reboot, the graphical desktop (mouse, XFCE desktop, Firefox)
is working — successfully logged into the intra42 website from inside the VM.

**Resolved**: VS Code Remote-SSH (from the host) is now used instead of installing
VS Code inside the VM, keeping this VM's footprint limited to XFCE + Firefox — see
"VSCode / Remote-SSH" below.

---

# SSH Authentication (GitHub & Vogosphere)

Applies to whichever VM is currently in use (UTM or VirtualBox) — the keys are
generated once and reused across environments, so this setup isn't tied to a
specific hypervisor.

The VM uses multi-key SSH configuration to seamlessly interact with both personal
GitHub repositories and the school's Vogosphere Git server.

## 1. GitHub Key Setup (Personal)

Algorithm used: **ED25519** (modern, fast, short key).

```bash
# Generate the key pair inside the VM
ssh-keygen -t ed25519 -C "your_email@example.com"

# Display the public key to copy it
cat ~/.ssh/id_ed25519.pub
```
→ Add the key on GitHub: **Settings → SSH and GPG keys → New SSH key**

```bash
# Test the connection
ssh -T git@github.com
```

Configure git identity (so commits are properly attributed):
```bash
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
```

## 2. Vogosphere Setup (42 Le Havre)

The school's Vogosphere key is generated on the host machine during initial setup.
It must be transferred to the VM without overwriting the personal key.

**Step 1: Copy keys from host to VM**
```bash
scp ~/.ssh/id_rsa doberes@<VM_IP>:~/.ssh/id_vogsphere
scp ~/.ssh/id_rsa.pub doberes@<VM_IP>:~/.ssh/id_vogsphere.pub
```

**Step 2: Set permissions inside the VM**
```bash
chmod 600 ~/.ssh/id_vogsphere
chmod 644 ~/.ssh/id_vogsphere.pub
```

**Step 3: Configure `~/.ssh/config`**
```bash
nano ~/.ssh/config
```
Add the following configuration:
```
# Vogsphere (42 Le Havre)
Host vogsphere.42lehavre.fr
    HostName vogsphere.42lehavre.fr
    User git
    IdentityFile ~/.ssh/id_vogsphere

# GitHub (Personal)
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
```
Apply strict permissions to the config file:
```bash
chmod 600 ~/.ssh/config
```

## 3. Connection Validation Tests

From inside the VM:
```bash
# Test 1: GitHub authentication
ssh -T git@github.com
# Expected: Hi <username>! You've successfully authenticated...

# Test 2: Vogsphere authentication (42 Le Havre)
ssh -T git@vogsphere.42lehavre.fr
# Expected: Hi there, doberes! You've successfully authenticated...
```

⚠️ **Note on network mode**: If `vogsphere.42lehavre.fr` returns `Name or service not known`, the VM's network adapter needs to be in **Bridged mode** so it can reach the campus local DNS server — regardless of hypervisor, this is the equivalent setting in both:
- UTM: Network → **Bridged**
- VirtualBox: Network → **Bridged Adapter** (Accès par pont)

---

# VSCode / Remote-SSH (Microsoft)

**Goal**: edit code directly inside the VM without duplicating the local setup, and
without repeated push/pull cycles just to test a single line.

Two options were considered:
- Install VS Code directly inside the VM — self-contained, but requires a desktop
environment and adds resource usage on a VM meant to stay lightweight (headless, no
GUI, Docker-only).
- Keep VS Code on the host and use the **Remote-SSH** extension to edit files inside
the VM remotely — lighter, no GUI needed inside the VM, avoids repeated push/pull
cycles.

The Remote-SSH approach was chosen.

## Setup
1. Install the **"Remote-SSH"** extension (published by Microsoft) in the host's VS
Code.
2. Open the Command Palette (`View > Command Palette`, or `Cmd/Ctrl+Shift+P`) → **Remote-SSH: Add New SSH Host** → enter: 'ssh doberes@10.11.200.110'
3. Choose which SSH config file to save the host to. This adds an entry to VS Code's
SSH config, e.g.:


  ```bash
  Host 10.11.200.110
  HostName 10.11.200.110
  User doberes
  ```
4. Open the Command Palette again → **Remote-SSH: Connect to Host** → select `10.11.200.110` → enter the password when prompted.
5. Once connected, `Open Folder` to browse and edit the project files directly
inside the VM.

---

# Nginx Container

Once the Nginx Dockerfile and configuration are ready, test the container
independently before orchestrating with Docker Compose.

## Step 1: Build and Run the Test Container

```bash
cd ~/Inception/srcs/requirements/nginx
docker build -t nginx-test .
docker run -d -p 443:443 --name nginx-test nginx-test
```

Verify that the container is running:
```bash
docker ps
```

## Step 2: CLI Validation inside the VM (curl)
From inside the VM terminal, execute:
```bash
curl -k https://doberes.42.fr
```
Note on -k: The flag is required to bypass SSL certificate verification since we are
using a self-signed certificate generated via OpenSSL.

Expected Result: The HTML output of your index.html page should be printed directly
in the terminal.

## Step 3: Browser Validation

### 1. Local DNS & IP Mapping

#### Option A: Personal Mac Host (with sudo access)
If you have root privileges on your machine, edit `/etc/hosts` to map the VM's IP
address:
```
192.168.64.3    doberes.42.fr
```

#### Option B: School Campus Linux Host (without sudo access)
On school computers, modifying /etc/hosts is restricted due to lack of sudo
privileges. To bypass this, launch Chrome with internal DNS resolver rules and a
dedicated user profile directory:

```bash
# Launch Chrome with local DNS override and isolated profile directory:
# - --host-resolver-rules: Forces Chrome to map 'doberes.42.fr' directly to the VM IP
# - --user-data-dir: Spawns an isolated instance so flags are not ignored by background processes
google-chrome --user-data-dir=/tmp/chrome_42 --host-resolver-rules="MAP doberes.42.fr 10.11.200.110" &
```

Convenience Alias (inception-web)
```bash
# Add alias to ~/.zshrc
echo 'alias inception-web="google-chrome --user-data-dir=/tmp/chrome_42 --host-resolver-rules=\"MAP doberes.42.fr 10.11.200.110\" &"' >> ~/.zshrc
source ~/.zshrc

# Usage:
inception-web
```

2. Open Chrome/Safari/Firefox on the Mac and navigate to:
https://doberes.42.fr

3. Bypass the SSL Warning: Since the certificate is self-signed, browsers will flag it as unsafe.
- Chrome: Click Advanced → Proceed to doberes.42.fr (unsafe) (or type thisisunsafe directly on the page).
- Safari: Click Show Details → Visit this website → confirm with TouchID / Password.
- Firefox: Click Advanced → Accept the Risk and Continue.

### Step 4: Cleanup
Always stop and remove the test container after validation to free port 443:
```bash
docker stop test-nginx && docker rm test-nginx
```

```bash
docker ps -a
curl -k https://doberes.42.fr
```

---

# MariaDB Container

Once the MariaDB Dockerfile, config and startup script are ready, test the container
independently before orchestrating with Docker Compose — same approach used for
Nginx.

**Step 1: Build the Test Image**
```bash
cd ~/Inception/srcs/requirements/mariadb
docker build -t mariadb-test .
```

**Step 2: Run the Test Container**
```bash
docker run -d \
  --name mariadb-test \
  -e SQL_DATABASE=wordpress \
  -e SQL_USER=wp_user \
  -e SQL_PASSWORD=change_this_password \
  -e SQL_ROOT_PASSWORD=change_this_root_password \
  -v mariadb_test_data:/var/lib/mysql \
  mariadb-test
```

Verify that the container is running (and stays up — this is the real test, since the startup script could crash right after initialization):
```bash
docker ps
```

**Step 3: Check the Logs**

```bash
docker logs mariadb-test
```
Expected output: `INFO: Première installation de MariaDB...` then `SUCCESS: Configuration initiale terminée.`, followed by the daemon starting in the foreground — no `chown: Operation not permitted` and no `Access denied` errors.

**Step 4: Validate the Connection**

```bash
docker exec -it mariadb-test mariadb -u wp_user -p wordpress
```
(enter `SQL_PASSWORD` when prompted)

Once on the `MariaDB [wordpress]>` prompt:
```sql
SHOW DATABASES;
exit
```
The `wordpress` database should be listed.

**Step 5: Cleanup**

Always remove the test container and volume after validation, to start fresh for the next test:
```bash
docker stop mariadb-test && docker rm mariadb-test
docker volume rm mariadb_test_data
```

## ⚠️ Known issue: `USER mysql` breaks root authentication

Adding `USER mysql` at the end of the Dockerfile (to make the container run as non-root) causes the startup script to fail with two errors:
```
chown: changing ownership of '/usr/lib/mysql/plugin/auth_pam_tool_dir/auth_pam_tool': Operation not permitted
ERROR 1698 (28000): Access denied for user 'root'@'localhost'
```

**Root cause**: MariaDB's `root@localhost` account uses `unix_socket` authentication by default — it only allows a passwordless connection if the OS user attempting to connect is also named `root`. With `USER mysql` set at the Docker level, the entire container (including the script's `mariadb -u root` call) runs as the OS user `mysql`, not `root`, so the connection is rejected before a password is even involved. On top of that, `mysql_install_db` needs to `chown` some system files it doesn't already own, which also requires root.

**Fix**: do not set `USER mysql` at the Dockerfile level. The startup script already drops privileges for the MariaDB *process* itself via the `--user=mysql` flag passed to `mysql_install_db` and `mysqld_safe` — that's the correct place to apply this, not a Docker-level `USER` instruction. The container's build/init steps still need root, only the running `mysqld` process needs to be `mysql`.

## Architecture

The MariaDB service relies on 3 files working together:
- `Dockerfile` — installs MariaDB, sets up permissions, copies the config and the startup script
- `conf/mariadb.cnf` — network configuration of the server
- `tools/mariadb-script.sh` — startup logic (used as `ENTRYPOINT`)

## Configuration choices

**`bind-address = 0.0.0.0`** — MariaDB listens on `127.0.0.1` by default, which would make it unreachable from other containers on the Docker network. This value opens listening on all network interfaces, required so WordPress can connect to it.

## Startup script logic

The script distinguishes two cases on container startup:
1. **First launch**: the folder `/var/lib/mysql/${SQL_DATABASE}` does not exist yet in the volume → full initialization (system tables, creation of the application database, creation of a dedicated user, security hardening)
2. **Restart**: the folder already exists (persistent volume) → direct startup without reinitializing, to avoid losing existing data

This check is essential: without it, every container restart would wipe the database.

## Security choices

- Passwords (root, application user) are provided via environment variables (`.env`), never hardcoded in versioned code
- A dedicated MySQL user is created for WordPress, with privileges limited to its own database (`GRANT ALL PRIVILEGES ON db.*`, no global access)
- Anonymous accounts and the default `test` database are removed (standard post-install hardening)
- The MariaDB process runs under the system user `mysql` (not root), via the permissions set in the Dockerfile on `/var/run/mysqld`

## Foreground startup (PID 1)

The script ends with `exec mysqld_safe ...` rather than a plain call. `exec` replaces the script's process with MariaDB's, allowing it to receive Docker's stop signals (`SIGTERM`) directly for a clean container shutdown.

## Comparison — good vs bad practices observed in other student repos

| ❌ To avoid (seen elsewhere) | ✅ Good practice (used here) |
|---|---|
| Hardcoded password in the script (`root4life`) | Passwords via environment variables (`.env`) |
| `GRANT ALL ON *.*` for root with remote access (`@'%'`) | Dedicated user with privileges limited to one database |
| `user = root` in the MariaDB config (process runs as root) | Process run under the system user `mysql` |
| `debian:buster` (Debian 10, obsolete, no more security support) | `debian:12.15-slim` (Bookworm, penultimate stable) |

**Possible improvement**: add `USER mysql` at the end of the Dockerfile (before `ENTRYPOINT`) so the process doesn't run as root by default. To be tested first, since `mysql_install_db` might require root privileges on the very first launch.

---

# Docker Compose — Architecture

`srcs/docker-compose.yml` orchestrates 5 services:

| Service | Role | Depends on |
|---|---|---|
| `mariadb` | Database | — |
| `wordpress` | Website (php-fpm) | `mariadb` |
| `nginx` | Single entrypoint (TLS, port 443) | `wordpress`, `adminer`, `static-website` |
| `adminer` (bonus) | Database admin UI | `mariadb` |
| `static-website` (bonus) | CV page | — |

**Networking**: all services share a single bridge network (`inception_network`). Docker Compose's built-in DNS resolves each service by its name (e.g. `mariadb`, `wordpress`), so containers never need to know each other's IP address.

**Volumes**: two named volumes (`mariadb_data`, `wordpress_data`), both backed by a host bind path via `driver_opts` (`type: none`, `o: bind`, `device: /home/doberes/data/...`). This satisfies the subject's two requirements at once: *named* volumes (not raw bind mounts) that *also* physically live at `/home/login/data` on the host.

**Secrets**: three files declared under the top-level `secrets:` key, each mapped to a file in `../secrets/`. At runtime they are mounted read-only inside the relevant containers at `/run/secrets/<name>`.

**Image naming**: every service pins an explicit tag (`nginx:1.0`, `mariadb:1.0`, etc.) — the image name always matches its service name, and `latest` is never used, as required by the subject.

⚠️ **Lesson learned**: a Docker Compose service name is case- and character-sensitive when referenced elsewhere (in `nginx.conf`'s `proxy_pass`/`fastcgi_pass`, for instance). A mismatch like `static_website` (underscore) in the config vs `static-website` (hyphen) as the actual service name causes an immediate `host not found in upstream` error and crash-loops the container referencing it. Always keep the exact same spelling everywhere.

⚠️ **Lesson learned**: YAML does not allow duplicate keys at the same level — declaring two services under the same name (e.g. two blocks both named `adminer:`) does not raise an error, it silently keeps only the last one. Always double-check `docker compose config` output (or `make ps` afterward) to confirm every intended service actually exists.

---

# WordPress Container

## Architecture

The WordPress service relies on 3 files working together, mirroring the MariaDB service's structure:
- `Dockerfile` — installs php-fpm, WP-CLI, and prepares php-fpm to listen over the network
- `tools/wordpress-setup.sh` — startup logic (used as `ENTRYPOINT`)
- (no dedicated config file — php-fpm's default pool config is patched in place via `sed`)

## Configuration choices

**`listen = 9000`** (instead of the default Unix socket) — php-fpm listens on a local socket file by default, which is invisible from another container. Switching to a TCP port makes it reachable from the `nginx` container over the Docker network (see `fastcgi_pass wordpress:9000` in `nginx.conf`).

**`clear_env = no`** — php-fpm strips all environment variables before running PHP by default (a security measure). Since database credentials arrive via environment variables (`.env` + secrets), this had to be disabled, otherwise `wp-config.php` and the setup script would have no way to read them.

**WP-CLI over the web installer** — the subject requires
WordPress to be already installed and configured on first access
(no installation wizard). [WP-CLI](https://wp-cli.org/) scripts
the entire lifecycle (`wp core download`, `wp config create`,
`wp core install`, `wp user create`) without any browser
interaction.

## Startup script logic

Same two-case pattern as MariaDB:
1. **First launch**: `/var/www/html/wp-config.php` does not
exist yet → full installation (download WordPress, generate
config, install core tables, create both required users)
2. **Restart**: `wp-config.php` already exists (persistent
volume) → skip installation entirely, start php-fpm directly

Before installing, the script actively waits for MariaDB to
accept an **authenticated** query (`SELECT 1` with the real
application credentials), not just a network ping — this
specifically confirms the database *and* the WordPress user
schema created by the MariaDB script are usable, which a simple
`mariadbadmin ping` would not guarantee. A 60-second timeout
prevents an indefinite hang if MariaDB never becomes ready; on
timeout the script exits with an error, and `restart:
unless-stopped` lets Compose retry.

## The two required WordPress users

The subject requires two database users, one of them an
administrator whose username must not contain "admin" or
"administrator" in any casing. Both are created via WP-CLI:
```bash
wp core install --admin_user="${WP_ADMIN_USER}" ...   # administrator
wp user create "${WP_USER}" ... --role=author          # regular user
```
Usernames and emails are stored in `.env` (not sensitive), while
both passwords live in `secrets/credentials.txt` and are parsed
with `grep`/`cut` inside the script — the same secret file holds
both, since they are logically related (WordPress account
credentials), unlike MariaDB's two separate password files which
map to two structurally different accounts (application user vs
root).

## Comparison — bugs encountered and fixed during development

| ❌ Bug encountered | ✅ Fix |
|---|---|
| `curl` only listed as `php8.2-curl` (a PHP extension) in the package list, not the actual `curl` CLI tool | Added `curl` explicitly alongside `php8.2-curl` |
| `-p "${SQL_PASSWORD}"` (space between `-p` and the value) | `mariadb` interprets `-p` with a space as "prompt for password interactively" instead of reading the given value — removed the space: `-p"${SQL_PASSWORD}"` |
| `--url=$(DOMAIN_NAME)` | `$(...)` triggers command execution, not variable expansion — corrected to `"${DOMAIN_NAME}"` |
| `[ -f "var/www/html/wp-config.php" ]` (missing leading `/`) | Relative path resolved incorrectly, breaking the "already installed" detection on every restart — corrected to the absolute path `/var/www/html/wp-config.php` |
| `exec php-fpm7.3 -F` | Version mismatch with the php8.2-fpm package actually installed — corrected to `php-fpm8.2` |

---

# Adminer Container (Bonus)

## Purpose

Adminer is a single-file PHP application providing a lightweight
web UI to browse and manage the MariaDB database — a visual
complement to the CLI (`mariadb -u ... -p`) used to validate the
database during development.

## Architecture

Minimal by design: no framework, no build step. `php -S` (PHP's
built-in development server) serves a single `index.php` file
downloaded directly from the Adminer project.

```dockerfile
RUN curl -fsSL https://www.adminer.org/latest-mysql-en.php -o /var/www/adminer/index.php
...
ENTRYPOINT ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/adminer"]
```

## Comparison — bug encountered and fixed

| ❌ Bug encountered | ✅ Fix |
|---|---|
| `curl -L fsSL ... -o file` (missing leading dash before the combined flags) | `curl` parsed `fsSL` as a separate (invalid) URL argument instead of combined flags, so `index.php` was never actually written to disk — every request to Adminer returned a 404 from PHP's own dev server, since it had nothing to serve. Corrected to `curl -fsSL ... -o file` (dash attached to the flags). |

## Access

Reached through NGINX at `/adminer/`, reverse-proxied to the
container on port 8080:
```nginx
location /adminer/ {
    proxy_pass http://adminer:8080/;
    proxy_set_header Host $host;
    ...
}
```
Login requires the **database** credentials (server: `mariadb`,
`SQL_USER`/`db_password` secret) — not the WordPress admin
account, which is a separate authentication system entirely.

---

# Static Website Container (Bonus)

## Purpose

A simple standalone CV page, served independently of WordPress — satisfies the
subject's bonus requirement for "a simple static website... a site for presenting
your resume", **explicitly excluding PHP** as the implementation language.

## Why Python

Python was chosen mainly for its built-in `http.server` module: the standard library
ships a minimal, ready-to-use HTTP server capable of serving any static file (HTML,
PDF, images, etc.) with a single command and zero extra configuration:
```dockerfile
ENTRYPOINT ["python3", "-m", "http.server", "5000"]
```

This is not the only valid option — a dedicated NGINX instance configured to serve
static files only, or a small Node.js/Express server, would have worked just as
well. Python was picked as the most minimal path to a working static file server: no
extra config file to write (unlike a second NGINX instance, which would need its own
`nginx.conf`), on top of the one already maintained for the main entrypoint.

## Architecture

```dockerfile
COPY ./html/index.html .
COPY ./html/cv.pdf .
ENTRYPOINT ["python3", "-m", "http.server", "5000"]
```

## Access

Reached through NGINX at `/cv/`, reverse-proxied to the container on port 5000:
```nginx
location = /cv/ {
    return 301 /cv/cv.pdf;
}
location /cv/ {
    proxy_pass http://static-website:5000/;
    proxy_set_header Host $host;
}
```

## Comparison — bug encountered and fixed

| ❌ Bug encountered | ✅ Fix |
|---|---|
| Link in `index.html` pointed to `cv.pdf` (lowercase) while the actual file was named `CV.pdf` (uppercase) | Linux filesystems are case-sensitive — the two names refer to different files, causing a 404 when clicking the download link. Aligned the casing between the `COPY` instruction, the actual file, and the link in `index.html`. |

---

# Build and launch the project

The project is orchestrated with Docker Compose and driven through a root-level `Makefile`.

```bash
make          # build images and start all containers (detached)
make init     # create data directories, .env and secret files (first time only)
make up       # start containers (detached)
make down     # stop and remove containers
make stop     # stop containers without removing them
make start    # restart previously stopped containers
make logs     # follow logs of all services
make clean    # down + prune unused Docker resources
make fclean   # clean + remove volumes and local data directories
make re       # fclean + all (full rebuild)
```

The `Makefile` wraps `docker compose -f srcs/docker-compose.yml`, so the same commands work regardless of the current working directory (as long as run from the repo root).

---

# Managing containers and volumes

Useful commands during development, once containers are orchestrated via Compose:

```bash
docker compose -f srcs/docker-compose.yml ps                       # status of all services
docker compose -f srcs/docker-compose.yml logs -f nginx            # follow logs of a specific service
docker exec -it inception-mariadb mariadb -u wp_user -p wordpress  # DB shell
docker exec -it inception-wordpress sh                             # shell into WordPress container
```

All services share a single Docker network (`inception_network`,
bridge driver) defined in `docker-compose.yml`. This lets
containers reach each other by service name (e.g. WordPress
connects to `mariadb`, NGINX proxies to `wordpress`/`adminer`/
`static-website`) — Docker Compose provides this name resolution
automatically, and it must exactly match each service's declared
name in the compose file.

```bash
docker volume ls
docker volume inspect inception_mariadb_data
docker volume inspect inception_wordpress_data
```

---

# Data storage and persistence

Containers are stateless by design: any data written inside a
container's filesystem is lost when the container is removed
(`docker rm` or `docker compose down`).

To persist data across restarts and rebuilds, two named Docker
volumes are used, both bind-mounted to `/home/doberes/data/` on
the host:

```yaml
volumes:
  mariadb_data:
    driver_opts:
      device: /home/doberes/data/mariadb
  wordpress_data:
    driver_opts:
      device: /home/doberes/data/wordpress
```

- **`mariadb_data`** → mounted at `/var/lib/mysql` in the
`mariadb` container. Stores all database files, so articles,
users, comments and WordPress configuration survive container
recreation.
- **`wordpress_data`** → mounted at `/var/www/html` in **both**
the `wordpress` and `nginx` containers. WordPress writes its
core files, themes, plugins and uploads here; NGINX reads from
the same volume to serve static assets directly (only PHP
requests are proxied to `wordpress:9000`).

Volumes are declared under the top-level `volumes:` key in
`docker-compose.yml` and are managed independently of container
lifecycle — they are only removed with an explicit `docker
volume rm` or `make fclean`.

Both services' startup scripts check for the presence of a
marker file/folder in the volume (`wp-config.php` for WordPress,
`/var/lib/mysql/${SQL_DATABASE}` for MariaDB) to distinguish a
first launch from a restart — without this check, every
container restart would silently wipe and reinitialize the data.

---

# Ports and routing

How EXPOSE, `ports:` and NGINX fit together?

Three different mechanisms are involved, easy to confuse at first:

| Mechanism | Where | What it actually does |
|---|---|---|
| `ports:` | `docker-compose.yml` | **Publishes** a container port to the **host** — makes it reachable from outside Docker entirely (e.g. from a browser on the Mac) |
| `EXPOSE` | `Dockerfile` | Documents which port the process listens on, and makes it reachable **from other containers on the same Docker network** — never reachable from the host directly |
| `proxy_pass` / `fastcgi_pass` | `nginx.conf` | Decides, based on the requested URL, which internal service (by container name + port) should handle the request |

## The only port published to the outside world: 443

```yaml
# docker-compose.yml
nginx:
  ports:
    - "443:443"
```

This is the **only** `ports:` entry in the whole project. No other service (`wordpress`, `mariadb`, `adminer`, `static-website`) publishes anything to the host — they only declare `EXPOSE` in their own Dockerfile, making them reachable exclusively from other containers on `inception_network`. This directly satisfies the subject's requirement: *"Your NGINX container must be the only entrypoint into your infrastructure via the port 443 only."*

## How NGINX routes to each internal service

NGINX receives every external request on 443, then decides internally where to forward it, purely based on the URL path — using the target container's name (resolved automatically by Docker's internal DNS) and its `EXPOSE`d port:

```nginx
# PHP requests → WordPress (php-fpm), port 9000
location ~ \.php$ {
    fastcgi_pass wordpress:9000;
}

# /adminer/ → Adminer, port 8080
location /adminer/ {
    proxy_pass http://adminer:8080/;
}

# /cv/ → static website, port 5000
location /cv/ {
    proxy_pass http://static-website:5000/;
}

# Everything else → served directly from the shared wordpress_data volume
location / {
    try_files $uri $uri/ =404;
}
```

```
Outside world (browser)
       │
       │  only port published: 443 (docker-compose.yml → ports:)
       ▼
   [ nginx ]  ← the only container reachable from outside
       │
       │  nginx.conf decides where to route, based on the URL,
       │  using each target's container name + EXPOSE'd port
       │  (never published to the host — internal network only)
       │
       ├──→ wordpress:9000        (*.php requests)
       ├──→ adminer:8080          (/adminer/)
       └──→ static-website:5000   (/cv/)
```

## Checklist: adding a new service behind NGINX

When adding a new container that should be reachable through the website (e.g. a future bonus service), four things need to be done together — forgetting one is the most common source of a silent 404 or a crash-looping NGINX:

1. **In the new service's own `Dockerfile`**: declare `EXPOSE <port>` — the port the process actually listens on (check the app's own config/docs for its default listening port).
2. **In `docker-compose.yml`**: add the service under `services:`, on the same `inception_network` as the others. **Do not** add a `ports:` entry — only NGINX should ever publish a port to the host. Also add the service's name to NGINX's `depends_on:` list, so it starts before NGINX tries to reach it.
3. **In `nginx.conf`**: add a new `location` block, using `proxy_pass http://<exact-service-name>:<port>/;` — the service name **must be character-for-character identical** to the one declared in `docker-compose.yml` (hyphens vs underscores matter, and are a very easy typo to make).
4. **Rebuild and test in isolation before assuming it works**:
```bash
   make down
   make up
   docker logs inception-nginx        # confirm no "host not found in upstream" crash-loop
   curl -kv https://doberes.42.fr/<new-path>/
```

⚠️ **Reminder of two bugs hit while wiring up Adminer and the static website** (see their dedicated sections above for details): a service name mismatch between `nginx.conf` and `docker-compose.yml` crashes NGINX outright (`host not found in upstream`), while a missing/misconfigured `EXPOSE`d port or an unreachable file inside the target container instead returns a **404** — the request reaches NGINX and gets proxied correctly, but the target container itself has nothing to serve. Checking `docker logs` on both NGINX *and* the target container is the fastest way to tell which of the two situations is happening.

---

# PHP vs php-fpm

Why do WordPress and Adminer run PHP differently?

PHP by itself is just the language/interpreter — it can be executed in several different ways. This project uses two of them, on purpose, for two different reasons:

| | `php -S` (used by Adminer) | php-fpm (used by WordPress) |
|---|---|---|
| What it is | PHP's built-in, minimal development web server | FastCGI Process Manager — a dedicated, long-running service |
| Intended use | Development/debugging, light occasional use | Production-grade, sustained traffic |
| Performance | Single process, handles requests one at a time | Pool of worker processes, handles requests **in parallel** |
| Robustness | Basic — not designed to sustain load | Automatically restarts crashed workers |
| Communication with NGINX | Plain HTTP | FastCGI protocol, more efficient for this exact use case |

**Adminer** is used occasionally, to inspect the database during development or a defense — `php -S` is more than enough for that, and needs zero extra configuration (see its Dockerfile: `ENTRYPOINT ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/adminer"]`).

**WordPress** is the actual website, potentially serving multiple simultaneous visitors — php-fpm is built for that, and is explicitly required by the subject ("*A Docker container that contains WordPress + php-fpm*"). NGINX forwards `.php` requests to it over FastCGI (`fastcgi_pass wordpress:9000`), rather than proxying plain HTTP as it does for Adminer.