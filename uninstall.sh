#!/bin/bash
set -euo pipefail

# Removes PassGenerator from /Applications (and optionally local build output).
#
# Usage:
#   ./uninstall.sh          # remove the installed app only
#   ./uninstall.sh --clean  # also remove local build artifacts (.build, PassGenerator.app)

APP_NAME="PassGenerator"
BUNDLE_ID="dev.local.passgenerator"
DEST="/Applications/${APP_NAME}.app"

# 1. Quit the app if it's running.
if pgrep -x "${APP_NAME}" >/dev/null; then
    echo "==> Quitting running ${APP_NAME}..."
    osascript -e "tell application \"${APP_NAME}\" to quit" 2>/dev/null || pkill -x "${APP_NAME}" || true
    sleep 1
fi

# 2. Remove the installed bundle.
if [ -d "${DEST}" ]; then
    echo "==> Removing ${DEST}..."
    rm -rf "${DEST}"
else
    echo "==> Not installed in /Applications (nothing to remove there)."
fi

# 3. Unregister from Launch Services.
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
[ -x "${LSREGISTER}" ] && "${LSREGISTER}" -u "${DEST}" 2>/dev/null || true

# 4. Best-effort: revoke the Accessibility permission grant.
tccutil reset Accessibility "${BUNDLE_ID}" 2>/dev/null || true

# 5. Optionally clean local build artifacts in the repo.
if [ "${1:-}" = "--clean" ]; then
    echo "==> Cleaning local build artifacts..."
    rm -rf .build "${APP_NAME}.app" Assets/AppIcon.icns
fi

echo "==> Done."
