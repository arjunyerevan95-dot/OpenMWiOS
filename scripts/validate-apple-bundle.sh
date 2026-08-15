#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

APP_PATH="$1"
OUTPUT_DIR="$2"
EXPECTED_IDENTIFIER="${3:-${PRODUCT_BUNDLE_IDENTIFIER:-org.openmw.ios}}"
INFO_PLIST="${APP_PATH}/Info.plist"
EXECUTABLE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "${INFO_PLIST}")"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/openmw-bundle-validation.XXXXXX")"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

mkdir -p "${OUTPUT_DIR}"
plutil -lint "${INFO_PLIST}" | tee "${OUTPUT_DIR}/plutil-lint.txt"
find "${APP_PATH}" -mindepth 1 -maxdepth 1 -print \
    | LC_ALL=C sort > "${OUTPUT_DIR}/top-level-entries.txt"

xcrun swiftc "${ROOT_DIR}/validation/BundleProbe.swift" \
    -o "${TEMP_ROOT}/BundleProbe"
"${TEMP_ROOT}/BundleProbe" corrected "${APP_PATH}" \
    "${OUTPUT_DIR}/corrected.json"

mkdir -p "${TEMP_ROOT}/reciprocal"
/usr/bin/ditto "${APP_PATH}" "${TEMP_ROOT}/reciprocal/OpenMW.app"
mkdir "${TEMP_ROOT}/reciprocal/OpenMW.app/resources"
"${TEMP_ROOT}/BundleProbe" reciprocal-with-resources-collision \
    "${TEMP_ROOT}/reciprocal/OpenMW.app" \
    "${OUTPUT_DIR}/reciprocal-with-resources-collision.json"

python3 - "${OUTPUT_DIR}" "${EXPECTED_IDENTIFIER}" "${EXECUTABLE_NAME}" <<'PY'
import json
import os
import sys

output_dir, expected_identifier, executable_name = sys.argv[1:]
with open(os.path.join(output_dir, "corrected.json"), encoding="utf-8") as stream:
    corrected = json.load(stream)
with open(
    os.path.join(output_dir, "reciprocal-with-resources-collision.json"), encoding="utf-8"
) as stream:
    reciprocal = json.load(stream)

expected_suffix = "/" + executable_name
checks = {
    "foundation_bundle_created": corrected.get("foundationBundleCreated") is True,
    "foundation_identifier": corrected.get("foundationBundleIdentifier") == expected_identifier,
    "foundation_executable": str(corrected.get("foundationExecutableURL", "")).endswith(expected_suffix),
    "foundation_info_dictionary": bool(corrected.get("foundationInfoDictionary")),
    "cf_bundle_created": corrected.get("cfBundleCreated") is True,
    "cf_identifier": corrected.get("cfBundleIdentifier") == expected_identifier,
    "cf_executable": str(corrected.get("cfBundleExecutableURL", "")).endswith(expected_suffix),
    "cf_info_dictionary": bool(corrected.get("cfBundleInfoDictionary")),
    "reciprocal_foundation_identifier_nil": reciprocal.get("foundationBundleIdentifier") is None,
    "reciprocal_foundation_executable_nil": reciprocal.get("foundationExecutableURL") is None,
    "reciprocal_cf_identifier_nil": reciprocal.get("cfBundleIdentifier") is None,
    "reciprocal_cf_executable_nil": reciprocal.get("cfBundleExecutableURL") is None,
}
summary = {
    "expected_identifier": expected_identifier,
    "expected_executable": executable_name,
    "checks": checks,
    "qualified": all(checks.values()),
}
with open(os.path.join(output_dir, "summary.json"), "w", encoding="utf-8", newline="\n") as stream:
    json.dump(summary, stream, indent=2, sort_keys=True)
    stream.write("\n")
print(json.dumps(summary, indent=2, sort_keys=True))
if not summary["qualified"]:
    raise SystemExit(1)
PY

echo "Apple Foundation/CoreFoundation bundle validation and reciprocal collision test passed."
