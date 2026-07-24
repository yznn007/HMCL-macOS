#!/bin/bash

set -euo pipefail

CHANNEL="stable"
ARCH="universal"
OUTPUT_DIR="dist"
DOWNLOAD_DIR="downloads"

usage() {
  printf 'Usage: %s [--channel stable] [--arch aarch64|x64|universal] [--output-dir DIR] [--download-dir DIR]\n' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --channel)
      if [ "$#" -lt 2 ]; then
        usage
        exit 1
      fi
      CHANNEL="$2"
      shift
      ;;
    --arch)
      if [ "$#" -lt 2 ]; then
        usage
        exit 1
      fi
      ARCH="$2"
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
    --download-dir)
      if [ "$#" -lt 2 ]; then
        usage
        exit 1
      fi
      DOWNLOAD_DIR="$2"
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

case "$ARCH" in
  aarch64|x64|universal)
    ;;
  *)
    printf 'Error: unsupported arch: %s\n' "$ARCH" >&2
    usage
    exit 1
    ;;
esac

DOWNLOAD_OUTPUT="$("./scripts/download-hmcl-channel.sh" --channel "$CHANNEL" --output-dir "$DOWNLOAD_DIR")"
printf '%s\n' "$DOWNLOAD_OUTPUT"

HMCL_JAR="$(printf '%s\n' "$DOWNLOAD_OUTPUT" | awk -F= '/^HMCL_JAR=/{print $2}')"
HMCL_TAG="$(printf '%s\n' "$DOWNLOAD_OUTPUT" | awk -F= '/^HMCL_TAG=/{print $2}')"

if [ -z "$HMCL_JAR" ] || [ -z "$HMCL_TAG" ]; then
  printf 'Error: failed to resolve HMCL jar or tag from download output\n' >&2
  exit 1
fi

"./scripts/build-hmcl-app.sh" "$HMCL_JAR" --version "$HMCL_TAG" --arch "$ARCH" --output-dir "$OUTPUT_DIR"
printf '%s\n' "$ARCH" > "$OUTPUT_DIR/HMCL.app/Contents/Resources/HMCL.arch"
"./scripts/create-dmg.sh" --app "$OUTPUT_DIR/HMCL.app" --version "$ARCH-$HMCL_TAG" --output-dir "$OUTPUT_DIR"
