#!/bin/bash
set -euo pipefail

# Builds PassGenerator.app from the SwiftPM executable.
# Usage: ./build_app.sh [debug|release]   (default: release)

CONFIG="${1:-release}"
APP_NAME="PassGenerator"
BUNDLE_ID="dev.local.passgenerator"
BUILD_DIR=".build/${CONFIG}"
APP_DIR="${APP_NAME}.app"
ICON_SRC="Assets/AppIcon-source.png"
ICON_ICNS="Assets/AppIcon.icns"

build_icon() {
    [ -f "${ICON_SRC}" ] || { echo "==> No icon source, skipping icon."; return; }
    if [ -f "${ICON_ICNS}" ] && [ "${ICON_ICNS}" -nt "${ICON_SRC}" ]; then
        return
    fi
    echo "==> Building app icon..."
    local sq=".build/icon-square.png"
    local set=".build/AppIcon.iconset"
    sips -c 1024 1024 "${ICON_SRC}" --out "${sq}" >/dev/null
    rm -rf "${set}"; mkdir -p "${set}"
    for s in 16 32 128 256 512; do
        sips -z $s $s "${sq}" --out "${set}/icon_${s}x${s}.png" >/dev/null
        sips -z $((s*2)) $((s*2)) "${sq}" --out "${set}/icon_${s}x${s}@2x.png" >/dev/null
    done
    iconutil -c icns "${set}" -o "${ICON_ICNS}"
}

echo "==> Building (${CONFIG})..."
swift build -c "${CONFIG}"

echo "==> Assembling ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"

build_icon
ICON_PLIST_ENTRY=""
if [ -f "${ICON_ICNS}" ]; then
    cp "${ICON_ICNS}" "${APP_DIR}/Contents/Resources/AppIcon.icns"
    ICON_PLIST_ENTRY="    <key>CFBundleIconFile</key>
    <string>AppIcon</string>"
fi

cat > "${APP_DIR}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>Password Generator</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
${ICON_PLIST_ENTRY}
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# Ad-hoc sign so the app can run locally and request accessibility.
codesign --force --deep --sign - "${APP_DIR}" >/dev/null 2>&1 || true

echo "==> Done: ${APP_DIR}"
echo "    Run with: open ${APP_DIR}   (or ./${APP_DIR}/Contents/MacOS/${APP_NAME})"
