#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPOSITORY_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

APP_PATH="${1:-}"
OUTPUT_DMG="${2:-}"
VOLUME_NAME="${3:-Focenda}"

usage() {
  cat <<HELP
Usage: $(basename "$0") <path-to-app-bundle> <output-dmg-path> [volume-name]

Creates a native macOS .dmg disk image with drag-and-drop /Applications shortcut.

Arguments:
  path-to-app-bundle  Path to the .app bundle (e.g. dist/Focenda.app)
  output-dmg-path     Destination path for the .dmg file (e.g. dist/Focenda-macOS.dmg)
  volume-name         Optional disk image volume name (default: Focenda)
HELP
  exit 1
}

if [ -z "$APP_PATH" ] || [ -z "$OUTPUT_DMG" ]; then
  usage
fi

if [ "$(uname -s)" != "Darwin" ]; then
  echo "Error: DMG creation requires macOS (Darwin) and hdiutil." >&2
  exit 1
fi

command -v hdiutil >/dev/null 2>&1 || {
  echo "Error: macOS hdiutil tool is not available." >&2
  exit 1
}

if [ ! -d "$APP_PATH" ]; then
  echo "Error: App bundle not found at: $APP_PATH" >&2
  exit 1
fi

# Resolve absolute paths
APP_ABS_PATH=$(cd "$(dirname "$APP_PATH")" && pwd)/$(basename "$APP_PATH")
OUTPUT_DIR=$(mkdir -p "$(dirname "$OUTPUT_DMG")" && cd "$(dirname "$OUTPUT_DMG")" && pwd)
OUTPUT_DMG_ABS="$OUTPUT_DIR/$(basename "$OUTPUT_DMG")"

# Temporary directory for DMG layout
TEMP_DMG_DIR=$(mktemp -d "${TMPDIR:-/tmp}/focenda-dmg-staging.XXXXXX")
cleanup() {
  rm -rf "$TEMP_DMG_DIR"
}
trap cleanup EXIT INT TERM

echo "========================================"
echo "Packaging DMG: $VOLUME_NAME"
echo "  - Source: $APP_ABS_PATH"
echo "  - Target: $OUTPUT_DMG_ABS"
echo "========================================"

# Copy the app bundle into staging folder
cp -R "$APP_ABS_PATH" "$TEMP_DMG_DIR/"

# Create symlink to /Applications for standard drag-and-drop install
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# Remove target DMG if already exists
rm -f "$OUTPUT_DMG_ABS"

# Create UDZO (zlib-compressed) read-only DMG image
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$TEMP_DMG_DIR" \
  -ov \
  -format UDZO \
  "$OUTPUT_DMG_ABS"

# Verify generated disk image
hdiutil imageinfo "$OUTPUT_DMG_ABS" >/dev/null 2>&1 || {
  echo "Error: Failed to verify generated DMG at $OUTPUT_DMG_ABS" >&2
  exit 1
}

echo "DMG created successfully at: $OUTPUT_DMG_ABS"
