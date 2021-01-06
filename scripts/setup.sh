#!/bin/sh -l

# Install docker-compose
if ! [ -x "$(command -v docker-compose)" ]; then
  echo "\"docker-compose\" command not found; installing"
  sudo -E curl -L https://github.com/docker/compose/releases/download/1.27.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

# Install docker
if ! [ -x "$(command -v docker)" ]; then
  echo "\"docker\" command not found; installing"
  wget -qO- https://get.docker.com/ | sh
fi;