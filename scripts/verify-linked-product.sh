#!/usr/bin/env bash

set -euo pipefail

binary="$1"
linker_command_file="${2:-}"
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
if ! grep -Eq 'platform[[:space:]]+(IOS|2)' "${vtool_output}"; then
    echo "error: ${binary} is not marked as an iOS device product" >&2
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
else
    third_party_undefined="${diagnostics_dir}/${product_name}.third-party-undefined-symbols.txt"
    # OpenGLES framework imports deliberately remain undefined in the Mach-O;
    # everything named here belongs to a statically linked project dependency.
    grep -E '(_osgdb_|_wrapper_serializer_library_|osg|MyGUI|Bullet|bt[A-Z]|Recast|Detour|_rc[A-Z]|_dt[A-Z]|_du[A-Z]|sqlite3_|png_|jpeg_|FT_|avcodec|avformat|avutil|swresample|swscale|lua|LZ4|icu|ucol_|YAML|yaml|boost|SDL_|alGet)' \
        "${undefined_symbols}" > "${third_party_undefined}" || true
    if [[ -s "${third_party_undefined}" ]]; then
        echo "error: unresolved project or third-party symbols remain in ${binary}" >&2
        cat "${third_party_undefined}" >&2
        validation_status=1
    fi
fi

link_policy_report="${diagnostics_dir}/${product_name}.link-policy.txt"
if [[ -n "${linker_command_file}" && -f "${linker_command_file}" ]]; then
    canonical_linker_command="${diagnostics_dir}/${product_name}.final-link-command.txt"
    source_linker_command="$(cd "$(dirname "${linker_command_file}")" && pwd)/$(basename "${linker_command_file}")"
    canonical_linker_command="$(cd "${diagnostics_dir}" && pwd)/$(basename "${canonical_linker_command}")"
    if [[ "${source_linker_command}" != "${canonical_linker_command}" ]]; then
        cp "${linker_command_file}" "${canonical_linker_command}"
    fi
    if grep -Eq -- '(dynamic_lookup|-flat_namespace|(^|[[:space:],])-U([,[:space:]]|$))' \
            "${linker_command_file}"; then
        echo "permissive undefined-symbol option detected" > "${link_policy_report}"
        echo "error: linker command permits unresolved symbols" >&2
        validation_status=1
    else
        echo "strict undefined-symbol resolution enforced" > "${link_policy_report}"
    fi
else
    echo "linker command was not supplied" > "${link_policy_report}"
    echo "error: final linker command is required for strict link-policy verification" >&2
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
