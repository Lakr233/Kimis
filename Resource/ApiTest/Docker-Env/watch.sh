#!/bin/zsh

set -e # Exit immediately if a command exits with a non-zero status.

cd "$(dirname "$0")" 

# check if docker-compose.yml exists
if [ ! -f docker-compose.yml ]; then
    echo "[-] malformed project structure"
    exit 1
fi

docker-compose logs -f