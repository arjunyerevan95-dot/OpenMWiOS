#!/usr/bin/env bash

set -uo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
set +e

report="${BUILD_DIR}/diagnostics/cheap-validation.tsv"
validation_status=0
mkdir -p "$(dirname "${report}")"
printf 'check\tstatus\n' > "${report}"

record_result() {
    local label="$1"
    local status="$2"

    printf '%s\t%s\n' "${label}" "${status}" >> "${report}"
    printf '[%s] %s\n' "${status}" "${label}"
    if [[ "${status}" != "pass" ]]; then
        validation_status=1
    fi
}

run_check() {
    local label="$1"
    shift

    if "$@"; then
        record_result "${label}" pass
    else
        record_result "${label}" fail
    fi
}

for command_name in git cmake shellcheck python3 plutil ruby tar find mktemp; do
    run_check "command:${command_name}" command -v "${command_name}"
done

if command -v cmake >/dev/null 2>&1; then
    actual_cmake_version="$(cmake --version | awk 'NR == 1 { print $3 }')"
    if [[ "${actual_cmake_version}" == "${CMAKE_VERSION}" ]]; then
        record_result "tool-version:cmake-${CMAKE_VERSION}" pass
    else
        echo "error: CMake ${actual_cmake_version} is active, expected pinned ${CMAKE_VERSION}" >&2
        record_result "tool-version:cmake-${CMAKE_VERSION}" fail
    fi
fi

if command -v shellcheck >/dev/null 2>&1; then
    actual_shellcheck_version="$(shellcheck --version | awk '/^version:/ { print $2 }')"
    if [[ "${actual_shellcheck_version}" == "${SHELLCHECK_VERSION}" ]]; then
        record_result "tool-version:shellcheck-${SHELLCHECK_VERSION}" pass
    else
        echo "error: ShellCheck ${actual_shellcheck_version} is active, expected pinned ${SHELLCHECK_VERSION}" >&2
        record_result "tool-version:shellcheck-${SHELLCHECK_VERSION}" fail
    fi
fi

shell_syntax_status=0
for script in "${ROOT_DIR}"/scripts/*.sh; do
    bash -n "${script}" || shell_syntax_status=1
done
if (( shell_syntax_status == 0 )); then
    record_result "shell:bash-syntax-all" pass
else
    record_result "shell:bash-syntax-all" fail
fi

if command -v shellcheck >/dev/null 2>&1; then
    run_check "shell:shellcheck-all" shellcheck "${ROOT_DIR}"/scripts/*.sh
fi

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
mkdir -p "${tmp}/openmw" "${tmp}/gl4es" "${tmp}/pycache"

python_syntax_status=0
while IFS= read -r -d '' python_file; do
    PYTHONPYCACHEPREFIX="${tmp}/pycache" python3 -m py_compile "${python_file}" || python_syntax_status=1
done < <(find "${ROOT_DIR}/scripts" "${ROOT_DIR}/validation" -type f -name '*.py' -print0)
if (( python_syntax_status == 0 )); then
    record_result "python:syntax-all" pass
else
    record_result "python:syntax-all" fail
fi

run_check "python:regression-tests" \
    python3 -m unittest discover -s "${ROOT_DIR}/validation" -p 'test_*.py'
run_check "data:vcpkg-json" python3 -m json.tool "${ROOT_DIR}/vcpkg.json"
run_check "data:info-plist" plutil -lint "${ROOT_DIR}/ios/Info.plist.in"
run_check "data:workflow-yaml" ruby -e \
    'require "yaml"; YAML.parse_file(ARGV.fetch(0))' "${ROOT_DIR}/.github/workflows/ios.yml"

openmw_snapshot_ready=0
if git -C "${DEPS_DIR}/openmw" archive HEAD | tar -x -C "${tmp}/openmw"; then
    record_result "source-snapshot:openmw" pass
    openmw_snapshot_ready=1
else
    record_result "source-snapshot:openmw" fail
fi
gl4es_snapshot_ready=0
if git -C "${DEPS_DIR}/gl4es" archive HEAD | tar -x -C "${tmp}/gl4es"; then
    record_result "source-snapshot:gl4es" pass
    gl4es_snapshot_ready=1
else
    record_result "source-snapshot:gl4es" fail
fi

if (( openmw_snapshot_ready == 1 )); then
    for patch_file in "${ROOT_DIR}"/patches/openmw/*.patch; do
        patch_name="$(basename "${patch_file}")"
        if git -C "${tmp}/openmw" apply --check "${patch_file}" &&
                git -C "${tmp}/openmw" apply "${patch_file}"; then
            record_result "patch:openmw:${patch_name}" pass
        else
            record_result "patch:openmw:${patch_name}" fail
        fi
    done
fi
if (( gl4es_snapshot_ready == 1 )); then
    for patch_file in "${ROOT_DIR}"/patches/gl4es/*.patch; do
        patch_name="$(basename "${patch_file}")"
        if git -C "${tmp}/gl4es" apply --check "${patch_file}" &&
                git -C "${tmp}/gl4es" apply "${patch_file}"; then
            record_result "patch:gl4es:${patch_name}" pass
        else
            record_result "patch:gl4es:${patch_name}" fail
        fi
    done
fi

while IFS='|' read -r dependency_name dependency_path expected_revision; do
    if [[ "$(git -C "${dependency_path}" rev-parse HEAD 2>/dev/null)" == "${expected_revision}" ]]; then
        record_result "revision:${dependency_name}" pass
    else
        echo "error: ${dependency_name} is not at pinned revision ${expected_revision}" >&2
        record_result "revision:${dependency_name}" fail
    fi
done <<EOF
openmw|${DEPS_DIR}/openmw|${OPENMW_REVISION}
gl4es|${DEPS_DIR}/gl4es|${GL4ES_REVISION}
ios-cmake|${DEPS_DIR}/ios-cmake|${IOS_CMAKE_REVISION}
vcpkg|${DEPS_DIR}/vcpkg-pinned|${VCPKG_REVISION}
luajit|${DEPS_DIR}/luajit|${LUAJIT_REVISION}
EOF

if (( validation_status != 0 )); then
    echo "error: one or more cheap validations failed; see ${report}" >&2
    exit "${validation_status}"
fi

echo "All aggregated source, patch, tool, shell, Python, YAML, JSON, and plist validation passed."
