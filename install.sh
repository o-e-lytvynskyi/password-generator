#!/bin/bash
set -euo pipefail

# Builds the app and installs/updates the copy in /Applications.
# The /Applications copy does NOT auto-update from a local rebuild, so run
# this after building when you want the installed app refreshed.
#
# Usage: ./install.sh [debug|release]   (default: release)

CONFIG="${1:-release}"
APP_NAME="PassGenerator"
SRC="${APP_NAME}.app"
DEST="/Applications/${APP_NAME}.app"

# 1. Build the .app bundle.
./build_app.sh "${CONFIG}"

# 2. If it's currently running, quit it so the binary can be replaced.
if pgrep -x "${APP_NAME}" >/dev/null; then
    echo "==> Quitting running ${APP_NAME}..."
    osascript -e "tell application \"${APP_NAME}\" to quit" 2>/dev/null || pkill -x "${APP_NAME}" || true
    sleep 1
fi

# 3. Replace the installed copy.
echo "==> Installing to ${DEST}..."
rm -rf "${DEST}"
cp -R "${SRC}" "${DEST}"

# 4. Re-sign (ad-hoc) and refresh Launch Services so Finder/Logi see the update.
codesign --force --deep --sign - "${DEST}" >/dev/null 2>&1 || true
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
[ -x "${LSREGISTER}" ] && "${LSREGISTER}" -f "${DEST}" || true

# 5. Nudge the icon cache (so the new icon shows immediately).
touch "${DEST}"

echo "==> Installed: ${DEST}"
