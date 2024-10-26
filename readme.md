Secure Docker Compose Environment with Automated Backup and Encryption
This setup provides a streamlined way to deploy containerized services with Docker Compose. Each service’s environment variables (including sensitive passwords) are securely generated and stored using GPG encryption. Additionally, local and remote backups are automated for all specified services, accessible only with a master password.

Features
Dynamic Container Configuration: Add containers on-the-fly by entering Docker image names, and the script will auto-generate a docker-compose.yml file.
Environment Variable Encryption: Sensitive environment variables are securely stored in an encrypted .env file.
Automated Local and Remote Backups: Periodic, encrypted backups are automatically scheduled for secure storage on your homelab or other remote server.
Single Master Password: Access and manage all encrypted secrets with a single master password.
Setup Instructions
Clone or download this repository containing the following setup script and files:

setup_docker_env.sh: The main setup script to configure Docker Compose, environment variables, and encryption.
deploy_with_decryption.sh: Deployment script to start Docker Compose after decrypting the environment variables.
Run the Initial Setup:
Run the setup script, which will prompt you to configure and secure your environment.

bash
Copy code
./setup_docker_env.sh
Setup Details: You’ll be prompted to enter essential setup information:
Domain name
Master password for encryption
SSH credentials for remote backup
List of containers to add (e.g., wordpress, phpmyadmin, mysql, or any other Docker Hub image name).
Environment File Encryption:

The script generates a .env file with dynamically created passwords for each environment variable.
The .env file is encrypted with GPG using your master password and securely deleted after encryption.
Usage
Deploying Services
After the initial setup, use deploy_with_decryption.sh to decrypt and start Docker Compose.

bash
Copy code
./deploy_with_decryption.sh
This script will prompt for the master password to decrypt the .env.gpg file.
Docker Compose will launch the specified services using the decrypted .env.
After launching, the decrypted .env is securely deleted.
Backup Service
The backup service is automatically configured in docker-compose.yml and will:

Perform local backups of your Docker volumes.
Send encrypted backups over a secure connection to the remote SSH server.
Example docker-compose.yml
The following is a sample docker-compose.yml generated by the setup script:

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
      echo "0 3 * * * duplicity --encrypt-key \$PASSPHRASE /data file:///backup && \
      rsync -avz -e 'ssh -i /backup/ssh_key' /backup \${BACKUP_SSH_USER}@\${BACKUP_SSH_HOST}:\${BACKUP_SSH_PATH}" | crontab - && \
      crond -f

volumes:
  wordpress_data:
  db_data:
Files Generated
.env.gpg: Encrypted environment variables file containing sensitive passwords and configuration details.
docker-compose.yml: The Docker Compose file with services specified by the user.
deploy_with_decryption.sh: Deployment script to decrypt .env.gpg and start services.
Security Notes
Master Password: Your master password is required only during setup and deployment. Use a strong, unique password.
Environment Decryption: .env.gpg is decrypted only when deploying services; .env is deleted immediately after.
Backup Security: Backups are encrypted and can only be decrypted with the specified encryption key.
Troubleshooting
GPG Decryption Fails: Ensure you’re using the correct master password.
Container Not Found: Verify container names and ensure they exist on Docker Hub.
Backup Issues: Check SSH connectivity and path permissions on the remote server.
License
This project is licensed under the MIT License.

This README provides all necessary information to understand, set up, and use your secure Docker Compose environment. Just save it as README.md alongside your project files!