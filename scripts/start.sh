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

# Copies & runs docker-compose from the `.cache` directory
# This allows us to store secrets in `.cache/docker.env` without committing to git
cp $ROOT_DIR/docker-compose.yml $ROOT_DIR/.cache/docker-compose.yml

# Start docker
docker-compose -f $ROOT_DIR/.cache/docker-compose.yml up --build $DETACH $SERVICE