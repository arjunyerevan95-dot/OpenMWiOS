#!/usr/bin/env bash

set -euo pipefail

diagnostics_dir="${BUILD_DIAGNOSTICS_DIR:-build/diagnostics}"
report="${diagnostics_dir}/deployment-target-warnings.txt"
mkdir -p "${diagnostics_dir}"
: > "${report}"

validation_status=0
for log_file in "$@"; do
    [[ -f "${log_file}" ]] || continue
    matches="$(grep -E "built for newer .*iOS.*version|deployment target.*newer" "${log_file}" || true)"
    if [[ -n "${matches}" ]]; then
        printf '## %s\n%s\n' "${log_file}" "${matches}" >> "${report}"
        validation_status=1
    fi
done

if (( validation_status != 0 )); then
    echo "error: deployment-target mismatch warning detected" >&2
    cat "${report}" >&2
    exit "${validation_status}"
fi
echo "No deployment-target mismatch warnings found in: $*" > "${report}"
