*This project has been created as part of the 42 curriculum by jdupuis.*

## Description
Inception is a system administration project where a small production-like web stack is built with Docker Compose.

This repository provides three isolated services:
- NGINX as the single public web entrypoint.
- WordPress with PHP-FPM (without NGINX in that container).
- MariaDB (without NGINX in that container).

The stack is designed to show service isolation, networking, persistence, startup ordering, and secret handling.

## Instructions
### Prerequisites
- Linux host with Docker Engine and Docker Compose plugin.
- A valid domain mapping to local machine IP (for 42 requirement: login.42.fr).
- Secret files in secrets/:
- db_password.txt
- db_root_password.txt

### Build and Run
From repository root:

```bash
make all
```

This command builds images and starts containers in detached mode.

The stack is exposed through HTTPS on port 443 only.

### Stop

```bash
make down
```

### Rebuild from scratch

```bash
make re
```

### Cleanup

```bash
make clean
make fclean
```

### Reset persistent data

```bash
make reset
```

This removes Docker named volumes used for database and WordPress data.

### Additional Documentation
- USER_DOC.md: end-user and administrator guide.
- DEV_DOC.md: developer setup and maintenance guide.

## Project Description
### Docker usage in this project
- One Dockerfile per service.
- One Docker Compose file orchestrating containers, network, volumes, and secrets.
- Dedicated startup scripts configure MariaDB, WordPress, and NGINX runtime behavior.

### Main design choices
- Debian bullseye base images for all services.
- NGINX handles TLS termination and forwards PHP requests to WordPress PHP-FPM.
- MariaDB initializes database/user with secrets on first start.
- Persistent data is stored outside containers.

### Sources included
- srcs/docker-compose.yml: orchestration.
- srcs/requirements/nginx: web server, TLS, reverse proxy.
- srcs/requirements/wordpress: PHP-FPM runtime and WordPress bootstrap.
- srcs/requirements/mariadb: database runtime and initialization.
- secrets/: local secret files mounted as Docker secrets.

### Comparison: Virtual Machines vs Docker
- VM virtualizes full OS kernel and userspace, heavier and slower to start.
- Docker containers share host kernel, are lighter, and start quickly.
- VM gives stronger isolation boundary; Docker gives higher deployment speed and density.

### Comparison: Secrets vs Environment Variables
- Environment variables are convenient but can leak via process inspection, logs, and debugging output.
- Docker secrets are mounted as files at runtime and better suited for passwords.
- In this project, sensitive DB passwords are handled via Docker secrets.

### Comparison: Docker Network vs Host Network
- Docker bridge network isolates stack traffic and provides service DNS by name.
- Host network removes network namespace isolation and may cause port conflicts.
- This project uses a dedicated bridge network to keep internal traffic private.

### Comparison: Docker Volumes vs Bind Mounts
- Docker volumes are managed by Docker and are portable between hosts/runtimes.
- Bind mounts map exact host paths and couple deployment to host filesystem structure.
- Subject requirement expects named volumes for WordPress and MariaDB persistent data.

## Resources
- Docker documentation: https://docs.docker.com/
- Docker Compose documentation: https://docs.docker.com/compose/
- NGINX documentation: https://nginx.org/en/docs/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/
- PHP-FPM documentation: https://www.php.net/manual/en/install.fpm.php
- WordPress documentation: https://wordpress.org/documentation/
- OWASP TLS cheat sheet: https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Security_Cheat_Sheet.html

### AI usage disclosure
AI assistance was used for:
- Explaining architecture and traffic flow between services.
- Reviewing configuration consistency and subject compliance.
- Drafting documentation structure and wording.

All generated suggestions were manually reviewed and validated before inclusion.
