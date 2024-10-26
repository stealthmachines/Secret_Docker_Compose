To implement a GPG encryption scheme for scrambling all passwords, we can use GPG-encrypted files for the environment variables, which will decrypt automatically on each docker-compose up command. Here's a step-by-step guide on setting up this workflow:

Steps
Store All Sensitive Information in .env: This will be the file to encrypt with GPG.
Encrypt the .env file with GPG: Use your master password for encryption.
Automate Decryption Before docker-compose up: Create a script that decrypts .env.gpg just before running docker-compose.
Delete .env After Deployment: Ensure that the decrypted .env file is removed after each deployment to maintain security.
Implementation
Step 1: Create and Populate the .env File
In your project directory, create a .env file with sensitive information:

env
Copy code
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=your_secure_wp_db_password
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_PASSWORD=your_secure_db_password
PMA_PASSWORD=your_phpmyadmin_password
PASSPHRASE=your_encryption_passphrase
Step 2: Encrypt the .env File
Run this command to encrypt .env with GPG using a strong symmetric encryption algorithm. You’ll be prompted to enter a master password, which will be required each time you deploy.

bash
Copy code
gpg --symmetric --cipher-algo AES256 .env
This will create an encrypted .env.gpg file. Now delete the unencrypted .env file:

bash
Copy code
rm .env
Step 3: Modify docker-compose.yml to Use the Decrypted .env
In docker-compose.yml, specify .env as the environment file so Docker Compose will use it after it’s decrypted.

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
      - .env  # Uses decrypted .env file at runtime
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
Step 4: Create a Script to Decrypt .env.gpg Before Deployment
Create a script, deploy_with_decryption.sh, to handle the decryption and deployment process. This script will:

Prompt for the master password.
Decrypt .env.gpg into .env.
Run docker-compose up to start the services.
Delete .env after deployment to keep the decrypted data secure.
Content for deploy_with_decryption.sh:

bash
Copy code
#!/bin/bash

# Prompt for master password and decrypt .env.gpg to .env
echo "Enter master password to decrypt environment variables:"
gpg --quiet --batch --yes --decrypt --passphrase-fd 0 --output .env .env.gpg

# Run docker-compose with the decrypted .env file
docker-compose up -d

# Securely remove the decrypted .env file after deployment
shred -u .env
Make the script executable:

bash
Copy code
chmod +x deploy_with_decryption.sh
Step 5: Run the Deployment Script
Now, to deploy your Docker containers securely, run:

bash
Copy code
./deploy_with_decryption.sh
This script will ask for the master password each time and ensure that the .env file is securely removed after deployment.

Security Notes
shred -u: This command securely deletes .env by overwriting it before deletion.
Avoid Storing the Master Password in Plain Text: The password should only be entered at runtime to prevent exposure.
Back Up Your .env.gpg: Make sure to securely back up your .env.gpg file since it contains all necessary credentials in encrypted form.
This approach centralizes all sensitive environment variables in a secure, encrypted file and requires only the master password for deployment.