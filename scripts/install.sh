#!/bin/sh -l

# Install docker-compose
sudo -E curl -L https://github.com/docker/compose/releases/download/1.27.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install docker
wget -qO- https://get.docker.com/ | sh