#!/usr/bin/env python3

import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
TRIPLET = os.environ.get("VCPKG_TRIPLET", "arm64-ios-openmw-release")
DEPLOYMENT = os.environ.get("IOS_DEPLOYMENT_TARGET", "16.3")


def run(*args: str) -> str:
    return subprocess.run(args, check=False, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT).stdout.strip()


def file_hash(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def configuration_fingerprint() -> str:
    digest = hashlib.sha256()
    paths = [
        ROOT / "versions.env",
        ROOT / "vcpkg.json",
        ROOT / "triplets" / "arm64-ios-openmw-release.cmake",
    ]
    paths += sorted((ROOT / "scripts").glob("*"))
    paths += sorted((ROOT / "patches").glob("**/*.patch"))
    paths += sorted((ROOT / "ios").glob("**/*"))
    for path in paths:
        if path.is_file():
            digest.update(str(path.relative_to(ROOT)).encode())
            digest.update(path.read_bytes())
    return digest.hexdigest()


def source_revisions() -> dict[str, str]:
    revisions = {}
    for line in (ROOT / "versions.env").read_text().splitlines():
        match = re.match(r"([A-Z0-9_]+)_REVISION=['\"]?([^'\" ]+)", line)
        if match:
            revisions[match.group(1).lower()] = match.group(2)
    return revisions


def package_features() -> list[dict[str, object]]:
    status = ROOT / "build" / "vcpkg_installed" / "vcpkg" / "status"
    if not status.exists():
        return []
    packages = []
    for paragraph in status.read_text(errors="replace").split("\n\n"):
        fields = {}
        for line in paragraph.splitlines():
            if ": " in line:
                key, value = line.split(": ", 1)
                fields[key] = value
        if fields.get("Package"):
            packages.append({
                "name": fields["Package"],
                "version": fields.get("Version", ""),
                "architecture": fields.get("Architecture", ""),
                "feature": fields.get("Feature", "core"),
            })
    return packages


roots = [
    ROOT / "build" / "vcpkg_installed" / TRIPLET / "lib",
    ROOT / "build" / "prefix" / TRIPLET / "lib",
    ROOT / "build" / "ios",
]
archives = sorted({path.resolve() for root in roots if root.exists() for path in root.rglob("*.a")})
records = []
violations = []
for archive in archives:
    architectures = run("xcrun", "lipo", "-archs", str(archive)).split()
    load_commands = run("xcrun", "otool", "-l", str(archive))
    platforms = sorted(set(re.findall(r"^\s+platform\s+([0-9]+)", load_commands, re.MULTILINE)))
    if not platforms and "LC_VERSION_MIN_IPHONEOS" in load_commands:
        platforms = ["2"]
    minimum_versions = sorted(set(re.findall(r"^\s+minos\s+([0-9.]+)", load_commands, re.MULTILINE)))
    if not minimum_versions:
        minimum_versions = sorted(set(re.findall(
            r"LC_VERSION_MIN_IPHONEOS(?:.|\n)*?\n\s+version\s+([0-9.]+)",
            load_commands, re.MULTILINE)))
    record = {
        "path": str(archive.relative_to(ROOT)),
        "sha256": file_hash(archive),
        "architecture": architectures,
        "platforms": platforms,
        "deployment_targets": minimum_versions,
        "configuration": "Release",
        "triplet": TRIPLET,
    }
    records.append(record)
    if architectures != ["arm64"]:
        violations.append(f"{record['path']}: architectures={architectures}")
    if platforms != ["2"]:
        violations.append(f"{record['path']}: platforms={platforms}, expected iOS device platform 2")
    if not minimum_versions or any(version != DEPLOYMENT for version in minimum_versions):
        violations.append(f"{record['path']}: deployment_targets={minimum_versions}")

inventory = {
    "schema": 1,
    "configuration_fingerprint": configuration_fingerprint(),
    "target": {"architecture": "arm64", "platform": "iOS-device", "deployment_target": DEPLOYMENT},
    "toolchain": {
        "xcode": run("xcodebuild", "-version"),
        "iphoneos_sdk": run("xcrun", "--sdk", "iphoneos", "--show-sdk-version"),
        "cmake": run("cmake", "--version").splitlines()[0],
    },
    "source_revisions": source_revisions(),
    "packages": package_features(),
    "archives": records,
    "violations": violations,
}
output = ROOT / "build" / "diagnostics" / "dependency-inventory.json"
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(inventory, indent=2, sort_keys=True) + "\n")
print(f"Wrote {output} with {len(records)} archives.")
if violations:
    print("\n".join(f"error: {item}" for item in violations), file=sys.stderr)
    sys.exit(1)
