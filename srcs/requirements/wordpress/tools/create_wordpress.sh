#!/bin/bash

# Load database password from Docker secrets or environment variable
if [ -f /run/secrets/db_password ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)
fi

# Load WordPress admin credentials from Docker secrets
if [ -f /run/secrets/credentials ]; then
    # Parse credentials file (format: KEY=VALUE)
    # Source the file to load variables
    # Use eval with careful input validation
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key == \#* ]] && continue
        [ -z "$key" ] && continue
        # Set the variable
        export "$key"="$value"
    done < /run/secrets/credentials
fi

echo "WordPress setup starting..."
echo "Domain: $DOMAIN_NAME"
echo "Database: $MYSQL_DATABASE @ $MYSQL_HOSTNAME"

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

# Create WordPress admin user if not already created (check by user count)
if [ -n "$WORDPRESS_ADMIN_USER" ] && [ -n "$WORDPRESS_ADMIN_PASSWORD" ]; then
    # Wait for WordPress to be accessible via wp-cli
    # Check if admin user already exists
    if ! wp user get "$WORDPRESS_ADMIN_USER" --allow-root &> /dev/null; then
        echo "Creating WordPress admin user: $WORDPRESS_ADMIN_USER"
        wp user create "$WORDPRESS_ADMIN_USER" "$WORDPRESS_ADMIN_EMAIL" \
            --user_pass="$WORDPRESS_ADMIN_PASSWORD" \
            --role=administrator \
            --allow-root
        echo "WordPress admin user created successfully"
    else
        echo "Admin user $WORDPRESS_ADMIN_USER already exists"
    fi
else
    echo "WARNING: WORDPRESS_ADMIN_USER or WORDPRESS_ADMIN_PASSWORD not set in credentials"
fi

# Execute the CMD from Dockerfile (php-fpm)
exec "$@"