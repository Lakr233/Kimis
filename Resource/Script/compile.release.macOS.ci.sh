#!/bin/zsh

set -e

echo "[*] building project for release"

cd "$(dirname "$0")"/../../
WORKING_ROOT=$(pwd)
echo "[*] working root: $WORKING_ROOT"

if [ ! -f .root ]; then
    echo "[E] malformed project directory"
    exit 1
fi

TIMESTAMP=$(date +%s)
BUILD_DIR="$WORKING_ROOT/.build/release/$TIMESTAMP/XcodeBuild"

SIGNING_ENT="$WORKING_ROOT/Kimis/Kimis.entitlements"

echo "[*] build directory: $BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ============================================================================
echo "[*] building project for macOS"
DERIVED_LOCATION_MACOS="$BUILD_DIR/OSX"
mkdir -p "$DERIVED_LOCATION_MACOS"
PRODUCT_LOCATION_MACOS="$DERIVED_LOCATION_MACOS/Build/Products/Release-maccatalyst"
PRODUCT_LOCATION_APP_MACOS="$PRODUCT_LOCATION_MACOS/Kimis.app"
XCODEBUILD_LOG_FILE_MACOS="$DERIVED_LOCATION_MACOS/xcodebuild.log"
echo "[*] build with log at: $XCODEBUILD_LOG_FILE_MACOS"

xcodebuild \
    -workspace "$WORKING_ROOT/Kimis.xcworkspace" \
    -scheme Kimis \
    -configuration Release \
    -derivedDataPath "$DERIVED_LOCATION_MACOS" \
    -destination 'generic/platform=macOS' \
    CODE_SIGNING_ALLOWED=NO \
    clean build \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO" \
    GCC_GENERATE_DEBUGGING_SYMBOLS=YES STRIP_INSTALLED_PRODUCT=NO \
    COPY_PHASE_STRIP=NO UNSTRIPPED_PRODUCT=NO \
    | tee "$XCODEBUILD_LOG_FILE_MACOS" \
    | xcbeautify --is-ci --quiet

echo "[*] looking for app at $PRODUCT_LOCATION_APP_MACOS"

if [ ! -d "$PRODUCT_LOCATION_APP_MACOS" ]; then
    echo "[E] product could not be found"
    exit 1
fi

echo "[*] signing locally..."
codesign --force --deep --options runtime --sign - --entitlements "$SIGNING_ENT" "$PRODUCT_LOCATION_APP_MACOS"
echo "[*] verifying signature..."
codesign --verify --deep --strict --verbose=2 "$PRODUCT_LOCATION_APP_MACOS"

echo "[*] packaging product for macOS..."
cd "$PRODUCT_LOCATION_MACOS"
mv "Kimis.app" "$WORKING_ROOT/Kimis.app"

echo "done"