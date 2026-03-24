# USER_DOC

## Services Provided
This stack provides three services:
- NGINX: HTTPS entrypoint on port 443.
- WordPress + PHP-FPM: website application runtime.
- MariaDB: relational database for WordPress.

## Start and Stop
From project root:

```bash
make all
```

Stop services:

```bash
make down
```

Rebuild and restart:

```bash
make re
```

## Access the Website and Administration Panel
1. Ensure your host resolves jdupuis.42.fr to your local machine IP.
2. Open:
- https://jdupuis.42.fr
3. WordPress admin panel:
- https://jdupuis.42.fr/wp-admin

## Credentials Location and Management
- Database password secret: secrets/db_password.txt
- Database root password secret: secrets/db_root_password.txt
- WordPress admin credentials secret: secrets/credentials.txt

Expected credentials format in secrets/credentials.txt:

```text
MY_USERNAME: your_admin_login
MY_PASSWORD: your_admin_password
MY_EMAIL: your_admin_email
```

Notes:
- Admin username must not contain admin or administrator.
- Keep all secret files local and out of public repositories.

## Check Services Health
List running containers:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Check logs:

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

Quick DB health status:

```bash
docker inspect --format='{{json .State.Health}}' mariadb
```

## Troubleshooting Basics
- If website is unreachable: check port 443 availability and DNS/hosts mapping.
- If WordPress fails startup: verify DB secrets and MariaDB health.
- If admin login fails: confirm secrets/credentials.txt content and restart with make re.
