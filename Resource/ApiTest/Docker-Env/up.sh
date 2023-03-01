#!/bin/zsh

set -e # Exit immediately if a command exits with a non-zero status.

cd "$(dirname "$0")" 

# check if docker-compose.yml exists
if [ ! -f docker-compose.yml ]; then
    echo "[-] malformed project structure"
    exit 1
fi

echo "[+] reset this directory in git"
git clean -fdx
git checkout -- .

echo "[+] extract payload dir from payload.tar.gz"
tar -xzf payload.tar.gz

echo "[+] waiting for file system to get ready..."
sleep 1

echo "[+] start environment"
# docker-compose pull
docker-compose up --force-recreate

echo "[+] done"
