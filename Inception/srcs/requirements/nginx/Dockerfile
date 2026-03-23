FROM debian:buster 

# Update package manager cache
RUN apt-get update 

# Install nginx web server and OpenSSL for certificate generation
RUN apt-get install -y nginx \ 
	openssl 

RUN mkdir /etc/nginx/ssl 
# Generate self-signed certificate (4096-bit RSA, valid 365 days)
RUN openssl req -newkey rsa:4096 -x509 -sha256 -days 365 -nodes \ 
		# Output certificate file
		-out /etc/nginx/ssl/jdupuis.crt \ 
		# Output private key file
		-keyout /etc/nginx/ssl/jdupuis.key \ 
		# Fill certificate subject fields automatically
		-subj "/C=FR/ST=Perpignan/L=Perpignan/O=42 School/OU=jdupuis/CN=jdupuis/" 

# Copy custom nginx configuration file
COPY ./conf/nginx.conf /etc/nginx/conf.d 

# Create nginx runtime directory for PID files
RUN mkdir -p run/nginx 

# Expose HTTPS port to container network
EXPOSE 443 

# Start nginx in foreground mode (required for containers)
CMD ["nginx", "-g", "daemon off;"] 
