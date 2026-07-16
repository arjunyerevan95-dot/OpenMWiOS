#!/usr/bin/env bash

set -euo pipefail

binary="$1"
expected_minos="${IOS_DEPLOYMENT_TARGET:-16.3}"
diagnostics_dir="${BUILD_DIAGNOSTICS_DIR:-build/diagnostics}"
product_name="$(basename "${binary}")"
validation_status=0
mkdir -p "${diagnostics_dir}"

if [[ ! -f "${binary}" ]]; then
    echo "error: linked product missing: ${binary}" >&2
    exit 1
fi

if ! xcrun lipo -archs "${binary}" > "${diagnostics_dir}/${product_name}.architectures.txt" 2>&1; then
    echo "error: lipo failed for linked product: ${binary}" >&2
    validation_status=1
elif [[ "$(<"${diagnostics_dir}/${product_name}.architectures.txt")" != "arm64" ]]; then
    echo "error: linked product is not arm64-only: ${binary}" >&2
    validation_status=1
fi

vtool_output="${diagnostics_dir}/${product_name}.vtool.txt"
if ! xcrun vtool -show-build "${binary}" > "${vtool_output}" 2>&1; then
    echo "error: vtool failed for linked product: ${binary}" >&2
    validation_status=1
fi
minos="$(awk '/minos/ { print $2 }' "${vtool_output}" | sort -u)"
if [[ "${minos}" != "${expected_minos}" ]]; then
    echo "error: ${binary} has deployment target '${minos}', expected ${expected_minos}" >&2
    validation_status=1
fi

undefined_symbols="${diagnostics_dir}/${product_name}.undefined-symbols.txt"
if ! xcrun nm -u "${binary}" > "${undefined_symbols}" 2>&1; then
    echo "error: nm failed for linked product: ${binary}" >&2
    validation_status=1
elif grep -Eq '_osgdb_|_wrapper_serializer_library_' "${undefined_symbols}"; then
    echo "error: unresolved OSG registrar remains in ${binary}" >&2
    grep -E '_osgdb_|_wrapper_serializer_library_' "${undefined_symbols}" >&2
    validation_status=1
fi

dynamic_dependencies="${diagnostics_dir}/${product_name}.dynamic-dependencies.txt"
if ! xcrun otool -L "${binary}" > "${dynamic_dependencies}" 2>&1; then
    echo "error: otool failed for linked product: ${binary}" >&2
    validation_status=1
else
    while IFS= read -r dependency; do
        case "${dependency}" in
            /System/Library/Frameworks/*|/usr/lib/*) ;;
            *)
                echo "error: prohibited dynamic dependency in ${binary}: ${dependency}" >&2
                validation_status=1
                ;;
        esac
    done < <(awk 'NR > 1 { print $1 }' "${dynamic_dependencies}")
fi

(( validation_status == 0 )) || exit "${validation_status}"
echo "Linked product verification passed: ${binary}"
