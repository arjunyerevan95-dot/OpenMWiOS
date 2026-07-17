#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

VCPKG_TRIPLET="${VCPKG_TRIPLET:-arm64-ios-openmw-release}"
CONFIGURATION="${CONFIGURATION:-Release}"
PREFIX="${BUILD_DIR}/prefix/${VCPKG_TRIPLET}"
VCPKG_PREFIX="${BUILD_DIR}/vcpkg_installed/${VCPKG_TRIPLET}"
TEMPLATE_PRODUCT_MANIFEST="${BUILD_DIR}/ios/generated/ios-archive-products-${CONFIGURATION}.tsv"
RESOLVED_PRODUCT_MANIFEST="${BUILD_DIR}/ios/generated/ios-archive-products-${CONFIGURATION}.resolved.tsv"

required_files=(
    "${PREFIX}/lib/libGL.a"
    "${PREFIX}/lib/libluajit-5.1.a"
    "${PREFIX}/include/gl4es/gl4eshint.h"
    "${PREFIX}/include/gl4es/gl4esinit.h"
    "${VCPKG_PREFIX}/include/boost/geometry/geometries/box.hpp"
    "${VCPKG_PREFIX}/lib/libSDL2.a"
    "${VCPKG_PREFIX}/lib/libSDL2main.a"
    "${VCPKG_PREFIX}/lib/libboost_iostreams.a"
    "${VCPKG_PREFIX}/lib/libboost_program_options.a"
    "${VCPKG_PREFIX}/lib/libavcodec.a"
    "${VCPKG_PREFIX}/lib/libavformat.a"
    "${VCPKG_PREFIX}/lib/libavutil.a"
    "${VCPKG_PREFIX}/lib/libswresample.a"
    "${VCPKG_PREFIX}/lib/libswscale.a"
    "${VCPKG_PREFIX}/lib/libfreetype.a"
    "${VCPKG_PREFIX}/lib/libicudata.a"
    "${VCPKG_PREFIX}/lib/libicui18n.a"
    "${VCPKG_PREFIX}/lib/libicuuc.a"
    "${VCPKG_PREFIX}/lib/libpng16.a"
    "${VCPKG_PREFIX}/lib/libjpeg.a"
    "${VCPKG_PREFIX}/lib/liblz4.a"
    "${VCPKG_PREFIX}/lib/libopenal.a"
    "${VCPKG_PREFIX}/lib/libyaml-cpp.a"
    "${VCPKG_PREFIX}/lib/libz.a"
    "${TEMPLATE_PRODUCT_MANIFEST}"
)

REGISTRAR_INVENTORY="${BUILD_DIR}/ios/required-osg-plugins-${CONFIGURATION}.txt"
GENERATED_REGISTRATION_HEADER="${BUILD_DIR}/ios/generated/openmw_ios_osg_plugins.hpp"
required_files+=("${REGISTRAR_INVENTORY}" "${GENERATED_REGISTRATION_HEADER}")
if [[ -f "${REGISTRAR_INVENTORY}" ]]; then
    while IFS='|' read -r plugin_target registrar_symbol plugin_archive; do
        [[ -n "${plugin_target}" && -n "${registrar_symbol}" && -n "${plugin_archive}" ]] || continue
        required_files+=("${plugin_archive}")
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
if [[ -f "${TEMPLATE_PRODUCT_MANIFEST}" ]]; then
    cp "${TEMPLATE_PRODUCT_MANIFEST}" \
        "${BUILD_DIR}/diagnostics/ios-archive-products-${CONFIGURATION}.template.tsv"
    if [[ -z "${EFFECTIVE_PLATFORM_NAME:-}" ]]; then
        echo "error: EFFECTIVE_PLATFORM_NAME must be supplied explicitly" >&2
        exit 1
    fi
    python3 "${ROOT_DIR}/scripts/resolve-xcode-manifest.py" \
        --input "${TEMPLATE_PRODUCT_MANIFEST}" \
        --output "${RESOLVED_PRODUCT_MANIFEST}" \
        --define "EFFECTIVE_PLATFORM_NAME=${EFFECTIVE_PLATFORM_NAME}" \
        --require-existing-products \
        | tee "${BUILD_DIR}/diagnostics/ios-archive-products-${CONFIGURATION}.resolution.log"
    cp "${RESOLVED_PRODUCT_MANIFEST}" "${BUILD_DIR}/diagnostics/"
    shasum -a 256 \
        "${TEMPLATE_PRODUCT_MANIFEST}" \
        "${RESOLVED_PRODUCT_MANIFEST}" \
        > "${BUILD_DIR}/diagnostics/ios-archive-products-${CONFIGURATION}.sha256"
fi
printf 'target\texpected_symbol\tarchive\tstatus\n' > "${REGISTRAR_REPORT}"
if [[ -f "${REGISTRAR_INVENTORY}" ]]; then
    while IFS='|' read -r plugin_target registrar_symbol archive; do
        [[ -n "${plugin_target}" && -n "${registrar_symbol}" && -n "${archive}" ]] || continue
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

if ! "${ROOT_DIR}/scripts/dependency-inventory.py" \
        --manifest "${RESOLVED_PRODUCT_MANIFEST}"; then
    validation_status=1
fi

if (( validation_status != 0 )); then
    echo "error: dependency validation found one or more violations; inspect the complete inventory and registrar report" >&2
    exit "${validation_status}"
fi
echo "Dependency architecture, deployment target, archive, header, and registrar checks passed."
