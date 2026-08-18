# Developer Documentation

---

# Environment setup — VM (UTM + Debian)

## 1. Creating the VM UTM

- **Hypervisor**: UTM (Apple Virtualization enabled, OpenGL acceleration disabled)
- **OS**: Debian arm64v8 (netinst), suited for Apple Silicon Macs
- **Resources**: enough RAM/disk for Docker (4 GB RAM / 2 CPU cores / dynamic disk recommended)
- **Network**: **Bridged** mode → the VM gets its own IP on the local network (simpler for SSH and for testing the domain name)
- **Partitioning**: automatic/guided, no custom partitioning needed
- **Desktop environment**: unchecked during installation → command-line system only
- **Packages to select during install**: `SSH server`, `standard system utilities`

## 2. Privilege management (sudo)

By leaving the root password empty during installation, Debian does not enable a classic root account: `sudo` privileges are granted directly to the main user created during setup (`doberes`).

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

**Principle**: a DNS normally translates a domain name into an IP address over the internet. Here, we simulate this **locally**, without going through the internet, so we can test `login.42.fr` as if the site were actually online.

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

**On the Mac (host)**, to access the site from an actual browser, point instead to the VM's IP (not 127.0.0.1):
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
- Inside the VM (connected via SSH), `git pull` to fetch the code and test it with Docker
- To improve later: VS Code Remote-SSH to edit directly inside the VM and avoid repeated push/pull cycles just to test a line of code. (Currently blocked by a Permission denied error — see "VSCode / Remote-SSH" below, being investigated)

⚠️ **Lesson learned**: keep `.gitignore` at the repository root, not in a subfolder (e.g. `srcs/`) — a `.gitignore` placed in a subfolder only matches paths relative to that subfolder, which silently breaks the ignore rules for files like `.env`.

## 8. VM shutdown / restart cycle

```bash
# Clean shutdown
sudo shutdown -h now
```
Then restart from UTM, log back in (intra42 credentials), and retrieve the IP if it changed:
```bash
ip a
ssh doberes@VM_IP
```

## 9. Best practices

- [ ] Take a **UTM snapshot** once the base setup is clean (Debian + Docker + Git configured) → quick rollback in case of issues
- [ ] Note the exact Debian version used (`cat /etc/debian_version`) for consistency with the Dockerfiles
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

Used on the Linux school workstations, as a complement to the personal UTM VM (used on the Mac). Same Debian base, different hypervisor since VirtualBox runs natively on x86_64 school machines (no ARM compatibility issue like on Apple Silicon).

## 1. Resources

Started at the same specs as the UTM VM (4 GB RAM / 2 CPU cores), then revised upward after adding a graphical environment (XFCE + browser), since a desktop environment and a browser add noticeable overhead on top of Docker.

**Final configuration:**
- CPU: 4 cores (checked host capacity first — school workstation reports 4 cores available via `nproc`, allocated all 4 to the VM after the reboot)
- RAM: to confirm with `free -h` inside the VM after the change
- Disk: 25 GB (unchanged, largely sufficient)

⚠️ Resource changes (CPU/RAM) made in VirtualBox settings require a **full VM shutdown** (not just an internal reboot) to be applied:
```bash
sudo shutdown -h now
```
Then adjust settings in VirtualBox (VM must be powered off) → Settings → System, and restart the VM from VirtualBox.

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

The school workstation session doesn't have sudo rights (rootless-like setup for the student account itself, not just Docker), which makes editing `/etc/hosts` on the host impossible to point `doberes.42.fr` to the VM's IP. Having a browser directly inside the VM sidesteps this: `/etc/hosts` can be edited inside the VM (where sudo *is* available), and the browser inside the VM tests the domain locally without touching the host machine's configuration at all.

## 4. Installing the graphical environment

```bash
sudo apt update
sudo apt install -y xfce4 xfce4-goodies lightdm
sudo apt install -y firefox-esr
```

`lightdm` provides the graphical login screen and should start automatically after install. If the VirtualBox window still shows a text console:
```bash
sudo reboot
```

**Validated**: after a reboot, the graphical desktop (mouse, XFCE desktop, Firefox) is working — successfully logged into the intra42 website from inside the VM.

**Next step being investigated**: whether a lighter alternative (VS Code Remote-SSH from the host, instead of installing VS Code inside the VM) can reduce the resource footprint of this graphical setup — see "VSCode / Remote-SSH" below.

---

# SSH Authentication (GitHub & Vogosphere)

Applies to whichever VM is currently in use (UTM or VirtualBox) — the keys are generated once and reused across environments, so this setup isn't tied to a specific hypervisor.

The VM uses multi-key SSH configuration to seamlessly interact with both personal GitHub repositories and the school's Vogosphere Git server.

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

The school's Vogosphere key is generated on the host machine during initial setup. It must be transferred to the VM without overwriting the personal key.

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

# VSCode / Remote-SSH — under investigation

Two options considered for editing code inside a VM without duplicating the setup on every environment:
- Install VS Code directly inside the VM (needs the GUI, already in place on the School VM) — self-contained but adds resource usage
- Keep VS Code on the host and use the **Remote-SSH** extension to edit files inside the VM remotely — lighter, avoids repeated push/pull cycles just to test a line of code

Currently blocked by a `Permission denied` error on Remote-SSH — investigating the extension as a way to lighten the School VM install (avoid a full local VS Code install on top of XFCE + Firefox).

---

# Nginx Container

Once the Nginx Dockerfile and configuration are ready, test the container independently before orchestrating with Docker Compose.

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
curl -k [https://doberes.42.fr](https://doberes.42.fr)
```
Note on -k: The flag is required to bypass SSL certificate verification since we are using a self-signed certificate generated via OpenSSL.

Expected Result: The HTML output of your index.html page should be printed directly in the terminal.

## Step 3: Browser Validation

### 1. Local DNS & IP Mapping

#### Option A : Personnal Mas Host (with sudo access)
If you have root privileges on your machine, edit `/etc/hosts` to map the VM's IP address:
```bash
192.168.64.3    doberes.42.fr
```

#### Option B : $@ Capmus Linux Host (without sudo access)
On school computers, modifying /etc/hosts is restricted due to lack of sudo privileges. To bypass this, launch Chrome with internal DNS resolver rules and a dedicated user profile directory:

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
[https://doberes.42.fr](https://doberes.42.fr)

3. Bypass the SSL Warning: Since the certificate is self-signed, browsers will flag it as unsafe.
- Chrome: Click Advanced → Proceed to doberes.42.fr (unsafe) (or type thisisunsafe directly on the page).
- Safari: Click Show Details → Visit this website → confirm with TouchID / Password.
- Firefox: Click Advanced → Accept the Risk and Continue.

### Step 4 : Cleanup
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

Once the MariaDB Dockerfile, config and startup script are ready, test the container independently before orchestrating with Docker Compose — same approach used for Nginx.

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

# Build and launch the project

The project is orchestrated with Docker Compose and driven through a root-level `Makefile`.

```bash
make          # build images and start all containers (detached)
make build    # build images only
make up       # start containers (detached)
make down     # stop and remove containers
make stop     # stop containers without removing them
make start    # restart previously stopped containers
make logs     # follow logs of all services
make clean    # down + prune unused Docker resources
make fclean   # clean + remove volumes and networks
make re       # fclean + all (full rebuild)
```

The `Makefile` wraps `docker compose -f srcs/docker-compose.yml`, so the same commands work regardless of the current working directory (as long as run from the repo root).

# Managing containers and volumes

Useful commands during development, once containers are orchestrated via Compose:

```bash
docker compose -f srcs/docker-compose.yml ps          # status of all services
docker compose -f srcs/docker-compose.yml logs -f nginx    # follow logs of a specific service
docker exec -it mariadb bash                           # shell into a running container
```

All services share a single Docker network (`inception`, bridge driver) defined in `docker-compose.yml`. This lets containers reach each other by service name (e.g. WordPress connects to `mariadb`, not to an IP address) — Docker Compose provides this name resolution automatically.

# Data storage and persistence

Containers are stateless by design: any data written inside a container's filesystem is lost when the container is removed (`docker rm` or `docker compose down`).

To persist data across restarts and rebuilds, named Docker volumes are used:

```yaml
volumes:
  mariadb_data:/var/lib/mysql
```

- `mariadb_data` — stores the MariaDB database files, so articles, users and WordPress configuration survive container recreation
- (to add once WordPress is set up) a volume for `/var/www/html`, so uploaded media, themes and plugins persist as well

Volumes are declared under the top-level `volumes:` key in `docker-compose.yml` and are managed independently of container lifecycle — they are only removed with an explicit `docker volume rm` or `make fclean`.
