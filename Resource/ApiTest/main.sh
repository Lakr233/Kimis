#!/bin/zsh

# This is a test script for the API
#  Misskey Api is changed oftenly, so execute this script every time
#  before release.

# test account:
#  username: test
#  password: test

# Exit immediately if a command exits with a non-zero status.
set -e

# If any command in a pipeline fails,
# that return code will be used as the return code of the whole pipeline.
set -o pipefail

cd "$(dirname "$0")"
cd ../..

PROJECT_ROOT=$(pwd)

# check .root file ex
if [ ! -f .root ]; then
    echo "[-] malformed project structure"
    exit 1
fi

# check docker and docker-compose exists
REQUIRED_BINARIES=(docker docker-compose)
for binary in $REQUIRED_BINARIES; do
    if ! type $binary > /dev/null 2>&1; then
        echo "[-] $binary is not installed"
        exit 1
    fi
done

function cleanup {
    echo "[+] cleaning up..."

    echo "[+] stopping docker env"
    cd "$PROJECT_ROOT/"
    ./Resource/ApiTest/Docker-Env/shutdown.sh

    echo "[+] cleanup done"
}

trap cleanup EXIT

echo "[+] starting docker env"
cd "$PROJECT_ROOT/"
./Resource/ApiTest/Docker-Env/startup.sh

echo "[+] waiting for docker env to be ready"
cd "$PROJECT_ROOT/"
./Resource/ApiTest/Docker-Env/wait.sh

echo "[+] running test"

cd "$PROJECT_ROOT/"
TIMESTAMP=$(date +%s)
BUILD_DIR="$PROJECT_ROOT/.build/release/$TIMESTAMP/XcodeBuild"
DERIVED_LOCATION_TEST="$BUILD_DIR/TEST"
mkdir -p "$DERIVED_LOCATION_TEST"
XCODEBUILD_LOG_FILE_TEST="$DERIVED_LOCATION_TEST/xcodebuild.log"

echo "[*] test data directory: $DERIVED_LOCATION_TEST"
echo "[*] test with log at: $XCODEBUILD_LOG_FILE_TEST"

cd "$PROJECT_ROOT/"
cd ./Foundation/Source
swift test

echo "[+] test passed"