#!/bin/bash

set -e

# Load database password from Docker secrets or environment variable
if [ -f /run/secrets/db_password ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)
    export MYSQL_PASSWORD
fi

echo "WordPress setup starting..."
echo "Domain: $DOMAIN_NAME"
echo "Database: $MYSQL_DATABASE @ $MYSQL_HOSTNAME"

# Apply sane defaults and fail early on missing required values.
MYSQL_HOSTNAME="${MYSQL_HOSTNAME:-mariadb}"

required_vars=(MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD MYSQL_HOSTNAME)
for var_name in "${required_vars[@]}"; do
    if [ -z "${!var_name:-}" ]; then
        echo "ERROR: Missing required variable: $var_name"
        exit 1
    fi
done

# Wait for MariaDB to be reachable before touching WordPress config.
echo "Waiting for MariaDB to be ready..."
for i in $(seq 1 60); do
    if php -r '
        mysqli_report(MYSQLI_REPORT_OFF);
        $db = @new mysqli(getenv("MYSQL_HOSTNAME"), getenv("MYSQL_USER"), getenv("MYSQL_PASSWORD"), getenv("MYSQL_DATABASE"));
        if (!$db->connect_errno) { exit(0); }
        exit(1);
    '; then
        echo "MariaDB connection established"
        break
    fi
    if [ "$i" -eq 60 ]; then
        echo "ERROR: MariaDB is not reachable after 60 attempts"
        exit 1
    fi
    sleep 2
done

# Check if WordPress is already installed
if [ -f ./wp-config.php ]
then
	echo "WordPress already configured, skipping installation..."
else
	echo "Downloading and installing WordPress..."
	# Download WordPress specific version (not latest)
	wget https://wordpress.org/wordpress-6.3.1.tar.gz
	tar xfz wordpress-6.3.1.tar.gz
	mv wordpress/* .
	rm -rf wordpress-6.3.1.tar.gz
	rm -rf wordpress

	echo "Configuring wp-config.php with database settings..."
	# Import environment variables in the config file
	sed -i "s/username_here/$MYSQL_USER/g" wp-config-sample.php
	sed -i "s/password_here/$MYSQL_PASSWORD/g" wp-config-sample.php
	sed -i "s/localhost/$MYSQL_HOSTNAME/g" wp-config-sample.php
	sed -i "s/database_name_here/$MYSQL_DATABASE/g" wp-config-sample.php
	cp wp-config-sample.php wp-config.php
	
	echo "WordPress installation completed"
fi
# Execute the CMD from Dockerfile (php-fpm)
exec "$@"