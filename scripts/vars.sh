#!/bin/bash

export ROOT_DIR="$(cd "$(dirname "$0")" && cd ../ && pwd -P)"
export CACHE_DIR=$ROOT_DIR/.cache
export SECURE_DIR=$ROOT_DIR/.secure
export TF_DIR=$CACHE_DIR/aws