#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

require_command git
require_command cmake

actual_cmake_version="$(cmake --version | awk 'NR == 1 { print $3 }')"
if [[ "${actual_cmake_version}" != "${CMAKE_VERSION}" ]]; then
    echo "error: CMake ${actual_cmake_version} is active, expected pinned ${CMAKE_VERSION}" >&2
    exit 1
fi

for script in "${ROOT_DIR}"/scripts/*.sh; do
    bash -n "${script}"
done
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "${ROOT_DIR}"/scripts/*.sh
fi

python3 -m json.tool "${ROOT_DIR}/vcpkg.json" >/dev/null
python3 -m unittest discover -s "${ROOT_DIR}/validation" -p 'test_*.py'
plutil -lint "${ROOT_DIR}/ios/Info.plist.in" >/dev/null
ruby_bin="$(command -v ruby || true)"
if [[ -z "${ruby_bin}" ]] && command -v brew >/dev/null 2>&1; then
    ruby_bin="$(brew --prefix ruby)/bin/ruby"
fi
"${ruby_bin}" -e 'require "yaml"; YAML.parse_file(ARGV.fetch(0))' "${ROOT_DIR}/.github/workflows/ios.yml"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
mkdir -p "${tmp}/openmw" "${tmp}/gl4es"
git -C "${DEPS_DIR}/openmw" archive HEAD | tar -x -C "${tmp}/openmw"
git -C "${DEPS_DIR}/gl4es" archive HEAD | tar -x -C "${tmp}/gl4es"

for patch_file in "${ROOT_DIR}"/patches/openmw/*.patch; do
    git -C "${tmp}/openmw" apply --check "${patch_file}"
    git -C "${tmp}/openmw" apply "${patch_file}"
done
for patch_file in "${ROOT_DIR}"/patches/gl4es/*.patch; do
    git -C "${tmp}/gl4es" apply --check "${patch_file}"
    git -C "${tmp}/gl4es" apply "${patch_file}"
done

test "$(git -C "${DEPS_DIR}/openmw" rev-parse HEAD)" = "${OPENMW_REVISION}"
test "$(git -C "${DEPS_DIR}/gl4es" rev-parse HEAD)" = "${GL4ES_REVISION}"
test "$(git -C "${DEPS_DIR}/ios-cmake" rev-parse HEAD)" = "${IOS_CMAKE_REVISION}"
test "$(git -C "${DEPS_DIR}/vcpkg-pinned" rev-parse HEAD)" = "${VCPKG_REVISION}"
test "$(git -C "${DEPS_DIR}/luajit" rev-parse HEAD)" = "${LUAJIT_REVISION}"

echo "Source, patch, shell, YAML, JSON, and plist validation passed."
