#!/bin/bash

set -euo pipefail

APP_PATH="dist/HMCL.app"
OUTPUT_DIR="dist"
VERSION="latest"

usage() {
  printf 'Usage: %s [--app PATH] [--version VERSION] [--output-dir DIR]\n' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --app)
      if [ "$#" -lt 2 ]; then
        usage
        exit 1
      fi
      APP_PATH="$2"
      shift
      ;;
    --version)
      if [ "$#" -lt 2 ]; then
        usage
        exit 1
      fi
      VERSION="$2"
      shift
      ;;
    --output-dir)
      if [ "$#" -lt 2 ]; then
        usage
        exit 1
      fi
      OUTPUT_DIR="$2"
      shift
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

if [ ! -d "$APP_PATH" ]; then
  printf 'Error: app bundle not found: %s\n' "$APP_PATH" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

APP_NAME="$(basename "$APP_PATH" .app)"
DMG_NAME="$APP_NAME-macOS-$VERSION.dmg"
DMG_PATH="$OUTPUT_DIR/$DMG_NAME"
STAGING_DIR="$(mktemp -d)"

cleanup() {
  rm -r "$STAGING_DIR"
}
trap cleanup EXIT

cp -R "$APP_PATH" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

printf 'Created: %s\n' "$DMG_PATH"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  printf 'dmg=%s\n' "$DMG_PATH" >> "$GITHUB_OUTPUT"
fi

