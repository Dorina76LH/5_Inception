# Developer Documentation
 
# Environment setup — VM (UTM + Debian)

## 1. Creating the VM

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

## 4. SSH authentication to GitHub

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

## 5. SSH access to the VM from the Mac

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

## 6. Local DNS configuration (project domain name)

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

## 7. Cloning the project inside the VM

```bash
git clone git@github.com:your_account/inception.git
cd inception
```

## 8. Current workflow

1. Code is edited locally on the Mac (VS Code)
2. `git add / commit / push` from the Mac to GitHub
3. Inside the VM (connected via SSH), `git pull` to fetch the code and test it with Docker

> To improve later: VS Code Remote-SSH to edit directly inside the VM and avoid repeated push/pull cycles just to test a line of code. (Currently blocked by a `Permission denied` error, to be fixed.)

## 9. VM shutdown / restart cycle

```bash
# Clean shutdown
sudo shutdown -h now
```
Then restart from UTM, log back in (intra42 credentials), and retrieve the IP if it changed:
```bash
ip a
ssh doberes@VM_IP
```

## 10. Best practices

- [ ] Take a **UTM snapshot** once the base setup is clean (Debian + Docker + Git configured) → quick rollback in case of issues
- [ ] Note the exact Debian version used (`cat /etc/debian_version`) for consistency with the Dockerfiles
- [ ] Verify `docker --version` and `docker compose version` run without errors

## 11. Final checks before coding

```bash
cat /etc/debian_version
docker --version
docker compose version
docker run hello-world
```

## 12. Validating the Nginx Container

Once the Nginx Dockerfile and configuration are ready, test the container independently before orchestrating with Docker Compose.

### Step 1: Build and Run the Test Container

```bash
cd ~/Inception/srcs/requirements/nginx
docker build -t nginx-test .
docker run -d -p 443:443 --name test-nginx nginx-test
```

Verify that the container is running:
```bash
docker ps
```


### Step 2: CLI Validation inside the VM (curl)
From inside the VM terminal, execute:
```bash
curl -k [https://doberes.42.fr](https://doberes.42.fr)
```
Note on -k: The flag is required to bypass SSL certificate verification since we are using a self-signed certificate generated via OpenSSL.

Expected Result: The HTML output of your index.html page should be printed directly in the terminal.

### Step 3: Browser Validation from the Mac (Host)

1. Ensure the Mac's /etc/hosts contains the VM's IP mapping:
```bash
192.168.64.3    doberes.42.fr
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
docker ps
```

## Build and launch the project
 
<!-- Using the Makefile and Docker Compose -->
 
## Managing containers and volumes
 
<!-- Relevant commands: docker compose ps/logs/exec, docker volume ls/inspect, etc. -->
 
## Data storage and persistence
 
<!-- Where project data is stored (/home/login/data) and how it persists -->