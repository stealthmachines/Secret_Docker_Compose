#!/bin/bash

# Generate unique passwords
WORDPRESS_DB_PASSWORD=$(openssl rand -hex 16)
MYSQL_ROOT_PASSWORD=$(openssl rand -hex 16)
MYSQL_PASSWORD=$(openssl rand -hex 16)
PMA_PASSWORD=$(openssl rand -hex 16)
PASSPHRASE=$(openssl rand -hex 16)

# Create the .env file
cat <<EOF > .env
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=$WORDPRESS_DB_PASSWORD
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_PASSWORD=$MYSQL_PASSWORD
PMA_PASSWORD=$PMA_PASSWORD
PASSPHRASE=$PASSPHRASE
BACKUP_SSH_USER=user
BACKUP_SSH_HOST=homelab_server
BACKUP_SSH_PATH=/path/to/homelab/backup
EOF

# Encrypt .env with GPG
gpg --symmetric --cipher-algo AES256 .env
shred -u .env  # Securely delete unencrypted .env
echo ".env file generated, encrypted, and removed."
