Currently, with this setup:

Passwords in .env: The passwords remain the same on each docker-compose up command because they are stored in the .env.gpg file, which is decrypted each time but does not change.

To generate new passwords on each deployment:

We can use a script to generate unique passwords each time and encrypt them back into .env.gpg.
This would involve regenerating and encrypting the .env file on each run, ensuring you only use fresh passwords at runtime.
Backup Encryption and Storage:

The backup is encrypted using duplicity with a passphrase stored in .env.gpg.
The encrypted backup is saved in the ./backup directory (local), and it is also synced to your homelab server.
Since the backup files are encrypted by duplicity, they are secure and only accessible with the encryption passphrase.
Secure Transfer to Homelab Server:

The rsync command in the backup service uses SSH (ssh -i /backup/ssh_key) to securely transfer the encrypted backup files to your homelab server.
This ensures the connection is secure and encrypted during the transfer, provided that SSH keys are set up correctly.
Updates for Dynamic Passwords and Secure Backup
To meet your exact requirements, here’s an improved setup:

1. Dynamic Password Generation
We’ll create a script to:

Generate new passwords dynamically on each docker-compose up run.
Update the .env file with these passwords, re-encrypt it, and securely remove the plaintext .env.
Example generate_and_encrypt_env.sh:

bash
Copy code
#!/bin/bash

# Generate unique passwords for each variable
WORDPRESS_DB_PASSWORD=$(openssl rand -hex 16)
MYSQL_ROOT_PASSWORD=$(openssl rand -hex 16)
MYSQL_PASSWORD=$(openssl rand -hex 16)
PMA_PASSWORD=$(openssl rand -hex 16)
PASSPHRASE=$(openssl rand -hex 16)

# Create the .env file with the generated passwords
cat <<EOF > .env
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=$WORDPRESS_DB_PASSWORD
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_PASSWORD=$MYSQL_PASSWORD
PMA_PASSWORD=$PMA_PASSWORD
PASSPHRASE=$PASSPHRASE
EOF

# Encrypt .env and delete plaintext version
gpg --symmetric --cipher-algo AES256 .env
shred -u .env  # Securely delete the unencrypted .env
Run this script each time before docker-compose up to regenerate passwords and update .env.gpg with them.

2. Automate the Full Deployment with Encrypted Backup
Now, combine decryption, backup, and deployment in deploy_with_encryption.sh:

bash
Copy code
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
To maintain secure and fresh passwords:

Run ./generate_and_encrypt_env.sh first to generate and encrypt new passwords.
Then run ./deploy_with_encryption.sh for each docker-compose up.
Key Points of the Improved Setup
Dynamic Passwords: Each deployment generates new passwords, re-encrypts .env.gpg, and uses them only during runtime.
Encrypted Backup and Secure Transfer: The backup files are encrypted by duplicity, stored locally in encrypted format, and transferred over SSH to your homelab server securely.
This approach ensures fully dynamic, secure, and encrypted handling of passwords and backup data across deployments and backups.