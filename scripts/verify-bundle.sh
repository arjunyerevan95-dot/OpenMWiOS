#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

APP_PATH="$1"
LINKER_COMMAND_FILE="${2:-}"
INFO_PLIST="${APP_PATH}/Info.plist"
validation_status=0
EXECUTABLE_NAME=""

while IFS= read -r -d '' top_level_entry; do
    top_level_name="$(basename "${top_level_entry}")"
    folded_name="$(printf '%s' "${top_level_name}" | LC_ALL=C tr '[:upper:]' '[:lower:]')"
    if [[ "${folded_name}" == "resources" ]]; then
        echo "ERROR: top-level \"resources\" collides case-insensitively with Apple's reserved/conventional \"Resources\" bundle directory" >&2
        validation_status=1
    fi
done < <(find "${APP_PATH}" -mindepth 1 -maxdepth 1 -print0)

if [[ ! -f "${INFO_PLIST}" ]]; then
    echo "error: app bundle is missing Info.plist" >&2
    validation_status=1
else
    if ! plutil -lint "${INFO_PLIST}" >/dev/null; then
        echo "error: app bundle Info.plist is invalid" >&2
        validation_status=1
    fi
    EXECUTABLE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "${INFO_PLIST}" 2>/dev/null || true)"
    if [[ -z "${EXECUTABLE_NAME}" ]]; then
        echo "error: app bundle Info.plist has no CFBundleExecutable" >&2
        validation_status=1
    fi
    bundle_identifier="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${INFO_PLIST}" 2>/dev/null || true)"
    if [[ "${bundle_identifier}" != "${PRODUCT_BUNDLE_IDENTIFIER:-org.openmw.ios}" ]]; then
        echo "error: unexpected bundle identifier '${bundle_identifier}'" >&2
        validation_status=1
    fi
fi

if [[ -n "${EXECUTABLE_NAME}" ]]; then
    if ! "${ROOT_DIR}/scripts/verify-linked-product.sh" \
            "${APP_PATH}/${EXECUTABLE_NAME}" "${LINKER_COMMAND_FILE}"; then
        validation_status=1
    fi
fi

for required in defaults.bin openmw.cfg gamecontrollerdb.txt openmw-resources openmw-resources/version openmw-resources/lua_libs; do
    if [[ ! -e "${APP_PATH}/${required}" ]]; then
        echo "error: app bundle is missing ${required}" >&2
        validation_status=1
    fi
done

if (( validation_status == 0 )); then
    resource_source="${BUILD_DIR}/ios/${CONFIGURATION:-Release}/resources"
    if ! python3 "${ROOT_DIR}/scripts/verify-resource-relocation.py" \
            --source "${resource_source}" \
            --staged "${APP_PATH}/openmw-resources" \
            --output-dir "${BUILD_DIR}/diagnostics/resource-relocation"; then
        validation_status=1
    fi
    if ! "${ROOT_DIR}/scripts/validate-apple-bundle.sh" "${APP_PATH}" \
            "${BUILD_DIR}/diagnostics/apple-bundle-validation" \
            "${PRODUCT_BUNDLE_IDENTIFIER:-org.openmw.ios}"; then
        validation_status=1
    fi
fi

(( validation_status == 0 )) || exit "${validation_status}"
echo "App bundle resources, plist, identifier, executable, architecture, and linkage passed."
