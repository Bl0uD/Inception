#!/bin/sh

# Initialize MariaDB system database
mysql_install_db

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

# Start MySQL/MariaDB service
/etc/init.d/mysql start

if [ -d "/var/lib/mysql/$MYSQL_DATABASE" ] # Check if database directory already exists
then
	echo "Database already exists"
else
# Run interactive MySQL security setup with inline input (using environment variables for passwords)
#	Y						:	Accept default
#	$MYSQL_ROOT_PASSWORD	:	Set root password
#	$MYSQL_ROOT_PASSWORD	:	Confirm root password
#	Y						:	Remove anonymous users
#	N						:	Keep remote root login disabled (optional)
#	Y						:	Remove test databases
#	Y						:	Reload privilege tables
#	_EOF_					:	End of heredoc input
mysql_secure_installation << _EOF_

Y
$MYSQL_ROOT_PASSWORD
$MYSQL_ROOT_PASSWORD
Y
N
Y
Y
_EOF_

# Allow root to connect from any host, set its password, grant all privileges, then reload permission cache
echo "GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD'; FLUSH PRIVILEGES;" | mysql -uroot

# Create WordPress database and user with permissions
echo "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE; GRANT ALL ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD'; FLUSH PRIVILEGES;" | mysql -u root

# Import WordPress database structure and data
mysql -uroot -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE < /usr/local/bin/wordpress.sql

fi

# Stop MySQL service (container will restart it)
/etc/init.d/mysql stop

# Execute passed command (replace shell process with CMD from Dockerfile)
exec "$@"