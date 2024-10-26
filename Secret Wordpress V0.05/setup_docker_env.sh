#!/bin/bash

echo "Welcome! Let's set up your Docker Compose environment with secure credentials."

# Prompt for basic setup details
read -p "Enter domain name (e.g., stealthmachines.com): " DOMAIN_NAME
read -p "Enter the master password for encrypting credentials: " -s MASTER_PASSWORD
echo
read -p "Enter SSH username for remote backup: " SSH_USER
read -p "Enter SSH host for remote backup: " SSH_HOST
read -p "Enter SSH path for remote backup location: " SSH_PATH

# Generate dynamic passwords
WORDPRESS_DB_PASSWORD=$(openssl rand -hex 16)
MYSQL_ROOT_PASSWORD=$(openssl rand -hex 16)
MYSQL_PASSWORD=$(openssl rand -hex 16)
PMA_PASSWORD=$(openssl rand -hex 16)
PASSPHRASE=$(openssl rand -hex 16)

# Generate the .env file
cat <<EOF > .env
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=$WORDPRESS_DB_PASSWORD
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_PASSWORD=$MYSQL_PASSWORD
PMA_PASSWORD=$PMA_PASSWORD
PASSPHRASE=$PASSPHRASE
BACKUP_SSH_USER=$SSH_USER
BACKUP_SSH_HOST=$SSH_HOST
BACKUP_SSH_PATH=$SSH_PATH
EOF

# Encrypt the .env file
echo "$MASTER_PASSWORD" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 .env
shred -u .env  # Securely delete the plaintext .env

# Create docker-compose.yml based on user inputs and encrypted environment file
cat <<EOF > docker-compose.yml
version: '3.7'

services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: always
    ports:
      - 8080:80
    env_file:
      - .env
    volumes:
      - wordpress_data:/var/www/html

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: phpmyadmin
    restart: always
    ports:
      - 8081:80
    env_file:
      - .env

  db:
    image: mysql:5.7
    container_name: wordpress_db
    restart: always
    env_file:
      - .env
    volumes:
      - db_data:/var/lib/mysql

  backup:
    image: alpine:latest
    container_name: wordpress_backup
    restart: always
    volumes:
      - wordpress_data:/data/wordpress:ro
      - db_data:/data/db:ro
      - ./backup:/backup  # Local backup directory
    env_file:
      - .env
    entrypoint: ["/bin/sh", "-c"]
    command: |
      apk add --no-cache duplicity openssh-client rsync bash && \
      echo "0 3 * * * duplicity --encrypt-key $PASSPHRASE /data file:///backup && \
      rsync -avz -e 'ssh -i /backup/ssh_key' /backup \${BACKUP_SSH_USER}@\${BACKUP_SSH_HOST}:\${BACKUP_SSH_PATH}" | crontab - && \
      crond -f

volumes:
  wordpress_data:
  db_data:
EOF

# Create the deploy_with_decryption.sh script
cat <<'EOF' > deploy_with_decryption.sh
#!/bin/bash

# Prompt for master password to decrypt .env.gpg
echo "Enter master password to decrypt environment variables:"
read -s MASTER_PASSWORD

# Decrypt .env.gpg to .env
echo "$MASTER_PASSWORD" | gpg --quiet --batch --yes --passphrase-fd 0 --decrypt --output .env .env.gpg

# Start Docker Compose with decrypted .env file
docker-compose up -d

# Run encrypted backup
docker-compose exec backup duplicity --encrypt-key $PASSPHRASE /data file:///backup

# Securely remove the decrypted .env file
shred -u .env
EOF

chmod +x deploy_with_decryption.sh  # Make deploy script executable

echo "Setup complete!"
echo "Run './deploy_with_decryption.sh' to start the containers and back up data securely."
