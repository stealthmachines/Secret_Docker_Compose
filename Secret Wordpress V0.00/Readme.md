To automatically back up these containers to your homelab in an encrypted format, we’ll modify the docker-compose.yml file by adding a backup service. This service will run periodic backups and sync the encrypted files to your homelab server.

Overview of Changes:
Add duplicity for backup encryption and syncing.
Use cron to automate the backup frequency.
Connect to your homelab via SSH or a network mount.
Here's the modified docker-compose.yml to include these features:

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
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpresspassword
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wordpress_data:/var/www/html

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: phpmyadmin
    restart: always
    ports:
      - 8081:80
    environment:
      PMA_HOST: db
      MYSQL_ROOT_PASSWORD: rootpassword

  db:
    image: mysql:5.7
    container_name: wordpress_db
    restart: always
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpresspassword
      MYSQL_ROOT_PASSWORD: rootpassword
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
    environment:
      - PASSPHRASE=your-encryption-passphrase
      - TARGET_SSH=user@homelab_server:/path/to/homelab/backup
    entrypoint: ["/bin/sh", "-c"]
    command: |
      apk add --no-cache duplicity openssh-client rsync bash && \
      echo "0 3 * * * duplicity --encrypt-key $PASSPHRASE /data file:///backup && \
      rsync -avz -e 'ssh -i /backup/ssh_key' /backup user@homelab_server:/path/to/homelab/backup" | crontab - && \
      crond -f

volumes:
  wordpress_data:
  db_data:
Explanation of the Backup Service
Backup Service Container:

Uses alpine as a lightweight base image with duplicity, openssh-client, rsync, and bash installed.
Backs up wordpress_data and db_data volumes from the WordPress and MySQL containers, making them read-only (ro) to ensure data integrity.
Stores encrypted backups in the ./backup directory.
Environment Variables:

PASSPHRASE: Set to your encryption passphrase for duplicity.
TARGET_SSH: Specifies the homelab server’s SSH destination. Replace user@homelab_server:/path/to/homelab/backup with the correct SSH user, server, and destination path on your homelab.
Cron Job:

Runs at 3:00 AM daily, performing an encrypted backup with duplicity.
rsync then syncs these encrypted backup files to your homelab server over SSH.
SSH Key:

For automated, secure transfers to your homelab, add an SSH key in the backup directory. Generate a key pair (e.g., ssh-keygen -f /path/to/backup/ssh_key) and copy the public key to your homelab server's authorized_keys.
Local Backup Storage:

The ./backup directory holds the encrypted backups for local storage. Adjust or change this path if you want to store backups elsewhere.
After these changes, start your containers:

bash
Copy code
docker-compose up -d
This configuration will automate backups, encrypt them with duplicity, and transfer them to your homelab server for redundancy. Make sure to replace paths and variables as needed for your specific setup.