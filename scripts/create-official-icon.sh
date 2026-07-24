#!/bin/bash

set -euo pipefail

SOURCE="assets/icons/HMCL-official-icon-mac.png"
OUTPUT="assets/icons/AppIcon.icns"
ICONSET="assets/icons/AppIcon.iconset"
UPSTREAM_ICON_URL="https://raw.githubusercontent.com/HMCL-dev/HMCL/main/HMCL/src/main/resources/assets/img/icon-mac.png"

usage() {
  printf 'Usage: %s [--refresh]\n' "$0"
}

REFRESH="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --refresh)
      REFRESH="true"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
  shift
done

mkdir -p "$(dirname "$SOURCE")"

if [ "$REFRESH" = "true" ] || [ ! -f "$SOURCE" ]; then
  curl -fsSL "$UPSTREAM_ICON_URL" -o "$SOURCE"
fi

if [ ! -f "$SOURCE" ]; then
  printf 'Error: official icon source not found: %s\n' "$SOURCE" >&2
  exit 1
fi

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

make_png() {
  local size="$1"
  local name="$2"
  sips -s format png -z "$size" "$size" "$SOURCE" --out "$ICONSET/$name" >/dev/null
}

make_png 16 icon_16x16.png
make_png 32 icon_16x16@2x.png
make_png 32 icon_32x32.png
make_png 64 icon_32x32@2x.png
make_png 128 icon_128x128.png
make_png 256 icon_128x128@2x.png
make_png 256 icon_256x256.png
make_png 512 icon_256x256@2x.png
make_png 512 icon_512x512.png
make_png 512 icon_512x512@2x.png

iconutil -c icns "$ICONSET" -o "$OUTPUT"
rm -r "$ICONSET"

printf 'Created: %s from %s\n' "$OUTPUT" "$SOURCE"
