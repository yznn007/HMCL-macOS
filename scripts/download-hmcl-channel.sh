#!/bin/bash

set -euo pipefail

CHANNEL="stable"
OUTPUT_DIR="downloads"
REPO="HMCL-dev/HMCL"
API_ROOT="https://api.github.com"

usage() {
  printf 'Usage: %s [--channel stable|dev] [--output-dir DIR] [--repo OWNER/REPO]\n' "$0"
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
    --output-dir)
      if [ "$#" -lt 2 ]; then
        usage
        exit 1
      fi
      OUTPUT_DIR="$2"
      shift
      ;;
    --repo)
      if [ "$#" -lt 2 ]; then
        usage
        exit 1
      fi
      REPO="$2"
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

case "$CHANNEL" in
  stable|dev)
    ;;
  *)
    printf 'Error: unsupported channel: %s\n' "$CHANNEL" >&2
    usage
    exit 1
    ;;
esac

mkdir -p "$OUTPUT_DIR"

RELEASES_JSON="$(mktemp)"
PAGE_JSON="$(mktemp)"
trap 'rm -f "$RELEASES_JSON" "$PAGE_JSON"' EXIT

CURL_HEADERS=(
  -H "Accept: application/vnd.github+json"
  -H "X-GitHub-Api-Version: 2022-11-28"
  -H "User-Agent: hmcl-macos"
)

if [ -n "${GITHUB_TOKEN:-}" ]; then
  CURL_HEADERS+=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

: > "$RELEASES_JSON"

for page in 1 2 3 4 5; do
  if ! curl -fsSL "${CURL_HEADERS[@]}" \
    "$API_ROOT/repos/$REPO/releases?per_page=100&page=$page" \
    -o "$PAGE_JSON"; then
    printf 'Error: failed to fetch GitHub releases for %s.\n' "$REPO" >&2
    printf 'If you are running locally and hit GitHub rate limits, set GITHUB_TOKEN and retry.\n' >&2
    exit 1
  fi

  python3 - "$RELEASES_JSON" "$PAGE_JSON" <<'PY'
import json
import sys

target, page = sys.argv[1], sys.argv[2]

try:
    with open(target, "r", encoding="utf-8") as file:
        existing = json.load(file)
except Exception:
    existing = []

with open(page, "r", encoding="utf-8") as file:
    current = json.load(file)

if not isinstance(current, list):
    raise SystemExit("GitHub releases API did not return a list")

existing.extend(current)

with open(target, "w", encoding="utf-8") as file:
    json.dump(existing, file)
PY

  count="$(python3 - "$PAGE_JSON" <<'PY'
import json, sys
print(len(json.load(open(sys.argv[1], encoding="utf-8"))))
PY
)"
  if [ "$count" -lt 100 ]; then
    break
  fi
done

ASSET_INFO="$(python3 - "$RELEASES_JSON" "$CHANNEL" "$OUTPUT_DIR" <<'PY'
import json
import os
import re
import shlex
import sys

releases_path, channel, output_dir = sys.argv[1], sys.argv[2], sys.argv[3]

with open(releases_path, "r", encoding="utf-8") as file:
    releases = json.load(file)

if not isinstance(releases, list):
    raise SystemExit("GitHub releases API did not return a release list")

def version_tuple(tag):
    text = tag[1:] if tag.startswith("v") else tag
    parts = []
    for item in text.split("."):
        try:
            parts.append(int(item))
        except ValueError:
            parts.append(-1)
    return tuple(parts)

def release_matches(release, channel):
    if release.get("draft"):
        return False
    prerelease = bool(release.get("prerelease"))
    if channel == "stable":
        return not prerelease
    if channel == "dev":
        return prerelease
    return False

def find_jar_asset(release):
    tag = release.get("tag_name", "")
    version = tag[1:] if tag.startswith("v") else tag
    expected = f"HMCL-{version}.jar"
    assets = release.get("assets", [])
    for asset in assets:
        if asset.get("name") == expected:
            return asset
    for asset in assets:
        name = asset.get("name", "")
        if re.fullmatch(r"HMCL-[0-9][0-9A-Za-z_.-]*\.jar", name):
            return asset
    return None

release = None
asset = None
for candidate in releases:
    if not release_matches(candidate, channel):
        continue
    candidate_asset = find_jar_asset(candidate)
    if candidate_asset:
        release = candidate
        asset = candidate_asset
        break

if not release or not asset:
    raise SystemExit(f"No jar asset found for channel: {channel}")

tag = release["tag_name"]
version = tag[1:] if tag.startswith("v") else tag
asset_name = asset["name"]
download_url = asset["browser_download_url"]
output_path = os.path.join(output_dir, asset_name)

sha256 = ""
body = release.get("body") or ""
pattern = re.compile(rf"{re.escape(asset_name)}.*?`?([a-fA-F0-9]{{64}})`?", re.IGNORECASE)
match = pattern.search(body)
if match:
    sha256 = match.group(1).lower()

print(f"HMCL_CHANNEL={shlex.quote(channel)}")
print(f"HMCL_VERSION={shlex.quote(version)}")
print(f"HMCL_TAG={shlex.quote(tag)}")
print(f"HMCL_ASSET_NAME={shlex.quote(asset_name)}")
print(f"HMCL_DOWNLOAD_URL={shlex.quote(download_url)}")
print(f"HMCL_SHA256={shlex.quote(sha256)}")
print(f"HMCL_JAR={shlex.quote(output_path)}")
PY
)"

eval "$ASSET_INFO"

if [ -f "$HMCL_JAR" ] && [ -n "$HMCL_SHA256" ]; then
  EXISTING_SHA256="$(shasum -a 256 "$HMCL_JAR" | awk '{print $1}')"
  if [ "$EXISTING_SHA256" != "$HMCL_SHA256" ]; then
    rm "$HMCL_JAR"
  fi
fi

if [ ! -f "$HMCL_JAR" ]; then
  curl -fL "${CURL_HEADERS[@]}" \
    "$HMCL_DOWNLOAD_URL" \
    -o "$HMCL_JAR"
fi

if [ -n "$HMCL_SHA256" ]; then
  ACTUAL_SHA256="$(shasum -a 256 "$HMCL_JAR" | awk '{print $1}')"
  if [ "$ACTUAL_SHA256" != "$HMCL_SHA256" ]; then
    printf 'Error: SHA-256 mismatch for %s\n' "$HMCL_JAR" >&2
    printf 'Expected: %s\n' "$HMCL_SHA256" >&2
    printf 'Actual:   %s\n' "$ACTUAL_SHA256" >&2
    exit 1
  fi
else
  printf 'Warning: no SHA-256 checksum found in upstream release notes for %s\n' "$HMCL_ASSET_NAME" >&2
fi

printf 'HMCL_CHANNEL=%s\n' "$HMCL_CHANNEL"
printf 'HMCL_VERSION=%s\n' "$HMCL_VERSION"
printf 'HMCL_TAG=%s\n' "$HMCL_TAG"
printf 'HMCL_ASSET_NAME=%s\n' "$HMCL_ASSET_NAME"
printf 'HMCL_JAR=%s\n' "$HMCL_JAR"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    printf 'channel=%s\n' "$HMCL_CHANNEL"
    printf 'version=%s\n' "$HMCL_VERSION"
    printf 'tag=%s\n' "$HMCL_TAG"
    printf 'asset_name=%s\n' "$HMCL_ASSET_NAME"
    printf 'jar=%s\n' "$HMCL_JAR"
  } >> "$GITHUB_OUTPUT"
fi
