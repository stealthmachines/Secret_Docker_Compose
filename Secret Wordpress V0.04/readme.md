To automate this setup, we’ll generate new passwords dynamically for each service in .env, encrypt them for secure storage, and configure Docker Compose to decrypt and load them at runtime. The backup service will then handle both local and remote encrypted backups via duplicity and secure rsync to your homelab server.

Here's the complete setup:

1. Generate and Encrypt the .env File
Create a generate_and_encrypt_env.sh script that:

Generates random passwords for each environment variable.
Creates a new .env file with these values.
Encrypts .env into .env.gpg and securely deletes .env.
generate_and_encrypt_env.sh:
bash
Copy code
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
Run generate_and_encrypt_env.sh each time you want to generate new passwords and encrypt the .env file.

2. Modify docker-compose.yml to Use the Decrypted .env
Add a new backup configuration to the Docker Compose file, enabling both local and remote encrypted backup storage:

yaml
Copy code
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
      rsync -avz -e 'ssh -i /backup/ssh_key' /backup ${BACKUP_SSH_USER}@${BACKUP_SSH_HOST}:${BACKUP_SSH_PATH}" | crontab - && \
      crond -f

volumes:
  wordpress_data:
  db_data:
3. Deploy with Decryption and Backup Automation
Create deploy_with_decryption.sh to handle decryption and deployment:

bash
Copy code
#!/bin/bash

# Decrypt .env.gpg
echo "Enter master password to decrypt environment variables:"
gpg --quiet --batch --yes --decrypt --passphrase-fd 0 --output .env .env.gpg

# Run docker-compose with the decrypted .env file
docker-compose up -d

# Run encrypted backup
docker-compose exec backup duplicity --encrypt-key $PASSPHRASE /data file:///backup

# Securely remove the decrypted .env file
shred -u .env
Key Points
Dynamic Passwords: generate_and_encrypt_env.sh generates fresh, encrypted passwords in .env.gpg before each deployment.
Automated Encrypted Backup:
Local Storage: The backup is encrypted and saved locally in the ./backup directory.
Remote Storage: The backup is sent over a secure rsync connection to your homelab server using SSH, making it accessible only with the encryption passphrase.
Now, each deployment will use newly generated credentials and securely transfer and store encrypted backups both locally and remotely.