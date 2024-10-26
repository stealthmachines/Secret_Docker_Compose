#!/bin/bash

# Decrypt the .env file
echo "Enter master password to decrypt environment variables:"
gpg --quiet --batch --yes --decrypt --passphrase-fd 0 --output .env .env.gpg

# Run docker-compose with the decrypted .env file
docker-compose up -d

# Run backup service (ensure duplicity encryption with new passphrase)
docker-compose exec backup duplicity --encrypt-key $PASSPHRASE /data file:///backup

# Securely remove the decrypted .env file
shred -u .env
