# 🚀 Secure Docker Compose Environment with Automated Backup and Encryption

A streamlined solution for deploying containerized services using Docker Compose, complete with GPG-encrypted environment variables and automated local and remote backups, accessible only with a master password.

---

## 🌟 Features

- **Dynamic Container Configuration**: Easily add containers with prompts and automatically generate a `docker-compose.yml`.
- **Environment Variable Encryption**: Secure sensitive environment variables using GPG encryption.
- **Automated Local & Remote Backups**: Periodic, encrypted backups for secure storage on your homelab or remote server.
- **Single Master Password**: Manage all secrets with a single master password.

---

## 📋 Setup Instructions

1. **Clone or Download** this repository with the following files:
   - **`setup_docker_env.sh`**: Main script to configure Docker Compose, environment variables, and encryption.
   - **`deploy_with_decryption.sh`**: Script to start Docker Compose after decrypting environment variables.

2. **Run the Setup Script**:
   ```bash
   ./setup_docker_env.sh
Setup Prompts: Configure essential details:
Domain name
Master password for encryption
SSH credentials for remote backup
List of containers to add (e.g., wordpress, phpmyadmin, mysql)
Environment Encryption:
Generates a .env file with secure, auto-generated passwords.
Encrypts .env with GPG using your master password, then securely deletes it.
⚙️ Usage
🚀 Deploying Services
Run deploy_with_decryption.sh to decrypt the environment file and start Docker Compose:

bash
Copy code
./deploy_with_decryption.sh
Decryption Prompt: Enter your master password to decrypt .env.gpg.
Environment Cleanup: After deployment, the decrypted .env is deleted to maintain security.
🔒 Backup Service
The backup service in docker-compose.yml performs:

Local Backups: Backs up Docker volumes locally.
Remote Backup: Sends encrypted backups to the specified remote SSH server.
🔧 Example docker-compose.yml
The docker-compose.yml generated by the setup script will look like this:

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
📄 Files Generated
.env.gpg: Encrypted environment variables file containing sensitive credentials.
docker-compose.yml: Docker Compose file with services as specified by the user.
deploy_with_decryption.sh: Script for decrypting .env.gpg and starting services.
🔐 Security Notes
Master Password: Only required during setup and deployment. Use a strong, unique password.
Environment Decryption: .env.gpg is decrypted only at deployment, and .env is deleted immediately afterward.
Backup Security: Encrypted backups can only be decrypted with the specified encryption key.
🛠 Troubleshooting
GPG Decryption Fails: Verify the master password is correct.
Container Not Found: Confirm container names on Docker Hub.
Backup Issues: Check SSH connectivity and remote server permissions.
📜 License
This project is licensed under the MIT License.
