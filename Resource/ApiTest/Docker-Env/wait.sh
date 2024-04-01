#!/bin/zsh

# wait for most 3 min for the docker container to be ready
# checkout http://127.0.0.1:3555/ for the status

ENDPOINT="http://127.0.0.1:3555/"

echo "[+] waiting for docker container to be ready"
echo "[+] check $ENDPOINT for the status"

COUNT=0
while true; do
    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" $ENDPOINT)
    if [ $STATUS_CODE -eq 200 ]; then
        echo "[+] docker container is ready"
        break
    fi
    echo "[i] docker container is not ready $STATUS_CODE, retry in 10s"
    sleep 10
    COUNT=$((COUNT+1))
    if [ $COUNT -eq 180 ]; then
        echo "[!] docker container is not ready after 30 min, exit"
        exit 1
    fi
done