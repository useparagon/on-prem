#!/bin/sh

echo "⏱  Stopping containers..."

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--service) SERVICE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

ROOT_DIR="$(cd "$(dirname "$0")" && cd ../ && pwd)"

if [[ "$SERVICE" == "" ]]; then
  docker-compose -f $ROOT_DIR/.cache/docker-compose.yml down

  docker rm paragon-cerberus
  docker rm paragon-hercules
  docker rm paragon-hermes
  docker rm paragon-api
  docker rm paragon-web
else
  docker stop paragon-$SERVICE
  docker rm paragon-$SERVICE
fi

echo "✅ Stopped containers."