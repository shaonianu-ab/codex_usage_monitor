#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Codex Usage Monitor"
PROCESS_NAME="CodexUsageMonitor"
BUNDLE_ID="dev.example.CodexUsageMonitor"
APP_VERSION="1.0.0"
BUILD_VERSION="1"
MIN_SYSTEM_VERSION="14.0"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$PROCESS_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON="$ROOT_DIR/Assets/AppIcon/CodexUsageMonitor.icns"
SNAPSHOT_PATH="$ROOT_DIR/artifacts/usage-popover.png"
LIGHT_SNAPSHOT_PATH="$ROOT_DIR/artifacts/usage-popover-light.png"
SETTINGS_SNAPSHOT_PATH="$ROOT_DIR/artifacts/settings-popover.png"
SETTINGS_LIGHT_SNAPSHOT_PATH="$ROOT_DIR/artifacts/settings-popover-light.png"
SETTINGS_ZH_SNAPSHOT_PATH="$ROOT_DIR/artifacts/settings-popover-zh.png"
SETTINGS_LIGHT_ZH_SNAPSHOT_PATH="$ROOT_DIR/artifacts/settings-popover-light-zh.png"

pkill -x "$PROCESS_NAME" >/dev/null 2>&1 || true

swift build
BUILD_BINARY="$(swift build --show-bin-path)/$PROCESS_NAME"

if [[ ! -f "$APP_ICON" ]]; then
  echo "missing app icon: $APP_ICON" >&2
  echo "run ./script/generate_app_icon.swift Assets/AppIcon/app-icon-source.png Assets/AppIcon" >&2
  exit 1
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
cp "$APP_ICON" "$APP_RESOURCES/CodexUsageMonitor.icns"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$PROCESS_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>CodexUsageMonitor.icns</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

/usr/bin/codesign --force --sign "$CODESIGN_IDENTITY" "$APP_BUNDLE"
/usr/bin/codesign --verify --strict "$APP_BUNDLE"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$PROCESS_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -f "$APP_BINARY" >/dev/null
    ;;
  --snapshot|snapshot)
    rm -f "$SNAPSHOT_PATH"
    /usr/bin/open -n "$APP_BUNDLE" --args --render-snapshot "$SNAPSHOT_PATH"
    for _ in {1..50}; do
      [[ -f "$SNAPSHOT_PATH" ]] && exit 0
      sleep 0.1
    done
    echo "snapshot was not created: $SNAPSHOT_PATH" >&2
    exit 1
    ;;
  --snapshot-light|snapshot-light)
    rm -f "$LIGHT_SNAPSHOT_PATH"
    /usr/bin/open -n "$APP_BUNDLE" --args --render-snapshot-light "$LIGHT_SNAPSHOT_PATH"
    for _ in {1..50}; do
      [[ -f "$LIGHT_SNAPSHOT_PATH" ]] && exit 0
      sleep 0.1
    done
    echo "snapshot was not created: $LIGHT_SNAPSHOT_PATH" >&2
    exit 1
    ;;
  --snapshot-settings|snapshot-settings)
    rm -f "$SETTINGS_SNAPSHOT_PATH"
    /usr/bin/open -n "$APP_BUNDLE" --args --render-settings-snapshot "$SETTINGS_SNAPSHOT_PATH"
    for _ in {1..50}; do
      [[ -f "$SETTINGS_SNAPSHOT_PATH" ]] && exit 0
      sleep 0.1
    done
    echo "snapshot was not created: $SETTINGS_SNAPSHOT_PATH" >&2
    exit 1
    ;;
  --snapshot-settings-light|snapshot-settings-light)
    rm -f "$SETTINGS_LIGHT_SNAPSHOT_PATH"
    /usr/bin/open -n "$APP_BUNDLE" --args \
      --render-settings-snapshot-light "$SETTINGS_LIGHT_SNAPSHOT_PATH"
    for _ in {1..50}; do
      [[ -f "$SETTINGS_LIGHT_SNAPSHOT_PATH" ]] && exit 0
      sleep 0.1
    done
    echo "snapshot was not created: $SETTINGS_LIGHT_SNAPSHOT_PATH" >&2
    exit 1
    ;;
  --snapshot-settings-zh|snapshot-settings-zh)
    rm -f "$SETTINGS_ZH_SNAPSHOT_PATH"
    /usr/bin/open -n "$APP_BUNDLE" --args --render-settings-snapshot-zh "$SETTINGS_ZH_SNAPSHOT_PATH"
    for _ in {1..50}; do
      [[ -f "$SETTINGS_ZH_SNAPSHOT_PATH" ]] && exit 0
      sleep 0.1
    done
    echo "snapshot was not created: $SETTINGS_ZH_SNAPSHOT_PATH" >&2
    exit 1
    ;;
  --snapshot-settings-light-zh|snapshot-settings-light-zh)
    rm -f "$SETTINGS_LIGHT_ZH_SNAPSHOT_PATH"
    /usr/bin/open -n "$APP_BUNDLE" --args \
      --render-settings-snapshot-light-zh "$SETTINGS_LIGHT_ZH_SNAPSHOT_PATH"
    for _ in {1..50}; do
      [[ -f "$SETTINGS_LIGHT_ZH_SNAPSHOT_PATH" ]] && exit 0
      sleep 0.1
    done
    echo "snapshot was not created: $SETTINGS_LIGHT_ZH_SNAPSHOT_PATH" >&2
    exit 1
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--snapshot|--snapshot-light|--snapshot-settings|--snapshot-settings-light|--snapshot-settings-zh|--snapshot-settings-light-zh]" >&2
    exit 2
    ;;
esac
