#!/bin/bash

echo "Welcome! Let's set up a secure Docker Compose environment for your chosen services."

# Prompt for master password
read -p "Enter the master password for encrypting credentials: " -s MASTER_PASSWORD
echo

# Initialize .env file
> .env  # Clear any previous contents

# Docker Compose file initialization
cat <<EOF > docker-compose.yml
version: '3.7'
services:
EOF

# Define function to add service to Docker Compose
add_service_to_compose() {
  local SERVICE_NAME=$1
  local IMAGE_NAME=$2
  local PORT_MAPPING=$3
  local ENV_VARS=$4
  
  echo "  $SERVICE_NAME:" >> docker-compose.yml
  echo "    image: $IMAGE_NAME" >> docker-compose.yml
  echo "    container_name: $SERVICE_NAME" >> docker-compose.yml
  echo "    restart: always" >> docker-compose.yml
  [ -n "$PORT_MAPPING" ] && echo "    ports:" >> docker-compose.yml && echo "      - $PORT_MAPPING" >> docker-compose.yml
  echo "    env_file:" >> docker-compose.yml
  echo "      - .env" >> docker-compose.yml

  # Append each environment variable to .env with a generated password
  for ENV_VAR in $ENV_VARS; do
    GENERATED_PASSWORD=$(openssl rand -hex 16)
    echo "$ENV_VAR=$GENERATED_PASSWORD" >> .env
  done
}

# Prompt user to add containers
while true; do
  echo -n "Enter the name of the Docker container to add (e.g., wordpress, phpmyadmin, mysql), or type 'done' when finished: "
  read CONTAINER_NAME

  if [[ "$CONTAINER_NAME" == "done" ]]; then
    break
  fi

  # Check if the container name exists in Docker Hub library
  if ! docker pull $CONTAINER_NAME > /dev/null 2>&1; then
    echo "Error: Container '$CONTAINER_NAME' not found on Docker Hub. Please try again."
    continue
  fi

  # Identify default ports and environment variables for some common containers
  case $CONTAINER_NAME in
    wordpress)
      PORT_MAPPING="8080:80"
      ENV_VARS="WORDPRESS_DB_USER WORDPRESS_DB_PASSWORD"
      ;;
    phpmyadmin)
      PORT_MAPPING="8081:80"
      ENV_VARS="PMA_HOST MYSQL_ROOT_PASSWORD"
      ;;
    mysql)
      PORT_MAPPING=""
      ENV_VARS="MYSQL_ROOT_PASSWORD MYSQL_USER MYSQL_PASSWORD"
      ;;
    *)
      PORT_MAPPING=""
      ENV_VARS="APP_PASSWORD APP_USER"  # Generic placeholders; user may need to modify based on actual needs
      ;;
  esac

  add_service_to_compose "$CONTAINER_NAME" "$CONTAINER_NAME:latest" "$PORT_MAPPING" "$ENV_VARS"
done

# Add backup service
cat <<EOF >> docker-compose.yml
  backup:
    image: alpine:latest
    container_name: backup
    restart: always
    volumes:
      - ./backup:/backup  # Local backup directory
    env_file:
      - .env
    entrypoint: ["/bin/sh", "-c"]
    command: |
      apk add --no-cache duplicity openssh-client rsync bash && \
      echo "0 3 * * * duplicity --encrypt-key \$PASSPHRASE /data file:///backup && \
      rsync -avz -e 'ssh -i /backup/ssh_key' /backup \${BACKUP_SSH_USER}@\${BACKUP_SSH_HOST}:\${BACKUP_SSH_PATH}" | crontab - && \
      crond -f
EOF

# Append generic backup environment variables to .env
echo "BACKUP_SSH_USER=$SSH_USER" >> .env
echo "BACKUP_SSH_HOST=$SSH_HOST" >> .env
echo "BACKUP_SSH_PATH=$SSH_PATH" >> .env

# Encrypt .env with GPG
echo "$MASTER_PASSWORD" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 .env
shred -u .env  # Securely delete unencrypted .env

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
