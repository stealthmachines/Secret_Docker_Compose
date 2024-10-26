#!/bin/bash

# Generate unique passwords for each variable
WORDPRESS_DB_PASSWORD=$(openssl rand -hex 16)
MYSQL_ROOT_PASSWORD=$(openssl rand -hex 16)
MYSQL_PASSWORD=$(openssl rand -hex 16)
PMA_PASSWORD=$(openssl rand -hex 16)
PASSPHRASE=$(openssl rand -hex 16)

# Create the .env file with the generated passwords
cat <<EOF > .env
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=$WORDPRESS_DB_PASSWORD
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_PASSWORD=$MYSQL_PASSWORD
PMA_PASSWORD=$PMA_PASSWORD
PASSPHRASE=$PASSPHRASE
EOF

# Encrypt .env and delete plaintext version
gpg --symmetric --cipher-algo AES256 .env
shred -u .env  # Securely delete the unencrypted .env
