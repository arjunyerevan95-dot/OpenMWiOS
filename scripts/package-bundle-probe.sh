#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 /path/to/OpenMW.app" >&2
    exit 64
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app_path="$1"
diagnostics_dir="${repo_root}/build/diagnostics/bundle-probe"
artifact_dir="${repo_root}/build/bundle-probe-artifacts"
ipa_path="${artifact_dir}/OpenMW-iOS-bundle-probe-unsigned.ipa"
inspection_app="${artifact_dir}/OpenMW.app"
staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/openmw-bundle-probe-package.XXXXXX")"
verification_dir=""

cleanup() {
    rm -rf "${staging_dir}"
    if [[ -n "${verification_dir}" ]]; then
        rm -rf "${verification_dir}"
    fi
}
trap cleanup EXIT

mkdir -p "${diagnostics_dir}"

plist_value() {
    local plist_path="$1"
    local key_path="$2"
    plutil -extract "${key_path}" raw -o - "${plist_path}"
}

inspect_app() {
    local app="$1"
    local label="$2"
    local plist="${app}/Info.plist"
    local executable="${app}/openmw"
    local otool_report="${diagnostics_dir}/${label}-otool.txt"
    local lipo_report="${diagnostics_dir}/${label}-lipo.txt"
    local mode_report="${diagnostics_dir}/${label}-executable-mode.txt"
    local platform=""
    local minimum_os=""

    [[ -d "${app}" && "$(basename "${app}")" == "OpenMW.app" ]]
    test -f "${plist}"
    test -f "${executable}"

    plutil -lint "${plist}" | tee "${diagnostics_dir}/${label}-plutil-lint.txt"
    plutil -p "${plist}" > "${diagnostics_dir}/${label}-plist.txt"

    test "$(plist_value "${plist}" CFBundleIdentifier)" = "org.openmw.ios"
    test "$(plist_value "${plist}" CFBundleExecutable)" = "openmw"
    test "$(plist_value "${plist}" CFBundlePackageType)" = "APPL"
    test "$(plist_value "${plist}" CFBundleShortVersionString)" = "0.1"
    test "$(plist_value "${plist}" CFBundleVersion)" = "1"
    test "$(plist_value "${plist}" MinimumOSVersion)" = "16.3"
    test "$(plist_value "${plist}" CFBundleSupportedPlatforms.0)" = "iPhoneOS"
    test "$(plist_value "${plist}" UIDeviceFamily.0)" = "1"

    file "${executable}" | tee "${diagnostics_dir}/${label}-file.txt"
    lipo -info "${executable}" | tee "${lipo_report}"
    otool -l "${executable}" > "${otool_report}"
    stat -f '%Lp' "${executable}" | tee "${mode_report}"

    grep -Eq 'arm64' "${lipo_report}"
    test "$(cat "${mode_report}")" = "755"

    platform="$(
        awk '
            /cmd LC_BUILD_VERSION/ { in_build = 1; next }
            in_build && $1 == "platform" { print $2; exit }
        ' "${otool_report}"
    )"
    minimum_os="$(
        awk '
            /cmd LC_BUILD_VERSION/ { in_build = 1; next }
            in_build && $1 == "minos" { print $2; exit }
        ' "${otool_report}"
    )"

    if [[ -z "${platform}" ]]; then
        grep -q 'LC_VERSION_MIN_IPHONEOS' "${otool_report}"
        platform="2"
        minimum_os="$(
            awk '
                /cmd LC_VERSION_MIN_IPHONEOS/ { in_version = 1; next }
                in_version && $1 == "version" { print $2; exit }
            ' "${otool_report}"
        )"
    fi

    [[ "${platform}" == "2" || "${platform}" == "IOS" || "${platform}" == "iOS" ]]
    test "${minimum_os}" = "16.3"
    printf 'platform=%s\nminimum_os=%s\n' "${platform}" "${minimum_os}" \
        > "${diagnostics_dir}/${label}-platform.txt"

    test ! -e "${app}/embedded.mobileprovision"
    test ! -d "${app}/_CodeSignature"
    test -z "$(find "${app}" -mindepth 1 -type d -print -quit)"
    test -z "$(
        find "${app}" -mindepth 1 -type f \
            ! -name Info.plist ! -name openmw ! -name PkgInfo -print -quit
    )"
    test -z "$(
        find "${app}" -mindepth 1 \
            \( -name '*.appex' -o -name '*.framework' -o -name '*.dylib' \
               -o -name '*.bundle' -o -name PlugIns -o -name Frameworks \) \
            -print -quit
    )"
    test -z "$(
        grep -A4 -E 'LC_ENCRYPTION_INFO(_64)?' "${otool_report}" \
            | grep 'cryptid 1' || true
    )"

    find "${app}" -mindepth 1 -print \
        | LC_ALL=C sort > "${diagnostics_dir}/${label}-tree.txt"
    printf 'files=%s\nbytes=%s\n' \
        "$(find "${app}" -type f | wc -l | tr -d ' ')" \
        "$(du -sk "${app}" | awk '{ print $1 * 1024 }')" \
        > "${diagnostics_dir}/${label}-counts.txt"
    shasum -a 256 "${executable}" "${plist}" \
        > "${diagnostics_dir}/${label}-sha256.txt"
}

if [[ ! -d "${app_path}" || "$(basename "${app_path}")" != "OpenMW.app" ]]; then
    echo "error: expected an existing OpenMW.app bundle" >&2
    exit 1
fi

printf '%s\n' "${app_path}" > "${diagnostics_dir}/built-app-path.txt"
inspect_app "${app_path}" "pre-package"

rm -rf "${artifact_dir}"
mkdir -p "${artifact_dir}" "${staging_dir}/Payload"

/usr/bin/ditto "${app_path}" "${staging_dir}/Payload/OpenMW.app"
chmod 0755 "${staging_dir}/Payload/OpenMW.app/openmw"

(
    cd "${staging_dir}"
    /usr/bin/zip -qry -y "${ipa_path}" Payload
)

/usr/bin/ditto "${app_path}" "${inspection_app}"
chmod 0755 "${inspection_app}/openmw"

test -f "${ipa_path}"
test -d "${inspection_app}"

unzip -t "${ipa_path}" | tee "${diagnostics_dir}/ipa-integrity.txt"
unzip -Z1 "${ipa_path}" > "${diagnostics_dir}/ipa-paths.txt"
zipinfo -l "${ipa_path}" > "${diagnostics_dir}/ipa-permissions.txt"
unzip -l "${ipa_path}" > "${diagnostics_dir}/ipa-listing.txt"

test -z "$(grep -Ev '^Payload(/|$)' "${diagnostics_dir}/ipa-paths.txt" || true)"
test -z "$(
    grep -E '(^|/)(Frameworks|PlugIns)(/|$)|\.appex/|\.framework/|\.dylib$|\.ipa$|embedded\.mobileprovision$|_CodeSignature/' \
        "${diagnostics_dir}/ipa-paths.txt" || true
)"

verification_dir="$(mktemp -d "${TMPDIR:-/tmp}/openmw-bundle-probe-verify.XXXXXX")"
unzip -q "${ipa_path}" -d "${verification_dir}"
find "${verification_dir}" -print \
    | LC_ALL=C sort > "${diagnostics_dir}/extracted-tree.txt"

test -d "${verification_dir}/Payload"
test -z "$(
    find "${verification_dir}" -mindepth 1 -maxdepth 1 \
        ! -name Payload -print -quit
)"
test -z "$(
    find "${verification_dir}/Payload" -mindepth 1 -maxdepth 1 \
        ! -name OpenMW.app -print -quit
)"

find "${verification_dir}/Payload" -type d -name '*.app' -prune -print \
    > "${diagnostics_dir}/packaged-app-paths.txt"
test "$(wc -l < "${diagnostics_dir}/packaged-app-paths.txt" | tr -d ' ')" -eq 1

packaged_app="${verification_dir}/Payload/OpenMW.app"
inspect_app "${packaged_app}" "packaged"

cmp "${app_path}/Info.plist" "${packaged_app}/Info.plist"
cmp "${app_path}/openmw" "${packaged_app}/openmw"
cmp "${app_path}/Info.plist" "${inspection_app}/Info.plist"
cmp "${app_path}/openmw" "${inspection_app}/openmw"
test "$(stat -f '%Lp' "${inspection_app}/openmw")" = "755"

shasum -a 256 \
    "${packaged_app}/openmw" \
    "${packaged_app}/Info.plist" \
    "${ipa_path}" \
    > "${diagnostics_dir}/probe-artifact-sha256.txt"
printf '0\n' > "${diagnostics_dir}/probe-validation.exit-status"
