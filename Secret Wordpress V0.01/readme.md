To enhance password security for this setup, we'll use Docker's .env file to store sensitive passwords and protect them with a "master" password. Here’s how:

Create a .env File for Sensitive Data:

Use the .env file to store environment variables outside the docker-compose.yml file. This file should contain all passwords and sensitive information.
We’ll use Docker secrets with a custom script to decrypt sensitive data only when needed.
Encrypt the .env File:

Encrypt the .env file using a secure tool like GPG.
This will require a "master password" to decrypt the .env file, which only authorized users can access.
Here’s how to implement this setup:

Step 1: Create and Populate the .env File
In the project directory, create a .env file and store sensitive environment variables:

env
Copy code
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=your_secure_wp_db_password
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_PASSWORD=your_secure_db_password
PASSPHRASE=your_encryption_passphrase
Save the .env file.

Step 2: Encrypt the .env File
Encrypt the .env file using a GPG command. You’ll be prompted to enter a master password:

bash
Copy code
gpg --symmetric --cipher-algo AES256 .env
This command creates an encrypted .env.gpg file.

Step 3: Modify docker-compose.yml to Use the .env File
In docker-compose.yml, refer to the .env file by specifying env_file for each service. Add a new decrypt_env.sh script that decrypts .env.gpg only when the stack is deployed.

Updated docker-compose.yml:

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
      - .env  # Use decrypted environment file
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
      rsync -avz -e 'ssh -i /backup/ssh_key' /backup user@homelab_server:/path/to/homelab/backup" | crontab - && \
      crond -f

volumes:
  wordpress_data:
  db_data:
Step 4: Automate Decryption with a Shell Script
Create a decrypt_env.sh script that decrypts .env.gpg before starting docker-compose.

Example decrypt_env.sh:

bash
Copy code
#!/bin/bash

# Prompt for master password and decrypt .env.gpg to .env
echo "Enter master password to decrypt .env:"
gpg --quiet --batch --yes --decrypt --passphrase-fd 0 --output .env .env.gpg
After decrypting, run docker-compose up to deploy the containers with the decrypted environment.

Step 5: Run the Containers Securely
To run the containers with the decrypted .env file:

bash
Copy code
./decrypt_env.sh && docker-compose up -d
This workflow will keep passwords encrypted and secure, using a master password for decryption only when the containers are started.