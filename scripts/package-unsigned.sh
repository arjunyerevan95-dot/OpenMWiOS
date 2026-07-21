#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

DEVICE_DIR="${BUILD_DIR}/device"
ARTIFACT_DIR="${BUILD_DIR}/artifacts"
PAYLOAD_DIR="${ARTIFACT_DIR}/Payload"

APP_PATH="$(find "${DEVICE_DIR}" -maxdepth 1 -type d -name '*.app' -print -quit)"
if [[ -z "${APP_PATH}" ]]; then
    echo "error: no .app bundle found in ${DEVICE_DIR}" >&2
    exit 1
fi

rm -rf "${ARTIFACT_DIR}"
mkdir -p "${PAYLOAD_DIR}"
cp -R "${APP_PATH}" "${PAYLOAD_DIR}/OpenMW.app"

(
    cd "${ARTIFACT_DIR}"
    /usr/bin/zip -qry "OpenMW-iOS-unsigned.ipa" Payload
)

mv "${PAYLOAD_DIR}/OpenMW.app" "${ARTIFACT_DIR}/OpenMW.app"
rmdir "${PAYLOAD_DIR}"

echo "Created ${ARTIFACT_DIR}/OpenMW-iOS-unsigned.ipa"

