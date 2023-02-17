#!/bin/bash

set -e
# Pull any updates to the filcryo repository.
pushd /opt/filcryo || exit 0

# Fetch the latest changes from the remote repository
git fetch

# Check if there are any changes to be merged
if git diff HEAD origin/main --quiet && \
	[ "$(docker compose -f /opt/filcryo/docker-compose.yml ps -q)" != "" ];
then
  echo "No changes to the repository and the Filcryo stack is running. Exiting."
  exit 0
fi

echo "Pulling repository and deploying the Filcryo stack"

# Pull the latest changes from the remote repository
git pull origin/main

echo "There was an update: building and deploying"

docker build --no-cache -t filcryo:latest -f Dockerfile

docker compose down
docker compose up --quite-pull --pull=always --detach

echo "Docker compose Filcryo stack was recreated"
