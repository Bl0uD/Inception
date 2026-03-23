FROM debian:bullseye 

# Update package manager cache
RUN apt-get update 

# Install nginx web server, OpenSSL for certificate generation, bash, and gettext for envsubst
RUN apt-get install -y nginx \ 
	openssl \
	bash \
	gettext-base \
	&& rm -rf /var/lib/apt/lists/*

# Create nginx ssl and runtime directories
RUN mkdir -p /etc/nginx/ssl /run/nginx

# Copy custom nginx configuration file
COPY ./conf/nginx.conf /etc/nginx/conf.d 

# Copy entrypoint script that generates certificates dynamically from environment variables
COPY ./tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose HTTPS port to container network
EXPOSE 443 

# Entrypoint generates certificate dynamically using $DOMAIN_NAME environment variable
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"] 
