#!/bin/zsh

set -e # Exit immediately if a command exits with a non-zero status.

cd "$(dirname "$0")" 

# check if docker-compose.yml exists
if [ ! -f docker-compose.yml ]; then
    echo "[-] malformed project structure"
    exit 1
fi

echo "[+] stop environment"
docker-compose kill
docker-compose down -v

echo "[+] reset this directory in git"
git clean -fdx
git checkout -- .

echo "[+] done"
