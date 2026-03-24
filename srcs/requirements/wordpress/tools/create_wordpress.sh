#!/bin/bash

set -e

# Load database password from Docker secrets or environment variable
if [ -f /run/secrets/db_password ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)
    export MYSQL_PASSWORD
fi

# Load WordPress admin credentials from Docker secret if available.
if [ -f /run/secrets/wp_credentials ]; then
    WP_CREDENTIALS_USER=$(grep -E '^MY_USERNAME:' /run/secrets/wp_credentials | sed 's/^MY_USERNAME:[[:space:]]*//' || true)
    WP_CREDENTIALS_PASSWORD=$(grep -E '^MY_PASSWORD:' /run/secrets/wp_credentials | sed 's/^MY_PASSWORD:[[:space:]]*//' || true)
    WP_CREDENTIALS_EMAIL=$(grep -E '^MY_EMAIL:' /run/secrets/wp_credentials | sed 's/^MY_EMAIL:[[:space:]]*//' || true)
fi

WP_ADMIN_USER="${WP_CREDENTIALS_USER:-${WP_ADMIN_USER:-}}"
WP_ADMIN_PASSWORD="${WP_CREDENTIALS_PASSWORD:-${WP_ADMIN_PASSWORD:-}}"
WP_ADMIN_EMAIL="${WP_CREDENTIALS_EMAIL:-${WP_ADMIN_EMAIL:-}}"
WP_TITLE="${WP_TITLE:-Inception Site}"
WP_URL="https://${DOMAIN_NAME}"
WP_USER_NAME="${WP_USER_NAME:-writer42}"
WP_USER_EMAIL="${WP_USER_EMAIL:-writer42@42.fr}"
WP_USER_ROLE="${WP_USER_ROLE:-author}"
WP_USER_PASSWORD="${WP_USER_PASSWORD:-$MYSQL_PASSWORD}"

echo "WordPress setup starting..."
echo "Domain: $DOMAIN_NAME"
echo "Database: $MYSQL_DATABASE @ $MYSQL_HOSTNAME"

# Apply sane defaults and fail early on missing required values.
MYSQL_HOSTNAME="${MYSQL_HOSTNAME:-mariadb}"

required_vars=(MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD MYSQL_HOSTNAME DOMAIN_NAME WP_ADMIN_USER WP_ADMIN_PASSWORD WP_ADMIN_EMAIL)
for var_name in "${required_vars[@]}"; do
    if [ -z "${!var_name:-}" ]; then
        echo "ERROR: Missing required variable: $var_name"
        exit 1
    fi
done

# Subject rule: admin username must not contain admin/administrator.
if echo "$WP_ADMIN_USER" | grep -Eiq 'admin|administrator'; then
    echo "ERROR: WP admin username must not contain 'admin' or 'administrator'"
    exit 1
fi

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

# Force local filesystem operations (no FTP prompt) and ensure php-fpm can write.
if ! grep -q "FS_METHOD" /var/www/html/wp-config.php; then
    sed -i "/\/\* That's all, stop editing! Happy publishing\. \*\//i define( 'FS_METHOD', 'direct' );" /var/www/html/wp-config.php
fi

chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# Install WordPress core once, then ensure required users exist.
if ! wp core is-installed --allow-root --path=/var/www/html >/dev/null 2>&1; then
    wp core install \
        --allow-root \
        --path=/var/www/html \
        --url="$WP_URL" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL"
fi

if ! wp user get "$WP_USER_NAME" --allow-root --path=/var/www/html >/dev/null 2>&1; then
    wp user create "$WP_USER_NAME" "$WP_USER_EMAIL" \
        --allow-root \
        --path=/var/www/html \
        --user_pass="$WP_USER_PASSWORD" \
        --role="$WP_USER_ROLE"
fi

# Execute the CMD from Dockerfile (php-fpm)
exec "$@"