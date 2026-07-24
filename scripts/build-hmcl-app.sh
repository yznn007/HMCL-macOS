#!/bin/bash

set -euo pipefail

APP_NAME="HMCL"
BUNDLE_ID="io.github.yznn007.hmcl-macos"
VERSION="1.0.0"
OUTPUT_DIR="dist"
ARCH="universal"

usage() {
  printf 'Usage: %s /path/to/HMCL.jar [--version VERSION] [--arch aarch64|x64|universal] [--output-dir DIR]\n' "$0"
}

if [ "$#" -lt 1 ]; then
  usage
  exit 1
fi

SOURCE_JAR="$1"
shift

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version)
      if [ "$#" -lt 2 ]; then
        usage
        exit 1
      fi
      VERSION="$2"
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
    *)
      usage
      exit 1
      ;;
  esac
  shift
done

if [ ! -f "$SOURCE_JAR" ]; then
  printf 'Error: jar not found: %s\n' "$SOURCE_JAR" >&2
  exit 1
fi

APP_PATH="$OUTPUT_DIR/$APP_NAME.app"
CONTENTS="$APP_PATH/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
ICON_PATH="assets/icons/AppIcon.icns"

rm -rf "$APP_PATH"
mkdir -p "$MACOS" "$RESOURCES"

cp "$SOURCE_JAR" "$RESOURCES/HMCL.jar"
printf '%s\n' "$VERSION" > "$RESOURCES/HMCL.version"
printf '%s\n' "$ARCH" > "$RESOURCES/HMCL.arch"

if [ -f "$ICON_PATH" ]; then
  cp "$ICON_PATH" "$RESOURCES/AppIcon.icns"
fi

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>zh_CN</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
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
  <key>LSMinimumSystemVersion</key>
  <string>10.13</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

cat > "$MACOS/$APP_NAME" <<'LAUNCHER'
#!/bin/bash

set -e

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HMCL_JAR="$APP_DIR/Resources/HMCL.jar"
JAVA_OPTS="-Xmx2G -XX:+UseG1GC"
USER_HOME="${HOME:-}"

if [ -z "$USER_HOME" ] && [ -n "${USER:-}" ]; then
  USER_HOME="$(/usr/bin/dscl . -read "/Users/$USER" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}' || true)"
fi

APP_SUPPORT_DIR="$USER_HOME/Library/Application Support/HMCL"
CACHE_DIR="$USER_HOME/Library/Caches/HMCL"
LOG_DIR="$USER_HOME/Library/Logs/HMCL-macOS"
LOG_FILE="$LOG_DIR/hmcl-app-launcher.log"

show_error() {
  /usr/bin/osascript -e "display dialog \"$1\" buttons {\"OK\"} default button \"OK\" with icon stop" >/dev/null 2>&1 || true
}

if [ -z "$USER_HOME" ] || [ ! -d "$USER_HOME" ]; then
  show_error "The current user home directory could not be resolved."
  exit 1
fi

mkdir -p "$APP_SUPPORT_DIR" "$CACHE_DIR" "$LOG_DIR"
exec >>"$LOG_FILE" 2>&1
echo "[$(/bin/date '+%Y-%m-%d %H:%M:%S')] Starting HMCL.app"

if [ ! -f "$HMCL_JAR" ]; then
  show_error "HMCL.jar was not found inside the application bundle."
  exit 1
fi

if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ]; then
  JAVA="$JAVA_HOME/bin/java"
elif [ -x "/usr/libexec/java_home" ] && JAVA_HOME_FOUND="$(/usr/libexec/java_home 2>/dev/null)"; then
  JAVA="$JAVA_HOME_FOUND/bin/java"
else
  JAVA="$(/usr/bin/which java 2>/dev/null || true)"
fi

if [ -z "$JAVA" ] || [ ! -x "$JAVA" ]; then
  show_error "Java was not found. Please install a Java runtime first."
  exit 1
fi

cd "$USER_HOME"
exec "$JAVA" $JAVA_OPTS \
  -Duser.home="$USER_HOME" \
  -Dhmcl.dir="$APP_SUPPORT_DIR" \
  -Dhmcl.home="$APP_SUPPORT_DIR" \
  -Dhmcl.dependencies.dir="$CACHE_DIR/dependencies" \
  -jar "$HMCL_JAR"
LAUNCHER

chmod +x "$MACOS/$APP_NAME"
plutil -lint "$CONTENTS/Info.plist" >/dev/null

printf 'Built: %s\n' "$APP_PATH"
