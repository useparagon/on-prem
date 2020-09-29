#!/bin/sh -l

ROOT_DIR="$(cd "$(dirname "$0")" && cd ../ && pwd)"
PUBLIC_KEY_PATH=$ROOT_DIR/.secure/id_rsa.pub
PRIVATE_KEY_PATH=$ROOT_DIR/.secure/id_rsa

if [[ -f "$PUBLIC_KEY_PATH" ]] && [[ -f "$PRIVATE_KEY_PATH" ]]; then
  echo "✅ existing public + private key available"
else
  echo "⏱  Creating public + private key..."
  ssh-keygen -t rsa -b 4096 -C "Paragon" -f "$ROOT_DIR/.secure/id_rsa"
  echo "✅ Created public + private key."
fi