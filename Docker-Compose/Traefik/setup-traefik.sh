#!/bin/bash
# chmod +x setup-traefik.sh

# Set variables
TRAFFIK_DIR="$HOME/traefik"     # Specify the Traefik directory
DATA_DIR="$HOME/traefik/data"   # Specify the data directory
LINUX_USER="linux-user"         # Specify the Linux user for Docker admin
USER="your_username"            # Specify the user variable (for Traefik dashboard)
PASSWORD="your_password"        # Specify the password for the Traefik dashboard (replace with your actual password)

# Add the existing Linux user to the Docker group to allow Docker usage without sudo
echo "Adding $LINUX_USER to the Docker group..."
sudo usermod -aG docker "$LINUX_USER"

# Prompt the user to log out and back in to apply Docker group changes
echo "The user $LINUX_USER has been added to the Docker group. Please log out and back in for the changes to take effect."

# Navigate to the Traefik directory
cd "$TRAFFIK_DIR" || { echo "Failed to navigate to Traefik directory"; exit 1; }

# Navigate to data directory and create acme.json
cd "$DATA_DIR" || { echo "Failed to navigate to data directory"; exit 1; }
touch acme.json
chmod 600 acme.json

# Check if traefik.yml exists in the data directory
if [ ! -f "$DATA_DIR/traefik.yml" ]; then
    echo "traefik.yml not found in $DATA_DIR"
    exit 1
fi

# Check if cf_api_token.txt exists in the Traefik directory
if [ ! -f "$TRAFFIK_DIR/cf_api_token.txt" ]; then
    echo "cf_api_token.txt not found in $TRAFFIK_DIR"
    exit 1
fi

# Create Docker network named "proxy"
docker network create proxy

# Install apache2-utils for htpasswd (only if not already installed)
if ! command -v htpasswd &>/dev/null; then
    echo "Installing apache2-utils for htpasswd..."
    sudo apt install -y apache2-utils
fi

# Generate the hash for the user password
HASH=$(echo "$PASSWORD" | htpasswd -nB "$USER" | sed -e 's/\$/\$\$/g')

# Display the hash output to the user
echo "Generated hash for $USER: $HASH"

# Save the hash into the .env file in the Traefik directory
echo "TRAEFIK_DASHBOARD_CREDENTIALS=$HASH" > "$TRAFFIK_DIR/.env"

# Output to let the user know the script is complete
echo "Traefik setup complete. Dashboard credentials have been saved in .env file in the Traefik directory."

# Execute docker compose to recreate and start the containers
docker compose up -d --force-recreate -f "$TRAFFIK_DIR/traefik-docker-compose.yml"

# Output to let the user know that the containers are being recreated
echo "Docker Compose containers have been recreated and started."
