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
 
<!-- Compilation / installation / execution: how to clone, configure secrets & .env, and run the project via the Makefile -->
 
## Project description

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

Without Docker Compose, each image has to be built and run manually through separate `docker build`/`docker run`
commands: networks, volumes, environment variables, and the startup order between containers all have to be created
and coordinated by hand.

With Docker Compose, a single declarative file (`docker-compose.yml`) describes all services, their build context,
network, volumes, and dependencies at once. A single command (`docker compose up --build`) builds and launches the
entire stack. Compose also automatically creates a shared network with DNS resolution between services by name (e.g.
the nginx container can reach the wordpress container simply via the hostname `wordpress`, no manual IP lookup
needed), and the whole stack can be stopped or restarted consistently as one unit.
 
### Virtual Machines vs Docker
 
A VM virtualizes everything above the bare metal: kernel, OS, and applications, via a hypervisor. A container
virtualizes only what sits above the OS — the application layer — and shares the host machine's kernel instead of
embedding its own.

As a result, a VM is slower to start (minutes) and takes up more disk space (GBs), while a container is lightweight
(MBs) and starts almost instantly (seconds). Containers are also faster and easier to duplicate/share between users,
and a single host can run far more containers than VMs, since containers don't each carry a full OS.

The trade-off is isolation: because containers share the host kernel, their isolation (via namespaces and cgroups) is
weaker than a VM's, which is isolated by the hypervisor at the hardware level. A VM therefore provides a stronger
security boundary, while Docker trades some of that isolation for speed, density, and portability
 
### Secrets vs Environment Variables
 
<!-- Comparison -->
 
### Docker Network vs Host Network
 
<!-- Comparison -->
 
### Docker Volumes vs Bind Mounts
 
<!-- Comparison -->
 
## Resources
 
<!-- Classic references: official docs, articles, tutorials -->
 
<!-- AI usage: specify for which tasks and which parts of the project AI was used -->