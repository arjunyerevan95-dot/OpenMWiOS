#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

require_command git

mkdir -p "${DEPS_DIR}" "${BUILD_DIR}"

clone_pinned "${OPENMW_REPOSITORY}" "${OPENMW_REVISION}" "${DEPS_DIR}/openmw"
clone_pinned "${GL4ES_REPOSITORY}" "${GL4ES_REVISION}" "${DEPS_DIR}/gl4es"
clone_pinned "${IOS_CMAKE_REPOSITORY}" "${IOS_CMAKE_REVISION}" "${DEPS_DIR}/ios-cmake"
clone_pinned "${VCPKG_REPOSITORY}" "${VCPKG_REVISION}" "${DEPS_DIR}/vcpkg-pinned"

PATCH_MARKER="${DEPS_DIR}/openmw/.openmw-ios-patched"
if [[ ! -f "${PATCH_MARKER}" ]]; then
    if grep -q 'option(OPENMW_IOS' "${DEPS_DIR}/openmw/CMakeLists.txt"; then
        echo "OpenMW iOS patch series is already present."
    else
        for patch_file in "${ROOT_DIR}"/patches/openmw/*.patch; do
            git -C "${DEPS_DIR}/openmw" apply --check "${patch_file}"
            git -C "${DEPS_DIR}/openmw" apply "${patch_file}"
        done
    fi
    touch "${PATCH_MARKER}"
fi

mkdir -p "${DEPS_DIR}/openmw/ios"
cp -R "${ROOT_DIR}/ios/." "${DEPS_DIR}/openmw/ios/"

echo "Bootstrap complete. Run ./scripts/build-ios.sh on a Mac with Xcode."
