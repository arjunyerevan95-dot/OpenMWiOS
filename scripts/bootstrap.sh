#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

require_command git

mkdir -p "${DEPS_DIR}" "${BUILD_DIR}"

patch_fingerprint() {
    local revision="$1"
    local patch_directory="$2"
    {
        printf '%s\n' "${revision}"
        shasum -a 256 "${patch_directory}"/*.patch
    } | shasum -a 256 | awk '{print $1}'
}

clone_pinned "${OPENMW_REPOSITORY}" "${OPENMW_REVISION}" "${DEPS_DIR}/openmw"
clone_pinned "${GL4ES_REPOSITORY}" "${GL4ES_REVISION}" "${DEPS_DIR}/gl4es"
clone_pinned "${IOS_CMAKE_REPOSITORY}" "${IOS_CMAKE_REVISION}" "${DEPS_DIR}/ios-cmake"
clone_pinned "${VCPKG_REPOSITORY}" "${VCPKG_REVISION}" "${DEPS_DIR}/vcpkg-pinned"
clone_pinned "${LUAJIT_REPOSITORY}" "${LUAJIT_REVISION}" "${DEPS_DIR}/luajit"

GL4ES_PATCH_MARKER="${DEPS_DIR}/gl4es/.openmw-ios-patched"
GL4ES_PATCH_FINGERPRINT="$(patch_fingerprint "${GL4ES_REVISION}" "${ROOT_DIR}/patches/gl4es")"
if [[ -f "${GL4ES_PATCH_MARKER}" && "$(<"${GL4ES_PATCH_MARKER}")" != "${GL4ES_PATCH_FINGERPRINT}" ]]; then
    if [[ "${OPENMW_REFRESH_PATCHES:-0}" == "1" ]]; then
        git -C "${DEPS_DIR}/gl4es" reset --hard "${GL4ES_REVISION}"
        rm -f "${GL4ES_PATCH_MARKER}"
    else
        echo "error: GL4ES patch fingerprint changed; remove deps/gl4es and rerun bootstrap" >&2
        exit 1
    fi
fi
if [[ ! -f "${GL4ES_PATCH_MARKER}" ]]; then
    for patch_file in "${ROOT_DIR}"/patches/gl4es/*.patch; do
        git -C "${DEPS_DIR}/gl4es" apply --check "${patch_file}"
        git -C "${DEPS_DIR}/gl4es" apply "${patch_file}"
    done
    printf '%s\n' "${GL4ES_PATCH_FINGERPRINT}" > "${GL4ES_PATCH_MARKER}"
fi

PATCH_MARKER="${DEPS_DIR}/openmw/.openmw-ios-patched"
PATCH_FINGERPRINT="$(patch_fingerprint "${OPENMW_REVISION}" "${ROOT_DIR}/patches/openmw")"
if [[ -f "${PATCH_MARKER}" && "$(<"${PATCH_MARKER}")" != "${PATCH_FINGERPRINT}" ]]; then
    if [[ "${OPENMW_REFRESH_PATCHES:-0}" == "1" ]]; then
        git -C "${DEPS_DIR}/openmw" reset --hard "${OPENMW_REVISION}"
        rm -f "${PATCH_MARKER}"
    else
        echo "error: OpenMW patch fingerprint changed; remove deps/openmw and rerun bootstrap" >&2
        exit 1
    fi
fi
if [[ ! -f "${PATCH_MARKER}" ]]; then
    for patch_file in "${ROOT_DIR}"/patches/openmw/*.patch; do
        git -C "${DEPS_DIR}/openmw" apply --check "${patch_file}"
        git -C "${DEPS_DIR}/openmw" apply "${patch_file}"
    done
    printf '%s\n' "${PATCH_FINGERPRINT}" > "${PATCH_MARKER}"
fi

mkdir -p "${DEPS_DIR}/openmw/ios"
cp -R "${ROOT_DIR}/ios/." "${DEPS_DIR}/openmw/ios/"

echo "Bootstrap complete. Run ./scripts/build-ios.sh on a Mac with Xcode."
