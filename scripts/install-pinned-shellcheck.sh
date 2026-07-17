#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

require_command curl
require_command tar

case "$(uname -s):$(uname -m)" in
    Darwin:x86_64)
        shellcheck_archive="${SHELLCHECK_DARWIN_X86_64_ARCHIVE}"
        shellcheck_url="${SHELLCHECK_DARWIN_X86_64_URL}"
        shellcheck_sha256="${SHELLCHECK_DARWIN_X86_64_SHA256}"
        ;;
    Linux:x86_64)
        shellcheck_archive="${SHELLCHECK_LINUX_X86_64_ARCHIVE}"
        shellcheck_url="${SHELLCHECK_LINUX_X86_64_URL}"
        shellcheck_sha256="${SHELLCHECK_LINUX_X86_64_SHA256}"
        ;;
    *)
        echo "error: no pinned ShellCheck binary for $(uname -s) $(uname -m)" >&2
        exit 1
        ;;
esac

download_dir="${BUILD_DIR}/tool-downloads"
archive="${download_dir}/${shellcheck_archive}"
install_root="${BUILD_DIR}/tools/shellcheck-${SHELLCHECK_VERSION}"
shellcheck_bin="${install_root}/shellcheck"
mkdir -p "${download_dir}"

if [[ ! -f "${archive}" ]]; then
    curl --fail --location --retry 3 --output "${archive}" "${shellcheck_url}"
fi
if command -v shasum >/dev/null 2>&1; then
    actual_sha256="$(shasum -a 256 "${archive}" | awk '{print $1}')"
else
    require_command sha256sum
    actual_sha256="$(sha256sum "${archive}" | awk '{print $1}')"
fi
if [[ "${actual_sha256}" != "${shellcheck_sha256}" ]]; then
    echo "error: ${shellcheck_archive} checksum ${actual_sha256}, expected ${shellcheck_sha256}" >&2
    exit 1
fi

rm -rf "${install_root}"
mkdir -p "${install_root}"
tar -xJf "${archive}" -C "${install_root}" --strip-components=1
if [[ ! -x "${shellcheck_bin}" ]]; then
    echo "error: pinned ShellCheck archive did not contain ${shellcheck_bin}" >&2
    exit 1
fi

actual_version="$("${shellcheck_bin}" --version | awk '/^version:/ { print $2 }')"
if [[ "${actual_version}" != "${SHELLCHECK_VERSION}" ]]; then
    echo "error: installed ShellCheck ${actual_version}, expected ${SHELLCHECK_VERSION}" >&2
    exit 1
fi

if [[ -n "${GITHUB_PATH:-}" ]]; then
    printf '%s\n' "${install_root}" >> "${GITHUB_PATH}"
fi
echo "Installed checksum-verified ShellCheck ${SHELLCHECK_VERSION} at ${shellcheck_bin}."
