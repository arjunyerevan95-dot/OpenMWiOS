#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

VCPKG_TRIPLET="${VCPKG_TRIPLET:-arm64-ios-openmw-release}"
PREFIX="${BUILD_DIR}/prefix/${VCPKG_TRIPLET}"
VCPKG_PREFIX="${BUILD_DIR}/vcpkg_installed/${VCPKG_TRIPLET}"
OSG_LIB="${BUILD_DIR}/ios/_deps/osg-build/lib"

required_files=(
    "${PREFIX}/lib/libGL.a"
    "${PREFIX}/lib/libluajit-5.1.a"
    "${PREFIX}/include/gl4es/gl4eshint.h"
    "${PREFIX}/include/gl4es/gl4esinit.h"
    "${VCPKG_PREFIX}/include/boost/geometry/geometries/box.hpp"
    "${VCPKG_PREFIX}/lib/libSDL2.a"
    "${VCPKG_PREFIX}/lib/libboost_program_options.a"
    "${VCPKG_PREFIX}/lib/libavcodec.a"
    "${VCPKG_PREFIX}/lib/libfreetype.a"
    "${VCPKG_PREFIX}/lib/libpng16.a"
    "${VCPKG_PREFIX}/lib/libjpeg.a"
    "${VCPKG_PREFIX}/lib/libz.a"
)

REGISTRAR_INVENTORY="${BUILD_DIR}/ios/required-osg-plugins.txt"
required_files+=("${REGISTRAR_INVENTORY}")
while IFS='|' read -r plugin_target registrar_symbol; do
    [[ -n "${plugin_target}" && -n "${registrar_symbol}" ]] || continue
    required_files+=("${OSG_LIB}/lib${plugin_target}.a")
done < "${REGISTRAR_INVENTORY}"

missing=0
for required_file in "${required_files[@]}"; do
    if [[ ! -f "${required_file}" ]]; then
        echo "error: missing required dependency: ${required_file}" >&2
        missing=1
    fi
done
(( missing == 0 )) || exit 1

while IFS='|' read -r plugin_target registrar_symbol; do
    [[ -n "${plugin_target}" && -n "${registrar_symbol}" ]] || continue
    if ! xcrun nm -gU "${OSG_LIB}/lib${plugin_target}.a" \
        | grep -Eq "[[:space:]]${registrar_symbol}$"; then
        echo "error: lib${plugin_target}.a does not export ${registrar_symbol}" >&2
        exit 1
    fi
done < "${REGISTRAR_INVENTORY}"

"${ROOT_DIR}/scripts/dependency-inventory.py"
echo "Dependency architecture, deployment target, archive, header, and registrar checks passed."
