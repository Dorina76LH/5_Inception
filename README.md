# Inception

*This project has been created as part of the 42 curriculum by <doberes>.*
 
## Description
 
This project is part of the 42 system administration curriculum. Its goal is to deepen the understanding of Docker by
building a small, containerized web infrastructure from scratch, inside a personal virtual machine.
Concretely, this means learning how to design a network of isolated containers, connect them together, and expose the
result securely to the outside world — rather than relying on a single monolithic setup. It also covers automating
the whole build and startup process with Docker Compose and a Makefile, adding persistent storage through named
volumes, and securing the entry point with a self-signed TLS certificate.
The infrastructure sets up a classic three-tier web application: an NGINX reverse proxy as the single TLS entry
point, a WordPress site running with php-fpm, and a MariaDB database — each running in its own dedicated container,
built from a custom Dockerfile.
 
## Instructions

### Prerequisites

Install a VM (Debian) with Git and Docker (+ Docker Compose) set up.

### Setup

Clone the project repository:

From the root of the repository:
`make init` creates empty `.env` and `secrets/*.txt` files — **fill them in before continuing**:
```bash
nano srcs/.env          # domain name, database name, etc.
nano secrets/db_password.txt
nano secrets/db_root_password.txt
nano secrets/credentials.txt
```

Then, still from the root of the repository, point the domain name to the VM's IP address (on the host machine, in `/etc/hosts`, or via a browser flag if `sudo` is unavailable — see DEV_DOC for both cases):
```bash
<VM_IP>    doberes.42.fr
```

⚠️ See USER_DOC for more informations 

### Build and Run

```bash
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

⚠️ The TLS certificate is self-signed — the browser will flag the connection as unsafe. This is expected: accept the warning to proceed (see DEV_DOC for the exact steps per browser).
 
## Project description
 
### How Docker and Docker Compose work
 
Docker is a solution for virtualizing the application layer, unlike a virtual machine, which virtualizes an entire
operating system. Docker builds **images** (fixed, read-only templates) from Dockerfiles (build instructions), then
runs these images as **containers** (isolated, running instances). Several containers can be started from the same
image.
 
Containers share the host machine's kernel instead of embedding a full one — this is what makes them significantly
lighter and faster to start than a classic VM. On Mac/Windows, since there is no native Linux kernel, Docker Desktop
embeds a lightweight Linux VM internally to provide one.
 
**Docker Compose** orchestrates multiple containers from a single declarative file (`docker-compose.yml`): it defines
services, their network, their volumes, and their startup dependencies, and allows building and launching everything
with a single command (`docker compose up`) — instead of running a separate `docker run` command for each container
and manually handling networking and dependencies.
 
This makes it possible to provide, in an isolated and reproducible environment, the code, libraries, and dependencies
required to run the application — avoiding the classic "it works on my machine" issue and simplifying configuration
both in development and deployment.
 
### Image used with vs without Docker Compose
 
Without Docker Compose, each image has to be built and run manually through separate `docker build`/`docker run`
commands: networks, volumes, environment variables, and the startup order between containers all have to be created
and coordinated by hand.
 
With Docker Compose, a single declarative file (`docker-compose.yml`) describes all services, their build context,
network, volumes, and dependencies at once. A single command (`docker compose up --build`) builds and launches the
entire stack. Compose also automatically creates a shared network with DNS resolution between services by name (e.g.
the nginx container can reach the wordpress container simply via the hostname `wordpress`, no manual IP lookup
needed), and the whole stack can be stopped or restarted consistently as one unit.
 
### Base image choice
 
All containers are built from **Debian 12 "Bookworm"**, the penultimate stable Debian release as required by the
subject. Debian 13 "Trixie" became the current stable release in August 2025, which moved Debian 12 to "oldstable"
status — it is still officially supported via LTS until June 2028.
 
### Virtual Machines vs Docker
 
A VM virtualizes everything above the bare metal: kernel, OS, and applications, via a hypervisor. A container
virtualizes only what sits above the OS — the application layer — and shares the host machine's kernel instead of
embedding its own.
 
As a result, a VM is slower to start (minutes) and takes up more disk space (GBs), while a container is lightweight
(MBs) and starts almost instantly (seconds). Containers are also faster and easier to duplicate/share between users,
and a single host can run far more containers than VMs, since containers don't each carry a full OS.
 
The trade-off is isolation: because containers share the host kernel, their isolation (via namespaces and cgroups) is
weaker than a VM's, which is isolated by the hypervisor at the hardware level. A VM therefore provides a stronger
security boundary, while Docker trades some of that isolation for speed, density, and portability.
 
### Secrets vs Environment Variables
 
`.env` files store environment variables, used for non-sensitive configuration (domain name, database name, ports, etc.). The file must be explicitly referenced in `docker-compose.yml` via `env_file:` for each service that needs it:
```yaml
env_file:
  - .env
```
 
Their security is weaker than Docker secrets: environment variables are visible to anyone with access to the running container or the Docker daemon, for example via:
```bash
docker inspect <container_name> --format='{{json .Config.Env}}'
docker exec <container_name> printenv
```
 
Docker secrets are used to communicate sensitive information (passwords, certificates, API keys), passed as files rather than environment variables. Each secret's source file is declared once at the top level:
```yaml
secrets:
  db_password:
    file: ../secrets/db_password.txt
```
and made available only to the services that explicitly list it under their own `secrets:` key — any service that does not list a given secret has no access to it at all, the file is simply never mounted inside its container. When mounted, a secret appears as a plain file inside the container, under `/run/secrets/<name>` (e.g. `/run/secrets/db_password`), read explicitly by the application/script rather than being exposed as an environment variable:
```bash
docker exec <container_name> cat /run/secrets/db_password
```
 
Because they are not environment variables, secrets do not show up in `docker inspect` or `printenv` — only a process inside a container that has been granted the secret can read it.
 
### Docker Network vs Host Network
 
By default, a container started with `network_mode: host` shares the host machine's network stack directly: it uses the host's IP address and ports as if the process were running natively on the host, with no network isolation and no need for explicit port mapping (`-p`).

A **Docker network** (the approach used in this project, via a custom `bridge` network declared in `docker-compose.yml`) instead gives each container its own private, isolated network namespace. Containers on the same Docker network can reach each other by service name — Docker provides automatic DNS resolution (e.g. `wordpress` resolves to the WordPress container's internal IP) — while remaining isolated from the host's network and from containers on other Docker networks.

This project only exposes the Nginx container to the host, via explicit port mapping (`443:443`); every other service (MariaDB, WordPress, the bonus services) is reachable exclusively through the internal `inception_network`, never directly from the host or the outside world. This matches the subject's requirement of a single, controlled TLS entry point: using `host` networking here would remove that isolation entirely, exposing every service's port directly on the VM and defeating the purpose of routing everything through Nginx.
 
### Docker Volumes vs Bind Mounts
 
Both mechanisms let a container access files that live outside its own filesystem, so data survives even if the container is removed — the difference is in how Docker manages and references that storage.

A **bind mount** references a host path directly, inline, in a service's own `volumes:` list:
```yaml
services:
  mariadb:
    volumes:
      - /home/login/data/mariadb:/var/lib/mysql
```
Docker treats this as a raw mount of an existing host directory — it has no name, is not tracked as a Docker entity, and never appears in `docker volume ls`.

A **named volume** is declared once at the top level of `docker-compose.yml`, then referenced by name in the service:
```yaml
services:
  mariadb:
    volumes:
      - mariadb_data:/var/lib/mysql

volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/login/data/mariadb
```
This is still backed by the same host directory (via `driver_opts`), but because it is declared as a named volume, Docker manages it as a first-class entity: it appears in `docker volume ls`, can be inspected with `docker volume inspect mariadb_data`, and can be created, removed, or reused independently of any single container.

The subject explicitly requires named volumes for MariaDB's and WordPress's persistent storage — bind mounts are not allowed for these two. This project therefore uses named volumes with `driver_opts` pointing to `/home/login/data/...`, satisfying both the subject's requirement (a real Docker-managed volume, not a raw bind mount) and the constraint that data must be visible on the host filesystem at a specific path.
 
## Resources
- [Docker build best practices](https://docs.docker.com/build/building/best-practices/) — official documentation
- [Control NGINX at runtime](https://docs.nginx.com/nginx/admin-guide/basic-functionality/runtime-control/) — signal handling reference
- [Control NGINX daemon off](https://labex.io/questions/what-is-the-purpose-of-the-nginx-g-daemon-off-command-in--871954)
- TechWorld with Nana — *Docker Crash Course For Absolute Beginners* (YouTube)
- [Using TLS certificates with an NGINX Docker container](https://medium.com/@mvuk/using-tls-certificates-with-nginx-docker-container-74c6769a26db)
- [Inception project docuemntation - Youssef](https://medium.com/@imyzf/inception-3979046d90a0)
- [Inception project documentation](https://tuto.grademe.fr/inception/)
- [Incpetion documentation](https://medium.com/@Seraph919/inception-project-comprehensive-deep-dive-2f7e9d3cdfee)


## AI usage
- Structure and write project documentation
- Brainstorming : design choices
- Bug research and debugging