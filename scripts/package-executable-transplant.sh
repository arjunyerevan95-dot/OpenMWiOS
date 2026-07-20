#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
diagnostics_dir="${repo_root}/build/diagnostics/executable-transplant"
staging_root="${repo_root}/build/executable-transplant"
staged_app="${staging_root}/OpenMW.app"
artifact_dir="${repo_root}/build/executable-transplant-artifacts"
ipa_path="${artifact_dir}/OpenMW-iOS-executable-transplant-unsigned.ipa"
inspection_app="${artifact_dir}/OpenMW.app"
package_root=""
verification_root=""

cleanup() {
    if [[ -n "${package_root}" ]]; then
        rm -rf "${package_root}"
    fi
    if [[ -n "${verification_root}" ]]; then
        rm -rf "${verification_root}"
    fi
}
trap cleanup EXIT

mkdir -p "${diagnostics_dir}"
rm -rf "${staging_root}" "${artifact_dir}"
mkdir -p "${staging_root}" "${artifact_dir}"

fail() {
    echo "error: $*" >&2
    exit 1
}

single_path() {
    local candidates_file="$1"
    local description="$2"
    local count
    count="$(wc -l < "${candidates_file}" | tr -d ' ')"
    [[ "${count}" == "1" ]] || fail "expected exactly one ${description}, found ${count}"
    cat "${candidates_file}"
}

plist_value() {
    local plist_path="$1"
    local key_path="$2"
    plutil -extract "${key_path}" raw -o - "${plist_path}"
}

inspect_macho() {
    local executable="$1"
    local label="$2"
    local file_report="${diagnostics_dir}/${label}-file.txt"
    local lipo_report="${diagnostics_dir}/${label}-lipo.txt"
    local otool_report="${diagnostics_dir}/${label}-otool.txt"
    local mode_report="${diagnostics_dir}/${label}-mode.txt"
    local size_report="${diagnostics_dir}/${label}-size.txt"
    local hash_report="${diagnostics_dir}/${label}-sha256.txt"
    local platform
    local minimum_os
    local sdk

    test -f "${executable}"
    file "${executable}" | tee "${file_report}"
    lipo -info "${executable}" | tee "${lipo_report}"
    otool -l "${executable}" > "${otool_report}"
    stat -f '%Lp' "${executable}" | tee "${mode_report}"
    stat -f '%z' "${executable}" | tee "${size_report}"
    shasum -a 256 "${executable}" | tee "${hash_report}"

    grep -Eq 'arm64' "${lipo_report}"

    platform="$(awk '/cmd LC_BUILD_VERSION/ { in_build = 1; next } in_build && $1 == "platform" { print $2; exit }' "${otool_report}")"
    minimum_os="$(awk '/cmd LC_BUILD_VERSION/ { in_build = 1; next } in_build && $1 == "minos" { print $2; exit }' "${otool_report}")"
    sdk="$(awk '/cmd LC_BUILD_VERSION/ { in_build = 1; next } in_build && $1 == "sdk" { print $2; exit }' "${otool_report}")"

    if [[ -z "${platform}" ]]; then
        grep -q 'LC_VERSION_MIN_IPHONEOS' "${otool_report}"
        platform="2"
        minimum_os="$(awk '/cmd LC_VERSION_MIN_IPHONEOS/ { in_version = 1; next } in_version && $1 == "version" { print $2; exit }' "${otool_report}")"
        sdk="$(awk '/cmd LC_VERSION_MIN_IPHONEOS/ { in_version = 1; next } in_version && $1 == "sdk" { print $2; exit }' "${otool_report}")"
    fi

    printf '%s\n' "${platform}" > "${diagnostics_dir}/${label}-platform.txt"
    printf '%s\n' "${minimum_os}" > "${diagnostics_dir}/${label}-minimum-os.txt"
    printf '%s\n' "${sdk}" > "${diagnostics_dir}/${label}-sdk.txt"

    [[ "${platform}" == "2" || "${platform}" == "IOS" ]] || fail "${label} is not an iOS device executable"
    [[ "${minimum_os}" == "16.3" ]] || fail "${label} minimum OS is ${minimum_os}, expected 16.3"
}

find "${repo_root}/build/device" -type d -name 'openmw.app' -prune -print 2>/dev/null \
    | LC_ALL=C sort > "${diagnostics_dir}/complete-app-candidates.txt"
complete_app="$(single_path "${diagnostics_dir}/complete-app-candidates.txt" "complete OpenMW app")"
complete_executable="${complete_app}/openmw"
complete_plist="${complete_app}/Info.plist"
test -r "${complete_plist}" || fail "complete OpenMW Info.plist is not readable"
test -f "${complete_executable}" || fail "complete OpenMW executable is missing"

find "${repo_root}/build/bundle-probe" -type d -name 'OpenMW.app' -prune -print 2>/dev/null \
    | LC_ALL=C sort > "${diagnostics_dir}/probe-app-candidates.txt"
probe_app="$(single_path "${diagnostics_dir}/probe-app-candidates.txt" "minimal probe app")"
probe_plist="${probe_app}/Info.plist"
probe_pkginfo="${probe_app}/PkgInfo"
probe_executable="${probe_app}/openmw"
test -r "${probe_plist}" || fail "probe Info.plist is not readable"
test -f "${probe_pkginfo}" || fail "probe PkgInfo is missing"
test -f "${probe_executable}" || fail "probe executable is missing"

printf '%s\n' "${complete_app}" > "${diagnostics_dir}/complete-app-path.txt"
printf '%s\n' "${complete_executable}" > "${diagnostics_dir}/complete-executable-path.txt"
printf '%s\n' "${probe_app}" > "${diagnostics_dir}/probe-app-path.txt"
printf '%s\n' "${staged_app}" > "${diagnostics_dir}/staged-app-path.txt"
printf '%s\n' "${ipa_path}" > "${diagnostics_dir}/ipa-path.txt"

find "${probe_app}" -type f -print | sed "s#^${probe_app}/##" | LC_ALL=C sort \
    > "${diagnostics_dir}/probe-tree-files.txt"
find "${probe_app}" -mindepth 1 -type d -print | sed "s#^${probe_app}/##" | LC_ALL=C sort \
    > "${diagnostics_dir}/probe-tree-directories.txt"
cat > "${diagnostics_dir}/expected-files.txt" <<'EOF_EXPECTED'
Info.plist
PkgInfo
openmw
EOF_EXPECTED
cmp -s "${diagnostics_dir}/expected-files.txt" "${diagnostics_dir}/probe-tree-files.txt" \
    || fail "minimal probe does not contain exactly Info.plist, PkgInfo, and openmw"
test ! -s "${diagnostics_dir}/probe-tree-directories.txt" \
    || fail "minimal probe contains unexpected nested directories"
test ! -e "${probe_app}/embedded.mobileprovision"
test ! -d "${probe_app}/_CodeSignature"

plutil -lint "${probe_plist}" | tee "${diagnostics_dir}/probe-plutil-lint.txt"
plutil -p "${probe_plist}" > "${diagnostics_dir}/probe-plist.txt"
test "$(plist_value "${probe_plist}" CFBundleDisplayName)" = "OpenMW Probe"
test "$(plist_value "${probe_plist}" CFBundleIdentifier)" = "org.openmw.ios"
test "$(plist_value "${probe_plist}" CFBundleExecutable)" = "openmw"
test "$(plist_value "${probe_plist}" CFBundlePackageType)" = "APPL"
test "$(plist_value "${probe_plist}" CFBundleShortVersionString)" = "0.1"
test "$(plist_value "${probe_plist}" CFBundleVersion)" = "1"
test "$(plist_value "${probe_plist}" MinimumOSVersion)" = "16.3"
test "$(plist_value "${probe_plist}" CFBundleSupportedPlatforms.0)" = "iPhoneOS"
test "$(plist_value "${probe_plist}" UIDeviceFamily.0)" = "1"

inspect_macho "${complete_executable}" "complete-executable"
inspect_macho "${probe_executable}" "probe-executable"

complete_mode="$(cat "${diagnostics_dir}/complete-executable-mode.txt")"
complete_hash="$(awk '{ print $1 }' "${diagnostics_dir}/complete-executable-sha256.txt")"
probe_hash="$(awk '{ print $1 }' "${diagnostics_dir}/probe-executable-sha256.txt")"
probe_plist_hash="$(shasum -a 256 "${probe_plist}" | awk '{ print $1 }')"
probe_pkginfo_hash="$(shasum -a 256 "${probe_pkginfo}" | awk '{ print $1 }')"

cp -R "${probe_app}" "${staged_app}"
cp "${complete_executable}" "${staged_app}/openmw"
chmod 0755 "${staged_app}/openmw"
chmod 0644 "${staged_app}/Info.plist" "${staged_app}/PkgInfo"

cmp -s "${probe_plist}" "${staged_app}/Info.plist" || fail "transplant Info.plist differs from probe"
cmp -s "${probe_pkginfo}" "${staged_app}/PkgInfo" || fail "transplant PkgInfo differs from probe"
cmp -s "${complete_executable}" "${staged_app}/openmw" || fail "transplant executable differs from complete OpenMW executable"
if cmp -s "${probe_executable}" "${staged_app}/openmw"; then
    fail "transplant executable unexpectedly matches minimal probe executable"
fi

find "${staged_app}" -type f -print | sed "s#^${staged_app}/##" | LC_ALL=C sort \
    > "${diagnostics_dir}/staged-tree-files.txt"
find "${staged_app}" -mindepth 1 -type d -print | sed "s#^${staged_app}/##" | LC_ALL=C sort \
    > "${diagnostics_dir}/staged-tree-directories.txt"
cmp -s "${diagnostics_dir}/expected-files.txt" "${diagnostics_dir}/staged-tree-files.txt" \
    || fail "staged transplant does not contain exactly three expected files"
test ! -s "${diagnostics_dir}/staged-tree-directories.txt" \
    || fail "staged transplant contains unexpected nested directories"

for forbidden in resources defaults.bin openmw.cfg gamecontrollerdb.txt openmw-link.map embedded.mobileprovision _CodeSignature; do
    if find "${staged_app}" -name "${forbidden}" -print -quit | grep -q .; then
        fail "staged transplant contains forbidden path: ${forbidden}"
    fi
done
if find "${staged_app}" \( -name '*.framework' -o -name '*.dylib' -o -name '*.appex' -o -name '*.plugin' -o -name '*.bundle' \) -print -quit | grep -q .; then
    fail "staged transplant contains unexpected nested code or bundle"
fi
test ! -d "${staged_app}/_CodeSignature"
test ! -e "${staged_app}/embedded.mobileprovision"

plutil -lint "${staged_app}/Info.plist" | tee "${diagnostics_dir}/staged-plutil-lint.txt"
plutil -p "${staged_app}/Info.plist" > "${diagnostics_dir}/staged-plist.txt"
inspect_macho "${staged_app}/openmw" "staged-executable"
test "$(cat "${diagnostics_dir}/staged-executable-mode.txt")" = "755"
test "$(cat "${diagnostics_dir}/staged-executable-sdk.txt")" = "$(cat "${diagnostics_dir}/complete-executable-sdk.txt")"

staged_plist_hash="$(shasum -a 256 "${staged_app}/Info.plist" | awk '{ print $1 }')"
staged_pkginfo_hash="$(shasum -a 256 "${staged_app}/PkgInfo" | awk '{ print $1 }')"
staged_hash="$(awk '{ print $1 }' "${diagnostics_dir}/staged-executable-sha256.txt")"

[[ "${probe_plist_hash}" == "${staged_plist_hash}" ]]
[[ "${probe_pkginfo_hash}" == "${staged_pkginfo_hash}" ]]
[[ "${complete_hash}" == "${staged_hash}" ]]
[[ "${probe_hash}" != "${staged_hash}" ]]

cat > "${diagnostics_dir}/comparison-manifest.txt" <<EOF_MANIFEST
complete_app_path=${complete_app}
complete_executable_path=${complete_executable}
probe_app_path=${probe_app}
staged_app_path=${staged_app}
probe_info_plist_sha256=${probe_plist_hash}
transplant_info_plist_sha256=${staged_plist_hash}
probe_pkginfo_sha256=${probe_pkginfo_hash}
transplant_pkginfo_sha256=${staged_pkginfo_hash}
probe_executable_sha256=${probe_hash}
complete_openmw_executable_sha256=${complete_hash}
transplant_executable_sha256=${staged_hash}
complete_executable_original_mode=${complete_mode}
transplant_executable_mode=$(cat "${diagnostics_dir}/staged-executable-mode.txt")
probe_file_count=$(wc -l < "${diagnostics_dir}/probe-tree-files.txt" | tr -d ' ')
transplant_file_count=$(wc -l < "${diagnostics_dir}/staged-tree-files.txt" | tr -d ' ')
metadata_source=minimal probe
executable_source=complete OpenMW app
no_other_files_present=true
conclusion_metadata_copied_from_minimal_probe=true
conclusion_executable_copied_from_complete_openmw_app=true
conclusion_no_other_files_present=true
EOF_MANIFEST

package_root="$(mktemp -d "${TMPDIR:-/tmp}/openmw-executable-transplant-package.XXXXXX")"
mkdir -p "${package_root}/Payload"
cp -R "${staged_app}" "${package_root}/Payload/OpenMW.app"
find "${package_root}/Payload" -type d -exec chmod 0755 {} +
chmod 0644 "${package_root}/Payload/OpenMW.app/Info.plist" "${package_root}/Payload/OpenMW.app/PkgInfo"
chmod 0755 "${package_root}/Payload/OpenMW.app/openmw"

(
    cd "${package_root}"
    COPYFILE_DISABLE=1 /usr/bin/zip -X -q -r "${ipa_path}" Payload
)

unzip -t "${ipa_path}" | tee "${diagnostics_dir}/ipa-integrity.txt"
unzip -l "${ipa_path}" > "${diagnostics_dir}/ipa-listing.txt"
unzip -Z1 "${ipa_path}" > "${diagnostics_dir}/ipa-paths.txt"
zipinfo -l "${ipa_path}" > "${diagnostics_dir}/ipa-permissions.txt"
cat > "${diagnostics_dir}/expected-ipa-paths.txt" <<'EOF_IPA_PATHS'
Payload/
Payload/OpenMW.app/
Payload/OpenMW.app/Info.plist
Payload/OpenMW.app/PkgInfo
Payload/OpenMW.app/openmw
EOF_IPA_PATHS
LC_ALL=C sort "${diagnostics_dir}/ipa-paths.txt" > "${diagnostics_dir}/ipa-paths.sorted.txt"
LC_ALL=C sort "${diagnostics_dir}/expected-ipa-paths.txt" > "${diagnostics_dir}/expected-ipa-paths.sorted.txt"
cmp -s "${diagnostics_dir}/expected-ipa-paths.sorted.txt" "${diagnostics_dir}/ipa-paths.sorted.txt" \
    || fail "IPA contains paths other than Payload/OpenMW.app and its three expected files"

verification_root="$(mktemp -d "${TMPDIR:-/tmp}/openmw-executable-transplant-verify.XXXXXX")"
unzip -q "${ipa_path}" -d "${verification_root}"
extracted_app="${verification_root}/Payload/OpenMW.app"

find "${verification_root}" -type d -name '*.app' -prune -print | LC_ALL=C sort \
    > "${diagnostics_dir}/packaged-app-paths.txt"
test "$(wc -l < "${diagnostics_dir}/packaged-app-paths.txt" | tr -d ' ')" = "1"
test "$(cat "${diagnostics_dir}/packaged-app-paths.txt")" = "${extracted_app}"
find "${extracted_app}" -type f -print | sed "s#^${extracted_app}/##" | LC_ALL=C sort \
    > "${diagnostics_dir}/packaged-tree-files.txt"
find "${extracted_app}" -mindepth 1 -type d -print | sed "s#^${extracted_app}/##" | LC_ALL=C sort \
    > "${diagnostics_dir}/packaged-tree-directories.txt"
cmp -s "${diagnostics_dir}/expected-files.txt" "${diagnostics_dir}/packaged-tree-files.txt" \
    || fail "packaged transplant does not contain exactly three expected files"
test ! -s "${diagnostics_dir}/packaged-tree-directories.txt" \
    || fail "packaged transplant contains unexpected nested directories"

cmp -s "${probe_plist}" "${extracted_app}/Info.plist" || fail "packaged Info.plist differs from probe"
cmp -s "${probe_pkginfo}" "${extracted_app}/PkgInfo" || fail "packaged PkgInfo differs from probe"
cmp -s "${complete_executable}" "${extracted_app}/openmw" || fail "packaged executable differs from complete OpenMW executable"
test ! -d "${extracted_app}/_CodeSignature"
test ! -e "${extracted_app}/embedded.mobileprovision"

plutil -lint "${extracted_app}/Info.plist" | tee "${diagnostics_dir}/packaged-plutil-lint.txt"
plutil -p "${extracted_app}/Info.plist" > "${diagnostics_dir}/packaged-plist.txt"
inspect_macho "${extracted_app}/openmw" "packaged-executable"
test "$(cat "${diagnostics_dir}/packaged-executable-mode.txt")" = "755"
test "$(cat "${diagnostics_dir}/packaged-executable-sdk.txt")" = "$(cat "${diagnostics_dir}/complete-executable-sdk.txt")"

find "${extracted_app}" -print | sed "s#^${verification_root}/##" | LC_ALL=C sort \
    > "${diagnostics_dir}/packaged-tree.txt"
find "${extracted_app}" -type f -exec stat -f '%z %N' {} + | LC_ALL=C sort \
    > "${diagnostics_dir}/packaged-file-sizes.txt"
shasum -a 256 "${ipa_path}" | tee "${diagnostics_dir}/ipa-sha256.txt"
shasum -a 256 "${staged_app}/Info.plist" "${staged_app}/PkgInfo" "${staged_app}/openmw" \
    > "${diagnostics_dir}/staged-file-sha256.txt"
shasum -a 256 "${extracted_app}/Info.plist" "${extracted_app}/PkgInfo" "${extracted_app}/openmw" \
    > "${diagnostics_dir}/packaged-file-sha256.txt"

cp -R "${staged_app}" "${inspection_app}"

printf 'Executable transplant packaged successfully\n'
printf 'IPA: %s\n' "${ipa_path}"
printf 'Complete executable SHA-256: %s\n' "${complete_hash}"
printf 'Transplant executable SHA-256: %s\n' "${staged_hash}"
