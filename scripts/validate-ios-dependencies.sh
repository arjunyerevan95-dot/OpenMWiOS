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
GENERATED_REGISTRATION_HEADER="${BUILD_DIR}/ios/generated/openmw_ios_osg_plugins.hpp"
required_files+=("${REGISTRAR_INVENTORY}" "${GENERATED_REGISTRATION_HEADER}")
if [[ -f "${REGISTRAR_INVENTORY}" ]]; then
    while IFS='|' read -r plugin_target registrar_symbol; do
        [[ -n "${plugin_target}" && -n "${registrar_symbol}" ]] || continue
        required_files+=("${OSG_LIB}/lib${plugin_target}.a")
    done < "${REGISTRAR_INVENTORY}"
fi

validation_status=0
for required_file in "${required_files[@]}"; do
    if [[ ! -f "${required_file}" ]]; then
        echo "error: missing required dependency: ${required_file}" >&2
        validation_status=1
    fi
done

SYMBOL_DIR="${BUILD_DIR}/diagnostics/osg-registrar-symbols"
REGISTRAR_REPORT="${BUILD_DIR}/diagnostics/osg-registrar-validation.tsv"
mkdir -p "${SYMBOL_DIR}"
if [[ -f "${REGISTRAR_INVENTORY}" ]]; then
    cp "${REGISTRAR_INVENTORY}" "${BUILD_DIR}/diagnostics/required-osg-plugins.txt"
fi
if [[ -f "${GENERATED_REGISTRATION_HEADER}" ]]; then
    cp "${GENERATED_REGISTRATION_HEADER}" "${BUILD_DIR}/diagnostics/openmw_ios_osg_plugins.hpp"
fi
printf 'target\texpected_symbol\tarchive\tstatus\n' > "${REGISTRAR_REPORT}"
if [[ -f "${REGISTRAR_INVENTORY}" ]]; then
    while IFS='|' read -r plugin_target registrar_symbol; do
        [[ -n "${plugin_target}" && -n "${registrar_symbol}" ]] || continue
        archive="${OSG_LIB}/lib${plugin_target}.a"
        symbol_dump="${SYMBOL_DIR}/${plugin_target}.nm.txt"
        registrar_status="passed"
        if [[ ! -f "${archive}" ]]; then
            registrar_status="missing-archive"
            validation_status=1
        elif ! xcrun nm -gU "${archive}" > "${symbol_dump}" 2>&1; then
            echo "error: nm failed while inspecting ${archive}" >&2
            registrar_status="nm-failed"
            validation_status=1
        elif ! grep -Eq "[[:space:]]${registrar_symbol}$" "${symbol_dump}"; then
            echo "error: lib${plugin_target}.a does not export ${registrar_symbol}" >&2
            registrar_status="missing-symbol"
            validation_status=1
        fi
        printf '%s\t%s\t%s\t%s\n' \
            "${plugin_target}" "${registrar_symbol}" "${archive}" "${registrar_status}" \
            >> "${REGISTRAR_REPORT}"
    done < "${REGISTRAR_INVENTORY}"
fi

if ! "${ROOT_DIR}/scripts/dependency-inventory.py"; then
    validation_status=1
fi

if (( validation_status != 0 )); then
    echo "error: dependency validation found one or more violations; inspect the complete inventory and registrar report" >&2
    exit "${validation_status}"
fi
echo "Dependency architecture, deployment target, archive, header, and registrar checks passed."
