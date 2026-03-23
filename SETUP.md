# Inception - Secure Docker Setup

## 🔐 Security Improvements

This project now complies with Docker security best practices:

### ✅ Changes Made

1. **Removed hardcoded passwords** from Dockerfiles and scripts
   - All passwords now use environment variables or Docker secrets
   - `mariadb.sh` reads from `/run/secrets/` first, falls back to environment variables

2. **Specific WordPress version** instead of `latest`
   - Changed from: `wget http://wordpress.org/latest.tar.gz`
   - Changed to: `wget https://wordpress.org/wordpress-6.3.1.tar.gz`

3. **Dynamic SSL certificate generation**
   - Certificates are now generated at container runtime
   - Uses `$DOMAIN_NAME` from environment variables
   - Created nginx entrypoint script with `envsubst`

4. **Docker Secrets support**
   - Passwords stored in separate files under `./secrets/`
   - Mounted securely at `/run/secrets/` in containers
   - Files are git-ignored

5. **HTTP → HTTPS redirect**
   - Added server block in nginx to redirect all HTTP traffic to HTTPS
   - Nginx listens on ports 80 and 443
   - Only HTTPS (port 443) serves actual content

6. **Environment variables**
   - Removed passwords from `.env`
   - Only stored domain name and database configuration
   - All sensitive data in Docker secrets

7. **.gitignore**
   - `.env` files are ignored
   - `secrets/` directory is ignored
   - SSL certificates are ignored
   - Database backups are ignored

---

## 📋 Setup Instructions

### 1. Create Secret Files

Create the password files in `./srcs/secrets/`:

```bash
# Database user password
echo "your_secure_db_password" > srcs/secrets/db_password.txt

# Database root password
echo "your_secure_root_password" > srcs/secrets/db_root_password.txt

# Set restrictive permissions
chmod 600 srcs/secrets/db_password.txt
chmod 600 srcs/secrets/db_root_password.txt
```

### 2. Configure .env

Edit `./srcs/.env`:

```env
DOMAIN_NAME=your_domain.com
MYSQL_HOSTNAME=mariadb
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress_user
```

### 3. Start the Stack

```bash
cd srcs/
docker-compose up -d --build
```

---

## 🔒 Security Features

| Feature | Status | Details |
|---------|--------|---------|
| Hardcoded Passwords | ✅ Removed | All passwords use Docker secrets |
| Specific Versions | ✅ Used | WordPress 6.3.1, Debian Buster |
| Environment Variables | ✅ Configured | Non-sensitive data in .env |
| Docker Secrets | ✅ Implemented | Passwords in encrypted files |
| HTTPS Only | ✅ Enforced | HTTP redirects to HTTPS |
| TLS Version | ✅ Correct | TLSv1.2 and TLSv1.3 only |
| Git Ignore | ✅ Complete | All credentials excluded from repository |
| Dynamic Certificates | ✅ Implemented | Generated at runtime from $DOMAIN_NAME |

---

## 📁 Important Files

- `.gitignore` - Ignores all sensitive files
- `./srcs/.env` - Non-sensitive configuration
- `./srcs/secrets/` - Stores password files (git-ignored)
- `./srcs/requirements/nginx/tools/entrypoint.sh` - Generates SSL certificate dynamically
- `./srcs/requirements/mysql/tools/mariadb.sh` - Reads passwords from secrets

---

## ⚠️ Important Notes

1. **Never commit** `.env` with passwords
2. **Never commit** files in `./secrets/`
3. **Backup your secrets securely** (not in git)
4. **Change default domain** from `jdupuis.42.fr` to your domain in `.env`
5. **Use strong passwords** in your secret files
6. SSL certificates are self-signed (for testing/development)

---

## 🚀 Production Recommendations

For production:
- Use Let's Encrypt for certificate generation
- Store secrets in a proper secrets management system (HashiCorp Vault, AWS Secrets Manager, etc.)
- Use strong, unique passwords
- Enable Docker content trust
- Scan images for vulnerabilities
- Use only authenticated registries
