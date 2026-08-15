#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
diagnostics_dir="${repo_root}/build/diagnostics/production-plist-transplant"
staging_root="${repo_root}/build/production-plist-transplant"
staged_app="${staging_root}/OpenMW.app"
artifact_dir="${repo_root}/build/production-plist-transplant-artifacts"
ipa_path="${artifact_dir}/OpenMW-iOS-production-plist-transplant-unsigned.ipa"
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

relative_path() {
    local path="$1"
    printf '%s\n' "${path#"${repo_root}/"}"
}

file_mode() {
    stat -f '%Lp' "$1"
}

file_size() {
    stat -f '%z' "$1"
}

file_hash() {
    shasum -a 256 "$1" | awk '{ print $1 }'
}

record_app_tree() {
    local app="$1"
    local label="$2"

    find "${app}" -print | sed "s#^${app}#OpenMW.app#" | LC_ALL=C sort \
        > "${diagnostics_dir}/${label}-tree.txt"
    find "${app}" -mindepth 1 -print | sed "s#^${app}/##" | LC_ALL=C sort \
        > "${diagnostics_dir}/${label}-tree-entries.txt"
    find "${app}" -type f -print | sed "s#^${app}/##" | LC_ALL=C sort \
        > "${diagnostics_dir}/${label}-tree-files.txt"
    find "${app}" -mindepth 1 -type d -print | sed "s#^${app}/##" | LC_ALL=C sort \
        > "${diagnostics_dir}/${label}-tree-directories.txt"
    find "${app}" -type f -exec stat -f '%Lp\t%z\t%N' {} + | LC_ALL=C sort \
        > "${diagnostics_dir}/${label}-file-modes-sizes.tsv"
    find "${app}" -type d -exec stat -f '%Lp\t%N' {} + | LC_ALL=C sort \
        > "${diagnostics_dir}/${label}-directory-modes.tsv"
}

inspect_macho() {
    local executable="$1"
    local label="$2"
    local file_report="${diagnostics_dir}/${label}-file.txt"
    local lipo_report="${diagnostics_dir}/${label}-lipo.txt"
    local otool_report="${diagnostics_dir}/${label}-otool.txt"
    local platform
    local minimum_os
    local sdk

    test -f "${executable}" || fail "${label} executable is missing"
    file "${executable}" | tee "${file_report}"
    lipo -info "${executable}" | tee "${lipo_report}"
    otool -l "${executable}" > "${otool_report}"
    file_mode "${executable}" | tee "${diagnostics_dir}/${label}-mode.txt"
    file_size "${executable}" | tee "${diagnostics_dir}/${label}-size.txt"
    shasum -a 256 "${executable}" | tee "${diagnostics_dir}/${label}-sha256.txt"

    grep -Eq 'arm64' "${lipo_report}" || fail "${label} is not arm64"
    if grep -q 'LC_CODE_SIGNATURE' "${otool_report}"; then
        fail "${label} unexpectedly contains an LC_CODE_SIGNATURE command"
    fi

    platform="$(awk '/cmd LC_BUILD_VERSION/ { in_build = 1; next } in_build && $1 == "platform" { print $2; exit }' "${otool_report}")"
    minimum_os="$(awk '/cmd LC_BUILD_VERSION/ { in_build = 1; next } in_build && $1 == "minos" { print $2; exit }' "${otool_report}")"
    sdk="$(awk '/cmd LC_BUILD_VERSION/ { in_build = 1; next } in_build && $1 == "sdk" { print $2; exit }' "${otool_report}")"

    if [[ -z "${platform}" ]]; then
        grep -q 'LC_VERSION_MIN_IPHONEOS' "${otool_report}" \
            || fail "${label} has no iPhoneOS build-version command"
        platform="2"
        minimum_os="$(awk '/cmd LC_VERSION_MIN_IPHONEOS/ { in_version = 1; next } in_version && $1 == "version" { print $2; exit }' "${otool_report}")"
        sdk="$(awk '/cmd LC_VERSION_MIN_IPHONEOS/ { in_version = 1; next } in_version && $1 == "sdk" { print $2; exit }' "${otool_report}")"
    fi

    printf '%s\n' "${platform}" > "${diagnostics_dir}/${label}-platform.txt"
    printf '%s\n' "${minimum_os}" > "${diagnostics_dir}/${label}-minimum-os.txt"
    printf '%s\n' "${sdk}" > "${diagnostics_dir}/${label}-sdk.txt"

    [[ "${platform}" == "2" || "${platform}" == "IOS" ]] \
        || fail "${label} is not an iOS device executable"
    [[ "${minimum_os}" == "16.3" ]] \
        || fail "${label} minimum OS is ${minimum_os}, expected 16.3"
}

require_unsigned_app() {
    local app="$1"
    local label="$2"
    local codesign_report="${diagnostics_dir}/${label}-codesign.txt"

    test ! -e "${app}/embedded.mobileprovision" \
        || fail "${label} contains embedded.mobileprovision"
    test ! -d "${app}/_CodeSignature" \
        || fail "${label} contains _CodeSignature"
    if codesign -d --verbose=4 "${app}" > "${codesign_report}" 2>&1; then
        fail "${label} unexpectedly has a code signature"
    fi
}

write_plist_inventory() {
    local production_plist="$1"
    local minimal_plist="$2"

    python3 - "${production_plist}" "${minimal_plist}" "${diagnostics_dir}" <<'PY'
import base64
import datetime
import json
import pathlib
import plistlib
import sys

production_path = pathlib.Path(sys.argv[1])
minimal_path = pathlib.Path(sys.argv[2])
out_dir = pathlib.Path(sys.argv[3])

with production_path.open("rb") as handle:
    production = plistlib.load(handle)
with minimal_path.open("rb") as handle:
    minimal = plistlib.load(handle)

if not isinstance(production, dict):
    raise SystemExit("production plist root is not a dictionary")
if not isinstance(minimal, dict):
    raise SystemExit("minimal probe plist root is not a dictionary")


def type_name(value):
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, str):
        return "string"
    if isinstance(value, bytes):
        return "data"
    if isinstance(value, datetime.datetime):
        return "date"
    if isinstance(value, int):
        return "integer"
    if isinstance(value, float):
        return "real"
    if isinstance(value, list):
        return "array"
    if isinstance(value, dict):
        return "dictionary"
    return type(value).__name__


def json_safe(value):
    if isinstance(value, bytes):
        return {"$data_base64": base64.b64encode(value).decode("ascii")}
    if isinstance(value, datetime.datetime):
        return {"$date": value.isoformat()}
    if isinstance(value, list):
        return [json_safe(item) for item in value]
    if isinstance(value, dict):
        return {key: json_safe(value[key]) for key in sorted(value)}
    return value


def encoded(value):
    return json.dumps(json_safe(value), ensure_ascii=False, sort_keys=True, separators=(",", ":"))

with (out_dir / "production-plist-key-inventory.tsv").open("w", encoding="utf-8", newline="\n") as handle:
    handle.write("key\ttype\tvalue_json\n")
    for key in sorted(production):
        handle.write(f"{key}\t{type_name(production[key])}\t{encoded(production[key])}\n")

with (out_dir / "minimal-probe-plist-key-inventory.tsv").open("w", encoding="utf-8", newline="\n") as handle:
    handle.write("key\ttype\tvalue_json\n")
    for key in sorted(minimal):
        handle.write(f"{key}\t{type_name(minimal[key])}\t{encoded(minimal[key])}\n")

with (out_dir / "production-only-plist-keys.tsv").open("w", encoding="utf-8", newline="\n") as handle:
    handle.write("key\ttype\tvalue_json\n")
    for key in sorted(set(production) - set(minimal)):
        handle.write(f"{key}\t{type_name(production[key])}\t{encoded(production[key])}\n")

with (out_dir / "production-vs-minimal-plist-differences.tsv").open("w", encoding="utf-8", newline="\n") as handle:
    handle.write("key\tstatus\tproduction_type\tproduction_value_json\tminimal_type\tminimal_value_json\n")
    for key in sorted(set(production) | set(minimal)):
        if key not in minimal:
            status = "production-only"
        elif key not in production:
            status = "minimal-only"
        elif production[key] != minimal[key]:
            status = "different"
        else:
            continue
        production_type = type_name(production[key]) if key in production else "absent"
        production_value = encoded(production[key]) if key in production else "null"
        minimal_type = type_name(minimal[key]) if key in minimal else "absent"
        minimal_value = encoded(minimal[key]) if key in minimal else "null"
        handle.write(
            f"{key}\t{status}\t{production_type}\t{production_value}\t"
            f"{minimal_type}\t{minimal_value}\n"
        )

required = [
    "CFBundleIdentifier",
    "CFBundleExecutable",
    "CFBundlePackageType",
    "CFBundleDisplayName",
    "CFBundleName",
    "CFBundleShortVersionString",
    "CFBundleVersion",
    "MinimumOSVersion",
    "CFBundleSupportedPlatforms",
    "UIDeviceFamily",
    "UILaunchScreen",
]
with (out_dir / "production-plist-required-keys.tsv").open("w", encoding="utf-8", newline="\n") as handle:
    handle.write("key\tpresence\ttype\tvalue_json\n")
    for key in required:
        if key in production:
            handle.write(f"{key}\tpresent\t{type_name(production[key])}\t{encoded(production[key])}\n")
        else:
            handle.write(f"{key}\tabsent\tabsent\tnull\n")
PY
}

find "${repo_root}/build/device" -type d -name 'openmw.app' -prune -print 2>/dev/null \
    | LC_ALL=C sort > "${diagnostics_dir}/production-app-candidates.txt"
production_app="$(single_path "${diagnostics_dir}/production-app-candidates.txt" "complete production OpenMW app")"
production_plist="${production_app}/Info.plist"
production_executable="${production_app}/openmw"
test -r "${production_plist}" || fail "production Info.plist is not readable"
test -f "${production_executable}" || fail "production executable is missing"

find "${repo_root}/build/bundle-probe" -type d -name 'OpenMW.app' -prune -print 2>/dev/null \
    | LC_ALL=C sort > "${diagnostics_dir}/minimal-probe-app-candidates.txt"
minimal_probe_app="$(single_path "${diagnostics_dir}/minimal-probe-app-candidates.txt" "minimal probe app")"
minimal_probe_plist="${minimal_probe_app}/Info.plist"
minimal_probe_pkginfo="${minimal_probe_app}/PkgInfo"
test -r "${minimal_probe_plist}" || fail "minimal probe Info.plist is not readable"
test -f "${minimal_probe_pkginfo}" || fail "minimal probe PkgInfo is missing"

find "${repo_root}/build/executable-transplant-artifacts" -type d -name 'OpenMW.app' -prune -print 2>/dev/null \
    | LC_ALL=C sort > "${diagnostics_dir}/executable-transplant-app-candidates.txt"
executable_transplant_app="$(single_path "${diagnostics_dir}/executable-transplant-app-candidates.txt" "validated executable-transplant app")"
executable_transplant_plist="${executable_transplant_app}/Info.plist"
executable_transplant_pkginfo="${executable_transplant_app}/PkgInfo"
executable_transplant_executable="${executable_transplant_app}/openmw"
test -r "${executable_transplant_plist}" || fail "executable-transplant Info.plist is not readable"
test -f "${executable_transplant_pkginfo}" || fail "executable-transplant PkgInfo is missing"
test -f "${executable_transplant_executable}" || fail "executable-transplant executable is missing"

printf '%s\n' "$(relative_path "${production_app}")" > "${diagnostics_dir}/production-app-path.txt"
printf '%s\n' "$(relative_path "${production_plist}")" > "${diagnostics_dir}/production-plist-path.txt"
printf '%s\n' "$(relative_path "${production_executable}")" > "${diagnostics_dir}/production-executable-path.txt"
printf '%s\n' "$(relative_path "${minimal_probe_app}")" > "${diagnostics_dir}/minimal-probe-app-path.txt"
printf '%s\n' "$(relative_path "${executable_transplant_app}")" > "${diagnostics_dir}/executable-transplant-app-path.txt"
printf '%s\n' "$(relative_path "${staged_app}")" > "${diagnostics_dir}/staged-app-path.txt"
printf '%s\n' "$(relative_path "${ipa_path}")" > "${diagnostics_dir}/ipa-path.txt"

record_app_tree "${production_app}" "production-app"
record_app_tree "${minimal_probe_app}" "minimal-probe-app"
record_app_tree "${executable_transplant_app}" "executable-transplant-app"

cat > "${diagnostics_dir}/expected-files.txt" <<'EOF_EXPECTED'
Info.plist
PkgInfo
openmw
EOF_EXPECTED
cmp -s "${diagnostics_dir}/expected-files.txt" "${diagnostics_dir}/executable-transplant-app-tree-entries.txt" \
    || fail "executable transplant contains an unexpected path"
cmp -s "${diagnostics_dir}/expected-files.txt" "${diagnostics_dir}/executable-transplant-app-tree-files.txt" \
    || fail "executable transplant does not contain exactly three regular files"
test ! -s "${diagnostics_dir}/executable-transplant-app-tree-directories.txt" \
    || fail "executable transplant contains unexpected nested directories"

require_unsigned_app "${executable_transplant_app}" "executable-transplant-app"
plutil -lint "${production_plist}" | tee "${diagnostics_dir}/production-plutil-lint.txt"
plutil -p "${production_plist}" > "${diagnostics_dir}/production-plist.plutil.txt"
plutil -convert xml1 -o "${diagnostics_dir}/production-plist.xml" "${production_plist}"
plutil -lint "${minimal_probe_plist}" | tee "${diagnostics_dir}/minimal-probe-plutil-lint.txt"
plutil -p "${minimal_probe_plist}" > "${diagnostics_dir}/minimal-probe-plist.plutil.txt"
plutil -lint "${executable_transplant_plist}" | tee "${diagnostics_dir}/executable-transplant-plutil-lint.txt"
plutil -p "${executable_transplant_plist}" > "${diagnostics_dir}/executable-transplant-plist.plutil.txt"
write_plist_inventory "${production_plist}" "${minimal_probe_plist}"

production_plist_hash="$(file_hash "${production_plist}")"
minimal_probe_plist_hash="$(file_hash "${minimal_probe_plist}")"
minimal_probe_pkginfo_hash="$(file_hash "${minimal_probe_pkginfo}")"
executable_transplant_plist_hash="$(file_hash "${executable_transplant_plist}")"
executable_transplant_pkginfo_hash="$(file_hash "${executable_transplant_pkginfo}")"
production_executable_hash="$(file_hash "${production_executable}")"
executable_transplant_executable_hash="$(file_hash "${executable_transplant_executable}")"

shasum -a 256 "${production_plist}" > "${diagnostics_dir}/production-plist-sha256.txt"
shasum -a 256 "${minimal_probe_plist}" > "${diagnostics_dir}/minimal-probe-plist-sha256.txt"
shasum -a 256 "${minimal_probe_pkginfo}" > "${diagnostics_dir}/minimal-probe-pkginfo-sha256.txt"
shasum -a 256 "${executable_transplant_plist}" > "${diagnostics_dir}/executable-transplant-plist-sha256.txt"
shasum -a 256 "${executable_transplant_pkginfo}" > "${diagnostics_dir}/executable-transplant-pkginfo-sha256.txt"

cmp -s "${minimal_probe_plist}" "${executable_transplant_plist}" \
    || fail "executable-transplant Info.plist differs from minimal-probe Info.plist"
cmp -s "${minimal_probe_pkginfo}" "${executable_transplant_pkginfo}" \
    || fail "executable-transplant PkgInfo differs from minimal-probe PkgInfo"
cmp -s "${production_executable}" "${executable_transplant_executable}" \
    || fail "executable-transplant executable differs from production executable"
if cmp -s "${production_plist}" "${minimal_probe_plist}"; then
    fail "production Info.plist unexpectedly matches minimal-probe Info.plist"
fi

[[ "$(file_mode "${executable_transplant_app}")" == "755" ]] \
    || fail "executable-transplant app directory mode is not 0755"
[[ "$(file_mode "${executable_transplant_executable}")" == "755" ]] \
    || fail "executable-transplant executable mode is not 0755"
[[ "$(file_mode "${executable_transplant_plist}")" == "644" ]] \
    || fail "executable-transplant Info.plist mode is not 0644"
[[ "$(file_mode "${executable_transplant_pkginfo}")" == "644" ]] \
    || fail "executable-transplant PkgInfo mode is not 0644"

inspect_macho "${production_executable}" "production-executable"
inspect_macho "${executable_transplant_executable}" "executable-transplant-executable"
[[ "$(cat "${diagnostics_dir}/production-executable-sdk.txt")" == "$(cat "${diagnostics_dir}/executable-transplant-executable-sdk.txt")" ]] \
    || fail "executable-transplant SDK differs from production executable"

cp -R "${executable_transplant_app}" "${staged_app}"
cp "${production_plist}" "${staged_app}/Info.plist"
find "${staged_app}" -type d -exec chmod 0755 {} +
chmod 0755 "${staged_app}/openmw"
chmod 0644 "${staged_app}/Info.plist" "${staged_app}/PkgInfo"

record_app_tree "${staged_app}" "staged-app"
cmp -s "${diagnostics_dir}/expected-files.txt" "${diagnostics_dir}/staged-app-tree-entries.txt" \
    || fail "staged transplant contains an unexpected path"
cmp -s "${diagnostics_dir}/expected-files.txt" "${diagnostics_dir}/staged-app-tree-files.txt" \
    || fail "staged transplant does not contain exactly three regular files"
test ! -s "${diagnostics_dir}/staged-app-tree-directories.txt" \
    || fail "staged transplant contains unexpected nested directories"

cmp -s "${production_plist}" "${staged_app}/Info.plist" \
    || fail "staged Info.plist differs from production Info.plist"
if cmp -s "${minimal_probe_plist}" "${staged_app}/Info.plist"; then
    fail "staged Info.plist unexpectedly matches minimal-probe Info.plist"
fi
cmp -s "${executable_transplant_pkginfo}" "${staged_app}/PkgInfo" \
    || fail "staged PkgInfo differs from executable-transplant PkgInfo"
cmp -s "${executable_transplant_executable}" "${staged_app}/openmw" \
    || fail "staged executable differs from executable-transplant executable"
cmp -s "${production_executable}" "${staged_app}/openmw" \
    || fail "staged executable differs from production executable"

for forbidden in defaults.bin openmw.cfg gamecontrollerdb.txt resources openmw-link.map embedded.mobileprovision _CodeSignature; do
    if find "${staged_app}" -name "${forbidden}" -print -quit | grep -q .; then
        fail "staged transplant contains forbidden path: ${forbidden}"
    fi
done
if find "${staged_app}" \( -name '*.framework' -o -name '*.dylib' -o -name '*.appex' -o -name '*.plugin' -o -name '*.bundle' -o -iname '*entitlements*' \) -print -quit | grep -q .; then
    fail "staged transplant contains unexpected code, bundle, or entitlements file"
fi

[[ "$(file_mode "${staged_app}")" == "755" ]] || fail "staged app directory mode is not 0755"
[[ "$(file_mode "${staged_app}/openmw")" == "755" ]] || fail "staged executable mode is not 0755"
[[ "$(file_mode "${staged_app}/Info.plist")" == "644" ]] || fail "staged Info.plist mode is not 0644"
[[ "$(file_mode "${staged_app}/PkgInfo")" == "644" ]] || fail "staged PkgInfo mode is not 0644"

require_unsigned_app "${staged_app}" "staged-app"
plutil -lint "${staged_app}/Info.plist" | tee "${diagnostics_dir}/staged-plutil-lint.txt"
plutil -p "${staged_app}/Info.plist" > "${diagnostics_dir}/staged-plist.plutil.txt"
inspect_macho "${staged_app}/openmw" "staged-executable"
[[ "$(cat "${diagnostics_dir}/staged-executable-sdk.txt")" == "$(cat "${diagnostics_dir}/production-executable-sdk.txt")" ]] \
    || fail "staged executable SDK differs from production executable"

staged_plist_hash="$(file_hash "${staged_app}/Info.plist")"
staged_pkginfo_hash="$(file_hash "${staged_app}/PkgInfo")"
staged_executable_hash="$(file_hash "${staged_app}/openmw")"
[[ "${staged_plist_hash}" == "${production_plist_hash}" ]]
[[ "${staged_plist_hash}" != "${minimal_probe_plist_hash}" ]]
[[ "${staged_pkginfo_hash}" == "${executable_transplant_pkginfo_hash}" ]]
[[ "${staged_executable_hash}" == "${executable_transplant_executable_hash}" ]]
[[ "${staged_executable_hash}" == "${production_executable_hash}" ]]

cat > "${diagnostics_dir}/comparison-manifest.txt" <<EOF_MANIFEST
production_app_path=$(relative_path "${production_app}")
production_info_plist_path=$(relative_path "${production_plist}")
production_executable_path=$(relative_path "${production_executable}")
minimal_probe_app_path=$(relative_path "${minimal_probe_app}")
minimal_probe_info_plist_path=$(relative_path "${minimal_probe_plist}")
minimal_probe_pkginfo_path=$(relative_path "${minimal_probe_pkginfo}")
executable_transplant_app_path=$(relative_path "${executable_transplant_app}")
executable_transplant_info_plist_path=$(relative_path "${executable_transplant_plist}")
executable_transplant_pkginfo_path=$(relative_path "${executable_transplant_pkginfo}")
executable_transplant_executable_path=$(relative_path "${executable_transplant_executable}")
staged_app_path=$(relative_path "${staged_app}")
staged_info_plist_path=$(relative_path "${staged_app}/Info.plist")
staged_pkginfo_path=$(relative_path "${staged_app}/PkgInfo")
staged_executable_path=$(relative_path "${staged_app}/openmw")
packaged_app_path=Payload/OpenMW.app
minimal_probe_info_plist_sha256=${minimal_probe_plist_hash}
minimal_probe_pkginfo_sha256=${minimal_probe_pkginfo_hash}
executable_transplant_info_plist_sha256=${executable_transplant_plist_hash}
production_info_plist_sha256=${production_plist_hash}
staged_info_plist_sha256=${staged_plist_hash}
executable_transplant_pkginfo_sha256=${executable_transplant_pkginfo_hash}
staged_pkginfo_sha256=${staged_pkginfo_hash}
production_executable_sha256=${production_executable_hash}
executable_transplant_executable_sha256=${executable_transplant_executable_hash}
staged_executable_sha256=${staged_executable_hash}
executable_transplant_file_count=$(wc -l < "${diagnostics_dir}/executable-transplant-app-tree-files.txt" | tr -d ' ')
staged_file_count=$(wc -l < "${diagnostics_dir}/staged-app-tree-files.txt" | tr -d ' ')
executable_transplant_app_mode=$(file_mode "${executable_transplant_app}")
staged_app_mode=$(file_mode "${staged_app}")
executable_transplant_info_plist_mode=$(file_mode "${executable_transplant_plist}")
staged_info_plist_mode=$(file_mode "${staged_app}/Info.plist")
executable_transplant_pkginfo_mode=$(file_mode "${executable_transplant_pkginfo}")
staged_pkginfo_mode=$(file_mode "${staged_app}/PkgInfo")
executable_transplant_executable_mode=$(file_mode "${executable_transplant_executable}")
staged_executable_mode=$(file_mode "${staged_app}/openmw")
executable_transplant_info_plist_size=$(file_size "${executable_transplant_plist}")
staged_info_plist_size=$(file_size "${staged_app}/Info.plist")
executable_transplant_pkginfo_size=$(file_size "${executable_transplant_pkginfo}")
staged_pkginfo_size=$(file_size "${staged_app}/PkgInfo")
executable_transplant_executable_size=$(file_size "${executable_transplant_executable}")
staged_executable_size=$(file_size "${staged_app}/openmw")
EOF_MANIFEST

package_root="$(mktemp -d "${TMPDIR:-/tmp}/openmw-production-plist-transplant-package.XXXXXX")"
mkdir -p "${package_root}/Payload"
cp -R "${staged_app}" "${package_root}/Payload/OpenMW.app"
find "${package_root}/Payload" -type d -exec chmod 0755 {} +
chmod 0755 "${package_root}/Payload/OpenMW.app/openmw"
chmod 0644 "${package_root}/Payload/OpenMW.app/Info.plist" "${package_root}/Payload/OpenMW.app/PkgInfo"

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

verification_root="$(mktemp -d "${TMPDIR:-/tmp}/openmw-production-plist-transplant-verify.XXXXXX")"
unzip -q "${ipa_path}" -d "${verification_root}"
extracted_app="${verification_root}/Payload/OpenMW.app"

find "${verification_root}/Payload" -type d -name '*.app' -prune -print | LC_ALL=C sort \
    > "${diagnostics_dir}/packaged-app-paths.txt"
test "$(wc -l < "${diagnostics_dir}/packaged-app-paths.txt" | tr -d ' ')" = "1"
test "$(cat "${diagnostics_dir}/packaged-app-paths.txt")" = "${extracted_app}"
record_app_tree "${extracted_app}" "packaged-app"
cmp -s "${diagnostics_dir}/expected-files.txt" "${diagnostics_dir}/packaged-app-tree-entries.txt" \
    || fail "packaged transplant contains an unexpected path"
cmp -s "${diagnostics_dir}/expected-files.txt" "${diagnostics_dir}/packaged-app-tree-files.txt" \
    || fail "packaged transplant does not contain exactly three regular files"
test ! -s "${diagnostics_dir}/packaged-app-tree-directories.txt" \
    || fail "packaged transplant contains unexpected nested directories"

cmp -s "${production_plist}" "${extracted_app}/Info.plist" \
    || fail "packaged Info.plist differs from production Info.plist"
cmp -s "${executable_transplant_pkginfo}" "${extracted_app}/PkgInfo" \
    || fail "packaged PkgInfo differs from executable-transplant PkgInfo"
cmp -s "${production_executable}" "${extracted_app}/openmw" \
    || fail "packaged executable differs from production executable"

[[ "$(file_mode "${verification_root}/Payload")" == "755" ]] || fail "packaged Payload directory mode is not 0755"
[[ "$(file_mode "${extracted_app}")" == "755" ]] || fail "packaged app directory mode is not 0755"
[[ "$(file_mode "${extracted_app}/openmw")" == "755" ]] || fail "packaged executable mode is not 0755"
[[ "$(file_mode "${extracted_app}/Info.plist")" == "644" ]] || fail "packaged Info.plist mode is not 0644"
[[ "$(file_mode "${extracted_app}/PkgInfo")" == "644" ]] || fail "packaged PkgInfo mode is not 0644"

require_unsigned_app "${extracted_app}" "packaged-app"
plutil -lint "${extracted_app}/Info.plist" | tee "${diagnostics_dir}/packaged-plutil-lint.txt"
plutil -p "${extracted_app}/Info.plist" > "${diagnostics_dir}/packaged-plist.plutil.txt"
inspect_macho "${extracted_app}/openmw" "packaged-executable"
[[ "$(cat "${diagnostics_dir}/packaged-executable-sdk.txt")" == "$(cat "${diagnostics_dir}/production-executable-sdk.txt")" ]] \
    || fail "packaged executable SDK differs from production executable"

packaged_plist_hash="$(file_hash "${extracted_app}/Info.plist")"
packaged_pkginfo_hash="$(file_hash "${extracted_app}/PkgInfo")"
packaged_executable_hash="$(file_hash "${extracted_app}/openmw")"
[[ "${packaged_plist_hash}" == "${production_plist_hash}" ]]
[[ "${packaged_pkginfo_hash}" == "${executable_transplant_pkginfo_hash}" ]]
[[ "${packaged_executable_hash}" == "${production_executable_hash}" ]]

cat >> "${diagnostics_dir}/comparison-manifest.txt" <<EOF_MANIFEST
packaged_info_plist_sha256=${packaged_plist_hash}
packaged_pkginfo_sha256=${packaged_pkginfo_hash}
packaged_executable_sha256=${packaged_executable_hash}
packaged_file_count=$(wc -l < "${diagnostics_dir}/packaged-app-tree-files.txt" | tr -d ' ')
packaged_app_mode=$(file_mode "${extracted_app}")
packaged_info_plist_mode=$(file_mode "${extracted_app}/Info.plist")
packaged_pkginfo_mode=$(file_mode "${extracted_app}/PkgInfo")
packaged_executable_mode=$(file_mode "${extracted_app}/openmw")
packaged_info_plist_size=$(file_size "${extracted_app}/Info.plist")
packaged_pkginfo_size=$(file_size "${extracted_app}/PkgInfo")
packaged_executable_size=$(file_size "${extracted_app}/openmw")
only_info_plist_bytes_changed_relative_to_executable_transplant=true
pkginfo_did_not_change=true
executable_did_not_change=true
no_other_file_exists=true
EOF_MANIFEST

shasum -a 256 "${ipa_path}" | tee "${diagnostics_dir}/ipa-sha256.txt"
shasum -a 256 "${staged_app}/Info.plist" "${staged_app}/PkgInfo" "${staged_app}/openmw" \
    > "${diagnostics_dir}/staged-file-sha256.txt"
shasum -a 256 "${extracted_app}/Info.plist" "${extracted_app}/PkgInfo" "${extracted_app}/openmw" \
    > "${diagnostics_dir}/packaged-file-sha256.txt"

cp -R "${staged_app}" "${inspection_app}"

printf 'Production Info.plist transplant packaged successfully\n'
printf 'IPA: %s\n' "${ipa_path}"
printf 'Production Info.plist SHA-256: %s\n' "${production_plist_hash}"
printf 'PkgInfo SHA-256: %s\n' "${staged_pkginfo_hash}"
printf 'OpenMW executable SHA-256: %s\n' "${staged_executable_hash}"
