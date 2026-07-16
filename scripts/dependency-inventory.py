#!/usr/bin/env python3

import argparse
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
from dataclasses import dataclass

ROOT = pathlib.Path(__file__).resolve().parents[1]
DEFAULT_TRIPLET = os.environ.get("VCPKG_TRIPLET", "arm64-ios-openmw-release")
DEFAULT_DEPLOYMENT = os.environ.get("IOS_DEPLOYMENT_TARGET", "16.3")
DEFAULT_CONFIGURATION = os.environ.get("CONFIGURATION", "Release")


@dataclass(frozen=True)
class ManifestEntry:
    kind: str
    origin: str
    name: str
    path: pathlib.Path


def run(*args: str) -> str:
    return subprocess.run(args, check=False, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT).stdout.strip()


def inspect(path: pathlib.Path, *args: str) -> tuple[str, str | None]:
    result = subprocess.run(args, check=False, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT)
    output = result.stdout.strip()
    if result.returncode == 0:
        return output, None
    detail = output.splitlines()[-1] if output else f"exit code {result.returncode}"
    return output, f"{path}: {' '.join(args[:2])} failed: {detail}"


def file_hash(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def display_path(path: pathlib.Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


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


def read_product_manifest(path: pathlib.Path) -> list[ManifestEntry]:
    lines = path.read_text().splitlines()
    if not lines or lines[0] != "kind\torigin\tname\tpath":
        raise ValueError(f"{path}: invalid product manifest header")
    entries = []
    for line_number, line in enumerate(lines[1:], start=2):
        if not line:
            continue
        fields = line.split("\t")
        if len(fields) != 4:
            raise ValueError(f"{path}:{line_number}: expected four tab-separated fields")
        kind, origin, name, raw_path = fields
        if kind not in {"archive", "directory"}:
            raise ValueError(f"{path}:{line_number}: unsupported product kind '{kind}'")
        if not origin or not name or not raw_path:
            raise ValueError(f"{path}:{line_number}: empty product manifest field")
        product_path = pathlib.Path(raw_path)
        if not product_path.is_absolute():
            product_path = ROOT / product_path
        entries.append(ManifestEntry(kind, origin, name, product_path.resolve()))
    return entries


def resolve_product_manifest(
        entries: list[ManifestEntry]) -> tuple[dict[pathlib.Path, list[dict[str, str]]], list[str]]:
    products: dict[pathlib.Path, list[dict[str, str]]] = {}
    violations: list[str] = []

    def include(path: pathlib.Path, entry: ManifestEntry) -> None:
        resolved = path.resolve()
        reason = {"kind": entry.kind, "origin": entry.origin, "name": entry.name}
        reasons = products.setdefault(resolved, [])
        if reason not in reasons:
            reasons.append(reason)
            reasons.sort(key=lambda item: (item["origin"], item["name"], item["kind"]))

    for entry in entries:
        if entry.kind == "archive":
            if not entry.path.is_file():
                violations.append(
                    f"missing expected {entry.origin} archive '{entry.name}': {display_path(entry.path)}")
                continue
            if entry.path.suffix != ".a":
                violations.append(
                    f"expected archive '{entry.name}' is not a .a file: {display_path(entry.path)}")
                continue
            include(entry.path, entry)
            continue

        if not entry.path.is_dir():
            violations.append(
                f"missing expected {entry.origin} directory '{entry.name}': {display_path(entry.path)}")
            continue
        directory_archives = sorted(path for path in entry.path.glob("*.a") if path.is_file())
        if not directory_archives:
            violations.append(
                f"expected archive directory is empty '{entry.name}': {display_path(entry.path)}")
            continue
        for archive in directory_archives:
            include(archive, entry)

    if not entries:
        violations.append("product manifest contains no declarations")
    if not products:
        violations.append("product manifest resolved to an empty archive inventory")
    return dict(sorted(products.items(), key=lambda item: str(item[0]))), violations


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Inspect only declared iOS dependency build products")
    parser.add_argument("--configuration", default=DEFAULT_CONFIGURATION)
    parser.add_argument("--manifest", type=pathlib.Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    manifest_path = args.manifest or (
        ROOT / "build" / "ios" / "generated"
        / f"ios-archive-products-{args.configuration}.tsv")
    if not manifest_path.is_absolute():
        manifest_path = ROOT / manifest_path

    violations: list[str] = []
    entries: list[ManifestEntry] = []
    products: dict[pathlib.Path, list[dict[str, str]]] = {}
    try:
        entries = read_product_manifest(manifest_path)
        products, manifest_violations = resolve_product_manifest(entries)
        violations.extend(manifest_violations)
    except (OSError, ValueError) as error:
        violations.append(str(error))

    records = []
    for archive, inclusion_reasons in products.items():
        relative_archive = pathlib.Path(display_path(archive))
        lipo_output, lipo_error = inspect(relative_archive, "xcrun", "lipo", "-archs", str(archive))
        load_commands, otool_error = inspect(relative_archive, "xcrun", "otool", "-l", str(archive))
        inspection_errors = [error for error in (lipo_error, otool_error) if error]
        violations.extend(inspection_errors)
        architectures = lipo_output.split() if lipo_error is None else []
        platforms = sorted(set(re.findall(r"^\s+platform\s+([0-9]+)", load_commands, re.MULTILINE)))
        if not platforms and "LC_VERSION_MIN_IPHONEOS" in load_commands:
            platforms = ["2"]
        minimum_versions = sorted(set(re.findall(r"^\s+minos\s+([0-9.]+)", load_commands, re.MULTILINE)))
        if not minimum_versions:
            minimum_versions = sorted(set(re.findall(
                r"LC_VERSION_MIN_IPHONEOS(?:.|\n)*?\n\s+version\s+([0-9.]+)",
                load_commands, re.MULTILINE)))
        record = {
            "path": display_path(archive),
            "sha256": file_hash(archive),
            "architecture": architectures,
            "platforms": platforms,
            "deployment_targets": minimum_versions,
            "configuration": args.configuration,
            "triplet": DEFAULT_TRIPLET,
            "inclusion_reasons": inclusion_reasons,
            "inspection_errors": inspection_errors,
        }
        records.append(record)
        if architectures != ["arm64"]:
            violations.append(f"{record['path']}: architectures={architectures}")
        if platforms != ["2"]:
            violations.append(
                f"{record['path']}: platforms={platforms}, expected iOS device platform 2")
        if not minimum_versions or any(version != DEFAULT_DEPLOYMENT for version in minimum_versions):
            violations.append(f"{record['path']}: deployment_targets={minimum_versions}")

    inventory = {
        "schema": 2,
        "configuration_fingerprint": configuration_fingerprint(),
        "product_manifest": display_path(manifest_path),
        "product_manifest_sha256": file_hash(manifest_path) if manifest_path.is_file() else None,
        "target": {
            "architecture": "arm64",
            "platform": "iOS-device",
            "deployment_target": DEFAULT_DEPLOYMENT,
        },
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
    print(f"Wrote {output} with {len(records)} declared production archives.")
    if violations:
        print("\n".join(f"error: {item}" for item in violations), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
