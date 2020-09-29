#!/bin/sh

ROOT_DIR="$(cd "$(dirname "$0")" && cd ../ && pwd)"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--service) SERVICE="$2"; shift ;;
        -d|--detach) DETACH="--detach" ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ "$SERVICE" == "" ]]; then
  sh $ROOT_DIR/scripts/stop.sh
else
  sh $ROOT_DIR/scripts/stop.sh -s $SERVICE
fi

# Copies necessary files into the `.cache` directory & executes from there.
# 
# By default we use the .env-docker` at the root of the project.
# However if there's one stored at `.secure/.env-docker`, we'll prefer that.
# This allows us to store secrets in `.secure/.env-docker` without committing to git.
cp $ROOT_DIR/docker-compose.yml $ROOT_DIR/.cache/docker-compose.yml
cp $ROOT_DIR/.env-docker $ROOT_DIR/.cache/.env-docker
if [[ -f "$ROOT_DIR/.secure/.env-docker" ]]; then
  cp $ROOT_DIR/.secure/.env-docker $ROOT_DIR/.cache/.env-docker
fi

# Load env variables from `.env-docker`
LICENSE=$(grep LICENSE $CACHE_DIR/.env-docker | cut -d '=' -f2)
if [[ "$LICENSE" == "" ]]; then
  echo "LICENSE is empty. Please add it to your \".env-docker\" file"
  exit 1
fi

# Start docker
docker-compose -f $ROOT_DIR/.cache/docker-compose.yml up --build $DETACH $SERVICE