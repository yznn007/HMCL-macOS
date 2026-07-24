#!/bin/bash

set -euo pipefail

APP_PATH=""
DMG_PATH=""
IDENTITY="${HMCL_CODESIGN_IDENTITY:-}"
NOTARY_PROFILE="${HMCL_NOTARY_PROFILE:-}"

usage() {
  printf 'Usage: %s --app PATH --dmg PATH --identity "Developer ID Application: ..." [--notary-profile PROFILE]\n' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --app)
      APP_PATH="$2"
      shift
      ;;
    --dmg)
      DMG_PATH="$2"
      shift
      ;;
    --identity)
      IDENTITY="$2"
      shift
      ;;
    --notary-profile)
      NOTARY_PROFILE="$2"
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

if [ -z "$APP_PATH" ] || [ -z "$DMG_PATH" ] || [ -z "$IDENTITY" ]; then
  usage
  exit 1
fi

if [ ! -d "$APP_PATH" ]; then
  printf 'Error: app not found: %s\n' "$APP_PATH" >&2
  exit 1
fi

codesign --force --deep --options runtime --timestamp --sign "$IDENTITY" "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

if [ -f "$DMG_PATH" ]; then
  codesign --force --timestamp --sign "$IDENTITY" "$DMG_PATH"
fi

if [ -n "$NOTARY_PROFILE" ]; then
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
fi

printf 'Signed: %s\n' "$APP_PATH"
if [ -n "$NOTARY_PROFILE" ]; then
  printf 'Notarized and stapled: %s\n' "$DMG_PATH"
fi
