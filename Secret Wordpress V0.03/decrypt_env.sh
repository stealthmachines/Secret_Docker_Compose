#!/bin/bash

# Prompt for master password and decrypt .env.gpg to .env
echo "Enter master password to decrypt .env:"
gpg --quiet --batch --yes --decrypt --passphrase-fd 0 --output .env .env.gpg
