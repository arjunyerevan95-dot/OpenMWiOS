#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

require_macos
require_command curl
require_command shasum
require_command tar

download_dir="${BUILD_DIR}/tool-downloads"
archive="${download_dir}/${CMAKE_MACOS_ARCHIVE}"
install_root="${BUILD_DIR}/tools/cmake-${CMAKE_VERSION}"
cmake_bin="${install_root}/CMake.app/Contents/bin"
mkdir -p "${download_dir}"

if [[ ! -f "${archive}" ]]; then
    curl --fail --location --retry 3 --output "${archive}" "${CMAKE_MACOS_URL}"
fi
actual_sha256="$(shasum -a 256 "${archive}" | awk '{print $1}')"
if [[ "${actual_sha256}" != "${CMAKE_MACOS_SHA256}" ]]; then
    echo "error: ${CMAKE_MACOS_ARCHIVE} checksum ${actual_sha256}, expected ${CMAKE_MACOS_SHA256}" >&2
    exit 1
fi

rm -rf "${install_root}"
mkdir -p "${install_root}"
tar -xzf "${archive}" -C "${install_root}" --strip-components=1
if [[ ! -x "${cmake_bin}/cmake" ]]; then
    echo "error: pinned CMake archive did not contain ${cmake_bin}/cmake" >&2
    exit 1
fi

actual_version="$("${cmake_bin}/cmake" --version | awk 'NR == 1 { print $3 }')"
if [[ "${actual_version}" != "${CMAKE_VERSION}" ]]; then
    echo "error: installed CMake ${actual_version}, expected ${CMAKE_VERSION}" >&2
    exit 1
fi

if [[ -n "${GITHUB_PATH:-}" ]]; then
    printf '%s\n' "${cmake_bin}" >> "${GITHUB_PATH}"
else
    echo "Add ${cmake_bin} to PATH"
fi
echo "Installed checksum-verified CMake ${CMAKE_VERSION} at ${cmake_bin}."
