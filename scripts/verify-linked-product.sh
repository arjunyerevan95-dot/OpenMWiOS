#!/usr/bin/env bash

set -euo pipefail

binary="$1"
expected_minos="${IOS_DEPLOYMENT_TARGET:-16.3}"

test -f "${binary}" || { echo "error: linked product missing: ${binary}" >&2; exit 1; }
test "$(xcrun lipo -archs "${binary}")" = "arm64" || {
    echo "error: linked product is not arm64-only: ${binary}" >&2
    exit 1
}

minos="$(xcrun vtool -show-build "${binary}" | awk '/minos/ { print $2 }' | sort -u)"
test "${minos}" = "${expected_minos}" || {
    echo "error: ${binary} has deployment target '${minos}', expected ${expected_minos}" >&2
    exit 1
}

if xcrun nm -u "${binary}" | grep -Eq '_osgdb_|_wrapper_serializer_library_'; then
    echo "error: unresolved OSG registrar remains in ${binary}" >&2
    xcrun nm -u "${binary}" | grep -E '_osgdb_|_wrapper_serializer_library_' >&2
    exit 1
fi

if xcrun otool -L "${binary}" | tail -n +2 \
    | awk '{print $1}' \
    | grep -Evq '^(/System/Library/Frameworks/|/usr/lib/)'; then
    echo "error: prohibited dynamic dependency in ${binary}" >&2
    xcrun otool -L "${binary}" >&2
    exit 1
fi

echo "Linked product verification passed: ${binary}"
