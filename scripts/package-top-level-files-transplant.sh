#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
diag="${repo_root}/build/diagnostics/top-level-files-transplant"
staging="${repo_root}/build/top-level-files-transplant"
staged_app="${staging}/OpenMW.app"
out="${repo_root}/build/top-level-files-transplant-artifacts"
ipa="${out}/OpenMW-iOS-top-level-files-transplant-unsigned.ipa"
inspection_app="${out}/OpenMW.app"
package_root=""
verify_root=""

cleanup() {
    [[ -z "${package_root}" ]] || rm -rf "${package_root}"
    [[ -z "${verify_root}" ]] || rm -rf "${verify_root}"
}
trap cleanup EXIT

fail() { echo "error: $*" >&2; exit 1; }
rel() { printf '%s\n' "${1#"${repo_root}/"}"; }
mode() { stat -f '%Lp' "$1"; }
hash() { shasum -a 256 "$1" | awk '{print $1}'; }

single_app() {
    local root="$1" name="$2" label="$3" list="${diag}/${label}-candidates.txt" count
    find "${root}" -type d -name "${name}" -prune -print 2>/dev/null | LC_ALL=C sort > "${list}"
    count="$(wc -l < "${list}" | tr -d ' ')"
    [[ "${count}" == 1 ]] || fail "expected exactly one ${label}, found ${count}"
    cat "${list}"
}

unsigned_app() {
    local app="$1" label="$2"
    [[ ! -e "${app}/embedded.mobileprovision" ]] || fail "${label} contains embedded.mobileprovision"
    [[ ! -d "${app}/_CodeSignature" ]] || fail "${label} contains _CodeSignature"
    if codesign -d --verbose=4 "${app}" > "${diag}/${label}-codesign.txt" 2>&1; then
        fail "${label} unexpectedly has a code signature"
    fi
}

inspect_macho() {
    local exe="$1" label="$2" platform minos sdk otool_file="${diag}/${label}-otool.txt"
    file "${exe}" | tee "${diag}/${label}-file.txt"
    lipo -info "${exe}" | tee "${diag}/${label}-lipo.txt"
    otool -l "${exe}" > "${otool_file}"
    stat -f '%Lp\t%z\t%N' "${exe}" > "${diag}/${label}-mode-size.txt"
    shasum -a 256 "${exe}" > "${diag}/${label}-sha256.txt"
    grep -Eq 'arm64' "${diag}/${label}-lipo.txt" || fail "${label} is not arm64"
    ! grep -q 'LC_CODE_SIGNATURE' "${otool_file}" || fail "${label} contains LC_CODE_SIGNATURE"
    platform="$(awk '/cmd LC_BUILD_VERSION/{p=1;next} p&&$1=="platform"{print $2;exit}' "${otool_file}")"
    minos="$(awk '/cmd LC_BUILD_VERSION/{p=1;next} p&&$1=="minos"{print $2;exit}' "${otool_file}")"
    sdk="$(awk '/cmd LC_BUILD_VERSION/{p=1;next} p&&$1=="sdk"{print $2;exit}' "${otool_file}")"
    if [[ -z "${platform}" ]]; then
        grep -q 'LC_VERSION_MIN_IPHONEOS' "${otool_file}" || fail "${label} is not iPhoneOS"
        platform=2
        minos="$(awk '/cmd LC_VERSION_MIN_IPHONEOS/{p=1;next} p&&$1=="version"{print $2;exit}' "${otool_file}")"
        sdk="$(awk '/cmd LC_VERSION_MIN_IPHONEOS/{p=1;next} p&&$1=="sdk"{print $2;exit}' "${otool_file}")"
    fi
    printf '%s\n' "${platform}" > "${diag}/${label}-platform.txt"
    printf '%s\n' "${minos}" > "${diag}/${label}-minimum-os.txt"
    printf '%s\n' "${sdk}" > "${diag}/${label}-sdk.txt"
    [[ "${platform}" == 2 || "${platform}" == IOS ]] || fail "${label} is not iOS device platform"
    [[ "${minos}" == 16.3 ]] || fail "${label} minimum OS is ${minos}, expected 16.3"
}

rm -rf "${staging}" "${out}"
mkdir -p "${diag}" "${staging}" "${out}"

production_app="$(single_app "${repo_root}/build/device" openmw.app production-app)"
minimal_app="$(single_app "${repo_root}/build/bundle-probe" OpenMW.app minimal-probe-app)"
executable_app="$(single_app "${repo_root}/build/executable-transplant-artifacts" OpenMW.app executable-transplant-app)"
plist_app="$(single_app "${repo_root}/build/production-plist-transplant-artifacts" OpenMW.app production-plist-transplant-app)"

for item in \
    "production_app=${production_app}" \
    "minimal_probe_app=${minimal_app}" \
    "executable_transplant_app=${executable_app}" \
    "production_plist_transplant_app=${plist_app}" \
    "staged_app=${staged_app}" \
    "ipa=${ipa}"; do
    printf '%s\n' "${item%%=*}=$(rel "${item#*=}")"
done > "${diag}/paths.txt"

python3 - "${repo_root}" "${diag}" "${production_app}" "${minimal_app}" "${executable_app}" "${plist_app}" <<'PY'
import hashlib, os, pathlib, stat, sys
root, diag, production, minimal, executable, plist = map(pathlib.Path, sys.argv[1:])
loose = ["defaults.bin", "openmw.cfg", "gamecontrollerdb.txt", "openmw-link.map"]
retained = ["Info.plist", "PkgInfo", "openmw"]
expected = sorted(retained + loose)

def fail(msg): raise SystemExit(f"error: {msg}")
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def mode(p): return stat.S_IMODE(p.stat().st_mode)
def rel(p): return str(p.relative_to(root))
def files(app): return sorted(str(p.relative_to(app)) for p in app.rglob('*') if p.is_file())
def dirs(app): return sorted(str(p.relative_to(app)) for p in app.rglob('*') if p.is_dir())
def record_tree(app, label):
    (diag/f"{label}-tree.txt").write_text("\n".join(["OpenMW.app"]+[f"OpenMW.app/{x}" for x in files(app)+dirs(app)])+"\n")
    (diag/f"{label}-files.txt").write_text("\n".join(files(app))+"\n")
    (diag/f"{label}-directories.txt").write_text("\n".join(dirs(app))+("\n" if dirs(app) else ""))
    rows=["path\tsha256\tsize\tmode"]
    for name in files(app):
        p=app/name; rows.append(f"{name}\t{sha(p)}\t{p.stat().st_size}\t{mode(p):04o}")
    (diag/f"{label}-inventory.tsv").write_text("\n".join(rows)+"\n")

for app,label in [(production,"production-app"),(plist,"production-plist-transplant-app")]: record_tree(app,label)
(diag/"production-top-level.txt").write_text("\n".join(sorted(p.name for p in production.iterdir()))+"\n")
if files(plist) != sorted(retained) or dirs(plist): fail("production-plist transplant is not the exact three-file app")
for name in loose+["resources"]:
    if (plist/name).exists(): fail(f"production-plist transplant unexpectedly contains {name}")
for name in expected:
    if not (production/name).is_file(): fail(f"production app is missing {name}")
resources=production/"resources"
if not resources.is_dir(): fail("production resources directory is missing")
resource_files=sorted(p for p in resources.rglob('*') if p.is_file())
resource_rows=[f"{p.relative_to(resources)}\t{sha(p)}" for p in resource_files]
(diag/"production-resources-path.txt").write_text(rel(resources)+"\n")
(diag/"production-resources-file-count.txt").write_text(str(len(resource_files))+"\n")
(diag/"production-resources-tree.txt").write_text("resources\n"+"\n".join(f"resources/{p.relative_to(resources)}" for p in resource_files)+"\n")
resource_inventory="\n".join(resource_rows)+"\n"
(diag/"production-resources-inventory.tsv").write_text(resource_inventory)
(diag/"production-resources-tree-sha256.txt").write_text(hashlib.sha256(resource_inventory.encode()).hexdigest()+"\n")

pkg=[("production",production/"PkgInfo"),("minimal-probe",minimal/"PkgInfo"),("executable-transplant",executable/"PkgInfo"),("production-plist-transplant",plist/"PkgInfo")]
rows=["label\tpath\tsize\tsha256\thex"]
base=None
for label,p in pkg:
    if not p.is_file(): fail(f"{label} PkgInfo is missing")
    data=p.read_bytes()
    (diag/f"{label}-pkginfo-bytes.bin").write_bytes(data)
    (diag/f"{label}-pkginfo-hex.txt").write_text(data.hex()+"\n")
    rows.append(f"{label}\t{rel(p)}\t{len(data)}\t{sha(p)}\t{data.hex()}")
    if len(data)!=8: fail(f"{label} PkgInfo is {len(data)} bytes, expected 8")
    if base is None: base=data
    elif data!=base: fail(f"production PkgInfo differs from {label} PkgInfo")
(diag/"pkginfo-comparison.tsv").write_text("\n".join(rows)+"\n")
(diag/"pkginfo-comparison-conclusion.txt").write_text("PkgInfo equality precondition passed\n")
if (production/"Info.plist").read_bytes() != (plist/"Info.plist").read_bytes(): fail("production-plist Info.plist differs from production")
if (production/"openmw").read_bytes() != (plist/"openmw").read_bytes(): fail("production-plist executable differs from production")
PY

for app_label in \
    "${production_app}:production-app" \
    "${minimal_app}:minimal-probe-app" \
    "${executable_app}:executable-transplant-app" \
    "${plist_app}:production-plist-transplant-app"; do
    unsigned_app "${app_label%%:*}" "${app_label#*:}"
done
plutil -lint "${production_app}/Info.plist" | tee "${diag}/production-plutil-lint.txt"
plutil -p "${production_app}/Info.plist" > "${diag}/production-plist.txt"
inspect_macho "${production_app}/openmw" production-executable
inspect_macho "${plist_app}/openmw" production-plist-transplant-executable
cmp -s "${diag}/production-executable-sdk.txt" "${diag}/production-plist-transplant-executable-sdk.txt" || fail "production-plist SDK differs"

cp -R "${plist_app}" "${staged_app}"
for name in defaults.bin openmw.cfg gamecontrollerdb.txt openmw-link.map; do cp "${production_app}/${name}" "${staged_app}/${name}"; done
find "${staged_app}" -type d -exec chmod 0755 {} +
chmod 0755 "${staged_app}/openmw"
chmod 0644 "${staged_app}/Info.plist" "${staged_app}/PkgInfo" "${staged_app}/defaults.bin" "${staged_app}/openmw.cfg" "${staged_app}/gamecontrollerdb.txt" "${staged_app}/openmw-link.map"

python3 - "${repo_root}" "${diag}" "${production_app}" "${plist_app}" "${staged_app}" <<'PY'
import hashlib, pathlib, stat, sys
root,diag,production,plist,staged=map(pathlib.Path,sys.argv[1:])
expected=sorted(["Info.plist","PkgInfo","openmw","defaults.bin","openmw.cfg","gamecontrollerdb.txt","openmw-link.map"])
def fail(m): raise SystemExit(f"error: {m}")
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def mode(p): return stat.S_IMODE(p.stat().st_mode)
def rel(p): return str(p.relative_to(root))
def names(app,kind): return sorted(str(p.relative_to(app)) for p in app.rglob('*') if getattr(p,kind)())
files=names(staged,"is_file"); dirs=names(staged,"is_dir")
if files!=expected or dirs: fail("staged app is not the exact seven-file flat app")
if (staged/"resources").exists(): fail("staged app contains resources")
for name in ["Info.plist","PkgInfo","openmw"]:
    if (staged/name).read_bytes()!=(plist/name).read_bytes(): fail(f"staged {name} changed")
for name in ["defaults.bin","openmw.cfg","gamecontrollerdb.txt","openmw-link.map"]:
    if (staged/name).read_bytes()!=(production/name).read_bytes(): fail(f"staged {name} differs from production")
if mode(staged)!=0o755 or mode(staged/"openmw")!=0o755: fail("staged directory/executable mode differs")
for name in expected:
    if name!="openmw" and mode(staged/name)!=0o644: fail(f"staged {name} mode differs")
(diag/"expected-files.txt").write_text("\n".join(expected)+"\n")
(diag/"staged-tree.txt").write_text("OpenMW.app\n"+"\n".join(f"OpenMW.app/{x}" for x in files)+"\n")
rows=["name\tproduction_path\tproduction_sha256\tproduction_size\tproduction_mode\tplist_transplant_path\tplist_transplant_sha256\tstaged_path\tstaged_sha256\tstaged_size\tstaged_mode\tchange"]
for name in expected:
    p=production/name; t=plist/name; s=staged/name
    present=t.is_file()
    rows.append("\t".join([name,rel(p),sha(p),str(p.stat().st_size),f"{mode(p):04o}",rel(t) if present else "absent",sha(t) if present else "absent",rel(s),sha(s),str(s.stat().st_size),f"{mode(s):04o}","retained-byte-identical" if present else "added-from-production"]))
(diag/"comparison-manifest.tsv").write_text("\n".join(rows)+"\n")
(diag/"comparison-conclusions.txt").write_text("metadata_did_not_change=true\nexecutable_did_not_change=true\nexactly_four_loose_files_added=true\nadded_files=defaults.bin,openmw.cfg,gamecontrollerdb.txt,openmw-link.map\nresources_was_not_copied=true\nno_eighth_file_exists=true\npkginfo_all_four_inputs_byte_identical=true\nstaged_file_count=7\n")
PY

unsigned_app "${staged_app}" staged-app
plutil -lint "${staged_app}/Info.plist" | tee "${diag}/staged-plutil-lint.txt"
inspect_macho "${staged_app}/openmw" staged-executable
cmp -s "${diag}/production-executable-sdk.txt" "${diag}/staged-executable-sdk.txt" || fail "staged SDK differs"

package_root="$(mktemp -d "${TMPDIR:-/tmp}/openmw-top-level-files-package.XXXXXX")"
mkdir -p "${package_root}/Payload"
cp -R "${staged_app}" "${package_root}/Payload/OpenMW.app"
find "${package_root}/Payload" -type d -exec chmod 0755 {} +
chmod 0755 "${package_root}/Payload/OpenMW.app/openmw"
find "${package_root}/Payload/OpenMW.app" -type f ! -name openmw -exec chmod 0644 {} +
(cd "${package_root}" && COPYFILE_DISABLE=1 /usr/bin/zip -X -q -r "${ipa}" Payload)

unzip -t "${ipa}" | tee "${diag}/ipa-integrity.txt"
unzip -l "${ipa}" > "${diag}/ipa-listing.txt"
unzip -Z1 "${ipa}" > "${diag}/ipa-paths.txt"
zipinfo -l "${ipa}" > "${diag}/ipa-permissions.txt"
cat > "${diag}/expected-ipa-paths.txt" <<'PATHS'
Payload/
Payload/OpenMW.app/
Payload/OpenMW.app/Info.plist
Payload/OpenMW.app/PkgInfo
Payload/OpenMW.app/defaults.bin
Payload/OpenMW.app/gamecontrollerdb.txt
Payload/OpenMW.app/openmw
Payload/OpenMW.app/openmw-link.map
Payload/OpenMW.app/openmw.cfg
PATHS
LC_ALL=C sort "${diag}/ipa-paths.txt" > "${diag}/ipa-paths.sorted.txt"
LC_ALL=C sort "${diag}/expected-ipa-paths.txt" > "${diag}/expected-ipa-paths.sorted.txt"
cmp -s "${diag}/ipa-paths.sorted.txt" "${diag}/expected-ipa-paths.sorted.txt" || fail "IPA path set differs"

verify_root="$(mktemp -d "${TMPDIR:-/tmp}/openmw-top-level-files-verify.XXXXXX")"
unzip -q "${ipa}" -d "${verify_root}"
packaged_app="${verify_root}/Payload/OpenMW.app"
python3 - "${diag}" "${staged_app}" "${packaged_app}" <<'PY'
import hashlib,pathlib,stat,sys
diag,staged,packaged=map(pathlib.Path,sys.argv[1:])
expected=sorted(["Info.plist","PkgInfo","openmw","defaults.bin","openmw.cfg","gamecontrollerdb.txt","openmw-link.map"])
def fail(m): raise SystemExit(f"error: {m}")
def files(a): return sorted(str(p.relative_to(a)) for p in a.rglob('*') if p.is_file())
def dirs(a): return sorted(str(p.relative_to(a)) for p in a.rglob('*') if p.is_dir())
def mode(p): return stat.S_IMODE(p.stat().st_mode)
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
if files(packaged)!=expected or dirs(packaged): fail("packaged app is not the exact seven-file flat app")
if (packaged/"resources").exists(): fail("packaged app contains resources")
rows=["name\tsha256\tsize\tmode"]
for name in expected:
    if (staged/name).read_bytes()!=(packaged/name).read_bytes(): fail(f"packaged {name} differs")
    rows.append(f"{name}\t{sha(packaged/name)}\t{(packaged/name).stat().st_size}\t{mode(packaged/name):04o}")
if mode(packaged)!=0o755 or mode(packaged/"openmw")!=0o755: fail("packaged directory/executable mode differs")
for name in expected:
    if name!="openmw" and mode(packaged/name)!=0o644: fail(f"packaged {name} mode differs")
(diag/"packaged-tree.txt").write_text("Payload/OpenMW.app\n"+"\n".join(f"Payload/OpenMW.app/{x}" for x in expected)+"\n")
(diag/"packaged-file-inventory.tsv").write_text("\n".join(rows)+"\n")
with (diag/"comparison-conclusions.txt").open("a") as f:
    f.write("packaged_file_count=7\npackaged_metadata_did_not_change=true\npackaged_executable_did_not_change=true\npackaged_exactly_four_loose_files_added=true\npackaged_resources_was_not_copied=true\npackaged_no_eighth_file_exists=true\n")
PY

[[ "$(mode "${verify_root}/Payload")" == 755 ]] || fail "packaged Payload mode differs"
unsigned_app "${packaged_app}" packaged-app
plutil -lint "${packaged_app}/Info.plist" | tee "${diag}/packaged-plutil-lint.txt"
inspect_macho "${packaged_app}/openmw" packaged-executable
cmp -s "${diag}/production-executable-sdk.txt" "${diag}/packaged-executable-sdk.txt" || fail "packaged SDK differs"
shasum -a 256 "${ipa}" | tee "${diag}/ipa-sha256.txt"
find "${staged_app}" -type f -exec shasum -a 256 {} + | LC_ALL=C sort > "${diag}/staged-file-sha256.txt"
find "${packaged_app}" -type f -exec shasum -a 256 {} + | LC_ALL=C sort > "${diag}/packaged-file-sha256.txt"
cp -R "${staged_app}" "${inspection_app}"
printf 'Top-level bundle files transplant packaged successfully\nIPA: %s\n' "${ipa}"
