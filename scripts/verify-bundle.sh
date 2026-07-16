#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

APP_PATH="$1"
INFO_PLIST="${APP_PATH}/Info.plist"
EXECUTABLE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "${INFO_PLIST}")"
EXECUTABLE="${APP_PATH}/${EXECUTABLE_NAME}"

plutil -lint "${INFO_PLIST}" >/dev/null
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${INFO_PLIST}")" \
    = "${PRODUCT_BUNDLE_IDENTIFIER:-org.openmw.ios}"
"${ROOT_DIR}/scripts/verify-linked-product.sh" "${EXECUTABLE}"

for required in defaults.bin openmw.cfg gamecontrollerdb.txt resources resources/version resources/lua_libs; do
    test -e "${APP_PATH}/${required}" || {
        echo "error: app bundle is missing ${required}" >&2
        exit 1
    }
done

echo "App bundle resources, plist, identifier, executable, architecture, and linkage passed."
