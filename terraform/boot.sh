#!/bin/bash

set -e

if [ -x "$(command -v docker)" ]; then
    echo "Docker is already installed, skipping installation"
else
    echo "Installing Docker-ce from official repositories"
    # Update the package index and install necessary dependencies.
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release emacs-nox

    # Add the Docker GPG key and repository to the system.
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
	"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update the package index again and install Docker CE.
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    echo "Docker CE has been installed"
fi

if [ -d "/opt/filcryo" ]; then
    echo "Filcryo is already installed"
else
    echo "Cloning Filcryo"
    sudo git clone --depth 1 https://github.com/filecoin-project/filcryo.git /opt/filcryo
fi

# Define a function to fetch a secret from Google Cloud Secrets Manager and append it to an .env file.
fetch_secret() {
  secret_name=$1
  secret_value=$(gcloud secrets versions access latest --secret="${secret_name}")

  echo "$secret_name=$secret_value" >> /opt/filcryo/.env-temp
}

# Fetch secrets and append them to the .env file.
fetch_secret "FILCRYO_PROMETHEUS_USERNAME"
fetch_secret "FILCRYO_PROMETHEUS_PASSWORD"
fetch_secret "FILCRYO_LOKI_USERNAME"
fetch_secret "FILCRYO_LOKI_PASSWORD"
mv /opt/filcryo/.env-temp /opt/filcryo/.env

# Write cronjobs to the crontab file.
echo "Installing cronjob to check updates every minute"
echo "* * * * * root /opt/filcryo/scripts/update_stack.sh >> /opt/filcryo/update_stack_log 2>&1" > /etc/cron.d/update_stack
