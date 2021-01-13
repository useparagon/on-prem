#!/bin/bash

echo "⏱  Building docker configuration..."

ROOT_DIR="$(pwd -P)"
CACHE_DIR=$ROOT_DIR/.cache
SECURE_DIR=$ROOT_DIR/.secure

echo "ℹ️  ROOT_DIR: $ROOT_DIR"
echo "ℹ️  CACHE_DIR: $CACHE_DIR"
echo "ℹ️  SECURE_DIR: $SECURE_DIR"

# Copies necessary files into the `.cache` directory & executes from there.
# 
# By default we use the .env-docker` at the root of the project.
# However if there's one stored at `.secure/.env-docker`, we'll prefer that.
# This allows us to store secrets in `.secure/.env-docker` without committing to git.
cp $ROOT_DIR/docker-compose.yml $CACHE_DIR/docker-compose.yml
cp $ROOT_DIR/.env-docker $CACHE_DIR/.env-docker
if [ -f "$SECURE_DIR/.env-docker" ]; then
  cp $SECURE_DIR/.env-docker $CACHE_DIR/.env-docker
fi

# Load env variables from `.env-docker`
LICENSE=$(grep LICENSE $CACHE_DIR/.env-docker | cut -d '=' -f2)
if [[ "$LICENSE" == "" ]]; then
  echo "LICENSE is empty. Please add it to your \".env-docker\" file"
  exit 1
fi

echo "✅ Built docker configuration."