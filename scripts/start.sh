#!/bin/bash

CWD="$(cd "$(dirname "$0")" && pwd)"
source $CWD/vars.sh || exit 1

while [ "$#" -gt 0 ]; do
    case $1 in
        -s|--service) SERVICE="$2"; shift ;;
        -d|--detach) DETACH="--detach" ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ "$SERVICE" == "" ]]; then
  bash $ROOT_DIR/scripts/stop.sh
else
  bash $ROOT_DIR/scripts/stop.sh -s $SERVICE
fi

$ROOT_DIR/scripts/build.sh

# Start docker
DOCKER_WEB_CPU=$(grep DOCKER_WEB_CPU $CACHE_DIR/.env-docker | cut -d '=' -f2)
DOCKER_WEB_MEMORY=$(grep DOCKER_WEB_MEMORY $CACHE_DIR/.env-docker | cut -d '=' -f2)
DOCKER_WORKER_CPU=$(grep DOCKER_WORKER_CPU $CACHE_DIR/.env-docker | cut -d '=' -f2)
DOCKER_WORKER_MEMORY=$(grep DOCKER_WORKER_MEMORY $CACHE_DIR/.env-docker | cut -d '=' -f2)

echo "ℹ️  DOCKER_WEB_CPU: $DOCKER_WEB_CPU"
echo "ℹ️  DOCKER_WEB_MEMORY: $DOCKER_WEB_MEMORY"
echo "ℹ️  DOCKER_WORKER_CPU: $DOCKER_WORKER_CPU"
echo "ℹ️  DOCKER_WORKER_MEMORY: $DOCKER_WORKER_MEMORY"

DOCKER_WEB_CPU=$DOCKER_WEB_CPU \
  DOCKER_WEB_MEMORY=$DOCKER_WEB_MEMORY \
  DOCKER_WORKER_CPU=$DOCKER_WORKER_CPU \
  DOCKER_WORKER_MEMORY=$DOCKER_WORKER_MEMORY \
  docker-compose -f $ROOT_DIR/.cache/docker-compose.yml up --build $DETACH $SERVICE