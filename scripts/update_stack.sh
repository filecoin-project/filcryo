#!/bin/bash

# Pull any updates to the filcryo repository.
pushd /opt/filcryo || exit 1

# Fetch the latest changes from the remote repository
git fetch

# Check if there are any changes to be merged
if git diff HEAD origin/main --quiet; then
  echo "No changes to the repository. Exiting."
  exit 0
fi

# Pull the latest changes from the remote repository
git pull origin/main

echo "There was an update: building and deploying"

docker build --no-cache -t filcryo:latest -f Dockerfile

docker compose down
docker compose up --quite-pull --pull=always --detach

echo "Docker compose Filcryo stack was recreated"
