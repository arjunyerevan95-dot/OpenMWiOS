#!/usr/bin/env bash

# This file is sourced; these shared paths are consumed by the caller scripts.
# shellcheck disable=SC2034

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPS_DIR="${ROOT_DIR}/deps"
BUILD_DIR="${ROOT_DIR}/build"

# shellcheck disable=SC1091
source "${ROOT_DIR}/versions.env"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "error: required command '$1' was not found" >&2
        exit 1
    fi
}

require_macos() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        echo "error: iOS builds require macOS and Xcode" >&2
        exit 1
    fi
}

clone_pinned() {
    local repository="$1"
    local revision="$2"
    local destination="$3"

    if [[ ! -d "${destination}/.git" ]]; then
        mkdir -p "${destination}"
        git -C "${destination}" init
        git -C "${destination}" remote add origin "${repository}"
        git -C "${destination}" fetch --depth 1 origin "${revision}"
        git -C "${destination}" checkout --detach FETCH_HEAD
        return
    fi

    git -C "${destination}" fetch --depth 1 origin "${revision}"
    if [[ "$(git -C "${destination}" rev-parse HEAD)" != "${revision}" ]]; then
        echo "error: ${destination} is not at the pinned revision ${revision}" >&2
        echo "Move the existing dependency checkout aside and rerun bootstrap." >&2
        exit 1
    fi
}
