#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPOSITORY_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
APP_NAME="${FOCENDA_APP_NAME:-Focenda Staging}"
PRODUCT_NAME="FocendaApp"
BUNDLE_IDENTIFIER="${FOCENDA_BUNDLE_IDENTIFIER:-com.oomestre.focenda.staging}"
VERSION_FILE="$REPOSITORY_ROOT/VERSION"
ENTITLEMENTS_FILE="$REPOSITORY_ROOT/Resources/Focenda.entitlements"
BUILD_CONFIGURATION="${FOCENDA_BUILD_CONFIGURATION:-release}"
RELEASE_TAG="${FOCENDA_RELEASE_TAG:-}"
SIGNING_IDENTITY="${FOCENDA_SIGNING_IDENTITY:--}"
DIST_DIRECTORY="$REPOSITORY_ROOT/dist"
APP_BUNDLE="$DIST_DIRECTORY/$APP_NAME.app"

fail() {
  echo "Focenda staging build failed: $*" >&2
  exit 1
}

command -v swift >/dev/null 2>&1 || fail "Swift is not installed or is not on PATH."
if [ "${FOCENDA_NO_OPEN:-0}" != "1" ]; then
  command -v open >/dev/null 2>&1 || fail "The macOS open command is not available."
fi

[ "$(uname -s)" = "Darwin" ] || fail "staging builds require macOS (Darwin)."
[ -f "$REPOSITORY_ROOT/Package.swift" ] || fail "Package.swift was not found at $REPOSITORY_ROOT."
[ -f "$VERSION_FILE" ] || fail "VERSION was not found at $VERSION_FILE."
[ -f "$ENTITLEMENTS_FILE" ] || fail "Focenda entitlements were not found at $ENTITLEMENTS_FILE."
command -v codesign >/dev/null 2>&1 || fail "The macOS codesign tool is not available."

VERSION=$(sed -n "1p" "$VERSION_FILE")
if ! printf "%s\n" "$VERSION" | grep -Eq "^[0-9]+\.[0-9]+\.[0-9]+$"; then
  fail "VERSION must contain MAJOR.MINOR.PATCH."
fi

if [ -n "$RELEASE_TAG" ] && ! printf "%s\n" "$RELEASE_TAG" | grep -Eq "^v?[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$"; then
  fail "FOCENDA_RELEASE_TAG must contain a valid release tag."
fi

case "$BUILD_CONFIGURATION" in
  debug|release) ;;
  *) fail "FOCENDA_BUILD_CONFIGURATION must be debug or release." ;;
esac

cd "$REPOSITORY_ROOT"

echo "Validating Focenda Core tests ($BUILD_CONFIGURATION)..."
swift test --configuration "$BUILD_CONFIGURATION"

echo "Building $APP_NAME ($BUILD_CONFIGURATION)..."
swift build --configuration "$BUILD_CONFIGURATION" --product "$PRODUCT_NAME"

BIN_DIRECTORY=$(swift build --configuration "$BUILD_CONFIGURATION" --show-bin-path)
APP_EXECUTABLE="$BIN_DIRECTORY/$PRODUCT_NAME"
[ -x "$APP_EXECUTABLE" ] || fail "Swift built successfully, but $APP_EXECUTABLE was not found."

mkdir -p "$DIST_DIRECTORY"
rm -rf "$APP_BUNDLE"

TEMP_DIRECTORY=$(mktemp -d "${TMPDIR:-/tmp}/focenda-staging.XXXXXX")
TEMP_APP="$TEMP_DIRECTORY/$APP_NAME.app"
cleanup() {
  rm -rf "$TEMP_DIRECTORY"
}
trap cleanup EXIT INT TERM

mkdir -p "$TEMP_APP/Contents/MacOS" "$TEMP_APP/Contents/Resources"
install -m 755 "$APP_EXECUTABLE" "$TEMP_APP/Contents/MacOS/$PRODUCT_NAME"

if [ -f "$REPOSITORY_ROOT/Resources/AppIcon.icns" ]; then
  cp "$REPOSITORY_ROOT/Resources/AppIcon.icns" "$TEMP_APP/Contents/Resources/AppIcon.icns"
fi

if [ -f "$REPOSITORY_ROOT/Resources/focenda-mascot.png" ]; then
  cp "$REPOSITORY_ROOT/Resources/focenda-mascot.png" "$TEMP_APP/Contents/Resources/focenda-mascot.png"
fi

if [ -f "$REPOSITORY_ROOT/Resources/focenda-icon.png" ]; then
  cp "$REPOSITORY_ROOT/Resources/focenda-icon.png" "$TEMP_APP/Contents/Resources/focenda-icon.png"
fi

cat > "$TEMP_APP/Contents/Info.plist" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$PRODUCT_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_IDENTIFIER</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>FocendaReleaseTag</key>
  <string>$RELEASE_TAG</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.productivity</string>
</dict>
</plist>
PLIST_EOF

# Sign every generated bundle with the Focenda entitlements and hardened runtime.
# A Developer ID identity should be supplied for distributable builds through
# FOCENDA_SIGNING_IDENTITY; ad-hoc signing remains useful for local staging.
if [ "$SIGNING_IDENTITY" = "-" ]; then
  codesign --force --options runtime --entitlements "$ENTITLEMENTS_FILE" --sign - "$TEMP_APP"
else
  codesign --force --options runtime --timestamp --entitlements "$ENTITLEMENTS_FILE" --sign "$SIGNING_IDENTITY" "$TEMP_APP"
fi
codesign --verify --deep --strict "$TEMP_APP"

mv "$TEMP_APP" "$APP_BUNDLE"

echo "========================================"
echo "✅ Created $APP_BUNDLE"
if [ "${FOCENDA_NO_OPEN:-0}" != "1" ]; then
  echo "🚀 Launching $APP_NAME..."
  echo "========================================"
  open "$APP_BUNDLE"
else
  echo "========================================"
fi
