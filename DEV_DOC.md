# DEV_DOC

## Environment Setup From Scratch
### Prerequisites
- Linux VM
- Docker Engine
- Docker Compose plugin
- make

### Required Files
- srcs/.env
- secrets/db_password.txt
- secrets/db_root_password.txt
- secrets/credentials.txt

Example srcs/.env:

```env
DOMAIN_NAME=jdupuis.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_HOSTNAME=mariadb
WP_TITLE=Inception by jdupuis
WP_ADMIN_USER=jdupuis
WP_ADMIN_EMAIL=jdupuis@student.42perpignan.fr
WP_USER_NAME=writer42
WP_USER_EMAIL=writer42@42.fr
```

## Build and Launch
Build and start:

```bash
make all
```

Stop:

```bash
make down
```

Full rebuild:

```bash
make re
```

Cleanup:

```bash
make clean
make fclean
```

Reset volumes:

```bash
make reset
```

## Useful Container and Volume Commands
Container status:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Logs by service:

```bash
docker compose -f srcs/docker-compose.yml logs -f nginx
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

Open shell in service container:

```bash
docker exec -it wordpress bash
docker exec -it mariadb bash
docker exec -it nginx bash
```

List named volumes:

```bash
docker volume ls
```

Inspect a volume:

```bash
docker volume inspect inception_wordpress_data
docker volume inspect inception_mariadb_data
```

## Data Persistence
Persistent data is stored in Docker named volumes:
- inception_mariadb_data -> MariaDB data (/var/lib/mysql)
- inception_wordpress_data -> WordPress files (/var/www/html)

Data survives container recreation until volumes are explicitly removed.

## Architecture Notes
- NGINX is the only public entrypoint and exposes 443.
- NGINX forwards PHP requests to wordpress:9000 via FastCGI.
- WordPress waits for MariaDB health and then initializes site/users.
- Secrets are mounted under /run/secrets inside containers.
