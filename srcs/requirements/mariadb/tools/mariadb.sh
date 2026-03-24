#!/bin/sh

set -e

SOCKET_PATH="/tmp/mysql.sock"
INIT_MARKER="/var/lib/mysql/.inception_db_initialized"

# Initialize MariaDB system database only if it does not exist yet.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Load passwords from Docker secrets or environment variables
# Docker secrets are mounted at /run/secrets/
if [ -f /run/secrets/db_root_password ]; then
    MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
fi

if [ -f /run/secrets/db_password ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)
fi

# Export variables for use in MySQL commands
export MYSQL_ROOT_PASSWORD
export MYSQL_PASSWORD

# Validate required environment values before initialization.
if [ -z "${MYSQL_DATABASE:-}" ] || [ -z "${MYSQL_USER:-}" ] || [ -z "${MYSQL_PASSWORD:-}" ] || [ -z "${MYSQL_ROOT_PASSWORD:-}" ]; then
    echo "ERROR: Missing required MariaDB environment or secret values"
    exit 1
fi

# First-time database setup
if [ -f "$INIT_MARKER" ]; then
    echo "Database already exists"
else
    echo "Starting temporary MariaDB server for initialization..."
    mysqld --user=mysql --skip-networking --socket="$SOCKET_PATH" &
    TEMP_PID=$!

    for i in $(seq 1 60); do
        if mysqladmin --socket="$SOCKET_PATH" ping >/dev/null 2>&1; then
            break
        fi
        if [ "$i" -eq 60 ]; then
            echo "ERROR: Temporary MariaDB server did not start"
            exit 1
        fi
        sleep 1
    done

    mysql --socket="$SOCKET_PATH" -uroot <<-EOSQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL

    mysql --socket="$SOCKET_PATH" -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < /usr/local/bin/wordpress.sql

    touch "$INIT_MARKER"

    mysqladmin --socket="$SOCKET_PATH" -uroot -p"$MYSQL_ROOT_PASSWORD" shutdown
    wait "$TEMP_PID"
fi

# Execute passed command (replace shell process with CMD from Dockerfile)
exec "$@"