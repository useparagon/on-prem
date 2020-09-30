#!/bin/bash

sudo apt-get update
sudo apt-get install -y redis-tools
sudo apt-get install docker.io
sudo -E curl -L https://github.com/docker/compose/releases/download/1.27.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose