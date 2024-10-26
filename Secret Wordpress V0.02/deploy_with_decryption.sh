#!/bin/bash

# Prompt for master password and decrypt .env.gpg to .env
echo "Enter master password to decrypt environment variables:"
gpg --quiet --batch --yes --decrypt --passphrase-fd 0 --output .env .env.gpg

# Run docker-compose with the decrypted .env file
docker-compose up -d

# Securely remove the decrypted .env file after deployment
shred -u .env
